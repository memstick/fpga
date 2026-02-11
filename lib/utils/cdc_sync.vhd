library ieee;
use ieee.std_logic_1164.all;

entity cdc_sync is
  generic (
    WIDTH  : positive := 1;
    STAGES : positive := 2
  );
  port (
    clk  : in  std_logic;
    din  : in  std_logic_vector(WIDTH - 1 downto 0);
    dout : out std_logic_vector(WIDTH - 1 downto 0)
  );
end entity cdc_sync;

architecture rtl of cdc_sync is
  type sync_array_t is array (natural range <>) of std_logic_vector(WIDTH - 1 downto 0);
  signal sync_ff : sync_array_t(0 to STAGES - 1) := (others => (others => '0'));
begin
  process (clk)
  begin
    if rising_edge(clk) then
      sync_ff(0) <= din;
      for i in 1 to STAGES - 1 loop
        sync_ff(i) <= sync_ff(i - 1);
      end loop;
    end if;
  end process;

  dout <= sync_ff(STAGES - 1);
end architecture rtl;
