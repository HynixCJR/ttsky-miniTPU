`timescale 1ns/1ps
`default_nettype none

module tb_systolic_array_fsm;

    // Parameters
    parameter DATA_WIDTH = 6;
    parameter ACC_WIDTH  = 14;
    parameter CLK_PERIOD = 10; // 10ns clock period (100MHz)

    // DUT signals
    logic                    clk;
    logic                    rst;
    logic                    forward_systo;
    logic [DATA_WIDTH-1:0]   a_in;
    logic [2:0]              curr_state_systo;

    // Test variables
    integer test_count;
    integer error_count;

    // State encoding for reference (matching DUT)
    typedef enum logic [2:0] {
        IDLE    = 3'b000,
        FLUSH_1 = 3'b001,
        FLUSH_2 = 3'b010,
        FLUSH_3 = 3'b011,
        FLUSH_4 = 3'b100,
        FLUSH_5 = 3'b101,
        FLUSH_6 = 3'b110,
        FLUSH_7 = 3'b111
    } state_t;

    // Instantiate DUT
    systolic_array_fsm #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .forward_systo(forward_systo),
        .a_in(a_in),
        .curr_state_systo(curr_state_systo)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Checker task
    task check_state(input logic [2:0] expected, input string test_name);
        test_count++;
        if (curr_state_systo !== expected) begin
            error_count++;
            $display("LOG: %0t : ERROR : tb_systolic_array_fsm : dut.curr_state_systo : expected_value: 3'b%03b actual_value: 3'b%03b", 
                     $time, expected, curr_state_systo);
            $display("  Test: %s FAILED", test_name);
        end else begin
            $display("LOG: %0t : INFO : tb_systolic_array_fsm : dut.curr_state_systo : expected_value: 3'b%03b actual_value: 3'b%03b", 
                     $time, expected, curr_state_systo);
            $display("  Test: %s PASSED", test_name);
        end
    endtask

    // Apply forward pulse task
    task apply_forward_pulse();
        @(posedge clk);
        forward_systo = 1'b1;
        @(posedge clk);
        forward_systo = 1'b0;
    endtask

    // Main test sequence
    initial begin
        $display("TEST START");
        $display("========================================");
        $display("Testbench for systolic_array_fsm");
        $display("========================================");
        
        // Initialize
        test_count = 0;
        error_count = 0;
        rst = 1'b0;
        forward_systo = 1'b0;
        a_in = 6'b0;

        // Test 1: Reset behavior
        $display("\n--- Test 1: Reset Behavior ---");
        rst = 1'b1;
        repeat(3) @(posedge clk);
        rst = 1'b0;
        @(posedge clk);
        check_state(IDLE, "Reset to IDLE");

        // Test 2: IDLE to FLUSH_1 transition
        $display("\n--- Test 2: IDLE to FLUSH_1 ---");
        apply_forward_pulse();
        @(posedge clk); // Wait for output register to update
        check_state(FLUSH_1, "IDLE -> FLUSH_1");

        // Test 3: Sequential transitions FLUSH_1 through FLUSH_7
        $display("\n--- Test 3: Sequential State Transitions ---");
        apply_forward_pulse();
        @(posedge clk);
        check_state(FLUSH_2, "FLUSH_1 -> FLUSH_2");

        apply_forward_pulse();
        @(posedge clk);
        check_state(FLUSH_3, "FLUSH_2 -> FLUSH_3");

        apply_forward_pulse();
        @(posedge clk);
        check_state(FLUSH_4, "FLUSH_3 -> FLUSH_4");

        apply_forward_pulse();
        @(posedge clk);
        check_state(FLUSH_5, "FLUSH_4 -> FLUSH_5");

        apply_forward_pulse();
        @(posedge clk);
        check_state(FLUSH_6, "FLUSH_5 -> FLUSH_6");

        apply_forward_pulse();
        @(posedge clk);
        check_state(FLUSH_7, "FLUSH_6 -> FLUSH_7");

        // Test 4: Cyclic behavior - FLUSH_7 back to FLUSH_1
        $display("\n--- Test 4: Cyclic Behavior (FLUSH_7 -> FLUSH_1) ---");
        apply_forward_pulse();
        @(posedge clk);
        check_state(FLUSH_1, "FLUSH_7 -> FLUSH_1 (cyclic)");

        // Test 5: State holds when forward_systo is not asserted
        $display("\n--- Test 5: State Hold without Forward Signal ---");
        forward_systo = 1'b0;
        repeat(5) @(posedge clk);
        check_state(FLUSH_1, "State holds at FLUSH_1");

        // Test 6: Verify output timing (1-cycle delay)
        $display("\n--- Test 6: Output Timing Verification ---");
        // The state register updates on clock edge when forward_systo=1
        // The output register updates on the NEXT clock edge
        @(posedge clk);
        forward_systo = 1'b1;
        @(posedge clk); // State changes to FLUSH_2, but output still shows FLUSH_1
        forward_systo = 1'b0;
        // At this point, internal state is FLUSH_2, output should update on next edge
        check_state(FLUSH_1, "Output still at FLUSH_1 (not yet updated)");
        @(posedge clk); // Now output should reflect FLUSH_2
        check_state(FLUSH_2, "Output updated to FLUSH_2 (1-cycle delay)");

        // Test 7: Multiple consecutive forward pulses
        $display("\n--- Test 7: Rapid State Transitions ---");
        for (int i = 0; i < 5; i++) begin
            apply_forward_pulse();
            @(posedge clk);
        end
        check_state(FLUSH_7, "After 5 transitions from FLUSH_2");

        // Test 8: Reset from non-IDLE state
        $display("\n--- Test 8: Reset from FLUSH_7 ---");
        rst = 1'b1;
        @(posedge clk);
        rst = 1'b0;
        @(posedge clk);
        check_state(IDLE, "Reset from FLUSH_7 to IDLE");

        // Test 9: Full cycle from IDLE
        $display("\n--- Test 9: Complete Cycle Test ---");
        for (int i = 0; i < 8; i++) begin
            apply_forward_pulse();
            @(posedge clk);
        end
        check_state(FLUSH_1, "After complete cycle (8 transitions)");

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
