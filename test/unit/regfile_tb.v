`timescale 1ps / 1ps
module regfile_tb;
  reg clk = 0, rst = 1, we = 0;
  reg [4:0] waddr, raddr1, raddr2;
  reg [31:0] wdata;
  wire [31:0] rdata1, rdata2;
  integer errors = 0;

  regfile #(
      .DATA_WIDTH(32),
      .REGISTER_ADDRESS_WIDTH(5)
  ) dut (
      .clk(clk),
      .rst(rst),
      .write_enable(we),
      .waddr(waddr),
      .wdata(wdata),
      .raddr1(raddr1),
      .rdata1(rdata1),
      .raddr2(raddr2),
      .rdata2(rdata2)
  );

  always #5 clk = ~clk;

  // Waveforms for WaveTrace
  initial begin
    $dumpfile("test/unit/regfile_tb.vcd");
    $dumpvars(0, regfile_tb);
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

  // All stimulus changes happen on the NEGEDGE, so every value is stable
  // across the DUT's posedge sampling. Reads are checked 1ns later.
  initial begin
    // 1. reset clears everything (posedge at t=5 clears with rst=1)
    @(negedge clk);
    rst = 0;
    raddr1 = 5'd10;
    raddr2 = 5'd20;
    @(negedge clk);
    check(rdata1, 32'h0, "reset: r10 == 0");
    check(rdata2, 32'h0, "reset: r20 == 0");

    // 2. write + read back on both ports
    we = 1;
    waddr = 5'd5;
    wdata = 32'hDEADBEEF;
    @(negedge clk);
    raddr1 = 5'd5;
    raddr2 = 5'd5;
    @(negedge clk);
    check(rdata1, 32'hDEADBEEF, "write r5, read port1");
    check(rdata2, 32'hDEADBEEF, "write r5, read port2");

    // 3. write to x0 is dropped
    waddr = 5'd0;
    wdata = 32'h12345678;
    @(negedge clk);
    raddr1 = 5'd0;
    #1 check(rdata1, 32'h0, "write to x0 ignored");

    // 4. bypass: we=1, waddr=r7, raddr=r7 in the same cycle
    waddr  = 5'd7;
    wdata  = 32'hCAFEBABE;
    raddr1 = 5'd7;
    raddr2 = 5'd7;
    #1 check(rdata1, 32'hCAFEBABE, "bypass port1 (same-cycle write+read r7)");
    check(rdata2, 32'hCAFEBABE, "bypass port2 (same-cycle write+read r7)");
    @(negedge clk);

    // 5. we=0: read returns stored value (no bypass leak)
    we = 0;
    #1 check(rdata1, 32'hCAFEBABE, "stored value after write (we=0)");

    // 6. no false bypass: write r8 while reading r5
    we = 1;
    waddr = 5'd8;
    wdata = 32'h11111111;
    raddr1 = 5'd5;
    #1 check(rdata1, 32'hDEADBEEF, "no false bypass (write r8, read r5)");
    @(negedge clk);

    // 7. x0 read during a write to x0 stays 0 (bypass corner)
    we = 1;
    waddr = 5'd0;
    wdata = 32'hAAAAAAAA;
    raddr1 = 5'd0;
    #1 check(rdata1, 32'h0, "x0 read during write to x0");

    $display("----");
    if (errors == 0) $display("ALL TESTS PASSED");
    else $display("%0d TEST(S) FAILED", errors);
    $finish;
  end
endmodule
