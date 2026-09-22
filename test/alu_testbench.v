`timescale 1ps/1ps

module alu_tb;

localparam DATA_WIDTH = 32;

// TestBench bindings
// -----------------------------------

reg [(DATA_WIDTH - 1) : 0] A;
reg [(DATA_WIDTH - 1) : 0] B;
reg [1 : 0] alu_select;
wire [(DATA_WIDTH - 1) : 0] result;


// ALU
// ------------------------------------
ALU#(
    .DATA_WIDTH(DATA_WIDTH)
) alu_dut (
    .A(A),
    .B(B),
    .alu_select(alu_select),
    .result(result)
);

// Initialization
// ------------------------------------

initial begin

    // Addition
    // ------------------------------------ 
    A = 10;
    B = 5;
    alu_select = 2'b00;

    #4; //wait 4 ns

    if (result == 15)
        $display("PASS: ADD, result = %d", result);
    else
        $display("FAIL: ADD, result = %d", result);

    // Multiplication
    // -----------------------------------
    A = 10;
    B = 5;
    alu_select = 2'b01;

    #4;

    if (result == 50)
        $display("PASS: MUL, result = %d", result);
    else
        $display("FAIL: MUL, result = %d", result);

    // Shift Left
    // -----------------------------------
    A = 10;
    B = 5;
    alu_select = 2'b10;

    #4;

    if (result == 320)
        $display("PASS: SLL, result = %d", result);
    else
        $display("FAIL: SLL, result = %d", result);

    // Shift Left
    // -----------------------------------
    A = 1;
    B = 31;
    alu_select = 2'b10;

    #4;

    if (result == 2147483648)
        $display("PASS: SLL, result = %d", result);
    else
        $display("FAIL: SLL, result = %d", result);

    // Less than
    // -----------------------------------
    A = 10;
    B = 5;
    alu_select = 2'b11;

    #4;

    if (result == 0)
        $display("PASS: LT, result = %d", result);
    else
        $display("FAIL: LT, result = %d", result);

    // Less than
    // -----------------------------------
    A = -5;
    B = 2;
    alu_select = 2'b11;

    #4;

    if (result == 1)
        $display("PASS: LT, result = %d", result);
    else
        $display("FAIL: LT, result = %d", result);

end

initial begin
  $dumpfile("wave.vcd");
  $dumpvars(0, alu_tb);
end

endmodule