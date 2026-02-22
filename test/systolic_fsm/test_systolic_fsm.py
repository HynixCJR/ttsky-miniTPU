import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_systolic_array_fsm(dut):
    """Test systolic_array_fsm basic behavior and outputs."""

    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    # Apply reset
    dut.rst.value = 1
    dut.ena.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst.value = 0

    # Check INIT state after reset
    assert int(dut.curr_state.value) == 0, f"FSM should start in INIT state, got {dut.curr_state.value}"

    # Enable FSM
    dut.ena.value = 1

    # Step through several cycles and check outputs
    for cycle in range(12):  # simulate 3 full matrices (4 states each)
        await ClockCycles(dut.clk, 1)
        curr_state = int(dut.curr_state.value)
        fwd = int(dut.forward_pulse.value)
        flush = int(dut.flush.value)
        clear = int(dut.clear.value)
        pe_sel = int(dut.PE_clear_select.value)
        c_sel = int(dut.c_out_select.value)
        first_matrix = int(dut.is_first_matrix.value)

        dut._log.info(
            f"Cycle {cycle}: state={curr_state}, fwd={fwd}, flush={flush}, clear={clear}, "
            f"PE={pe_sel}, C={c_sel}, first_matrix={first_matrix}"
        )

        # Forward pulse should be high only in UPDATE
        if curr_state == 1:  # UPDATE
            assert fwd == 1, "forward_pulse should be 1 in UPDATE"
        else:
            assert fwd == 0, "forward_pulse should be 0 outside UPDATE"

        # flush & clear should be 0 for first matrix
        if first_matrix:
            assert flush == 0, "flush should be 0 for first matrix"
            assert clear == 0, "clear should be 0 for first matrix"

        # flush & clear should be high in FLUSH/CLEAR for later matrices
        if not first_matrix:
            if curr_state == 2:  # FLUSH
                assert flush == 1, "flush should be 1 in FLUSH"
            if curr_state == 3:  # CLEAR
                assert clear == 1, "clear should be 1 in CLEAR"

    # After multiple CLEARs, select_index should increment
    prev_pe = int(dut.PE_clear_select.value)
    await ClockCycles(dut.clk, 1)
    new_pe = int(dut.PE_clear_select.value)
    assert new_pe == (prev_pe + 1) % 4, f"PE_clear_select did not increment correctly: {prev_pe} -> {new_pe}"

    await ClockCycles(dut.clk, 16)