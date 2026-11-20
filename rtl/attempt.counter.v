timescale 1ns/1ps
// =============================================================================
// attempt_counter.v
// Counts failed login attempts. Saturates at MAX_ATTEMPTS.
//   inc   : add one failed attempt
//   clear : reset the count (successful login)
//   last_attempt : high when ONE more failure would reach MAX_ATTEMPTS
//   limit_reached: high when count == MAX_ATTEMPTS
// Synchronous active-high reset. 'clear' has priority over 'inc'.
// =============================================================================
module attempt_counter #(
    parameter MAX_ATTEMPTS = 3,
    parameter CNT_WIDTH    = 2
) (
    input  wire                 clk,
    input  wire                 rst,
    input  wire                 inc,
    input  wire                 clear,
    output reg  [CNT_WIDTH-1:0] count,
    output wire                 last_attempt,
    output wire                 limit_reached
);
    assign last_attempt  = (count == (MAX_ATTEMPTS - 1));
    assign limit_reached = (count == MAX_ATTEMPTS);

    always @(posedge clk) begin
        if (rst)
            count <= {CNT_WIDTH{1'b0}};
        else if (clear)
            count <= {CNT_WIDTH{1'b0}};
        else if (inc && (count != MAX_ATTEMPTS))
            count <= count + 1'b1;
    end
endmodule
