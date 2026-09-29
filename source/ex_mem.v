`timescale 1ps / 1ps
module ex_mem (
    input wire clk,
    rst,
    en,
    flush,

    // Data
    input wire [31:0] alu_result_in,
    store_data_in,
    input wire [ 4:0] rd_in,

    // Control signals
    input wire reg_write_in,
    mem_read_in,
    mem_write_in,
    input wire [1:0] wb_sel_in,

    // OUTPUT
    output reg [31:0] alu_result_out,
    store_data_out,
    output reg [ 4:0] rd_out,

    output reg reg_write_out,
    mem_read_out,
    mem_write_out,
    output reg [1:0] wb_sel_out
);

  always @(posedge clk) begin
    if (rst || flush) begin
      alu_result_out <= 0;
      store_data_out <= 0;
      rd_out         <= 0;
      reg_write_out  <= 0;
      mem_read_out   <= 0;
      mem_write_out  <= 0;
      wb_sel_out     <= 0;
    end else if (en) begin
      alu_result_out <= alu_result_in;
      store_data_out <= store_data_in;
      rd_out         <= rd_in;
      reg_write_out  <= reg_write_in;
      mem_read_out   <= mem_read_in;
      mem_write_out  <= mem_write_in;
      wb_sel_out     <= wb_sel_in;
    end
  end

endmodule
