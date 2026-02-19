module systolic_array#(
    parameter DATA_WIDTH = 6,
    parameter ARRAY_SIZE = 4
) (
    input wire                          clk,
    input wire                          rstn,
    input wire                          forward_systo,

    input wire [DATA_WIDTH - 1:0]       row0_val,
    input wire [DATA_WIDTH - 1:0]       row1_val,
    input wire [DATA_WIDTH - 1:0]       row2_val,
    input wire [DATA_WIDTH - 1:0]       row3_val,

    input wire [DATA_WIDTH - 1:0]       col0_val,
    input wire [DATA_WIDTH - 1:0]       col1_val,
    input wire [DATA_WIDTH - 1:0]       col2_val,
    input wire [DATA_WIDTH - 1:0]       col3_val,

    // I'm currently outputting the c_out for all PEs
    // bc I'm not entirely sure how it's being used later
    // Can fix it later on
        // editor's note: i changed this to bit width 14 instead of 6
        // bc c_out is the PE psum, also i changed to wire instead of reg
        // bc PE modules continuously drive these
    output wire [DATA_WIDTH * 2 + 1: 0] c_out [0:ARRAY_SIZE - 1][0:ARRAY_SIZE - 1]

);

    /* Systolic array
             |      |      |      |
             V      V      V      V
        -->PE11-->PE12-->PE13-->PE14-->
             |      |      |      |
             V      V      V      V
        -->PE21-->PE22-->PE23-->PE24-->
             |      |      |      |
             V      V      V      V
        -->PE31-->PE32-->PE33-->PE34-->
             |      |      |      |
             V      V      V      V
        -->PE41-->PE42-->PE43-->PE44-->
             |      |      |      |
             V      V      V      V

    */


    // 2D array (including output wires here)
    wire [DATA_WIDTH - 1: 0] matA_wires [0:ARRAY_SIZE - 1][0:ARRAY_SIZE]; // [rows][cols]
    wire [DATA_WIDTH - 1: 0] matB_wires [0:ARRAY_SIZE][0:ARRAY_SIZE - 1]; // [rows][cols]

    // Set up the beginning rows and cols
    // These values will change as inputs are continuously added
    assign matA_wires[0][0] = row0_val;
    assign matA_wires[1][0] = row1_val;
    assign matA_wires[2][0] = row2_val;
    assign matA_wires[3][0] = row3_val;

    assign matB_wires[0][0] = col0_val;
    assign matB_wires[0][1] = col1_val;
    assign matB_wires[0][2] = col2_val;
    assign matB_wires[0][3] = col3_val;
    

    genvar rows, cols;

    generate
        for (rows = 0; rows < ARRAY_SIZE; rows = rows + 1) begin
            for (cols = 0; cols < ARRAY_SIZE; cols = cols + 1) begin
                processing_element u1 (
                    .clk(clk),
                    .rst(!rstn),
                    .forward(forward_systo), // am not sure if this is the enable signal
                    .a_in(matA_wires[rows][cols]),
                    .b_in(matB_wires[rows][cols]),
                    .a_reg(matA_wires[rows][cols + 1]),
                    .b_reg(matB_wires[rows + 1][cols]),
                    .c_reg(c_out[rows][cols])
                );
            end        
        end
    endgenerate



endmodule