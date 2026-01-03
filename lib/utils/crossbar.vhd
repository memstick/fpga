library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;
 
entity crossbar is
  port (
	
		clk	     : in std_logic;
		
		reset      : in std_logic;

		-- Requestor interface
		addr		  : in 		std_logic_vector(31 downto 0);
		data       : inout 	std_logic_vector(31 downto 0);
		rreq       : in 		std_logic;
		rw			  : in      std_logic;
		rack       : out 		std_logic := '0';
		
		-- Port0
		a_addr     	: out 		std_logic_vector(31 downto 0);
		a_data		: inout   std_logic_vector(31 downto 0);
		a_rreq		: out 		std_logic;
		a_rw		  	: out     std_logic;
		a_rack		: in 		std_logic;
		
		-- Port1
		b_addr      : out 		std_logic_vector(31 downto 0);
		b_data		: inout   std_logic_vector(31 downto 0);
		b_rreq		: out 		std_logic;
		b_rw		  	: out     std_logic;
		b_rack		: in 		std_logic;
		
		-- Port2
		c_addr      : out 		std_logic_vector(31 downto 0);
		c_data		: inout   std_logic_vector(31 downto 0);
		c_rreq		: out 		std_logic;
		c_rw		  	: out     std_logic;
		c_rack		: in 		std_logic;
		
		debug      	: out     std_logic_vector(7 downto 0)
		
 
    );
end crossbar;

architecture rtl of crossbar is

function porta_match return std_logic_vector is begin return "0000"; end;
function portb_match return std_logic_vector is begin return "1000"; end;
function portc_match return std_logic_vector is begin return "0100"; end;

signal data_i : std_logic_vector(31 downto 0);
signal data_o : std_logic_vector(31 downto 0);

signal a_data_i : std_logic_vector(31 downto 0);
signal a_data_o : std_logic_vector(31 downto 0);

signal b_data_i : std_logic_vector(31 downto 0);
signal b_data_o : std_logic_vector(31 downto 0);

signal c_data_i : std_logic_vector(31 downto 0);
signal c_data_o : std_logic_vector(31 downto 0);

begin

data <= data_o when (rw = '0') else (others => 'Z');
data_i <= data;

a_data <= a_data_o when (rw = '1') else (others => 'Z');
a_data_i <= a_data;

b_data <= b_data_o when (rw = '1') else (others => 'Z');
b_data_i <= b_data;

c_data <= c_data_o when (rw = '1') else (others => 'Z');
c_data_i <= c_data;

--debug <= addr(31 downto 28) & portc_match;

process(clk,reset) begin
	
	if falling_edge(clk) then
	
		if reset = '1' then
			-- Reset
		
			a_rreq <= '0';
			a_rw <= '0';
			a_addr <= (others => '0');
			--a_data <= (others => '0');
			
			b_rreq <= '0';
			b_rw <= '0';
			b_addr <= (others => '0');
			--b_data <= (others => '0');
			
			c_rreq <= '0';
			c_rw <= '0';
			c_addr <= (others => '0');
			--c_data <= (others => '0');
			
			rack <= '0';
			
			debug <= (others => '0');

		else
			case addr(31 downto 28) is
				
				when porta_match =>
				
					a_rreq <= rreq;
					a_rw   <= rw;
					rack   <= a_rack;
					a_addr <= addr;
					if rw = '0' then
						data_o <= a_data_i;
					else
						a_data_o <= data_i;
					end if;
					
				when portb_match =>
				
					b_rreq <= rreq;
					b_rw   <= rw;
					rack   <= b_rack;
					b_addr <= addr;
					if rw = '0' then
						data_o <= b_data_i;
					else
						b_data_o <= data_i;
					end if;
					
					debug(1) <= '1';
					
				when portc_match =>
				
					c_rreq <= rreq;
					c_rw   <= rw;
					rack   <= c_rack;
					c_addr <= addr;
					if rw = '0' then
						data_o <= c_data_i;
					else
						c_data_o <= data_i;
					end if;
					
					--debug(2) <= '1';
					--debug <= c_data_i(7 downto 0);
				
				when others =>
				
					--debug(3) <= '1';
				
	--				c_rreq <= rreq;
	--				c_rw   <= rw;
	--				rack   <= c_rack;
	--				c_addr <= addr;
	--				if rw = '0' then
	--					data_o <= c_data_i;
	--				else
	--					c_data_o <= data_i;
	--				end if;
			
			end case;
		end if;
	end if;
end process;

end rtl;


