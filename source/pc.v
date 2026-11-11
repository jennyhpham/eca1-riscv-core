`timescale 1ps / 1ps

module pc (
    input wire clk,
    rst,
    stall,
    branch_en,
    input wire [31:0] pc_target,
    output reg [31:0] pc,
    output wire [31:0] pc_plus4
);

  assign pc_plus4 = pc + 32'd4;

  always @(posedge clk) begin
    if (rst) begin
      pc <= 0;
    end else if (branch_en) begin
      pc <= pc_target;
    end else if (!stall) begin
      pc <= pc + 32'd4;
    end
    // stall == 1: hold
  end
endmodule


