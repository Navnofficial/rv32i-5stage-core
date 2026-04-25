module memory_cycle_tb;
    
    //Declaration of Ports
    reg clk, rst ;
    reg RegWriteM, ResultSrcM, MemWriteM;
    reg [31:0] ALUResultM, WriteDataM, PCPlus4M ;
    reg [4:0] RD_M ;
    wire RegWriteW, ResultSrcW ;
    wire [31:0] ALUResultW ;
    wire [31:0] ReadDataW , PCPlus4W ;
    wire [4:0] RD_W ; 

    // Declare uut 
    memory_cycle uut(
                    .clk(clk), 
                    .rst(rst), 
                    .RegWriteM(RegWriteM), 
                    .ResultSrcM(ResultSrcM), 
                    .MemWriteM(MemWriteM), 
                    .ALUResultM(ALUResultM), 
                    .WriteDataM(WriteDataM), 
                    .PCPlus4M(PCPlus4M), 
                    .RD_M(RD_M), 
                    .RegWriteW(RegWriteW), 
                    .ResultSrcW(ResultSrcW), 
                    .ALUResultW(ALUResultW),
                    .ReadDataW(ReadDataW), 
                    .PCPlus4W(PCPlus4W), 
                    .RD_W(RD_W) 
                    );

    //Waveform Generation 
    initial begin 
        $dumpfile ("Memory_Cycle_wave.vcd");
        $dumpvars (0 , memory_cycle_tb);
    end

    //Clk declare 
    always begin
      clk = ~clk ;
      #5 ; 
    end

    //Provding Test Inputs 
    initial begin
        // Initialize
        clk = 0; rst = 0;
        {RegWriteM, ResultSrcM, MemWriteM} = 3'b0;
        ALUResultM = 0; WriteDataM = 0; PCPlus4M = 0; RD_M = 0;

        #10 rst = 1; // Release Reset

        // --- TEST 1: STORE WORD (Write 0xAAAA_BBBB to Address 4) ---
        ALUResultM = 32'd4;          // Memory Address
        WriteDataM = 32'hAAAA_BBBB;  // Data to write
        MemWriteM  = 1'b1;           // Enable Write
        RegWriteM  = 1'b0;           // SW doesn't write to Register File
        #10;

        // --- TEST 2: LOAD WORD (Read from Address 4) ---
        // We expect ReadDataW to capture AAAA_BBBB on the next rising edge
        ALUResultM = 32'd4;          // Same address
        MemWriteM  = 1'b0;           // Disable Write (Read mode)
        ResultSrcM = 1'b1;           // Tell WB stage to select ReadData
        RegWriteM  = 1'b1;           // LW writes to Register File
        RD_M       = 5'd10;          // Destination register x10
        #10;

        // --- TEST 3: R-TYPE (Pass ALU result through) ---
        ALUResultM = 32'd100;        // Some calculation result
        ResultSrcM = 1'b0;           // Tell WB stage to select ALUResult
        RD_M       = 5'd12;
        #10;

        #20 $finish;
    end 
endmodule

