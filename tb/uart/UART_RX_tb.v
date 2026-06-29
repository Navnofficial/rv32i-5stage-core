// ============================================================
// UART_RX_tb.v — Verilog 2001, fork/join for parallel watch
// ============================================================
`timescale 1ns/1ps

module UART_RX_tb;

localparam CLK_FREQ     = 50_000_000;
localparam BAUD_RATE    = 115_200;
localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
localparam CLK_PERIOD   = 20;
localparam BIT_PERIOD   = CLKS_PER_BIT * CLK_PERIOD;
localparam MAX_WAIT     = BIT_PERIOD * 15;   // timeout ceiling

reg        clk;
reg        rst;
reg        rx;
wire [7:0] rx_data;
wire       rx_valid;

UART_RX #(
    .CLK_FREQ  (CLK_FREQ),
    .BAUD_RATE (BAUD_RATE)
) dut (
    .clk     (clk),
    .rst     (rst),
    .rx      (rx),
    .rx_data (rx_data),
    .rx_valid(rx_valid)
);

initial clk = 0;
always #(CLK_PERIOD/2) clk = ~clk;

// ----------------------------------------------------------------
// Task: drive one byte onto the RX line
// ----------------------------------------------------------------
task send_byte;
    input [7:0] data;
    integer i;
    begin
        rx = 1'b0;
        #(BIT_PERIOD);
        for (i = 0; i < 8; i = i + 1) begin
            rx = data[i];
            #(BIT_PERIOD);
        end
        rx = 1'b1;
        #(BIT_PERIOD);
    end
endtask

// ----------------------------------------------------------------
// Shared result registers written by the watcher process
// ----------------------------------------------------------------
reg        got_valid;
reg [7:0]  got_data;

// ----------------------------------------------------------------
// Task: watch for rx_valid with a hard timeout
// Runs in parallel with send_byte inside a fork/join
// ----------------------------------------------------------------
task watch_valid;
    begin
        got_valid = 0;
        got_data  = 0;
        // Wait until rx_valid goes high OR timeout expires
        #1;                          // let send_byte get one step ahead
        wait (rx_valid === 1'b1 || $time > MAX_WAIT * 10);
        if (rx_valid === 1'b1) begin
            got_valid = 1;
            got_data  = rx_data;
        end
    end
endtask

// ----------------------------------------------------------------
// Task: send + watch in parallel, then report
// ----------------------------------------------------------------
task send_and_check;
    input [7:0] data;
    begin
        fork
            send_byte(data);
            watch_valid;
        join

        if (!got_valid)
            $display("[TB] FAIL: Timeout waiting for rx_valid (sent 0x%02X)", data);
        else if (got_data === data)
            $display("[TB] PASS: Received 0x%02X", got_data);
        else
            $display("[TB] FAIL: Expected 0x%02X, got 0x%02X", data, got_data);
    end
endtask

// ----------------------------------------------------------------
// Stimulus
// ----------------------------------------------------------------
initial begin
    $dumpfile("uart_rx_tb.vcd");
    $dumpvars(0, UART_RX_tb);

    $display("[TB] CLKS_PER_BIT = %0d", CLKS_PER_BIT);

    rst = 1'b0;
    rx  = 1'b1;
    #(CLK_PERIOD * 4);
    rst = 1'b1;
    #(CLK_PERIOD * 4);

    send_and_check(8'h55);
    #(BIT_PERIOD * 2);

    send_and_check(8'hA3);
    #(BIT_PERIOD * 2);

    send_and_check(8'hAA);
    #(BIT_PERIOD * 2);

    $display("[TB] Done.");
    $finish;
end

always @(posedge clk) begin
    if (rx_valid)
        $display("[MON] rx_valid HIGH  rx_data=0x%02X  t=%0t ns", rx_data, $time);
end

endmodule