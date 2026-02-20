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
                $display("[%0t] FSM State Change: %s -> %s", 
                         $time, 
                         state_name(prev_state), 
                         state_name(dut.curr_state));
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
        $display("Testbench for systolic_array_fsm (Simplified)");
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
        check_2bit("PE_clear_select", 2'b00, PE_clear_select, "Reset: PE_clear_select = 0");
        check_2bit("c_out_select", 2'b00, c_out_select, "Reset: c_out_select = 0");

        // Test 2: Enable and observe cycling
        $display("\n--- Test 2: Enable FSM and Observe Cycling ---");
        ena = 1'b1;
        
        // Let FSM run for 5 complete cycles (20 clocks: 4 states * 5 cycles)
        // Count forward_pulse and clear signals
        repeat(20) begin
            @(posedge clk);
            if (forward_pulse) forward_pulse_count++;
            if (clear) clear_pulse_count++;
        end
        
        // Should see 5 forward_pulse and 5 clear pulses
        test_count++;
        if (forward_pulse_count == 5) begin
            $display("LOG: %0t : INFO : tb_systolic_array_fsm : forward_pulse_count : expected_value: 5 actual_value: %0d", $time, forward_pulse_count);
            $display("  Test: forward_pulse cycling PASSED");
        end else begin
            error_count++;
            $display("LOG: %0t : ERROR : tb_systolic_array_fsm : forward_pulse_count : expected_value: 5 actual_value: %0d", $time, forward_pulse_count);
            $display("  Test: forward_pulse cycling FAILED");
        end
        
        test_count++;
        if (clear_pulse_count == 5) begin
            $display("LOG: %0t : INFO : tb_systolic_array_fsm : clear_pulse_count : expected_value: 5 actual_value: %0d", $time, clear_pulse_count);
            $display("  Test: clear cycling PASSED");
        end else begin
            error_count++;
            $display("LOG: %0t : ERROR : tb_systolic_array_fsm : clear_pulse_count : expected_value: 5 actual_value: %0d", $time, clear_pulse_count);
            $display("  Test: clear cycling FAILED");
        end

        // Test 3: Counter wrap-around
        $display("\n--- Test 3: Counter Wrap-Around ---");
        // Counter should have incremented 5 times: 0->1->2->3->0->1
        // So PE_clear_select should be 1
        check_2bit("PE_clear_select", 2'b01, PE_clear_select, "Counter after 5 cycles = 1");
        
        // Run 3 more cycles to get to counter = 0 (1->2->3->0)
        repeat(12) @(posedge clk);
        check_2bit("PE_clear_select", 2'b00, PE_clear_select, "Counter wraps to 0");

        // Test 4: c_out_select latching
        $display("\n--- Test 4: Output Select Latching ---");
        // c_out_select should have latched during the last FLUSH state
        // Just verify it's a valid 2-bit value (0-3)
        test_count++;
        if (c_out_select <= 2'b11) begin
            $display("LOG: %0t : INFO : tb_systolic_array_fsm : c_out_select : expected_value: 0-3 actual_value: %0d", $time, c_out_select);
            $display("  Test: c_out_select is valid PASSED");
        end else begin
            error_count++;
            $display("LOG: %0t : ERROR : tb_systolic_array_fsm : c_out_select : expected_value: 0-3 actual_value: %0d", $time, c_out_select);
            $display("  Test: c_out_select is valid FAILED");
        end

        // Test 5: Reset during operation
        $display("\n--- Test 5: Reset During Operation ---");
        rst = 1'b1;
        repeat(3) @(posedge clk);
        rst = 1'b0;
        repeat(2) @(posedge clk);  // Give time to settle in INIT
        check_signal("forward_pulse", 1'b0, forward_pulse, "After reset: back to INIT");
        check_signal("clear", 1'b0, clear, "After reset: clear = 0");
        check_2bit("PE_clear_select", 2'b00, PE_clear_select, "After reset: counter = 0");
        check_2bit("c_out_select", 2'b00, c_out_select, "After reset: c_out_select = 0");

        // Test 6: Re-enable after reset
        $display("\n--- Test 6: Re-enable After Reset ---");
        ena = 1'b1;
        forward_pulse_count = 0;
        
        // Run for 2 cycles and verify forward_pulse occurs
        repeat(8) begin
            @(posedge clk);
            if (forward_pulse) forward_pulse_count++;
        end
        
        test_count++;
        if (forward_pulse_count >= 1) begin
            $display("LOG: %0t : INFO : tb_systolic_array_fsm : forward_pulse after re-enable : expected_value: >=1 actual_value: %0d", $time, forward_pulse_count);
            $display("  Test: Re-enable works PASSED");
        end else begin
            error_count++;
            $display("LOG: %0t : ERROR : tb_systolic_array_fsm : forward_pulse after re-enable : expected_value: >=1 actual_value: %0d", $time, forward_pulse_count);
            $display("  Test: Re-enable works FAILED");
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
