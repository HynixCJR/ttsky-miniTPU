/*
Five States:

IDLE:

FLUSH1:
Load PE11 c_out to output buffer position 1
Load PE42 c_out to output buffer position 2
Load PE33 c_out to output buffer position 3
Load PE24 c_out to output buffer position 4

FLUSH2:
Load PE21 c_out to output buffer position 1
Load PE12 c_out to output buffer position 2
Load PE43 c_out to output buffer position 3
Load PE34 c_out to output buffer position 4

FLUSH3:
Load PE31 c_out to output buffer position 1
Load PE22 c_out to output buffer position 2
Load PE13 c_out to output buffer position 3
Load PE44 c_out to output buffer position 4

FLUSH4:
Load PE41 c_out to output buffer position 1
Load PE32 c_out to output buffer position 2
Load PE23 c_out to output buffer position 3
Load PE14 c_out to output buffer position 4

*/
module systolic_array_fsm #(
    parameter DATA_WIDTH = 6,   // width of input operands
    parameter PSUM_WIDTH  = 14, // width of accumulator
    parameter ARRAY_SIZE = 4
) (
    input logic                     clk,
    input logic                     rst,                // Global reset

    
    
    input logic [PSUM_WIDTH-1: 0]   c_out [0:ARRAY_SIZE - 1][0:ARRAY_SIZE - 1],
                                                        // c_out for all PEs


    output wire [PSUM_WIDTH-1: 0] psum [0:ARRAY_SIZE - 1]


);

// reset MUX
always_comb begin
    case (sel)
        2'b01: out = a;
        2'b10: out = b;
        default: out = 2'b00;       // Covers all other cases
    endcase
end

// c_out MUX



endmodule