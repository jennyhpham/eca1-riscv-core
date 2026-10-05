`timescale 1ps / 1ps

module hazard_unit (
    input wire[4:0] rs1_ex,  // Source Register1 no in EX Stage
    input wire[4:0] rs2_ex, // Source Register2 no in EX Stage
    input wire [4:0]  rd_mem, // Destination Register no in MEM Stage
    input wire reg_write_mem, // Register Write Signal from MEM stage
    input wire [4:0]  rd_wb, // Destination Register no in WB Stage
    input wire reg_write_wb, // Register Write Signal from WB stage

    input wire mem_read_ex, // Indicates Memory Read/ load instruction in EX stage
    input wire [4:0]  rd_ex, // Destination Register no in EX Stage
    input wire[4:0] rs1_dec,  // Source Register1 no in Decode Stage
    input wire[4:0] rs2_dec, // Source Register2 no in Decode Stage
    input wire PCSrcE, // Signal which indicates if branch is taken

    output reg [1:0] fwd_rs1_sel, // Control Signal for forward mux1
    output reg [1:0] fwd_rs2_sel, // Control Signal for forward mux2
    output reg stallF, stallD,  // Stall Signals for Fetch , Decode Stages
    output reg flushD, flushE // Flush signal for Decode, EX stage
);

always @(*) begin

    stallF = 0;
    stallD = 0;
    flushD = 0;
    flushE = 0;

    // Forwarding to solve data hazard
    if(reg_write_mem && (rd_mem != 0) && (rs1_ex == rd_mem))
        fwd_rs1_sel = 2'b10;
    else if (reg_write_wb && (rd_wb != 0) && (rs1_ex == rd_wb))
        fwd_rs1_sel = 2'b01;
    else
        fwd_rs1_sel = 2'b00;

    if (reg_write_mem && (rd_mem != 0) && (rs2_ex == rd_mem))
        fwd_rs2_sel = 2'b10;
    else if (reg_write_wb && (rd_wb != 0) && (rs2_ex == rd_wb))
        fwd_rs2_sel = 2'b01;
    else
        fwd_rs2_sel = 2'b00;
    
    // Stalling when load hazard 
    if (mem_read_ex && ((rs1_dec == rd_ex) || (rs2_dec == rd_ex))) begin
        stallF = 1;
        stallD = 1;
        flushE = 1;
    end

    // Flush when a branch is taken (control hazard)
    if (PCSrcE) begin
        flushD = 1;
        flushE = 1;
    end
end

endmodule