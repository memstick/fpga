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

--function rv32i_        return std_logic_vector is begin return ""; end;
function rv32i_lui      return std_logic_vector is begin return "0110111"; end;
function rv32i_auipc    return std_logic_vector is begin return "0010111"; end;
function rv32i_jal      return std_logic_vector is begin return "1101111"; end;
function rv32i_jalr     return std_logic_vector is begin return "1100111"; end;
function rv32i_b        return std_logic_vector is begin return "1100011"; end;
function rv32i_l        return std_logic_vector is begin return "0000011"; end;
function rv32i_s        return std_logic_vector is begin return "0100011"; end;
function rv32i_compi    return std_logic_vector is begin return "0010011"; end;
function rv32i_compr    return std_logic_vector is begin return "0110011"; end;
function rv32i_fence    return std_logic_vector is begin return "0001111"; end;
function rv32i_system   return std_logic_vector is begin return "1110011"; end;

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
	bytecode(6 downto 0)    := rv32i_l;--"0000011";
	
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
	bytecode(6 downto 0)    := rv32i_s;--"0100011";
	
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
	bytecode(6 downto 0)    := rv32i_compi;--"0010011";
	
	return bytecode;
end;

function rv32i_encode_lui(
	imm    : in std_logic_vector(31 downto 0);
	rd     : in integer range 0 to 31
	)
	return std_logic_vector is
	variable bytecode : std_logic_vector( 31 downto 0 );

	
begin

	bytecode(31 downto 12)  := imm(31 downto 12);
	bytecode(11 downto 7) 	:= std_logic_vector(to_unsigned(rd, 5));
	bytecode(6 downto 0)    := rv32i_lui;
	
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
	bytecode(6 downto 0)    := rv32i_jal;--"1101111";
	
	return bytecode;
end;


-- Typedefs
type t_cpu_state IS (ROM_INIT,INIT,FETCH,DECODE,EXECUTE,WRITEBACK,HALTED,ERROR);
type t_ram_state IS (RAM_INIT,RAM_READ,RAM_WRITE,RAM_DONE);

type t_rom is array (0 to 255) of std_logic_vector(31 downto 0);

type t_reg_bank is array (0 to 31) of std_logic_vector(31 downto 0);

-- State machine (execution cycle)
signal state : t_cpu_state := INIT;
signal rstate : t_ram_state := RAM_INIT;

-- A ROM containing code.
constant rom : t_rom := (
	0  => rv32i_encode_lui((31 => '1', others => '0'), 5),
	4  => rv32i_encode_addi(72, 0, 4),          -- imm, rs1, rd
	8  => rv32i_encode_store(0, 4, 5, 2), 		  -- imm[offset],rs2[src],rs1[base],funct3[2:4B,1:2B,0:1B]
	12  => rv32i_encode_addi(101, 0, 4),
	16  => rv32i_encode_store(1, 4, 5, 2),
	20  => rv32i_encode_addi(105, 0, 4),
	24  => rv32i_encode_store(2, 4, 5, 2),
	28  => rv32i_encode_addi(44, 0, 4),
	32  => rv32i_encode_store(3, 4, 5, 2),
	36  => rv32i_encode_addi(32, 0, 4),
	40  => rv32i_encode_store(4, 4, 5, 2),
	44  => rv32i_encode_addi(118, 0, 4),
	48  => rv32i_encode_store(5, 4, 5, 2),
	52  => rv32i_encode_addi(101, 0, 4),
	56  => rv32i_encode_store(6, 4, 5, 2),
	60  => rv32i_encode_addi(114, 0, 4),
	64  => rv32i_encode_store(7, 4, 5, 2),
	68  => rv32i_encode_addi(100, 0, 4),
	72  => rv32i_encode_store(8, 4, 5, 2),
	76  => rv32i_encode_addi(101, 0, 4),
	80  => rv32i_encode_store(9, 4, 5, 2),
	84  => rv32i_encode_addi(110, 0, 4),
	88  => rv32i_encode_store(10, 4, 5, 2),
	92  => rv32i_encode_addi(33, 0, 4),
	96  => rv32i_encode_store(11, 4, 5, 2),
	
	100  => rv32i_encode_addi(94, 0, 4),          -- imm, rs1, rd
	104  => rv32i_encode_store(0, 4, 0, 2), 		  -- imm[offset],rs2[src],rs1[base],funct3[2:4B,1:2B,0:1B]
	108  => rv32i_encode_load(0, 0, 2, '0', 4),   -- imm[offset],         rs1[base],funct3,extend?,rd
	112  => rv32i_encode_store(40, 4, 5, 2), 		  -- imm[offset],rs2[src],rs1[base],funct3[2:4B,1:2B,0:1B]
	116  => rv32i_encode_store(41, 4, 5, 2), 		  -- imm[offset],rs2[src],rs1[base],funct3[2:4B,1:2B,0:1B]
	120  => rv32i_encode_addi(47, 0, 4),          -- imm, rs1, rd
	124  => rv32i_encode_store(42, 4, 5, 2), 		  -- imm[offset],rs2[src],rs1[base],funct3[2:4B,1:2B,0:1B]
	
	128 => rv32i_encode_jal(0, 0),              -- imm[offset],rd
	
	others => (others => '0')
);

-- Until the ROM lives on the "address bus" we need some (fake) way to store the next instruction and process it.
signal MDR_ROM : std_logic_vector(31 downto 0);

-- MDR I/O (tristated)
signal MDR_i : std_logic_vector(31 downto 0) := (others => '0');
signal MDR_o : std_logic_vector(31 downto 0) := (others => '0');

-- Program counter
signal PC : unsigned( 31 downto 0 );-- := to_unsigned(0, PC'length);
-- The next PC
signal nPC : unsigned( 31 downto 0);

-- Registers
signal GPR : t_reg_bank := (others => (others => '0'));
signal GPR_RD  : std_logic_vector(31 downto 0);
signal GPR_RS1 : std_logic_vector(31 downto 0);
signal GPR_RS2 : std_logic_vector(31 downto 0);

-- OP code (instruction) register
signal OP : std_logic_vector(6 downto 0) := (others => '0');

-- Immediate register
signal IMM : std_logic_vector(31 downto 0); --

-- rs1 and rs2 register
signal RS1 : integer range 0 to 31; --(4 downto 0) := (others => '0');
signal RS2 : integer range 0 to 31; --(4 downto 0) := (others => '0');

signal RD : integer range 0 to 31;

-- Funct register
signal FUNCT3 : std_logic_vector(2 downto 0) := (others => '0');
signal FUNCT7 : std_logic_vector(6 downto 0) := (others => '0');

--signal rack_sticky : std_logic := '0';
--signal rack_sticky_clear : std_logic := '0';

begin

-- I think this saves me for all that of checking on source registers
GPR_RS1 <= (others => '0') when RS1 = 0 else GPR(RS1);
GPR_RS2 <= (others => '0') when RS2 = 0 else GPR(RS2);
GPR(RD) <= GPR_RD when (RD /= 0) and (state = WRITEBACK);
--GPR(RD) <= (others => '0') when RD = 0 else GPR_RD;

debug <= std_logic_vector(PC(7 downto 0));--MDR_ROM(7 downto 0);


-- The MDR register must be tri-stated		
MDR <= MDR_o when rstate = RAM_WRITE else (others => 'Z');
--MDR <= MDR_o;
MDR_i <= MDR;

--process(rack, rack_sticky_clear)
--
--begin
--
--if rack_sticky_clear = '1' then
--	rack_sticky <= '0';
--elsif rising_edge(rack) then
--	rack_sticky <= '1';
--end if;
--
--end process; -- rack

process(clk,reset)

-- DECODING PROCEDURES

procedure rv32i_decode_r is

begin
	FUNCT7 <= std_logic_vector(MDR_ROM(31 downto 25));
	RS2 <= to_integer(unsigned(MDR_ROM(24 downto 20)));
	RS1 <= to_integer(unsigned(MDR_ROM(19 downto 15)));
	FUNCT3 <= std_logic_vector(MDR_ROM(14 downto 12));
	RD <= to_integer(unsigned(MDR_ROM(11 downto 7)));
	OP <= MDR_ROM(6 downto 0);
end procedure rv32i_decode_r;

procedure rv32i_decode_i is

begin
	IMM <= std_logic_vector(resize(signed(MDR_ROM(31 downto 20)), IMM'length));
	RS1 <= to_integer(unsigned(MDR_ROM(19 downto 15)));
	FUNCT3 <= MDR_ROM(14 downto 12);
	RD <= to_integer(unsigned(MDR_ROM(11 downto 7)));
	OP <= MDR_ROM(6 downto 0);
end procedure rv32i_decode_i;

procedure rv32i_decode_s is

	variable temp : std_logic_vector(11 downto 0);
	
begin
	
	temp := MDR_ROM(31 downto 25) & MDR_ROM(11 downto 7);
	IMM <= std_logic_vector(resize(signed(temp), IMM'length));
	RS1 <= to_integer(unsigned(MDR_ROM(19 downto 15)));
	RS2 <= to_integer(unsigned(MDR_ROM(24 downto 20)));
	FUNCT3 <= MDR_ROM(14 downto 12);
	OP <= MDR_ROM(6 downto 0);
end procedure rv32i_decode_s;

procedure rv32i_decode_b is

	variable temp : std_logic_vector(12 downto 0);
	
begin
	
	temp := MDR_ROM(31) & MDR_ROM(7) & MDR_ROM(30 downto 25) & MDR_ROM(11 downto 8) & '0';
	IMM <= std_logic_vector(resize(signed(temp), IMM'length));
	RS1 <= to_integer(unsigned(MDR_ROM(19 downto 15)));
	RS2 <= to_integer(unsigned(MDR_ROM(24 downto 20)));
	FUNCT3 <= MDR_ROM(14 downto 12);
	OP <= MDR_ROM(6 downto 0);
end procedure rv32i_decode_b;

procedure rv32i_decode_u is

	variable temp : std_logic_vector(31 downto 0);
	
begin
	
	temp := MDR_ROM(31 downto 12) & x"000";
	IMM <= temp;--std_logic_vector(resize(signed(temp), IMM'length));
	RD <= to_integer(unsigned(MDR_ROM(11 downto 7)));
	OP <= MDR_ROM(6 downto 0);
end procedure rv32i_decode_u;

procedure rv32i_decode_j is

	variable temp : std_logic_vector(20 downto 0);
	
begin
	
	temp := MDR_ROM(31) & MDR_ROM(19 downto 12) & MDR_ROM(20) & MDR_ROM(30 downto 21) & '0';
	IMM <= std_logic_vector(resize(signed(temp), IMM'length));
	RD <= to_integer(unsigned(MDR_ROM(11 downto 7)));
	OP <= MDR_ROM(6 downto 0);
end procedure rv32i_decode_j;

-- EXECUTION PROCEDURES

procedure rv32i_execute_lui is
begin
	GPR_RD <= std_logic_vector(IMM);
	state <= WRITEBACK;
end procedure rv32i_execute_lui;

procedure rv32i_execute_auipc is
begin
	GPR_RD <= std_logic_vector(unsigned(IMM) + PC);
	state <= WRITEBACK;
end procedure rv32i_execute_auipc;

procedure rv32i_execute_jal is

begin

	GPR_RD <= std_logic_vector(PC+4);
	nPC <= unsigned(IMM) + PC;
	
	state <= WRITEBACK;

end procedure rv32i_execute_jal;

procedure rv32i_execute_jalr is

begin

	
	GPR_RD <= std_logic_vector(PC+4);
	nPC <= unsigned(
				std_logic_vector(unsigned(IMM) + unsigned(GPR_RS1)) and x"FFFFFFFE"
				);
	
	state <= WRITEBACK;

end procedure rv32i_execute_jalr;

procedure rv32i_execute_b is
begin

	case funct3 is
		
		when "000" => -- BEQ
			if GPR_RS1 = GPR_RS2 then
				nPC <= unsigned(IMM) + PC;
			end if;
			
		when "001" => -- BNE
			if GPR_RS1 /= GPR_RS2 then
				nPC <= unsigned(IMM) + PC;
			end if;
			
		when "100" => -- BLT
			if signed(GPR_RS1) < signed(GPR_RS2) then
				nPC <= unsigned(IMM) + PC;
			end if;
			
		when "101" => -- BGE
			if signed(GPR_RS1) >= signed(GPR_RS2) then
				nPC <= unsigned(IMM) + PC;
			end if;
			
		when "110" => -- BLTU
			if unsigned(GPR_RS1) < unsigned(GPR_RS2) then
				nPC <= unsigned(IMM) + PC;
			end if;
			
		when "111" => -- BGEU
			if unsigned(GPR_RS1) >= unsigned(GPR_RS2) then
				nPC <= unsigned(IMM) + PC;
			end if;
			
		when others =>
			-- error
	end case;
	
end procedure rv32i_execute_b;

procedure rv32i_execute_l is
	
begin

	case rstate is
		when RAM_INIT =>
			
			rreq <= '1';
			RW   <= '0';
			MAR <= std_logic_vector(unsigned(IMM) + unsigned(GPR_RS1));
			
			rstate <= RAM_READ;
		
		when RAM_READ =>
		
			--rreq <= '1';
			--GPR_RD <= MDR;
			if rack = '1' then
				
				case FUNCT3 is
					when "010" => --LW
						GPR_RD <= MDR_i;
					when "001" => --LH
						GPR_RD <= std_logic_vector(resize(signed(MDR_i(15 downto 0)), 32));
					when "101" => --LHU
						GPR_RD <= MDR_i and x"0000FFFF";
					when "000" => --LB
						GPR_RD <= std_logic_vector(resize(signed(MDR_i(7 downto 0)), 32));
					when "100" => --LBU
						GPR_RD <= MDR_i and x"000000FF";
					when others =>
						-- Error
				end case;
				
				
				rstate <= RAM_DONE;
				--state <= WRITEBACK;
			end if;
			
		when RAM_DONE =>
		
			rreq <= '0';
		
			if rack = '0' then
				state <= WRITEBACK;
			end if;
				
		when others =>
			-- Error
	
	end case;

end procedure rv32i_execute_l;

procedure rv32i_execute_s is

begin

	case rstate is
		when RAM_INIT =>
			
			rreq <= '1';
			RW   <= '1';

			case FUNCT3 is
				when "000" => --SB
					MDR_o <= GPR_RS2 and x"000000FF";
				when "001" => --SH
					MDR_o <= GPR_RS2 and x"0000FFFF";
				when "010" => --SW
					MDR_o <= GPR_RS2;
				when others =>
			end case;
			MAR <= std_logic_vector(unsigned(IMM) + unsigned(GPR_RS1));
			
			rstate <= RAM_WRITE;

		when RAM_WRITE =>
		
			--rreq <= '1';
			if rack = '1' then
				--state <= WRITEBACK;
				rstate <= RAM_DONE;
			end if;
			
		when RAM_DONE =>
		
			rreq <= '0';
		
			if rack = '0' then
				state <= WRITEBACK;
			end if;
			
		when others =>
			-- Error
	
	end case;

end procedure rv32i_execute_s;

procedure rv32i_execute_compi is

begin

	case funct3 is
		when "000" => -- ADDI
			GPR_RD <= std_logic_vector(unsigned(GPR_RS1) + unsigned(IMM));
		when "010" => -- SLTI
			if signed(GPR_RS1) < signed(IMM) then
				GPR_RD <= (0 => '1', others => '0');
			end if;
		when "011" => -- SLTIU
			if unsigned(GPR_RS1) < unsigned(IMM) then
				GPR_RD <= (0 => '1', others => '0');
			end if;
		when "100" => -- XORI
			GPR_RD <= GPR_RS1 xor IMM;
		when "110" => -- ORI
			GPR_RD <= GPR_RS1 or IMM;
		when "111" => -- ANDI
			GPR_RD <= GPR_RS1 and IMM;
		when "001" => -- SLLI ; This and the one below I have decoded as "R" - so the amount to be shifted is in "RS2", and the imm is in FUNCT7
			GPR_RD <= std_logic_vector(unsigned(GPR_RS1) sll RS2);
		when "101" => -- SRLI / SRAI
			case funct7(5) is -- Bit30 of the instruction tells us the final type
				
				when '0' => -- SRLI
					GPR_RD <= std_logic_vector(unsigned(GPR_RS1) srl RS2);
					
				when '1' => -- SRAI arithmetic shift
					GPR_RD <= std_logic_vector(shift_right(signed(GPR_RS1), RS2));
				
			end case;
		when others =>
			-- error!
	end case;
	
	state <= WRITEBACK;

end procedure rv32i_execute_compi;

procedure rv32i_execute_compr is
begin

	case funct3 is
	
		when "000" => -- ADD/SUB
		
			case funct7(5) is
				when '0' => -- ADD
					GPR_RD <= std_logic_vector(unsigned(GPR_RS1) + unsigned(GPR_RS2));
					
				when '1' => -- SUB
					GPR_RD <= std_logic_vector(unsigned(GPR_RS1) - unsigned(GPR_RS2));
					
			end case;
		
		when "001" => -- SLL
			GPR_RD <= std_logic_vector( unsigned(GPR_RS1) sll to_integer(unsigned(GPR_RS2(4 downto 0))));
		
		when "010" => -- SLT
		
			if signed(GPR_RS1) < signed(GPR_RS2) then
				GPR_RD <= (0 => '1', others => '0');
			end if;
			
		when "011" => -- SLTU
		
			if unsigned(GPR_RS1) < unsigned(GPR_RS2) then
				GPR_RD <= (0 => '1', others => '0');
			end if;
			
		when "100" => -- XOR
		
			GPR_RD <= GPR_RS1 xor GPR_RS2;
			
		when "101" => -- SRL/SRA
		
			case funct7(5) is
				when '0' => -- SRL
					GPR_RD <= std_logic_vector( unsigned(GPR_RS1) srl to_integer(unsigned(GPR_RS2(4 downto 0))));
					
				when '1' => -- SRA
					GPR_RD <= std_logic_vector( shift_right(signed(GPR_RS1), to_integer(unsigned(GPR_RS2(4 downto 0)))));
				
			end case;
			
		when "110" => -- OR
			GPR_RD <= GPR_RS1 or GPR_RS2;
			
		when "111" => -- AND
			GPR_RD <= GPR_RS1 and GPR_RS2;
			
		when others =>
			--error		
	end case;

end procedure rv32i_execute_compr;

begin

	if falling_edge(clk) then
		if reset = '1' then

			FUNCT3 <= (others => '0');
			FUNCT7 <= (others => '0');
			RS1 <= 0;
			RS2 <= 0;
			RD <= 0;
			IMM <= (others => '0');
			OP <= (others => '0');
			PC <= (others => '0');
			nPC <= (others => '0');
			MDR_o <= (others => '0');
			rreq <= '0';
			
			state <= FETCH;
			rstate <= RAM_INIT;
			
			--rack_sticky_clear <= '1';

		else

			-- ####################### --
			--     STATE MACHINERY     --
			-- ####################### --
			case state is
			
				when FETCH =>
				
					MDR_ROM <= rom(to_integer(PC));
					nPC <= PC + 4;
					state <= DECODE;
					rstate <= RAM_INIT;
					
					--rack_sticky_clear <= '0';

				when DECODE =>
					
					case MDR_ROM(6 downto 0) is
					
						when rv32i_compr =>
							rv32i_decode_r;
					
						when rv32i_compi =>
						
							case MDR_ROM(13 downto 12) is
								
								when "01" =>
									rv32i_decode_r;
								
								when others =>
									rv32i_decode_i;
							
							end case;
					
						when rv32i_l | rv32i_jalr | rv32i_fence | rv32i_system =>
							rv32i_decode_i;
							
						when rv32i_s =>
							rv32i_decode_s;
							
						when rv32i_b =>
							rv32i_decode_b;
							
						when rv32i_lui | rv32i_auipc =>
							rv32i_decode_u;
							
						when rv32i_jal =>
							rv32i_decode_j;
							
						when others =>
							--error
					end case;
					
					state <= EXECUTE;
					rstate <= RAM_INIT;
					
				when EXECUTE =>
				
					case OP is
						when rv32i_lui =>
							rv32i_execute_lui;
							
						when rv32i_auipc =>
							rv32i_execute_auipc;
							
						when rv32i_jal =>
							rv32i_execute_jal;
							
						when rv32i_jalr =>
							rv32i_execute_jalr;
							
						when rv32i_b =>
							rv32i_execute_b;
							
						when rv32i_l =>
							rv32i_execute_l;
							
						when rv32i_s =>
							rv32i_execute_s;
							
						when rv32i_compi =>
							rv32i_execute_compi;
						
						when rv32i_compr =>
							rv32i_execute_compr;
							
						when rv32i_fence =>
							-- Ignore for now
						
						when rv32i_system =>
							-- Ignore for now
							
						when others =>
					end case;
					
				when WRITEBACK =>
				
					PC <= nPC;
					
					state <= FETCH;
					rstate <= RAM_INIT;
					
					--rreq <= '0';
					--rack_sticky_clear <= '1';

				when ERROR =>
				
				when others =>
					
			end case;
			
		end if;
			
	end if;

end process;

end rtl;