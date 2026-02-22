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

    // ----------------------------------------
    // Clock Generation
    // ----------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;   // 100MHz clock

    // ----------------------------------------
    // Stimulus
    // ----------------------------------------
    initial begin
        // Initialize
        rst = 1;
        forward_systo = 0;
        PE_clear = '{default: 1'b0};

        row0_val = 0;
        row1_val = 0;
        row2_val = 0;
        row3_val = 0;

        col0_val = 0;
        col1_val = 0;
        col2_val = 0;
        col3_val = 0;

        // Release reset
        #20;
        rst = 0;

        // Example input stream
        forward_systo = 1;

        row0_val = 6'd1;
        row1_val = 6'd2;
        row2_val = 6'd3;
        row3_val = 6'd4;

        col0_val = 6'd1;
        col1_val = 6'd1;
        col2_val = 6'd1;
        col3_val = 6'd1;

        #10;

        row0_val = 6'd5;
        row1_val = 6'd6;
        row2_val = 6'd7;
        row3_val = 6'd8;

        col0_val = 6'd2;
        col1_val = 6'd2;
        col2_val = 6'd2;
        col3_val = 6'd2;

        #200;

        $finish;
    end

endmodule