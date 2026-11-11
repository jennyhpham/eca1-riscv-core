`timescale 1ps / 1ps
module wbmux_tb;
    reg  [31:0] alu_result, mem_data, pc_plus4;
    reg  [1:0]  wb_sel;
    wire [31:0] writeback;

    integer errors = 0;

    wb_mux dut (
        .alu_result(alu_result),
        .mem_data(mem_data),
        .pc_plus4(pc_plus4),
        .wb_sel(wb_sel),
        .writeback(writeback)
    );

    task check(input [31:0] exp, input [511:0] name);
    begin
        if (writeback === exp) $display("PASS: %0s", name);
        else begin
            $display("FAIL: %0s  got=%h exp=%h", name, writeback, exp);
            errors = errors + 1;
        end
    end
    endtask

    initial begin
        // Distinct source values
        alu_result = 32'h000000aa;
        mem_data   = 32'h000000bb;
        pc_plus4   = 32'h000000cc;

        // 1. wb_sel = 00: ALU result (R-type, addi)
        wb_sel = 2'b00; #1
        check(32'h000000aa, "wb_sel=00: picks alu_result");

        // 2. wb_sel = 01: memory data (lw)
        wb_sel = 2'b01; #1
        check(32'h000000bb, "wb_sel=01: picks mem_data");

        // 3. wb_sel = 10: PC+4 (jal/jalr link write)
        wb_sel = 2'b10; #1
        check(32'h000000cc, "wb_sel=10: picks pc_plus4");

        // 4. default (11): falls back to alu_result
        wb_sel = 2'b11; #1
        check(32'h000000aa, "wb_sel=11: default falls back to alu_result");

        // 5. select actually switches with the same inputs
        wb_sel = 2'b01; #1
        check(32'h000000bb, "re-select: switches back to mem_data");

        $display("----");
        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
