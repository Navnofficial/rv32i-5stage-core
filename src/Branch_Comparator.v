// Branch Comparator — evaluates all 6 RV32I branch conditions
// funct3 encoding for branches:
//   000 = BEQ
//   001 = BNE
//   100 = BLT
//   101 = BGE
//   110 = BLTU
//   111 = BGEU
module Branch_Comparator(SrcA, SrcB, funct3, BranchE, BranchTaken);

    input  [31:0] SrcA, SrcB;
    input  [2:0]  funct3;
    input         BranchE;
    output        BranchTaken;

    wire signed [31:0] signed_A = SrcA;
    wire signed [31:0] signed_B = SrcB;

    reg result;

    always @(*) begin
        case (funct3)
            3'b000: result = (SrcA == SrcB);              // BEQ
            3'b001: result = (SrcA != SrcB);              // BNE
            3'b100: result = (signed_A < signed_B);       // BLT
            3'b101: result = (signed_A >= signed_B);      // BGE
            3'b110: result = (SrcA < SrcB);               // BLTU
            3'b111: result = (SrcA >= SrcB);              // BGEU
            default: result = 1'b0;
        endcase
    end

    assign BranchTaken = BranchE & result;

endmodule
