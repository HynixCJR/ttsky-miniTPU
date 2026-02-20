// this module essentially just takes the 14 bit number output, applies ReLU, and gets rid of the 13th bit to produce a 12 bit number
// saves all four psums through ReLU into the four output buffers
// all of this happens immediately because it is simply non-blocking

module output_buffer(
    // finished 14-bit signed psums from PEs (muxed outside of this module)
    input logic                     clk,
    input logic                     rst,    // GLOBAL RESET
    input logic                     flush,  // flush pulse from systo fsm
    input logic [13:0]              psum[3:0],

    // output buffers (12-bit unsigned)
    output logic [11:0]             outBuff[3:0]
);

    always_ff @(posedge flush or posedge rst) begin
        for (int i = 0; i < 4; i++) begin
            if (psum[i][13]) outBuff[i] <= 12'd0;           // ReLU component
            else if (psum[i][12]) outBuff[i] <= 12'hFFF;    // compressing if too high
            else outBuff[i] <= psum[i][11:0];                // otherwise set buffer to bottom 12 bits
        end
    end

endmodule