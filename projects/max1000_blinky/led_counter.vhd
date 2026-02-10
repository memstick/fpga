library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity led_counter is
  generic (
    CLK_HZ : positive := 15_000_000
  );
  port (
    clk    : in  std_logic;
    enable : in  std_logic;
    leds   : out std_logic_vector(7 downto 0)
  );
end entity led_counter;

architecture rtl of led_counter is
  constant TICK_MAX : natural := CLK_HZ - 1;
  signal tick_cnt   : natural range 0 to TICK_MAX := 0;
  signal sec_cnt    : unsigned(7 downto 0) := (others => '0');
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if enable = '1' then
        if tick_cnt = TICK_MAX then
          tick_cnt <= 0;
          sec_cnt  <= sec_cnt + 1;
        else
          tick_cnt <= tick_cnt + 1;
        end if;
      end if;
    end if;
  end process;

  leds <= std_logic_vector(sec_cnt);
end architecture rtl;
