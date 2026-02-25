library ieee;
use ieee.std_logic_1164.all;

entity const1 is
    generic (LPM_WIDTH : natural := 1);
    port (RESULT : out std_logic_vector(LPM_WIDTH-1 downto 0));
end entity;

architecture rtl of const1 is
begin
    RESULT <= (others => '1');
end architecture;
