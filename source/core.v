`timescale 1ps / 1ps

module CustomCore #(
    // --- SET BY THE TEST BENCH. DO NOT CHANGE ---
    parameter REGISTER_WIDTH = 32,
    parameter REGISTER_ADDRESS_WDITH = 5,
    parameter INSTRUCTION_MEMORY_ADDRESS_WIDTH = 5,
    parameter DATA_MEMORY_ADDRESS_WIDTH = 5
) (
    // --- TEST BENCH PORTS. DO NOT CHANGE ---
    input wire clock,
    input wire reset,

    input wire [(REGISTER_WIDTH - 1):0] instruction_memory_read,
    input wire [(REGISTER_WIDTH - 1):0] data_memory_read,

    output wire [(INSTRUCTION_MEMORY_ADDRESS_WIDTH - 1):0] instruction_memory_address,
    output wire [       (DATA_MEMORY_ADDRESS_WIDTH - 1):0] data_memory_address,
    output wire [                  (REGISTER_WIDTH - 1):0] data_write_value,
    output wire                                            data_write_enable,
    output wire                                            core_finish_signal
);

  // IMPLEMENTATION ONWARD FROM HERE

  // DECLARATIONS OF WIRES

  // Pipeline controls
  wire stallF, stallD, flushD, flushE, redirect;

  // IF Stage
  wire [31:0] pc_out, pc_plus4_out, branch_target;

  // IF/ID Outputs
  wire [31:0] if_id_pc, if_id_pc_plus4, if_id_instr;

  // ID Stage (dec means decoder outputs)
  wire [4:0] dec_rd, dec_rs1, dec_rs2;
  wire [2:0] dec_funct3;
  wire [6:0] dec_funct7;

  wire reg_write, mem_read, mem_write, alusrc, is_branch, is_jal, is_jalr;  // 
  wire [1:0] alu_op, wb_sel, imm_sel;
  wire [2:0] alu_control;
  wire [31:0] rs1_data, rs2_data, imm;

  // ID/EX Outputs
  wire [31:0] id_ex_pc, id_ex_pc_plus4, id_ex_rs1_data, id_ex_rs2_data, id_ex_imm;

  wire [4:0] id_ex_rs1, id_ex_rs2, id_ex_rd;

  wire        id_ex_reg_write, id_ex_mem_read, id_ex_mem_write, id_ex_alu_src, id_ex_is_branch, id_ex_is_jal, id_ex_is_jalr;

  wire [3:0] id_ex_alu_op;
  wire [1:0] id_ex_wb_sel;
  wire [2:0] id_ex_branch_op;

  // EX Stage
  wire [1:0] fwd_rs1_sel, fwd_rs2_sel;
  wire [31:0] opA, opB_fwd, alu_b, alu_result;

  // EX/MEM Outputs
  wire [31:0] ex_mem_alu_result, ex_mem_store_data, ex_mem_pc_plus4;
  wire [4:0] ex_mem_rd;
  wire ex_mem_reg_write, ex_mem_mem_read, ex_mem_mem_write;
  wire [ 1:0] ex_mem_wb_sel;

  // MEM Stage
  wire [31:0] lsu_addr_src;

  // MEM/WB Outputs
  wire [31:0] mem_wb_alu_result, mem_wb_mem_data, mem_wb_pc_plus4;
  wire [ 4:0] mem_wb_rd;
  wire        mem_wb_reg_write;
  wire [ 1:0] mem_wb_wb_sel;

  // WB Stage
  wire [31:0] writeback;

  // Finish signal
  reg         finish_signal_reg;

  // MODULE INSTANTIATIONS
  // IF 
  pc pc_inst (
      .clk(clock),
      .rst(reset),
      .stall(stallF),
      .branch_en(redirect),
      .pc_target(branch_target),
      .pc(pc_out),
      .pc_plus4(pc_plus4_out)
  );

  assign instruction_memory_address = pc_out[8:2]; // byte adress program counter, therefore we convert byte to word address 

  if_id if_id_inst (
      .clk(clock),
      .rst(reset),
      .stall(stallD),
      .flush(flushD),
      .pc_in(pc_out),
      .pc_plus4_in(pc_plus4_out),
      .instr_in(instruction_memory_read),
      .pc_out(if_id_pc),
      .pc_plus4_out(if_id_pc_plus4),
      .instr_out(if_id_instr)
  );

  // ID
  decoder decoder_inst (
      .instr(if_id_instr),
      .rd(dec_rd),
      .rs1(dec_rs1),
      .rs2(dec_rs2),
      .funct3(dec_funct3),
      .funct7(dec_funct7),
      .reg_write(reg_write),
      .mem_read(mem_read),
      .mem_write(mem_write),
      .ALUSrc(alusrc),
      .ALUOp(alu_op),
      .is_branch(is_branch),
      .is_jal(is_jal),
      .is_jalr(is_jalr),
      .wb_sel(wb_sel),
      .imm_sel(imm_sel)
  );

  immgen immgen_inst (
      .instr(if_id_instr),
      .imm_sel(imm_sel),
      .imm(imm)
  );

  ALU_Control alu_control_inst (
      .ALUOp(alu_op),
      .funct3(dec_funct3),
      .funct7(dec_funct7),
      .alu_control(alu_control)
  );

  regfile regfile_inst (
      .clk(clock),
      .rst(reset),
      .write_enable(mem_wb_reg_write),
      .waddr(mem_wb_rd),
      .wdata(writeback),
      .raddr1(dec_rs1),
      .raddr2(dec_rs2),
      .rdata1(rs1_data),
      .rdata2(rs2_data)
  );

  id_ex id_ex_inst (
      .clk             (clock),
      .rst             (reset),
      .stall           (1'b0),
      .flush           (flushE),
      .pc_in           (if_id_pc),
      .pc_plus4_in     (if_id_pc_plus4),
      .rs1_data_in     (rs1_data),
      .rs2_data_in     (rs2_data),
      .imm_in          (imm),
      .rs1_in          (dec_rs1),
      .rs2_in          (dec_rs2),
      .rd_in           (dec_rd),
      .reg_write_in    (reg_write),
      .mem_read_in     (mem_read),
      .mem_write_in    (mem_write),
      .alu_src2_imm_in (alusrc),
      .is_jal_in       (is_jal),
      .is_jalr_in      (is_jalr),
      .alu_op_in       ({1'b0, alu_control}),  // 4-bit field carries the 3-bit code
      .branch_op_in    ({1'b0, alu_op}),       // carry decoder ALUOp: 01 = branch
      .wb_sel_in       (wb_sel),
      .pc_out          (id_ex_pc),
      .pc_plus4_out    (id_ex_pc_plus4),
      .rs1_data_out    (id_ex_rs1_data),
      .rs2_data_out    (id_ex_rs2_data),
      .imm_out         (id_ex_imm),
      .rs1_out         (id_ex_rs1),
      .rs2_out         (id_ex_rs2),
      .rd_out          (id_ex_rd),
      .reg_write_out   (id_ex_reg_write),
      .mem_read_out    (id_ex_mem_read),
      .mem_write_out   (id_ex_mem_write),
      .alu_src2_imm_out(id_ex_alu_src),
      .is_jal_out      (id_ex_is_jal),
      .is_jalr_out     (id_ex_is_jalr),
      .alu_op_out      (id_ex_alu_op),
      .branch_op_out   (id_ex_branch_op),
      .wb_sel_out      (id_ex_wb_sel)
  );

  // EX
  fwd_mux_rs1 fwd_rs1_inst (
      .rs1_data(id_ex_rs1_data),
      .fw_mem(ex_mem_alu_result),
      .fw_wb(writeback),
      .fwd_rs1_sel(fwd_rs1_sel),
      .OpA(opA)
  );

  fwd_mux_rs2 fwd_rs2_inst (
      .rs2_data(id_ex_rs2_data),
      .fw_mem(ex_mem_alu_result),
      .fw_wb(writeback),
      .fwd_rs2_sel(fwd_rs2_sel),
      .OpB(opB_fwd)
  );

  ALU_SrcMux alusrc_mux_inst (
      .rdata2(opB_fwd),
      .imm(id_ex_imm),
      .ALUSrc(id_ex_alu_src),
      .B(alu_b)
  );

  ALU alu_inst (
      .A(opA),
      .B(alu_b),
      .alu_control(id_ex_alu_op[2:0]),
      .alu_result(alu_result),
      .zero_flag(),
      .neg_flag()
  );

  ex_mem ex_mem_inst (
      .clk(clock),
      .rst(reset),
      .stall(1'b0),
      .flush(1'b0),
      .alu_result_in(alu_result),
      .store_data_in(opB_fwd),  // forwarded store data
      .pc_plus4_in(id_ex_pc_plus4),
      .rd_in(id_ex_rd),
      .reg_write_in(id_ex_reg_write),
      .mem_read_in(id_ex_mem_read),
      .mem_write_in(id_ex_mem_write),
      .wb_sel_in(id_ex_wb_sel),
      .alu_result_out(ex_mem_alu_result),
      .store_data_out(ex_mem_store_data),
      .pc_plus4_out(ex_mem_pc_plus4),
      .rd_out(ex_mem_rd),
      .reg_write_out(ex_mem_reg_write),
      .mem_read_out(ex_mem_mem_read),
      .mem_write_out(ex_mem_mem_write),
      .wb_sel_out(ex_mem_wb_sel)
  );

  // EX HELPER
  assign branch_target = id_ex_is_jalr ? alu_result : (id_ex_pc + id_ex_imm);
  assign redirect = (id_ex_branch_op[1:0] == 2'b01 && alu_result[0]) || id_ex_is_jal || id_ex_is_jalr;

  always @(posedge clock) begin
    if (reset) finish_signal_reg <= 0;
    else if (id_ex_is_jalr && alu_result == 0) finish_signal_reg <= 1;
  end
  assign core_finish_signal = finish_signal_reg;

  // MEM 
  assign lsu_addr_src = ex_mem_mem_write ? ex_mem_alu_result :  // store wins port
      id_ex_mem_read ? alu_result :  // load addr from EX
      ex_mem_alu_result;

  lsu lsu_inst (
      .alu_result_out(lsu_addr_src),
      .store_data_out(ex_mem_store_data),
      .mem_write_out(ex_mem_mem_write),
      .data_memory_address(data_memory_address),
      .data_write_value(data_write_value),
      .data_write_enable(data_write_enable)
  );

  mem_wb mem_wb_inst (
      .clk(clock),
      .rst(reset),
      .stall(1'b0),
      .flush(1'b0),
      .alu_result_in(ex_mem_alu_result),
      .mem_data_in(data_memory_read),
      .pc_plus4_in(ex_mem_pc_plus4),
      .rd_in(ex_mem_rd),
      .reg_write_in(ex_mem_reg_write),
      .wb_sel_in(ex_mem_wb_sel),
      .alu_result_out(mem_wb_alu_result),
      .mem_data_out(mem_wb_mem_data),
      .pc_plus4_out(mem_wb_pc_plus4),
      .rd_out(mem_wb_rd),
      .reg_write_out(mem_wb_reg_write),
      .wb_sel_out(mem_wb_wb_sel)
  );

  // WB
  wb_mux wb_mux_inst (
      .alu_result(mem_wb_alu_result),
      .mem_data(mem_wb_mem_data),
      .pc_plus4(mem_wb_pc_plus4),
      .wb_sel(mem_wb_wb_sel),
      .writeback(writeback)
  );

  // Hazard
  hazard_unit hazard_inst (
      .rs1_ex(id_ex_rs1),
      .rs2_ex(id_ex_rs2),
      .rd_mem(ex_mem_rd),
      .reg_write_mem(ex_mem_reg_write),
      .rd_wb(mem_wb_rd),
      .reg_write_wb(mem_wb_reg_write),
      .mem_read_ex(id_ex_mem_read),
      .rd_ex(id_ex_rd),
      .rs1_dec(dec_rs1),
      .rs2_dec(dec_rs2),
      .PCSrcE(redirect),
      .fwd_rs1_sel(fwd_rs1_sel),
      .fwd_rs2_sel(fwd_rs2_sel),
      .stallF(stallF),
      .stallD(stallD),
      .flushD(flushD),
      .flushE(flushE)
  );

endmodule
