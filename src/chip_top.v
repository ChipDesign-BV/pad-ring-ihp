// SPDX-License-Identifier: Apache-2.0
//
// chip_top -- chip top level for pad-ring-ihp.
//
// This module builds the *pad ring* by explicitly instantiating IHP SG13G2 IO
// pad cells (sg13g2_IOPad*) around the demo_core instance. The *instance names*
// chosen here are exactly what LibreLane's OpenROAD.PadRing step consumes via
// the PAD_SOUTH / PAD_EAST / PAD_NORTH / PAD_WEST lists in config.yaml.
//
// Pad-cell port convention (see the PDK model
//   $PDK_ROOT/$PDK/libs.ref/sg13g2_io/verilog/sg13g2_io.v):
//   .pad            external bond pad (chip pin)
//   .p2c            pad -> core   (inputs)
//   .c2p            core -> pad   (outputs)
//   .c2p_en         core -> pad output enable (tri-state / inout)
//   .iovdd/.iovss   IO supply ring nets (3.3 V)
//   .vdd/.vss       core supply ring nets (1.2 V)
//
// The four ring nets are only wired under USE_POWER_PINS; physically the ring
// rails are joined by OpenROAD's connect_by_abutment during the PadRing step,
// and global connections tie them to VDD/VSS/IOVDD/IOVSS. Power/ground pads are
// marked (* keep *) so synthesis does not strip them.

module chip_top (
`ifdef USE_POWER_PINS
    inout wire VDD,     // core 1.2 V
    inout wire VSS,     // core ground
    inout wire IOVDD,   // IO 3.3 V
    inout wire IOVSS,   // IO ground
`endif
    // South
    inout wire        clk_PAD,
    inout wire        rst_n_PAD,
    inout wire [5:0]  din_lo_PAD,   // din[5:0]
    // West
    inout wire [1:0]  din_hi_PAD,   // din[7:6]
    inout wire        start_PAD,
    inout wire        mode_PAD,
    // North
    inout wire [7:0]  dout_PAD,
    // East
    inout wire        done_PAD,
    inout wire        busy_PAD,
    inout wire        irq_PAD,
    inout wire        gpio_PAD
);

    // ---- Core-side nets -----------------------------------------------------
    wire        clk_i, rst_n_i, start_i, mode_i;
    wire [7:0]  din_i;
    wire [7:0]  dout_o;
    wire        done_o, busy_o, irq_o;
    wire        gpio_out, gpio_oe, gpio_in;

    // ========================================================================
    // POWER / GROUND PADS  (2 IO + 2 core per side on East and West)
    // ========================================================================
    (* keep *) sg13g2_IOPadIOVdd sg13g2_IOPad_iovdd_w (
    `ifdef USE_POWER_PINS
        .vss(VSS), .vdd(VDD), .iovss(IOVSS), .iovdd(IOVDD)
    `endif
    );
    (* keep *) sg13g2_IOPadIOVss sg13g2_IOPad_iovss_w (
    `ifdef USE_POWER_PINS
        .vss(VSS), .vdd(VDD), .iovss(IOVSS), .iovdd(IOVDD)
    `endif
    );
    (* keep *) sg13g2_IOPadVdd sg13g2_IOPad_vdd_w (
    `ifdef USE_POWER_PINS
        .vss(VSS), .vdd(VDD), .iovss(IOVSS), .iovdd(IOVDD)
    `endif
    );
    (* keep *) sg13g2_IOPadVss sg13g2_IOPad_vss_w (
    `ifdef USE_POWER_PINS
        .vss(VSS), .vdd(VDD), .iovss(IOVSS), .iovdd(IOVDD)
    `endif
    );

    (* keep *) sg13g2_IOPadIOVdd sg13g2_IOPad_iovdd_e (
    `ifdef USE_POWER_PINS
        .vss(VSS), .vdd(VDD), .iovss(IOVSS), .iovdd(IOVDD)
    `endif
    );
    (* keep *) sg13g2_IOPadIOVss sg13g2_IOPad_iovss_e (
    `ifdef USE_POWER_PINS
        .vss(VSS), .vdd(VDD), .iovss(IOVSS), .iovdd(IOVDD)
    `endif
    );
    (* keep *) sg13g2_IOPadVdd sg13g2_IOPad_vdd_e (
    `ifdef USE_POWER_PINS
        .vss(VSS), .vdd(VDD), .iovss(IOVSS), .iovdd(IOVDD)
    `endif
    );
    (* keep *) sg13g2_IOPadVss sg13g2_IOPad_vss_e (
    `ifdef USE_POWER_PINS
        .vss(VSS), .vdd(VDD), .iovss(IOVSS), .iovdd(IOVDD)
    `endif
    );

    // ========================================================================
    // SOUTH  : clk, rst_n, din[5:0]
    // ========================================================================
    sg13g2_IOPadIn sg13g2_IOPad_io_clk (
        .p2c(clk_i),   .pad(clk_PAD)
    );
    sg13g2_IOPadIn sg13g2_IOPad_io_rst (
        .p2c(rst_n_i), .pad(rst_n_PAD)
    );
    generate
        genvar i;
        for (i = 0; i < 6; i = i + 1) begin : sg13g2_IOPad_din_lo
            sg13g2_IOPadIn sg13g2_IOPad_io_din (
                .p2c(din_i[i]), .pad(din_lo_PAD[i])
            );
        end
    endgenerate

    // ========================================================================
    // WEST   : din[7:6], start, mode
    // ========================================================================
    generate
        for (i = 0; i < 2; i = i + 1) begin : sg13g2_IOPad_din_hi
            sg13g2_IOPadIn sg13g2_IOPad_io_din (
                .p2c(din_i[6 + i]), .pad(din_hi_PAD[i])
            );
        end
    endgenerate
    sg13g2_IOPadIn sg13g2_IOPad_io_start (
        .p2c(start_i), .pad(start_PAD)
    );
    sg13g2_IOPadIn sg13g2_IOPad_io_mode (
        .p2c(mode_i),  .pad(mode_PAD)
    );

    // ========================================================================
    // NORTH  : dout[7:0]
    // ========================================================================
    generate
        for (i = 0; i < 8; i = i + 1) begin : sg13g2_IOPad_dout
            sg13g2_IOPadOut30mA sg13g2_IOPad_io_dout (
                .c2p(dout_o[i]), .pad(dout_PAD[i])
            );
        end
    endgenerate

    // ========================================================================
    // EAST   : done, busy, irq, gpio (bidir)
    // ========================================================================
    sg13g2_IOPadOut30mA sg13g2_IOPad_io_done (
        .c2p(done_o), .pad(done_PAD)
    );
    sg13g2_IOPadOut30mA sg13g2_IOPad_io_busy (
        .c2p(busy_o), .pad(busy_PAD)
    );
    sg13g2_IOPadOut30mA sg13g2_IOPad_io_irq (
        .c2p(irq_o),  .pad(irq_PAD)
    );
    sg13g2_IOPadInOut30mA sg13g2_IOPad_io_gpio (
        .c2p(gpio_out), .c2p_en(gpio_oe), .p2c(gpio_in), .pad(gpio_PAD)
    );

    // ========================================================================
    // CORE
    // ========================================================================
    demo_core core (
        .clk(clk_i),
        .rst_n(rst_n_i),
        .start(start_i),
        .mode(mode_i),
        .din(din_i),
        .dout(dout_o),
        .done(done_o),
        .busy(busy_o),
        .irq(irq_o),
        .gpio_out(gpio_out),
        .gpio_oe(gpio_oe),
        .gpio_in(gpio_in)
    );
endmodule
