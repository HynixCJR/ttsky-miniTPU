# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

async def reset(dut):
    "reset the TPU"
    dut._log.info("resetting...")
    dut.rst_n.value = 0
    dut.ena.value = 1
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1

async def input_value(dut, matA: int, matB: int):
    "input a value into the TPU's IO"

    # matA gets {ui_in[7:2]}
    # matB gets {ui_in[1:0], uio_in[3:0]}
    if (matA >= 0):
        matA = matA & 0b011111 # positive number
    else:
        matA = matA & 0b111111 # negative number
    if (matB >= 0):
        matB = matB & 0b011111 # positive number
    else:
        matB = matB & 0b111111 # negative number

    # stuff fed into ui_in
    dut.ui_in.value = ((matA << 2) & 0b11111100) | ((matB >> 4) & 0b11) # matA put at top 6 bits, top 2 bits of matB at bottom 2 bits of ui_in
    dut.uio_in.value = matB & 0b1111 # buttom 4 bits of matB
    await ClockCycles(dut.clk, 1)

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 30 ns (~33 MHz)
    clock = Clock(dut.clk, 30, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    await reset(dut)

    mat_A = [
        [1,2,3,4],
        [5,6,7,8],
        [9,10,11,12],
        [13,14,15,16]
    ]
    mat_B = [
        [17,18,19,20],
        [21,22,23,24],
        [25,26,27,28],
        [29,30,31,1]
    ]

    ARRAY_SIZE = 4
    # A 4x4 array requires 2N - 1 = 7 systolic steps to push the data completely.
    # We add a few extra steps (zeros) to guarantee the last accumulations flush.
    NUM_STEPS = 2 * ARRAY_SIZE - 1 + 2

    dut._log.info("Feeding staggered inputs into the TPU...")

    for step in range(NUM_STEPS):
        # The IO_interface loops through 4 states to load the matrices row/col by row/col.
        for i in range(ARRAY_SIZE):
            # To stagger inputs properly:
            # Row 'i' of Matrix A is delayed by 'i' time steps.
            # Col 'i' of Matrix B is delayed by 'i' time steps.
            k = step - i

            # Skewed value for Matrix A (rows)
            if 0 <= k < ARRAY_SIZE:
                val_a = mat_A[i][k]
            else:
                val_a = 0

            # Skewed value for Matrix B (columns)
            if 0 <= k < ARRAY_SIZE:
                val_b = mat_B[k][i]
            else:
                val_b = 0

            # Send values to the DUT. This awaits 1 clock cycle, naturally matching 
            # the hardware's 4-cycle FSM required to trigger startSysArray.
            await input_value(dut, val_a, val_b)

    dut._log.info("Finished feeding inputs. Waiting for output buffer to clear...")

    # Wait for the systo_fsm to pulse flush/clear correctly and clear outputs
    await ClockCycles(dut.clk, 20)

    dut._log.info("Done.")

    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    # assert dut.uo_out.value == 0

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.
