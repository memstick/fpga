library ieee;
use ieee.std_logic_1164.all;

entity max1000_blinky_top is
  port (
    clk_in : in  std_logic;
    leds   : out std_logic_vector(7 downto 0)
  );
end entity max1000_blinky_top;

architecture rtl of max1000_blinky_top is
  signal clk_sys : std_logic;
  signal pll_ok  : std_logic;
  signal pll_ok_sync : std_logic_vector(1 downto 0) := (others => '0');
  signal enable_leds : std_logic;
begin
  u_pll : entity work.pll15m
    port map (
      inclk0 => clk_in,
      c0     => clk_sys,
      locked => pll_ok
    );

  -- Synchronize PLL lock into clk_sys domain to avoid metastability.
  process (clk_sys)
  begin
    if rising_edge(clk_sys) then
      pll_ok_sync <= pll_ok_sync(0) & pll_ok;
    end if;
  end process;

  enable_leds <= pll_ok_sync(1);

  u_leds : entity work.led_counter
    generic map (
      CLK_HZ => 15_000_000
    )
    port map (
      clk    => clk_sys,
      enable => enable_leds,
      leds   => leds
    );
end architecture rtl;
