// this module essentially just takes the 14 bit number output, applies ReLU, and gets rid of the 13th bit to produce a 12 bit number
// saves all four psums through ReLU into the four output buffers
// all of this happens immediately because it is simply non-blocking

module ReLU(
    // finished 14-bit signed psums from PEs (muxed outside of this module)
    input wire [13:0] psum0, psum1, psum2, psum3,

    // output buffers (12-bit unsigned)
    output reg [11:0] outBuff0, outBuff1, outBuff2, outBuff3
);

    always@(*) begin
        // buffer 0
        if (psum0[13]) outBuff0 = 12'd0;           // ReLU component
        else if (psum0[12]) outBuff0 = 12'hFFF;    // compressing if too high
        else outBuff0 = psum0[11:0];               // otherwise set buffer to bottom 12 bits

        // buffer 1
        if (psum1[13]) outBuff1 = 12'd0;           // ReLU component
        else if (psum1[12]) outBuff1 = 12'hFFF;    // compressing if too high
        else outBuff1 = psum1[11:0];               // otherwise set buffer to bottom 12 bits

        // buffer 2
        if (psum2[13]) outBuff2 = 12'd0;           // ReLU component
        else if (psum2[12]) outBuff2 = 12'hFFF;    // compressing if too high
        else outBuff2 = psum2[11:0];               // otherwise set buffer to bottom 12 bits

        // buffer 3
        if (psum3[13]) outBuff3 = 12'd0;           // ReLU component
        else if (psum3[12]) outBuff3 = 12'hFFF;    // compressing if too high
        else outBuff3 = psum3[11:0];               // otherwise set buffer to bottom 12 bits
    end

endmodule