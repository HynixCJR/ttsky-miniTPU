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
    input logic [ARRAY_SIZE-1:0][PSUM_WIDTH-1:0]    psum,

    // output buffers (12-bit signed)
    output logic [ARRAY_SIZE-1:0][OUTR_WIDTH-1:0]   outBuff
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin // reset all output buffers
            for (int cols = 0; cols < ARRAY_SIZE; cols++) begin
                outBuff[cols] <= '0;
            end
        end else if (flush) begin
            for (int cols = 0; cols < ARRAY_SIZE; cols++) begin
                // Create a temporaty wire to pass Icarus test 
                logic [PSUM_WIDTH-1:0] tmp_psum;
                tmp_psum = psum[cols];
                
                if (tmp_psum[13]) 
                    outBuff[cols] <= '0;                            // ReLU component, Set to zero is negative
                else if (tmp_psum[12]) 
                    outBuff[cols] <= 12'hFFF;                       // compressing if too high
                else 
                    outBuff[cols] <= tmp_psum[OUTR_WIDTH-1:0];      // otherwise set buffer to bottom 12 bits
            end
        end

    end

endmodule