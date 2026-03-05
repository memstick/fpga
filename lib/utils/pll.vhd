library ieee;
use ieee.std_logic_1164.all;

entity pll is
    port (
        inclk0  : in  std_logic;
        c0      : out std_logic;
        locked  : out std_logic
    );
end entity;

architecture rtl of pll is
begin
    -- Black box: instantiated as Altera PLL hard IP at P&R stage
    -- Yosys/nextpnr will infer the actual PLL primitive
    c0     <= inclk0;  -- passthrough placeholder
    locked <= '1';
end architecture;
