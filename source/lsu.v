`timescale 1ps / 1ps

module lsu #(
    parameter DATA_WIDTH = 32,
    parameter ADDRESS_WIDTH = 9
)(
    // From EX/MEM
    input  wire [(DATA_WIDTH - 1): 0]    alu_result_out,
    input  wire [(DATA_WIDTH - 1): 0]    store_data_out,
    input  wire                     mem_write_out,

    output reg [(ADDRESS_WIDTH - 1): 0] data_memory_address,
    output reg [(DATA_WIDTH - 1): 0]    data_write_value,
    output reg                    data_write_enable
);

always @(*) begin

  data_memory_address = alu_result_out >> 2;

  data_write_value = store_data_out;

  data_write_enable = mem_write_out;

end

endmodule