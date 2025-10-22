library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

use work.rv32i_global.all; -- Assuming your package is compiled into the 'work' library
 
entity rom is
  port (
	
		clk	     : in std_logic;
		
		reset      : in std_logic;

		addr		  : in 		std_logic_vector(31 downto 0);
		rw			  : in std_logic;
		data       : inout   	std_logic_vector(31 downto 0);
		rreq       : in 		std_logic;
		rack       : out 		std_logic := '0';
		
		debug      : out     std_logic_vector(7 downto 0)
		
 
    );
end rom;

architecture rtl of rom is

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

function rv32i_encode_cbranch(
	imm    : in integer range -4096 to 4095;
	rs1    : in integer range 0 to 31;
	rs2    : in integer range 0 to 31;
	funct3 : in integer range 0 to 7
	)
	return std_logic_vector is
	variable bytecode : std_logic_vector( 31 downto 0 );
	
	variable temp : std_logic_vector(12 downto 0);
begin

	temp := std_logic_vector(to_signed(imm, 13));
	
	bytecode(31) := temp(12);
	bytecode(7) := temp(11);
	bytecode(30 downto 25) := temp(10 downto 5);
	bytecode(11 downto 8) := temp(4 downto 1);

	bytecode(24 downto 20) 	:= std_logic_vector(to_unsigned(rs2, 5));
	bytecode(19 downto 15) 	:= std_logic_vector(to_unsigned(rs1, 5));
	bytecode(14 downto 12)  := std_logic_vector(to_unsigned(funct3, 3));
	bytecode(6 downto 0)    := rv32i_b;
	
	return bytecode;
end;

type t_rom is array (0 to 1023) of std_logic_vector(31 downto 0);

type t_ram_state IS (RAM_INIT,RAM_READ,RAM_WRITE,RAM_DONE);

signal rstate : t_ram_state := RAM_INIT;

signal data_o : std_logic_vector(31 downto 0);

-- A ROM containing code.
constant rom : t_rom := (
--	0  => rv32i_encode_lui((31 => '1', others => '0'), 5),
--	1  => rv32i_encode_addi(72, 0, 4),          -- imm, rs1, rd
--	2  => rv32i_encode_store(0, 4, 5, 2), 		  -- imm[offset],rs2[src],rs1[base],funct3[2:4B,1:2B,0:1B]
--	3  => rv32i_encode_addi(101, 0, 4),
--	4  => rv32i_encode_store(4, 4, 5, 2),
--	5  => rv32i_encode_addi(105, 0, 4),
--	6  => rv32i_encode_store(8, 4, 5, 2),
--	7  => rv32i_encode_addi(44, 0, 4),
--	8  => rv32i_encode_store(12, 4, 5, 2),
--	9  => rv32i_encode_addi(32, 0, 4),
--	10  => rv32i_encode_store(16, 4, 5, 2),
--	11  => rv32i_encode_addi(118, 0, 4),
--	12  => rv32i_encode_store(20, 4, 5, 2),
--	13  => rv32i_encode_addi(101, 0, 4),
--	14  => rv32i_encode_store(24, 4, 5, 2),
--	15  => rv32i_encode_addi(114, 0, 4),
--	16  => rv32i_encode_store(28, 4, 5, 2),
--	17  => rv32i_encode_addi(100, 0, 4),
--	18  => rv32i_encode_store(32, 4, 5, 2),
--	19  => rv32i_encode_addi(101, 0, 4),
--	20  => rv32i_encode_store(36, 4, 5, 2),
--	21  => rv32i_encode_addi(110, 0, 4),
--	22  => rv32i_encode_store(40, 4, 5, 2),
--	23  => rv32i_encode_addi(33, 0, 4),
--	24  => rv32i_encode_store(44, 4, 5, 2),
----	
--	25  => rv32i_encode_addi(94, 0, 4),          -- imm, rs1, rd
--	26  => rv32i_encode_store(48, 4, 0, 2), 		  -- imm[offset],rs2[src],rs1[base],funct3[2:4B,1:2B,0:1B]
--	27  => rv32i_encode_load(12, 0, 2, '0', 4),   -- imm[offset],         rs1[base],funct3,extend?,rd
--	28  => rv32i_encode_store(160, 4, 5, 2), 		  -- imm[offset],rs2[src],rs1[base],funct3[2:4B,1:2B,0:1B]
--	29  => rv32i_encode_store(164, 4, 5, 2), 		  -- imm[offset],rs2[src],rs1[base],funct3[2:4B,1:2B,0:1B]
--	30  => rv32i_encode_addi(47, 0, 4),          -- imm, rs1, rd
--	31  => rv32i_encode_store(168, 4, 5, 2), 		  -- imm[offset],rs2[src],rs1[base],funct3[2:4B,1:2B,0:1B]
--
--
--	-- Init sequence
--	32  => rv32i_encode_lui((19 => '1', others => '0'), 1), -- Num cycles before break
--	33  => rv32i_encode_addi(0, 0, 2), -- Our cycle count before increment
--	34  => rv32i_encode_addi(58, 0, 3), -- End of count
--	35  => rv32i_encode_addi(48, 0, 4), -- Current decimal
--	
--	36  => rv32i_encode_addi(47, 0, 6),
--	37  => rv32i_encode_store(4, 6, 0, 1), -- here
--	38  => rv32i_encode_addi(124, 0, 6),
--			
--			
--		 	-- Start loop here
--	--C: 
--	39  => rv32i_encode_store(168, 6, 5, 2),
--	40  => rv32i_encode_load(4, 0, 2, '0', 7),
--	41  => rv32i_encode_store(4, 6, 0, 1), -- here
--	42  => rv32i_encode_addi(0, 7, 6),
--	43  => rv32i_encode_store(136, 4, 5, 2),
--	44  => rv32i_encode_addi(1, 4, 4), 			-- Increment	
--	45  => rv32i_encode_cbranch(20 , 3, 4, 0 ), 	-- A!! imm, rs1, rs2, funct3:BE; check if we counted to 9
--	--B: 
--	46  => rv32i_encode_addi(1, 2, 2), 			-- inc cycle counter
--	47  => rv32i_encode_cbranch(-4 , 1, 2, 1 ), 	-- B!! imm, rs1, rs2, funct3:BNE; check if we counted to num cycles
--	48  => rv32i_encode_addi(0, 0, 2), 				-- Restore our cycle counter to 0
--	49  => rv32i_encode_jal(-40, 0), --C!!
--		-- Reset decimal counter
--	--A:
--	50  => rv32i_encode_addi(48, 0, 4),
--	51  => rv32i_encode_jal(-20, 0),
--	52  => x"00000000",
	
0 => x"00001137",
1 => x"0500006f",
2 => x"400006b7",
3 => x"0806a783",
4 => x"00000713",
5 => x"800005b7",
6 => x"02f00813",
7 => x"00052603",
8 => x"00061863",
9 => x"00070463",
10 => x"08f6a023",
11 => x"00008067",
12 => x"00279713",
13 => x"00b70733",
14 => x"00c72023",
15 => x"00178793",
16 => x"00450513",
17 => x"00f87463",
18 => x"00000793",
19 => x"00100713",
20 => x"fcdff06f",
21 => x"40000537",
22 => x"ff010113",
23 => x"06c50513",
24 => x"00112623",
25 => x"fa5ff0ef",
26 => x"0000006f",
27 => x"00000065",
28 => x"00000066",
29 => x"00000067",
30 => x"00000068",
31 => x"00000000",


	others => (others => '0')
);

begin

data <= data_o when (rw = '0') else (others => 'Z');

process(clk,reset)

variable idx : integer range 0 to 1023;

begin
	
	if falling_edge(clk) then
	
		if reset = '1' then
			-- Reset
			rstate <= RAM_INIT;
			rack <= '0';
			
			data_o <= x"00000076";
			
			debug <= (others => '0');

		else
			case rstate is
			
				when RAM_INIT =>
				
					if rreq = '1' then
					
						debug(0) <= '1';
						
						if RW = '0' then
						
							idx := to_integer(unsigned(addr(11 downto 2)));
							data_o <= rom(to_integer(unsigned(addr(11 downto 2))));--addr;--rom( unsigned(addr(11 downto 2)) );--idx );
						end if;
						
						rack <= '1';
						rstate <= RAM_DONE;
					end if;
				
				when RAM_DONE =>
				
					if rreq = '0' then
						rack <= '0';
						rstate <= RAM_INIT;
					end if;
			
				when others =>
					-- error
			end case;
		end if;
		
	end if;
end process;

end rtl;


