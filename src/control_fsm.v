module control_fsm #(
  parameter int unsigned K_BEATS = 4
)(
  input  wire clk,
  input  wire rst_n,
  input  wire ena_global,
  input  wire startSysArray,

  output reg  forward_systo,
  output reg  reset_pe,
  output reg  flush_pe
);

  localparam [1:0]
    S_STARTER = 2'd0,
    S_FLUSH   = 2'd1,
    S_DRAIN   = 2'd2;

  reg [1:0] st;
  reg [$clog2(K_BEATS+1)-1:0] beat_cnt;

  always @(*) begin
    flush_pe = 1'b0;
    reset_pe = 1'b0;
    case (st)
      S_FLUSH: flush_pe = 1'b1;
      S_DRAIN: reset_pe = 1'b1;
      default: ;
    endcase
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st            <= S_STARTER;
      beat_cnt      <= '0;
      forward_systo <= 1'b0;
    end else if (ena_global) begin
      forward_systo <= 1'b0;

      case (st)
        S_STARTER: begin
          if (startSysArray) begin
            forward_systo <= 1'b1;
            if (beat_cnt + 1 < K_BEATS) begin //only for the first ever matrices
              beat_cnt <= beat_cnt + 1;
            end else begin
              st <= S_FLUSH;
            end
          end
        end

        S_FLUSH: st <= S_DRAIN;
        S_DRAIN: st <= S_STARTER;

        default: st <= S_STARTER;
      endcase
    end
  end

endmodule
