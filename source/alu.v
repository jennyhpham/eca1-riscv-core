`timescale 1ps/1ps

module ALU#(
    parameter DATA_WIDTH = 32
) (
    input wire[(DATA_WIDTH - 1):0] A,
    input wire[(DATA_WIDTH - 1):0] B,
    input wire[2:0] alu_control,
    output reg[(DATA_WIDTH - 1):0] alu_result,
    output reg zero_flag, // Zero status flag
    output reg neg_flag   // Negative status flag
);

always @(*) begin

    case (alu_control)
        3'b000: alu_result = A + B;
        3'b001: alu_result = A * B;
        3'b010: alu_result = A << B[4:0];
        3'b011: alu_result = ($signed(A) < $signed(B)) ? 1:0;
        3'b100: alu_result = ($signed(A) > $signed(B)) ? 1:0;
        3'b101: alu_result = (A == B) ? 1:0;
        3'b110: alu_result = (A != B) ? 1:0;
        default: alu_result = 32'b0;
    endcase

    neg_flag = alu_result[31];
    zero_flag = ((alu_result == 32'b0) ? 1:0);
end

endmodule

module ALU_SrcMux#(
    parameter DATA_WIDTH = 32
) (
    input wire [(DATA_WIDTH - 1):0] rdata2,
    input wire [(DATA_WIDTH - 1):0] imm,
    input wire ALUSrc,
    output reg [(DATA_WIDTH - 1):0] B
);

always @(*) begin
    case (ALUSrc)
        1'b0: B = rdata2;
        1'b1: B = imm;
        default: B = rdata2;
    endcase
end

endmodule
