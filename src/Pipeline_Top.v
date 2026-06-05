`include "PC.v"
`include "PC_Adder.v"
`include "Mux.v"
`include "Instruction_Memory.v"
`include "Control_Unit_Top.v"
`include "Register_File.v"
`include "Sign_Extend.v"
`include "ALU.v"
`include "Branch_Comparator.v"
`include "Data_Memory.v"
`include "Fetch_Cycle.v"
`include "Decode_Cycle.v"
`include "Execute_Cycle.v"
`include "Memory_Cycle.v"
`include "Write_Back_Cycle.v"
`include "Hazard_unit.v"

module Pipeline_top(clk, rst);

    input clk, rst;

    // ---- Hazard Unit control wires ----
    wire        StallF, StallD, FlushE, FlushD;
    wire [1:0]  ForwardAE, ForwardBE;

    // ---- Fetch → Decode wires ----
    wire [31:0] InstrD, PCD, PCPlus4D;

    // ---- Decode → Execute wires ----
    wire        RegWriteE, ALUSrcE, MemWriteE, BranchE, JumpE;
    wire [1:0]  ResultSrcE, ALUSrcAE;
    wire [3:0]  ALUControlE;
    wire [2:0]  Funct3E;
    wire [31:0] RD1_E, RD2_E, Imm_Ext_E, PCE, PCPlus4E;
    wire [4:0]  RD_E, Rs1_E, Rs2_E;

    // ---- Hazard unit inputs from Decode ----
    wire [4:0]  Rs1_D, Rs2_D;

    // ---- Execute → Fetch (branch/jump) ----
    wire        PCSrcE;
    wire [31:0] PCTargetE;

    // ---- Execute → Memory wires ----
    wire        RegWriteM, MemWriteM;
    wire [1:0]  ResultSrcM;
    wire [31:0] ALUResultM, WriteDataM, PCPlus4M;
    wire [4:0]  RD_M;
    wire [2:0]  Funct3M;

    // ---- Memory → Writeback wires ----
    wire        RegWriteW;
    wire [1:0]  ResultSrcW;
    wire [31:0] ALUResultW, ReadDataW, PCPlus4W;
    wire [4:0]  RDW;

    // ---- Writeback → Decode ----
    wire [31:0] ResultW;

    // ----------------------------------------------------------------
    // Fetch Stage
    // ----------------------------------------------------------------
    fetch_cycle fetch(
        .clk       (clk),
        .rst       (rst),
        .PCSrcE    (PCSrcE),
        .PCTargetE (PCTargetE),
        .StallF    (StallF),
        .StallD    (StallD),
        .InstrD    (InstrD),
        .PCD       (PCD),
        .PCPlus4D  (PCPlus4D)
    );

    // ----------------------------------------------------------------
    // Decode Stage
    // ----------------------------------------------------------------
    decode_cycle decode(
        .clk       (clk),
        .rst       (rst),
        .PCSrcE    (PCSrcE),
        .FlushD    (FlushD),
        .StallD    (StallD),
        .InstrD    (InstrD),
        .PCD       (PCD),
        .PCPlus4D  (PCPlus4D),
        .RegWriteW (RegWriteW),
        .RDW       (RDW),
        .ResultW   (ResultW),
        // Outputs
        .RegWriteE (RegWriteE),
        .ALUSrcE   (ALUSrcE),
        .MemWriteE (MemWriteE),
        .ResultSrcE(ResultSrcE),
        .BranchE   (BranchE),
        .ALUControlE(ALUControlE),
        .RD1_E     (RD1_E),
        .RD2_E     (RD2_E),
        .Imm_Ext_E (Imm_Ext_E),
        .RD_E      (RD_E),
        .PCE       (PCE),
        .PCPlus4E  (PCPlus4E),
        .Rs1_E     (Rs1_E),
        .Rs2_E     (Rs2_E),
        .JumpE     (JumpE),
        .ALUSrcAE  (ALUSrcAE),
        .Funct3E   (Funct3E),
        .Rs1_D     (Rs1_D),
        .Rs2_D     (Rs2_D)
    );

    // ----------------------------------------------------------------
    // Execute Stage
    // ----------------------------------------------------------------
    execute_cycle execute(
        .clk         (clk),
        .rst         (rst),
        .FlushE      (FlushE),
        .RegWriteE   (RegWriteE),
        .ALUSrcE     (ALUSrcE),
        .MemWriteE   (MemWriteE),
        .ResultSrcE  (ResultSrcE),
        .BranchE     (BranchE),
        .ALUControlE (ALUControlE),
        .JumpE       (JumpE),
        .ALUSrcAE    (ALUSrcAE),
        .Funct3E     (Funct3E),
        .RD1_E       (RD1_E),
        .RD2_E       (RD2_E),
        .Imm_Ext_E   (Imm_Ext_E),
        .RD_E        (RD_E),
        .PCE         (PCE),
        .PCPlus4E    (PCPlus4E),
        .ResultW     (ResultW),
        .ForwardAE   (ForwardAE),
        .ForwardBE   (ForwardBE),
        .ALUResultM_In(ALUResultM),
        // Outputs
        .PCSrcE      (PCSrcE),
        .PCTargetE   (PCTargetE),
        .RegWriteM   (RegWriteM),
        .ResultSrcM  (ResultSrcM),
        .MemWriteM   (MemWriteM),
        .ALU_ResultM (ALUResultM),
        .WriteDataM  (WriteDataM),
        .RD_M        (RD_M),
        .PCPlus4M    (PCPlus4M),
        .Funct3M     (Funct3M)
    );

    // ----------------------------------------------------------------
    // Memory Stage
    // ----------------------------------------------------------------
    memory_cycle memory(
        .clk        (clk),
        .rst        (rst),
        .RegWriteM  (RegWriteM),
        .ResultSrcM (ResultSrcM),
        .MemWriteM  (MemWriteM),
        .ALUResultM (ALUResultM),
        .WriteDataM (WriteDataM),
        .PCPlus4M   (PCPlus4M),
        .RD_M       (RD_M),
        .Funct3M    (Funct3M),
        // Outputs
        .RegWriteW  (RegWriteW),
        .ResultSrcW (ResultSrcW),
        .ALUResultW (ALUResultW),
        .ReadDataW  (ReadDataW),
        .PCPlus4W   (PCPlus4W),
        .RD_W       (RDW)
    );

    // ----------------------------------------------------------------
    // Write-Back Stage
    // ----------------------------------------------------------------
    write_back_cycle write_back(
        .clk        (clk),
        .rst        (rst),
        .ResultSrcW (ResultSrcW),
        .ALUResultW (ALUResultW),
        .ReadDataW  (ReadDataW),
        .PCPlus4W   (PCPlus4W),
        .ResultW    (ResultW)
    );

    // ----------------------------------------------------------------
    // Hazard Unit
    // ----------------------------------------------------------------
    hazard_unit hazard(
        .rst         (rst),
        .RegWriteM   (RegWriteM),
        .RegWriteW   (RegWriteW),
        .RD_M        (RD_M),
        .RD_W        (RDW),
        .Rs1_E       (Rs1_E),
        .Rs2_E       (Rs2_E),
        .ForwardAE   (ForwardAE),
        .ForwardBE   (ForwardBE),
        .ResultSrcE  (ResultSrcE),
        .RD_E        (RD_E),
        .Rs1_D       (Rs1_D),
        .Rs2_D       (Rs2_D),
        .StallF      (StallF),
        .StallD      (StallD),
        .FlushE      (FlushE),
        .PCSrcE      (PCSrcE),
        .FlushD      (FlushD)
    );

endmodule