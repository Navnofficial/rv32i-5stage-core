module execute_cycle_tb;
    
    //Declaration of Ports
    reg clk = 0, rst, RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE ; 
    reg [2:0] ALUControlE ;
    reg [31:0] RD1_E , RD2_E , Imm_Ext_E ;
    reg [4:0] RD_E ;
    reg [31:0] PCE , PCPlus4E ;
    wire [31:0] PCTargetE ;
    wire PCSrcE ;
    wire RegWriteM, ResultSrcM, MemWriteM;
    wire [31:0] ALUResultM, WriteDataM, PCPlus4M ;
    wire [4:0] RD_M ;

    // Declare uut 
    execute_cycle dut(
                        .clk(clk),
                        .rst(rst),
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
                        .PCPlus4E(PCPlus4E), 
                        .PCSrcE(PCSrcE), 
                        .PCTargetE(PCTargetE), 
                        .RegWriteM(RegWriteM), 
                        .ResultSrcM(ResultSrcM), 
                        .MemWriteM(MemWriteM), 
                        .ALUResultM(ALUResultM), 
                        .WriteDataM(WriteDataM), 
                        .RD_M(RD_M), 
                        .PCPlus4M(PCPlus4M)
                        );

    //Waveform Generation 
    initial begin 
        $dumpfile ("Execute_Cycle_wave.vcd");
        $dumpvars (0 , execute_cycle_tb);
    end

    //Clk declare 
    always begin
        #5 clk = ~clk;
    end

    //Provding Test Inputs 
    initial begin
    // Initialize Signals
        clk = 0; rst = 0;
        RD1_E = 0; RD2_E = 0; Imm_Ext_E = 0; 
        PCE = 0; PCPlus4E = 0; ALUControlE = 0;
        {RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE} = 5'b0;

        // Reset the system
        #10 rst = 1;

        // --- TEST 1: R-TYPE ADD (add x5, x1, x2) ---
        // Expected: ALUResultM = 15 + 25 = 40 (0x28)
        RD1_E = 32'd15; RD2_E = 32'd25; 
        ALUSrcE = 0; ALUControlE = 3'b000; // ADD
        RegWriteE = 1; RD_E = 5'd5;
        #10; 

        // --- TEST 2: I-TYPE ADDI (addi x10, x1, 100) ---
        // Expected: ALUResultM = 15 + 100 = 115
        Imm_Ext_E = 32'd100;
        ALUSrcE = 1; // Select Immediate
        ALUControlE = 3'b000;
        #10;

        // --- TEST 3: STORE WORD (sw x2, 8(x1)) ---
        // Expected: ALUResultM (Address) = 15 + 8 = 23, WriteDataM = 25
        RD1_E = 32'd15; Imm_Ext_E = 32'd8; RD2_E = 32'd25;
        ALUSrcE = 1; ALUControlE = 3'b000;
        MemWriteE = 1; RegWriteE = 0;
        #10;

        // --- TEST 4: BRANCH EQUAL (beq x1, x2, label) - TAKEN ---
        // Expected: PCSrcE = 1 (Combinational), PCTargetE = 0x100 + 20 = 0x114
        PCE = 32'h100; Imm_Ext_E = 32'd20;
        RD1_E = 32'd50; RD2_E = 32'd50;
        BranchE = 1; ALUSrcE = 0; 
        ALUControlE = 3'b001; // SUB (Used for comparison)
        #10;

        // --- TEST 5: BRANCH EQUAL - NOT TAKEN ---
        // Expected: PCSrcE = 0
        RD2_E = 32'd51; // Values not equal
        #10;

        // --- TEST 6: LOGICAL AND (and x7, x1, x2) ---
        // Expected: ALUResultM = 15 & 25 (00001111 & 00011001 = 00001001 -> 9)
        RD1_E = 32'd15; RD2_E = 32'd25;
        ALUSrcE = 0; ALUControlE = 3'b010; // AND
        BranchE = 0;
        #10;

        // Finish
        #50 $finish;
    end 
endmodule

