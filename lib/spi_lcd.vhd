library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;
 
entity spi_lcd is
  port (
	
	 clk_200k   : in std_logic;
	 
	 acc			: in std_logic_vector(12 downto 0);
	 mdr			: in std_logic_vector(12 downto 0);
	 mar			: in std_logic_vector(7 downto 0);
	 pc			: in std_logic_vector(7 downto 0);
	 ir			: in std_logic_vector(3 downto 0);
	 ar			: in std_logic_vector(7 downto 0);
	 pipe     	: in std_logic_vector(23 downto 0);
	 
	 spi_data	: out std_logic := '0';
	 spi_clk    : out std_logic := '1';
	 spi_rst    : out std_logic := '0';
	 spi_rs     : out std_logic := '0'
	 
    );
end spi_lcd;

architecture rtl of spi_lcd is

--type t_lcd_state is (INIT,RESET,RESET_DELAY,INIT,SENDING,CHARWRITE,DELAY,TEMP);
type t_lcd_state is (RESET,INIT,DRAW,HALT);
type t_op_state is (TRANSMIT,DELAY);

type t_ram is array (0 to 79) of std_logic_vector(7 downto 0);
type t_ini is array (0 to 8) of std_logic_vector(7 downto 0);

signal state : t_lcd_state := RESET;
signal op    : t_op_state := DELAY;

signal ddram : t_ram := (others => (others => '0'));
signal init_cmd : t_ini := (others => (others => '0'));

-- XRESET needs 100 µs according to datasheet
-- This is 20 cycles at 200kHz
-- Let's give it 1ms which is 200 cycles
signal counter : unsigned(15 downto 0) := x"00c8";

signal index : integer range 0 to 79 := 0;

signal tosend : integer range 0 to 7 := 7;

constant ascii_num_off : unsigned(7 downto 0) := to_unsigned(48, 8);

begin

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

process(clk_200k)

variable test : unsigned(7 downto 0);

begin

if rising_edge(clk_200k) then

	case state is

		when RESET =>
		
			spi_rst <= '0';
			
			init_cmd(0) <= x"39";
			init_cmd(1) <= x"15";
			init_cmd(2) <= x"55";
			init_cmd(3) <= x"6e";
			init_cmd(4) <= x"72";
			init_cmd(5) <= x"38";
			init_cmd(6) <= x"0f";
			init_cmd(7) <= x"01";
			init_cmd(8) <= x"06";
			
			
			-- 0123456789ABCDEF
			-- AC +999 PC 99 DE
			-- IR AR MAR MDR  
			--  4 99 99 +999  
			
			ddram(0) <= x"41"; -- A
			ddram(1) <= x"43"; -- C
			ddram(2) <= x"20";
			ddram(3) <= x"00";
			ddram(4) <= x"00";
			ddram(5) <= x"00";
			ddram(6) <= x"00";
			ddram(7) <= x"20";
			ddram(8) <= x"50"; -- P
			ddram(9) <= x"43"; -- C
			ddram(10) <= x"20";
			ddram(11) <= x"00";
			ddram(12) <= x"00";
			ddram(13) <= x"00";
			ddram(14) <= x"00";
			ddram(15) <= x"00";
			
			ddram(16) <= x"49"; -- I
			ddram(17) <= x"52"; -- R
			ddram(18) <= x"20";
			ddram(19) <= x"41"; -- A
			ddram(20) <= x"52"; -- R
			ddram(21) <= x"20";
			ddram(22) <= x"4D"; -- M
			ddram(23) <= x"41"; -- A
			ddram(24) <= x"52"; -- R
			ddram(25) <= x"20";
			ddram(26) <= x"4D"; -- M
			ddram(27) <= x"44"; -- D
			ddram(28) <= x"52"; -- R
			ddram(29) <= x"20";
			ddram(30) <= x"20";
			ddram(31) <= x"20";
			
			ddram(32) <= x"20";
			ddram(33) <= x"20";
			ddram(34) <= x"20";
			ddram(35) <= x"20";
			ddram(36) <= x"20";
			ddram(37) <= x"20";
			ddram(38) <= x"20";
			ddram(39) <= x"20";
			ddram(40) <= x"20";
			ddram(41) <= x"20";
			ddram(42) <= x"20";
			ddram(43) <= x"20";
			ddram(44) <= x"20";
			ddram(45) <= x"20";
			ddram(46) <= x"20";
			ddram(47) <= x"20";
			
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
			
			if acc(12) = '1' then
				ddram(3) <= x"2D";
			else
				ddram(3) <= x"20";
			end if;
			
			--test := resize(unsigned(acc(11 downto 8)), 8) + ascii_num_off;
			ddram(4) <= std_logic_vector(resize(unsigned(acc(11 downto 8)), 8) + ascii_num_off);
			ddram(5) <= std_logic_vector(resize(unsigned(acc(7 downto 4)), 8) + ascii_num_off);
			ddram(6) <= std_logic_vector(resize(unsigned(acc(3 downto 0)), 8) + ascii_num_off);
			
			ddram(11) <= std_logic_vector(resize(unsigned(pc(7 downto 4)), 8) + ascii_num_off);
			ddram(12) <= std_logic_vector(resize(unsigned(pc(3 downto 0)), 8) + ascii_num_off);

			
			-- 0123456789ABCDEF
			-- AC +999 PC 99 DE
			-- IR AR MAR MDR  
			--  4 99 99 +999  
			ddram(33) <= std_logic_vector(resize(unsigned(ir(3 downto 0)), 8) + ascii_num_off);
			
			ddram(35) <= std_logic_vector(resize(unsigned(ar(7 downto 4)), 8) + ascii_num_off);
			ddram(36) <= std_logic_vector(resize(unsigned(ar(3 downto 0)), 8) + ascii_num_off);
			
			ddram(38) <= std_logic_vector(resize(unsigned(mar(7 downto 4)), 8) + ascii_num_off);
			ddram(39) <= std_logic_vector(resize(unsigned(mar(3 downto 0)), 8) + ascii_num_off);
			
			if mdr(12) = '1' then
				ddram(41) <= x"2D";
			else
				ddram(41) <= x"20";
			end if;
			
			--test := resize(unsigned(acc(11 downto 8)), 8) + ascii_num_off;
			ddram(42) <= std_logic_vector(resize(unsigned(mdr(11 downto 8)), 8) + ascii_num_off);
			ddram(43) <= std_logic_vector(resize(unsigned(mdr(7 downto 4)), 8) + ascii_num_off);
			ddram(44) <= std_logic_vector(resize(unsigned(mdr(3 downto 0)), 8) + ascii_num_off);
			
			ddram(15) <= pipe(23 downto 16);
			ddram(31) <= pipe(15 downto 8);
			ddram(47) <= pipe(7 downto 0);
			
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

--spi_clk <= clk;
	
--spi_clk <= clk if state is SENDING else '0';

end process;

end rtl;


