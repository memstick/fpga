-- FIXME: this is just stubbed out completely

library ieee;
use ieee.std_logic_1164.all;

entity rom is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    addr  : in  std_logic_vector(31 downto 0);
    rw    : in  std_logic;
    data  : inout std_logic_vector(31 downto 0);
    rreq  : in  std_logic;
    rack  : out std_logic := '0';
    debug : out std_logic_vector(7 downto 0)
  );
end rom;

architecture rtl of rom is
begin
  data  <= (others => 'Z');
  rack  <= '0';
  debug <= (others => '0');
end architecture;
