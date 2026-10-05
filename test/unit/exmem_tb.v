`timescale 1ps / 1ps
module exmem_tb;
    reg clk = 0, rst = 0, en = 1, flush = 0;

    reg  [31:0] alu_result_in, store_data_in, pc_plus4_in;
    reg  [4:0]  rd_in;
    reg         reg_write_in, mem_read_in, mem_write_in;
    reg  [1:0]  wb_sel_in;

    wire [31:0] alu_result_out, store_data_out, pc_plus4_out;
    wire [4:0]  rd_out;
    wire        reg_write_out, mem_read_out, mem_write_out;
    wire [1:0]  wb_sel_out;

    integer errors = 0;

    ex_mem dut (
        .clk(clk), .rst(rst), .en(en), .flush(flush),
        .alu_result_in(alu_result_in), .store_data_in(store_data_in),
        .pc_plus4_in(pc_plus4_in),
        .rd_in(rd_in),
        .reg_write_in(reg_write_in), .mem_read_in(mem_read_in),
        .mem_write_in(mem_write_in), .wb_sel_in(wb_sel_in),
        .alu_result_out(alu_result_out), .store_data_out(store_data_out),
        .pc_plus4_out(pc_plus4_out),
        .rd_out(rd_out),
        .reg_write_out(reg_write_out), .mem_read_out(mem_read_out),
        .mem_write_out(mem_write_out), .wb_sel_out(wb_sel_out)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("test/unit/exmem_tb.vcd");
        $dumpvars(0, exmem_tb);
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

    task drive_a;
    begin
        alu_result_in = 32'h00000a34;   // store address
        pc_plus4_in = 32'h00000100;
        store_data_in = 32'hdeadbeef;
        rd_in = 5'd7;
        reg_write_in = 1'b1; mem_read_in = 1'b0; mem_write_in = 1'b1;
        wb_sel_in = 2'b00;
    end
    endtask

    task drive_b;
    begin
        alu_result_in = 32'h00000abc;
        pc_plus4_in = 32'h00000200;
        store_data_in = 32'hcafebabe;
        rd_in = 5'd12;
        reg_write_in = 1'b0; mem_read_in = 1'b1; mem_write_in = 1'b0;
        wb_sel_in = 2'b01;
    end
    endtask

    initial begin
        drive_a();
        @(negedge clk);
        #1;
        // 1. capture
        check(alu_result_out, 32'h00000a34, "capture: alu_result_out");
        check(pc_plus4_out, 32'h00000100, "capture: pc_plus4_out");
        check(store_data_out, 32'hdeadbeef, "capture: store_data_out");
        check({27'b0, rd_out}, 32'd7, "capture: rd_out");
        check({31'b0, reg_write_out}, 32'd1, "capture: reg_write_out");
        check({31'b0, mem_read_out}, 32'd0, "capture: mem_read_out");
        check({31'b0, mem_write_out}, 32'd1, "capture: mem_write_out");
        check({30'b0, wb_sel_out}, 32'd0, "capture: wb_sel_out");

        // 2. stall
        drive_b();
        en = 0;
        @(negedge clk);
        #1;
        check(alu_result_out, 32'h00000a34, "stall: alu_result_out held");
        check(pc_plus4_out, 32'h00000100, "stall: pc_plus4_out held");
        check(store_data_out, 32'hdeadbeef, "stall: store_data_out held");
        check({31'b0, mem_write_out}, 32'd1, "stall: mem_write_out held");

        // 3. flush -> bubble
        drive_b();
        en = 1; flush = 1;
        @(negedge clk);
        #1;
        check(reg_write_out, 32'd0, "flush: reg_write_out zeroed");
        check(mem_read_out, 32'd0, "flush: mem_read_out zeroed");
        check(mem_write_out, 32'd0, "flush: mem_write_out zeroed");
        check(store_data_out, 32'd0, "flush: store_data_out zeroed");
        check(pc_plus4_out, 32'd0, "flush: pc_plus4_out zeroed");
        check({30'b0, wb_sel_out}, 32'd0, "flush: wb_sel_out zeroed");

        // 4. re-enable
        drive_b();
        flush = 0;
        @(negedge clk);
        #1;
        check(alu_result_out, 32'h00000abc, "re-enable: alu_result_out = pattern B");
        check(pc_plus4_out, 32'h00000200, "re-enable: pc_plus4_out = pattern B");
        check({27'b0, rd_out}, 32'd12, "re-enable: rd_out");
        check({31'b0, mem_read_out}, 32'd1, "re-enable: mem_read_out");

        $display("----");
        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
