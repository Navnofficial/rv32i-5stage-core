module fetch_cycle_tb;
    
    //Declaration of Ports
    reg clk = 0, rst ;
    reg PCSrcE ;
    reg [31:0] PCTargetE ;
    wire [31:0] InstrD ;
    wire [31:0] PCD , PCPlus4D ; 

    // Declare uut 
    fetch_cycle dut(
        .clk(clk), 
        .rst(rst), 
        .PCSrcE(PCSrcE), 
        .PCTargetE(PCTargetE), 
        .InstrD(InstrD), 
        .PCD(PCD), 
        .PCPlus4D(PCPlus4D)
        );

    //Waveform Generation 
    initial begin 
        $dumpfile ("Fetch_Cycle_wave.vcd");
        $dumpvars (0 , fetch_cycle_tb);
    end

    //Clk declare 
    always begin
      clk = ~clk ;
      #50 ; 
    end

    //Provding Test Inputs 
    initial begin
      rst <= 1'b0 ;
      #200 ;
      rst <= 1'b1 ;
      
      PCSrcE <= 1'b0 ;
      PCTargetE <= 32'h0000_0000;
      #500 ;
      $finish ;
    end 
endmodule

