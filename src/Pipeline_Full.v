module PC_Module(clk,rst,PC,PC_Next);

    input clk,rst;
    input [31:0]PC_Next;
    output [31:0]PC;
    reg [31:0]PC;

    always @(posedge clk or negedge rst)
    begin
        if(rst == 1'b0)
            PC <= 32'h0000_0000;
        else
            PC <= PC_Next;
    end
endmodule
module PC_Adder (a,b,c);

    input [31:0]a,b;
    output [31:0]c;

    assign c = a + b;
    
endmodule
module Mux (a,b,s,c);

    input [31:0]a,b;
    input s;
    output [31:0]c;

    assign c = (s == 1'b1) ? b : a;
    
endmodule

module Mux3x1 ( a, b, c, s, d);

    input [31:0] a, b, c ;
    input [1:0] s;
    output [31:0] d;

    assign d =  (s == 2'b00) ? a : 
                (s == 2'b01) ? b :
                (s == 2'b10) ? c :
                32'h0000_0000 ;

endmodule
module ALU(A,B,Result,ALUControl,OverFlow,Carry,Zero,Negative);

    input [31:0]A,B;
    input [2:0]ALUControl;
    output Carry,OverFlow,Zero,Negative;
    output [31:0]Result;

    wire Cout;
    wire [31:0]Sum;

    assign {Cout,Sum} = (ALUControl[0] == 1'b0) ? A + B :
                                          (A + ((~B)+1)) ;
    assign Result = (ALUControl == 3'b000) ? Sum :
                    (ALUControl == 3'b001) ? Sum :
                    (ALUControl == 3'b010) ? A & B :
                    (ALUControl == 3'b011) ? A | B :
                    (ALUControl == 3'b101) ? {{31{1'b0}},(Sum[31])} : {32{1'b0}};
    
    assign OverFlow = ((Sum[31] ^ A[31]) & 
                      (~(ALUControl[0] ^ B[31] ^ A[31])) &
                      (~ALUControl[1]));
    assign Carry = ((~ALUControl[1]) & Cout);
    assign Zero = &(~Result);
    assign Negative = Result[31];

endmodule
module ALU_Decoder(ALUOp,funct3,funct7,op,ALUControl);

    input [1:0]ALUOp;
    input [2:0]funct3;
    input [6:0]funct7,op;
    output [2:0]ALUControl;

    // Method 1 
    // assign ALUControl = (ALUOp == 2'b00) ? 3'b000 :
    //                     (ALUOp == 2'b01) ? 3'b001 :
    //                     (ALUOp == 2'b10) ? ((funct3 == 3'b000) ? ((({op[5],funct7[5]} == 2'b00) | ({op[5],funct7[5]} == 2'b01) | ({op[5],funct7[5]} == 2'b10)) ? 3'b000 : 3'b001) : 
    //                                         (funct3 == 3'b010) ? 3'b101 : 
    //                                         (funct3 == 3'b110) ? 3'b011 : 
    //                                         (funct3 == 3'b111) ? 3'b010 : 3'b000) :
    //                                        3'b000;

    // Method 2
    assign ALUControl = (ALUOp == 2'b00) ? 3'b000 :
                        (ALUOp == 2'b01) ? 3'b001 :
                        ((ALUOp == 2'b10) & (funct3 == 3'b000) & ({op[5],funct7[5]} == 2'b11)) ? 3'b001 : 
                        ((ALUOp == 2'b10) & (funct3 == 3'b000) & ({op[5],funct7[5]} != 2'b11)) ? 3'b000 : 
                        ((ALUOp == 2'b10) & (funct3 == 3'b010)) ? 3'b101 : 
                        ((ALUOp == 2'b10) & (funct3 == 3'b110)) ? 3'b011 : 
                        ((ALUOp == 2'b10) & (funct3 == 3'b111)) ? 3'b010 : 
                                                                  3'b000 ;
endmodule
module Main_Decoder(Op,RegWrite,ImmSrc,ALUSrc,MemWrite,ResultSrc,Branch,ALUOp);
    input [6:0]Op;
    output RegWrite,ALUSrc,MemWrite,ResultSrc,Branch;
    output [1:0]ImmSrc,ALUOp;

    assign RegWrite = (Op == 7'b0000011 | Op == 7'b0110011 | Op == 7'b0010011) ? 1'b1 :
                                                                               1'b0 ;
    assign ImmSrc = (Op == 7'b0100011) ? 2'b01 : 
                    (Op == 7'b1100011) ? 2'b10 :    
                                         2'b00 ;
    assign ALUSrc = (Op == 7'b0000011 | Op == 7'b0100011 | Op == 7'b0010011) ? 1'b1 :
                                                                             1'b0 ;

    assign MemWrite = (Op == 7'b0100011) ? 1'b1 :
                                           1'b0 ;
    assign ResultSrc = (Op == 7'b0000011) ? 1'b1 :
                                            1'b0 ;
    assign Branch = (Op == 7'b1100011) ? 1'b1 :
                                         1'b0 ;
    assign ALUOp = (Op == 7'b0110011 | Op == 7'b0010011) ? 2'b10 :
                   (Op == 7'b1100011) ? 2'b01 :
                                        2'b00 ;

endmodule




module Control_Unit_Top(Op,RegWrite,ImmSrc,ALUSrc,MemWrite,ResultSrc,Branch,funct3,funct7,ALUControl);

    input [6:0]Op,funct7;
    input [2:0]funct3;
    output RegWrite,ALUSrc,MemWrite,ResultSrc,Branch;
    output [1:0]ImmSrc;
    output [2:0]ALUControl;

    wire [1:0]ALUOp;

    Main_Decoder Main_Decoder(
                .Op(Op),
                .RegWrite(RegWrite),
                .ImmSrc(ImmSrc),
                .MemWrite(MemWrite),
                .ResultSrc(ResultSrc),
                .Branch(Branch),
                .ALUSrc(ALUSrc),
                .ALUOp(ALUOp)
    );

    ALU_Decoder ALU_Decoder(
                            .ALUOp(ALUOp),
                            .funct3(funct3),
                            .funct7(funct7),
                            .op(Op),
                            .ALUControl(ALUControl)
    );


endmodule
module Register_File(clk,rst,WE3,WD3,A1,A2,A3,RD1,RD2);

    input clk,rst,WE3;
    input [4:0]A1,A2,A3;
    input [31:0]WD3;
    output [31:0]RD1,RD2;

    reg [31:0] Register [31:0];

    always @ (posedge clk)
    begin
        if(WE3 & (A3 != 5'b00000))
            Register[A3] <= WD3;
    end

    assign RD1 = (~rst) ? 32'd0 : (A1 == 5'b00000) ? 32'd0 : Register[A1];
    assign RD2 = (~rst) ? 32'd0 : (A2 == 5'b00000) ? 32'd0 : Register[A2];
    
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1)
         Register[i] = 32'h00000000;
        
    end

endmodule

module Sign_Extend (In,Imm_Ext,ImmSrc);

    input [31:7] In;
    input [1:0] ImmSrc;
    output reg [31:0]Imm_Ext;

    always @(*) begin
        case (ImmSrc)
            // I-type (e.g., addi, lw)
            2'b00: Imm_Ext = {{20{In[31]}}, In[31:20]};
            
            // S-type (e.g., sw)
            2'b01: Imm_Ext = {{20{In[31]}}, In[31:25], In[11:7]};
            
            // B-type (e.g., beq) - Bits are shuffled for branches
            2'b10: Imm_Ext = {{20{In[31]}}, In[7], In[30:25], In[11:8], 1'b0};
            
            // J-type or default
            default: Imm_Ext = 32'h0000_0000;
        endcase
    end
                                
endmodule
module Instruction_Memory(rst,A,RD);

  input rst;
  input [31:0]A;
  output [31:0]RD;

  reg [31:0] mem [1023:0];
  
  assign RD = (rst == 1'b0) ? {32{1'b0}} : mem[A[31:2]];

  initial begin
    $readmemh("memfile.hex",mem);
  end

  initial begin
    //mem[0] = 32'hFFC4A303;
    //mem[1] = 32'h00832383;
    // mem[0] = 32'h0064A423;
    // mem[1] = 32'h00B62423;
    mem[0] = 32'h0062E233;
    // mem[1] = 32'h00B62423;

  end
endmodule
module Data_Memory(clk,rst,WE,WD,A,RD);

    input clk,rst,WE;
    input [31:0]A,WD;
    output [31:0]RD;

    reg [31:0] mem [1023:0];

    always @ (posedge clk)
    begin
        if(WE)
            mem[A[31:2]] <= WD;
    end

    assign RD = (~rst) ? 32'd0 : mem[A[31:2]];

    initial begin
        //mem[28] = 32'h00000020;
        //mem[40] = 32'h00000002;
        mem[0] = 32'h00000020;
    end

endmodule
module hazard_unit(rst, RegWriteM, RegWriteW, RD_M, RD_W, Rs1_E, Rs2_E, ForwardAE, ForwardBE);

    //Input & Output Ports
    input rst, RegWriteM, RegWriteW;
    input [4:0] RD_M, RD_W, Rs1_E, Rs2_E;
    output [1:0] ForwardAE, ForwardBE;

    assign ForwardAE =  ( rst == 1'b0) ? 2'b00 : 
                        ((RegWriteM == 1'b1) & (RD_M != 5'h00) & (RD_M == Rs1_E)) ? 2'b10 : 
                        ((RegWriteW == 1'b1) & (RD_W != 5'h00) & (RD_W == Rs1_E)) ? 2'b01 : 2'b00 ; 
    
    assign ForwardBE =  ( rst == 1'b0) ? 2'b00 : 
                        ((RegWriteM == 1'b1) & (RD_M != 5'h00) & (RD_M == Rs2_E)) ? 2'b10 : 
                        ((RegWriteW == 1'b1) & (RD_W != 5'h00) & (RD_W == Rs2_E)) ? 2'b01 : 2'b00 ; 
endmodule
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
module decode_cycle(clk, rst, PCSrcE, InstrD, PCD, PCPlus4D, RegWriteW, RDW, ResultW,RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE, ALUControlE, RD1_E, RD2_E, Imm_Ext_E, RD_E, PCE, PCPlus4E, Rs1_E, Rs2_E );

    //port Declaration
    input clk , rst , RegWriteW , PCSrcE ;
    input [31:0] InstrD , PCD , PCPlus4D , ResultW ;
    input [4:0] RDW ;
    output RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE ; 
    output [2:0] ALUControlE ;
    output [31:0] RD1_E , RD2_E , Imm_Ext_E ;
    output [4:0] RD_E, Rs1_E, Rs2_E ;
    output [31:0] PCE , PCPlus4E ;
    
    //wire initialisation
    wire RegWriteD, ALUSrcD, MemWriteD, ResultSrcD, BranchD; 
    wire [1:0] ImmSrcD ;
    wire [2:0] ALUControlD ;
    wire [31:0] RD1_D , RD2_D , Imm_Ext_D ;

    //Reg Declaration
    reg RegWriteD_reg, ALUSrcD_reg, MemWriteD_reg, ResultSrcD_reg, BranchD_reg ; 
    reg [2:0] ALUControlD_reg ;
    reg [31:0] RD1_D_reg , RD2_D_reg , Imm_Ext_D_reg ;
    reg [4:0] RD_D_reg ;
    reg [31:0] PCD_reg , PCPlus4D_reg ; 
    reg [4:0] RS1_D_reg, RS2_D_reg ;

    //Contrl Unit 
    Control_Unit_Top control(
                            .Op(InstrD[6:0]),
                            .RegWrite(RegWriteD),
                            .ImmSrc(ImmSrcD),
                            .ALUSrc(ALUSrcD),
                            .MemWrite(MemWriteD),
                            .ResultSrc(ResultSrcD),
                            .Branch(BranchD),
                            .funct3(InstrD[14:12]),
                            .funct7(InstrD[31:25]),
                            .ALUControl(ALUControlD)
                            );

    //Register File
    Register_File Reg_file(
                            .clk(clk),
                            .rst(rst),
                            .WE3(RegWriteW),
                            .WD3(ResultW),
                            .A1(InstrD[19:15]),
                            .A2(InstrD[24:20]),
                            .A3(RDW),
                            .RD1(RD1_D),
                            .RD2(RD2_D)
                            );

    //Extender 
    Sign_Extend extension(
                            .In(InstrD[31:7]),
                            .Imm_Ext(Imm_Ext_D),
                            .ImmSrc(ImmSrcD)
                            );

    //Register Initialisation
    always @(posedge clk or negedge rst) begin
         if (rst == 1'b0 || PCSrcE) begin
            RegWriteD_reg     <= 1'b0 ; 
            ALUSrcD_reg       <= 1'b0 ; 
            MemWriteD_reg     <= 1'b0 ; 
            ResultSrcD_reg    <= 1'b0 ; 
            BranchD_reg       <= 1'b0 ;
            ALUControlD_reg   <= 3'b000 ;
            RD1_D_reg         <= 32'h0000_0000 ; 
            RD2_D_reg         <= 32'h0000_0000 ; 
            Imm_Ext_D_reg     <= 32'h0000_0000 ;
            RD_D_reg          <= 5'h00 ;
            PCD_reg           <= 32'h0000_0000 ; 
            PCPlus4D_reg      <= 32'h0000_0000;
        end
        else begin
            RegWriteD_reg     <= RegWriteD ; 
            ALUSrcD_reg       <= ALUSrcD ; 
            MemWriteD_reg     <= MemWriteD ; 
            ResultSrcD_reg    <= ResultSrcD ; 
            BranchD_reg       <= BranchD ;
            ALUControlD_reg   <= ALUControlD ;
            RD1_D_reg         <= RD1_D ; 
            RD2_D_reg         <= RD2_D ; 
            Imm_Ext_D_reg     <= Imm_Ext_D ;
            RD_D_reg          <= InstrD[11:7] ;
            PCD_reg           <= PCD ; 
            PCPlus4D_reg      <= PCPlus4D;
            RS1_D_reg         <= InstrD[19:15] ;
            RS2_D_reg         <= InstrD[24:20] ;
        end
    end

    //Assign Output 
    assign RegWriteE        = RegWriteD_reg ;
    assign ALUSrcE          = ALUSrcD_reg ;
    assign MemWriteE        = MemWriteD_reg ;
    assign ResultSrcE       = ResultSrcD_reg ;
    assign BranchE          = BranchD_reg ;
    assign ALUControlE      = ALUControlD_reg ;
    assign RD1_E            = RD1_D_reg ;
    assign RD2_E            = RD2_D_reg ;
    assign Imm_Ext_E        = Imm_Ext_D_reg ;
    assign RD_E             = RD_D_reg ;
    assign PCE              = PCD_reg ;
    assign PCPlus4E         = PCPlus4D_reg ;
    assign Rs1_E            = RS1_D_reg ;
    assign Rs2_E            = RS2_D_reg ;

endmodule
module execute_cycle(clk, rst, RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE, ALUControlE, 
                    RD1_E, RD2_E, Imm_Ext_E, RD_E, PCE, PCPlus4E, PCSrcE, PCTargetE, 
                    RegWriteM, ResultSrcM, MemWriteM, ALU_ResultM, WriteDataM, RD_M, 
                    PCPlus4M, ResultW, ForwardAE, ForwardBE, ALUResultM_In);

    //Input & Output Declaration
    input clk, rst, RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE ; 
    input [2:0] ALUControlE ;
    input [31:0] RD1_E , RD2_E , Imm_Ext_E ;
    input [4:0] RD_E ;
    input [31:0] PCE , PCPlus4E, ResultW ;
    input [31:0] ALUResultM_In ;
    input [1:0] ForwardAE, ForwardBE ;
    output [31:0] PCTargetE ;
    output PCSrcE ;
    output RegWriteM, ResultSrcM, MemWriteM;
    output [31:0] ALU_ResultM, WriteDataM, PCPlus4M ;
    output [4:0] RD_M ;

    //Wire  Declaration
    wire [31:0] SrcBE ,SrcAE, SrcBE_interim;
    wire [31:0] ALUResultE ;
    wire ZeroE ;

    //Register Declaration
    reg RegWriteE_reg, ResultSrcE_reg, MemWriteE_reg ;
    reg [31:0] ALUResultE_reg, PCPlus4E_reg, WriteDataE_reg ;
    reg [4:0] RD_E_reg ;

    //Mux3x1 Initialisation
    Mux3x1 mux_forward_A(
                        .a(RD1_E),
                        .b(ResultW),
                        .c(ALUResultM_In),
                        .s(ForwardAE),
                        .d(SrcAE)
                        );

    Mux3x1 mux_forward_B(
                        .a(RD2_E),
                        .b(ResultW),
                        .c(ALUResultM_In),
                        .s(ForwardBE),
                        .d(SrcBE_interim)
                        );

    //MUX initialisation    
    Mux alu_src_mux(
                    .a(SrcBE_interim  ),
                    .b(Imm_Ext_E),
                    .s(ALUSrcE),
                    .c(SrcBE)
                    );
    
    //Adder initialisation
    PC_Adder branch_adder(
                            .a(PCE),
                            .b(Imm_Ext_E),
                            .c(PCTargetE)
                            );

    //ALU Initialisation 
    ALU alu(
            .A(SrcAE),
            .B(SrcBE),
            .Result(ALUResultE),
            .ALUControl(ALUControlE),
            .OverFlow(),
            .Carry(),
            .Zero(ZeroE),
            .Negative()
            );


    always @(posedge clk or negedge rst) begin
        if(rst == 1'b0 ) begin
            RegWriteE_reg    <= 1'b0 ;
            ResultSrcE_reg   <= 1'b0 ;
            MemWriteE_reg    <= 1'b0 ;
            ALUResultE_reg   <= 32'h0000_0000 ;
            PCPlus4E_reg     <= 32'h0000_0000 ;
            WriteDataE_reg   <= 32'h0000_0000 ;
            RD_E_reg         <= 5'h00 ;
        end
        else begin
            RegWriteE_reg    <= RegWriteE ;
            ResultSrcE_reg   <= ResultSrcE ;
            MemWriteE_reg    <= MemWriteE ;
            ALUResultE_reg   <= ALUResultE ;
            PCPlus4E_reg     <= PCPlus4E ;
            WriteDataE_reg   <= SrcBE_interim ;
            RD_E_reg         <= RD_E ;
        end
    end

    assign PCSrcE      = ZeroE & BranchE ;
    assign RegWriteM   = RegWriteE_reg;
    assign ResultSrcM  = ResultSrcE_reg;
    assign MemWriteM   = MemWriteE_reg;
    assign ALU_ResultM = ALUResultE_reg;
    assign WriteDataM  = WriteDataE_reg;
    assign RD_M        = RD_E_reg;
    assign PCPlus4M    = PCPlus4E_reg;

endmodule

module memory_cycle(clk, rst, RegWriteM, ResultSrcM, MemWriteM, ALUResultM, 
                    WriteDataM, PCPlus4M, RD_M, RegWriteW, ResultSrcW, 
                    ALUResultW,ReadDataW, PCPlus4W, RD_W );

    //Input & Output Declaration
    input clk, rst ;
    input RegWriteM, ResultSrcM, MemWriteM;
    input [31:0] ALUResultM, WriteDataM, PCPlus4M ;
    input [4:0] RD_M ;
    output RegWriteW, ResultSrcW ;
    output [31:0] ALUResultW ;
    output [31:0] ReadDataW , PCPlus4W ;
    output [4:0] RD_W ;

    //Wire  Declaration
    wire [31:0] ReadDataM ;

    //Register Declaration
    reg RegWriteM_reg, ResultSrcM_reg ;
    reg [31:0] ALUResultM_reg ;
    reg [31:0] ReadDataM_reg , PCPlus4M_reg ;
    reg [4:0] RD_M_reg ;

    //Data Memory Initiasation
    Data_Memory data_memory(
                            .clk(clk),
                            .rst(rst),
                            .WE(MemWriteM),
                            .WD(WriteDataM),
                            .A(ALUResultM),
                            .RD(ReadDataM)
                            );

    //Register Declaration
    always @(posedge clk or negedge rst) begin
        if(rst == 1'b0 ) begin
            RegWriteM_reg    <= 1'b0 ;
            ResultSrcM_reg   <= 1'b0 ;
            ALUResultM_reg   <= 32'h0000_0000 ;
            ReadDataM_reg    <= 32'h0000_0000 ;
            PCPlus4M_reg     <= 32'h0000_0000 ;
            RD_M_reg         <= 5'h00 ;
        end
        else begin
            RegWriteM_reg    <= RegWriteM ;
            ResultSrcM_reg   <= ResultSrcM ;
            ALUResultM_reg   <= ALUResultM ;
            ReadDataM_reg    <= ReadDataM ;
            PCPlus4M_reg     <= PCPlus4M ;
            RD_M_reg         <= RD_M ;
        end
    end

    //Assign output
    assign RegWriteW   = RegWriteM_reg ; 
    assign ResultSrcW  = ResultSrcM_reg ;
    assign ALUResultW  = ALUResultM_reg ;
    assign ReadDataW   = ReadDataM_reg ; 
    assign PCPlus4W    = PCPlus4M_reg ;
    assign RD_W        = RD_M_reg ;

endmodule

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


module Pipeline_top(clk, rst);

    //Declaration of I/O
    input clk, rst ;

    //Declaration of wires
    wire PCSrcE, RegWriteW, RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE, RegWriteM, ResultSrcM, MemWriteM ;
    wire [2:0] ALUControlE ;
    wire [1:0] ForwardAE, ForwardBE ;
    wire [4:0] RDW, RD_E, RD_M, Rs1_E, Rs2_E ;
    wire [31:0] PCTargetE, InstrD, PCD, PCPlus4D, ResultW, RD1_E, RD2_E, Imm_Ext_E, PCE, PCPlus4E ;
    wire [31:0] WriteDataM, PCPlus4M, ALUResultM;
    wire [31:0] ALUResultW, ReadDataW, PCPlus4W;
    wire ResultSrcW;

    //Fetch_Cycle
    fetch_cycle fetch(
                        .clk(clk), 
                        .rst(rst), 
                        .PCSrcE(PCSrcE), 
                        .PCTargetE(PCTargetE), 
                        .InstrD(InstrD), 
                        .PCD(PCD), 
                        .PCPlus4D(PCPlus4D)
                    );

    //Decoder_Cycle
    decode_cycle decode(
                        .clk(clk), 
                        .rst(rst), 
                        .PCSrcE(PCSrcE),
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
                        .PCPlus4E(PCPlus4E),
                        .Rs1_E(Rs1_E),
                        .Rs2_E(Rs2_E)
                        );

    //Execute_Cycle
    execute_cycle execute(
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
                        .ALU_ResultM(ALUResultM), 
                        .WriteDataM(WriteDataM), 
                        .RD_M(RD_M), 
                        .PCPlus4M(PCPlus4M),
                        .ResultW(ResultW),
                        .ForwardAE(ForwardAE),
                        .ForwardBE(ForwardBE),
                        .ALUResultM_In(ALUResultM)
                    );

    //Memory_Cycle
    memory_cycle memory(
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
                        .RD_W(RDW) 
                    );
    //Write Bach Cycle
    write_back_cycle write_back(
                        .clk(clk), 
                        .rst(rst),  
                        .ResultSrcW(ResultSrcW), 
                        .ALUResultW(ALUResultW), 
                        .ReadDataW(ReadDataW), 
                        .PCPlus4W(PCPlus4W), 
                        .ResultW(ResultW)
                    );
    

    //Hazard Unit 
    hazard_unit Forwarding_Block(
                .rst(rst),
                .RegWriteM(RegWriteM),
                .RegWriteW(RegWriteW),
                .RD_M(RD_M),
                .RD_W(RDW),
                .Rs1_E(Rs1_E),
                .Rs2_E(Rs2_E),
                .ForwardAE(ForwardAE),
                .ForwardBE(ForwardBE)
                );

endmodule
