library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity cpu is
  port (
	
	 -- Input clock
    clk        : in  std_logic;
	 
	 -- Output port
	 o_data     : out std_logic_vector(7 downto 0) := (others => '0');
	 o_valid		: out std_logic := '0';
	 
	 -- Input port
	 i_data     : in std_logic_vector(7 downto 0);
	 
	 -- Interrupt
	 irq_iow    : in std_logic;
	 irq_ior		: in std_logic;
	 ack_ior    : out std_logic := '0';
	 ack_iow    : out std_logic := '0';
	 
	 -- To LCD
	 o_acc		: out std_logic_vector(12 downto 0);
	 o_pc 		: out std_logic_vector(7 downto 0);
	 o_mdr		: out std_logic_vector(12 downto 0);
	 o_mar		: out std_logic_vector(7 downto 0);
	 o_ir		: out std_logic_vector(3 downto 0);
	 o_ar		: out std_logic_vector(7 downto 0);
	 o_state : out std_logic_vector(23 downto 0) := (others => '0');
	 	 
	 -- Generic debug port (8 bits).
	 debug		: out std_logic_vector(7 downto 0) := (others => '0')
	 
    );
end cpu;

architecture rtl of cpu is

-- Typedefs
type t_cpu_state IS (ROM_INIT,INIT,FETCH,DECODE,EXECUTE,WRITEBACK,HALTED,ERROR);
type t_ram_state IS (RAM_INIT,RAM_READ,RAM_WRITE,RAM_DONE);
type t_io_state IS (IO_INIT,I_WFI,I_ACK,O_WFI,O_ACK,I_DONE,O_DONE,IO_RETRY);
type t_boot_state IS (BOOTROM,NORMAL);

type t_buf is array(0 to 3) of unsigned(7 downto 0);
type t_ram is array (0 to 99) of std_logic_vector(12 downto 0);

-- State machine (execution cycle)
signal state : t_cpu_state := INIT;
signal rstate : t_ram_state := RAM_INIT;
signal iostate : t_io_state := IO_INIT;
signal bstate : t_boot_state := BOOTROM;

-- The RAM that this machine has
signal ram : t_ram := (others => (others => '0'));

signal rom : t_ram := (others => (others => '0'));

-- Program counter
signal PC : unsigned( 7 downto 0 ) := to_unsigned(0, 8);

-- Accumulator
signal ACC : std_logic_vector( 12 downto 0 ) := "0" & x"072";-- (others => '0');

-- Instruction register
signal IR : unsigned( 3 downto 0) := to_unsigned(0, 4);

-- Address register
signal AR : unsigned( 7 downto 0) := to_unsigned(0, 8);

-- MAR/MDR - should be in a RAM controller ideally
signal MAR : unsigned( 7 downto 0) := to_unsigned(0, 8);
signal MDR : std_logic_vector( 12 downto 0) := (others => '0');

function tens_remainder ( number : unsigned(12 downto 0) ) return unsigned is 
variable result : unsigned ( 12 downto 0 ) ;
begin
	case number is
		when to_unsigned(19, result'length) => result := to_unsigned(9, result'length);
		when to_unsigned(18, result'length) => result := to_unsigned(8, result'length);
		when to_unsigned(17, result'length) => result := to_unsigned(7, result'length);
		when to_unsigned(16, result'length) => result := to_unsigned(6, result'length);
		when to_unsigned(15, result'length) => result := to_unsigned(5, result'length);
		when to_unsigned(14, result'length) => result := to_unsigned(4, result'length);
		when to_unsigned(13, result'length) => result := to_unsigned(3, result'length);
		when to_unsigned(12, result'length) => result := to_unsigned(2, result'length);
		when to_unsigned(11, result'length) => result := to_unsigned(1, result'length);
		when to_unsigned(10, result'length) => result := to_unsigned(0, result'length);
		when others => result := number;
	end case;
	
	return result ;
end function tens_remainder;

function bin_to_dec ( number : unsigned(7 downto 0) ) return std_logic_vector is 
variable result : std_logic_vector ( 7 downto 0 ) ;
begin
	case number is
		when to_unsigned(0, number'length) => result := x"00";
		when to_unsigned(1, number'length) => result := x"01";
		when to_unsigned(2, number'length) => result := x"02";
		when to_unsigned(3, number'length) => result := x"03";
		when to_unsigned(4, number'length) => result := x"04";
		when to_unsigned(5, number'length) => result := x"05";
		when to_unsigned(6, number'length) => result := x"06";
		when to_unsigned(7, number'length) => result := x"07";
		when to_unsigned(8, number'length) => result := x"08";
		when to_unsigned(9, number'length) => result := x"09";
		when to_unsigned(10, number'length) => result := x"10";
		when to_unsigned(11, number'length) => result := x"11";
		when to_unsigned(12, number'length) => result := x"12";
		when to_unsigned(13, number'length) => result := x"13";
		when to_unsigned(14, number'length) => result := x"14";
		when to_unsigned(15, number'length) => result := x"15";
		when to_unsigned(16, number'length) => result := x"16";
		when to_unsigned(17, number'length) => result := x"17";
		when to_unsigned(18, number'length) => result := x"18";
		when to_unsigned(19, number'length) => result := x"19";
		when to_unsigned(20, number'length) => result := x"20";
		when to_unsigned(21, number'length) => result := x"21";
		when to_unsigned(22, number'length) => result := x"22";
		when to_unsigned(23, number'length) => result := x"23";
		when to_unsigned(24, number'length) => result := x"24";
		when to_unsigned(25, number'length) => result := x"25";
		when to_unsigned(26, number'length) => result := x"26";
		when to_unsigned(27, number'length) => result := x"27";
		when to_unsigned(28, number'length) => result := x"28";
		when to_unsigned(29, number'length) => result := x"29";
		when to_unsigned(30, number'length) => result := x"30";
		when to_unsigned(31, number'length) => result := x"31";
		when to_unsigned(32, number'length) => result := x"32";
		when to_unsigned(33, number'length) => result := x"33";
		when to_unsigned(34, number'length) => result := x"34";
		when to_unsigned(35, number'length) => result := x"35";
		when to_unsigned(36, number'length) => result := x"36";
		when to_unsigned(37, number'length) => result := x"37";
		when to_unsigned(38, number'length) => result := x"38";
		when to_unsigned(39, number'length) => result := x"39";
		when to_unsigned(40, number'length) => result := x"40";
		when to_unsigned(41, number'length) => result := x"41";
		when to_unsigned(42, number'length) => result := x"42";
		when to_unsigned(43, number'length) => result := x"43";
		when to_unsigned(44, number'length) => result := x"44";
		when to_unsigned(45, number'length) => result := x"45";
		when to_unsigned(46, number'length) => result := x"46";
		when to_unsigned(47, number'length) => result := x"47";
		when to_unsigned(48, number'length) => result := x"48";
		when to_unsigned(49, number'length) => result := x"49";
		when to_unsigned(50, number'length) => result := x"50";
		when to_unsigned(51, number'length) => result := x"51";
		when to_unsigned(52, number'length) => result := x"52";
		when to_unsigned(53, number'length) => result := x"53";
		when to_unsigned(54, number'length) => result := x"54";
		when to_unsigned(55, number'length) => result := x"55";
		when to_unsigned(56, number'length) => result := x"56";
		when to_unsigned(57, number'length) => result := x"57";
		when to_unsigned(58, number'length) => result := x"58";
		when to_unsigned(59, number'length) => result := x"59";
		when to_unsigned(60, number'length) => result := x"60";
		when to_unsigned(61, number'length) => result := x"61";
		when to_unsigned(62, number'length) => result := x"62";
		when to_unsigned(63, number'length) => result := x"63";
		when to_unsigned(64, number'length) => result := x"64";
		when to_unsigned(65, number'length) => result := x"65";
		when to_unsigned(66, number'length) => result := x"66";
		when to_unsigned(67, number'length) => result := x"67";
		when to_unsigned(68, number'length) => result := x"68";
		when to_unsigned(69, number'length) => result := x"69";
		when to_unsigned(70, number'length) => result := x"70";
		when to_unsigned(71, number'length) => result := x"71";
		when to_unsigned(72, number'length) => result := x"72";
		when to_unsigned(73, number'length) => result := x"73";
		when to_unsigned(74, number'length) => result := x"74";
		when to_unsigned(75, number'length) => result := x"75";
		when to_unsigned(76, number'length) => result := x"76";
		when to_unsigned(77, number'length) => result := x"77";
		when to_unsigned(78, number'length) => result := x"78";
		when to_unsigned(79, number'length) => result := x"79";
		when to_unsigned(80, number'length) => result := x"80";
		when to_unsigned(81, number'length) => result := x"81";
		when to_unsigned(82, number'length) => result := x"82";
		when to_unsigned(83, number'length) => result := x"83";
		when to_unsigned(84, number'length) => result := x"84";
		when to_unsigned(85, number'length) => result := x"85";
		when to_unsigned(86, number'length) => result := x"86";
		when to_unsigned(87, number'length) => result := x"87";
		when to_unsigned(88, number'length) => result := x"88";
		when to_unsigned(89, number'length) => result := x"89";
		when to_unsigned(90, number'length) => result := x"90";
		when to_unsigned(91, number'length) => result := x"91";
		when to_unsigned(92, number'length) => result := x"92";
		when to_unsigned(93, number'length) => result := x"93";
		when to_unsigned(94, number'length) => result := x"94";
		when to_unsigned(95, number'length) => result := x"95";
		when to_unsigned(96, number'length) => result := x"96";
		when to_unsigned(97, number'length) => result := x"97";
		when to_unsigned(98, number'length) => result := x"98";
		when to_unsigned(99, number'length) => result := x"99";
		
		when others =>
	end case;
	
	return result ;
end function bin_to_dec;

begin

process(clk)

variable ibuf : unsigned(7 downto 0);
variable inp_buf : t_buf;
variable inp_idx : integer range 0 to 15;

variable a0 : unsigned(12 downto 0);
variable a1 : unsigned(12 downto 0);
variable a2 : unsigned(12 downto 0);

variable s0 : signed(12 downto 0);
variable s1 : signed(12 downto 0);
variable s2 : signed(12 downto 0);

variable t0 : signed(12 downto 0);
variable t1 : signed(12 downto 0);
variable t2 : signed(12 downto 0);

-- Used to vary ADD/SUB procedure
variable mdr_sign : std_logic;
variable acc_sign : std_logic;
variable negate_result : std_logic;

variable temp2 : unsigned(12 downto 0);

variable out_buf : t_buf;
variable out_idx : integer range 0 to 15;

variable temp : signed(12 downto 0);

variable carry : std_logic;

begin

if rising_edge(clk) then

	-- ####################### --
	--     STATE MACHINERY     --
	-- ####################### --
	case state is
	
		-- We pass this just once to "program" the machine
		when ROM_INIT =>
										
			rom(0) <= "0" & x"591";
			rom(1) <= "0" & x"922";
			rom(2) <= "0" & x"589";
			rom(3) <= "0" & x"922";
			rom(4) <= "0" & x"572";
			rom(5) <= "0" & x"922";
			rom(6) <= "0" & x"592";
			rom(7) <= "0" & x"922";
			rom(8) <= "0" & x"591";
			rom(9) <= "0" & x"922";
			rom(10) <= "0" & x"585";
			rom(11) <= "0" & x"922";
			rom(12) <= "0" & x"570";
			rom(13) <= "0" & x"922";
			rom(14) <= "0" & x"587";
			rom(15) <= "0" & x"922";
			rom(16) <= "0" & x"588";
			rom(17) <= "0" & x"922";
			rom(18) <= "0" & x"574";
			rom(19) <= "0" & x"922";
			rom(20) <= "0" & x"590";
			rom(21) <= "0" & x"922";
			rom(22) <= "0" & x"572";
			rom(23) <= "0" & x"922";
			rom(24) <= "0" & x"584";
			rom(25) <= "0" & x"922";
			rom(26) <= "0" & x"573";
			rom(27) <= "0" & x"922";
			rom(28) <= "0" & x"574";
			rom(29) <= "0" & x"922";
			rom(30) <= "0" & x"593";
			rom(31) <= "0" & x"922";
			rom(32) <= "0" & x"590";
			rom(33) <= "0" & x"922";
			rom(34) <= "0" & x"588";
			rom(35) <= "0" & x"922";
			rom(36) <= "0" & x"577";
			rom(37) <= "0" & x"922";
			rom(38) <= "0" & x"574";
			rom(39) <= "0" & x"922";
			rom(40) <= "0" & x"583";
			rom(41) <= "0" & x"922";
			rom(42) <= "0" & x"590";
			rom(43) <= "0" & x"922";
			rom(44) <= "0" & x"596";
			rom(45) <= "0" & x"922";
			rom(46) <= "0" & x"592";
			rom(47) <= "0" & x"922";
			rom(48) <= "0" & x"591";
			rom(49) <= "0" & x"922";
			rom(50) <= "0" & x"560";
			rom(51) <= "0" & x"268";
			rom(52) <= "0" & x"902";
			rom(53) <= "0" & x"590";
			rom(54) <= "0" & x"922";
			rom(55) <= "0" & x"595";
			rom(56) <= "0" & x"922";
			rom(57) <= "0" & x"590";
			rom(58) <= "0" & x"922";
			rom(59) <= "0" & x"901";
			rom(60) <= "0" & x"400";
			rom(61) <= "0" & x"591";
			rom(62) <= "0" & x"922";
			rom(63) <= "0" & x"560";
			rom(64) <= "0" & x"169";
			rom(65) <= "0" & x"360";
			rom(66) <= "0" & x"650";
			rom(67) <= "0" & x"000";
			rom(68) <= "0" & x"400";
			rom(69) <= "0" & x"001";
			rom(70) <= "0" & x"097";
			rom(71) <= "0" & x"098";
			rom(72) <= "0" & x"099";
			rom(73) <= "0" & x"100";
			rom(74) <= "0" & x"101";
			rom(75) <= "0" & x"102";
			rom(76) <= "0" & x"103";
			rom(77) <= "0" & x"104";
			rom(78) <= "0" & x"105";
			rom(79) <= "0" & x"106";
			rom(80) <= "0" & x"107";
			rom(81) <= "0" & x"108";
			rom(82) <= "0" & x"109";
			rom(83) <= "0" & x"110";
			rom(84) <= "0" & x"111";
			rom(85) <= "0" & x"112";
			rom(86) <= "0" & x"114";
			rom(87) <= "0" & x"115";
			rom(88) <= "0" & x"116";
			rom(89) <= "0" & x"119";
			rom(90) <= "0" & x"032";
			rom(91) <= "0" & x"013";
			rom(92) <= "0" & x"033";
			rom(93) <= "0" & x"044";
			rom(94) <= "0" & x"045";
			rom(95) <= "0" & x"062";
			rom(96) <= "0" & x"035";

			state <= INIT;
			
		when INIT =>
		
			state <= FETCH;
			rstate <= RAM_INIT;
			iostate <= IO_INIT;
			
			negate_result := '0';
			
			PC <= to_unsigned(0, 8);
			ACC <= "0" & x"000";
			IR <= to_unsigned(0, 4);
			AR <= to_unsigned(0, 8);
			MAR <= to_unsigned(0, 8);
			MDR <=  (others => '0');
			
		when FETCH =>
		
			o_state <= x"464554";
		
			case rstate is
				when RAM_INIT =>
					MAR <= PC;
					rstate <= RAM_READ;
				when RAM_READ =>
					case bstate is
						when BOOTROM =>
							MDR <= rom(to_integer(MAR));
						when NORMAL =>
							MDR <= ram(to_integer(MAR));
					end case;
					rstate <= RAM_DONE;
				when RAM_DONE =>
				
					if PC = 99 then
						PC <= to_unsigned(0, PC'length);
					else
						PC <= PC + 1;
					end if;
					
					state <= DECODE;
					rstate <= RAM_INIT;
				when others =>
					state <= ERROR;
					
			end case;
			-- FETCH
					
		when DECODE =>
		
			o_state <= x"444543";
		
			--IR <= MDR(3:0);
			IR <= resize(shift_right(unsigned(MDR), 8) and x"F", 4);
			
			a0 := shift_right(unsigned(MDR), 0) and x"F";
			a1 := shift_right(unsigned(MDR), 4) and x"F";
			
			AR <= resize(a0, 8) + resize(a1 * 10, 8);
			
			state <= EXECUTE;
			
			-- DECODE
			
		when EXECUTE =>
		
			o_state <= x"455845";
		
			if IR = 0 then -- HLT
			
				state <= HALTED;
				
			elsif IR = 1 then -- ADD
				case rstate is
					when RAM_INIT =>
						MAR <= AR;
						rstate <= RAM_READ;
						
					when RAM_READ =>
						case bstate is
							when BOOTROM =>
								MDR <= rom(to_integer(MAR));
							when NORMAL =>
								MDR <= ram(to_integer(MAR));
						end case;
						rstate <= RAM_DONE;
					when RAM_DONE =>
					
						acc_sign := ACC(12);
						mdr_sign := MDR(12);
						
						if (acc_sign = '0') and (mdr_sign = '1') then
						
							MDR(12) <= '0';
							IR <= to_unsigned(2, IR'length);
							
						elsif (acc_sign = '1') and (mdr_sign = '0') then
						
							ACC(12) <= '0';
							negate_result := '1';
							IR <= to_unsigned(2, IR'length);
							
						elsif (acc_sign = '1') and (mdr_sign = '1') then
						
							-- Multiply both sides with -1
							ACC(12) <= '0';			-- Negate ACC
							MDR(12) <= '0';			-- Negate MDR
							negate_result := '1'; 	-- Negate result
							
						elsif (acc_sign = '0') and (mdr_sign = '0') then --normal
						
								-- Just continue
							a0 := (shift_right(unsigned(ACC), 0)  and x"F") + (shift_right(unsigned(MDR), 0) and x"F");
							a1 := (shift_right(unsigned(ACC), 4)  and x"F") + (shift_right(unsigned(MDR), 4) and x"F");
							a2 := (shift_right(unsigned(ACC), 8)  and x"F") + (shift_right(unsigned(MDR), 8) and x"F");
							
							carry := '0';
							
							if a0 > 9 then
								a1 := a1 + 1;
							end if;
							
							if a1 > 9 then
								a2 := a2 + 1;
							end if;
							
							if a2 > 9 then
								carry := '1';
							end if;
							
							-- This is like doing modulus ten on all of them.
							a0 := tens_remainder(a0);
							a1 := tens_remainder(a1);
							a2 := tens_remainder(a2);
							
							if carry = '1' then
								a0 := 9 - a0;
								a1 := 9 - a1;
								a2 := (9 - a2);-- or ("0" & x"010");
							end if;
							
							negate_result := carry xor negate_result;
							
							if negate_result = '1' then
								a2 := a2 or ("0" & x"010");
							end if;
							
							ACC <= std_logic_vector(
															  a0       or
												shift_left(a1, 4)   or
												shift_left(a2, 8));
							
							state <= WRITEBACK;
						end if;
					when others =>
						state <= ERROR;
				end case;
			
			elsif IR = 2 then -- SUB
				
				case rstate is
					when RAM_INIT =>
						MAR <= AR;
						rstate <= RAM_READ;
						
					when RAM_READ =>
						case bstate is
							when BOOTROM =>
								MDR <= rom(to_integer(MAR));
							when NORMAL =>
								MDR <= ram(to_integer(MAR));
						end case;
						rstate <= RAM_DONE;
					when RAM_DONE =>
					
						acc_sign := ACC(12);
						mdr_sign := MDR(12);
						
						if (acc_sign = '0') and (mdr_sign = '1') then 
							
							MDR(12) <= '0';
							IR <= to_unsigned(1, IR'length);
							
						elsif (acc_sign = '1') and (mdr_sign = '0') then
						
							ACC(12) <= '0';
							IR <= to_unsigned(1, IR'length);
							negate_result := '1';
							
						elsif (acc_sign = '1') and (mdr_sign = '1') then 
						
							ACC(12) <= '0';
							MDR(12) <= '0';
							negate_result := '1';
							
						elsif (acc_sign = '0') and (mdr_sign = '0') then --normal
							-- Just continue
					
							s0 := signed(shift_right(unsigned(ACC), 0) and x"F");
							s1 := signed(shift_right(unsigned(ACC), 4) and x"F");
							s2 := signed(shift_right(unsigned(ACC), 8) and x"F");
							
							t0 := signed(shift_right(unsigned(MDR), 0) and x"F");
							t1 := signed(shift_right(unsigned(MDR), 4) and x"F");
							t2 := signed(shift_right(unsigned(MDR), 8) and x"F");
							
							carry := '0';
							
							if s0 - t0 < 0 then
								if s1 = 0 then
									carry := '1';
									s0 := t0 - s0;
								else
									s0 := s0 - t0 + 10;
									s1 := s1 - 1;
								end if;
							else
								s0 := s0 - t0;
							end if;
							
							if s1 - t1 < 0 then
								if s2 = 0 then
									carry := '1';
									s1 := t1 - s1;
								else
									carry := '0';
									s1 := s1 - t1 + 10;
									s2 := s2 - 1;
								end if;
							else
								s1 := s1 - t1;
								if s1 > 0 then
									carry := '0';
								end if;
							end if;
							
							if s2 - t2 < 0 then
								s2 := t2 - s2;
								carry := '1';
							else
								s2 := s2 - t2;
								if s2 > 0 then
									carry := '0';
								end if;
							end if;
						
							if negate_result = '1' then
								carry := not carry;
							end if;
							
							a0 := unsigned(s0);
							a1 := unsigned(s1);
							a2 := unsigned(s2) or ("" & carry & x"0");
							
							ACC <= std_logic_vector(
															  a0       or
												shift_left(a1, 4)   or
												shift_left(a2, 8));
						
							state <= WRITEBACK;
						end if;
					when others =>
						state <= ERROR;
				end case;
			
			elsif IR = 3 then -- STA
				
				case rstate is
					when RAM_INIT =>
						MAR <= AR;
						MDR <= ACC;
						rstate <= RAM_WRITE;
					when RAM_WRITE =>
						case bstate is
							when BOOTROM =>
								rom(to_integer(MAR)) <= std_logic_vector(ACC);
							when NORMAL =>
								ram(to_integer(MAR)) <= std_logic_vector(ACC);
						end case;	
						rstate <= RAM_DONE;
					when RAM_DONE =>
						state <= WRITEBACK;
					when others =>
						state <= ERROR;
				end case;
				
			elsif IR = 4 then -- UNDEFINED INSTRUCTION
			
				case bstate is
					when BOOTROM =>
			
						case rstate is
							when RAM_INIT =>
							
								MAR <= AR;
								MDR <= ACC;
								rstate <= RAM_WRITE;
								
							when RAM_WRITE =>
							
								ram(to_integer(MAR)) <= MDR;
								
								rstate <= RAM_DONE;
								
							when RAM_DONE =>
							
								state <= WRITEBACK;
								
							when others =>
							
								state <= ERROR;
								
						end case;

					when NORMAL =>
						state <= ERROR;
				end case;
			
			elsif IR = 5 then -- LDA
			
				case rstate is
					when RAM_INIT =>
						MAR <= AR;
						rstate <= RAM_READ;
					when RAM_READ =>
						case bstate is
							when BOOTROM =>
								MDR <= rom(to_integer(MAR));
							when NORMAL =>
								MDR <= ram(to_integer(MAR));
						end case;
						rstate <= RAM_DONE;
					when RAM_DONE =>
						ACC <= MDR;
						state <= WRITEBACK;
					when others =>
						state <= ERROR;
				end case;
			
			elsif IR = 6 then -- BRA
				
				PC <= AR;
				state <= WRITEBACK;
			
			elsif IR = 7 then -- BRZ
			
				a0 := shift_right(unsigned(ACC), 0) and x"F";
				a1 := shift_right(unsigned(ACC), 4) and x"F";
				a2 := shift_right(unsigned(ACC), 8) and x"F";
				
				temp := signed(a0 + resize(a1 * 10, 13) + resize(a2 * 100, 13) );
				
				if ACC(12) = '1' then
					temp := 0 - temp;
				end if;
				
				if temp = 0 then
					PC <= AR;
				end if;
				
				a0 := tens_remainder(a0);
				
				state <= WRITEBACK;
			
			elsif IR = 8 then -- BRP
			
				a0 := shift_right(unsigned(ACC), 0) and x"F";
				a1 := shift_right(unsigned(ACC), 4) and x"F";
				a2 := shift_right(unsigned(ACC), 8) and x"F";
				
				temp := signed(a0 + resize(a1 * 10, 13) + resize(a2 * 100, 13) );
				
				if ACC(12) = '1' then
					temp := 0 - temp;
				end if;
				
				if temp >= 0 then
					PC <= AR;
				end if;
				
				state <= WRITEBACK;
			
			elsif IR = 9 then
			
				if AR = 2 then -- OUT
					
					case iostate is
					
						when IO_INIT =>
						
							out_buf(2) := 48 + resize(shift_right(unsigned(ACC), 8) and x"F", 8);
							out_buf(1) := 48 + resize(shift_right(unsigned(ACC), 4) and x"F", 8);
							out_buf(0) := 48 + resize(shift_right(unsigned(ACC), 0) and x"F", 8);
							
							-- Sign bit check
							if ACC(12) = '1' and not (ACC(11 downto 0) = x"000") then
								o_data <= std_logic_vector(to_unsigned(45, 8));
								out_idx := integer(3);
							else
								o_data <= std_logic_vector(out_buf(integer(2)));
								out_idx := integer(2);
							end if;
							
							o_valid <= '1';
				
							iostate <= O_WFI;
							
						when IO_RETRY =>
						
							o_data <= std_logic_vector(out_buf(out_idx));
							o_valid <= '1';
							
							iostate <= O_WFI;
							
						when O_WFI =>
							
							o_valid <= '1';
		
							if irq_iow = '1' then
								iostate <= O_ACK;
							end if;
							
						when O_ACK =>
						
							o_valid <= '0';
							ack_iow <= '1';
						
							if irq_iow = '0' then
								iostate <= O_DONE;
								
							end if;
					
						when O_DONE =>
						
							ack_iow <= '0';
							
							if out_idx = 0 then
								state <= WRITEBACK;
							end if;
							
							out_idx := out_idx - 1;
							
							iostate <= IO_RETRY;
						
						when others =>
							state <= ERROR;
					end case;
					
				elsif AR = 22 then -- OTC
					case iostate is
						when IO_INIT =>
						
							out_buf(2) := resize(100 * resize(shift_right(unsigned(ACC), 8) and x"F", 8), 8);
							out_buf(1) := resize( 10 * resize(shift_right(unsigned(ACC), 4) and x"F", 8), 8);
							out_buf(0) := resize(             shift_right(unsigned(ACC), 0) and x"F", 8);
						
							o_data <= std_logic_vector(out_buf(2) + out_buf(1) + out_buf(0));
				
							iostate <= O_WFI;
							
						when O_WFI =>
							
							o_valid <= '1';
		
							if irq_iow = '1' then
								iostate <= O_ACK;
							end if;
							
						when O_ACK =>
						
							o_valid <= '0';
							ack_iow <= '1';
						
							if irq_iow = '0' then
								iostate <= O_DONE;
								
							end if;
					
						when O_DONE =>
						
							ack_iow <= '0';
							state <= WRITEBACK;
						
						when others =>
							state <= ERROR;
					end case;
					
				elsif AR = 1 then -- INP
				
					case iostate is
						when IO_INIT =>
										
							iostate <= I_WFI;
							
							inp_idx := integer(0);
							inp_buf := (others => (to_unsigned(0, 8)));
							
						when I_WFI =>
		
							if irq_ior = '1' then
								iostate <= I_ACK;
								ibuf := unsigned(i_data);
							end if;

						when I_ACK =>
						
							ack_ior <= '1';
						
							if irq_ior = '0' then
								iostate <= I_DONE;
							end if;
					
						when I_DONE =>
						
							ack_ior <= '0';
							
							if (inp_idx = 0) and (ibuf = 45) then -- minus '-'
								
								inp_buf(integer(3)) := x"01";
								
								o_data <= std_logic_vector(ibuf);
								
								iostate <= O_WFI;
								
							elsif (inp_idx = 0) and (ibuf = 35) and (bstate = BOOTROM) then -- #
								
								o_data <= x"0d";
								iostate <= O_WFI;
								
							elsif (ibuf >= 48) and (ibuf <= 57) and (inp_idx <= 3) then -- num \in[0,9]
							
								inp_buf(0) := inp_buf(1);
								inp_buf(1) := inp_buf(2);
								
								inp_buf(2) := ibuf - 48;
								inp_idx := inp_idx + 1;
								
								o_data <= std_logic_vector(ibuf);
								
								iostate <= O_WFI;
								
							-- CR accepted when we have the - and at least one digit
							elsif ibuf = 13 and inp_idx > 0 then
							
								o_data <= std_logic_vector(ibuf);
								inp_idx := integer(3);
								
								iostate <= O_WFI;
							else
								iostate <= I_WFI;
							end if;
							
						when O_WFI =>
							
							o_valid <= '1';
		
							if irq_iow = '1' then
								iostate <= O_ACK;
							end if;
							
						when O_ACK =>
						
							o_valid <= '0';
							ack_iow <= '1';
						
							if irq_iow = '0' then
								iostate <= O_DONE;
								
							end if;
						
						when O_DONE =>
						
							ack_iow <= '0';
							
							if (ibuf = 35) then
								
								state  <= INIT;
								bstate <= NORMAL;
								
							elsif inp_idx = 3 then
								
								ACC <= std_logic_vector(
											           resize(inp_buf(2), 13)       or
											shift_left(resize(inp_buf(1), 13), 4)   or
											shift_left(resize(inp_buf(0), 13), 8)   or
											shift_left(resize(inp_buf(3), 13), 12));
								
								state <= WRITEBACK;
							else
								iostate <= I_WFI;
							end if;
						
						when others =>
							
					end case;
				
				else
					state <= ERROR;
				end if;
			end if;
			
		when WRITEBACK =>
		
			o_state <= x"574220";
			
			negate_result := '0';
			
			state <= FETCH;
			rstate <= RAM_INIT;
			iostate <= IO_INIT;
			
			-- WRITEBACK
			
		when HALTED =>
			o_state <= x"484C54";
		when ERROR =>
			o_state <= x"455252";
			
	end case;
	
end if;

o_pc <= bin_to_dec(PC);
o_acc <= ACC;
o_mar <= bin_to_dec(MAR);
o_mdr <= MDR;
o_ir <= std_logic_vector(IR);
o_ar <= bin_to_dec(AR);

--debug <= ACC(7 downto 0);--std_logic_vector(PC);

end process;

end rtl;