`timescale 1ps / 1ps
module memwb_tb;
    reg clk = 0, rst = 0, stall = 0, flush = 0;

    reg  [31:0] alu_result_in, mem_data_in, pc_plus4_in;
    reg  [4:0]  rd_in;
    reg         reg_write_in;
    reg  [1:0]  wb_sel_in;

    wire [31:0] alu_result_out, mem_data_out, pc_plus4_out;
    wire [4:0]  rd_out;
    wire        reg_write_out;
    wire [1:0]  wb_sel_out;

    integer errors = 0;

    mem_wb dut (
        .clk(clk), .rst(rst), .stall(stall), .flush(flush),
        .alu_result_in(alu_result_in), .mem_data_in(mem_data_in),
        .pc_plus4_in(pc_plus4_in), .rd_in(rd_in),
        .reg_write_in(reg_write_in), .wb_sel_in(wb_sel_in),
        .alu_result_out(alu_result_out), .mem_data_out(mem_data_out),
        .pc_plus4_out(pc_plus4_out), .rd_out(rd_out),
        .reg_write_out(reg_write_out), .wb_sel_out(wb_sel_out)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("test/unit/memwb_tb.vcd");
        $dumpvars(0, memwb_tb);
    end

    task check(input [31:0] got, input [31:0] exp, input [511:0] name);
    begin
        if (got === exp) $display("PASS: %0s", name);
        else begin
            $display("FAIL: %0s  got=%h exp=%h", name, got, exp);
            errors = errors + 1;
        end
    end
    endtask

    // Tri-source pattern: all three writeback sources get distinct values
    task drive_a;
    begin
        alu_result_in = 32'h11111111;
        mem_data_in   = 32'h22222222;
        pc_plus4_in   = 32'h33333333;
        rd_in         = 5'd9;
        reg_write_in  = 1'b1;
        wb_sel_in     = 2'b01;   // load instruction would pick MEM
    end
    endtask

    task drive_b;
    begin
        alu_result_in = 32'h44444444;
        mem_data_in   = 32'h55555555;
        pc_plus4_in   = 32'h66666666;
        rd_in         = 5'd11;
        reg_write_in  = 1'b1;
        wb_sel_in     = 2'b10;   // jal/jalr would pick PC+4
    end
    endtask

    initial begin
        // 1. capture: all three sources carried
        drive_a();
        @(negedge clk);
        #1
        check(alu_result_out, 32'h11111111, "capture: alu_result_out");
        check(mem_data_out, 32'h22222222, "capture: mem_data_out");
        check(pc_plus4_out, 32'h33333333, "capture: pc_plus4_out");
        check({27'b0, rd_out}, 32'd9, "capture: rd_out");
        check({31'b0, reg_write_out}, 32'd1, "capture: reg_write_out");
        check({30'b0, wb_sel_out}, 32'd1, "capture: wb_sel_out");

        // 2. stall: hold pattern A
        drive_b();
        stall = 1;
        @(negedge clk);
        #1
        check(alu_result_out, 32'h11111111, "stall: alu_result_out held");
        check(mem_data_out, 32'h22222222, "stall: mem_data_out held");
        check(pc_plus4_out, 32'h33333333, "stall: pc_plus4_out held");
        check({30'b0, wb_sel_out}, 32'd1, "stall: wb_sel_out held");

        // 3. flush: bubble (reg_write dead -> no regfile write)
        drive_b();
        stall = 0; flush = 1;
        @(negedge clk);
        #1
        check(alu_result_out, 32'd0, "flush: alu_result_out zeroed");
        check(mem_data_out, 32'd0, "flush: mem_data_out zeroed");
        check(pc_plus4_out, 32'd0, "flush: pc_plus4_out zeroed");
        check({31'b0, reg_write_out}, 32'd0, "flush: reg_write_out zeroed");

        // 4. re-enable: pattern B (jal-style, wb_sel=PC+4 source)
        drive_b();
        flush = 0;
        @(negedge clk);
        #1
        check(alu_result_out, 32'h44444444, "re-enable: alu_result_out = B");
        check(mem_data_out, 32'h55555555, "re-enable: mem_data_out = B");
        check(pc_plus4_out, 32'h66666666, "re-enable: pc_plus4_out = B");
        check({30'b0, wb_sel_out}, 32'd2, "re-enable: wb_sel_out = PC+4");

        $display("----");
        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule


