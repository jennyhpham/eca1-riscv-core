`timescale 1ns/1ps

module lsu_tb;

localparam DATA_WIDTH = 32;
localparam RAM_ADDRESS_WIDTH = 9;

// Clock and reset
reg clock = 0;
reg reset = 1;

// EX/MEM outputs
reg [(DATA_WIDTH - 1):0] alu_result_out;
reg [(DATA_WIDTH - 1):0] store_data_out;
reg mem_write_out;

// LSU outputs / RAM inputs
wire [(RAM_ADDRESS_WIDTH - 1):0] data_memory_address;
wire [(DATA_WIDTH - 1):0]    data_write_value;
wire data_write_enable;

// RAM output
wire [(DATA_WIDTH - 1):0] ram_read_data;


// ---------------------------------
// LSU
// ---------------------------------

lsu #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDRESS_WIDTH(RAM_ADDRESS_WIDTH)
) dut_lsu (
    .alu_result_out(alu_result_out),
    .store_data_out(store_data_out),
    .mem_write_out(mem_write_out),

    .data_memory_address(data_memory_address),
    .data_write_value(data_write_value),
    .data_write_enable(data_write_enable)
);

// ---------------------------------
// RAM
// ---------------------------------

DataMemoryFile #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDRESS_WIDTH(RAM_ADDRESS_WIDTH)
) ram (
    .clock(clock),
    .reset(reset),
    .write_enable(data_write_enable),
    .write_data(data_write_value),
    .register_address(data_memory_address),
    .read_data(ram_read_data)
);

// Initialization
// ------------------------------------

always #5 clock = ~clock;

// Waveforms for WaveTrace
initial begin
    $dumpfile("test/unit/lsu_tb.vcd");
    $dumpvars(0, lsu_tb);
end

initial begin

    alu_result_out = 0;
    store_data_out = 0;
    mem_write_out = 0;

    @(posedge clock);
    reset = 0;

    alu_result_out = 692;
    store_data_out = 50;
    mem_write_out = 1;

    #1;
    if (data_memory_address == 173)
        $display("PASS: Address conversion");
    else
        $display("FAIL: Address conversion");

    @(posedge clock);
    #1;
    if (ram.memory[173] == store_data_out)
        $display("PASS: Store Word");
    else
        $display("FAIL: Store Word");

    alu_result_out = 692;
    store_data_out = 100;
    mem_write_out = 0;

    @(posedge clock);
    #1;
    if (ram.memory[173] == 50)
        $display("PASS: Write disabled, RAM data unchanged");
    else
        $display("FAIL: Write disabled, RAM data changed");
    $finish;
end

endmodule