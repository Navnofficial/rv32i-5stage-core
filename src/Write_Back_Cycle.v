/*
`include "Mux.v"
*/
module write_back_cycle(clk, rst, ResultSrcW, ALUResultW, ReadDataW, PCPlus4W, ResultW  );

    //Input & Output Declaration
    input clk, rst, ResultSrcW ;
    input [31:0] ALUResultW ;
    input [31:0] ReadDataW , PCPlus4W ;
    output [31:0] ResultW ;

    //MUX initialisation 
    Mux WB_mux(
                    .a(ALUResultW),
                    .b(ReadDataW),
                    .s(ResultSrcW),
                    .c(ResultW)
                    );

endmodule
