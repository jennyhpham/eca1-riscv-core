`timescale 1ps / 1ps

module ALU_Control (
    input  wire [1:0] ALUOp,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg  [2:0] alu_control
);

  localparam ADD = 3'b000;
  localparam MUL = 3'b001;
  localparam SLL = 3'b010;
  localparam BLT = 3'b011;
  localparam BGE = 3'b100;
  localparam BEQ = 3'b101;
  localparam BNE = 3'b110;

  always @(*) begin

    case (ALUOp)
      2'b00:   alu_control = ADD;  // LW /SW instructions
      2'b01: begin  // Branch instructions
        case (funct3)
          3'b000:  alu_control = BEQ;
          3'b001:  alu_control = BNE;
          3'b100:  alu_control = BLT;
          3'b101:  alu_control = BGE;
          default: alu_control = ADD;
        endcase
      end
      2'b10: begin  // R type instructions
        if (funct3 == 3'b000 && funct7 == 7'b0000000) alu_control = ADD;
        else if (funct3 == 3'b000 && funct7 == 7'b0000001) alu_control = MUL;
        else if (funct3 == 3'b001 && funct7 == 7'b0000000) alu_control = SLL;
        else alu_control = ADD;
      end
      default: alu_control = ADD;
    endcase
  end

endmodule
