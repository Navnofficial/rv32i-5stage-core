module ALU_Decoder(ALUOp, funct3, funct7, op, ALUControl);

    input  [1:0] ALUOp; // mea
    input  [2:0] funct3;
    input  [6:0] funct7, op;
    output [3:0] ALUControl;

    // ALUOp encoding:
    //  00 -> ADD  (for loads, stores, LUI via ALU)
    //  01 -> SUB  (for BEQ / branch compare uses branch comparator, but sub used for AUIPC etc)
    //  10 -> R/I  (decode from funct3/funct7)
    //  11 -> PASS_B (for LUI: 0 + imm, handled by forcing SrcA=0 upstream)

    reg [3:0] ALUControl_reg;

    always @(*) begin
        case (ALUOp)
            2'b00: ALUControl_reg = 4'b0000; // ADD (lw, sw, auipc, lui path)
            2'b01: ALUControl_reg = 4'b0001; // SUB (branch — result not used, comparator handles)
            2'b10: begin
                case (funct3)
                    3'b000: begin
                        // ADD or SUB (R-type) / ADDI (I-type)
                        if ((op[5] == 1'b1) && (funct7[5] == 1'b1))
                            ALUControl_reg = 4'b0001; // SUB
                        else
                            ALUControl_reg = 4'b0000; // ADD / ADDI
                    end
                    3'b001: ALUControl_reg = 4'b0111; // SLL / SLLI
                    3'b010: ALUControl_reg = 4'b0101; // SLT / SLTI
                    3'b011: ALUControl_reg = 4'b0110; // SLTU / SLTIU
                    3'b100: ALUControl_reg = 4'b0100; // XOR / XORI
                    3'b101: begin
                        // SRL / SRLI  or  SRA / SRAI
                        if (funct7[5] == 1'b1)
                            ALUControl_reg = 4'b1001; // SRA / SRAI
                        else
                            ALUControl_reg = 4'b1000; // SRL / SRLI
                    end
                    3'b110: ALUControl_reg = 4'b0011; // OR  / ORI
                    3'b111: ALUControl_reg = 4'b0010; // AND / ANDI
                    default: ALUControl_reg = 4'b0000;
                endcase
            end
            default: ALUControl_reg = 4'b0000; // default ADD
        endcase
    end

    assign ALUControl = ALUControl_reg;

endmodule