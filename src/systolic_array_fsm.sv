/*
* Systolic Array FSM
* Two process
* 4 States:     
    IDLE,
    UPDATE,
    FLUSH,
    CLEAR
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
    parameter PSUM_WIDTH  = 14  // width of accumulator
)(
    input logic                     clk,            
    input logic                     rst,                // Global reset
    input logic                     ena,                // Starts the Systolic Array

    output logic                    forward_pulse,      // Send forward Pulse to all PE
    output logic                    clear,              // Clear the selected PE 
    output logic                    flush,              // Signal to store psum into output buffer
    output logic [1:0]              PE_clear_select,    // Select which PE to reset
    output logic [1:0]              c_out_select        // Select which c_out to store in output buffer
);

// Define 4 states
typedef enum logic [2:0] {
    INIT,
    UPDATE,
    FLUSH,
    CLEAR,
    IDLE
} systo_state_t;
systo_state_t curr_state, next_state;


logic [1:0] select_index;           // 0 to 3
logic [1:0] first_matrix_counter;   // 0 to 3
logic is_first_matrix;              // T/F

//==FSM==================================================

// State Register:
always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        curr_state <= INIT;
    end
    else begin
        curr_state <= next_state;
    end
end

// Next-state logic:
always_comb begin
    next_state = curr_state;

    case (curr_state)
        INIT:
            if (ena)
                next_state = UPDATE;

        UPDATE:
            next_state = FLUSH;

        FLUSH:
            next_state = CLEAR;

        CLEAR:
            next_state = IDLE;

        IDLE:
            next_state = UPDATE;
    endcase
end

// Select Counter:
always_ff @(posedge clk or posedge rst) begin
    if (rst)
        select_index <= 2'd1;
    else if (curr_state == CLEAR)
        select_index <= select_index + 1'b1;
end

// First matrix Counter: (Do not flush or clear the first matrix)
always_ff @(posedge clk or posedge rst) begin
    if (rst)
        first_matrix_counter <= 2'd0;
    else if (curr_state == CLEAR)
        first_matrix_counter <= first_matrix_counter + 1'b1;
end

// is_first_matrix
always_ff @(posedge clk or posedge rst) begin
    if (rst)
        is_first_matrix <= 1'b1;
    else if (first_matrix_counter == 2'd3)
        is_first_matrix <= 1'b0;
end

// Output Wires ============================
always_comb begin
    forward_pulse = '0;
    flush = '0;
    clear = '0;
    if(curr_state == UPDATE) 
        forward_pulse = 1'b1;       // forward_pulse
    if(!is_first_matrix) begin
        case(curr_state)                            
            FLUSH:      flush = 1'b1;               // flush pulse
            CLEAR:      clear = 1'b1;               // clear pulse
            default: ;
        endcase
    end
end

assign PE_clear_select = select_index;          // PE_clear_select
assign c_out_select = select_index;             // c_out_select

/*
always_ff @(posedge clk or posedge rst) begin   // c_out_select
    if (rst)
        c_out_select <= 2'd0;
    else if (curr_state == FLUSH)
        c_out_select <= select_index;
end
*/
endmodule
