`timescale 1ps / 1ps

module if_id (
    input wire clk,
    rst,
    stall,
    flush,

    input wire [31:0] pc_in,
    input wire [31:0] pc_plus4_in,
    input wire [31:0] instr_in,

    output reg [31:0] pc_out,
    output reg [31:0] pc_plus4_out,
    output reg [31:0] instr_out
);

  always @(posedge clk) begin
    if (rst || flush) begin
      pc_out       <= 0;
      pc_plus4_out <= 0;
      instr_out    <= 0;
    end else if (!stall) begin
      pc_out       <= pc_in;
      pc_plus4_out <= pc_plus4_in;
      instr_out    <= instr_in;
    end
  end

endmodule

