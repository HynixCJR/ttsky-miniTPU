// this module essentially just takes the 14 bit number output, applies ReLU, and gets rid of the 13th bit to produce a 12 bit number
// saves all four psums through ReLU into the four output buffers
// all of this happens immediately because it is simply non-blocking

module output_buffer#(
    parameter DATA_WIDTH = 6,   // width of input operands
    parameter PSUM_WIDTH = 14,  // width of accumulator
    parameter OUTR_WIDTH = 12,  // width of output buffer
    parameter ARRAY_SIZE = 4    // width of systolic array
)(
    // finished 14-bit signed psums from PEs (muxed outside of this module)
    input logic                     clk,
    input logic                     rst,    // GLOBAL RESET
    input logic                     flush,  // flush pulse from systo fsm
    input logic [PSUM_WIDTH-1:0]    psum[0:ARRAY_SIZE-1],

    // output buffers (12-bit signed)
    output logic [OUTR_WIDTH-1:0]   outBuff[0:ARRAY_SIZE-1]
);

    always_ff @(posedge flush or posedge rst) begin
        for (int i = 0; i < 4; i++) begin
            if (psum[i][13]) outBuff[i] <= 12'd0;           // ReLU component
            else if (psum[i][12]) outBuff[i] <= 12'hFFF;    // compressing if too high
            else outBuff[i] <= psum[i][11:0];                // otherwise set buffer to bottom 12 bits
        end
    end

endmodule