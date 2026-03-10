library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity resettest is
    port (
        clk_en : in  std_logic;
        clock  : in  std_logic;
        q      : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of resettest is
    signal count : unsigned(15 downto 0) := (others => '0');
begin
    process(clock)
    begin
        if rising_edge(clock) then
            if clk_en = '1' then
                count <= count + 1;
            end if;
        end if;
    end process;

    q <= std_logic_vector(count);
end architecture;
