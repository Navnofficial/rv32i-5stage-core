/*
`include "ALU.v"
`include "Mux.v"
`include "PC_Adder.v"
`include "Branch_Comparator.v"
*/
module execute_cycle(
    clk, rst, FlushE,
    // Control inputs
    RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE, ALUControlE,
    JumpE, ALUSrcAE, Funct3E,
    // Data inputs
    RD1_E, RD2_E, Imm_Ext_E, RD_E, PCE, PCPlus4E,
    // Forwarding inputs
    ResultW, ForwardAE, ForwardBE, ALUResultM_In,
    // Outputs to IF stage
    PCSrcE, PCTargetE,
    // Outputs to MEM stage registers
    RegWriteM, ResultSrcM, MemWriteM,
    ALU_ResultM, WriteDataM, RD_M, PCPlus4M,
    Funct3M
);

    input  clk, rst, FlushE;
    input  RegWriteE, ALUSrcE, MemWriteE, BranchE, JumpE;
    input  [1:0]  ResultSrcE, ForwardAE, ForwardBE, ALUSrcAE;
    input  [3:0]  ALUControlE;
    input  [2:0]  Funct3E;
    input  [31:0] RD1_E, RD2_E, Imm_Ext_E, PCE, PCPlus4E;
    input  [4:0]  RD_E;
    input  [31:0] ResultW, ALUResultM_In;

    output        PCSrcE;
    output [31:0] PCTargetE;
    output        RegWriteM, MemWriteM;
    output [1:0]  ResultSrcM;
    output [31:0] ALU_ResultM, WriteDataM, PCPlus4M;
    output [4:0]  RD_M;
    output [2:0]  Funct3M;

    // Internal wires
    wire [31:0] SrcAE_fwd, SrcBE_fwd, SrcAE, SrcBE;
    wire [31:0] ALUResultE;
    wire        BranchTaken;

    // Pipeline regs (EX/MEM)
    reg        RegWriteE_reg, MemWriteE_reg;
    reg [1:0]  ResultSrcE_reg;
    reg [31:0] ALUResultE_reg, PCPlus4E_reg, WriteDataE_reg;
    reg [4:0]  RD_E_reg;
    reg [2:0]  Funct3E_reg;

    // ---- Forwarding muxes (3x1) for rs1 and rs2 ----
    Mux3x1 mux_forward_A(
        .a(RD1_E),
        .b(ResultW),
        .c(ALUResultM_In),
        .s(ForwardAE),
        .d(SrcAE_fwd)
    );

    Mux3x1 mux_forward_B(
        .a(RD2_E),
        .b(ResultW),
        .c(ALUResultM_In),
        .s(ForwardBE),
        .d(SrcBE_fwd)
    );

    // ---- ALUSrcA mux: fwd_rs1(00), zero(01), PC(10) ----
    Mux3x1 mux_alu_src_A(
        .a(SrcAE_fwd),   // 00: normal rs1
        .b(32'h0000_0000), // 01: zero (LUI)
        .c(PCE),           // 10: PC   (AUIPC / JAL)
        .s(ALUSrcAE),
        .d(SrcAE)
    );

    // ---- ALUSrcB mux: rs2(0) or immediate(1) ----
    Mux alu_src_B_mux(
        .a(SrcBE_fwd),
        .b(Imm_Ext_E),
        .s(ALUSrcE),
        .c(SrcBE)
    );

    // ---- Branch/Jump target adder ----
    // For JAL/Branch: PCE + Imm_Ext_E
    // For JALR: rs1 + Imm_Ext_E  (ALUSrcA already forced to rs1 by ALUSrcAE=00)
    // We can reuse the ALU result for JALR target since ALU does rs1 + imm
    // PCTargetE = (JALR) ? ALUResultE : PCE + Imm_Ext_E
    wire [31:0] BranchTarget;
    PC_Adder branch_adder(
        .a(PCE),
        .b(Imm_Ext_E),
        .c(BranchTarget)
    );

    // ALU
    ALU alu(
        .A         (SrcAE),
        .B         (SrcBE),
        .Result    (ALUResultE),
        .ALUControl(ALUControlE),
        .OverFlow  (),
        .Carry     (),
        .Zero      (),
        .Negative  ()
    );

    // Branch comparator (uses pre-ALU forwarded operands, before immediate mux)
    Branch_Comparator br_cmp(
        .SrcA      (SrcAE_fwd),
        .SrcB      (SrcBE_fwd),
        .funct3    (Funct3E),
        .BranchE   (BranchE),
        .BranchTaken(BranchTaken)
    );

    // PC source: branch taken OR unconditional jump
    // For JALR: target = ALU result (rs1+imm); for others: BranchTarget (PC+imm)
    // JALR: Jump=1, ALUSrcAE=2'b00 (rs1). JAL: Jump=1, ALUSrcAE=2'b10 (PC).
    wire IsJALR = JumpE & (ALUSrcAE == 2'b00);
    assign PCSrcE    = BranchTaken | JumpE;
    assign PCTargetE = IsJALR ? {ALUResultE[31:1], 1'b0} : BranchTarget;

    // EX/MEM Pipeline Register
    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0 || FlushE) begin
            RegWriteE_reg  <= 1'b0;
            ResultSrcE_reg <= 2'b00;
            MemWriteE_reg  <= 1'b0;
            ALUResultE_reg <= 32'h0000_0000;
            PCPlus4E_reg   <= 32'h0000_0000;
            WriteDataE_reg <= 32'h0000_0000;
            RD_E_reg       <= 5'h00;
            Funct3E_reg    <= 3'b000;
        end else begin
            RegWriteE_reg  <= RegWriteE;
            ResultSrcE_reg <= ResultSrcE;
            MemWriteE_reg  <= MemWriteE;
            ALUResultE_reg <= ALUResultE;
            PCPlus4E_reg   <= PCPlus4E;
            WriteDataE_reg <= SrcBE_fwd;  // store data = forwarded rs2
            RD_E_reg       <= RD_E;
            Funct3E_reg    <= Funct3E;
        end
    end

    assign RegWriteM  = RegWriteE_reg;
    assign ResultSrcM = ResultSrcE_reg;    // full 2-bit
    assign MemWriteM  = MemWriteE_reg;
    assign ALU_ResultM = ALUResultE_reg;
    assign WriteDataM  = WriteDataE_reg;
    assign RD_M        = RD_E_reg;
    assign PCPlus4M    = PCPlus4E_reg;
    assign Funct3M     = Funct3E_reg;

endmodule
