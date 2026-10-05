`timescale 1ps / 1ps

module if_id(
    input wire clk, rst,en, flush,

    input wire [31:0] pc_in,
    input wire [31:0] inst_in,

    output reg [31:0] pc_out,
    output reg [31:0] inst_out
);

  always @(posedge clk) begin
    if (rst || flush) begin
      pc_out   <= 0;
      inst_out <= 0;
    end else if (en) begin
      pc_out   <= pc_in;
      inst_out <= inst_in;
    end
  end
   
endmodule