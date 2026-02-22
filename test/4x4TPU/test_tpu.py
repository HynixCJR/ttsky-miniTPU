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
    matrices_A = [
        [ # Matrix 0, just to show that it works
            [1,2,3,4],
            [5,6,7,8],
            [9,10,11,12],
            [13,14,15,16]
        ],
        [ # Matrix 1 (Identity-ish)
            [1,0,0,0],
            [0,1,0,0],
            [0,0,1,0],
            [0,0,0,1]
        ],
        [ # Matrix 2 (maxing out)
            [31,31,31,31],
            [31,31,31,31],
            [31,31,31,31],
            [31,31,31,31]
        ],
        [ # Matrix 3 (testing ReLU)
            [31,31,31,31],
            [31,31,31,31],
            [31,31,31,31],
            [31,31,31,31]
        ]
    ]

    matrices_B = [
        [ # Matrix 0, just to show that it works
            [17,18,19,20],
            [21,22,23,24],
            [25,26,27,28],
            [29,30,31,1]
        ],
        [ # Matrix 1 (Sequential)
            [1,2,3,4],
            [5,6,7,8],
            [9,10,11,12],
            [13,14,15,16]
        ],
        [ # Matrix 2 (maxing out)
            [31,31,31,31],
            [31,31,31,31],
            [31,31,31,31],
            [31,31,31,31]
        ],
        [ # Matrix 3 (testing ReLU)
            [-31,-31,-31,-31],
            [-31,-31,-31,-31],
            [-31,-31,-31,-31],
            [-31,-31,-31,-31]
        ]
    ]

    ARRAY_SIZE = 4
    num_matrices = len(matrices_A)
    
    # 4 load steps per matrix
    # + (ARRAY_SIZE - 1) for the initial stagger delay of the last row
    # + 4 extra steps to ensure the final outputs flush entirely through the FSM
    NUM_STEPS = (ARRAY_SIZE * num_matrices) + (ARRAY_SIZE - 1) + 4

    dut._log.info(f"Feeding {num_matrices} matrices perfectly pipelined...")

    for step in range(NUM_STEPS):
        for i in range(ARRAY_SIZE):
            # 's' represents the active calculation step for row 'i', removing the stagger delay
            s = step - i

            # If this row is actively processing data for any of the matrices
            if 0 <= s < (ARRAY_SIZE * num_matrices):
                m = s // ARRAY_SIZE # Which matrix are we on? (0, 1, or 2)
                k = s % ARRAY_SIZE  # Which element of the row/col are we on? (0 to 3)
                
                val_a = matrices_A[m][i][k]
                val_b = matrices_B[m][k][i]
            else:
                # Padding zeros for the stagger ramp-up and ramp-down
                val_a = 0
                val_b = 0

            await input_value(dut, val_a, val_b)

    dut._log.info("Finished feeding inputs. Waiting for remaining outputs to clear...")
    
    # Allow time for the final matrix outputs to be flushed to the GPIO
    await ClockCycles(dut.clk, 30)
    
    dut._log.info("Done.")
    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    # assert dut.uo_out.value == 0

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.
