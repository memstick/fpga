library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reset is
  generic (
    DELAY_CYCLES : natural := 16
  );
  port (
    clk      : in  std_logic;
    pll_lock : in  std_logic;
    reset_o  : out std_logic
  );
end entity reset;

architecture rtl of reset is
  function count_width(n : natural) return natural is
    variable r : natural := 0;
    variable v : natural := 1;
  begin
    if n <= 1 then
      return 1;
    end if;
    while v < n loop
      v := v * 2;
      r := r + 1;
    end loop;
    return r;
  end function;

  constant CNT_WIDTH : natural := count_width(DELAY_CYCLES);
  signal cnt : unsigned(CNT_WIDTH - 1 downto 0);
  signal rst_i : std_logic;
begin
  assert DELAY_CYCLES > 0
    report "reset: DELAY_CYCLES must be > 0"
    severity failure;
  -- Asynchronous assert (pll_lock low), synchronous deassert after DELAY_CYCLES.
  process (clk, pll_lock)
  begin
    if pll_lock = '0' then
      cnt   <= (others => '0');
      rst_i <= '1';
    elsif rising_edge(clk) then
      if cnt < to_unsigned(DELAY_CYCLES - 1, CNT_WIDTH) then
        cnt   <= cnt + 1;
        rst_i <= '1';
      else
        rst_i <= '0';
      end if;
    end if;
  end process;

  reset_o <= rst_i;
end architecture rtl;
