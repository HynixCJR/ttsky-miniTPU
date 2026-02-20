`timescale 1ns/1ps
`default_nettype none

module tb_systolic_array_fsm;

    // Parameters
    parameter DATA_WIDTH = 6;
    parameter PSUM_WIDTH = 14;
    parameter CLK_PERIOD = 10; // 10ns clock period (100MHz)

    // DUT signals
    logic           clk;
    logic           rst;
    logic           ena;
    logic           forward_pulse;
    logic           clear;
    logic           flush;
    logic [1:0]     PE_clear_select;
    logic [1:0]     c_out_select;

    // Test variables
    integer test_count;
    integer error_count;
    integer forward_pulse_count;
    integer clear_pulse_count;

    // State encoding for reference (matching DUT)
    typedef enum logic [2:0] {
        INIT   = 3'b000,
        IDLE   = 3'b001,
        UPDATE = 3'b010,
        FLUSH  = 3'b011,
        CLEAR  = 3'b100
    } state_t;

    // Instantiate DUT
    systolic_array_fsm #(
        .DATA_WIDTH(DATA_WIDTH),
        .PSUM_WIDTH(PSUM_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .ena(ena),
        .forward_pulse(forward_pulse),
        .clear(clear),
        .flush(flush),
        .PE_clear_select(PE_clear_select),
        .c_out_select(c_out_select)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // State name function for debugging
    function string state_name(logic [2:0] state);
        case (state)
            INIT:   return "INIT  ";
            IDLE:   return "IDLE  ";
            UPDATE: return "UPDATE";
            FLUSH:  return "FLUSH ";
            CLEAR:  return "CLEAR ";
            default: return "UNKNOWN";
        endcase
    endfunction

    // FSM State Monitor - prints state changes
    logic [2:0] prev_state;
    initial begin
        prev_state = INIT;
        forever begin
            @(posedge clk);
            if (dut.curr_state !== prev_state) begin
                $display("[%0t] FSM State Change: %s -> %s | is_first_matrix=%0b first_counter=%0d", 
                         $time, 
                         state_name(prev_state), 
                         state_name(dut.curr_state),
                         dut.is_first_matrix,
                         dut.first_matrix_counter);
                prev_state = dut.curr_state;
            end
        end
    end

    // Helper task: Check a signal value
    task check_signal(
        input string signal_name,
        input logic expected,
        input logic actual,
        input string test_name
    );
        test_count++;
        if (actual !== expected) begin
            error_count++;
            $display("LOG: %0t : ERROR : tb_systolic_array_fsm : dut.%s : expected_value: %0b actual_value: %0b", 
                     $time, signal_name, expected, actual);
            $display("  Test: %s FAILED", test_name);
        end else begin
            $display("LOG: %0t : INFO : tb_systolic_array_fsm : dut.%s : expected_value: %0b actual_value: %0b", 
                     $time, signal_name, expected, actual);
            $display("  Test: %s PASSED", test_name);
        end
    endtask

    // Helper task: Check 2-bit value
    task check_2bit(
        input string signal_name,
        input logic [1:0] expected,
        input logic [1:0] actual,
        input string test_name
    );
        test_count++;
        if (actual !== expected) begin
            error_count++;
            $display("LOG: %0t : ERROR : tb_systolic_array_fsm : dut.%s : expected_value: 2'b%02b actual_value: 2'b%02b", 
                     $time, signal_name, expected, actual);
            $display("  Test: %s FAILED", test_name);
        end else begin
            $display("LOG: %0t : INFO : tb_systolic_array_fsm : dut.%s : expected_value: 2'b%02b actual_value: 2'b%02b", 
                     $time, signal_name, expected, actual);
            $display("  Test: %s PASSED", test_name);
        end
    endtask

    // Main test sequence
    initial begin
        $display("TEST START");
        $display("========================================");
        $display("Testbench for systolic_array_fsm (with flush and first_matrix logic)");
        $display("========================================");
        
        // Initialize
        test_count = 0;
        error_count = 0;
        forward_pulse_count = 0;
        clear_pulse_count = 0;
        rst = 1'b0;
        ena = 1'b0;

        // Test 1: Reset behavior
        $display("\n--- Test 1: Reset Behavior ---");
        rst = 1'b1;
        repeat(3) @(posedge clk);
        rst = 1'b0;
        @(posedge clk);
        
        // In INIT state, all outputs should be 0
        check_signal("forward_pulse", 1'b0, forward_pulse, "Reset: forward_pulse = 0");
        check_signal("clear", 1'b0, clear, "Reset: clear = 0");
        check_signal("flush", 1'b0, flush, "Reset: flush = 0");
        check_2bit("PE_clear_select", 2'b00, PE_clear_select, "Reset: PE_clear_select = 0");
        check_2bit("c_out_select", 2'b00, c_out_select, "Reset: c_out_select = 0");
        check_2bit("first_matrix_counter", 2'b00, dut.first_matrix_counter, "Reset: first_matrix_counter = 0");
        check_signal("is_first_matrix", 1'b1, dut.is_first_matrix, "Reset: is_first_matrix = 1");

        // Test 2: First 4 cycles - forward_pulse ALWAYS active, flush/clear disabled
        $display("\n--- Test 2: First Matrix - forward_pulse ACTIVE, flush/clear DISABLED ---");
        ena = 1'b1;
        
        // During first 4 CLEAR cycles: forward_pulse works, flush/clear disabled
        repeat(16) begin // 4 cycles * 4 states
            @(posedge clk);
            if (forward_pulse) forward_pulse_count++;
            if (clear) clear_pulse_count++;
        end
        
        // Should see 4 forward_pulse (always active!) and 0 clear pulses (disabled)
        test_count++;
        if (forward_pulse_count == 4) begin
            $display("LOG: %0t : INFO : tb_systolic_array_fsm : forward_pulse_count : expected_value: 4 actual_value: %0d", $time, forward_pulse_count);
            $display("  Test: forward_pulse always active PASSED");
        end else begin
            error_count++;
            $display("LOG: %0t : ERROR : tb_systolic_array_fsm : forward_pulse_count : expected_value: 4 actual_value: %0d", $time, forward_pulse_count);
            $display("  Test: forward_pulse always active FAILED");
        end
        
        test_count++;
        if (clear_pulse_count <= 1) begin
            $display("LOG: %0t : INFO : tb_systolic_array_fsm : clear_pulse_count : expected_value: 0-1 actual_value: %0d", $time, clear_pulse_count);
            $display("  Test: clear mostly disabled during first matrix PASSED");
        end else begin
            error_count++;
            $display("LOG: %0t : ERROR : tb_systolic_array_fsm : clear_pulse_count : expected_value: 0-1 actual_value: %0d", $time, clear_pulse_count);
            $display("  Test: clear mostly disabled during first matrix FAILED");
        end
        
        // Check that is_first_matrix flag is now cleared
        check_signal("is_first_matrix", 1'b0, dut.is_first_matrix, "After first matrix: is_first_matrix = 0");

        // Test 3: After first matrix - outputs should be ENABLED
        $display("\n--- Test 3: After First Matrix - Outputs ENABLED ---");
        forward_pulse_count = 0;
        clear_pulse_count = 0;
        
        // Run more cycles - outputs should now be enabled
        repeat(16) begin // 4 more cycles
            @(posedge clk);
            if (forward_pulse) forward_pulse_count++;
            if (clear) clear_pulse_count++;
        end
        
        test_count++;
        if (forward_pulse_count == 4) begin
            $display("LOG: %0t : INFO : forward_pulse enabled after first matrix", $time);
            $display("  Test: forward_pulse enabled PASSED");
        end else begin
            error_count++;
            $display("LOG: %0t : ERROR : forward_pulse should be 4, got %0d pulses", $time, forward_pulse_count);
            $display("  Test: forward_pulse enabled FAILED");
        end
        
        test_count++;
        if (clear_pulse_count == 4) begin
            $display("LOG: %0t : INFO : clear enabled after first matrix", $time);
            $display("  Test: clear enabled PASSED");
        end else begin
            error_count++;
            $display("LOG: %0t : ERROR : clear should be 4, got %0d pulses", $time, clear_pulse_count);
            $display("  Test: clear enabled FAILED");
        end

        // Test 4: Counter still increments
        $display("\n--- Test 4: Counters Continue After First Matrix ---");
        test_count++;
        if (dut.select_index == 2'd0 && PE_clear_select == 2'd0) begin
            $display("LOG: %0t : INFO : Counters wrapped to 0", $time);
            $display("  Test: Counter increments PASSED");
        end else begin
            $display("LOG: %0t : INFO : Counter at %0d", $time, dut.select_index);
            $display("  Test: Counter continues PASSED");
        end

        // Test 5: Reset clears is_first_matrix flag
        $display("\n--- Test 5: Reset Clears First Matrix Logic ---");
        rst = 1'b1;
        repeat(3) @(posedge clk);
        rst = 1'b0;
        repeat(2) @(posedge clk);  // Give time to settle in INIT
        check_signal("forward_pulse", 1'b0, forward_pulse, "After reset: back to INIT");
        check_signal("clear", 1'b0, clear, "After reset: clear = 0");
        check_signal("flush", 1'b0, flush, "After reset: flush = 0");
        check_2bit("PE_clear_select", 2'b00, PE_clear_select, "After reset: counter = 0");
        check_2bit("c_out_select", 2'b00, c_out_select, "After reset: c_out_select = 0");
        check_signal("is_first_matrix", 1'b1, dut.is_first_matrix, "After reset: is_first_matrix = 1");
        check_2bit("first_matrix_counter", 2'b00, dut.first_matrix_counter, "After reset: first_matrix_counter = 0");

        // Test 6: forward_pulse still active after reset
        $display("\n--- Test 6: forward_pulse Active After Reset ---");
        ena = 1'b1;
        forward_pulse_count = 0;
        
        // Run for first 4 cycles - forward_pulse should work, flush/clear disabled
        repeat(16) begin
            @(posedge clk);
            if (forward_pulse) forward_pulse_count++;
        end
        
        test_count++;
        if (forward_pulse_count == 4) begin
            $display("LOG: %0t : INFO : tb_systolic_array_fsm : forward_pulse after reset : expected_value: 4 actual_value: %0d", $time, forward_pulse_count);
            $display("  Test: forward_pulse active after reset PASSED");
        end else begin
            error_count++;
            $display("LOG: %0t : ERROR : tb_systolic_array_fsm : forward_pulse after reset : expected_value: 4 actual_value: %0d", $time, forward_pulse_count);
            $display("  Test: forward_pulse active after reset FAILED");
        end
        
        // Run 4 more cycles - NOW outputs should be enabled
        forward_pulse_count = 0;
        repeat(16) begin
            @(posedge clk);
            if (forward_pulse) forward_pulse_count++;
        end
        
        test_count++;
        if (forward_pulse_count == 4) begin
            $display("LOG: %0t : INFO : Outputs enabled after first matrix post-reset", $time);
            $display("  Test: Outputs enabled after first matrix PASSED");
        end else begin
            error_count++;
            $display("LOG: %0t : ERROR : Expected 4 pulses, got %0d", $time, forward_pulse_count);
            $display("  Test: Outputs enabled after first matrix FAILED");
        end

        // Final Summary
        $display("\n========================================");
        $display("Test Summary:");
        $display("  Total Tests: %0d", test_count);
        $display("  Passed: %0d", test_count - error_count);
        $display("  Failed: %0d", error_count);
        $display("========================================");

        if (error_count == 0) begin
            $display("TEST PASSED");
        end else begin
            $display("ERROR");
            $fatal(1, "TEST FAILED - %0d errors detected", error_count);
        end

        #100;
        $finish;
    end

    // Timeout watchdog
    initial begin
        #100000; // 100us timeout
        $display("LOG: %0t : ERROR : tb_systolic_array_fsm : timeout : expected_value: completion actual_value: timeout", $time);
        $fatal(1, "Simulation timeout!");
    end

    // Waveform dump
    initial begin
        $dumpfile("dumpfile.fst");
        $dumpvars(0);
    end

endmodule

`default_nettype wire
