/*
`include "ALU.v"
`include "Mux.v"
`include "PC_Adder.v"
*/
module execute_cycle(clk, rst, RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE, ALUControlE, 
                    RD1_E, RD2_E, Imm_Ext_E, RD_E, PCE, PCPlus4E, PCSrcE, PCTargetE, 
                    RegWriteM, ResultSrcM, MemWriteM, ALU_ResultM, WriteDataM, RD_M, 
                    PCPlus4M, ResultW, ForwardAE, ForwardBE, ALUResultM_In);

    //Input & Output Declaration
    input clk, rst, RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE ; 
    input [2:0] ALUControlE ;
    input [31:0] RD1_E , RD2_E , Imm_Ext_E ;
    input [4:0] RD_E ;
    input [31:0] PCE , PCPlus4E, ResultW ;
    input [31:0] ALUResultM_In ;
    input [1:0] ForwardAE, ForwardBE ;
    output [31:0] PCTargetE ;
    output PCSrcE ;
    output RegWriteM, ResultSrcM, MemWriteM;
    output [31:0] ALU_ResultM, WriteDataM, PCPlus4M ;
    output [4:0] RD_M ;

    //Wire  Declaration
    wire [31:0] SrcBE ,SrcAE, SrcBE_interim;
    wire [31:0] ALUResultE ;
    wire ZeroE ;

    //Register Declaration
    reg RegWriteE_reg, ResultSrcE_reg, MemWriteE_reg ;
    reg [31:0] ALUResultE_reg, PCPlus4E_reg, WriteDataE_reg ;
    reg [4:0] RD_E_reg ;

    //Mux3x1 Initialisation
    Mux3x1 mux_forward_A(
                        .a(RD1_E),
                        .b(ResultW),
                        .c(ALUResultM_In),
                        .s(ForwardAE),
                        .d(SrcAE)
                        );

    Mux3x1 mux_forward_B(
                        .a(RD2_E),
                        .b(ResultW),
                        .c(ALUResultM_In),
                        .s(ForwardBE),
                        .d(SrcBE_interim)
                        );

    //MUX initialisation    
    Mux alu_src_mux(
                    .a(SrcBE_interim  ),
                    .b(Imm_Ext_E),
                    .s(ALUSrcE),
                    .c(SrcBE)
                    );
    
    //Adder initialisation
    PC_Adder branch_adder(
                            .a(PCE),
                            .b(Imm_Ext_E),
                            .c(PCTargetE)
                            );

    //ALU Initialisation 
    ALU alu(
            .A(SrcAE),
            .B(SrcBE),
            .Result(ALUResultE),
            .ALUControl(ALUControlE),
            .OverFlow(),
            .Carry(),
            .Zero(ZeroE),
            .Negative()
            );


    always @(posedge clk or negedge rst) begin
        if(rst == 1'b0 ) begin
            RegWriteE_reg    <= 1'b0 ;
            ResultSrcE_reg   <= 1'b0 ;
            MemWriteE_reg    <= 1'b0 ;
            ALUResultE_reg   <= 32'h0000_0000 ;
            PCPlus4E_reg     <= 32'h0000_0000 ;
            WriteDataE_reg   <= 32'h0000_0000 ;
            RD_E_reg         <= 5'h00 ;
        end
        else begin
            RegWriteE_reg    <= RegWriteE ;
            ResultSrcE_reg   <= ResultSrcE ;
            MemWriteE_reg    <= MemWriteE ;
            ALUResultE_reg   <= ALUResultE ;
            PCPlus4E_reg     <= PCPlus4E ;
            WriteDataE_reg   <= SrcBE_interim ;
            RD_E_reg         <= RD_E ;
        end
    end

    assign PCSrcE      = ZeroE & BranchE ;
    assign RegWriteM   = RegWriteE_reg;
    assign ResultSrcM  = ResultSrcE_reg;
    assign MemWriteM   = MemWriteE_reg;
    assign ALU_ResultM = ALUResultE_reg;
    assign WriteDataM  = WriteDataE_reg;
    assign RD_M        = RD_E_reg;
    assign PCPlus4M    = PCPlus4E_reg;

endmodule
