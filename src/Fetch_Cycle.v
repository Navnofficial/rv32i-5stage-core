/*
`include "Instruction_Memory.v"
`include "PC.v"
`include "PC_Adder.v"
`include "Mux.v"
*/
module fetch_cycle(clk, rst, PCSrcE, PCTargetE, StallF, StallD, InstrD, PCD, PCPlus4D);

    input        clk, rst;
    input        PCSrcE;          // branch/jump taken
    input        StallF;          // load-use stall
    input        StallD;          // load-use stall for IF/ID register
    input  [31:0] PCTargetE;
    output [31:0] InstrD;
    output [31:0] PCD, PCPlus4D;

    // Pipeline registers
    reg [31:0] InstrF_reg;
    reg [31:0] PCF_reg;
    reg [31:0] PCPlus4F_reg;

    // Internal wires
    wire [31:0] PC_F;
    wire [31:0] PCPlus4F;
    wire [31:0] PCF;
    wire [31:0] InstrF;

    // PC mux: branch/jump target or PC+4
    Mux PC_MUX(
        .a(PCPlus4F),
        .b(PCTargetE),
        .s(PCSrcE),
        .c(PC_F)
    );

    // PC+4 adder
    PC_Adder PC_adder(
        .a(PCF),
        .b(32'h0000_0004),
        .c(PCPlus4F)
    );

    // Program Counter (with stall)
    PC_Module Program_Counter(
        .clk(clk),
        .rst(rst),
        .StallF(StallF),
        .PC(PCF),
        .PC_Next(PC_F)
    );

    // Instruction Memory
    Instruction_Memory I_Memory(
        .rst(rst),
        .A(PCF),
        .RD(InstrF)
    );

    // IF/ID pipeline register
    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0 || PCSrcE) begin
            // Reset OR branch/jump taken: flush IF/ID (insert NOP)
            InstrF_reg   <= 32'h0000_0013; // NOP
            PCF_reg      <= 32'h0000_0000;
            PCPlus4F_reg <= 32'h0000_0000;
        end else if (StallD) begin
            // Stall: hold IF/ID register values
            InstrF_reg   <= InstrF_reg;
            PCF_reg      <= PCF_reg;
            PCPlus4F_reg <= PCPlus4F_reg;
        end else begin
            InstrF_reg   <= InstrF;
            PCF_reg      <= PCF;
            PCPlus4F_reg <= PCPlus4F;
        end
    end

    assign InstrD   = (rst == 1'b0) ? 32'h0000_0013 : InstrF_reg;
    assign PCD      = (rst == 1'b0) ? 32'h0000_0000 : PCF_reg;
    assign PCPlus4D = (rst == 1'b0) ? 32'h0000_0000 : PCPlus4F_reg;

endmodule