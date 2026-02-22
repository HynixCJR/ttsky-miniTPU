`timescale 1ns/1ps

module tb_tt_um_4x4TPU();

    // --- Signals ---
    reg clk = 0;
    reg rst_n;
    reg ena;
    reg [7:0] ui_in;
    reg [7:0] uio_in;
    
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    // --- Instantiate the DUT ---
    tt_um_4x4TPU uut (
        .clk(clk),
        .rst_n(rst_n),
        .ena(ena),
        .ui_in(ui_in),
        .uio_in(uio_in),
        .uo_out(uo_out),
        .uio_out(uio_out),
        .uio_oe(uio_oe)
    );

    // --- Clock Generation (33.3 MHz) ---
    always #15 clk = ~clk;

    // --- Helper Task: Send 12-bit Data (1 Clock Cycle) ---
    task send_io(input [5:0] a, input [5:0] b);
        begin
            ui_in  = {a, b[5:4]};       // Pack top 8 bits
            uio_in = {4'b0000, b[3:0]}; // Pack bottom 4 bits
            @(posedge clk);
            #1;                         // Delay 1ns to allow signals to stabilize
        end
    endtask

    // --- Helper Task: Send Staggered Beat (4 Clock Cycles) ---
    task send_staggered_beat(
        input [5:0] r0, input [5:0] r1, input [5:0] r2, input [5:0] r3,
        input [5:0] c0, input [5:0] c1, input [5:0] c2, input [5:0] c3
    );
        begin
            send_io(r0, c0);            // Cycle 1 (first_buf)
            send_io(r1, c1);            // Cycle 2 (second_buf)
            send_io(r2, c2);            // Cycle 3 (third_buf - triggers early start)
            send_io(r3, c3);            // Cycle 4 (fourth_buf - FSM shifts array)
        end
    endtask

    // --- Main Simulation Sequence ---
    initial begin
        $dumpfile("tpu_sim.vcd");
        $dumpvars(0, tb_tt_um_4x4TPU);

        // 1. Initialize
        ena = 1;
        ui_in = 0;
        uio_in = 0;
        
        // 2. Hard Reset 
        rst_n = 0;
        #50;
        rst_n = 1;
        @(posedge clk);
        #1;
        $display("System Reset Complete. Sending Pipelined Matrices...");
        
        // =========================================================
        // PIPELINE SEQUENCE: Continuous staggering (No 0s in matrices)
        // Format: send_staggered_beat(A_r0, A_r1, A_r2, A_r3, B_c0, B_c1, B_c2, B_c3)
        // Note: Verilog natively converts negative integers to 6-bit 2's complement.
        // =========================================================
        
        // --- Matrix 1 Entering ---
        // T1: Head of M1 enters
        send_staggered_beat(  1,   0,   0,   0,     17,   0,   0,   0); 
        // T2
        send_staggered_beat( -2,  -5,   0,   0,    -21, -18,   0,   0); 
        // T3
        send_staggered_beat(  3,   6,   9,   0,     25,  22,  19,   0); 
        // T4: Middle diagonal of M1
        send_staggered_beat( -4,  -7, -10, -13,    -29, -26, -23, -20); 
        
        // --- Matrix 2 Entering & Matrix 1 Tail ---
        // T5: M2 head enters while M1 finishes
        send_staggered_beat( -1,   8,  11,  14,      2,  30,  27,  24); 
        // T6
        send_staggered_beat(  3,   9, -12, -15,     10,  -4, -31, -28); 
        // T7
        send_staggered_beat( -5, -11, -17,  16,    -18, -12,   6,  15); 
        // T8: M1 completely entered, M2 middle diagonal
        send_staggered_beat(  7,  13,  19,  25,     26,  20,  14,  -8); 
        
        // --- Matrix 2 Tail & Padding ---
        // T9
        send_staggered_beat(  0, -15, -21, -27,      0, -28, -22, -16); 
        // T10
        send_staggered_beat(  0,   0,  23,  29,      0,   0,  30,  24); 
        // T11: Last elements of M2 enter
        send_staggered_beat(  0,   0,   0, -31,      0,   0,   0, -14); 
        
        // --- Cool down / Drain remaining pipeline ---
        repeat (8) begin
            send_staggered_beat(0, 0, 0, 0,   0, 0, 0, 0);
        end

        $display("Simulation Complete.");
        $stop;
    end

    // --- Output Monitor ---
    // Streams the values directly from the physical output pins
    always @(posedge clk) begin
        if (ena) begin
            // Reconstruct the 12-bit output from the physical pins
            // uio_out[7:4] holds the top 4 bits, uo_out holds the bottom 8 bits
            $display("Time: %0t | System Output -> %0d", $time, $unsigned({uio_out[7:4], uo_out})); 
        end
    end

endmodule