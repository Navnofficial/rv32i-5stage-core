module Sign_Extend (In, Imm_Ext, ImmSrc);
    //sign extend use for ? 
    // sign extend is used to sign extend the immediate value
    // because immediate value is only 20 bits long 
    // and in 32 bit system we need 32 bit immediate value  

    input  [31:7] In; // Immediate value without last 7 bits 
    
    // why last 7 bits are zero? 
    // in I-type last 7 bits are opcode and funct3 which are not part of immediate value

    input  [2:0]  ImmSrc;
    output reg [31:0] Imm_Ext;

    always @(*) begin
        case (ImmSrc)
            // I-type: lw, addi, xori, etc. + JALR
            3'b000: Imm_Ext = {{20{In[31]}}, In[31:20]};  
            //first 20 bits are sign extended and last 12 bits are immediate value of I-type

            // S-type: sw, sb, sh
            3'b001: Imm_Ext = {{20{In[31]}}, In[31:25], In[11:7]};

            // B-type: beq, bne, blt, bge, bltu, bgeu
            3'b010: Imm_Ext = {{20{In[31]}}, In[7], In[30:25], In[11:8], 1'b0};

            // J-type: jal
            3'b011: Imm_Ext = {{12{In[31]}}, In[19:12], In[20], In[30:21], 1'b0};

            // U-type: lui, auipc
            3'b100: Imm_Ext = {In[31:12], 12'b0};

            default: Imm_Ext = 32'h0000_0000;
        endcase
    end

endmodule