// Write-Back Stage — 3-input result mux
// ResultSrcW:
//   00 = ALU result
//   01 = Memory read data
//   10 = PC+4 (link address for JAL/JALR)
module write_back_cycle(clk, rst, ResultSrcW, ALUResultW, ReadDataW, PCPlus4W, ResultW);

    input        clk, rst;
    input  [1:0] ResultSrcW;
    input  [31:0] ALUResultW;
    input  [31:0] ReadDataW, PCPlus4W;
    output [31:0] ResultW;

    // 3-to-1 mux
    Mux3x1 WB_mux(
        .a(ALUResultW),
        .b(ReadDataW),
        .c(PCPlus4W),
        .s(ResultSrcW),
        .d(ResultW)
    );

endmodule
