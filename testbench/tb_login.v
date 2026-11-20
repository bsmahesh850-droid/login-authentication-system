// =============================================================================
// tb_login_controller.v - self-checking testbench
// Run:  iverilog -g2012 -o login_sim rtl/*.v testbench/*.v
//       vvp login_sim
// =============================================================================
`timescale 1ns/1ps
module tb_login_controller;
    reg        clk = 1'b0, rst = 1'b0, start = 1'b0, data_valid = 1'b0;
    reg  [3:0] data_in = 4'b0000;
    wire       granted, denied, locked;
    wire [1:0] attempts;
    wire [2:0] state_out;

    localparam [2:0] S_IDLE = 0, S_INPUT = 1, S_VERIFY = 2,
                     S_GRANTED = 3, S_DENIED = 4, S_LOCKED = 5;
    localparam [3:0] GOOD = 4'b1010, BAD = 4'b0101;

    integer pass_count = 0, fail_count = 0;

    login_controller dut (
        .clk(clk), .rst(rst), .start(start), .data_valid(data_valid),
        .data_in(data_in), .granted(granted), .denied(denied),
        .locked(locked), .attempts(attempts), .state_out(state_out)
    );

    always #5 clk = ~clk;

    // ---- helper tasks (inputs change 1 ns after the rising edge) ----
    task do_reset;
        begin rst = 1; @(posedge clk); #1; @(posedge clk); #1; rst = 0; end
    endtask
    task press_start;
        begin start = 1; @(posedge clk); #1; start = 0; end
    endtask
    task enter;  // INPUT -> VERIFY -> result state
        input [3:0] code;
        begin
            data_in = code; data_valid = 1; @(posedge clk); #1;
            data_valid = 0;                 @(posedge clk); #1;
        end
    endtask
    task check;
        input [8*56-1:0] name;
        input         cond;
        begin
            if (cond) begin $display("PASS: %0s", name); pass_count = pass_count + 1; end
            else      begin $display("FAIL: %0s", name); fail_count = fail_count + 1; end
        end
    endtask

    initial begin
        $dumpfile("login_sim.vcd");
        $dumpvars(0, tb_login_controller);

        // Test 1: reset state
        do_reset;
        check("T1 reset -> IDLE, attempts=0", state_out == S_IDLE && attempts == 0);

        // Test 2: successful login
        press_start;
        check("T2a start -> INPUT", state_out == S_INPUT);
        enter(GOOD);
        check("T2b correct credential -> GRANTED", state_out == S_GRANTED && granted && !denied && !locked);
        check("T2c attempts=0 after success", attempts == 0);
        press_start;
        check("T2d logout -> IDLE", state_out == S_IDLE);

        // Test 3: incorrect credential
        press_start; enter(BAD);
        check("T3 wrong credential -> DENIED, attempts=1", state_out == S_DENIED && denied && attempts == 1);

        // Test 4: success clears counter
        press_start; enter(GOOD);
        check("T4a success after failure -> GRANTED", state_out == S_GRANTED);
        check("T4b success clears attempts", attempts == 0);
        press_start;  // logout

        // Test 5: three failed attempts -> LOCKED
        press_start; enter(BAD);
        check("T5a failure 1 -> DENIED, attempts=1", state_out == S_DENIED && attempts == 1);
        press_start; enter(BAD);
        check("T5b failure 2 -> DENIED, attempts=2", state_out == S_DENIED && attempts == 2);
        press_start; enter(BAD);
        check("T5c failure 3 -> LOCKED, attempts=3", state_out == S_LOCKED && locked && attempts == 3);

        // Test 6: lockout holds even with correct credential
        press_start; enter(GOOD);
        check("T6a start ignored while LOCKED", state_out == S_LOCKED);
        start = 1; data_in = GOOD; data_valid = 1; @(posedge clk); #1;
        start = 0; data_valid = 0; repeat (3) begin @(posedge clk); #1; end
        check("T6b correct credential rejected while LOCKED", state_out == S_LOCKED && !granted && attempts == 3);

        // Test 7: reset clears lockout
        do_reset;
        check("T7 reset clears LOCKED -> IDLE, attempts=0", state_out == S_IDLE && !locked && attempts == 0);

        // Test 8: recovery after reset
        press_start; enter(GOOD);
        check("T8a login works after reset", state_out == S_GRANTED && granted);
        press_start;
        press_start; enter(BAD);
        check("T8b counter restarted from 0 (attempts=1)", state_out == S_DENIED && attempts == 1);

        $display("--------------------------------------------");
        $display("SUMMARY: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) $display("OVERALL: PASS");
        else                 $display("OVERALL: FAIL");
        $finish;
    end

    initial begin  // watchdog
        #100000; $display("FAIL: simulation timeout"); $finish;
    end
endmodule
