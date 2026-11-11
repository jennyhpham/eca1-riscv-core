`timescale 1ps / 1ps

module wb_mux (
    input  wire [31:0] alu_result,
    mem_data,
    pc_plus4,
    input  wire [1:0]  wb_sel,
    output reg  [31:0] writeback
);
    always @(*) begin
        case (wb_sel)
        2'b00: writeback = alu_result;
        2'b01: writeback = mem_data;
        2'b10: writeback = pc_plus4;
        default: writeback = alu_result;
        endcase
    end
endmodule
