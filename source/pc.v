`timescale 1ps/1ps

module pc (
    input wire clk, rst, en, branch_en,
    input wire [31:0] pc_target,
    output reg [31:0] pc
);

  always @(posedge clk) begin
    if (rst) begin
      pc <= 0;
    end else if (branch_en) begin
      pc <= pc_target;
    end else if (en) begin
      pc <= pc + 32'd4;
    end
    // en == 0: hold (stall)
  end
endmodule
