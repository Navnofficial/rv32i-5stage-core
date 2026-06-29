// ============================================================
// UART_TX_tb.v — Pure Verilog 2001
// Sends bytes, reconstructs them by sampling the tx line,
// and checks the result.
// ============================================================
`timescale 1ns/1ps

module UART_TX_tb;

localparam CLK_FREQ     = 50_000_000;
localparam BAUD_RATE    = 115_200;
localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
localparam CLK_PERIOD   = 20;
localparam BIT_PERIOD   = CLKS_PER_BIT * CLK_PERIOD;

reg        clk;
reg        rst;
reg  [7:0] tx_data;
reg        tx_start;
wire       tx;
wire       tx_busy;

UART_TX #(
    .CLK_FREQ  (CLK_FREQ),
    .BAUD_RATE (BAUD_RATE)
) dut (
    .clk     (clk),
    .rst     (rst),
    .tx_data (tx_data),
    .tx_start(tx_start),
    .tx      (tx),
    .tx_busy (tx_busy)
);

initial clk = 0;
always #(CLK_PERIOD/2) clk = ~clk;

// ----------------------------------------------------------------
// Task: pulse tx_start for one clock then wait until tx_busy low
// ----------------------------------------------------------------
task send_byte;
    input [7:0] data;
    integer timeout;
    begin
        @(posedge clk);
        tx_data  = data;
        tx_start = 1'b1;
        @(posedge clk);
        tx_start = 1'b0;

        // Wait for tx_busy to go low (transmission complete)
        timeout = 0;
        while (tx_busy === 1'b1 && timeout < 5000) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        if (timeout >= 5000)
            $display("[TB] FAIL: tx_busy never cleared for 0x%02X", data);
    end
endtask

// ----------------------------------------------------------------
// Task: capture one frame from the tx line by sampling bit centres
// ----------------------------------------------------------------
task capture_byte;
    output [7:0] captured;
    integer i;
    begin
        captured = 0;

        // Wait for start bit (tx goes LOW)
        while (tx !== 1'b0) #(CLK_PERIOD);

        // Skip to middle of start bit
        #(BIT_PERIOD / 2);

        // Verify it is still LOW (valid start bit)
        if (tx !== 1'b0)
            $display("[CAPTURE] Warning: start bit not LOW at centre");

        // Sample 8 data bits at mid-point of each bit period
        for (i = 0; i < 8; i = i + 1) begin
            #(BIT_PERIOD);
            captured[i] = tx;
        end

        // Skip stop bit
        #(BIT_PERIOD);
    end
endtask

// ----------------------------------------------------------------
// Stimulus
// ----------------------------------------------------------------
reg [7:0] received;

initial begin
    $dumpfile("uart_tx_tb.vcd");
    $dumpvars(0, UART_TX_tb);

    $display("[TB] CLKS_PER_BIT = %0d", CLKS_PER_BIT);

    rst      = 1'b0;
    tx_start = 1'b0;
    tx_data  = 8'h00;
    #(CLK_PERIOD * 4);
    rst = 1'b1;
    #(CLK_PERIOD * 4);

    // ---- Send 0x55, capture and verify ----
    $display("[TB] Sending 0x55");
    fork
        send_byte(8'h55);
        capture_byte(received);
    join
    if (received === 8'h55)
        $display("[TB] PASS: Captured 0x%02X", received);
    else
        $display("[TB] FAIL: Expected 0x55, got 0x%02X", received);

    #(BIT_PERIOD);

    // ---- Send 0xA3 ----
    $display("[TB] Sending 0xA3");
    fork
        send_byte(8'hA3);
        capture_byte(received);
    join
    if (received === 8'hA3)
        $display("[TB] PASS: Captured 0x%02X", received);
    else
        $display("[TB] FAIL: Expected 0xA3, got 0x%02X", received);

    #(BIT_PERIOD);

    // ---- Send 0xAA ----
    $display("[TB] Sending 0xAA");
    fork
        send_byte(8'hAA);
        capture_byte(received);
    join
    if (received === 8'hAA)
        $display("[TB] PASS: Captured 0x%02X", received);
    else
        $display("[TB] FAIL: Expected 0xAA, got 0x%02X", received);

    #(BIT_PERIOD * 3);
    $display("[TB] Done.");
    $finish;
end

always @(posedge clk) begin
    if (tx_start)
        $display("[MON] tx_start asserted  tx_data=0x%02X  t=%0t ns", tx_data, $time);
end

endmodule