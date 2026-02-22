# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

async def reset(dut):
    "reset the TPU"
    dut._log.info("resetting...")
    dut.rst_n.value = 1
    dut.ena.value = 1
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 1)

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

    # input 
    await input_value(dut, 12, -4)

    await ClockCycles(dut.clk, 1)

    dut._log.info("TEST OVERALL BEHAVIOUR")

    # first clock cycle where rst_n is positive
    await ClockCycles(dut.clk, 8)

    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    assert dut.uo_out.value == 0

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.
