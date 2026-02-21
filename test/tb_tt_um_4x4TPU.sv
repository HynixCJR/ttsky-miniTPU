`timescale 1ns / 1ps
`default_nettype none

module tb_tt_um_4x4TPU;

    // Parameters
    parameter CLK_PERIOD = 10; // 10ns = 100MHz

    // DUT signals
    logic [7:0] ui_in;
    logic [7:0] uo_out;
    logic [7:0] uio_in;
    logic [7:0] uio_out;
    logic [7:0] uio_oe;
    logic       ena;
    logic       clk;
    logic       rst_n;

    // Test control
    integer test_num;
    integer error_count;
    integer cycle_count;

    // DUT instantiation
    tt_um_4x4TPU dut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(ena),
        .clk(clk),
        .rst_n(rst_n)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Helper task: Load matrix values over 4 clock cycles
    task load_matrix(
        input [5:0] mat_a [0:3],  // Matrix A values
        input [5:0] mat_b [0:3]   // Matrix B values
    );
        integer i;
        begin
            $display("[%0t] Loading matrix values...", $time);
            for (i = 0; i < 4; i = i + 1) begin
                // Combine matA (upper 6 bits) and matB (lower 6 bits) into 12-bit bus
                ui_in = {mat_a[i][5:2], mat_b[i][5:2]};  // Upper 8 bits
                uio_in = {4'b0000, mat_a[i][1:0], mat_b[i][1:0]};  // Lower 4 bits (input)
                @(posedge clk);
                $display("[%0t]   Cycle %0d: matA=6'h%h, matB=6'h%h", $time, i, mat_a[i], mat_b[i]);
            end
            $display("[%0t] Matrix loading complete", $time);
        end
    endtask

    // Helper task: Wait for N clock cycles
    task wait_cycles(input integer n);
        repeat(n) @(posedge clk);
    endtask

    // Helper task: Monitor outputs for N cycles
    task monitor_outputs(input integer n);
        integer i;
        begin
            $display("[%0t] Monitoring outputs for %0d cycles:", $time, n);
            for (i = 0; i < n; i = i + 1) begin
                @(posedge clk);
                #1;  // Small delay after clock edge
                $display("[%0t]   uo_out=8'h%h, uio_out[7:4]=4'h%h", 
                         $time, uo_out, uio_out[7:4]);
            end
        end
    endtask

    // Main test sequence
    initial begin
        $display("TEST START");
        $display("========================================");
        $display("Testbench for tt_um_4x4TPU - 4x4 Systolic Array TPU");
        $display("========================================\n");

        // Initialize
        test_num = 0;
        error_count = 0;
        cycle_count = 0;
        rst_n = 1'b1;
        ena = 1'b0;
        ui_in = 8'h00;
        uio_in = 8'h00;

        // TEST 1: Reset and initialization
        test_num = 1;
        $display("\n=== TEST %0d: Reset and Initialization ===", test_num);
        rst_n = 1'b0;  // Assert reset
        repeat(5) @(posedge clk);
        rst_n = 1'b1;  // Release reset
        repeat(3) @(posedge clk);
        
        // Check uio_oe is set correctly (should be 8'b11110000)
        #1;
        if (uio_oe !== 8'b11110000) begin
            $display("LOG: %0t : ERROR : tb_tt_um_4x4TPU : dut.uio_oe : expected_value: 8'b11110000 actual_value: 8'b%b", 
                     $time, uio_oe);
            error_count = error_count + 1;
        end else begin
            $display("LOG: %0t : INFO : tb_tt_um_4x4TPU : dut.uio_oe : expected_value: 8'b11110000 actual_value: 8'b%b (PASS)", 
                     $time, uio_oe);
        end
        $display("=== TEST %0d Complete ===\n", test_num);

        // TEST 2: Simple identity-like test (small values)
        test_num = 2;
        $display("\n=== TEST %0d: Simple Matrix Operation ===", test_num);
        ena = 1'b1;
        
        // Load simple test matrices
        // Matrix A rows: [1, 0, 0, 0]
        // Matrix B cols: [1, 0, 0, 0]
        begin
            logic [5:0] mat_a [0:3];
            logic [5:0] mat_b [0:3];
            
            mat_a[0] = 6'd1;
            mat_a[1] = 6'd0;
            mat_a[2] = 6'd0;
            mat_a[3] = 6'd0;
            
            mat_b[0] = 6'd1;
            mat_b[1] = 6'd0;
            mat_b[2] = 6'd0;
            mat_b[3] = 6'd0;
            
            load_matrix(mat_a, mat_b);
        end
        
        // Wait for systolic array FSM to process
        // FSM cycles: INIT->UPDATE->FLUSH->CLEAR->IDLE (repeat 4 times for first matrix)
        // Plus additional cycles for actual computation
        $display("[%0t] Waiting for systolic array processing (~32 cycles)...", $time);
        wait_cycles(32);
        
        // Monitor outputs
        monitor_outputs(8);
        
        $display("=== TEST %0d Complete ===\n", test_num);

        // TEST 3: Non-zero matrix test
        test_num = 3;
        $display("\n=== TEST %0d: Non-Zero Matrix Operation ===", test_num);
        
        // Load test matrices with small non-zero values
        // Matrix A rows: [2, 1, 1, 1]
        // Matrix B cols: [2, 1, 1, 1]
        begin
            logic [5:0] mat_a [0:3];
            logic [5:0] mat_b [0:3];
            
            mat_a[0] = 6'd2;
            mat_a[1] = 6'd1;
            mat_a[2] = 6'd1;
            mat_a[3] = 6'd1;
            
            mat_b[0] = 6'd2;
            mat_b[1] = 6'd1;
            mat_b[2] = 6'd1;
            mat_b[3] = 6'd1;
            
            load_matrix(mat_a, mat_b);
        end
        
        // Wait for processing
        $display("[%0t] Waiting for systolic array processing (~32 cycles)...", $time);
        wait_cycles(32);
        
        // Monitor outputs
        monitor_outputs(8);
        
        $display("=== TEST %0d Complete ===\n", test_num);

        // TEST 4: Larger values test
        test_num = 4;
        $display("\n=== TEST %0d: Larger Values Test ===", test_num);
        
        // Load matrices with larger values
        // Matrix A rows: [7, 5, 3, 2]
        // Matrix B cols: [6, 4, 3, 2]
        begin
            logic [5:0] mat_a [0:3];
            logic [5:0] mat_b [0:3];
            
            mat_a[0] = 6'd7;
            mat_a[1] = 6'd5;
            mat_a[2] = 6'd3;
            mat_a[3] = 6'd2;
            
            mat_b[0] = 6'd6;
            mat_b[1] = 6'd4;
            mat_b[2] = 6'd3;
            mat_b[3] = 6'd2;
            
            load_matrix(mat_a, mat_b);
        end
        
        // Wait for processing
        $display("[%0t] Waiting for systolic array processing (~32 cycles)...", $time);
        wait_cycles(32);
        
        // Monitor outputs (should see diagonal results over 4 cycles)
        monitor_outputs(8);
        
        $display("=== TEST %0d Complete ===\n", test_num);

        // TEST 5: Maximum values test (6-bit signed max = 31)
        test_num = 5;
        $display("\n=== TEST %0d: Maximum Values Test ===", test_num);
        
        // Load matrices with maximum positive values
        begin
            logic [5:0] mat_a [0:3];
            logic [5:0] mat_b [0:3];
            
            mat_a[0] = 6'd31;
            mat_a[1] = 6'd31;
            mat_a[2] = 6'd31;
            mat_a[3] = 6'd31;
            
            mat_b[0] = 6'd1;
            mat_b[1] = 6'd1;
            mat_b[2] = 6'd1;
            mat_b[3] = 6'd1;
            
            load_matrix(mat_a, mat_b);
        end
        
        // Wait for processing
        $display("[%0t] Waiting for systolic array processing (~32 cycles)...", $time);
        wait_cycles(32);
        
        // Monitor outputs
        monitor_outputs(8);
        
        $display("=== TEST %0d Complete ===\n", test_num);

        // TEST 6: Reset during operation
        test_num = 6;
        $display("\n=== TEST %0d: Reset During Operation ===", test_num);
        
        // Start loading values
        begin
            logic [5:0] mat_a [0:3];
            logic [5:0] mat_b [0:3];
            
            mat_a[0] = 6'd5;
            mat_a[1] = 6'd5;
            mat_a[2] = 6'd5;
            mat_a[3] = 6'd5;
            
            mat_b[0] = 6'd5;
            mat_b[1] = 6'd5;
            mat_b[2] = 6'd5;
            mat_b[3] = 6'd5;
            
            // Load only 2 values
            ui_in = {mat_a[0][5:2], mat_b[0][5:2]};
            uio_in = {4'b0000, mat_a[0][1:0], mat_b[0][1:0]};
            @(posedge clk);
            
            ui_in = {mat_a[1][5:2], mat_b[1][5:2]};
            uio_in = {4'b0000, mat_a[1][1:0], mat_b[1][1:0]};
            @(posedge clk);
        end
        
        // Apply reset mid-operation
        $display("[%0t] Applying reset mid-operation...", $time);
        rst_n = 1'b0;
        repeat(3) @(posedge clk);
        rst_n = 1'b1;
        repeat(2) @(posedge clk);
        
        // Verify outputs are reset
        #1;
        $display("[%0t] After reset: uo_out=8'h%h, uio_out[7:4]=4'h%h", 
                 $time, uo_out, uio_out[7:4]);
        
        $display("=== TEST %0d Complete ===\n", test_num);

        // TEST 7: Enable control test
        test_num = 7;
        $display("\n=== TEST %0d: Enable Control ===", test_num);
        
        ena = 1'b0;  // Disable
        ui_in = 8'hAA;
        uio_in = 8'hAA;
        
        wait_cycles(10);
        $display("[%0t] System disabled for 10 cycles", $time);
        
        ena = 1'b1;  // Re-enable
        wait_cycles(5);
        $display("[%0t] System re-enabled", $time);
        
        $display("=== TEST %0d Complete ===\n", test_num);

        // TEST 8: Continuous operation test
        test_num = 8;
        $display("\n=== TEST %0d: Continuous Operation ===", test_num);
        
        // Load and process multiple matrices back-to-back
        for (int matrix_num = 0; matrix_num < 2; matrix_num = matrix_num + 1) begin
            $display("[%0t] Loading matrix set %0d...", $time, matrix_num);
            
            begin
                logic [5:0] mat_a [0:3];
                logic [5:0] mat_b [0:3];
                
                // Different values for each matrix
                mat_a[0] = 6'(3 + matrix_num);
                mat_a[1] = 6'(2 + matrix_num);
                mat_a[2] = 6'(2 + matrix_num);
                mat_a[3] = 6'(1 + matrix_num);
                
                mat_b[0] = 6'(3 + matrix_num);
                mat_b[1] = 6'(2 + matrix_num);
                mat_b[2] = 6'(2 + matrix_num);
                mat_b[3] = 6'(1 + matrix_num);
                
                load_matrix(mat_a, mat_b);
            end
            
            // Wait between matrices
            wait_cycles(32);
            monitor_outputs(4);
        end
        
        $display("=== TEST %0d Complete ===\n", test_num);

        // Final Summary
        #100;
        $display("\n========================================");
        $display("    TESTBENCH SUMMARY");
        $display("========================================");
        $display("Total Tests Run: %0d", test_num);
        $display("Total Errors: %0d", error_count);
        $display("Total Cycles: ~%0d", cycle_count);
        $display("========================================");
        
        if (error_count == 0) begin
            $display("\n*** TEST PASSED ***");
        end else begin
            $display("\n*** TEST FAILED ***");
            $fatal("Testbench failed with %0d errors", error_count);
        end
        
        $finish;
    end

    // Timeout watchdog
    initial begin
        #500000;  // 500us timeout
        $display("\n*** ERROR: TIMEOUT ***");
        $fatal("Simulation timeout after 500us");
    end

    // Cycle counter
    always @(posedge clk) begin
        if (rst_n) cycle_count = cycle_count + 1;
    end

    // Waveform dump
    initial begin
        $dumpfile("dumpfile.fst");
        $dumpvars(0);
    end

endmodule

`default_nettype wire
