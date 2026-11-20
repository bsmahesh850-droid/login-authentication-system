`timescale 1ns/1ps
// =============================================================================
// authentication_fsm.v
// Moore FSM controlling the login sequence.
//
//  IDLE    --start-------------> INPUT
//  INPUT   --data_valid--------> VERIFY   (credential captured)
//  VERIFY  --match-------------> GRANTED  (clear attempts)
//  VERIFY  --!match, last------> LOCKED   (3rd failure)
//  VERIFY  --!match, !last-----> DENIED   (increment attempts)
//  GRANTED --start-------------> IDLE     (logout)
//  DENIED  --start-------------> INPUT    (retry)
//  LOCKED  --(only rst)--------> IDLE
// =============================================================================
module authentication_fsm (
    input  wire       clk,
    input  wire       rst,           // synchronous, active high
    input  wire       start,         // begin / retry / logout
    input  wire       data_valid,    // credential strobe (INPUT state)
    input  wire       match,         // from credential_checker
    input  wire       last_attempt,  // from attempt_counter
    output reg        capture,       // latch data_in into data register
    output reg        inc_attempt,
    output reg        clr_attempt,
    output wire       granted,
    output wire       denied,
    output wire       locked,
    output wire [2:0] state_out
);
    localparam [2:0] S_IDLE    = 3'd0,
                     S_INPUT   = 3'd1,
                     S_VERIFY  = 3'd2,
                     S_GRANTED = 3'd3,
                     S_DENIED  = 3'd4,
                     S_LOCKED  = 3'd5;

    reg [2:0] state, next_state;

    // State register
    always @(posedge clk) begin
        if (rst) state <= S_IDLE;
        else     state <= next_state;
    end

    // Next-state logic (all branches assign -> no latches)
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE:    if (start)      next_state = S_INPUT;
            S_INPUT:   if (data_valid) next_state = S_VERIFY;
            S_VERIFY:  begin
                if (match)             next_state = S_GRANTED;
                else if (last_attempt) next_state = S_LOCKED;
                else                   next_state = S_DENIED;
            end
            S_GRANTED: if (start)      next_state = S_IDLE;
            S_DENIED:  if (start)      next_state = S_INPUT;
            S_LOCKED:                  next_state = S_LOCKED;
            default:                   next_state = S_IDLE;
        endcase
    end

    // Control outputs (defaults first -> no latches)
    always @(*) begin
        capture     = 1'b0;
        inc_attempt = 1'b0;
        clr_attempt = 1'b0;
        case (state)
            S_INPUT:  capture     = data_valid;
            S_VERIFY: begin
                if (match) clr_attempt = 1'b1;
                else       inc_attempt = 1'b1;
            end
            default: ;
        endcase
    end

    assign granted   = (state == S_GRANTED);
    assign denied    = (state == S_DENIED);
    assign locked    = (state == S_LOCKED);
    assign state_out = state;
endmodule
