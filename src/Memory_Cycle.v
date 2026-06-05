


module memory_cycle(
    clk, rst,
    RegWriteM, ResultSrcM, MemWriteM,
    ALUResultM, WriteDataM, PCPlus4M, RD_M,
    Funct3M,
    RegWriteW, ResultSrcW,
    ALUResultW, ReadDataW, PCPlus4W, RD_W
);

    input  clk, rst;
    input  RegWriteM, MemWriteM;
    input  [1:0]  ResultSrcM;
    input  [31:0] ALUResultM, WriteDataM, PCPlus4M;
    input  [4:0]  RD_M;
    input  [2:0]  Funct3M;

    output        RegWriteW;
    output [1:0]  ResultSrcW;
    output [31:0] ALUResultW;
    output [31:0] ReadDataW, PCPlus4W;
    output [4:0]  RD_W;

    // Internal
    wire [31:0] ReadDataM;

    // MEM/WB pipeline registers
    reg        RegWriteM_reg;
    reg [1:0]  ResultSrcM_reg;
    reg [31:0] ALUResultM_reg;
    reg [31:0] ReadDataM_reg, PCPlus4M_reg;
    reg [4:0]  RD_M_reg;

    // Data Memory
    Data_Memory data_memory(
        .clk   (clk),
        .rst   (rst),
        .WE    (MemWriteM),
        .funct3(Funct3M),
        .WD    (WriteDataM),
        .A     (ALUResultM),
        .RD    (ReadDataM)
    );

    // MEM/WB pipeline register
    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            RegWriteM_reg  <= 1'b0;
            ResultSrcM_reg <= 2'b00;
            ALUResultM_reg <= 32'h0000_0000;
            ReadDataM_reg  <= 32'h0000_0000;
            PCPlus4M_reg   <= 32'h0000_0000;
            RD_M_reg       <= 5'h00;
        end else begin
            RegWriteM_reg  <= RegWriteM;
            // Store full 2-bit ResultSrc (00=ALU, 01=Mem, 10=PC+4)
            ResultSrcM_reg <= ResultSrcM;
            ALUResultM_reg <= ALUResultM;
            ReadDataM_reg  <= ReadDataM;
            PCPlus4M_reg   <= PCPlus4M;
            RD_M_reg       <= RD_M;
        end
    end

    assign RegWriteW  = RegWriteM_reg;
    assign ResultSrcW = ResultSrcM_reg;
    assign ALUResultW = ALUResultM_reg;
    assign ReadDataW  = ReadDataM_reg;
    assign PCPlus4W   = PCPlus4M_reg;
    assign RD_W       = RD_M_reg;

endmodule
