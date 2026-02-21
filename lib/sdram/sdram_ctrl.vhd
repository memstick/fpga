library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity sdram_ctrl is
  port (
	
		-- Input clock
		clki		   : in std_logic;
		
		-- Request address
		addr			: in std_logic_vector(31 downto 0);
		
		-- Data (read/write)
		data  		: inout std_logic_vector(31 downto 0);
		
		-- RW (1=w, 0=r)
		rw				: in std_logic;
		
		rreq			: in std_logic;
		
		reset 		: in std_logic;
	 
		A				: out std_logic_vector(13 downto 0) := (others => '0');
		
		BA				: out std_logic_vector(1 downto 0) := (others => '0');
		
		CLK   		: out std_logic := '0';
		
		-- Recommended to set "high" during initial 200 µs init delay
		CKE   		: out std_logic := '1';
		
		-- Must be high during initial 200 µs delay (NOP)
		RAS   		: out std_logic := '1';
		
		-- Must be high during initial 200 µs delay (NOP)
		CAS   		: out std_logic := '1';
		
		-- Must be high during initial 200 µs delay (NOP)
		WE    		: out std_logic := '1';
		
		-- Must be low during initial 200 µs delay (NOP)
		CS    		: out std_logic := '0';
		
		DQ				: inout std_logic_vector(15 downto 0);
		
		-- Recommended to set "high" during initial 200 µs init delay
		DQM			: out std_logic_vector(1 downto 0) := (others => '1');
		
		rack        : out std_logic := '0';
		
		debug         : out std_logic_vector(7 downto 0) := (others => '0')
	 
    );
end sdram_ctrl;

architecture rtl of sdram_ctrl is

-- Typedefs
type t_ini_state IS (PAUSE,PRECHARGE_ALL,AUTO_REFRESH,IDLE,WRITE_MR);
type t_ctrl_state IS (BOOT,IDLE,REFRESH,RD,WR,DONE);
type t_read_state IS (INIT,BANK_ACTIVE,WAIT_READ,DO_READ);
type t_write_state IS (INIT,BANK_ACTIVE,DO_WRITE);

signal state  : t_ctrl_state;
signal istate : t_ini_state;
signal rstate : t_read_state;
signal wstate : t_write_state;

signal delay : unsigned(15 downto 0);
signal refresh_cnt : unsigned(15 downto 0);
signal refresh_pending : std_logic;
signal refresh_req : std_logic;

constant REFRESH_CYCLES : unsigned(15 downto 0) := to_unsigned(391, 16); -- 7.8125us at 50 MHz
constant RFC_CYCLES : unsigned(15 downto 0) := to_unsigned(3, 16); -- >=60ns at 50 MHz

-- Addressing
signal bank : std_logic_vector(1 downto 0);
signal row  : std_logic_vector(12 downto 0);
signal col  : std_logic_vector(8 downto 0);

-- Tristate registers for data and DQ
signal data_i : std_logic_vector(31 downto 0);
signal data_o : std_logic_vector(31 downto 0);

signal DQ_i : std_logic_vector(15 downto 0);
signal DQ_o : std_logic_vector(15 downto 0);

--signal rreq_sticky : std_logic := '0';
--signal rreq_sticky_clear : std_logic := '0';

begin

-- Tristate the "data" pin
data <= data_o when RW = '0' else (others => 'Z');
data_i <= data;

debug <= data_o(7 downto 0);

-- Tristate DQ bus
DQ <= (others => 'Z') when state = RD else DQ_o;
DQ_i <= DQ;

CLK <= clki when reset = '0' else '0';

--process(rreq,rreq_sticky_clear)

--begin

--if rising_edge(rreq) then

--	rreq_sticky <= '1';
	
--elsif rreq_sticky_clear = '1' then

--	rreq_sticky <= '0';

--end if;

--end process; -- rreq


process(clki,reset)

begin

---- Clock gate dram until start pause
--if istate = IDLE then
--	--CLK <= '0';
--	CLK <= clki;
--else
--	CLK <= clki;
--end if;



if falling_edge(clki) then

	-- Reset
	if reset = '1' then

		state <= BOOT;
		istate <= IDLE;
		rstate <= INIT;
		wstate <= INIT;
		refresh_pending <= '0';

		-- After initial power up; all pins must be in "NOP"
		-- CKE[n-1] must be "1" and after that don't care, so just set CKE to 1

		A <= (others => '0');
		BA <= (others => '0');
		--CLK <= '0';
		CKE <= '1';
		RAS <= '1';
		CAS <= '1';
		WE <= '1';
		CS <= '0';
		DQM <= (others => '1');
		
		--rreq_sticky_clear <= '1';
		rack <= '0';

	else

		case state is
		
			when BOOT =>
				case istate is
				
					when IDLE =>
					
						if delay = 0 then
							istate <= PAUSE;
							delay <= to_unsigned(2400, delay'length);
						else
							delay <= delay - 1;
						end if;
						
					when PAUSE =>
						
						if delay = to_unsigned(0, delay'length) then
							istate <= PRECHARGE_ALL;
							
							CS <= '0';
							RAS <= '0';
							CAS <= '1';
							WE <= '0';
							
							DQM <= (others => '0');
						
							A(10) <= '1'; -- precharge all banks
							
							delay <= to_unsigned(2-1, delay'length); -- 1 cycle tRP; take 2 so that cs can go high one pulse as NOP (Device desel)
						else
							delay <= delay - 1;
						end if;
						
					when PRECHARGE_ALL =>
					
						CS <= '1';
					
						if delay = 0 then
							istate <= AUTO_REFRESH;
							
							CS <= '0';
							RAS <= '0';
							CAS <= '0';
							WE <= '1';
							
							delay <= to_unsigned(8-1+1, delay'length); -- does not depend on frequency; eight cycles before or after MR write. plus one cycle so that AR can do a device desel (NOP) before MR write
						else
							delay <= delay - 1;
						end if;
						
					when AUTO_REFRESH =>
					
						if delay = 1 then
							CS <= '1';
							delay <= delay - 1;
						elsif delay = 0 then
							istate <= WRITE_MR;
							
							CS <= '0';
							RAS <= '0';
							CAS <= '0';
							WE <= '0';
							
							-- A0-A2 Burst length 2 = 32bit per r/w (in seq + interleave)
							-- A3    Interleaved addressing mode
							-- A4-A6 CAS latency 3
							-- A9    Write mode burst read + burst write
							-- Rest is 0 "reserved" bits.
							A <= "00000000111001";
							BA <= "00";
							
							delay <= to_unsigned(2-1, delay'length); -- 2 cycles
							
						else
							delay <= delay - 1;
						end if;
					
					when WRITE_MR =>
					
						CS <= '1';
					
						if delay = 0 then
						
							-- NOP it
							--CS <= '0';
							--RAS <= '1';
							--CAS <= '1';
							--WE <= '1';
							
							-- Device deselect to bring CS high
							CS <= '1';
							
							state <= IDLE;
						else
							delay <= delay - 1;
						end if;
				end case;
				
			when IDLE =>

				if refresh_req = '1' then
					refresh_pending <= '1';
				end if;

				if (refresh_pending = '1') and (rreq = '0') then
					-- AUTO REFRESH command
					CS <= '0';
					RAS <= '0';
					CAS <= '0';
					WE <= '1';
					DQM <= (others => '0');
					delay <= RFC_CYCLES - 1;
					refresh_pending <= '0';
					state <= REFRESH;
				end if;
			
				if rreq = '1' then
				
					if rw = '1' then
						state <= WR;
						wstate <= INIT;
					else
						state <= RD;
						rstate <= INIT;
						
					end if;
					
					-- addr is byte-addressed (CPU is word-aligned); use halfword address for x16 SDRAM
					bank <= addr(24 downto 23);
					row  <= addr(22 downto 10);
					col  <= addr(9 downto 1);
				end if;
				
			when REFRESH =>
				CS <= '1';
				if delay = 0 then
					state <= IDLE;
				else
					delay <= delay - 1;
				end if;

			when WR =>
			
				case wstate is
				
					when INIT =>
					
						-- Bank activate command
						CS <= '0';
						RAS <= '0';
						CAS <= '1';
						WE <= '1';
						
						-- Select bank
						--BA(0) <= '0';
						--BA(1) <= '0';
						BA <= bank;
						
						-- Select row
						--A(11 downto 0) <= (others => '0');
						A(12 downto 0) <= row;
						
						--test
						--DQM <= (others => '1');
						
						wstate <= BANK_ACTIVE;
						
						-- timing diagram specifies three cycles - but also tRCD
						--tRCD -> minimum 15 ns; at 12 MHz the clock period is 83 ns so just one is okay.
						
						delay <= to_unsigned(3-1, delay'length); 
					
					when BANK_ACTIVE =>
					
						CS <= '1';
						
						if delay = 0 then
							
							-- Write command
							CS <= '0';
							RAS <= '1';
							CAS <= '0';
							WE <= '0'; -- Write is opposite to read with WE bit
							
							-- A(10) is AUTO PRECHARGE
							A(10) <= '1';
							
							-- A(8 -> 0) is column address
							--A(8 downto 0) <= (others => '0');
							A(8 downto 0) <= col;
							A(9) <= '0';
							A(11) <= '0';
							
							wstate <= DO_WRITE;
							
							-- First bits go here
							DQ_o <= data_i(15 downto 0);
							
							delay <= to_unsigned(7-1, delay'length);

						else
							delay <= delay - 1;
						end if;
					
					when DO_WRITE =>
					
						CS <= '1';
					
						if delay = 0 then
							state <= DONE;
							wstate <= INIT;
							--rreq_sticky_clear <= '1';
							rack <= '1';
						else
							DQ_o <= data_i(31 downto 16);
							delay <= delay - 1;
						end if;
			
				end case;
			
			when RD =>
			
				case rstate is
				
					when INIT =>
					
						-- Bank activate command
						CS <= '0';
						RAS <= '0';
						CAS <= '1';
						WE <= '1';
						
						-- Select bank
						--BA(0) <= '0';
						--BA(1) <= '0';
						BA <= bank;
						
						-- Select row
						--A(11 downto 0) <= (others => '0');
						A(12 downto 0) <= row;
						
						--test
						--DQM <= (others => '1');
						
						rstate <= BANK_ACTIVE;
						
						-- timing diagram specifies three cycles - but also tRCD
						--tRCD -> minimum 15 ns; at 12 MHz the clock period is 83 ns so just one is okay.
						
						delay <= to_unsigned(3-1, delay'length); 
					
					when BANK_ACTIVE =>
					
						CS <= '1';
						
						if delay = 0 then
							
							-- Read command
							CS <= '0';
							RAS <= '1';
							CAS <= '0';
							WE <= '1';
							
							-- A(10) is AUTO PRECHARGE
							A(10) <= '1';
							
							-- A(8 -> 0) is column address
							--A(8 downto 0) <= (others => '0');
							A(8 downto 0) <= col;
							A(9) <= '0';
							A(11) <= '0';
							
							rstate <= WAIT_READ;
							
							-- Need to wait CAS cycles - 1
							delay <= to_unsigned(3-1, delay'length);
							
							-- This is actually the minimum time needed before the next command.
							--delay <= (3 - 1);--to_unsigned(0, delay'length); -- tRC OR (tRAS + tRP) : 60 OR (42 + 15) : 60 OR 57: [ns] I guess I need to take the largest delay. So at 12 MHz, period 83 ns is plenty.
						else
							delay <= delay - 1;
						end if;
						
					when WAIT_READ =>
					
						CS <= '1';
						
						if delay = 0 then
							rstate <= DO_READ;
							delay <= to_unsigned(1, delay'length); --(2-1); -- Burst length - 1
						else
							delay <= delay - 1;
						end if;
					
					when DO_READ =>
					
						if delay = 0 then
							
							-- go to idle
							istate <= IDLE;
							state <= DONE;
							--rreq_sticky_clear <= '1';
							rack <= '1';
						
						else
						
							delay <= delay - 1;
						
						end if;
					
				end case;
				
			when DONE =>
			
				if rreq = '0' then
					state <= IDLE;
					rack <= '0';
				end if;
			
			when others =>
			
		end case;
		
	end if;

end if;

end process;

process(clki,reset)
begin
	if reset = '1' then
		refresh_cnt <= (others => '0');
		refresh_req <= '0';
	elsif rising_edge(clki) then
		refresh_req <= '0';
		if refresh_cnt >= (REFRESH_CYCLES - 1) then
			refresh_cnt <= (others => '0');
			refresh_req <= '1';
		else
			refresh_cnt <= refresh_cnt + 1;
		end if;
	end if;
end process;

process(clki)

begin

	if rising_edge(clki) then

		case state is
		
			when RD =>
			
				case rstate is
				
					when DO_READ =>
					
						if delay = 1 then
						
							data_o(15 downto 0) <= DQ_i;
						
						elsif delay = 0 then
					
							data_o(31 downto 16) <= DQ_i;
						
						end if;
					
					when others =>
					
				end case;
			
			when others =>
			
		end case;
		
	end if;

end process;

end rtl;
