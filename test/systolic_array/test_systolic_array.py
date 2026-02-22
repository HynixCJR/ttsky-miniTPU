import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb.triggers import ClockCycles

import numpy as np

DATA_WIDTH = 6,     #width of input operands
PSUM_WIDTH  = 14    #width of accumulator
ARRAY_SIZE = 4

@cocotb.test()
async def test_basic_multiply(dut):

    flat_array = np.array(dut.c_out)  # list of individual PSUM elements
    c_out_2d = flat_array.reshape((ARRAY_SIZE, ARRAY_SIZE))

    """Simple sanity test"""

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 2)
    dut.rst.value = 0

    # Apply inputs
    dut.row0_val.value = 3
    dut.col0_val.value = 4

    # Wait a few cycles
    await ClockCycles(dut.clk, 5)

    # Check result
    # assert dut.result.value == 12