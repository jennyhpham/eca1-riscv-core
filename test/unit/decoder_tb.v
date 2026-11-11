`timescale 1ps / 1ps
module decoder_tb;
    reg  [31:0] instr;
    wire [4:0]  rd, rs1, rs2;
    wire [2:0]  funct3;
    wire [6:0]  funct7;
    wire        reg_write, mem_read, mem_write, ALUSrc;
    wire        is_branch, is_jal, is_jalr;
    wire [1:0]  ALUOp, wb_sel, imm_sel;

    integer errors = 0;
    integer i;

    decoder dut (
        .instr(instr),
        .rd(rd), .rs1(rs1), .rs2(rs2),
        .funct3(funct3), .funct7(funct7),
        .reg_write(reg_write), .mem_read(mem_read), .mem_write(mem_write),
        .ALUSrc(ALUSrc), .ALUOp(ALUOp),
        .is_branch(is_branch), .is_jal(is_jal), .is_jalr(is_jalr),
        .wb_sel(wb_sel), .imm_sel(imm_sel)
    );

    // Expected control bundle, packed:
    // {reg_write, mem_read, mem_write, ALUSrc, ALUOp[1:0], is_branch,
    //  is_jal, is_jalr, wb_sel[1:0], imm_sel[1:0]}  = 13 bits
    task check_bundle(input [12:0] exp, input [511:0] name);
        reg [12:0] got;
    begin
        got = {reg_write, mem_read, mem_write, ALUSrc, ALUOp,
               is_branch, is_jal, is_jalr, wb_sel, imm_sel};
        if (got === exp) $display("PASS: %0s", name);
        else begin
            $display("FAIL: %0s  got=%b exp=%b", name, got, exp);
            errors = errors + 1;
        end
    end
    endtask

    task check_field(input [31:0] got, input [31:0] exp, input [511:0] name);
    begin
        if (got === exp) $display("PASS: %0s", name);
        else begin
            $display("FAIL: %0s  got=%h exp=%h", name, got, exp);
            errors = errors + 1;
        end
    end
    endtask

    // ---- reference bundle builder (from opcode class only) ----
    function [12:0] ref_bundle(input [6:0] op);
        case (op)
            7'b0110011: ref_bundle = {1'b1, 1'b0, 1'b0, 1'b0, 2'b10, 3'b000, 2'b00, 2'b00}; // R
            7'b0010011: ref_bundle = {1'b1, 1'b0, 1'b0, 1'b1, 2'b10, 3'b000, 2'b00, 2'b00}; // I-arith
            7'b0000011: ref_bundle = {1'b1, 1'b1, 1'b0, 1'b1, 2'b00, 3'b000, 2'b01, 2'b00}; // load
            7'b0100011: ref_bundle = {1'b0, 1'b0, 1'b1, 1'b1, 2'b00, 3'b000, 2'b00, 2'b01}; // store
            7'b1100011: ref_bundle = {1'b0, 1'b0, 1'b0, 1'b0, 2'b01, 3'b100, 2'b00, 2'b10}; // branch
            7'b1100111: ref_bundle = {1'b1, 1'b0, 1'b0, 1'b1, 2'b00, 3'b001, 2'b10, 2'b00}; // jalr
            default:    ref_bundle = {1'b0, 1'b0, 1'b0, 1'b0, 2'b00, 3'b000, 2'b00, 2'b00}; // bubble/unknown
        endcase
    endfunction

    // ---- program sweep ----
    reg [31:0] prog [0:41];
    initial $readmemh("test/program.hex", prog);

    task check_word(input [31:0] w, input [511:0] name);
        reg [12:0] exp;
        reg [12:0] got;
    begin
        instr = w;
        #1;
        exp = ref_bundle(w[6:0]);
        got = {reg_write, mem_read, mem_write, ALUSrc, ALUOp,
               is_branch, is_jal, is_jalr, wb_sel, imm_sel};
        if (got === exp) $display("PASS: %0s", name);
        else begin
            $display("FAIL: %0s  got=%b exp=%b", name, got, exp);
            errors = errors + 1;
        end
    end
    endtask

    task check_word_sweep(input [31:0] w, input integer idx);
        reg [12:0] exp;
        reg [12:0] got;
    begin
        instr = w;
        #1;
        exp = ref_bundle(w[6:0]);
        got = {reg_write, mem_read, mem_write, ALUSrc, ALUOp,
               is_branch, is_jal, is_jalr, wb_sel, imm_sel};
        if (got === exp) $display("PASS: prog[%0d] %h", idx, w);
        else begin
            $display("FAIL: prog[%0d] %h  got=%b exp=%b", idx, w, got, exp);
            errors = errors + 1;
        end
    end
    endtask

    // ---- hand vectors: one per arm, real words from the program ----
    initial begin
        // I-arith (addi a1, x0, 676)
        check_word(32'h2a400593, "addi 2a400593: I-arith bundle");
        // R-type add (add s5, s1, s4)
        check_word(32'h014482b3, "add 014482b3: R bundle");
        // R-type mul (mul t2, t0, t3)
        check_word(32'h037b02b3, "mul 037b02b3: R bundle");
        // slli (slli t2, t2, 2)
        check_word(32'h001a1293, "slli 001a1293: I-arith bundle");
        // load (lw s6, 0(t3))
        check_word(32'h000e2b03, "lw 000e2b03: load bundle");
        // store (sw s3, 0(t2))
        check_word(32'h0133a023, "sw 0133a023: store bundle");
        // branch blt (blt s5, t0, -28)
        check_word(32'hfe5ac2e3, "blt fe5ac2e3: branch bundle");
        // jalr (ret)
        check_word(32'h00008067, "ret 00008067: jalr bundle");

        // jal arm (not in program, but decoder supports it)
        instr = 32'h00c0006f;
        #1
        check_bundle({1'b1, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b1, 1'b0, 2'b10, 2'b11},
                     "jal 00c0006f: jal bundle");

        // bubble: opcode 0 (what flush produces) -> all controls dead
        instr = 32'h00000000;
        #1
        check_bundle(13'b0, "bubble 00000000: all controls 0");

        // unknown opcode -> also safe
        instr = 32'hffffffff;
        #1
        check_bundle(13'b0, "unknown ffffffff: all controls 0");

        // ---- field slice checks ----
        instr = 32'h2a400593; #1   // addi a1, x0, 676
        check_field({27'b0, rd},    32'd11,   "field: rd   (a1 = x11)");
        check_field({27'b0, rs1},   32'd0,    "field: rs1  (x0)");
        check_field({27'b0, rs2},   32'd4,    "field: rs2  (imm bit slice, don't-care)");
        check_field({29'b0, funct3}, 3'b000,  "field: funct3 (addi)");

        instr = 32'h014482b3; #1   // add t0, s1, s4
        check_field({27'b0, rd},    32'd5,    "field: rd   (t0 = x5)");
        check_field({27'b0, rs1},   32'd9,    "field: rs1  (s1 = x9)");
        check_field({27'b0, rs2},   32'd20,   "field: rs2  (s4 = x20)");
        check_field({29'b0, funct3}, 3'b000,  "field: funct3 (add)");
        check_field({25'b0, funct7}, 7'b0,    "field: funct7 (add = 0)");

        instr = 32'h037b02b3; #1   // mul t2, t0, t3
        check_field({25'b0, funct7}, 7'b1,    "field: funct7 (mul = 0000001)");
        check_field({29'b0, funct3}, 3'b000,  "field: funct3 (mul)");

        // ---- full sweep of the real program ----
        $display("---- sweeping test/program.hex (42 instructions) ----");
        for (i = 0; i < 42; i = i + 1)
            check_word_sweep(prog[i], i);

        $display("----");
        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
