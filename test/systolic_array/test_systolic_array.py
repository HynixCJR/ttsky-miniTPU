import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb.triggers import ClockCycles

DATA_WIDTH = 6,     #width of input operands
PSUM_WIDTH  = 14    #width of accumulator
ARRAY_SIZE = 4

@cocotb.test()
async def test_basic_multiply(dut):

    # flat_array = np.array(dut.c_out)  # list of individual PSUM elements
    # c_out_2d = flat_array.reshape((ARRAY_SIZE, ARRAY_SIZE))

    """Simple sanity test"""

    # Set the clock period to 30 ns (~33 MHz)
    clock = Clock(dut.clk, 30, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 2)
    dut.rst.value = 0

    # Apply inputs
    dut.row0_val.value = 3
    dut.col0_val.value = 4
    dut.row1_val.value = 0
    dut.row2_val.value = 0
    dut.row3_val.value = 0
    dut.col1_val.value = 0
    dut.col2_val.value = 0
    dut.col3_val.value = 0
    dut.forward_systo.value = 1
    await ClockCycles(dut.clk, 1)
    dut.forward_systo.value = 0

    # Wait 4 clock cycles
    await ClockCycles(dut.clk, 3)
    dut.row0_val.value = 2
    dut.col0_val.value = 1
    dut.row1_val.value = 5
    dut.row2_val.value = 0
    dut.row3_val.value = 0
    dut.col1_val.value = 6
    dut.col2_val.value = 0
    dut.col3_val.value = 0
    dut.forward_systo.value = 1
    await ClockCycles(dut.clk, 1)
    dut.forward_systo.value = 0

    await ClockCycles(dut.clk, 3)
    dut.row0_val.value = 1
    dut.col0_val.value = 2
    dut.row1_val.value = 4
    dut.row2_val.value = 7
    dut.row3_val.value = 0
    dut.col1_val.value = 2
    dut.col2_val.value = 9
    dut.col3_val.value = 0
    dut.forward_systo.value = 1
    await ClockCycles(dut.clk, 1)
    dut.forward_systo.value = 0

    await ClockCycles(dut.clk, 3)
    dut.row0_val.value = 2
    dut.col0_val.value = 1
    dut.row1_val.value = 5
    dut.row2_val.value = 7
    dut.row3_val.value = 1
    dut.col1_val.value = 6
    dut.col2_val.value = 9
    dut.col3_val.value = 2
    dut.forward_systo.value = 1
    await ClockCycles(dut.clk, 1)
    dut.forward_systo.value = 0


    await ClockCycles(dut.clk, 8)

    # Check result
    # assert dut.result.value == 12