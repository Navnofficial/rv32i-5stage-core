module PC_Module(clk, rst, StallF, PC, PC_Next);

    input  clk, rst, StallF;
    input  [31:0] PC_Next;
    output reg [31:0] PC;

    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0)
            PC <= 32'h0000_0000;
        else if (!StallF)
            PC <= PC_Next;
    end

endmodule