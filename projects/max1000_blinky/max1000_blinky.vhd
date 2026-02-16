library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity max1000_blinky is
  generic (
    CLK_HZ : positive := 15_000_000
  );
  port (
    clk_in : in  std_logic;
    leds   : out std_logic_vector(7 downto 0)
  );
end entity max1000_blinky;

architecture rtl of max1000_blinky is
  constant TICK_MAX : natural := CLK_HZ - 1;
  signal tick_cnt   : natural range 0 to TICK_MAX := 0;
  signal sec_cnt    : unsigned(7 downto 0) := (others => '0');
begin
  process (clk_in)
  begin
    if rising_edge(clk_in) then
      if tick_cnt = TICK_MAX then
        tick_cnt <= 0;
        sec_cnt  <= sec_cnt + 1;
      else
        tick_cnt <= tick_cnt + 1;
      end if;
    end if;
  end process;

  leds <= std_logic_vector(sec_cnt);
end architecture rtl;
