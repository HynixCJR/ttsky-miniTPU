/* Testbench for IO Interface
Cases to test for
1. Does rstn work
2. Does ena work
3. Does startSysArray turn on in the 3rd buffer cycle?
4. What happens if we turn ena off, then on while rstn is high?
5. positive and negative numbers
6. What happens if we fill in the output ports of uio?
7. what is rstn becomes low when startSysArray becomes high?
*/

`timescale 1ns / 1ps

module tb_IO;
    // Inputs
    reg clock;
    reg ena;
    reg rst_n;
    reg flush;
    reg [7:0] ui_in;
    reg [7:0] uio_in;
    reg [11:0] out0, out1, out2, out3;

    // Outputs
    wire startSysArray;
    wire [7:0] uio_out;
    wire [7:0] uo_out;
    wire [7:0] uio_oe;
    wire [5:0] row0_val, row1_val, row2_val, row3_val;
    wire [5:0] col0_val, col1_val, col2_val, col3_val;

    // Module
    IO_interface dut (
        .clk(clock),
        .ena(ena),
        .rst_n(rst_n),
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
        .flush(flush),
        .startSysArray(startSysArray)
    );

    // Clock generation:
    parameter CLOCK_PERIOD = 10;
    initial begin
        clock <= 0;
        rst_n <= 1;
        ena <= 1;
        flush <= 0;
        #(2 * CLOCK_PERIOD);
    end

    always @ (*)
    begin: Clock_Generator
       #(CLOCK_PERIOD/2) clock <= !clock;
    end
    
    // This is to check if the output matches what we expect
    wire [11:0] output_check;
    assign output_check = {uio_out[7:4], uo_out};

    // Input for matrix A will be ui_in[7:2]
    // input for matrix B will be {ui_in[1:0], uio_in[3:0]}
    initial begin
        // ========INPUT TESTING=============
        // reset
        rst_n <= 0;
        #CLOCK_PERIOD rst_n <= 1;

        // LOAD CYCLE 1
        // row0 and col0 will be h3F and h10
        ui_in <= 8'hFD;
        uio_in <= 8'h00;
        #CLOCK_PERIOD;
        // row1-3 and col1-3 will be all 0s
        ui_in <= 8'h00;
        uio_in <= 8'h00;
        #CLOCK_PERIOD;
        ui_in <= 8'h00; // by this time startSysArray will have gone high
        uio_in <= 8'h00;
        #CLOCK_PERIOD;
        ui_in <= 8'h00;
        uio_in <= 8'h00;
        #CLOCK_PERIOD;

        // LOAD CYCLE 2
        // row0 = 101011, col0 = 000011
        ui_in <= 8'hAC;
        uio_in <= 8'h03;
        #CLOCK_PERIOD;
        // row1 = 000001, col1 = 000010
        ui_in <= 8'h04;
        uio_in <= 8'h02;
        #CLOCK_PERIOD;
        //row2-3 and col2-3 are zeroes
        ui_in <= 8'h00; 
        uio_in <= 8'h00;
        #CLOCK_PERIOD;
        ui_in <= 8'h00;
        uio_in <= 8'h00;
        #CLOCK_PERIOD;

        // LOAD CYCLE 3
        // row0 = 110010 col0 = 001000
        ui_in <= 8'hC8;
        uio_in <= 8'h08;
        #CLOCK_PERIOD;
        // row1 = 000001 col1 = 000001
        ui_in <= 8'h04;
        uio_in <= 8'h01;
        #CLOCK_PERIOD;
        // row2 = 001011 col2 = 100001
        ui_in <= 8'h2E;
        uio_in <= 8'h01;
        #CLOCK_PERIOD;
        // row3, col3 are zeroes
        ui_in <= 8'h00;
        uio_in <= 8'h00;
        #CLOCK_PERIOD;

        // LOAD CYCLE 4
        // row0 = 111111 col0 = 111111
        ui_in <= 8'hFF;
        uio_in <= 8'h0F;
        #CLOCK_PERIOD;
        // row1 = 000011 col1 = 011100
        ui_in <= 8'h0D;
        uio_in <= 8'h0C;
        #CLOCK_PERIOD;
        // row2 = 111000 col2 = 000111
        ui_in <= 8'hE0;
        uio_in <= 8'h07;
        #CLOCK_PERIOD;
        // row3 = 111101 col3 = 101111
        ui_in <= 8'hF6;
        uio_in <= 8'h0F;
        #CLOCK_PERIOD;
        
        // LOAD CYCLE 5
        // row0 = 101010 col0 = 11100
        ui_in <= 8'hAB;
        uio_in <= 8'h0C;
        #CLOCK_PERIOD;
        // row1 = 010111 col1 = 110011
        ui_in <= 8'h5F;
        uio_in <= 8'h03;
        #CLOCK_PERIOD;
        // row2 = 100010 col2 = 000011
        ui_in <= 8'h88;
        uio_in <= 8'h03;
        rst_n <= 0;
        #CLOCK_PERIOD;
        // Here we reset

        // LOAD CYCLE 6
        // row0 = 011110 col0 = 100001
        ui_in <= 8'h7A;
        uio_in <= 8'h01;
        rst_n <= 1;
        #CLOCK_PERIOD;
        // row1 = 011111 col1 = 101010
        ui_in <= 8'h7E;
        uio_in <= 8'h0A;
        #CLOCK_PERIOD;
        // row2 = 000100 col2 = 101111
        ui_in <= 8'h12;
        uio_in <= 8'h0F;
        #CLOCK_PERIOD;
        // row3 = 100110 col3 = 010011
        ui_in <= 8'h99;
        uio_in <= 8'h03;
        #CLOCK_PERIOD;
        
        // LOAD CYCLE 7
        // row0 = 010110 col0 = 111010
        ui_in <= 8'h5B;
        uio_in <= 8'h0A;
        #CLOCK_PERIOD;
        // row1 = 000100 col1 = 010001
        ena <= 0; // enable goes off, but reset is high
        ui_in <= 8'h11;
        uio_in <= 8'h01;
        #CLOCK_PERIOD;
        // row2 = 000000 col2 = 000001
        ena <= 1; 
        ui_in <= 8'h00;
        uio_in <= 8'h01;
        #CLOCK_PERIOD;
        // Now we are going to try bits that are too wide
        // row3 = 11101010 col3 = 00101011
        // Essentially, see what happens when we try to pass in bits to output ports
        ui_in <= 8'hEA;
        uio_in <= 8'h2B;
        #CLOCK_PERIOD;
        

        // ENDING INPUT TESTING
        ui_in <= 8'h00;
        uio_in <= 8'h00;
        #CLOCK_PERIOD;
        ui_in <= 8'h00;
        uio_in <= 8'h00;
        #CLOCK_PERIOD;

        //=========OUTPUT TESTING=========
        // Here, we mostly just want to test flush 
        rst_n <= 0;
        #(2*CLOCK_PERIOD);
        rst_n <= 1;
        flush <= 1;
        out0 <= 12'h8D3;
        out1 <= 12'h023;
        out2 <= 12'h111;
        out3 <= 12'h92C;
        #CLOCK_PERIOD;
        flush <= 0;
        #(15 * CLOCK_PERIOD);
        flush <= 1;
        out0 <= 12'h123;
        out1 <= 12'hFFF;
        out2 <= 12'h8A2;
        out3 <= 12'h106;
        #CLOCK_PERIOD; 
        flush <= 0;
        #(2 * CLOCK_PERIOD);
        flush <= 1;
        #CLOCK_PERIOD;
        flush <= 0;

    end

endmodule