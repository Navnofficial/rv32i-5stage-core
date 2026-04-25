`include "PC.v"
`include "PC_Adder.v"
`include "Mux.v"
`include "Instruction_Memory.v"
`include "Control_Unit_Top.v"
`include "Register_File.v"
`include "Sign_Extend.v"
`include "ALU.v"
`include "Fetch_Cycle.v"
`include "Decode_Cycle.v"
`include "Execute_Cycle.v"
`include "Memory_Cycle.v"
`include "Write_Back_Cycle.v"
`include "Hazard_unit.v"


module Pipeline_top(clk, rst);

    //Declaration of I/O
    input clk, rst ;

    //Declaration of wires
    wire PCSrcE, RegWriteW, RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE, RegWriteM, ResultSrcM, MemWriteM ;
    wire [2:0] ALUControlE ;
    wire [1:0] ForwardAE, ForwardBE ;
    wire [4:0] RDW, RD_E, RD_M, Rs1_E, Rs2_E ;
    wire [31:0] PCTargetE, InstrD, PCD, PCPlus4D, ResultW, RD1_E, RD2_E, Imm_Ext_E, PCE, PCPlus4E ;
    wire [31:0] WriteDataM, PCPlus4M, ALUResultM;
    wire [31:0] ALUResultW, ReadDataW, PCPlus4W;
    wire ResultSrcW;

    //Fetch_Cycle
    fetch_cycle fetch(
                        .clk(clk), 
                        .rst(rst), 
                        .PCSrcE(PCSrcE), 
                        .PCTargetE(PCTargetE), 
                        .InstrD(InstrD), 
                        .PCD(PCD), 
                        .PCPlus4D(PCPlus4D)
                    );

    //Decoder_Cycle
    decode_cycle decode(
                        .clk(clk), 
                        .rst(rst), 
                        .PCSrcE(PCSrcE),
                        .InstrD(InstrD), 
                        .PCD(PCD), 
                        .PCPlus4D(PCPlus4D), 
                        .RegWriteW(RegWriteW), 
                        .RDW(RDW), 
                        .ResultW(ResultW),
                        .RegWriteE(RegWriteE), 
                        .ALUSrcE(ALUSrcE), 
                        .MemWriteE(MemWriteE), 
                        .ResultSrcE(ResultSrcE), 
                        .BranchE(BranchE), 
                        .ALUControlE(ALUControlE), 
                        .RD1_E(RD1_E), 
                        .RD2_E(RD2_E), 
                        .Imm_Ext_E(Imm_Ext_E), 
                        .RD_E(RD_E), 
                        .PCE(PCE), 
                        .PCPlus4E(PCPlus4E),
                        .Rs1_E(Rs1_E),
                        .Rs2_E(Rs2_E)
                        );

    //Execute_Cycle
    execute_cycle execute(
                        .clk(clk), 
                        .rst(rst), 
                        .RegWriteE(RegWriteE), 
                        .ALUSrcE(ALUSrcE), 
                        .MemWriteE(MemWriteE), 
                        .ResultSrcE(ResultSrcE), 
                        .BranchE(BranchE), 
                        .ALUControlE(ALUControlE), 
                        .RD1_E(RD1_E), 
                        .RD2_E(RD2_E), 
                        .Imm_Ext_E(Imm_Ext_E), 
                        .RD_E(RD_E), 
                        .PCE(PCE), 
                        .PCPlus4E(PCPlus4E), 
                        .PCSrcE(PCSrcE), 
                        .PCTargetE(PCTargetE), 
                        .RegWriteM(RegWriteM), 
                        .ResultSrcM(ResultSrcM), 
                        .MemWriteM(MemWriteM), 
                        .ALU_ResultM(ALUResultM), 
                        .WriteDataM(WriteDataM), 
                        .RD_M(RD_M), 
                        .PCPlus4M(PCPlus4M),
                        .ResultW(ResultW),
                        .ForwardAE(ForwardAE),
                        .ForwardBE(ForwardBE),
                        .ALUResultM_In(ALUResultM)
                    );

    //Memory_Cycle
    memory_cycle memory(
                        .clk(clk), 
                        .rst(rst), 
                        .RegWriteM(RegWriteM), 
                        .ResultSrcM(ResultSrcM), 
                        .MemWriteM(MemWriteM), 
                        .ALUResultM(ALUResultM), 
                        .WriteDataM(WriteDataM), 
                        .PCPlus4M(PCPlus4M), 
                        .RD_M(RD_M), 
                        .RegWriteW(RegWriteW), 
                        .ResultSrcW(ResultSrcW), 
                        .ALUResultW(ALUResultW), 
                        .ReadDataW(ReadDataW), 
                        .PCPlus4W(PCPlus4W), 
                        .RD_W(RDW) 
                    );
    //Write Bach Cycle
    write_back_cycle write_back(
                        .clk(clk), 
                        .rst(rst),  
                        .ResultSrcW(ResultSrcW), 
                        .ALUResultW(ALUResultW), 
                        .ReadDataW(ReadDataW), 
                        .PCPlus4W(PCPlus4W), 
                        .ResultW(ResultW)
                    );
    

    //Hazard Unit 
    hazard_unit Forwarding_Block(
                .rst(rst),
                .RegWriteM(RegWriteM),
                .RegWriteW(RegWriteW),
                .RD_M(RD_M),
                .RD_W(RDW),
                .Rs1_E(Rs1_E),
                .Rs2_E(Rs2_E),
                .ForwardAE(ForwardAE),
                .ForwardBE(ForwardBE)
                );

endmodule