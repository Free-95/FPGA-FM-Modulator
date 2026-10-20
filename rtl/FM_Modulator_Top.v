`timescale 1ns / 1ps

module FM_Modulator_Top (
    input        clk,             // 100 MHz Nexys A7 Clock (Pin E3)
    output [7:0] fm_out_pmod,     // 8-bit FM Output to Pmod JA
    output       pll_locked_led   // LED0 (Pin H17) indicates 200 MHz lock
);

    // Clocks and Status Signals
    wire clk100MHz;
    wire clk200MHz;
    wire clk10MHz;
    wire locked_Sig;

    assign pll_locked_led = locked_Sig;

    // Internal DSP Pipeline Buses
    wire               m_axis_data_tvalid_Sig;
    wire signed [15:0] Message_Tone;             // 14-bit magnitude + sign in 16-bit AXI bus
    wire signed [35:0] MessageMultiplied;        // 36-bit product from multiplier IP
    wire signed [35:0] tmp_shifted;              // Arithmetic right-shifted deviation by 14
    wire signed [22:0] MessageMultipliedShifted; // Sliced 23-bit deviation [-805306, +805306]
    wire        [31:0] Fm_Plus_Carrier;          // 32-bit AXI phase step (114890375 +/- 805306)
    wire               DDS1_tvalid_out;
    wire signed [7:0]  ModulatedSignalOut;       // 8-bit FM Carrier Output (10.7 MHz)

    // Block 0: Clocking Wizard (100 MHz -> 200 MHz)
    clk_wiz_0 Clk_Wizard (
        .clk_in1  (clk),
        .clk_out1 (clk100MHz),
        .clk_out2 (clk200MHz),
        .clk_out3 (clk10MHz),
        .locked   (locked_Sig)
    );

    // Block 1: Message DDS (5 kHz Baseband Sine Wave)
    dds_compiler_0 DDS_0 (
        .aclk               (clk200MHz),
        .m_axis_data_tvalid (m_axis_data_tvalid_Sig),
        .m_axis_data_tdata  (Message_Tone)
    );

    // Block 2: Constant Coefficient Multiplier (Message_Tone * 805,306)
    mult_gen_0 Multiplier (
        .CLK (clk200MHz),
        .A   (Message_Tone),
        .P   (MessageMultiplied)
    );

    // Block 3: Arithmetic Right Shift by 14 bits (Divide by 16,384)
    assign tmp_shifted              = MessageMultiplied >>> 14;
    assign MessageMultipliedShifted = tmp_shifted[22:0];

    // Block 4: Carrier Adder (114,890,375 + MessageMultipliedShifted)
    c_addsub_0 AdderSub (
        .A   (MessageMultipliedShifted),
        .CLK (clk200MHz),
        .S   (Fm_Plus_Carrier)
    );

    // Block 5: Streaming FM Carrier DDS (10.7 MHz +/- 75 kHz)
    dds_compiler_1 DDS1 (
        .aclk                (clk200MHz),
        .s_axis_phase_tvalid (1'b1),
        .s_axis_phase_tdata  (Fm_Plus_Carrier),
        .m_axis_data_tvalid  (DDS1_tvalid_out),
        .m_axis_data_tdata   (ModulatedSignalOut)
    );

    // External Pmod JA pins
    assign fm_out_pmod = ModulatedSignalOut;

    // Block 6: Integrated Logic Analyzer (ILA) for On-Chip Hardware Debugging
    ila_0 FM_Hardware_ILA (
        .clk    (clk200MHz),
        .probe0 (Message_Tone),       // 16-bit: 5 kHz Message Sine Wave
        .probe1 (Fm_Plus_Carrier),    // 32-bit: Dynamic Phase Increment
        .probe2 (ModulatedSignalOut)  // 8-bit:  10.7 MHz FM Output Wave
    );

endmodule