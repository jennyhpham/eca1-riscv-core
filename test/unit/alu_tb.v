`timescale 1ps/1ps

module alu_tb;

localparam DATA_WIDTH = 32;

// TestBench bindings
// -----------------------------------

reg [(DATA_WIDTH - 1) : 0] A;
reg [(DATA_WIDTH - 1):0] rdata2;
reg [(DATA_WIDTH - 1):0] imm;
reg ALUSrc;
reg[1:0] ALUOp;
reg[2:0] funct3;
reg[6:0] funct7;

wire [(DATA_WIDTH - 1):0] B;
wire [2:0] alu_control;
wire [(DATA_WIDTH - 1) : 0] alu_result;
wire zero_flag;
wire neg_flag;

// ALU, ALU Control, ALUSrc MUX
// ------------------------------------
ALU alu_dut (
    .A(A),
    .B(B),
    .alu_control(alu_control),
    .alu_result(alu_result),
    .zero_flag(zero_flag),
    .neg_flag(neg_flag)
);

ALU_SrcMux ALU_SrcMux_DUT (
    .rdata2(rdata2),
    .imm(imm),
    .ALUSrc(ALUSrc),
    .B(B)
);

ALU_Control ALU_Control_DUT (
    .ALUOp(ALUOp),
    .funct3(funct3),
    .funct7(funct7),
    .alu_control(alu_control)
);


// Initialization
// ------------------------------------

initial begin

    ALUSrc = 0;
    imm = 0;

    // Addition 
    // ------------------------------------ 
    A = 10;
    rdata2 = 20;
    ALUOp = 2'b10;
    funct3 = 3'b000;
    funct7 = 7'b0000000;

    #50; //wait 10 ns

    if (alu_result == 30)
        $display("PASS: ADD, result = %d", alu_result);
    else
        $display("FAIL: ADD, result = %d", alu_result);

    // Addition Immediate
    // ------------------------------------ 
    A = 10;
    rdata2 = 20;
    imm = -30;
    ALUOp = 2'b10;
    funct3 = 3'b000;
    funct7 = 7'b0000000;
    ALUSrc = 1;
    #50; //wait 10 ns

    if (alu_result == -20)
        $display("PASS: ADD, result = %d", $signed(alu_result));
    else
        $display("FAIL: ADD, result = %d", $signed(alu_result));

    // Multiplication
    // -----------------------------------
    A = 50;
    rdata2 = 50;
    ALUOp = 2'b10;
    funct3 = 3'b000;
    funct7 = 7'b0000001;
    ALUSrc = 0;

    #50;

    if (alu_result == 2500)
        $display("PASS: MUL, result = %d", alu_result);
    else
        $display("FAIL: MUL, result = %d", alu_result);

    // Shift Left Immediate
    // -----------------------------------
    A = 2;
    rdata2 = 6;
    imm = 3;
    ALUOp = 2'b10;
    funct3 = 3'b001;
    funct7 = 7'b0000000;
    ALUSrc = 1;

    #50;

    if (alu_result == 16)
        $display("PASS: SLLI, result = %d", alu_result);
    else
        $display("FAIL: SLLI, result = %d", alu_result);

    // BEQ
    // -----------------------------------
    A = 7;
    rdata2 = 7;
    ALUOp = 2'b01;
    funct3 = 3'b000;
    ALUSrc = 0;

    #50;

    if (alu_result == 1)
        $display("PASS: BEQ, result = %d", alu_result);
    else
        $display("FAIL: BEQ, result = %d", alu_result);

    // BEQ
    // -----------------------------------
    A = -7;
    rdata2 = 7;
    ALUOp = 2'b01;
    funct3 = 3'b000;

    #50;

    if (alu_result == 0)
        $display("PASS: BEQ, result = %d", alu_result);
    else
        $display("FAIL: BEQ, result = %d", alu_result);

    // BNE
    // -----------------------------------
    A = -7;
    rdata2 = 7;
    ALUOp = 2'b01;
    funct3 = 3'b001;

    #50;

    if (alu_result == 1)
        $display("PASS: BNE, result = %d", alu_result);
    else
        $display("FAIL: BNE, result = %d", alu_result);

    // BLT
    // -----------------------------------
    A = -7;
    rdata2 = 9;
    ALUOp = 2'b01;
    funct3 = 3'b100;

    #50;

    if (alu_result == 1)
        $display("PASS: BLT, result = %d", alu_result);
    else
        $display("FAIL: BLT, result = %d", alu_result);

    // BGE
    // -----------------------------------
    A = -2;
    rdata2 = -8;
    ALUOp = 2'b01;
    funct3 = 3'b101;

    #50;

    if (alu_result == 1)
        $display("PASS: BGE, result = %d", alu_result);
    else
        $display("FAIL: BGE, result = %d", alu_result);

end

initial begin
  $dumpfile("wave.vcd");
  $dumpvars(0, alu_tb);
end

endmodule