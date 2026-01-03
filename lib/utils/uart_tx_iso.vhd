library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;
 
entity uart_tx_iso is
  port (
	
	 clk_uart	: in std_logic;
	 clk_cpu 	: in std_logic;
	 
	 int_u   	: in std_logic;
	 ready_c    : in std_logic;
	 ack_c  		: in std_logic;
	 data_u    	: out std_logic_vector(7 downto 0);
	 
	 int_c     	: out std_logic;
	 ready_u    : out std_logic;
	 ack_u     	: out std_logic;
	 data_c     : in std_logic_vector(7 downto 0)
	 
    );
end uart_tx_iso;

architecture rtl of uart_tx_iso is

signal int_0 : std_logic := '0';
signal int_1 : std_logic := '0';

signal ack_0 : std_logic := '0';
signal ack_1 : std_logic := '0';

signal ready_0 : std_logic := '0';
signal ready_1 : std_logic := '0';

signal data_0 : std_logic_vector(7 downto 0);
signal data_1 : std_logic_vector(7 downto 0);

begin

process(clk_uart)

begin

	if rising_edge(clk_uart) then

		ack_0 <= ack_c;
		ack_1 <= ack_0;
		ack_u <= ack_1;
		
		ready_0 <= ready_c;
		ready_1 <= ready_0;
		ready_u <= ready_1;
		
		data_0 <= data_c;
		data_1 <= data_0;
		data_u <= data_1;

	end if;

end process;

process(clk_cpu)

begin

	if rising_edge(clk_cpu) then

		int_0 <= int_u;
		int_1 <= int_0;
		
		int_c <= int_1;

	end if;

end process;

end rtl;


