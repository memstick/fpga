library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;
 
entity spi_lcd is
  port (
	
		clk_200k   : in std_logic;
		
		reset      : in std_logic;

		addr		  : in std_logic_vector(31 downto 0);
		data  	  : in std_logic_vector(31 downto 0);
		rw			  : in std_logic;
		rreq		  : in std_logic;
		
		clk  		  : in std_logic;

		spi_data	: out std_logic := '0';
		spi_clk    : out std_logic := '1';
		spi_rst    : out std_logic := '0';
		spi_rs     : out std_logic := '0';
		
		rack       : out std_logic := '0';
		
		debug      : out std_logic_vector(7 downto 0)
 
    );
end spi_lcd;

architecture rtl of spi_lcd is

--type t_lcd_state is (INIT,RESET,RESET_DELAY,INIT,SENDING,CHARWRITE,DELAY,TEMP);
type t_lcd_state is (RST,INIT,DRAW,HALT);
type t_op_state is (TRANSMIT,DELAY);
type t_ram_state is (RAM_INIT,RAM_DONE);

type t_ram is array (0 to 79) of std_logic_vector(7 downto 0);
type t_ini is array (0 to 8) of std_logic_vector(7 downto 0);

signal state : t_lcd_state := RST;
signal op    : t_op_state := DELAY;
signal rstate : t_ram_state := RAM_INIT;

signal ddram : t_ram := (others => (others => '0'));
signal init_cmd : t_ini := (others => (others => '0'));

-- XRESET needs 100 µs according to datasheet
-- This is 20 cycles at 200kHz
-- Let's give it 1ms which is 200 cycles
signal counter : unsigned(15 downto 0) := x"00c8";

signal index : integer range 0 to 79 := 0;

signal tosend : integer range 0 to 7 := 7;

--signal test : unsigned(7 downto 0) := to_unsigned(1, 8);
signal test : integer range 0 to 7 := 0;

constant ascii_num_off : unsigned(7 downto 0) := to_unsigned(48, 8);

begin

process(reset,clk)
begin

if falling_edge(clk) then

	if reset = '1' then
		rstate <= RAM_INIT;
		rack <= '0';
		debug <= (others => '0');
		ddram(0) <= x"48";
		test <= 0;
	else
	
		case rstate is

			when RAM_INIT =>
				
				if rreq = '1' then
					
					ddram( to_integer(unsigned(addr(5 downto 0))) ) <= data(7 downto 0);
					--debug <= std_logic_vector(test);
					
					debug(test) <= '1';
					test <= test + 1;
					
					rstate <= RAM_DONE;
					rack <= '1';
					
				end if;
			
			when RAM_DONE =>
			
				if rreq = '0' then
					rack <= '0';
					rstate <= RAM_INIT;
				end if;
		
		end case;
	
	end if;

end if;

end process;

process(clk_200k)

begin

if falling_edge(clk_200k) then

case op is
	when TRANSMIT =>
		case state is
			when INIT =>
				spi_data <= init_cmd(index)(tosend);
			when DRAW =>
				spi_data <= ddram(index)(tosend);
			when others =>
		end case;
	when others =>
end case;

end if;

end process;

process(reset,clk_200k)

variable test : unsigned(7 downto 0);

begin

if reset = '1' then

	init_cmd(0) <= x"39";
	init_cmd(1) <= x"15";
	init_cmd(2) <= x"55";
	init_cmd(3) <= x"6e";
	init_cmd(4) <= x"72";
	init_cmd(5) <= x"38";
	init_cmd(6) <= x"0f";
	init_cmd(7) <= x"01";
	init_cmd(8) <= x"06";

	spi_rst <= '0';

	state <= RST;

elsif rising_edge(clk_200k) then

	case state is

		when RST =>
		
			spi_rst <= '0';
			
			if counter = to_unsigned(0, counter'length) then
				counter <= x"2710";
				
				state <= INIT;
				op <= DELAY;
				
				spi_rst <= '1';
				
				index <= 0;
				tosend <= 7;
			else
				counter <= counter - to_unsigned(1, counter'length);
			end if;
			
		when INIT =>
		
			spi_rs <= '0';

			case op is

				when TRANSMIT =>
				
					if (tosend = 0) and (index = init_cmd'length) then
						
						state <= DRAW;
						op <= DELAY;
						tosend <= 7;
						
						index <= 0;
						
						counter <= x"0004"; -- Write ram needs 18.5 µs at 540 kHZ oscillator
						
					elsif tosend = 0 then
					
						op <= DELAY;
						tosend <= 7;
						
						index <= index + 1;
						
						counter <= x"00c8";
						
					else
						tosend <= tosend - 1;
					end if;

				when DELAY =>
				
					if counter = to_unsigned(0, counter'length) then
						op <= TRANSMIT;
					else
						counter <= counter - to_unsigned(1, counter'length);
					end if;

			end case;

		when DRAW =>
		
			spi_rs <= '1';
			
			case op is

				when TRANSMIT =>
				
					if (tosend = 0) and (index = 47) then--ddram'length) then
						
						--state <= HALT;
						--op <= DELAY;
						
						op <= DELAY;
						tosend <= 7;
						
						index <= 0;
						
						counter <= x"0004";
						
					elsif tosend = 0 then
					
						op <= DELAY;
						tosend <= 7;
						
						index <= index + 1;
						
						counter <= x"0004";
						
					else
						tosend <= tosend - 1;
					end if;

				when DELAY =>
				
					if counter = to_unsigned(0, counter'length) then
						op <= TRANSMIT;
					else
						counter <= counter - to_unsigned(1, counter'length);
					end if;

			end case;

		when others =>
	end case;

end if;

case op is
	when TRANSMIT =>
		spi_clk <= clk_200k;
	when others =>
		spi_clk <= '1';
end case;

end process;

end rtl;


