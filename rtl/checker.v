`timescale 1ns/1ps
// =============================================================================
// credential_checker.v
// Combinational comparator: asserts 'match' when the entered credential equals
// the stored demonstration credential.
// EDUCATIONAL PROTOTYPE ONLY: a hardcoded 4-bit value is NOT real security.
// =============================================================================
module credential_checker #(
    parameter WIDTH      = 4,
    parameter CREDENTIAL = 4'b1010
) (
    input  wire [WIDTH-1:0] data_in,
    output wire             match
);
    assign match = (data_in == CREDENTIAL);
endmodule

