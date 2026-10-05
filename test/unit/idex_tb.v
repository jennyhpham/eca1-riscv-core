`timescale 1ps / 1ps
module idex_tb;
    reg clk = 0, rst = 0, en = 1, flush = 0;

    reg  [31:0] pc_in, pc_plus4_in, rs1_data_in, rs2_data_in, imm_in;
    reg  [4:0]  rs1_in, rs2_in, rd_in;
    reg         reg_write_in, mem_read_in, mem_write_in, alu_src2_imm_in;
    reg         is_jal_in, is_jalr_in;
    reg  [3:0]  alu_op_in;
    reg  [2:0]  branch_op_in;
    reg  [1:0]  wb_sel_in;

    wire [31:0] pc_out, pc_plus4_out, rs1_data_out, rs2_data_out, imm_out;
    wire [4:0]  rs1_out, rs2_out, rd_out;
    wire        reg_write_out, mem_read_out, mem_write_out, alu_src2_imm_out;
    wire        is_jal_out, is_jalr_out;
    wire [3:0]  alu_op_out;
    wire [2:0]  branch_op_out;
    wire [1:0]  wb_sel_out;

    integer errors = 0;

    id_ex dut (
        .clk(clk), .rst(rst), .en(en), .flush(flush),
        .pc_in(pc_in),
        .pc_plus4_in(pc_plus4_in),
        .rs1_data_in(rs1_data_in), .rs2_data_in(rs2_data_in), .imm_in(imm_in),
        .rs1_in(rs1_in), .rs2_in(rs2_in), .rd_in(rd_in),
        .reg_write_in(reg_write_in), .mem_read_in(mem_read_in),
        .mem_write_in(mem_write_in), .alu_src2_imm_in(alu_src2_imm_in),
        .is_jal_in(is_jal_in), .is_jalr_in(is_jalr_in),
        .alu_op_in(alu_op_in), .branch_op_in(branch_op_in),
        .wb_sel_in(wb_sel_in),
        .pc_out(pc_out),
        .pc_plus4_out(pc_plus4_out),
        .rs1_data_out(rs1_data_out), .rs2_data_out(rs2_data_out), .imm_out(imm_out),
        .rs1_out(rs1_out), .rs2_out(rs2_out), .rd_out(rd_out),
        .reg_write_out(reg_write_out), .mem_read_out(mem_read_out),
        .mem_write_out(mem_write_out), .alu_src2_imm_out(alu_src2_imm_out),
        .is_jal_out(is_jal_out), .is_jalr_out(is_jalr_out),
        .alu_op_out(alu_op_out), .branch_op_out(branch_op_out),
        .wb_sel_out(wb_sel_out)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("test/unit/idex_tb.vcd");
        $dumpvars(0, idex_tb);
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

    // Distinctive pattern A: every field gets a unique value
    task drive_a;
    begin
        pc_in = 32'h00000040; pc_plus4_in = 32'h00000044; rs1_data_in = 32'h11111111;
        rs2_data_in = 32'h22222222; imm_in = 32'h33333333;
        rs1_in = 5'd5; rs2_in = 5'd6; rd_in = 5'd7;
        reg_write_in = 1'b1; mem_read_in = 1'b1; mem_write_in = 1'b1;
        alu_src2_imm_in = 1'b1; is_jal_in = 1'b1; is_jalr_in = 1'b1;
        alu_op_in = 4'b0101; branch_op_in = 3'b101; wb_sel_in = 2'b10;
    end
    endtask

    // Different pattern B
    task drive_b;
    begin
        pc_in = 32'h00000080; pc_plus4_in = 32'h00000084; rs1_data_in = 32'h44444444;
        rs2_data_in = 32'h55555555; imm_in = 32'h66666666;
        rs1_in = 5'd8; rs2_in = 5'd9; rd_in = 5'd10;
        reg_write_in = 1'b0; mem_read_in = 1'b0; mem_write_in = 1'b0;
        alu_src2_imm_in = 1'b0; is_jal_in = 1'b0; is_jalr_in = 1'b0;
        alu_op_in = 4'b0010; branch_op_in = 3'b010; wb_sel_in = 2'b01;
    end
    endtask

    // All stimulus on the NEGEDGE; checks 1ns after the following POSEDGE.
    initial begin
        drive_a();
        @(negedge clk);   // posedge captures pattern A
        #1;
        // 1. capture
        check(pc_out, 32'h00000040, "capture: pc_out");
        check(pc_plus4_out, 32'h00000044, "capture: pc_plus4_out");
        check(rs1_data_out, 32'h11111111, "capture: rs1_data_out");
        check(rs2_data_out, 32'h22222222, "capture: rs2_data_out");
        check(imm_out, 32'h33333333, "capture: imm_out");
        check({27'b0, rs1_out}, 32'd5, "capture: rs1_out");
        check({27'b0, rs2_out}, 32'd6, "capture: rs2_out");
        check({27'b0, rd_out}, 32'd7, "capture: rd_out");
        check({31'b0, reg_write_out}, 32'd1, "capture: reg_write_out");
        check({31'b0, mem_read_out}, 32'd1, "capture: mem_read_out");
        check({31'b0, mem_write_out}, 32'd1, "capture: mem_write_out");
        check({31'b0, alu_src2_imm_out}, 32'd1, "capture: alu_src2_imm_out");
        check({31'b0, is_jal_out}, 32'd1, "capture: is_jal_out");
        check({31'b0, is_jalr_out}, 32'd1, "capture: is_jalr_out");
        check({28'b0, alu_op_out}, 32'h5, "capture: alu_op_out");
        check({29'b0, branch_op_out}, 32'h5, "capture: branch_op_out");
        check({30'b0, wb_sel_out}, 32'h2, "capture: wb_sel_out");

        // 2. stall: en=0, change inputs, outputs must hold pattern A
        drive_b();
        en = 0;
        @(negedge clk);
        #1;
        check(rs1_data_out, 32'h11111111, "stall: rs1_data_out held (input was B)");
        check(imm_out, 32'h33333333, "stall: imm_out held");
        check(pc_plus4_out, 32'h00000044, "stall: pc_plus4_out held");
        check({28'b0, alu_op_out}, 32'h5, "stall: alu_op_out held");
        check({30'b0, wb_sel_out}, 32'h2, "stall: wb_sel_out held");

        // 3. flush: en=1, flush=1, outputs must zero (bubble)
        drive_b();
        en = 1; flush = 1;
        @(negedge clk);
        #1;
        check(reg_write_out, 32'd0, "flush: reg_write_out zeroed");
        check(mem_write_out, 32'd0, "flush: mem_write_out zeroed");
        check({29'b0, branch_op_out}, 32'd0, "flush: branch_op_out zeroed");
        check({31'b0, is_jalr_out}, 32'd0, "flush: is_jalr_out zeroed");
        check(pc_plus4_out, 32'd0, "flush: pc_plus4_out zeroed");
        check(rs1_data_out, 32'd0, "flush: rs1_data_out zeroed");
        check({30'b0, wb_sel_out}, 32'd0, "flush: wb_sel_out zeroed");

        // 4. re-enable: flush=0, en=1, pattern B captured
        drive_b();
        flush = 0;
        @(negedge clk);
        #1;
        check(pc_out, 32'h00000080, "re-enable: pc_out = pattern B");
        check(pc_plus4_out, 32'h00000084, "re-enable: pc_plus4_out = pattern B");
        check(rs2_data_out, 32'h55555555, "re-enable: rs2_data_out");
        check({28'b0, alu_op_out}, 32'h2, "re-enable: alu_op_out");
        check({30'b0, wb_sel_out}, 32'h1, "re-enable: wb_sel_out");

        $display("----");
        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
