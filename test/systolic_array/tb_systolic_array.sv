`default_nettype none
`timescale 1ns / 1ps

module systolic_array_tb;

    // ----------------------------------------
    // VCD Dump
    // ----------------------------------------
    initial begin
`ifdef VCD_PATH
        $dumpfile(`VCD_PATH);
`else
        $dumpfile("systolic_array_tb.vcd");
`endif
        $dumpvars(0, systolic_array_tb);
        #1;
    end

    // ----------------------------------------
    // Parameters
    // ----------------------------------------
    localparam DATA_WIDTH  = 6;
    localparam PSUM_WIDTH  = 14;
    localparam ARRAY_SIZE  = 4;

    // ----------------------------------------
    // Inputs
    // ----------------------------------------
    reg clk;
    reg rst;
    reg forward_systo;

    reg [ARRAY_SIZE-1:0][ARRAY_SIZE-1:0] PE_clear;

    reg [DATA_WIDTH-1:0] row0_val;
    reg [DATA_WIDTH-1:0] row1_val;
    reg [DATA_WIDTH-1:0] row2_val;
    reg [DATA_WIDTH-1:0] row3_val;

    reg [DATA_WIDTH-1:0] col0_val;
    reg [DATA_WIDTH-1:0] col1_val;
    reg [DATA_WIDTH-1:0] col2_val;
    reg [DATA_WIDTH-1:0] col3_val;

    // ----------------------------------------
    // Outputs
    // ----------------------------------------
    wire [ARRAY_SIZE-1:0][ARRAY_SIZE-1:0][PSUM_WIDTH-1:0] c_out;

    // ----------------------------------------
    // DUT
    // ----------------------------------------
    systolic_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .PSUM_WIDTH(PSUM_WIDTH),
        .ARRAY_SIZE(ARRAY_SIZE)
    ) dut (
        .clk(clk),
        .rst(rst),
        .forward_systo(forward_systo),
        .PE_clear(PE_clear),

        .row0_val(row0_val),
        .row1_val(row1_val),
        .row2_val(row2_val),
        .row3_val(row3_val),

        .col0_val(col0_val),
        .col1_val(col1_val),
        .col2_val(col2_val),
        .col3_val(col3_val),

        .c_out(c_out)
    );


endmodule