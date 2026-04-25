/*
`include "Control_Unit_Top.v"
`include "Register_File.v"
`include "Sign_Extend.v"
*/
module decode_cycle(clk, rst, PCSrcE, InstrD, PCD, PCPlus4D, RegWriteW, RDW, ResultW,RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE, ALUControlE, RD1_E, RD2_E, Imm_Ext_E, RD_E, PCE, PCPlus4E, Rs1_E, Rs2_E );

    //port Declaration
    input clk , rst , RegWriteW , PCSrcE ;
    input [31:0] InstrD , PCD , PCPlus4D , ResultW ;
    input [4:0] RDW ;
    output RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE ; 
    output [2:0] ALUControlE ;
    output [31:0] RD1_E , RD2_E , Imm_Ext_E ;
    output [4:0] RD_E, Rs1_E, Rs2_E ;
    output [31:0] PCE , PCPlus4E ;
    
    //wire initialisation
    wire RegWriteD, ALUSrcD, MemWriteD, ResultSrcD, BranchD; 
    wire [1:0] ImmSrcD ;
    wire [2:0] ALUControlD ;
    wire [31:0] RD1_D , RD2_D , Imm_Ext_D ;

    //Reg Declaration
    reg RegWriteD_reg, ALUSrcD_reg, MemWriteD_reg, ResultSrcD_reg, BranchD_reg ; 
    reg [2:0] ALUControlD_reg ;
    reg [31:0] RD1_D_reg , RD2_D_reg , Imm_Ext_D_reg ;
    reg [4:0] RD_D_reg ;
    reg [31:0] PCD_reg , PCPlus4D_reg ; 
    reg [4:0] RS1_D_reg, RS2_D_reg ;

    //Contrl Unit 
    Control_Unit_Top control(
                            .Op(InstrD[6:0]),
                            .RegWrite(RegWriteD),
                            .ImmSrc(ImmSrcD),
                            .ALUSrc(ALUSrcD),
                            .MemWrite(MemWriteD),
                            .ResultSrc(ResultSrcD),
                            .Branch(BranchD),
                            .funct3(InstrD[14:12]),
                            .funct7(InstrD[31:25]),
                            .ALUControl(ALUControlD)
                            );

    //Register File
    Register_File Reg_file(
                            .clk(clk),
                            .rst(rst),
                            .WE3(RegWriteW),
                            .WD3(ResultW),
                            .A1(InstrD[19:15]),
                            .A2(InstrD[24:20]),
                            .A3(RDW),
                            .RD1(RD1_D),
                            .RD2(RD2_D)
                            );

    //Extender 
    Sign_Extend extension(
                            .In(InstrD[31:7]),
                            .Imm_Ext(Imm_Ext_D),
                            .ImmSrc(ImmSrcD)
                            );

    //Register Initialisation
    always @(posedge clk or negedge rst) begin
         if (rst == 1'b0 || PCSrcE) begin
            RegWriteD_reg     <= 1'b0 ; 
            ALUSrcD_reg       <= 1'b0 ; 
            MemWriteD_reg     <= 1'b0 ; 
            ResultSrcD_reg    <= 1'b0 ; 
            BranchD_reg       <= 1'b0 ;
            ALUControlD_reg   <= 3'b000 ;
            RD1_D_reg         <= 32'h0000_0000 ; 
            RD2_D_reg         <= 32'h0000_0000 ; 
            Imm_Ext_D_reg     <= 32'h0000_0000 ;
            RD_D_reg          <= 5'h00 ;
            PCD_reg           <= 32'h0000_0000 ; 
            PCPlus4D_reg      <= 32'h0000_0000;
        end
        else begin
            RegWriteD_reg     <= RegWriteD ; 
            ALUSrcD_reg       <= ALUSrcD ; 
            MemWriteD_reg     <= MemWriteD ; 
            ResultSrcD_reg    <= ResultSrcD ; 
            BranchD_reg       <= BranchD ;
            ALUControlD_reg   <= ALUControlD ;
            RD1_D_reg         <= RD1_D ; 
            RD2_D_reg         <= RD2_D ; 
            Imm_Ext_D_reg     <= Imm_Ext_D ;
            RD_D_reg          <= InstrD[11:7] ;
            PCD_reg           <= PCD ; 
            PCPlus4D_reg      <= PCPlus4D;
            RS1_D_reg         <= InstrD[19:15] ;
            RS2_D_reg         <= InstrD[24:20] ;
        end
    end

    //Assign Output 
    assign RegWriteE        = RegWriteD_reg ;
    assign ALUSrcE          = ALUSrcD_reg ;
    assign MemWriteE        = MemWriteD_reg ;
    assign ResultSrcE       = ResultSrcD_reg ;
    assign BranchE          = BranchD_reg ;
    assign ALUControlE      = ALUControlD_reg ;
    assign RD1_E            = RD1_D_reg ;
    assign RD2_E            = RD2_D_reg ;
    assign Imm_Ext_E        = Imm_Ext_D_reg ;
    assign RD_E             = RD_D_reg ;
    assign PCE              = PCD_reg ;
    assign PCPlus4E         = PCPlus4D_reg ;
    assign Rs1_E            = RS1_D_reg ;
    assign Rs2_E            = RS2_D_reg ;

endmodule