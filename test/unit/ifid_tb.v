`timescale 1ps / 1ps
module ifid_tb;
    reg clk = 0, rst = 0, en = 1, flush = 0;
    reg  [31:0] pc_in, inst_in;
    wire [31:0] pc_out, inst_out;

    integer errors = 0;

    if_id dut (
        .clk(clk), .rst(rst), .en(en), .flush(flush),
        .pc_in(pc_in), .inst_in(inst_in),
        .pc_out(pc_out), .inst_out(inst_out)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("test/unit/ifid_tb.vcd");
        $dumpvars(0, ifid_tb);
    end

    task check(input [31:0] got, input [31:0] exp, input [511:0] name);
    begin
        if (got === exp) $display("PASS: %0s", name);
        else begin
            $display("FAIL: %0s  got=%h exp=%h", name, got, exp);
            errors = errors + 1;
        end
    end
    endtask

    initial begin
        // 1. capture
        pc_in = 32'h00000008; inst_in = 32'h2a400593;   // real addi word
        @(negedge clk);
        #1
        check(pc_out, 32'h00000008, "capture: pc_out");
        check(inst_out, 32'h2a400593, "capture: inst_out");

        // 2. stall: en=0, inputs change, outputs hold
        pc_in = 32'h0000000c; inst_in = 32'h008e2b03;
        en = 0;
        @(negedge clk);
        #1
        check(pc_out, 32'h00000008, "stall: pc_out held");
        check(inst_out, 32'h2a400593, "stall: inst_out held");

        // 3. flush -> bubble (opcode 0 = illegal -> decoder deasserts all)
        en = 1; flush = 1;
        pc_in = 32'h00000010; inst_in = 32'h005ac663;
        @(negedge clk);
        #1
        check(pc_out, 32'd0, "flush: pc_out zeroed");
        check(inst_out, 32'd0, "flush: inst_out zeroed (bubble)");

        // 4. re-enable
        flush = 0;
        pc_in = 32'h00000014; inst_in = 32'h00c0006f;
        @(negedge clk);
        #1
        check(pc_out, 32'h00000014, "re-enable: pc_out");
        check(inst_out, 32'h00c0006f, "re-enable: inst_out");

        $display("----");
        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
