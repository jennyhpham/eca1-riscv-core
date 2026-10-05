`timescale 1ps / 1ps
module pc_tb;
    reg clk = 0, rst = 1, en = 1, branch_en = 0;
    reg  [31:0] pc_target = 0;
    wire [31:0] pc;

    integer errors = 0;

    pc dut (
        .clk(clk), .rst(rst), .en(en), .branch_en(branch_en),
        .pc_target(pc_target), .pc(pc)
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

    // Stimulus on negedge, checks 1ns after posedge
    initial begin
        // 1. reset -> 0
        @(negedge clk);
        rst = 0;
        #1
        check(32'd0, "reset: pc == 0");

        // 2. sequential increment (+4 per cycle)
        en = 1; branch_en = 0;
        @(negedge clk);
        #1
        check(32'd4, "increment: pc == 4");
        @(negedge clk);
        #1
        check(32'd8, "increment: pc == 8");
        @(negedge clk);
        #1
        check(32'd12, "increment: pc == 12");

        // 3. stall: en=0 -> hold
        en = 0;
        @(negedge clk);
        #1
        check(32'd12, "stall: pc holds at 12");
        @(negedge clk);
        #1
        check(32'd12, "stall: pc still holds at 12");

        // 4. redirect: branch_en wins, loads byte target
        en = 1; branch_en = 1; pc_target = 32'h00000064;  // 100
        @(negedge clk);
        #1
        check(32'h00000064, "redirect: pc == 100 (byte target loaded)");

        // 5. redirect while stalled still wins (priority check)
        branch_en = 0; en = 0;
        @(negedge clk);
        #1
        check(32'h00000064, "after redirect, en=0: pc holds at 100");

        // 6. resume incrementing from redirected value
        en = 1;
        @(negedge clk);
        #1
        check(32'h00000068, "resume: pc == 104");

        $display("----");
        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
