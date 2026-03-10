 -- Example VHDL Package
library ieee;
use ieee.std_logic_1164.all;

package rv32i_global is
    constant rv32i_lui      : std_logic_vector(6 downto 0) := "0110111";
    constant rv32i_auipc    : std_logic_vector(6 downto 0) := "0010111";
    constant rv32i_jal      : std_logic_vector(6 downto 0) := "1101111";
    constant rv32i_jalr     : std_logic_vector(6 downto 0) := "1100111";
    constant rv32i_b        : std_logic_vector(6 downto 0) := "1100011";
    constant rv32i_l        : std_logic_vector(6 downto 0) := "0000011";
    constant rv32i_s        : std_logic_vector(6 downto 0) := "0100011";
    constant rv32i_compi    : std_logic_vector(6 downto 0) := "0010011";
    constant rv32i_compr    : std_logic_vector(6 downto 0) := "0110011";
    constant rv32i_fence    : std_logic_vector(6 downto 0) := "0001111";
    constant rv32i_system   : std_logic_vector(6 downto 0) := "1110011";
end package rv32i_global;


