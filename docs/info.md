<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works
The Tensor Processing Unit (TPU) is an ASIC develop by Google to streamline the massive matrix multiplication calculations involved in neural network processing. 

This project is a scaled down version that can multiple two 4x4 matrices with signed 8-bit elements. This produces an output matrix of signed 14-bit elements, that are then processed through the Rectified Linear Unit (ReLU) activation function to provide an output matrix with 12-bit elements. ReLU is commonly used in neural network processing to approximate non-linear behaviour.

The matrices are multiplied using a 4x4 systolic array circuit that contains a total of 16 processing elements (PEs), which perform Multiply-Add-Accumulate (MAC) operations.

## How to test

Matrices A and B are 4x4 matrices, each element of which is a 7-bit number with an additional signed bit (total 8 bits). The output matrix, C, is also a 4x4 matrix, each element of which is an unsigned 12-bit number.

### Input Load
Notation: A_ij refers to the element in the ith row and jth column of matrix A.

Matrix A elements are loaded into GPIO input pins uin[5:0]. Matrix B elements are loaded into both the input and bidirectional pins such that the top 2 bits (bits 4 and 5) are loaded through uin[7:6] and the bottom 4 bits (bits 0 to 3) are loaded through the bidirectional uio_in[3:0].

The first inputs are entered staggered, according to what the systolic array circuit expects. Once the first pair of matrices have been entered, any subsequent inputs can be continuously entered. Each load cycle takes 4 clock cycles to fill the input buffers.

Load cycle 1: 
- Clock cycle 1: Load A_11 and B_11
- Clock cycles 2 - 4: Load 0 for both A and B

Load cycle 1:
- Clock cycle 1: Load A_12 and B_21
- Clock cycle 2: Load A_21 and B_12
- Clock cycles 3 - 4: Load 0

Load cycle 2:
- Clock cycle 1: Load A_13 and B_31
- Clock cycle 2: Load A_22 and B_22
- Clock cycle 3: Load A_31 and B_13
- Clock cycle 4: Load 0

Load cycles 4 - 7: Follow the pattern of the systolic array

## External hardware

The project requires an external microcontroller that can send inputs and read outputs from the chip's GPIO pins.