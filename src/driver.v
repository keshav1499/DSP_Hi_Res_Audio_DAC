module driver (
    input wire clk,         // 27 MHz system clock
    input wire btn1,        // Placeholder (e.g., for play/pause switch)
    output wire bck,        // Bit clock (from PLL @ 4.8 MHz)
    output reg ws = 0,      // Word Select (left/right channel toggle)
    output reg data = 0,     // I2S serial data output
    output mute
);

// === Parameters ===
localparam RESBIT     = 5'd24;                     // 24-bit audio
localparam RESFREQ    = 20'd96_000;                // 96 kHz sample rate
localparam TOTAL_BITS = (RESBIT + 1) * 2;          // Total I2S bit cycles per frame (25 + 25)
localparam COUNTMAX   = TOTAL_BITS - 1;            // Last index of bit count (0 to 49)
localparam ROM_ADDR_WIDTH = 8;                     // Address bits (e.g., 256 samples)

//========================================== Button Toggle Logic for Mute ==========================================
reg btn1_sync_0 = 1, btn1_sync_1 = 1;
reg btn1_prev = 1;
reg mute_state = 0;

// Synchronize and edge detect
always @(posedge clk) begin
    btn1_sync_0 <= btn1;
    btn1_sync_1 <= btn1_sync_0;
    btn1_prev <= btn1_sync_1;
end

wire btn1_pressed = (btn1_prev == 1) && (btn1_sync_1 == 0); // falling edge

// Toggle mute state on falling edge
always @(posedge clk) begin
    if (btn1_pressed)
        mute_state <= ~mute_state;
end

assign mute = mute_state;
//==============================================Mute Logic Ends=======================================================


// === Clock Generation (PLL) ===
// We generate 4.8 MHz BCK from 27 MHz input externally (using Gowin_rPLL)
Gowin_rPLL CLK_27_TO_4_8(
    .clkoutd(bck), // 4.8 MHz output clock for BCK
    .clkin(clk)    // 27 MHz input clock
);

// === ROM-based Sine Wave Table ===
// 256-entry ROM with precomputed 24-bit signed samples (dummy sine tone)
reg [23:0] sine_rom [0:(1<<ROM_ADDR_WIDTH)-1];
initial $readmemh("sine_wave_24bit.hex", sine_rom); // preload from file

reg [ROM_ADDR_WIDTH-1:0] rom_addr = 0;  // sample index pointer

// === Current audio sample registers ===
reg [23:0] left_sample  = 24'd0;
reg [23:0] right_sample = 24'd0;

// === Bit Counter (0 to 49) for 24-bit stereo + 1 wait bit per channel ===
reg [5:0] bit_count = 0;

always @(posedge bck) begin
    if (bit_count == COUNTMAX)
        bit_count <= 0;
    else
        bit_count <= bit_count + 1;
end

// === Word Select Toggle (ws) ===
// Toggled after the wait bit (at bit_count == 1 for left, at bit_count == 26 for right)
always @(negedge bck) begin
    if (bit_count == 0 || bit_count == RESBIT + 1)
        ws <= ~ws;
end

// === Audio Sample Loader ===
// Load a new sample at the start of every full I2S frame (bit_count == 0)
always @(posedge bck) begin
    if (bit_count == 0) begin
        left_sample  <= sine_rom[rom_addr];
        right_sample <= sine_rom[rom_addr];
        rom_addr     <= rom_addr + 1; // advance to next sample
    end
end

// === I2S Data Line Driver ===
// Send MSB-first 24-bit samples with 1-bit wait per channel
always @(negedge bck) begin
    if (bit_count == 0 || bit_count == RESBIT + 1) begin
        // Wait bit (bit 24) for each channel
        data <= 0;
    end else if (bit_count < RESBIT + 1) begin
        // Left channel: bits 23 downto 0
        data <= left_sample[23 - (bit_count - 1)];
    end else if (bit_count < TOTAL_BITS) begin
        // Right channel: bits 23 downto 0
        data <= right_sample[23 - (bit_count - (RESBIT + 1))];
    end else begin
        // Undefined zone (should not happen)
        data <= 0;
    end
end

endmodule
