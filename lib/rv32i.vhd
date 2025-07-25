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

		MDR : inout std_logic_vector( 31 downto 0) := (others => '0');
		
		RW : out std_logic := '0';
		
		rreq : out std_logic := '0';
		 
		-- Generic debug port (8 bits).
		debug		: out std_logic_vector(7 downto 0) := (others => '0')

	);
end rv32i;

architecture rtl of rv32i is

function rv32i_l        return std_logic_vector is begin return "0000011"; end;
function rv32i_s        return std_logic_vector is begin return "0100011"; end;
function rv32i_jal      return std_logic_vector is begin return "1101111"; end;
function rv32i_addi     return std_logic_vector is begin return "0010011"; end;

function rv32i_encode_load(
	offset : in integer range -2047 to 2048;
	rs1    : in integer range 0 to 31;
	funct3 : in integer range 0 to 2;
	extend : in std_logic;
	rd     : in integer range 0 to 31
	)
	return std_logic_vector is
	variable bytecode : std_logic_vector( 31 downto 0 );
begin

	--bytecode := (others => '0');
	bytecode(31 downto 20) 	:= std_logic_vector(to_signed(offset, 12));
	bytecode(19 downto 15) 	:= std_logic_vector(to_unsigned(rs1, 5));
	bytecode(14) 				:= extend;
	bytecode(13 downto 12)  := std_logic_vector(to_unsigned(funct3, 2));
	bytecode(11 downto 7) 	:= std_logic_vector(to_unsigned(rd, 5));
	bytecode(6 downto 0)    := "0000011";
	
	return bytecode;
end;

function rv32i_encode_store(
	offset : in integer range -2047 to 2048;
	rs2    : in integer range 0 to 31;
	rs1    : in integer range 0 to 31;
	funct3 : in integer range 0 to 2
	)
	return std_logic_vector is
	variable bytecode : std_logic_vector( 31 downto 0 );
	
	
	variable temp : std_logic_vector(11 downto 0);
begin

	
	temp := std_logic_vector(to_signed(offset, 12));

	--bytecode := (others => '0');
	bytecode(31 downto 25) 	:= temp(11 downto 5);
	bytecode(24 downto 20) 	:= std_logic_vector(to_unsigned(rs2, 5));
	bytecode(19 downto 15) 	:= std_logic_vector(to_unsigned(rs1, 5));
	bytecode(14) 				:= '0';
	bytecode(13 downto 12)  := std_logic_vector(to_unsigned(funct3, 2));
	bytecode(11 downto 7) 	:= temp(4 downto 0);
	bytecode(6 downto 0)    := "0100011";
	
	return bytecode;
end;

function rv32i_encode_addi(
	imm    : in integer range -2047 to 2048;
	rs1    : in integer range 0 to 31;
	rd     : in integer range 0 to 31--;	--funct3 : in integer range 0 to 2
	)
	return std_logic_vector is
	variable bytecode : std_logic_vector( 31 downto 0 );

begin

	bytecode(31 downto 20) 	:= std_logic_vector(to_signed(imm, 12));
	bytecode(19 downto 15) 	:= std_logic_vector(to_unsigned(rs1, 5));
	bytecode(14 downto 12)  := "000";
	bytecode(11 downto 7) 	:= std_logic_vector(to_unsigned(rd, 5));
	bytecode(6 downto 0)    := "0010011";
	
	return bytecode;
end;

function rv32i_encode_jal(
	imm    : in integer range -1048575 to 1048576;
	rd     : in integer range 0 to 31
	)
	return std_logic_vector is
	variable bytecode : std_logic_vector( 31 downto 0 );

	variable temp : std_logic_vector(20 downto 0);
begin

	temp := std_logic_vector(to_signed(imm, 21));

	bytecode(31) 	:= temp(20);
	bytecode(30 downto 21) 	:= temp(10 downto 1);
	bytecode(20) 	:= temp(11);
	bytecode(19 downto 12) 	:= temp(19 downto 12);
	bytecode(11 downto 7) 	:= std_logic_vector(to_unsigned(rd, 5));
	bytecode(6 downto 0)    := "1101111";
	
	return bytecode;
end;



-- Typedefs
type t_cpu_state IS (ROM_INIT,INIT,FETCH,DECODE,EXECUTE,WRITEBACK,HALTED,ERROR);
type t_ram_state IS (RAM_INIT,RAM_READ,RAM_WRITE,RAM_DONE);

type t_ram is array (0 to 255) of std_logic_vector(31 downto 0);

type t_reg_bank is array (0 to 15) of std_logic_vector(31 downto 0);

-- State machine (execution cycle)
signal state : t_cpu_state := INIT;
signal rstate : t_ram_state := RAM_INIT;

-- The RAM that this machine has
signal ram : t_ram := (others => (others => '0'));

-- Program counter
signal PC : unsigned( 31 downto 0 );-- := to_unsigned(0, PC'length);

-- Registers
--signal x0 : std_logic_vector(31 downto 0) := (others => '0');
signal GPR : t_reg_bank := (others => (others => '0'));

-- OP code (instruction) register
signal OP : std_logic_vector(6 downto 0) := (others => '0');

-- Immediate register
signal IMM : signed(19 downto 0); --std_logic_vector(19 downto 0) := (others => '0');

-- rs1 and rs2 register
signal RS1 : integer range 0 to 15; --(4 downto 0) := (others => '0');
signal RS2 : integer range 0 to 15; --(4 downto 0) := (others => '0');

signal RD : integer range 0 to 15;

-- Funct register
signal FUNCT : std_logic_vector(2 downto 0) := (others => '0');

signal test : signed(11 downto 0);


begin

process(clk,reset)

	procedure rv32i_decode_i is

	begin
		IMM <= resize(signed(MDR(31 downto 20)), IMM'length);
		RS1 <= to_integer(unsigned(MDR(19 downto 15)));
		FUNCT <= MDR(14 downto 12);
		RD <= to_integer(unsigned(MDR(11 downto 7)));
		OP <= MDR(6 downto 0);
	end procedure rv32i_decode_i;
	
	procedure rv32i_decode_s is
	
		variable temp : std_logic_vector(11 downto 0);
		
	begin
		
		temp := MDR(31 downto 25) & MDR(11 downto 7);
		IMM <= resize(signed(temp), IMM'length);
		RS1 <= to_integer(unsigned(MDR(19 downto 15)));
		FUNCT <= MDR(14 downto 12);
		--RD <= to_integer(unsigned(MDR(11 downto 7)));
		OP <= MDR(6 downto 0);
	end procedure rv32i_decode_s;
	
	procedure rv32i_decode_j is
	
		variable temp : std_logic_vector(19 downto 0);
		
	begin
		
		temp := MDR(31) & MDR(19 downto 12) & MDR(20) & MDR(30 downto 21);
		IMM <= resize(signed(temp), IMM'length);
		--RS1 <= to_integer(unsigned(MDR(19 downto 15)));
		--FUNCT <= MDR(14 downto 12);
		RD <= to_integer(unsigned(MDR(11 downto 7)));
		OP <= MDR(6 downto 0);
	end procedure rv32i_decode_j;

	begin

	if reset = '0' then

	-- Load ( offset, rs1, funct3(log2(bytes to fetch)), 0/1 (sign/zero extend), rd )
	-- Store ( offset, rs1, rs2, funct3(log2(bytes to write)) )
	-- Addi ( imm, rs1, rd )
	-- JAL ( imm, rd )

	ram(0) <= rv32i_encode_load(0, 0, 2, '0', 22);
	ram(1) <= rv32i_encode_addi(1, 22, 22);
	ram(2) <= rv32i_encode_store(0, 0, 22, 2);
	ram(3) <= rv32i_encode_jal(0, 0);

	FUNCT <= (others => '0');
	RS1 <= 0;
	RS2 <= 0;--(others => '0');
	RD <= 0;
	IMM <= (others => '0');
	OP <= (others => '0');
	GPR <= (others => (others => '0'));
	PC <= (others => '0');

	elsif falling_edge(clk) then

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
				
				MDR <= ram(to_integer(PC));
				PC <= PC + 1;
				state <= DECODE;

			when DECODE =>
			
				--OP := MDR(6 downto 0);
				
				case MDR(6 downto 0) is
					when rv32i_l | rv32i_addi =>
						rv32i_decode_i;
					when rv32i_s =>
						rv32i_decode_s;
					when rv32i_jal =>
						rv32i_decode_j;
					when others =>
				end case;
				
				state <= EXECUTE;
				
			when EXECUTE =>
			
				case OP is
					when rv32i_l =>
					when others =>
				end case;

			when ERROR =>
			
			when others =>
				
		end case;
		
	end if;

end process;

end rtl;