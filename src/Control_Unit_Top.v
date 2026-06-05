`include "Main_Decoder.v"
`include "ALU_Decoder.v"

module Control_Unit_Top(
    Op, funct3, funct7,
    RegWrite, ImmSrc, ALUSrc, MemWrite,
    ResultSrc, Branch, ALUControl, Jump, ALUSrcA
);

    input  [6:0] Op, funct7;
    input  [2:0] funct3;

    output        RegWrite;
    output [2:0]  ImmSrc;
    output        ALUSrc;
    output        MemWrite;
    output [1:0]  ResultSrc;
    output        Branch;
    output [3:0]  ALUControl;
    output        Jump;
    output [1:0]  ALUSrcA;

    wire [1:0] ALUOp;

    Main_Decoder Main_Decoder(
        .Op       (Op),
        .RegWrite (RegWrite),
        .ImmSrc   (ImmSrc),
        .ALUSrc   (ALUSrc),
        .MemWrite (MemWrite),
        .ResultSrc(ResultSrc),
        .Branch   (Branch),
        .ALUOp    (ALUOp),
        .Jump     (Jump),
        .ALUSrcA  (ALUSrcA)
    );

    ALU_Decoder ALU_Decoder(
        .ALUOp     (ALUOp),
        .funct3    (funct3),
        .funct7    (funct7),
        .op        (Op),
        .ALUControl(ALUControl)
    );

endmodule