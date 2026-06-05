// Byte-addressable Data Memory with funct3-controlled width
// funct3 encoding for loads/stores:
//   000 = byte (LB/SB)
//   001 = halfword (LH/SH)
//   010 = word (LW/SW)
//   100 = byte unsigned (LBU)
//   101 = halfword unsigned (LHU)

module Data_Memory(clk, rst, WE, funct3, WD, A, RD);

    input        clk, rst, WE;
    input  [2:0] funct3;
    input  [31:0] A, WD;
    output [31:0] RD;

    reg [7:0] mem [4095:0];  // byte-addressable, 4KB

    wire [11:0] byte_addr = A[11:0];

    // ---- Writes ----
    always @(posedge clk) begin
        if (WE && rst) begin
            case (funct3)
                3'b000: begin  // SB — store byte
                    mem[byte_addr] <= WD[7:0];
                end
                3'b001: begin  // SH — store halfword
                    mem[byte_addr]     <= WD[7:0];
                    mem[byte_addr + 1] <= WD[15:8];
                end
                default: begin  // SW — store word (funct3 == 3'b010)
                    mem[byte_addr]     <= WD[7:0];
                    mem[byte_addr + 1] <= WD[15:8];
                    mem[byte_addr + 2] <= WD[23:16];
                    mem[byte_addr + 3] <= WD[31:24];
                end
            endcase
        end
    end

    // ---- Reads ----
    wire [31:0] word_data = {mem[byte_addr+3], mem[byte_addr+2],
                              mem[byte_addr+1], mem[byte_addr]};
    wire [15:0] half_data = {mem[byte_addr+1], mem[byte_addr]};
    wire [7:0]  byte_data =  mem[byte_addr];

    assign RD = (~rst) ? 32'd0 :
                (funct3 == 3'b000) ? {{24{byte_data[7]}},  byte_data}         : // LB
                (funct3 == 3'b001) ? {{16{half_data[15]}}, half_data}          : // LH
                (funct3 == 3'b010) ? word_data                                 : // LW
                (funct3 == 3'b100) ? {24'b0,               byte_data}         : // LBU
                (funct3 == 3'b101) ? {16'b0,               half_data}          : // LHU
                                     word_data;                                  // default

    // Initialize data memory to 0
    integer i;
    initial begin
        for (i = 0; i < 4096; i = i + 1)
            mem[i] = 8'h00;
    end

endmodule