/*
 * Copyright (c) 2026 Albert Huang, Matthew Kong, Jiya Nair, Rivera Wijaya
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_4x4TPU (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  parameter DATA_WIDTH = 6,   // width of input operands

  // input buffers
  reg [DATA_WIDTH - 1:0] row0_buffer, row1_buffer, row2_buffer, row3_buffer;
  reg [DATA_WIDTH - 1:0] col0_buffer, col1_buffer, col2_buffer, col3_buffer;

  // output buffers
  reg [DATA_WIDTH * 2 - 1:0] output_buffer0, output_buffer1, output_buffer2, output_buffer3;

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, 1'b0};

endmodule
