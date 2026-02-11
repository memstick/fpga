library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

library utils;

entity reset_tb is
end entity reset_tb;

architecture tb of reset_tb is
  constant CLK_PERIOD   : time := 20 ns;
  constant DELAY_CYCLES : natural := 4;

  signal clk      : std_logic := '0';
  signal pll_lock : std_logic := '0';
  signal reset    : std_logic;
begin
  -- Clock generator
  clk <= not clk after CLK_PERIOD / 2;

  -- DUT
  u_dut : entity utils.reset
    generic map (
      DELAY_CYCLES => DELAY_CYCLES
    )
    port map (
      clk      => clk,
      pll_lock => pll_lock,
      reset_o  => reset
    );

  -- Stimulus and checks
  process
    variable cycles : natural := 0;
  begin
    -- Hold PLL unlocked for a few cycles.
    wait for 3 * CLK_PERIOD;
    assert reset = '1'
      report "reset should be asserted while pll_lock=0"
      severity failure;

    -- Lock PLL and start counting cycles.
    pll_lock <= '1';

    -- Expect reset to stay asserted for DELAY_CYCLES clocks.
    cycles := 0;
    while cycles < DELAY_CYCLES loop
      wait until rising_edge(clk);
      assert reset = '1'
        report "reset deasserted too early"
        severity failure;
      cycles := cycles + 1;
    end loop;

    -- Next rising edge should deassert reset.
    wait until rising_edge(clk);
    assert reset = '0'
      report "reset did not deassert after DELAY_CYCLES"
      severity failure;

    -- Relock test: drop pll_lock and ensure reset asserts again.
    pll_lock <= '0';
    wait until rising_edge(clk);
    assert reset = '1'
      report "reset did not reassert when pll_lock dropped"
      severity failure;

    report "reset_tb passed" severity note;
    stop;
  end process;
end architecture tb;
