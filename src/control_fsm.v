module control_fsm #(
  parameter int unsigned K_BEATS      = 4,
  parameter int unsigned DRAIN_STATES = 7,
  parameter int unsigned SEND_CYCLES  = 4
)(
  input  wire clk,
  input  wire rst_n,

  input  wire start,
  input  wire ena_global,

  input  wire startSysArray,

  output reg  sendOut,

  output reg  clear_psum,
  output reg  forward_systo,

  output reg  drain_en,
  output reg  [2:0] drain_state,
  output reg  drain_step,

  output reg  done,
  output reg  [1:0] curr_state_control
);


// to make it easier
  typedef enum reg [2:0] {
    S_IDLE   = 3'd0,
    S_CLEAR  = 3'd1,
    S_LOAD   = 3'd2,
    S_DRAIN  = 3'd3,
    S_SEND   = 3'd4,
    S_DONE   = 3'd5
  } state_t;

  state_t st;

//optimization bitwidth so we can adjust the parameter in the future alsdjfnsdkjfakdf 
  reg [$clog2(K_BEATS+1)-1:0]      beat_cnt;
  reg [$clog2(DRAIN_STATES+1)-1:0] drain_cnt;
  reg [$clog2(SEND_CYCLES+1)-1:0]  send_cnt;

  // combinational defaults
  always @(*) begin
    sendOut       = 1'b0;

    clear_psum    = 1'b0;

    drain_en      = 1'b0;
    drain_state   = drain_cnt[2:0];

    done          = 1'b0;

    // output lane
    curr_state_control = 2'd0;

    case (st)
      S_CLEAR: begin
        clear_psum = 1'b1;
      end

      S_LOAD: begin
        // Wait for startSysArray from input handler
      end

      S_DRAIN: begin
        drain_en = 1'b1;
      end

      S_SEND: begin
        sendOut = 1'b1;

        curr_state_control = send_cnt[1:0];  // 0,1,2,3 across 4 cycles
      end

      S_DONE: begin
        done = 1'b1;
      end

      default: ;
    endcase
  end

  // sequential behavior, pls check i am lowky crashing
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st        <= S_IDLE;
      beat_cnt  <= '0;
      drain_cnt <= '0;
      send_cnt  <= '0;

      forward_systo <= 1'b0;
      drain_step    <= 1'b0;
    end else if (ena_global) begin
      forward_systo <= 1'b0;
      drain_step    <= 1'b0;

      case (st)
        S_IDLE: begin
          beat_cnt  <= '0;
          drain_cnt <= '0;
          send_cnt  <= '0;
          if (start) st <= S_CLEAR;
        end

        S_CLEAR: begin
          beat_cnt <= '0;
          st <= S_LOAD;
        end

        S_LOAD: begin
          if (startSysArray) begin
            forward_systo <= 1'b1;
            if (beat_cnt + 1 < K_BEATS) begin
              beat_cnt <= beat_cnt + 1;
            end else begin
              drain_cnt <= '0;
              st <= S_DRAIN;
            end
          end
        end

        S_DRAIN: begin
          drain_step <= 1'b1;
          if (drain_cnt + 1 < DRAIN_STATES) begin
            drain_cnt <= drain_cnt + 1;
          end else begin
            send_cnt <= '0;
            st <= S_SEND;
          end
        end

        S_SEND: begin
          if (send_cnt + 1 < SEND_CYCLES) begin
            send_cnt <= send_cnt + 1;
          end else begin
            st <= S_DONE;
          end
        end

        S_DONE: begin
          st <= S_IDLE;
        end

        default: st <= S_IDLE;
      endcase
    end
  end

endmodule
