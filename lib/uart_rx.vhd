library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;
 
entity uart_rx is
  port (
	
	 -- Input clock
	 clk		   : in std_logic;
	 
	 -- RTS for hardware flow control
	 rts			: in std_logic;
	 
	 -- RXD and TXD
    rxd        : in std_logic;
	 
	 -- CTS for hardware flow control
	 cts		   : out std_logic := '1'; -- 1 IS DONT SEND
	 
	 -- Asserted when data is available by the FIFO.
	 int		   : out std_logic := '0';
	 
	 -- Asserted by reader when data has been read.
	 ack			: in std_logic;
	 
	 -- Received data (one byte)
	 data		   : out std_logic_vector(7 downto 0) := (others => '0');
	 
	 debug		   : out std_logic_vector(7 downto 0) := (others => '0')
	 
    );
end uart_rx;

architecture rtl of uart_rx is

-- Typedefs
type t_uart_state IS (IDLE,CAPTURE);
type t_flush_state IS (IDLE,TRANSMIT,SYNC_ACK_H,SYNC_ACK_L);

type t_buffer is array(0 to 3) of std_logic_vector(7 downto 0);

signal bytearr : t_buffer;

signal bidx : integer range 0 to 3 := integer(0);
signal cidx : integer range 0 to 3 := integer(0);

-- Clock multiplier (input clock should be baud * mult)
constant mult : unsigned(7 downto 0) := to_unsigned(16, 8);

-- State machine
signal state : t_uart_state := IDLE;

signal fstate : t_flush_state := IDLE;

-- Sampling counter
signal smp_cnt : unsigned( 7 downto 0 );

-- Delay counter
signal dly_cnt : unsigned( 15 downto 0 );

-- Bit counter
signal bit_cnt : unsigned( 7 downto 0 );

-- Byte that was read
--signal byte : std_logic_vector( 7 downto 0 ) := (others => '0');

begin

--process(clk)

--begin

--if rising_edge(clk) then

	
	
--end if;

--end process;

process(clk)

begin

if rising_edge(clk) then

	case fstate is
	
		when IDLE =>
		
			if bidx /= cidx then
				fstate <= SYNC_ACK_H;
				
				data <= bytearr(cidx);
				int <= '1';
			end if;
		
		when TRANSMIT =>
	
		when SYNC_ACK_H =>
		
			if ack = '1' then
				fstate <= SYNC_ACK_L;
			end if;
		
		when SYNC_ACK_L =>
		
			int <= '0';
	
			if ack = '0' then
			
				if cidx = 3 then
					cidx <= 0;
				else
					cidx <= cidx + 1;
				end if;
				
				fstate <= IDLE;
				
			else
				
			end if;

	end case;

	case state is
	
		when IDLE =>
		
			if rxd = '0' then

				-- Sample in the middle of the next pulse (div/2);
				-- -> minus one because it takes one cycle before we're in CAPTURE state
				smp_cnt <= mult + (mult / 2) - 1;
				
				-- The number of bits to sample 
				bit_cnt <= to_unsigned(0, bit_cnt'length);
				
				state <= CAPTURE;
				
			end if;
			
		when CAPTURE =>
		
				-- bit_cnt:
				--  0-7: bit 0-7 of the received byte
				--  8-9: stop bits that should always be high
				
				if (bit_cnt > 9) and (rxd = '1') then
					
					-- We're done, so wait signal not clear to send
					-- and be BUSY until CPU has read the char
					state <= IDLE;
					
					if bidx = 3 then
						bidx <= 0;
					else
						bidx <= bidx + 1;
					end if;
					
				elsif smp_cnt = 0 then
					
					-- Sample the bit until we get to the stop bits,
					-- which are ignored but still counted. We cannot
					-- risk having rxd LOW when we go back to IDLE if
					-- we're actually having a LOW last bit of the byte.
					if bit_cnt < 8 then
						
						bytearr(bidx)(to_integer(bit_cnt)) <= rxd;
						
					elsif bit_cnt = 8 then
					
					end if;
					
					-- We sampled a bit, be it stop or data, so increase
					-- the bit_cnt and reset the smp_cnt.
					bit_cnt <= bit_cnt + 1;
					smp_cnt <= (mult - 1);
			
				else
				
					-- Once the sampling counter reaches 0, we sample the bit.
					smp_cnt <= smp_cnt - 1;
				end if;
	end case;
	
	if (state = CAPTURE) or (bidx /= cidx) then
		cts <= '1';
	else
		cts <= '0';
	end if;

end if;

end process;

end rtl;