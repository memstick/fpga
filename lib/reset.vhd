library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;
 
entity reset is
	port (
	
		clk      : in std_logic;
	
		pll_lock : in std_logic;

		reset    : out std_logic := '1'

	);
end reset;

architecture rtl of reset is

signal flop0 : std_logic := '1';
signal flop1 : std_logic := '1';
signal flop2 : std_logic := '1';
signal flop3 : std_logic := '1';
signal flop4 : std_logic := '1';
signal flop5 : std_logic := '1';
signal flop6 : std_logic := '1';
signal flop7 : std_logic := '1';

begin

process(pll_lock)
begin

if rising_edge(pll_lock) then

	flop0 <= '0';
end if;

end process;

process(clk)
begin

if rising_edge(clk) then

	flop1 <= flop0;
	flop2 <= flop1;
	flop3 <= flop2;
	flop4 <= flop3;
	flop5 <= flop4;
	flop6 <= flop5;
	flop7 <= flop6;
	reset <= flop7;

end if;

end process;

end rtl;


