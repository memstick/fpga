-- Example VHDL Package
 library ieee;
 use ieee.std_logic_1164.all;

 package rv32i_global is

		function rv32i_lui      return std_logic_vector;
		function rv32i_auipc    return std_logic_vector;
		function rv32i_jal      return std_logic_vector;
		function rv32i_jalr     return std_logic_vector;
		function rv32i_b        return std_logic_vector;
		function rv32i_l        return std_logic_vector;
		function rv32i_s        return std_logic_vector;
		function rv32i_compi    return std_logic_vector;
		function rv32i_compr    return std_logic_vector;
		function rv32i_fence    return std_logic_vector;
		function rv32i_system   return std_logic_vector;

 end package rv32i_global;

 package body rv32i_global is
	  
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
 end package body rv32i_global;