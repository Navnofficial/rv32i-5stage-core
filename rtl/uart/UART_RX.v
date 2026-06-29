// ============================================================
// UART_RX.v
// Receives 8N1 UART frames at parameterized baud rate.
// Includes dual-FF synchronizer, start bit detection,
// mid-bit sampling, and a clean 4-state FSM.
// Active LOW reset.
// ============================================================

module UART_RX #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115_200
)(
    input  wire       clk,
    input  wire       rst,       // Active LOW

    input  wire       rx,        // Raw pin from CH340

    output reg  [7:0] rx_data,   // Received byte
    output reg        rx_valid   // Pulses HIGH for one clock when byte is ready
);

// ------------------------------------------------------------
// Derived parameter
// ------------------------------------------------------------
localparam CLKS_PER_BIT  = CLK_FREQ / BAUD_RATE;   // 434
localparam HALF_BIT      = CLKS_PER_BIT / 2;        // 217

// ------------------------------------------------------------
// FSM state encoding
// ------------------------------------------------------------
localparam S_IDLE  = 2'd0;
localparam S_START = 2'd1;
localparam S_DATA  = 2'd2;
localparam S_STOP  = 2'd3;

// ------------------------------------------------------------
// Dual flip-flop synchronizer
// Prevents metastability on the async RX pin.
// ------------------------------------------------------------
reg rx_ff1, rx_ff2;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        rx_ff1 <= 1'b1;
        rx_ff2 <= 1'b1;
    end else begin
        rx_ff1 <= rx;
        rx_ff2 <= rx_ff1;
    end
end

// rx_sync is the clean, metastability-safe version of the RX pin
wire rx_sync = rx_ff2;

// ------------------------------------------------------------
// Internal registers
// ------------------------------------------------------------
reg [1:0]  state;
reg [9:0]  clk_cnt;   // Counts up to CLKS_PER_BIT (needs ≥9 bits for 434)
reg [2:0]  bit_idx;   // Which data bit we are receiving (0–7)
reg [7:0]  rx_shift;  // Shift register assembling the byte

// ------------------------------------------------------------
// FSM
// ------------------------------------------------------------
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        state     <= S_IDLE;
        clk_cnt   <= 0;
        bit_idx   <= 0;
        rx_shift  <= 0;
        rx_data   <= 0;
        rx_valid  <= 0;
    end else begin

        // Default: de-assert valid every cycle
        rx_valid <= 1'b0;

        case (state)

            // ------------------------------------------------
            // Wait for line to go LOW (start bit)
            // ------------------------------------------------
            S_IDLE: begin
                clk_cnt <= 0;
                bit_idx <= 0;
                if (rx_sync == 1'b0)        // Falling edge detected
                    state <= S_START;
            end

            // ------------------------------------------------
            // Confirm start bit at mid-point
            // If still LOW at HALF_BIT, it is a real start bit.
            // If HIGH, it was a glitch — return to IDLE.
            // ------------------------------------------------
            S_START: begin
                if (clk_cnt == HALF_BIT - 1) begin
                    if (rx_sync == 1'b0) begin
                        clk_cnt <= 0;       // Reset counter for data bits
                        state   <= S_DATA;
                    end else begin
                        state   <= S_IDLE;  // Glitch, abort
                    end
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end

            // ------------------------------------------------
            // Sample 8 data bits at the centre of each bit period
            // LSB arrives first (standard UART)
            // ------------------------------------------------
            S_DATA: begin
                if (clk_cnt == CLKS_PER_BIT - 1) begin
                    clk_cnt              <= 0;
                    rx_shift[bit_idx]    <= rx_sync;   // Sample into shift reg

                    if (bit_idx == 3'd7) begin
                        bit_idx <= 0;
                        state   <= S_STOP;
                    end else begin
                        bit_idx <= bit_idx + 1;
                    end
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end

            // ------------------------------------------------
            // Wait through the stop bit, then latch output
            // ------------------------------------------------
            S_STOP: begin
                if (clk_cnt == CLKS_PER_BIT - 1) begin
                    rx_data  <= rx_shift;   // Latch complete byte
                    rx_valid <= 1'b1;       // Pulse valid for one clock
                    clk_cnt  <= 0;
                    state    <= S_IDLE;
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end

            default: state <= S_IDLE;

        endcase
    end
end

endmodule