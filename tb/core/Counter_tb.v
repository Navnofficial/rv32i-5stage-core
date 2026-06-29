`timescale 1ns/1ps

module Counter_tb;

reg clk;
reg rst;

Pipeline_top dut(
    .clk(clk),
    .rst(rst)
);

initial
    clk = 0;

always #5 clk = ~clk;


initial begin
    $dumpfile("Counter_dump.vcd");
    $dumpvars(0, Counter_tb);

    rst = 0;
    #22;           
    rst = 1;

    #500;

    $finish;
end



always @(posedge clk) begin
    if (rst)
        $display("t=%0t  x10(a0)=%0d  x11(a1)=%0d", $time,
                 dut.decode.Reg_file.Register[10],
                 dut.decode.Reg_file.Register[11]);
end


endmodule