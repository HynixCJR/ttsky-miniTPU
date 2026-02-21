/*
 * Copyright (c) 2026 Albert Huang, Matthew Kong, Jiya Nair, Rivera Wijaya
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_4x4TPU#(
    parameter DATA_WIDTH = 6,  // width of input operands
    parameter PSUM_WIDTH = 14, // width of accumulator
    parameter OUTR_WIDTH = 12, // width of output buffer
    parameter ARRAY_SIZE = 4   // width of systolic array
)(
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);


// =========================================
// WIRE
// =========================================

// io_interface_inst Wire==========
// Output
logic [DATA_WIDTH-1:0] row0_val, row1_val, row2_val, row3_val;  // Send to systo_array_inst
logic [DATA_WIDTH-1:0] col0_val, col1_val, col2_val, col3_val;  // Send to systo_array_inst

logic startSysArray;                                            // Unused

// output_buffer_inst Wires========
// Output
logic [ARRAY_SIZE-1:0][OUTR_WIDTH-1:0] outBuff;               // Send to io_interface_inst

// systo_fsm_inst Wires============
// Output
logic forward_systo;                                            // Send to systo_array_inst
logic clear_systo;                                              // Send to systo_mux_inst
logic flush_systo;                                              // Send to output_buffer_inst
logic [1:0] PE_clear_select;                                    // Send to systo_mux_inst
logic [1:0] c_out_select;                                       // Send to systo_mux_inst

// systolic_array_inst Wires========
// Output 
logic [PSUM_WIDTH-1:0] c_out [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];  // Send to systo_mux_inst

// systo_mux_inst Wires=============
// Output
logic [ARRAY_SIZE-1:0][ARRAY_SIZE-1:0] PE_clear ;                // Send to systo_array_inst
logic [ARRAY_SIZE-1:0][PSUM_WIDTH-1:0] psum;                // Send to output_buffer_inst


// =========================================
// I/O
// =========================================

/*
module IO_interface(
    input wire clk,
    input wire ena,                     // global enable
    input wire rst_n,                   // active low

    // physical input/output pins
    input wire [7:0] ui_in,             // input GPIO
    input wire [7:0] uio_in,            // bidirectional GPIO; [3:0] for input, [7:4] for output
    output wire [7:0] uio_out,
    output wire [7:0] uo_out,           // output GPIO
    output wire [7:0] uio_oe,           // direction control

    // register buffers in front of PEs
    output wire [5:0] row0_val, row1_val, row2_val, row3_val,
    output wire [5:0] col0_val, col1_val, col2_val, col3_val,

    // output logic
    input wire [11:0] out0, out1, out2, out3, // output buffer registers

    // control for the systolic array
    output wire startSysArray           // active high, pulse systolic array once all values are updated into registers
);
*/

// io_interface_inst=============
IO_interface io_interface_inst (
    .clk(clk),
    .ena(ena),
    .rst_n(rst_n),

    .ui_in(ui_in),
    .uio_in(uio_in),

    .out0(outBuff[0]),
    .out1(outBuff[1]),
    .out2(outBuff[2]),
    .out3(outBuff[3]),

    // Output
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

    .startSysArray(startSysArray),
    .flush(flush_systo)
);

/*
module output_buffer(
    // finished 14-bit signed psums from PEs (muxed outside of this module)
    input logic                     clk,
    input logic                     rst,    // GLOBAL RESET
    input logic                     flush,  // flush pulse from systo fsm
    input logic [PSUM_WIDTH-1:0]    psum[0:ARRAY_SIZE-1],

    // output buffers (12-bit signed)
    output logic [OUTR_WIDTH-1:0]   outBuff[0:ARRAY_SIZE-1]
);
*/

// output_buffer_inst============
output_buffer #(
    .DATA_WIDTH(DATA_WIDTH),
    .PSUM_WIDTH(PSUM_WIDTH),
    .OUTR_WIDTH(OUTR_WIDTH),
    .ARRAY_SIZE(ARRAY_SIZE)
) output_buffer_inst (
    .clk(clk),
    .rst(!rst_n),

    .flush(flush_systo),
    .psum(psum),
    // Output
    .outBuff(outBuff)
);


// =========================================
// Systolic Array
// =========================================

/*
module systolic_array_fsm(
    input logic                     clk,            
    input logic                     rst,                // Global reset
    input logic                     ena,                // Starts the Systolic Array

    output logic                    forward_pulse,      // Send forward Pulse to all PE
    output logic                    clear,              // Clear the selected PE 
    output logic                    flush,              // Signal to store psum into output buffer
    output logic [1:0]              PE_clear_select,    // Select which PE to reset
    output logic [1:0]              c_out_select        // Select which c_out to store in output buffer
);
*/
// systo_fsm_inst==================
systolic_array_fsm systo_fsm_inst (
    .clk(clk),
    .rst(!rst_n),
    .ena(startSysArray), // editor's note: i changed this to startSysArray, otherwise it would start shifting on the second clock cycle after chip powered on

    // Output
    .forward_pulse(forward_systo),
    .clear(clear_systo),
    .flush(flush_systo),
    .PE_clear_select(PE_clear_select),
    .c_out_select(c_out_select)
);

/*
module systolic_array (
    input wire                          clk,
    input wire                          rst,                // Global reset
    
    input wire                          forward_systo,      // From Systolic Array FSM, connected to all PE
        
    input wire                          PE_clear [0:ARRAY_SIZE - 1][0:ARRAY_SIZE - 1],
                                                            // clear signal for all PEs

    // A/BInput from Input Buffer
    input wire [DATA_WIDTH - 1:0]       row0_val,
    input wire [DATA_WIDTH - 1:0]       row1_val,
    input wire [DATA_WIDTH - 1:0]       row2_val,
    input wire [DATA_WIDTH - 1:0]       row3_val,

    input wire [DATA_WIDTH - 1:0]       col0_val,
    input wire [DATA_WIDTH - 1:0]       col1_val,
    input wire [DATA_WIDTH - 1:0]       col2_val,
    input wire [DATA_WIDTH - 1:0]       col3_val,

    // c_out for each PEs
    output wire [PSUM_WIDTH-1: 0] c_out [0:ARRAY_SIZE - 1][0:ARRAY_SIZE - 1]
);
*/

// systo_array_inst=================
systolic_array #(
    .DATA_WIDTH(DATA_WIDTH),
    .PSUM_WIDTH(PSUM_WIDTH),
    .ARRAY_SIZE(ARRAY_SIZE)
) systo_array_inst (
    .clk(clk),
    .rst(!rst_n),

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

    // Output
    .c_out(c_out)
);

/*
module systolic_array_mux(
    input logic                     clk,
    input logic                     rst,                    // Global reset

    input logic                     clear,                  // Signal to clear selected PE
    input logic [1:0]               PE_clear_select,        // Select which PEs to clear
    input logic [PSUM_WIDTH-1: 0]   c_out [0:ARRAY_SIZE - 1][0:ARRAY_SIZE - 1],
                                                            // c_out wire for all PEs
    input logic [1:0]               c_out_select,           // Select which c_out send to ReLU

    output logic                    PE_clear [0:ARRAY_SIZE - 1][0:ARRAY_SIZE - 1],
                                                            // clear wire for all PEs
    output logic [PSUM_WIDTH-1: 0]  psum [0:ARRAY_SIZE - 1] // selected c_out, send to ReLU
);
*/
// systo_mux_inst==================
systolic_array_mux #(
    .DATA_WIDTH(DATA_WIDTH),
    .PSUM_WIDTH(PSUM_WIDTH),
    .ARRAY_SIZE(ARRAY_SIZE)
) systo_mux_inst (
    .clk(clk),
    .rst(!rst_n),

    .clear(clear_systo),
    .PE_clear_select(PE_clear_select),
    .c_out(c_out),
    .c_out_select(c_out_select),

    // Output
    .PE_clear(PE_clear),
    .psum(psum)
);

endmodule
