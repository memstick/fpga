library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

library riscv_common;
use riscv_common.rv32i_global.all;
 
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
1 => x"0d00006f",
2 => x"80000737",
3 => x"02f00693",
4 => x"00054783",
5 => x"00079463",
6 => x"00008067",
7 => x"00052603",
8 => x"00259793",
9 => x"00e787b3",
10 => x"00c7a023",
11 => x"00158593",
12 => x"00150513",
13 => x"fcb6dee3",
14 => x"00000593",
15 => x"fd5ff06f",
16 => x"800007b7",
17 => x"00259593",
18 => x"00f585b3",
19 => x"00052783",
20 => x"00f5a023",
21 => x"00008067",
22 => x"ff010113",
23 => x"800007b7",
24 => x"00259593",
25 => x"00f585b3",
26 => x"01014783",
27 => x"01114703",
28 => x"03050513",
29 => x"0ff57513",
30 => x"00879793",
31 => x"00a7e7b3",
32 => x"01071713",
33 => x"00f76733",
34 => x"01214783",
35 => x"01879793",
36 => x"00e7e7b3",
37 => x"00f5a023",
38 => x"01010113",
39 => x"00008067",
40 => x"ff010113",
41 => x"000187b7",
42 => x"00012623",
43 => x"69f78793",
44 => x"00c12703",
45 => x"00e7d663",
46 => x"01010113",
47 => x"00008067",
48 => x"00c12703",
49 => x"00c12703",
50 => x"00170713",
51 => x"00e12623",
52 => x"fe1ff06f",
53 => x"40000537",
54 => x"fd010113",
55 => x"00000593",
56 => x"18450513",
57 => x"02812423",
58 => x"02912223",
59 => x"03212023",
60 => x"01312e23",
61 => x"01412c23",
62 => x"02112623",
63 => x"f0dff0ef",
64 => x"400007b7",
65 => x"19478993",
66 => x"800004b7",
67 => x"400007b7",
68 => x"00000413",
69 => x"19878a13",
70 => x"04048493",
71 => x"00a00913",
72 => x"01400593",
73 => x"00098513",
74 => x"ee1ff0ef",
75 => x"f75ff0ef",
76 => x"01400593",
77 => x"000a0513",
78 => x"ed1ff0ef",
79 => x"f65ff0ef",
80 => x"01014783",
81 => x"03040713",
82 => x"0ff77713",
83 => x"00879793",
84 => x"00e7e7b3",
85 => x"00e107a3",
86 => x"01114703",
87 => x"00140413",
88 => x"01071713",
89 => x"00f76733",
90 => x"01214783",
91 => x"01879793",
92 => x"00e7e7b3",
93 => x"00f4a023",
94 => x"fb2414e3",
95 => x"00000413",
96 => x"fa1ff06f",
97 => x"2c696548",
98 => x"72657620",
99 => x"216e6564",
100 => x"00000000",
101 => x"002f5e5e",
102 => x"007c5e5e",











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

