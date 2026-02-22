import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_io_interface_waveforms(dut):
    dut._log.info("Testing waveforms in IO.")
    
    # Setup clock
    clock = Clock(dut.clk, 30, unit="ns")
    cocotb.start_soon(clock.start())

    # Initial reset
    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.flush.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    
    # Initialize output buffer inputs
    dut.out0.value = 0xA
    dut.out1.value = 0xB
    dut.out2.value = 0xC
    dut.out3.value = 0xD
    
    # Hold reset for 2 cycles, then release
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1

    dut._log.info("Feeding 4 cycles of input data...")
    # Test Input Loading FSM (4 cycles)
    for i in range(4):
        # raw_input_bus = {ui_in, uio_in[3:0]}
        matA = i + 1
        matB = i + 5
        dut.ui_in.value = (matA << 2) | ((matB >> 4) & 0b11)
        dut.uio_in.value = matB & 0b1111
        
        # Advance the clock 1 cycle to process the input
        await ClockCycles(dut.clk, 1)

    # Give it an extra cycle to settle
    await ClockCycles(dut.clk, 1)

    dut._log.info("Pulsing flush to trigger output FSM...")
    # Test Output FSM
    dut.flush.value = 1
    await ClockCycles(dut.clk, 1)
    dut.flush.value = 0
    
    # Advance clock to watch the outputs cycle through the 4 states
    dut._log.info("Waiting for outputs to stream out...")
    await ClockCycles(dut.clk, 6)
    
    dut._log.info("Test finished.")