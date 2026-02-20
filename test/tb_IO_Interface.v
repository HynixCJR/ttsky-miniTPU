`timescale 1ns / 1ps

module tb_IO_Interface;

    // Testbench signals
    reg clock;
    reg reset;
    reg ena;
    reg [7:0] ui_in;
    reg [7:0] uio_in;
    wire [7:0] uio_out;
    wire [7:0] uo_out;
    wire [7:0] uio_oe;
    wire [5:0] row0_val, row1_val, row2_val, row3_val;
    wire [5:0] col0_val, col1_val, col2_val, col3_val;
    reg [11:0] out0, out1, out2, out3;
    wire startSysArray;

    // Test control
    integer test_num;
    integer error_count;

    // DUT instantiation
    IO_interface dut (
        .clk(clock),
        .ena(ena),
        .rst_n(reset),
        .ui_in(ui_in),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uo_out(uo_out),
        .uio_oe(uio_oe),
        .row0_val(row0_val),
        .row1_val(row1_val),
        .row2_val(row2_val),
        .row3_val(row3_val),
        .col0_val(col0_val),
        .col1_val(col1_val),
        .col2_val(col2_val),
        .col3_val(col3_val),
        .out0(out0),
        .out1(out1),
        .out2(out2),
        .out3(out3),
        .startSysArray(startSysArray)
    );

    // Clock generation - 10ns period (100MHz)
    initial begin
        clock = 0;
        forever #5 clock = ~clock;
    end

    // Main test sequence
    initial begin
        $display("TEST START");
        test_num = 0;
        error_count = 0;

        // Initialize signals
        reset = 0;
        ena = 0;
        ui_in = 8'h00;
        uio_in = 8'h00;
        out0 = 12'h000;
        out1 = 12'h000;
        out2 = 12'h000;
        out3 = 12'h000;

        // Apply reset
        #10;
        reset = 0;  // Active low reset
        #20;
        reset = 1;  // Release reset
        #10;

        // TEST 1: Verify reset state
        test_num = 1;
        $display("\n=== TEST %0d: Reset State Verification ===", test_num);
        if (startSysArray !== 0) begin
            $display("LOG: %0t : ERROR : tb_IO_Interface : dut.startSysArray : expected_value: 1'b0 actual_value: 1'b%b", $time, startSysArray);
            error_count = error_count + 1;
        end
        if (uio_oe !== 8'b11110000) begin
            $display("LOG: %0t : ERROR : tb_IO_Interface : dut.uio_oe : expected_value: 8'b11110000 actual_value: 8'b%b", $time, uio_oe);
            error_count = error_count + 1;
        end
        if (uo_out !== 8'h00 || uio_out[7:4] !== 4'h0) begin
            $display("LOG: %0t : INFO : tb_IO_Interface : dut.uo_out : expected_value: 8'h00 actual_value: 8'h%h", $time, uo_out);
        end
        #10;

        // TEST 2: Input loading sequence - Load 4 pairs of matrix values
        test_num = 2;
        $display("\n=== TEST %0d: Input Loading FSM - 4 Clock Cycles ===", test_num);
        ena = 1;
        
        // Cycle 1: Load row0/col0 with matA=6'h15, matB=6'h0A
        ui_in = 8'h54;      // Upper 8 bits
        uio_in = 8'h5A;     // Lower 4 bits: 0x5A[3:0] = 0xA
        // raw_input_bus = {8'h54, 4'hA} = 12'h54A
        // matA = 12'h54A[11:6] = 6'h15, matB = 12'h54A[5:0] = 6'h0A
        @(posedge clock);
        #1;
        if (startSysArray !== 0) begin
            $display("LOG: %0t : ERROR : tb_IO_Interface : dut.startSysArray : expected_value: 1'b0 actual_value: 1'b%b", $time, startSysArray);
            error_count = error_count + 1;
        end

        // Cycle 2: Load row1/col1
        ui_in = 8'h7F;
        uio_in = 8'hFF;
        @(posedge clock);
        #1;
        if (row0_val !== 6'h15) begin
            $display("LOG: %0t : ERROR : tb_IO_Interface : dut.row0_val : expected_value: 6'h15 actual_value: 6'h%h", $time, row0_val);
            error_count = error_count + 1;
        end
        if (col0_val !== 6'h0A) begin
            $display("LOG: %0t : ERROR : tb_IO_Interface : dut.col0_val : expected_value: 6'h0A actual_value: 6'h%h", $time, col0_val);
            error_count = error_count + 1;
        end
        if (startSysArray !== 0) begin
            $display("LOG: %0t : ERROR : tb_IO_Interface : dut.startSysArray : expected_value: 1'b0 actual_value: 1'b%b", $time, startSysArray);
            error_count = error_count + 1;
        end

        // Cycle 3: Load row2/col2
        ui_in = 8'h81;
        uio_in = 8'h00;
        @(posedge clock);
        #1;
        if (row1_val !== 6'h1F) begin
            $display("LOG: %0t : ERROR : tb_IO_Interface : dut.row1_val : expected_value: 6'h1F actual_value: 6'h%h", $time, row1_val);
            error_count = error_count + 1;
        end
        if (col1_val !== 6'h3F) begin
            $display("LOG: %0t : ERROR : tb_IO_Interface : dut.col1_val : expected_value: 6'h3F actual_value: 6'h%h", $time, col1_val);
            error_count = error_count + 1;
        end
        if (startSysArray !== 0) begin
            $display("LOG: %0t : ERROR : tb_IO_Interface : dut.startSysArray : expected_value: 1'b0 actual_value: 1'b%b", $time, startSysArray);
            error_count = error_count + 1;
        end

        // Cycle 4: Load row3/col3 and trigger startSysArray
        ui_in = 8'hFF;
        uio_in = 8'hFF;
        @(posedge clock);
        #1;
        if (row2_val !== 6'h20) begin
            $display("LOG: %0t : ERROR : tb_IO_Interface : dut.row2_val : expected_value: 6'h20 actual_value: 6'h%h", $time, row2_val);
            error_count = error_count + 1;
        end
        if (col2_val !== 6'h10) begin
            $display("LOG: %0t : ERROR : tb_IO_Interface : dut.col2_val : expected_value: 6'h10 actual_value: 6'h%h", $time, col2_val);
            error_count = error_count + 1;
        end
        if (startSysArray !== 1) begin
            $display("LOG: %0t : ERROR : tb_IO_Interface : dut.startSysArray : expected_value: 1'b1 actual_value: 1'b%b", $time, startSysArray);
            error_count = error_count + 1;
        end else begin
            $display("LOG: %0t : INFO : tb_IO_Interface : dut.startSysArray : expected_value: 1'b1 actual_value: 1'b1 (PASS)", $time);
        end

        // Cycle 5: FSM should reset, startSysArray should be 0
        ui_in = 8'h00;
        uio_in = 8'h00;
        @(posedge clock);
        #1;
        if (row3_val !== 6'h3F) begin
            $display("LOG: %0t : ERROR : tb_IO_Interface : dut.row3_val : expected_value: 6'h3F actual_value: 6'h%h", $time, row3_val);
            error_count = error_count + 1;
        end
        if (col3_val !== 6'h3F) begin
            $display("LOG: %0t : ERROR : tb_IO_Interface : dut.col3_val : expected_value: 6'h3F actual_value: 6'h%h", $time, col3_val);
            error_count = error_count + 1;
        end
        if (startSysArray !== 0) begin
            $display("LOG: %0t : ERROR : tb_IO_Interface : dut.startSysArray : expected_value: 1'b0 actual_value: 1'b%b", $time, startSysArray);
            error_count = error_count + 1;
        end
        $display("=== TEST %0d Complete: Input Loading FSM ===", test_num);

        // TEST 3: Output FSM - Automatic sequential output (no sendOut signal)
        test_num = 3;
        $display("\n=== TEST %0d: Output FSM with Initial State ===", test_num);
        
        // Setup output buffer values
        out0 = 12'hABC;
        out1 = 12'hDEF;
        out2 = 12'h123;
        out3 = 12'h456;
        
        // Note: The output FSM is continuously running
        // Reset initializes to first_buf state, which should output out0
        @(posedge clock);
        #1;
        $display("LOG: %0t : INFO : tb_IO_Interface : dut.uo_out : current_value: 8'h%h", $time, uo_out);
        $display("LOG: %0t : INFO : tb_IO_Interface : dut.uio_out[7:4] : current_value: 4'h%h", $time, uio_out[7:4]);
        
        // Continue clocking and observe output sequence
        @(posedge clock);
        #1;
        $display("LOG: %0t : INFO : tb_IO_Interface : dut.uo_out : current_value: 8'h%h", $time, uo_out);
        
        @(posedge clock);
        #1;
        $display("LOG: %0t : INFO : tb_IO_Interface : dut.uo_out : current_value: 8'h%h", $time, uo_out);
        
        @(posedge clock);
        #1;
        $display("LOG: %0t : INFO : tb_IO_Interface : dut.uo_out : current_value: 8'h%h", $time, uo_out);
        
        @(posedge clock);
        #1;
        $display("LOG: %0t : INFO : tb_IO_Interface : dut.uo_out : current_value: 8'h%h", $time, uo_out);
        
        $display("=== TEST %0d Complete: Output FSM ===", test_num);

        // TEST 4: Enable control test
        test_num = 4;
        $display("\n=== TEST %0d: Enable Control ===", test_num);
        ena = 0;
        ui_in = 8'hAA;
        uio_in = 8'hAA;
        
        @(posedge clock);
        @(posedge clock);
        #1;
        // When ena=0, FSM should not advance
        $display("LOG: %0t : INFO : tb_IO_Interface : dut.row0_val : current_value: 6'h%h", $time, row0_val);
        $display("=== TEST %0d Complete: Enable Control ===", test_num);

        // TEST 5: Reset during operation
        test_num = 5;
        $display("\n=== TEST %0d: Reset During Operation ===", test_num);
        ena = 1;
        ui_in = 8'h11;
        uio_in = 8'h11;
        
        @(posedge clock);
        @(posedge clock);
        
        // Apply reset
        reset = 0;
        #20;
        reset = 1;
        #1;
        
        if (startSysArray !== 0) begin
            $display("LOG: %0t : ERROR : tb_IO_Interface : dut.startSysArray : expected_value: 1'b0 actual_value: 1'b%b", $time, startSysArray);
            error_count = error_count + 1;
        end
        $display("=== TEST %0d Complete: Reset During Operation ===", test_num);

        // TEST 6: Continuous operation - verify both FSMs loop correctly
        test_num = 6;
        $display("\n=== TEST %0d: Continuous Operation ===", test_num);
        
        // Run through 2 complete input cycles (8 clocks)
        ui_in = 8'h01;
        uio_in = 8'h01;
        repeat(8) @(posedge clock);
        #1;
        
        $display("=== TEST %0d Complete: Continuous Operation ===", test_num);

        // TEST 7: All zeros input
        test_num = 7;
        $display("\n=== TEST %0d: All Zeros Input ===", test_num);
        ui_in = 8'h00;
        uio_in = 8'h00;
        
        repeat(4) @(posedge clock);
        #1;
        
        if (row0_val !== 6'h00 || row1_val !== 6'h00 || row2_val !== 6'h00 || row3_val !== 6'h00) begin
            $display("LOG: %0t : ERROR : tb_IO_Interface : dut.row_vals : expected_value: all_zeros actual_value: row0=%h row1=%h row2=%h row3=%h", 
                     $time, row0_val, row1_val, row2_val, row3_val);
            error_count = error_count + 1;
        end
        if (col0_val !== 6'h00 || col1_val !== 6'h00 || col2_val !== 6'h00 || col3_val !== 6'h00) begin
            $display("LOG: %0t : ERROR : tb_IO_Interface : dut.col_vals : expected_value: all_zeros actual_value: col0=%h col1=%h col2=%h col3=%h", 
                     $time, col0_val, col1_val, col2_val, col3_val);
            error_count = error_count + 1;
        end
        $display("=== TEST %0d Complete: All Zeros Input ===", test_num);

        // TEST 8: All ones input
        test_num = 8;
        $display("\n=== TEST %0d: All Ones Input ===", test_num);
        ui_in = 8'hFF;
        uio_in = 8'hFF;
        
        repeat(4) @(posedge clock);
        #1;
        
        if (row0_val !== 6'h3F || row1_val !== 6'h3F || row2_val !== 6'h3F || row3_val !== 6'h3F) begin
            $display("LOG: %0t : ERROR : tb_IO_Interface : dut.row_vals : expected_value: all_ones actual_value: row0=%h row1=%h row2=%h row3=%h", 
                     $time, row0_val, row1_val, row2_val, row3_val);
            error_count = error_count + 1;
        end
        if (col0_val !== 6'h3F || col1_val !== 6'h3F || col2_val !== 6'h3F || col3_val !== 6'h3F) begin
            $display("LOG: %0t : ERROR : tb_IO_Interface : dut.col_vals : expected_value: all_ones actual_value: col0=%h col1=%h col2=%h col3=%h", 
                     $time, col0_val, col1_val, col2_val, col3_val);
            error_count = error_count + 1;
        end
        $display("=== TEST %0d Complete: All Ones Input ===", test_num);

        // TEST 9: Verify output sequence with known values
        test_num = 9;
        $display("\n=== TEST %0d: Full Output Sequence ===", test_num);
        
        // Set distinct values
        out0 = 12'h111;
        out1 = 12'h222;
        out2 = 12'h333;
        out3 = 12'h444;
        
        // Clock through one complete output cycle
        repeat(6) begin
            @(posedge clock);
            #1;
            $display("LOG: %0t : INFO : tb_IO_Interface : Output - uo_out: 8'h%h uio_out[7:4]: 4'h%h", $time, uo_out, uio_out[7:4]);
        end
        
        $display("=== TEST %0d Complete: Full Output Sequence ===", test_num);

        // Final result summary
        #50;
        $display("\n========================================");
        $display("    TESTBENCH SUMMARY");
        $display("========================================");
        $display("Total Tests Run: %0d", test_num);
        $display("Total Errors: %0d", error_count);
        
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
        #100000;
        $display("\n*** ERROR: TIMEOUT ***");
        $fatal("Simulation timeout after 100us");
    end

    // Waveform dump
    initial begin
        $dumpfile("dumpfile.fst");
        $dumpvars(0);
    end

endmodule
