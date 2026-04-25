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