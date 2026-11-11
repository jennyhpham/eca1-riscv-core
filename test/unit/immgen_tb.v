`timescale 1ps/1ps
module immgen_tb;
    reg  [31:0] instr;
    reg  [1:0]  imm_sel;
    wire [31:0] imm;
    integer errors = 0;

    immgen dut (
        .instr(instr),
        .imm_sel(imm_sel),
        .imm(imm)
    );

    task check(input [31:0] exp, input [511:0] name);
    begin
        if (imm === exp) $display("PASS: %0s", name);
        else begin
            $display("FAIL: %0s  got=%h exp=%h", name, imm, exp);
            errors = errors + 1;
        end
    end
    endtask

    // Golden vectors assembled with riscv64-unknown-elf-as and verified
    // with objdump (imm value known from the .asm source by construction).
    initial begin
        // I-format (imm_sel = 00)
        instr = 32'h2a400593; imm_sel = 2'b00; #1
        check(32'd676,        "I: addi a1, x0, 676 -> +676");
        instr = 32'hfff00593; imm_sel = 2'b00; #1
        check(32'hffffffff,   "I: addi a1, x0, -1 -> -1 (sign ext)");
        instr = 32'h008e2b03; imm_sel = 2'b00; #1
        check(32'd8,          "I: lw s6, 8(t3) -> +8");
        instr = 32'h00008067; imm_sel = 2'b00; #1
        check(32'd0,          "I: jalr x0, 0(ra) (ret) -> +0");

        // S-format (imm_sel = 01)
        instr = 32'hff33ae23; imm_sel = 2'b01; #1
        check(-32'd4,         "S: sw s3, -4(t2) -> -4");
        instr = 32'h0133a623; imm_sel = 2'b01; #1
        check(32'd12,         "S: sw s3, 12(t2) -> +12");

        // B-format (imm_sel = 10)
        instr = 32'hfe5ac2e3; imm_sel = 2'b10; #1
        check(-32'd28,        "B: blt s5, t0, -28 -> -28");
        instr = 32'h005ac663; imm_sel = 2'b10; #1
        check(32'd12,         "B: blt s5, t0, +12 -> +12");

        // J-format (imm_sel = 11)
        instr = 32'h00c0006f; imm_sel = 2'b11; #1
        check(32'd12,         "J: jal x0, +12 -> +12");

        // R-type word with I selector: slices must ignore rd/funct3 fields
        instr = 32'h014482b3; imm_sel = 2'b00; #1
        check(32'h14,         "I: add s5, s1, s4 word, bits[31:20] = 0x014");

        $display("----");
        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
