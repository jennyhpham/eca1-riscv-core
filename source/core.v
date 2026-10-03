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
