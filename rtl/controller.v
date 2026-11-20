`timescale 1ns/1ps
// =============================================================================
// login_controller.v  (top level)
// Integrates authentication_fsm, credential_checker and attempt_counter.
// EDUCATIONAL PROTOTYPE: hardcoded 4-bit credential, not production security.
// =============================================================================
module login_controller #(
    parameter [3:0] CREDENTIAL   = 4'b1010,
    parameter       MAX_ATTEMPTS = 3
) (
    input  wire       clk,
    input  wire       rst,         // synchronous, active high (admin reset)
    input  wire       start,
    input  wire       data_valid,
    input  wire [3:0] data_in,
    output wire       granted,
    output wire       denied,
    output wire       locked,
    output wire [1:0] attempts,
    output wire [2:0] state_out
);
    reg  [3:0] data_reg;
    wire       match, last_attempt, limit_reached;
    wire       capture, inc_attempt, clr_attempt;

    always @(posedge clk) begin
        if (rst)          data_reg <= 4'b0000;
        else if (capture) data_reg <= data_in;
    end

    credential_checker #(.WIDTH(4), .CREDENTIAL(CREDENTIAL)) u_checker (
        .data_in(data_reg),
        .match  (match)
    );

    attempt_counter #(.MAX_ATTEMPTS(MAX_ATTEMPTS), .CNT_WIDTH(2)) u_counter (
        .clk          (clk),
        .rst          (rst),
        .inc          (inc_attempt),
        .clear        (clr_attempt),
        .count        (attempts),
        .last_attempt (last_attempt),
        .limit_reached(limit_reached)
    );

    authentication_fsm u_fsm (
        .clk         (clk),
        .rst         (rst),
        .start       (start),
        .data_valid  (data_valid),
        .match       (match),
        .last_attempt(last_attempt),
        .capture     (capture),
        .inc_attempt (inc_attempt),
        .clr_attempt (clr_attempt),
        .granted     (granted),
        .denied      (denied),
        .locked      (locked),
        .state_out   (state_out)
    );
endmodule
