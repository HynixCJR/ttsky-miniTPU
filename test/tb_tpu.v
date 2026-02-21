`timescale 1ns/1ps

module tb_tt_um_4x4TPU();

    // --- Signals ---
    reg clk;
    reg rst_n;
    reg ena;
    
    // Inputs to TPU
    reg [7:0] ui_in;
    reg [7:0] uio_in;
    
    // Outputs from TPU
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    // --- Instantiate the Device Under Test (DUT) ---
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

    // --- Helper Task: Send 12-bit Data ---
    // Takes two 6-bit numbers (matA, matB) and packs them into the physical pins
    task send_io(input [5:0] a, input [5:0] b);
        begin
            ui_in  = {a, b[5:4]};       // Top 8 bits
            uio_in = {4'b0000, b[3:0]}; // Bottom 4 bits (on input half of bidirectional)
            @(posedge clk);
        end
    endtask

    // --- Main Simulation Sequence ---
    initial begin
        // Setup Waveform Dumping for GTKWave
        $dumpfile("tpu_sim.vcd");
        $dumpvars(0, tb_tt_um_4x4TPU);

        // 1. Initialize System
        clk = 0;
        ena = 1;
        ui_in = 0;
        uio_in = 0;
        
        // 2. Hard Reset (Hold low for a few cycles)
        rst_n = 0;
        #50;
        rst_n = 1;
        @(posedge clk);
        $display("System Reset Complete. Commencing Data Stream...");

        // 3. Stream Data (Simulating the Software Driver)
        // We will stream 5 continuous matrices to watch the pipeline fill up
        // Using simple numbers (1s and 2s) so we can easily track the math in the waveform
        repeat (20) begin // 20 beats = 5 full 4x4 matrices (4 beats each)
            
            // Beat 1 (first_buf)
            send_io(6'd1, 6'd2); 
            
            // Beat 2 (second_buf)
            send_io(6'd1, 6'd2);
            
            // Beat 3 (third_buf) - This triggers startSysArray early!
            send_io(6'd1, 6'd2);
            
            // Beat 4 (fourth_buf) - FSM wakes up and shifts array here
            send_io(6'd1, 6'd2);
            
        end

        // 4. Cool down / Drain remaining pipeline
        // Feed 0s to let the final math trickle out to the output buffers
        repeat (16) begin
            send_io(6'd0, 6'd0);
        end

        $display("Simulation Complete.");
        $stop;
    end

    // --- Optional Monitor (Prints output to console) ---
    // Reconstructs the 12-bit output from the physical pins
    wire [11:0] full_output;
    assign full_output = {uio_out[7:4], uo_out[7:0]};

    always @(posedge clk) begin
        if (rst_n && full_output != 0) begin
            $display("Time: %0t | Output Data: %d (0x%h)", $time, full_output, full_output);
        end
    end

endmodule