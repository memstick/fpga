library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

library types;
use types.generic_types.ALL;

entity crossbar is
  generic (
    g_num_ports : positive := 4
  );
  port (
	
		clk	     : in std_logic;
		
		reset      : in std_logic;
		
		-- Port match constants
		port_match   : in port_match(g_num_ports-1 downto 0);

		-- Requestor interface
		addr_m		 : in 		std_logic_vector(31 downto 0);
		data_m       : inout 	std_logic_vector(31 downto 0);
		rreq_m       : in 		std_logic;
		rw_m			 : in       std_logic;
		rack_m       : out 		std_logic := '0';

      addr_s       : out addr_out(g_num_ports-1 downto 0);
		data_s       : inout data_out(g_num_ports-1 downto 0);
		rreq_s       : out rreq_out(g_num_ports-1 downto 0);
		rw_s         : out rw_out(  g_num_ports-1 downto 0);
		rack_s       : in rack_out(g_num_ports-1 downto 0);

		debug      	: out     std_logic_vector(7 downto 0)
		
 
    );
end crossbar;

architecture rtl of crossbar is

signal data_i : std_logic_vector(31 downto 0);
signal data_o : std_logic_vector(31 downto 0);

signal pdata_i : data_out(g_num_ports-1 downto 0);
signal pdata_o : data_out(g_num_ports-1 downto 0);

signal sel_valid : std_logic;
signal sel_idx : natural range 0 to g_num_ports-1;

begin

	data_m <= data_o when (rw_m = '0') else (others => 'Z');
	data_i <= data_m;
	
	gen_tri : for i in 0 to g_num_ports-1 generate
		data_s(i) <= pdata_o(i) when (rw_m = '1' and sel_valid = '1' and sel_idx = i) else (others => 'Z');
		pdata_i(i) <= data_s(i); -- simple wire
	end generate;
	
	process(all) begin
	
		sel_valid <= '0';
		sel_idx   <= 0;
		
		for i in 0 to g_num_ports-1 loop
			if addr_m(31 downto 28) = port_match(i) then
				sel_valid <= '1';
				sel_idx   <= i; -- last match wins; or add priority
			end if;
		end loop;
	end process;

	process(clk,reset) begin
	
--		sel_valid <= '0';
--		sel_idx   <= 0;
	
--		for i in 0 to g_num_ports-1 loop
--		
--			if rw_m = '1' then
--				data_s(i) <= pdata_o(i);
--			else
--				data_s(i) <= (others => 'Z');
--			end if;
--			--data_s(i) <= pdata_o(i) when (rw_m = '1') else (others => 'Z');
--			pdata_i(i) <= data_s(i);
--			
--		end loop;
		
		if reset = '1' then

			rack_m <= '0';
		
			for i in 0 to g_num_ports-1 loop

				rreq_s(i) <= '0';
				rw_s(i)   <= '0';
				addr_s(i) <= (others => '0');
			end loop;
				
		elsif rising_edge(clk) then
		
			rack_m <= '0';
			data_o <= (others => '0');
		
			for i in 0 to g_num_ports-1 loop
			
				rreq_s(i)  <= '0';
				rw_s(i)    <= '0';
				addr_s(i)  <= (others => '0');
				pdata_o(i) <= (others => '0');
		
				if (sel_valid = '1') and (sel_idx = i) then
						
					rreq_s(i)   <= rreq_m;
					rw_s(i)     <= rw_m;
					rack_m      <= rack_s(i);
					addr_s(i)   <= addr_m;

					if rw_m = '0' then
						data_o <= pdata_i(i);
					else
						pdata_o(i) <= data_i;
					end if;
				end if;
				
			end loop;
		end if;

	end process;

end rtl;


