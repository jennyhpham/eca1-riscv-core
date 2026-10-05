`timescale 1ps / 1ps

module regfile #(
    parameter DATA_WIDTH = 32,
    parameter REGISTER_ADDRESS_WIDTH = 5
) (
    input wire clk,
    input wire rst,
    input wire write_enable,
    input wire [(REGISTER_ADDRESS_WIDTH - 1):0] raddr1,
    input wire [(REGISTER_ADDRESS_WIDTH - 1):0] raddr2,
    input wire [(REGISTER_ADDRESS_WIDTH - 1):0] waddr,
    input wire [(DATA_WIDTH - 1):0] wdata,
    output wire [(DATA_WIDTH - 1):0] rdata1,
    output wire [(DATA_WIDTH - 1):0] rdata2
);

  // Initialize the register file with 32 registers of 32 bits each
  reg [31:0] registers[0:31];
  integer i;

  // On the rising edge of the clock:
  always @(posedge clk) begin
    if (rst) begin
      // Reset all registers to 0
      for (i = 0; i < 32; i = i + 1) begin
        registers[i] <= 32'b0;
      end
    end else if (write_enable && waddr != 5'd0) begin
      // Write only if address is not zero and signal is enabled
      registers[waddr] <= wdata;
    end
  end

  // Bypassing logic
  assign rdata1 = (raddr1 == 5'd0) ? 32'b0 :  
    (write_enable && !rst && (waddr == raddr1) ? wdata : 
    registers[raddr1]);

  assign rdata2 = 
    (raddr2 == 5'd0) ? 32'b0 :
    (write_enable && !rst && (waddr == raddr2) ? wdata : 
    registers[raddr2]);

endmodule

