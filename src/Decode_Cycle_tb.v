module decode_cycle_tb;
    
    //Declaration of Ports
    reg clk = 0 , rst , RegWriteW ;
    reg [31:0] InstrD , PCD , PCPlus4D , ResultW ;
    reg [4:0] RDW ;
    wire RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE ; 
    wire [2:0] ALUControlE ;
    wire [31:0] RD1_E , RD2_E , Imm_Ext_E ;
    wire [4:0] RD_E ;
    wire [31:0] PCE , PCPlus4E ;

    // Declare uut 
    decode_cycle dut(
                    .clk(clk), 
                    .rst(rst),                
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
                    .PCPlus4E(PCPlus4E) 
            );

    //Waveform Generation 
    initial begin 
        $dumpfile ("Decode_Cycle_wave.vcd");
        $dumpvars (0 , decode_cycle_tb);
    end

    //Clk declare 
    always begin
        #50 clk = ~clk;
    end

    //Provding Test Inputs 
    initial begin
        rst = 1'b0;
        InstrD = 32'h0; PCD = 32'h0; PCPlus4D = 32'h0;
        RegWriteW = 1'b0; RDW = 5'b0; ResultW = 32'h0;
        #200;
        rst = 1'b1;
        
        RegWriteW = 1'b1;
        RDW = 5'd1; 
        ResultW = 32'hAAAA_BBBB;
        #100;

        RDW = 5'd2;
        ResultW = 32'h1234_5678;
        #100;
        RegWriteW = 1'b0;

        PCD = 32'h0000_0004;
        PCPlus4D = 32'h0000_0008;
        InstrD = 32'h002081B3; 
        #100;

        InstrD = 32'h0040A283;
        #100;
        #200;

        $finish;
    end 
endmodule

