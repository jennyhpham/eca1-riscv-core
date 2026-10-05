module decoder (
    input  wire [31:0] instr,
    output wire [4:0]  rd, rs1, rs2,          
    output wire [2:0]  funct3,           
    output wire [6:0]  funct7,       
    output reg         reg_write, mem_read, mem_write,
    output reg         ALUSrc,                //  imm vs rs2 for operand B
    output reg  [1:0]  ALUOp,                 // 00 mem-addr(ADD), 01 branch, 10 arith
    output reg         is_branch, is_jal, is_jalr,
    output reg  [1:0]  wb_sel,                // 00 ALU, 01 MEM, 10 PC+4
    output reg  [1:0]  imm_sel                // 00 I, 01 S, 10 B, 11 J
);

// Field's positions are fixed in the instruction format for the instructions needed in this project
assign rd    = instr[11:7];
assign funct3 = instr[14:12];
assign rs1   = instr[19:15];
assign rs2   = instr[24:20];
assign funct7 = instr[31:25];

wire [6:0] opcode = instr[6:0];

always @(*) begin
    // Default values for control signals 
    reg_write = 0;
    mem_read = 0;
    mem_write = 0;
    ALUSrc = 0; // Operand B from rs2
    ALUOp = 2'b00;
    is_branch = 0;
    is_jal = 0;
    is_jalr = 0;
    wb_sel = 2'b00; // Default to ALU result
    imm_sel = 2'b00; // Default to I-type immediate

    // Values that are 0 isn't included as it is already set by default
    case (opcode)
        7'b0110011: begin // R-type
            reg_write = 1;
            ALUOp = 2'b10; 
        end
        7'b0010011: begin // I-type (arithmetic)
            reg_write = 1;
            ALUSrc = 1;
            ALUOp = 2'b10; 
        end
        7'b0000011: begin // Load (I-type)
            reg_write = 1;
            mem_read = 1;
            ALUSrc = 1; 
            wb_sel = 2'b01; 
        end
        7'b0100011: begin // Store (S-type)
            mem_write = 1;
            ALUSrc = 1; 
            imm_sel = 2'b01;
        end
        7'b1100011: begin // Branch (B-type)
            is_branch = 1;
            ALUSrc = 0;
            ALUOp = 2'b01; 
            imm_sel = 2'b10; 
        end
        7'b1101111: begin // JAL (J-type)
            reg_write = 1;
            is_jal    = 1;
            wb_sel    = 2'b10;
            imm_sel   = 2'b11;
        end
        7'b1100111: begin // JALR (J-type)
            reg_write = 1;
            is_jalr   = 1;
            ALUSrc    = 1;
            wb_sel    = 2'b10;
            imm_sel   = 2'b00;
        end

        endcase
end

endmodule