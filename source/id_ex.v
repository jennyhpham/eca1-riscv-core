`timescale 1ps / 1ps

module id_ex (
    input wire clk,
    rst,
    en,
    flush,

    // Data
    input wire [31:0] pc_in,  //needed for branch/jal
    input wire [31:0] pc_plus4_in,
    input wire [31:0] rs1_data_in,
    rs2_data_in,
    imm_in,

    // Registers 
    input wire [4:0] rs1_in,
    rs2_in,
    rd_in,

    // Control signals
    input wire reg_write_in,
    mem_read_in,
    mem_write_in,
    alu_src2_imm_in,
    is_jal_in,
    is_jalr_in,

    input wire [3:0] alu_op_in,
    input wire [2:0] branch_op_in,
    input wire [1:0] wb_sel_in,

    // OUTPUT
    output reg [31:0] pc_out,
    output reg [31:0] pc_plus4_out,
    output reg [31:0] rs1_data_out,
    rs2_data_out,
    imm_out,

    // Registers 
    output reg [4:0] rs1_out,
    rs2_out,
    rd_out,

    // Control signals
    output reg reg_write_out,
    mem_read_out,
    mem_write_out,
    alu_src2_imm_out,
    is_jal_out,
    is_jalr_out,

    output reg [3:0] alu_op_out,
    output reg [2:0] branch_op_out,
    output reg [1:0] wb_sel_out
);

  always @(posedge clk) begin
    if (rst || flush) begin
        pc_out           <= 0;
        pc_plus4_out     <= 0;
        rs1_data_out     <= 0;
      rs2_data_out     <= 0;
      imm_out          <= 0;

      rs1_out          <= 0;
      rs2_out          <= 0;
      rd_out           <= 0;

      reg_write_out    <= 0;
      mem_read_out     <= 0;
      mem_write_out    <= 0;
      alu_src2_imm_out <= 0;

      alu_op_out       <= 0;
      branch_op_out    <= 0;

      is_jal_out       <= 0;
      is_jalr_out      <= 0;

      wb_sel_out       <= 0;
    end else if (en) begin
        pc_out           <= pc_in;
        pc_plus4_out     <= pc_plus4_in;
        rs1_data_out    <= rs1_data_in;
      rs2_data_out     <= rs2_data_in;
      imm_out          <= imm_in;

      rs1_out          <= rs1_in;
      rs2_out          <= rs2_in;
      rd_out           <= rd_in;

      reg_write_out    <= reg_write_in;
      mem_read_out     <= mem_read_in;
      mem_write_out    <= mem_write_in;
      alu_src2_imm_out <= alu_src2_imm_in;

      alu_op_out       <= alu_op_in;
      branch_op_out    <= branch_op_in;

      is_jal_out       <= is_jal_in;
      is_jalr_out      <= is_jalr_in;

      wb_sel_out       <= wb_sel_in;
    end
  end


endmodule
