library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity rv32i is
	port (

		-- Input clock
		clk        : in  std_logic;
		
		reset      : in std_logic;
		
		rack       : in std_logic;
		 
		MAR : out std_logic_vector( 31 downto 0) := (others => '0');

		MDR : out std_logic_vector( 31 downto 0) := (others => '0');
		
		RW : out std_logic := '0';
		
		rreq : out std_logic := '0';
		 
		-- Generic debug port (8 bits).
		debug		: out std_logic_vector(7 downto 0) := (others => '0')

	);
end rv32i;

architecture rtl of rv32i is

-- Typedefs
type t_cpu_state IS (ROM_INIT,INIT,FETCH,DECODE,EXECUTE,WRITEBACK,HALTED,ERROR);
type t_ram_state IS (RAM_INIT,RAM_READ,RAM_WRITE,RAM_DONE);

type t_ram is array (0 to 255) of std_logic_vector(31 downto 0);

-- State machine (execution cycle)
signal state : t_cpu_state := INIT;
signal rstate : t_ram_state := RAM_INIT;

-- The RAM that this machine has
signal ram : t_ram := (others => (others => '0'));

-- Program counter
signal PC : unsigned( 31 downto 0 );-- := to_unsigned(0, PC'length);

-- Registers
signal x0 : std_logic_vector(31 downto 0) := (others => '0');

-- OP code (instruction) register
signal OP : std_logic_vector(31 downto 0) := (others => '0');

-- Immediate register
signal IMM : std_logic_vector(19 downto 0) := (others => '0');

-- rs1 and rs2 register
signal RS1 : std_logic_vector(4 downto 0) := (others => '0');
signal RS2 : std_logic_vector(4 downto 0) := (others => '0');

-- Funct register
signal FUNCT : std_logic_vector(2 downto 0) := (others => '0');



begin

process(clk)

begin

if rising_edge(clk) then

	-- ####################### --
	--     STATE MACHINERY     --
	-- ####################### --
	case state is
			
		when INIT =>
		
		when FETCH =>
		
			--case rstate is
--				when RAM_INIT =>
--					MAR <= PC;
--					rstate <= RAM_READ;
--				when RAM_READ =>
--					case bstate is
--						when BOOTROM =>
--							MDR <= rom(to_integer(MAR));
--						when NORMAL =>
--							MDR <= ram(to_integer(MAR));
--					end case;
--					rstate <= RAM_DONE;
--				when RAM_DONE =>
--				
--					if PC = 99 then
--						PC <= to_unsigned(0, PC'length);
--					else
--						PC <= PC + 1;
--					end if;
--					
--					state <= DECODE;
--					rstate <= RAM_INIT;
--				when others =>
--					state <= ERROR;
					
			--end case;
					
		when DECODE =>
			
		when EXECUTE =>

		when ERROR =>
			
	end case;
	
end if;

end process;

end rtl;