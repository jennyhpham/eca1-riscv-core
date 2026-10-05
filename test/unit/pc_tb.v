`timescale 1ps / 1ps
module pc_tb;
    reg clk = 0, rst = 1, stall = 0, branch_en = 0;
    reg  [31:0] pc_target = 0;
    wire [31:0] pc;
    wire [31:0] pc_plus4;

    integer errors = 0;

    pc dut (
        .clk(clk), .rst(rst), .stall(stall), .branch_en(branch_en),
        .pc_target(pc_target), .pc(pc), .pc_plus4(pc_plus4)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("test/unit/pc_tb.vcd");
        $dumpvars(0, pc_tb);
    end

    task check(input [31:0] exp, input [511:0] name);
    begin
        if (pc === exp) $display("PASS: %0s", name);
        else begin
            $display("FAIL: %0s  got=%h exp=%h", name, pc, exp);
            errors = errors + 1;
        end
    end
    endtask

    task check4(input [31:0] exp, input [511:0] name);
    begin
        if (pc_plus4 === exp) $display("PASS: %0s", name);
        else begin
            $display("FAIL: %0s  got=%h exp=%h", name, pc_plus4, exp);
            errors = errors + 1;
        end
    end
    endtask

    // Stimulus on negedge, checks 1ns after posedge
    initial begin
        // 1. reset -> 0
        @(negedge clk);
        rst = 0;
        #1
        check(32'd0, "reset: pc == 0");
        check4(32'd4, "reset: pc_plus4 == 4 (combinational adder)");

        // 2. sequential increment (+4 per cycle)
        stall = 0; branch_en = 0;
        @(negedge clk);
        #1
        check(32'd4, "increment: pc == 4");
        check4(32'd8, "increment: pc_plus4 == 8");
        @(negedge clk);
        #1
        check(32'd8, "increment: pc == 8");
        check4(32'd12, "increment: pc_plus4 == 12");
        @(negedge clk);
        #1
        check(32'd12, "increment: pc == 12");
        check4(32'd16, "increment: pc_plus4 == 16");

        // 3. stall: stall=1 -> hold
        stall = 1;
        @(negedge clk);
        #1
        check(32'd12, "stall: pc holds at 12");
        check4(32'd16, "stall: pc_plus4 follows pc (16)");
        @(negedge clk);
        #1
        check(32'd12, "stall: pc still holds at 12");

        // 4. redirect: branch_en wins, loads byte target
        stall = 0; branch_en = 1; pc_target = 32'h00000064;  // 100
        @(negedge clk);
        #1
        check(32'h00000064, "redirect: pc == 100 (byte target loaded)");
        check4(32'h00000068, "redirect: pc_plus4 == 104");

        // 5. redirect while stalled still wins (priority check)
        branch_en = 0; stall = 1;
        @(negedge clk);
        #1
        check(32'h00000064, "after redirect, stall=1: pc holds at 100");

        // 6. resume incrementing from redirected value
        stall = 0;
        @(negedge clk);
        #1
        check(32'h00000068, "resume: pc == 104");

        $display("----");
        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule


