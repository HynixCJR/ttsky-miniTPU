/*
* Systolic Array FSM
* One process
* 8 States: IDLE and 7 FLUSH state 
* 
* Next State when receive a forward_systo = 1 signal
* NOTE: Must be high for only one clock period
* Maybe add adge detection later
*
* OUTPUT the curr_state_systo signal to systo_MUX to 
* select the correct PE to flush into output buffer
*/

`default_nettype none
//`include "params.vh"

module systolic_array_fsm#(
    parameter DATA_WIDTH = 6,   // width of input operands
    parameter ACC_WIDTH  = 14   // width of accumulator
)(
    input wire                      clk,
    input wire                      rst,    // reset PE, not global reset?
    input wire                      forward_systo , 
    input logic  [DATA_WIDTH-1:0]   a_in,
    output logic [2:0]              curr_state_systo 
);

// Define 8 states
typedef enum logic [2:0] {
    IDLE,
    FLUSH_1,
    FLUSH_2,
    FLUSH_3,
    FLUSH_4,
    FLUSH_5,
    FLUSH_6,
    FLUSH_7
} systo_state_t;
systo_state_t curr_state;

// State Register
always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        curr_state <= IDLE;
    end
    // Next State Logic
    else if (forward_systo) begin
        case (curr_state)
            IDLE:       curr_state <= FLUSH_1;
            FLUSH_1:    curr_state <= FLUSH_2;
            FLUSH_2:    curr_state <= FLUSH_3;
            FLUSH_3:    curr_state <= FLUSH_4;
            FLUSH_4:    curr_state <= FLUSH_5;
            FLUSH_5:    curr_state <= FLUSH_6;
            FLUSH_6:    curr_state <= FLUSH_7;
            FLUSH_7:    curr_state <= FLUSH_1;
        endcase
    end
end

// Output Register
// NOTE: The state update is reflected on the next clock cycle!!!!!
always_ff @(posedge clk or posedge rst) begin
    if (rst)
        curr_state_systo <= 1'b0;
    else
        curr_state_systo <= curr_state;
end

// Combinational Output:
// assign curr_state_systo = curr_state;

endmodule
