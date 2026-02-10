create_clock -name clk_in -period 83.333 [get_ports {clk_in}]
# If you replace pll15m with a real PLL, Quartus can derive the output clocks.
derive_pll_clocks
derive_clock_uncertainty
