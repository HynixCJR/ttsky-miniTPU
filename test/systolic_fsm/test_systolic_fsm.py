import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_sanity(dut):
    """Minimal test to make sure Makefile and simulation setup work."""

    # Start a simple clock
    cocotb.start_soon(Clock(dut.clk, 10, unit="us").start())

    # Reset DUT
    dut.rst.value = 1
    await ClockCycles(dut.clk, 2)
    dut.rst.value = 0

    # Wait a few cycles
    await ClockCycles(dut.clk, 5)

    # Nothing else, just pass
    assert True