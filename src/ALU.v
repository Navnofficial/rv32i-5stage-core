module ALU(A, B, Result, ALUControl, OverFlow, Carry, Zero, Negative);

    input  [31:0] A, B;
    input  [3:0]  ALUControl;
    output        Carry, OverFlow, Zero, Negative;
    output [31:0] Result;

    wire        Cout;
    wire [31:0] Sum;
    wire [31:0] SLT_result, SLTU_result;
    wire [4:0]  shamt;
    wire [31:0] sra_result;

    assign {Cout, Sum} = (ALUControl[0] == 1'b0) ? (A + B) : (A + (~B) + 1);

    assign shamt = B[4:0];
    assign sra_result = $signed(A) >>> shamt;  // must be separate wire to preserve signedness

    assign SLT_result  = {{31{1'b0}}, (A[31] ^ B[31]) ? A[31] : Sum[31]};
    assign SLTU_result = {{31{1'b0}}, ~Cout};

    assign Result =
        (ALUControl == 4'b0000) ? Sum          :  // ADD
        (ALUControl == 4'b0001) ? Sum          :  // SUB
        (ALUControl == 4'b0010) ? A & B        :  // AND
        (ALUControl == 4'b0011) ? A | B        :  // OR
        (ALUControl == 4'b0100) ? A ^ B        :  // XOR
        (ALUControl == 4'b0101) ? SLT_result   :  // SLT
        (ALUControl == 4'b0110) ? SLTU_result  :  // SLTU
        (ALUControl == 4'b0111) ? A << shamt   :  // SLL
        (ALUControl == 4'b1000) ? A >> shamt   :  // SRL
        (ALUControl == 4'b1001) ? sra_result  :  // SRA (separate wire preserves sign)
                                  32'h0000_0000;

    assign OverFlow  = ((Sum[31] ^ A[31]) & (~(ALUControl[0] ^ B[31] ^ A[31])) & (~ALUControl[1]));
    assign Carry     = (~ALUControl[1]) & (~ALUControl[0]) & Cout | // ADD carry
                       ( ALUControl[0]) & (~ALUControl[1]) & (~Cout); // SUB borrow (inverted)
    assign Zero      = &(~Result);
    assign Negative  = Result[31];

endmodule
