## How it works

miniTPU multiplies two 4×4 matrices of signed 6-bit integers and applies a ReLU activation to the
result. It is a scaled-down take on the matrix-multiply engine at the centre of Google's TPU v1.

Multiplication happens in a 4×4 systolic array of 16 processing elements (PEs), each of which
performs a multiply-accumulate. Operand A flows left to right across the array while operand B flows
top to bottom, and each PE holds its own running partial sum. Partial sums are accumulated at 14 bits
to avoid overflow, then passed through ReLU and saturated down to a 12-bit unsigned result.

Because operands enter the array staggered, the PEs do not all finish at the same time. The ones that
finish together lie on an anti-diagonal, so results are read out four at a time, one diagonal per
beat. Each PE is cleared in the same beat it is read, which lets a new matrix pair begin without
waiting for the previous one to drain.

For diagrams and a fuller description, see the [project README](https://github.com/HynixCJR/ttsky-miniTPU).

## How to test

The design needs a controller that can drive the input pins every clock and sample the output pins.

### Data format

Matrix A and B elements are signed 6-bit two's-complement values, so 5 magnitude bits plus a sign,
covering −32 to +31. Results are 12-bit unsigned, since ReLU has already removed negatives. Values of
4096 or above saturate to `0xFFF`.

| Signal | Pins |
|---|---|
| Matrix A element | `ui_in[7:2]` |
| Matrix B element | `ui_in[1:0]` (high 2 bits) and `uio_in[3:0]` (low 4 bits) |
| Result, low 8 bits | `uo_out[7:0]` |
| Result, high 4 bits | `uio_out[7:4]` |

`uio_oe` is driven to `8'b11110000`, so the low nibble of the bidirectional port is an input and the
high nibble is an output.

### Loading inputs

One A element and one B element are accepted per clock. Four clocks make up one *beat*, and a beat
advances the array by one step. Within a beat the four clocks fill row/column slots 1 through 4 in
order.

Operands must be staggered, because the value arriving at a given PE has to be the one belonging
there at that moment. Row *i* and column *i* start *i* beats late, and the gaps are filled with
zeros. Using A_ij for the element in row i, column j:

| Beat | Clock | Load on A | Load on B |
|---|---|---|---|
| 1 | 1 | A_11 | B_11 |
| 1 | 2–4 | 0 | 0 |
| 2 | 1 | A_12 | B_21 |
| 2 | 2 | A_21 | B_12 |
| 2 | 3–4 | 0 | 0 |
| 3 | 1 | A_13 | B_31 |
| 3 | 2 | A_22 | B_22 |
| 3 | 3 | A_31 | B_13 |
| 3 | 4 | 0 | 0 |
| 4 | 1 | A_14 | B_41 |
| 4 | 2 | A_23 | B_32 |
| 4 | 3 | A_32 | B_23 |
| 4 | 4 | A_41 | B_14 |
| 5 | 1 | 0 | 0 |
| 5 | 2 | A_24 | B_42 |
| 5 | 3 | A_33 | B_33 |
| 5 | 4 | A_42 | B_24 |
| 6 | 1–2 | 0 | 0 |
| 6 | 3 | A_34 | B_43 |
| 6 | 4 | A_43 | B_34 |
| 7 | 1–3 | 0 | 0 |
| 7 | 4 | A_44 | B_44 |

The general rule is that on clock *i* of beat *t*, load `A_i(t-i+1)` and `B_(t-i+1)i`, substituting
zero whenever the index falls outside 1 to 4.

A single matrix pair therefore occupies 7 beats, but the ramp-up and ramp-down overlap. To multiply
several pairs, feed the next pair's beat 1 immediately after the current pair's beat 4 and keep
going; the zero padding above is only needed at the very start and very end of a run. There is no
gap between matrices in steady state.

### Reading results

Results leave on `uo_out` and `uio_out[7:4]`, one 12-bit value per clock. They emerge four at a time,
one anti-diagonal per beat, cycling through four groups:

| Group | Clock 1 | Clock 2 | Clock 3 | Clock 4 |
|---|---|---|---|---|
| 0 | C_11 | C_42 | C_33 | C_24 |
| 1 | C_21 | C_12 | C_43 | C_34 |
| 2 | C_31 | C_22 | C_13 | C_44 |
| 3 | C_41 | C_32 | C_23 | C_14 |

Four consecutive groups deliver all 16 elements of C. No output is produced while the array is still
filling; the design holds the bus at zero until the first real dot products are ready. When aligning
a controller to this stream, confirm the exact start beat against simulation rather than assuming it,
since it depends on the pipeline fill latency.

### Simulating it

The cocotb testbenches under `test/` drive this protocol already, and
[`test/4x4TPU/test_tpu.py`](https://github.com/HynixCJR/ttsky-miniTPU/blob/main/test/4x4TPU/test_tpu.py)
is the clearest reference for how the staggering is generated. Run `make -B` in `test/`.

## External hardware

None required beyond a controller for the GPIO. A microcontroller or FPGA that can present 12 input
bits per clock and capture 12 output bits per clock is enough.
