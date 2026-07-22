// SPDX-License-Identifier: Apache-2.0
//
// demo_core -- minimal placeholder core for the pad-ring-ihp padring demo.
//
// This is intentionally trivial: the point of this project is to exercise the
// LibreLane pad-ring generation for the IHP SG13G2 process, not to implement a
// real design. Replace this module with your actual core RTL (or swap it for
// a hardened macro via MACROS/EXTRA_LEFS) when it is available. The chip-top
// (chip_top.v) only cares about this port list.

module demo_core (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,
    input  wire       mode,
    input  wire [7:0] din,
    output reg  [7:0] dout,
    output reg        done,
    output wire       busy,
    output wire       irq,
    // Bidirectional GPIO, decomposed for the InOut pad:
    output wire       gpio_out, // core -> pad data
    output wire       gpio_oe,  // core -> pad output enable
    input  wire       gpio_in   // pad -> core data
);
    reg [7:0] acc;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc  <= 8'h00;
            dout <= 8'h00;
            done <= 1'b0;
        end else begin
            acc  <= mode ? (acc + din) : din;
            dout <= acc;
            done <= start;
        end
    end

    assign busy     = |acc;
    assign irq      = (done & mode) ^ gpio_in; // uses gpio_in so it is not optimized away
    assign gpio_out = acc[0];
    assign gpio_oe  = mode;
endmodule
