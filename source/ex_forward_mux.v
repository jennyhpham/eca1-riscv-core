`timescale 1ps / 1ps

module fwd_mux_rs1#(
    parameter DATA_WIDTH = 32
) (
    input wire[(DATA_WIDTH - 1):0] rs1_data,  // Coming from register file
    input wire[(DATA_WIDTH - 1):0] fw_mem, // Forwarded value from MEM stage
    input wire[(DATA_WIDTH - 1):0] fw_wb,  // Forwarded writeback value 
    input wire[1:0] fwd_rs1_sel,
    output reg[DATA_WIDTH - 1:0] OpA
);

always @(*) begin

    case (fwd_rs1_sel)
        2'b00: OpA = rs1_data;       
        2'b10: OpA = fw_mem;
        2'b01: OpA = fw_wb;
        default: OpA = rs1_data;
    endcase
end

endmodule

module fwd_mux_rs2#(
    parameter DATA_WIDTH = 32
) (
    input wire[DATA_WIDTH - 1:0] rs2_data,  // Coming from register file
    input wire[DATA_WIDTH - 1:0] fw_mem, // Forwarded value from MEM stage
    input wire[DATA_WIDTH - 1:0] fw_wb,  // Forwarded writeback value  
    input wire[1:0] fwd_rs2_sel,
    output reg[DATA_WIDTH - 1:0] OpB
);

always @(*) begin

    case (fwd_rs2_sel)
        2'b00: OpB = rs2_data;       
        2'b10: OpB = fw_mem;
        2'b01: OpB = fw_wb;
        default: OpB = rs2_data;
    endcase
end

endmodule