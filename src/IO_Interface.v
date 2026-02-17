// reads the input matrices from the input and bidirectional GPIO pins (ui_in and uio)
// saves the values in the matrices to their corresponding registers in front of the MXUs
// reads input from ui_in and uio as whole signed integers, and it does this 16 times 

// once the overall system is done we output the matrix to uo_out

module IO_interface(
    input wire clk,
    input wire ena,                     // global enable
    input wire rst_n,                   // active low

    // physical input/output pins
    input wire [7:0] ui_in,             // integer for Matrix A
    input wire [7:0] uio,               // integer for Matrix B
    output reg [7:0] uo_out,            // output matrix of the overall system

    // register buffers in front of PEs
    output reg [7:0] row0_val, row1_val, row2_val, row3_val,
    output reg [7:0] col0_val, col1_val, col2_val, col3_val,

    // control for the systolic array
    output reg startSysArray            // active high, pulse systolic array once all values are updated into registers
)
    handleInput I1(
        .clk(clk),
        .ena(ena),
        .rst_n(rst_n),
        .ui_in(ui_in),
        .uio(uio),
        .row0_val(row0_val),
        .row1_val(row1_val),
        .row2_val(row2_val),
        .row3_val(row3_val),
        .col0_val(col0_val), 
        .col1_val(col1_val),
        .col2_val(col2_val),
        .col3_val(col3_val),
        .startSysArray(startSysArray)
    )

    handleOutput O1(

    )

endmodule

module handleInput(
    input wire clk,
    input wire ena,                     // global enable
    input wire rst_n,                   // active low

    // physical input/output pins
    input wire [7:0] ui_in,             // integer for Matrix A
    input wire [7:0] uio,               // integer for Matrix B

    // register buffers in front of PEs
    output reg [7:0] row0_val, row1_val, row2_val, row3_val,
    output reg [7:0] col0_val, col1_val, col2_val, col3_val,

    // control for the systolic array
    output reg startSysArray            // active high, pulse systolic array once all values are updated into registers

);

    reg [1:0] state;                    // 0 = first buffer filled, 1 = second buffer filled, etc.
                                        // 4 = enable the PEs
    // labels for FSM states
    parameter first_buf = 2'd0;         // first_buf = load first row/col, second_buf = load second row/col, etc.
    parameter second_buf = 2'd1;
    parameter third_buf = 2'd2;
    parameter fourth_buf = 2'd3;        // on last buffer load, start the array

    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // reset everything
            state <= 0;
            startSysArray <= 0;
        end
        else if (ena) begin
            // by default, just load the buffers and don't enable startSysArray
            startSysArray <= 0;

            case (state)
                first_buf: begin
                    row0_val <= ui_in;
                    col0_val <= uio;
                    startSysArray <= 0;     // reset pulse
                    state <= second_buf;
                end
                second_buf: begin
                    row1_val <= ui_in;
                    col1_val <= uio;
                    state <= third_buf;
                end
                third_buf: begin
                    row2_val <= ui_in;
                    col2_val <= uio;
                    state <= fourth_buf;
                end
                fourth_buf: begin
                    row3_val <= ui_in;
                    col3_val <= uio;
                    startSysArray <= 1;     // start the systolic array computations
                    state <= first_buf;     // reset back to first state
                end
            endcase
        end
    end
endmodule

module handleOutput(
    input wire clk,
    input wire ena,                     // global enable
    input wire rst_n,                   // active low

    
)

endmodule