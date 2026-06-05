// Main Decoder — Full RV32I
// Opcodes:
//  0110011 = R-type
//  0010011 = I-type ALU
//  0000011 = Load
//  0100011 = Store
//  1100011 = Branch
//  1101111 = JAL
//  1100111 = JALR
//  0110111 = LUI
//  0010111 = AUIPC

module Main_Decoder(
    Op,
    RegWrite, ImmSrc, ALUSrc, MemWrite,
    ResultSrc, Branch, ALUOp, Jump,
    ALUSrcA
);
    input  [6:0] Op;

    output        RegWrite;
    output [2:0]  ImmSrc;
    output        ALUSrc;     // 0=rs2, 1=imm
    output        MemWrite;
    output [1:0]  ResultSrc;  // 00=ALU, 01=Mem, 10=PC+4
    output        Branch;
    output [1:0]  ALUOp;
    output        Jump;       // JAL or JALR
    output [1:0]  ALUSrcA;   // 00=rs1, 01=zero(LUI), 10=PC(AUIPC/branches)

    // RegWrite - use to say that register file should write , else be 0
    assign RegWrite  = (Op == 7'b0110011 |   // R-type
                        Op == 7'b0010011 |   // I-ALU
                        Op == 7'b0000011 |   // Load
                        Op == 7'b1101111 |   // JAL
                        Op == 7'b1100111 |   // JALR
                        Op == 7'b0110111 |   // LUI
                        Op == 7'b0010111)    // AUIPC
                       ? 1'b1 : 1'b0;


    // ImmSrc — 3-bit - use for select which type of immediate value to use from Imm_Ext 
    // i type -> 000
    // s type -> 001
    // b type -> 010
    // j type -> 011
    // u type -> 100
    // what is used 
    assign ImmSrc = (Op == 7'b0000011 | Op == 7'b0010011 | Op == 7'b1100111)    ? 3'b000 : // I-type
                    (Op == 7'b0100011)                                          ? 3'b001 : // S-type
                    (Op == 7'b1100011)                                          ? 3'b010 : // B-type
                    (Op == 7'b1101111)                                          ? 3'b011 : // J-type
                    (Op == 7'b0110111 | Op == 7'b0010111)                       ? 3'b100 : // U-type
                                                                                  3'b000 ;

    // ALUSrc (B operand): 1 = use immediate
    assign ALUSrc = (Op == 7'b0000011 |   // Load
                     Op == 7'b0100011 |   // Store
                     Op == 7'b0010011 |   // I-ALU
                     Op == 7'b1100111 |   // JALR
                     Op == 7'b0110111 |   // LUI
                     Op == 7'b0010111 |   // AUIPC
                     Op == 7'b1101111)    // JAL
                    ? 1'b1 : 1'b0;

    // ALUSrcA (A operand):
    //  00 = rs1 (normal)
    //  01 = 0   (LUI: 0 + imm)
    //  10 = PC  (AUIPC: PC + imm)
    assign ALUSrcA = (Op == 7'b0110111) ? 2'b01 : // LUI   -> A=0
                     (Op == 7'b0010111) ? 2'b10 : // AUIPC -> A=PC
                     (Op == 7'b1101111) ? 2'b10 : // JAL   -> A=PC (distinguish from JALR)
                                          2'b00;   // default rs1 (JALR/R/I/Load/Store/Branch)

    // MemWrite
    assign MemWrite  = (Op == 7'b0100011) ? 1'b1 : 1'b0;

    // ResultSrc: 00=ALU, 01=Mem, 10=PC+4 (link addr for JAL/JALR)
    assign ResultSrc = (Op == 7'b0000011)                    ? 2'b01 : // Load
                       (Op == 7'b1101111 | Op == 7'b1100111) ? 2'b10 : // JAL/JALR
                                                                2'b00;  // ALU

    // Branch (all B-type)
    assign Branch    = (Op == 7'b1100011) ? 1'b1 : 1'b0;

    // Jump
    assign Jump      = (Op == 7'b1101111 | Op == 7'b1100111) ? 1'b1 : 1'b0;

    // ALUOp
    assign ALUOp     = (Op == 7'b0110011 | Op == 7'b0010011) ? 2'b10 : // R/I ALU
                       (Op == 7'b1100011)                     ? 2'b01 : // Branch (SUB-like, unused)
                                                                2'b00;  // ADD (lw/sw/jal/jalr/lui/auipc)

endmodule
