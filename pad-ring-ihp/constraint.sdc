# SPDX-License-Identifier: Apache-2.0
# Minimal constraints for the pad-ring-ihp padring demo.
# The clock enters through the clk input pad; the core-side clock is the
# p2c pin of sg13g2_IOPad_io_clk (net clk_i).

current_design chip_top
set_units -time ns -resistance kOhm -capacitance pF -voltage V -current uA

set_max_fanout 8 [current_design]
set_max_transition 3 [current_design]

# ---- Clock (defined at the clock pad output) -------------------------------
set_ideal_network [get_pins sg13g2_IOPad_io_clk/p2c]
create_clock [get_pins sg13g2_IOPad_io_clk/p2c] -name clk_core -period 20.0 -waveform {0 10}
set_clock_uncertainty 0.15 [get_clocks clk_core]
set_clock_transition 0.25 [get_clocks clk_core]

# ---- Input pads (sg13g2_IOPadIn) -------------------------------------------
set input_ports [get_ports {
    clk_PAD
    rst_n_PAD
    din_lo_PAD[0] din_lo_PAD[1] din_lo_PAD[2]
    din_lo_PAD[3] din_lo_PAD[4] din_lo_PAD[5]
    din_hi_PAD[0] din_hi_PAD[1]
    start_PAD
    mode_PAD
}]
set_driving_cell -lib_cell sg13g2_IOPadIn -pin pad $input_ports
set_input_delay 8 -clock clk_core $input_ports

# ---- Output pads (sg13g2_IOPadOut30mA) -------------------------------------
set output_ports [get_ports {
    dout_PAD[0] dout_PAD[1] dout_PAD[2] dout_PAD[3]
    dout_PAD[4] dout_PAD[5] dout_PAD[6] dout_PAD[7]
    done_PAD busy_PAD irq_PAD
}]
set_driving_cell -lib_cell sg13g2_IOPadOut30mA -pin pad $output_ports
set_output_delay 8 -clock clk_core $output_ports

# ---- Bidirectional pad (sg13g2_IOPadInOut30mA) -----------------------------
set inout_ports [get_ports { gpio_PAD }]
set_driving_cell -lib_cell sg13g2_IOPadInOut30mA -pin pad $inout_ports
set_input_delay 8 -clock clk_core $inout_ports
set_output_delay 8 -clock clk_core $inout_ports

set_load -pin_load 5 [all_inputs]
set_load -pin_load 5 [all_outputs]
