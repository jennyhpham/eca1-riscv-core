`timescale 1ps / 1ps
module ifid_tb;
    reg clk = 0, rst = 0, stall = 0, flush = 0;
    reg  [31:0] pc_in, pc_plus4_in, instr_in;
    wire [31:0] pc_out, pc_plus4_out, instr_out;

    integer errors = 0;

    if_id dut (
        .clk(clk), .rst(rst), .stall(stall), .flush(flush),
        .pc_in(pc_in), .pc_plus4_in(pc_plus4_in), .instr_in(instr_in),
        .pc_out(pc_out), .pc_plus4_out(pc_plus4_out), .instr_out(instr_out)
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
        pc_in = 32'h00000008; pc_plus4_in = 32'h0000000c;
        instr_in = 32'h2a400593;   // real addi word
        @(negedge clk);
        #1
        check(pc_out, 32'h00000008, "capture: pc_out");
        check(pc_plus4_out, 32'h0000000c, "capture: pc_plus4_out");
        check(instr_out, 32'h2a400593, "capture: instr_out");

        // 2. stall: stall=1, inputs change, outputs hold
        pc_in = 32'h0000000c; pc_plus4_in = 32'h00000010;
        instr_in = 32'h008e2b03;
        stall = 1;
        @(negedge clk);
        #1
        check(pc_out, 32'h00000008, "stall: pc_out held");
        check(pc_plus4_out, 32'h0000000c, "stall: pc_plus4_out held");
        check(instr_out, 32'h2a400593, "stall: instr_out held");

        // 3. flush -> bubble (opcode 0 = illegal -> decoder deasserts all)
        stall = 0; flush = 1;
        pc_in = 32'h00000010; pc_plus4_in = 32'h00000014;
        instr_in = 32'h005ac663;
        @(negedge clk);
        #1
        check(pc_out, 32'd0, "flush: pc_out zeroed");
        check(pc_plus4_out, 32'd0, "flush: pc_plus4_out zeroed");
        check(instr_out, 32'd0, "flush: instr_out zeroed (bubble)");

        // 4. re-enable
        flush = 0;
        pc_in = 32'h00000014; pc_plus4_in = 32'h00000018;
        instr_in = 32'h00c0006f;
        @(negedge clk);
        #1
        check(pc_out, 32'h00000014, "re-enable: pc_out");
        check(pc_plus4_out, 32'h00000018, "re-enable: pc_plus4_out");
        check(instr_out, 32'h00c0006f, "re-enable: instr_out");

        $display("----");
        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule


