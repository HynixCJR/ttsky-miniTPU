// Maybe make the reset into individual nets
// 

module systolic_array #(
    parameter DATA_WIDTH = 6,   // width of input operands
    parameter PSUM_WIDTH  = 14, // width of accumulator
    parameter ARRAY_SIZE = 4
) (
    input wire                          clk,
    input wire                          rst,                // Global reset
    
    input wire                          forward_systo,      // From Systolic Array FSM, connected to all PE
        
    input wire                          PE_clear [0:ARRAY_SIZE - 1][0:ARRAY_SIZE - 1],
                                                            // clear signal for all PEs

    // A/BInput from Input Buffer
    input wire [DATA_WIDTH - 1:0]       row0_val,
    input wire [DATA_WIDTH - 1:0]       row1_val,
    input wire [DATA_WIDTH - 1:0]       row2_val,
    input wire [DATA_WIDTH - 1:0]       row3_val,

    input wire [DATA_WIDTH - 1:0]       col0_val,
    input wire [DATA_WIDTH - 1:0]       col1_val,
    input wire [DATA_WIDTH - 1:0]       col2_val,
    input wire [DATA_WIDTH - 1:0]       col3_val,



    // c_out for each PEs
    output wire [PSUM_WIDTH-1: 0] c_out [0:ARRAY_SIZE - 1][0:ARRAY_SIZE - 1]

);

    /* Systolic array
        B
      A
             |      |      |      |
             V      V      V      V
        -->PE00-->PE01-->PE02-->PE03-->
             |      |      |      |
             V      V      V      V
        -->PE10-->PE11-->PE12-->PE13-->
             |      |      |      |
             V      V      V      V
        -->PE20-->PE21-->PE22-->PE23-->
             |      |      |      |
             V      V      V      V
        -->PE30-->PE31-->PE32-->PE33-->
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
                    .rst(rst),
                    .clear(PE_clear[rows][cols]),               // Indipendent Clear Signals
                    .forward(forward_systo),                    // forward signal from systo_fsm
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