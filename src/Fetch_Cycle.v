/*
`include "Instruction_Memory.v"
`include "PC.v"
`include "PC_Adder.v"
`include "Mux.v"
*/
module fetch_cycle(clk, rst, PCSrcE, PCTargetE, InstrD, PCD, PCPlus4D);

        //port Declaration 
        input clk , rst ;
        input PCSrcE ;
        input [31:0] PCTargetE ;
        output [31:0] InstrD ;
        output [31:0] PCD , PCPlus4D ;

        //Register Declaration
        reg [31:0] InstrF_reg ;
        reg [31:0] PCF_reg ;
        reg [31:0] PCPlus4F_reg ;

        //wire Declaration
        wire [31:0] PC_F ;
        wire [31:0] PCPlus4F  ;
        wire [31:0] PCF ;
        wire [31:0] InstrF ;

        //MUX of Program Counter 
        Mux PC_MUX( 
            .a(PCPlus4F),
            .b(PCTargetE),
            .s(PCSrcE),
            .c(PC_F)
            );
        
        //PC_Adder initiation
        PC_Adder PC_adder(  
            .a(PCF),
            .b(32'h0000_0004),
            .c(PCPlus4F)
            );
        
        //Program Counter Initiation
        PC_Module Program_Counter(  
            .clk(clk),
            .rst(rst),
            .PC(PCF),
            .PC_Next(PC_F)
            );

        //Instruction Memory initiation 
        Instruction_Memory I_Memory(
            .rst(rst),
            .A(PCF),
            .RD(InstrF)
            );

        //Register Creation 
        always @( posedge clk or negedge rst) begin
           if (rst == 1'b0 || PCSrcE) begin
            InstrF_reg   <= 32'h0000_0000 ;
            PCF_reg      <= 32'h0000_0000 ;
            PCPlus4F_reg <= 32'h0000_0000 ;
          end
          else begin
            InstrF_reg   <= InstrF ;
            PCF_reg      <= PCF ;
            PCPlus4F_reg <= PCPlus4F ;
          end
        end

        assign InstrD     = (rst == 1'b0) ? 32'h0000_0000 : InstrF_reg ;
        assign PCD        = (rst == 1'b0) ? 32'h0000_0000 : PCF_reg ;
        assign PCPlus4D   = (rst == 1'b0) ? 32'h0000_0000 : PCPlus4F_reg ;

endmodule