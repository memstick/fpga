
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

library utils;
 
entity uart_cpu is
  port (
	
	-- Input clock
	clk_uart      : in std_logic;

    rxd           : in std_logic;

    txd           : out std_logic;

    -- CPU clock. Used for synchronisation.
    clk_cpu       : in std_logic;

    -- Reset (synchronous to CPU)
    reset         : in std_logic;

    -- Request address
    addr		: in std_logic_vector(31 downto 0);

    -- Data (read/write)
    data  	: inout std_logic_vector(31 downto 0);

    -- RW (1=w, 0=r)
    rw			: in std_logic;

    rreq		: in std_logic;

    rack        : out std_logic := '0'

    );
end uart_cpu;

architecture rtl of uart_cpu is

-- Typedefs
type t_tx_uart_state IS (IDLE,TRANSMIT_START,TRANSMIT_DATA,TRANSMIT_STOP);

type t_rx_uart_state IS (IDLE,CAPTURE);
type t_rx_flush_state IS (IDLE,TRANSMIT,SYNC_ACK_H,SYNC_ACK_L);


-- PASTED FROM RX MOD
-- PASTED FROM RX MOD

type t_buffer is array(0 to 3) of std_logic_vector(7 downto 0);

signal rx_bytearr : t_buffer;
signal rx_byte : std_logic_vector(7 downto 0);

signal rx_bidx : integer range 0 to 3 := integer(0);
signal rx_cidx : integer range 0 to 3 := integer(0);

-- Clock multiplier (input clock should be baud * mult)
--constant mult : unsigned(7 downto 0) := to_unsigned(16, 8);

-- State machine
signal rx_state : t_rx_uart_state := IDLE;

signal rx_fstate : t_rx_flush_state := IDLE;

-- Sampling counter
signal rx_smp_cnt : unsigned( 7 downto 0 );

-- Delay counter
signal rx_dly_cnt : unsigned( 15 downto 0 );

-- Bit counter
signal rx_bit_cnt : unsigned( 7 downto 0 );

-- PASTED FROM RX MOD
-- PASTED FROM RX MOD

-- Clock multiplier (input clock should be baud * mult)
-- 12 MHz / 104 ≈ 115200 baud
constant mult : unsigned(7 downto 0) := to_unsigned(104, 8);

-- State machine
signal tx_state : t_tx_uart_state := IDLE;

-- Sampling counter
signal tx_smp_cnt : unsigned( 7 downto 0 );

-- Bit counter
signal tx_bit_cnt : integer range 0 to 31;

-- CPU interface UART receivers
signal u_read       : std_logic_vector(7 downto 0);
signal u_write      : std_logic_vector(7 downto 0);
signal u_wr_busy    : std_logic;
signal u_rd_ready   : std_logic;
signal u_rd_ack     : std_logic;


-- CPU interface
signal c_read       : std_logic_vector(7 downto 0);
signal c_write      : std_logic_vector(7 downto 0);
signal c_wr_busy    : std_logic;
signal c_wr_en      : std_logic;
signal c_rd_ready   : std_logic;
signal c_rd_ack     : std_logic;

signal c_wr_busy_sync  : std_logic;
signal c_rd_ready_sync : std_logic;
signal u_wr_en_sync    : std_logic;

signal u_rd_ack_vec        : std_logic_vector(0 downto 0);
signal c_wr_busy_sync_vec  : std_logic_vector(0 downto 0);
signal u_wr_en_sync_vec    : std_logic_vector(0 downto 0);
signal c_rd_ready_sync_vec : std_logic_vector(0 downto 0);

signal reset_uart_vec  : std_logic_vector(0 downto 0);
signal reset_uart      : std_logic;

signal data_i : std_logic_vector(31 downto 0);
signal data_o : std_logic_vector(31 downto 0);

function make_control_reg(
   rd_valid : in std_logic;
   wr_busy : in std_logic
   ) return std_logic_vector is

   variable ret : std_logic_vector(31 downto 0) := (others => '0');
begin
    ret(0) := wr_busy;
    ret(1) := rd_valid;

    return ret;
end function make_control_reg;

begin
    data <= data_o when rw = '0' else (others => 'Z');
    data_i <= data;

    read_sync : entity utils.cdc_sync
      generic map(
         WIDTH => 8,
         STAGES => 2
      )
    port map(
         clk => clk_cpu,
         din => u_read,
         dout => c_read
    );

    write_sync : entity utils.cdc_sync
      generic map(
         WIDTH => 8,
         STAGES => 2
      )
    port map(
         clk => clk_uart,
         din => c_write,
         dout => u_write
    );

    ack_sync : entity utils.cdc_sync
      generic map(
         WIDTH => 1,
         STAGES => 2
      )
    port map(
         clk => clk_uart,
         din => (0 => c_rd_ack),
         dout => u_rd_ack_vec
    );

    u_wr_busy_sync : entity utils.cdc_sync
      generic map(
         WIDTH => 1,
         STAGES => 2
      )
    port map(
         clk => clk_cpu,
         din => (0 => u_wr_busy),
         dout => c_wr_busy_sync_vec
    );

    u_wr_en_sync_inst : entity utils.cdc_sync
      generic map(
         WIDTH => 1,
         STAGES => 2
      )
    port map(
         clk => clk_uart,
         din => (0 => c_wr_en),
         dout => u_wr_en_sync_vec
    );

    u_rd_ready_sync : entity utils.cdc_sync
      generic map(
         WIDTH => 1,
         STAGES => 2
      )
    port map(
         clk => clk_cpu,
         din => (0 => u_rd_ready),
         dout => c_rd_ready_sync_vec
    );

    reset_uart_sync : entity utils.cdc_sync
      generic map(
         WIDTH => 1,
         STAGES => 2
      )
    port map(
         clk => clk_uart,
         din => (0 => reset),
         dout => reset_uart_vec
    );

    reset_uart <= reset_uart_vec(0);
    u_rd_ack <= u_rd_ack_vec(0);
    c_wr_busy_sync <= c_wr_busy_sync_vec(0);
    u_wr_en_sync <= u_wr_en_sync_vec(0);
    c_rd_ready_sync <= c_rd_ready_sync_vec(0);

process(clk_cpu)

-- CPU variables
variable c_rd_valid : std_logic;
variable c_wr_ready : std_logic;

begin

    if reset = '1' then
        -- Reset CPU state
        rack <= '0';
        c_wr_en <= '0';
        --c_wr_busy <= '0';
        c_rd_ack <= '0';
        data_o <= (others => '0');

    elsif rising_edge(clk_cpu) then
        data_o <= (others => '0');

        c_rd_valid := c_rd_ready_sync and (not c_rd_ack);
        c_wr_ready := (not c_wr_busy_sync) and (not c_wr_en);

        if c_rd_ready_sync = '0' then
            c_rd_ack <= '0';
        end if;

        if c_wr_busy_sync = '1' then
            c_wr_en <= '0';
        end if;

        if rreq = '1' then

            if rw = '1' then

                if    addr(3 downto 0) = "0000" then -- Write control
                elsif addr(3 downto 0) = "0100" then -- Invalid
                elsif addr(3 downto 0) = "1000" then -- Write data

                    if c_wr_ready = '1' then
                        c_write <= data_i(7 downto 0);
                        c_wr_en <= '1';
                    end if;
                else
                    -- Invalid
                end if;

            else

                if addr(3 downto 0) = "0000" then -- Read control

                    data_o <= make_control_reg(c_rd_valid, c_wr_busy_sync);

                elsif addr(3 downto 0) = "0100" then -- Read data

                    data_o <= x"000000" & c_read;

                    if c_rd_ready_sync = '1' then
                        c_rd_ack <= '1';
                    end if;

                elsif addr(3 downto 0) = "1000" then -- Invalid
                else
                    -- Invalid
                end if;

                rack <= '1';

            end if;

        end if;
    end if;

end process;

-- TX process
process(clk_uart)

begin

if rising_edge(clk_uart) then

    if reset_uart = '1' then
        tx_state   <= IDLE;
        tx_smp_cnt <= (others => '0');
        tx_bit_cnt <= 0;
        u_wr_busy  <= '0';
        txd        <= '1';
    else

	case tx_state is
	
		when IDLE =>

		    u_wr_busy <= '0';

			if u_wr_en_sync = '1' then

			    u_wr_busy <= '1';
				
				-- Drive tx low to signal not idle
				txd <= '0';

				-- Txd should be driven low for mult cycles = one baud
				tx_smp_cnt <= mult - 1;
				
				-- The current bit to send
				tx_bit_cnt <= 0;
				
				tx_state <= TRANSMIT_START;
			end if;

		when TRANSMIT_START =>
		
			if tx_smp_cnt = 0 then
			
				txd <= u_write(tx_bit_cnt);
				
				tx_bit_cnt <= tx_bit_cnt + 1;
				
				tx_smp_cnt <= mult - 1;
				
				tx_state <= TRANSMIT_DATA;
				
			else
			
				tx_smp_cnt <= tx_smp_cnt - 1;
				
			end if;
			
		when TRANSMIT_DATA =>
						
				if (tx_bit_cnt = 8) and (tx_smp_cnt = 0) then
				
					txd <= '1';
					tx_smp_cnt <= mult - 1;
					tx_state <= TRANSMIT_STOP;
					
				elsif tx_smp_cnt = 0 then
										
					txd <= u_write(tx_bit_cnt);
					--txd <= '0';
					
					tx_bit_cnt <= tx_bit_cnt + 1;
					
					tx_smp_cnt <= mult - 1;
			
				else
				
					tx_smp_cnt <= tx_smp_cnt - 1;
					
				end if;
				
				
		when TRANSMIT_STOP =>
		
			if tx_smp_cnt = 0 then
				tx_state <= IDLE;				
			else
			
				tx_smp_cnt <= tx_smp_cnt - 1;
				
			end if;
	
	end case;
    end if;

end if;

end process;

-- RX process
process(clk_uart)

begin

if rising_edge(clk_uart) then

    if reset_uart = '1' then
        rx_state   <= IDLE;
        rx_smp_cnt <= (others => '0');
        rx_bit_cnt <= (others => '0');
        u_rd_ready <= '0';
        rx_bidx    <= 0;
        rx_cidx    <= 0;
    else

    if u_rd_ack = '1' then
        u_rd_ready <= '0';
    end if;

	case rx_state is
	
		when IDLE =>
		
			if rxd = '0' then

				-- Sample in the middle of the next pulse (div/2);
				-- -> minus one because it takes one cycle before we're in CAPTURE state
				rx_smp_cnt <= mult + (mult / 2) - 1;
				
				-- The number of bits to sample 
				rx_bit_cnt <= to_unsigned(0, rx_bit_cnt'length);
				
				rx_state <= CAPTURE;
				
			end if;
			
		when CAPTURE =>
		
				-- bit_cnt:
				--  0-7: bit 0-7 of the received byte
				--  8-9: stop bits that should always be high
				
				if (rx_bit_cnt > 9) and (rxd = '1') then
					
					-- We're done, so wait signal not clear to send
					-- and be BUSY until CPU has read the char
					rx_state <= IDLE;

					-- Signal the received character to CPU i/f
					u_rd_ready <= '1';
					u_read <= rx_byte;
					
					if rx_bidx = 3 then
						rx_bidx <= 0;
					else
						rx_bidx <= rx_bidx + 1;
					end if;
					
				elsif rx_smp_cnt = 0 then
					
					-- Sample the bit until we get to the stop bits,
					-- which are ignored but still counted. We cannot
					-- risk having rxd LOW when we go back to IDLE if
					-- we're actually having a LOW last bit of the byte.
					if rx_bit_cnt < 8 then
						
						rx_byte(to_integer(rx_bit_cnt)) <= rxd;
						
					elsif rx_bit_cnt = 8 then
					
					end if;
					
					-- We sampled a bit, be it stop or data, so increase
					-- the bit_cnt and reset the smp_cnt.
					rx_bit_cnt <= rx_bit_cnt + 1;
					rx_smp_cnt <= (mult - 1);
			
				else
				
					-- Once the sampling counter reaches 0, we sample the bit.
					rx_smp_cnt <= rx_smp_cnt - 1;
				end if;
	end case;
    end if;

end if;

end process;


end rtl;
