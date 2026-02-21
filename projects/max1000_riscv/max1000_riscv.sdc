create_clock -name clk_in -period 83.333 [get_ports {clk_in}]
create_generated_clock -name clk_sys -source [get_ports {clk_in}] -divide_by 6 -multiply_by 25 [get_pins {sys_pll|altpll_component|clk[0]}]
derive_pll_clocks
derive_clock_uncertainty
