// 2-to-1 Mux (32-bit)
module Mux (a, b, s, c);
    input  [31:0] a, b;
    input         s;
    output [31:0] c;
    assign c = (s == 1'b1) ? b : a;
endmodule

// 3-to-1 Mux (32-bit)
module Mux3x1 (a, b, c, s, d);
    input  [31:0] a, b, c;
    input  [1:0]  s;
    output [31:0] d;
    assign d = (s == 2'b00) ? a :
               (s == 2'b01) ? b :
               (s == 2'b10) ? c :
                              32'h0000_0000;
endmodule

// 4-to-1 Mux (32-bit)
module Mux4x1 (a, b, c, dd, s, e);
    input  [31:0] a, b, c, dd;
    input  [1:0]  s;
    output [31:0] e;
    assign e = (s == 2'b00) ? a  :
               (s == 2'b01) ? b  :
               (s == 2'b10) ? c  :
                              dd;
endmodule