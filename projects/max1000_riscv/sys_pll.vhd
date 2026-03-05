library ieee;
use ieee.std_logic_1164.all;

entity sys_pll is
    port (
        inclk0 : in  std_logic := '0';
        c0     : out std_logic;
        c1     : out std_logic;
        locked : out std_logic
    );
end entity;

architecture rtl of sys_pll is
begin
    c0     <= inclk0;
    c1     <= inclk0;
    locked <= '1';
end architecture;
