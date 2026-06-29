// ============================================================
// UART_TOP.v
// Instantiates UART_RX and UART_TX. No additional logic.
// ============================================================

module UART_TOP #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115_200
)(
    input  wire       clk,
    input  wire       rst,

    // Physical pins
    input  wire       rx,
    output wire       tx,

    // RX interface
    output wire [7:0] rx_data,
    output wire       rx_valid,

    // TX interface
    input  wire [7:0] tx_data,
    input  wire       tx_start,
    output wire       tx_busy
);

UART_RX #(
    .CLK_FREQ  (CLK_FREQ),
    .BAUD_RATE (BAUD_RATE)
) u_rx (
    .clk     (clk),
    .rst     (rst),
    .rx      (rx),
    .rx_data (rx_data),
    .rx_valid(rx_valid)
);

UART_TX #(
    .CLK_FREQ  (CLK_FREQ),
    .BAUD_RATE (BAUD_RATE)
) u_tx (
    .clk     (clk),
    .rst     (rst),
    .tx_data (tx_data),
    .tx_start(tx_start),
    .tx      (tx),
    .tx_busy (tx_busy)
);

endmodule