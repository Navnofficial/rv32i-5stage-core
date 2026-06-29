`timescale 1ns/1ps
module UART_TOP_tb;

localparam CLK_FREQ     = 50_000_000;
localparam BAUD_RATE    = 115_200;
localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
localparam CLK_PERIOD   = 20;
localparam BIT_PERIOD   = CLKS_PER_BIT * CLK_PERIOD;

reg        clk, rst;
reg  [7:0] tx_data;
reg        tx_start;
wire       tx_busy;
wire [7:0] rx_data;
wire       rx_valid;
wire       loop;

// TX pin wired directly to RX pin
UART_TOP #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) dut (
    .clk     (clk),
    .rst     (rst),
    .rx      (loop),
    .tx      (loop),
    .rx_data (rx_data),
    .rx_valid(rx_valid),
    .tx_data (tx_data),
    .tx_start(tx_start),
    .tx_busy (tx_busy)
);

initial clk = 0;
always #(CLK_PERIOD/2) clk = ~clk;

reg       got_valid;
reg [7:0] got_data;

// ----------------------------------------------------------------
// Send byte through TX
// ----------------------------------------------------------------
task send_byte;
    input [7:0] data;
    begin
        @(posedge clk);
        tx_data  = data;
        tx_start = 1'b1;
        @(posedge clk);
        tx_start = 1'b0;
        wait(tx_busy === 1'b0);
    end
endtask

// ----------------------------------------------------------------
// Watch RX side for rx_valid
// ----------------------------------------------------------------
task watch_rx;
    begin
        got_valid = 0;
        got_data  = 0;
        #1;
        wait(rx_valid === 1'b1);
        got_valid = 1;
        got_data  = rx_data;
    end
endtask

// ----------------------------------------------------------------
// Send and check loopback
// ----------------------------------------------------------------
task loopback_check;
    input [7:0] data;
    begin
        fork
            send_byte(data);
            watch_rx;
        join
        if (!got_valid)
            $display("[TB] FAIL: No rx_valid for 0x%02X", data);
        else if (got_data === data)
            $display("[TB] PASS: Loopback 0x%02X", got_data);
        else
            $display("[TB] FAIL: Sent 0x%02X received 0x%02X", data, got_data);
    end
endtask

initial begin
    $dumpfile("uart_top_tb.vcd");
    $dumpvars(0, UART_TOP_tb);

    $display("[TB] CLKS_PER_BIT = %0d", CLKS_PER_BIT);

    rst      = 1'b0;
    tx_start = 1'b0;
    tx_data  = 8'h00;
    #(CLK_PERIOD * 4);
    rst = 1'b1;
    #(CLK_PERIOD * 4);

    loopback_check(8'h55);
    #(BIT_PERIOD * 2);

    loopback_check(8'hA3);
    #(BIT_PERIOD * 2);

    loopback_check(8'hAA);
    #(BIT_PERIOD * 2);

    $display("[TB] Done.");
    $finish;
end

always @(posedge clk)
    if (rx_valid)
        $display("[MON] Loopback rx_data=0x%02X  t=%0t ns", rx_data, $time);

endmodule