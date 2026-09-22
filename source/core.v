`timescale 1ps/1ps

module CustomCore#(
    // --- SET BY THE TEST BENCH. DO NOT CHANGE ---
    parameter REGISTER_WIDTH = 32,
    parameter REGISTER_ADDRESS_WDITH = 5,
    parameter INSTRUCTION_MEMORY_ADDRESS_WIDTH = 5,
    parameter DATA_MEMORY_ADDRESS_WIDTH = 5
) (
    // --- TEST BENCH PORTS. DO NOT CHANGE ---
    input wire                                            clock,
    input wire                                            reset,

    input wire[(REGISTER_WIDTH - 1): 0]                   instruction_memory_read,
    input wire[(REGISTER_WIDTH - 1): 0]                   data_memory_read,

    output wire[(INSTRUCTION_MEMORY_ADDRESS_WIDTH - 1):0] instruction_memory_address,
    output wire[(DATA_MEMORY_ADDRESS_WIDTH - 1):0]        data_memory_address,
    output wire[(REGISTER_WIDTH - 1):0]                   data_write_value,
    output wire                                           data_write_enable,
    output wire                                           core_finish_signal
);

endmodule

module ALU#(
    parameter DATA_WIDTH = 32
) (
    input wire[DATA_WIDTH - 1:0] A,
    input wire[DATA_WIDTH - 1:0] B,
    input wire[1:0] alu_select,
    output reg[DATA_WIDTH - 1:0] result
);

always @(*) begin
    if (alu_select == 2'b00)
        result = A + B;
    else if (alu_select == 2'b01)
        result = A * B;
    else if (alu_select == 2'b10)
        result = A << B[4:0];
    else
        result = (A < B) ? 1:0;
    end

endmodule
