/*
Four Situations:

Select 0:
Load PE00 c_out to output buffer position 1
Load PE31 c_out to output buffer position 2
Load PE22 c_out to output buffer position 3
Load PE13 c_out to output buffer position 4

Select 1:
Load PE10 c_out to output buffer position 1
Load PE01 c_out to output buffer position 2
Load PE32 c_out to output buffer position 3
Load PE23 c_out to output buffer position 4

Select 2:
Load PE20 c_out to output buffer position 1
Load PE11 c_out to output buffer position 2
Load PE02 c_out to output buffer position 3
Load PE33 c_out to output buffer position 4

Select 3:
Load PE30 c_out to output buffer position 1
Load PE21 c_out to output buffer position 2
Load PE12 c_out to output buffer position 3
Load PE03 c_out to output buffer position 4

*/
module systolic_array_mux #(
    parameter DATA_WIDTH = 6,   // width of input operands
    parameter PSUM_WIDTH  = 14, // width of accumulator
    parameter ARRAY_SIZE = 4
) (
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

// reset MUX
always_comb begin
    // Default everything to 0
    for (int i = 0; i < ARRAY_SIZE; i++) begin
        for (int j = 0; j < ARRAY_SIZE; j++) begin
            PE_clear[i][j] = 1'b0;
        end
    end

    case (PE_clear_select)
        2'd0: begin
            PE_clear[0][0] = 1'b1;
            PE_clear[3][1] = 1'b1;
            PE_clear[2][2] = 1'b1;
            PE_clear[1][3] = 1'b1;
        end

        2'd1: begin
            PE_clear[1][0] = 1'b1;
            PE_clear[0][1] = 1'b1;
            PE_clear[3][2] = 1'b1;
            PE_clear[2][3] = 1'b1;
        end

        2'd2: begin
            PE_clear[2][0] = 1'b1;
            PE_clear[1][1] = 1'b1;
            PE_clear[0][2] = 1'b1;
            PE_clear[3][3] = 1'b1;
        end

        2'd3: begin
            PE_clear[3][0] = 1'b1;
            PE_clear[2][1] = 1'b1;
            PE_clear[1][2] = 1'b1;
            PE_clear[0][3] = 1'b1;
        end
    endcase
end

// c_out MUX
always_comb begin
    // Default everything to 0
    for (int i = 0; i < ARRAY_SIZE; i++) begin
        for (int j = 0; j < ARRAY_SIZE; j++) begin
            psum[i][j] = '0;
        end
    end

    case (c_out_select)
        2'd0: begin
            psum[0] = c_out[0][0];
            psum[1] = c_out[3][1];
            psum[2] = c_out[2][2];
            psum[3] = c_out[1][3];
        end

        2'd1: begin
            psum[0] = c_out[1][0];
            psum[1] = c_out[0][1];
            psum[2] = c_out[3][2];
            psum[3] = c_out[2][3];
        end

        2'd2: begin
            psum[0] = c_out[2][0];
            psum[1] = c_out[1][1];
            psum[2] = c_out[0][2];
            psum[3] = c_out[3][3];
        end

        2'd3: begin
            psum[0] = c_out[3][0];
            psum[1] = c_out[2][1];
            psum[2] = c_out[1][2];
            psum[3] = c_out[0][3];
        end
    endcase
end

endmodule