library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;
 
entity uart_tx is
  port (
	
	 -- Input clock
	 clk		   : in std_logic;
	 
	 -- RXD and TXD
	 txd			: out std_logic := '1';
	 
	 -- Asserted when data has been transmitted
	 int		   : out std_logic := '0';
	 
	 ack			: in std_logic;
	 
	 -- When asserted (pulsed), core starts transmit
	 ready      : in std_logic;
	 
	 -- Data to transmit (one byte)
	 data		   : in std_logic_vector(7 downto 0) := (others => '0')
	 
    );
end uart_tx;

architecture rtl of uart_tx is

-- Typedefs
type t_uart_state IS (IDLE,TRANSMIT_START,TRANSMIT_DATA,TRANSMIT_STOP, SYNC_ACK_H, SYNC_ACK_L);

-- Clock multiplier (input clock should be baud * mult)
constant mult : unsigned(7 downto 0) := to_unsigned(16, 8);

-- State machine
signal state : t_uart_state := IDLE;

-- Sampling counter
signal smp_cnt : unsigned( 7 downto 0 );

-- Bit counter
signal bit_cnt : unsigned( 7 downto 0 );

signal byte : std_logic_vector( 7 downto 0 ) := "01010101";

begin

process(clk)

begin

if rising_edge(clk) then

	case state is
	
		when IDLE =>
		
			-- Drive int low
			int <= '0';

			if ready = '1' then
				
				-- Drive tx low to signal not idle
				txd <= '0';

				-- Txd should be driven low for mult cycles = one baud
				smp_cnt <= mult - 1;
				
				-- The current bit to send
				bit_cnt <= to_unsigned(0, 8);
				
				state <= TRANSMIT_START;
			end if;

		when TRANSMIT_START =>
		
			if smp_cnt = 0 then
			
				txd <= byte(to_integer(bit_cnt));
				
				bit_cnt <= bit_cnt + 1;
				
				smp_cnt <= mult - 1;
				
				state <= TRANSMIT_DATA;
				
			else
			
				smp_cnt <= smp_cnt - 1;
				
			end if;
			
		when TRANSMIT_DATA =>
						
				if (bit_cnt = 8) and (smp_cnt = 0) then
				
					txd <= '1';
					smp_cnt <= mult - 1;
					state <= TRANSMIT_STOP;
					
				elsif smp_cnt = 0 then
										
					txd <= byte(to_integer(bit_cnt));
					--txd <= '0';
					
					bit_cnt <= bit_cnt + 1;
					
					smp_cnt <= mult - 1;
			
				else
				
					smp_cnt <= smp_cnt - 1;
					
				end if;
				
				
		when TRANSMIT_STOP =>
		
			if smp_cnt = 0 then
				state <= SYNC_ACK_H;				
			else
			
				smp_cnt <= smp_cnt - 1;
				
			end if;
			
		when SYNC_ACK_H =>
			
			int <= '1';
			if ack = '1' then
				state <= SYNC_ACK_L;
			end if;
		
		when SYNC_ACK_L =>
			int <= '0';
			if ack = '0' then
				state <= IDLE;
			end if;
	
	end case;

end if;

byte <= data;

end process;

end rtl;