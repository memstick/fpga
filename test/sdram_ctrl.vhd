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
		data  		: in std_logic_vector(31 downto 0);
		
		-- RW (1=w, 0=r)
		rw				: in std_logic;
		
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
		
		debug         : out std_logic_vector(7 downto 0) := (others => '0')
	 
    );
end sdram_ctrl;

architecture rtl of sdram_ctrl is

-- Typedefs
type t_ini_state IS (PAUSE,PRECHARGE_ALL,AUTO_REFRESH,IDLE2,WRITE_MR);
type t_ctrl_state IS (BOOT,IDLE,RD);
type t_read_state IS (INIT,BANK_ACTIVE,WAIT_READ,DO_READ);

signal state  : t_ctrl_state := BOOT;
signal istate : t_ini_state  := IDLE2;
signal rstate : t_read_state := INIT;

signal delay : unsigned(15 downto 0) := to_unsigned(0, 16);

signal data16 : std_logic_vector(15 downto 0) := (others => '0');

signal data32 : std_logic_vector(31 downto 0) := (others => '0');

signal on_req : std_logic := '0';

begin

process(clki,reset)

begin

if istate = IDLE2 then
	CLK <= '0';
else
	CLK <= '1';--clki;
end if;

if reset = '1' then
	--on_req <= '1';
elsif falling_edge(clki) and (on_req = '1') then

	case state is
	
		when BOOT =>
			case istate is
			
				when IDLE2 =>
				
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
					
						A(10) <= '1'; -- precharge all banks
						
						delay <= to_unsigned(0, delay'length); -- 1 cycle
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
						
						-- A0-A2 Burst length 2 = 32bit per r/w (in seq + interleave)
						-- A3    Interleaved addressing mode
						-- A4-A6 CAS latency 3
						-- A9    Write mode burst read + burst write
						-- Rest is 0 "reserved" bits.
						A <= "00000000111001";
						BA <= "00";
						
						delay <= to_unsigned(8, delay'length); -- does not depend on frequency
					else
						delay <= delay - 1;
					end if;
					
				when AUTO_REFRESH =>
				
					CS <= '1';
				
					if delay = 0 then
						istate <= WRITE_MR;
						
						CS <= '0';
						RAS <= '0';
						CAS <= '0';
						WE <= '0';
						
						delay <= to_unsigned(10, delay'length); -- 2 cycles minimum, no max specified
						
					else
						delay <= delay - 1;
					end if;
				
				when WRITE_MR =>
				
					CS <= '1';
				
					if delay = 0 then
					
						CKE <= '0';
						state <= RD;
						rstate <= INIT;
					else
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
					BA(0) <= '0';
					BA(1) <= '0';
					
					-- Select row
					A(11 downto 0) <= (others => '0');
					
					rstate <= BANK_ACTIVE;
					
					delay <= to_unsigned(0, delay'length); --tRCD -> minimum 15 ns; at 12 MHz the clock period is 83 ns so just one is okay.
				
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
						A(8 downto 0) <= (others => '0');
						
						rstate <= WAIT_READ;
						
						-- Need to wait CAS cycles - 1
						delay <= to_unsigned(2, delay'length);
						
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
						istate <= IDLE2;
						state <= IDLE;
					
					else
					
						delay <= delay - 1;
					
					end if;
				
			end case;
		
		when others =>
		
	end case;

end if;

c--ase state is
--	when RD =>
--		DQ <= (others =>'Z');
--		data16 <= DQ;
--	when others =>
--		DQ <= data16;
--end case;

--debug <= data32(7 downto 0);

end process;

process(clki)

begin

	if rising_edge(clki) then

		case state is
		
			when RD =>
			
				case rstate is
				
					when DO_READ =>
					
						if delay = 1 then
						
							data32(15 downto 0) <= data16;
						
						elsif delay = 0 then
					
							data32(31 downto 16) <= data16;
						
						end if;
					
					when others =>
					
				end case;
			
			when others =>
			
		end case;
		
	end if;

end process;

end rtl;


