/*
* Processing Element (MAC)
* Computes: c_reg += a_reg * b_reg when forward=1
* Designed for 4x4 systolic matrix multiplication
*/

`default_nettype none
//`include "params.vh"

module processing_element #(
    parameter DATA_WIDTH = 6,       // width of input operands
    parameter PSUM_WIDTH  = 14      // width of accumulator
)(
    input wire                      clk,
    input wire                      rst,    // GLOBAL RESET
    input wire                      clear,
    input wire                      forward, 
    input wire  [DATA_WIDTH-1:0]    a_in,
    input wire  [DATA_WIDTH-1:0]    b_in,
    output reg  [DATA_WIDTH-1:0]    a_reg,
    output reg  [DATA_WIDTH-1:0]    b_reg,
    output reg  [PSUM_WIDTH-1:0]     c_reg
);

// Combinational MAC datapath
wire [2*DATA_WIDTH-1:0] product;
wire [PSUM_WIDTH-1:0] product_sum;

assign product = a_in * b_in;           // Adder
assign product_sum = product + c_reg;   // Multiplier

// A/B Register
always @(posedge clk)  
begin: AB_Register
    if(rst) begin
        a_reg <= '0;
        b_reg <= '0;
    end else if (forward) begin
        // load A/B register from previous PEs
        a_reg <= a_in;
        b_reg <= b_in;
    end
end

// Accumulate Register
always @(posedge clk)  
begin: Accumulate_Register
    if(rst) begin
        c_reg <= '0;
    end 
    else if (clear) begin
        c_reg <= '0;
    end
    else if (forward) begin
        // Load the product_sum into c_reg
        c_reg <= product_sum;
    end
end

endmodule



