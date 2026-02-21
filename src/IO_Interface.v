// reads the input matrices from the input and bidirectional GPIO pins (ui_in and uio)
// saves the values in the matrices to their corresponding registers in front of the MXUs
// reads input from ui_in and uio as whole signed integers, and it does this 16 times 

// once the overall system is done we output the matrix to uo_out

module IO_interface(
    input wire clk,
    input wire ena,                     // global enable
    input wire rst_n,                   // active low

    // physical input/output pins
    input wire [7:0] ui_in,             // input GPIO
    input wire [7:0] uio_in,            // bidirectional GPIO; [3:0] for input, [7:4] for output
    output wire [7:0] uio_out,
    output wire [7:0] uo_out,           // output GPIO
    output wire [7:0] uio_oe,           // direction control

    // register buffers in front of PEs
    output wire [5:0] row0_val, row1_val, row2_val, row3_val,
    output wire [5:0] col0_val, col1_val, col2_val, col3_val,

    // output logic
    input wire [11:0] out0, out1, out2, out3, // output buffer registers

    // control for the systolic array
    output wire startSysArray,          // active high, pulse systolic array once all values are updated into registers
    input wire flush                    // signal that indicates when output buffers are flushed to
);

    assign uio_oe = 8'b11110000;        // set which bidirectional GPIO pins are being used for input and which for output

    // combining GPIO pins for input
    wire [11:0] raw_input_bus;
    assign raw_input_bus = {ui_in, uio_in[3:0]};
    

    handleInput I1(
        .clk(clk),
        .ena(ena),
        .rst_n(rst_n),
        .matA(raw_input_bus[11:6]),
        .matB(raw_input_bus[5:0]),
        .row0_val(row0_val),
        .row1_val(row1_val),
        .row2_val(row2_val),
        .row3_val(row3_val),
        .col0_val(col0_val), 
        .col1_val(col1_val),
        .col2_val(col2_val),
        .col3_val(col3_val),
        .startSysArray(startSysArray)
    );

    wire [11:0] output_bus;

    handleOutput O1(
        .clk(clk),
        .ena(ena),
        .rst_n(rst_n),
        .outGPIO(output_bus),
        .out0(out0),
        .out1(out1),
        .out2(out2),
        .out3(out3),
        .flush(flush)
    );

    assign uio_out = {output_bus[11:8], 4'b0000}; // for bidirectional output, set top 4 bits to output bus, and bottom 4 to 0s
    assign uo_out = output_bus[7:0];              // output pins can just be directly set

endmodule

module handleInput(
    input wire clk,
    input wire ena,                     // global enable
    input wire rst_n,                   // active low

    // physical input/output pins
    input wire [5:0] matA,              // integer for Matrix A
    input wire [5:0] matB,              // integer for Matrix B

    // register buffers in front of PEs
    output reg [5:0] row0_val, row1_val, row2_val, row3_val,
    output reg [5:0] col0_val, col1_val, col2_val, col3_val,

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
                    row0_val <= matA;
                    col0_val <= matB;
                    startSysArray <= 0;
                    state <= second_buf;
                end
                second_buf: begin
                    row1_val <= matA;
                    col1_val <= matB;
                    startSysArray <= 0;
                    state <= third_buf;
                end
                third_buf: begin
                    row2_val <= matA;
                    col2_val <= matB;
                    startSysArray <= 1;     // start the systolic array computations
                    state <= fourth_buf;
                end
                fourth_buf: begin
                    row3_val <= matA;
                    col3_val <= matB;
                    startSysArray <= 0;     // reset pulse
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

    output reg [11:0] outGPIO,          // 12 bit output GPIO
    input wire [11:0] out0, out1, out2, out3, // output buffer registers
    input wire flush
);

    reg [2:0] state;                    // states for FSM
    parameter delay_one = 3'd0;         // on VERY FIRST two clock cycles, delay by two cycles, THEN start reading
    parameter delay_two = 3'd1;
    parameter first_buf = 3'd2;         // first_buf = output from first output buffer, second_buf = output from second output buffer, etc.
    parameter second_buf = 3'd3;
    parameter third_buf = 3'd4;
    parameter fourth_buf = 3'd5;

    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // reset everything
            outGPIO <= 12'd0;           // reset output GPIO to 0
            state <= delay_one;
        end
        else if (ena) begin
            // by default just send 0s to output GPIO
            // assuming we haven't started a send loop
            if (state == first_buf) outGPIO <= 12'd0;

            case(state)
                delay_one: begin       // DELAY TWO CLOCK CYCLES AT THE BEGINNING before reading
                    outGPIO <= 12'd0;
                    if (flush) state <= delay_two;
                end
                delay_two: begin
                    outGPIO <= 12'd0;
                    state <= first_buf;
                end
                first_buf: begin
                    outGPIO <= out0;
                    state <= second_buf;
                end
                second_buf: begin
                    outGPIO <= out1;
                    state <= third_buf;
                end
                third_buf: begin
                    outGPIO <= out2;
                    state <= fourth_buf;
                end
                fourth_buf: begin
                    outGPIO <= out3;
                    state <= first_buf;
                end
            endcase

        end
    end

endmodule