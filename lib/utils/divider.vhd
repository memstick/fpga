library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity divider is
    port (
        clock : in  std_logic;
        q     : out std_logic_vector(24 downto 0)
    );
end entity;

architecture rtl of divider is
    signal count : unsigned(24 downto 0) := (others => '0');
begin
    process(clock)
    begin
        if rising_edge(clock) then
            count <= count + 1;
        end if;
    end process;

    q <= std_logic_vector(count);
end architecture;
