library ieee;
use ieee.std_logic_1164.all;

library riscv_common;
use riscv_common.rv32i_global.all;

library rv32i;
library utils;

entity max1000_riscv_top is
  port (
    clk_in : in  std_logic;
    leds   : out std_logic_vector(7 downto 0)
  );
end entity max1000_riscv_top;

architecture rtl of max1000_riscv_top is
  signal clk_sys     : std_logic;
  signal pll_ok      : std_logic;
  signal pll_ok_sync : std_logic;
  signal pll_ok_sync_vec : std_logic_vector(0 downto 0);

  signal reset       : std_logic;
  signal rack        : std_logic;
  signal mar         : std_logic_vector(31 downto 0);
  signal mdr         : std_logic_vector(31 downto 0);
  signal rw          : std_logic;
  signal rreq        : std_logic;
  signal debug       : std_logic_vector(7 downto 0);
begin
  u_pll : entity work.pll15m
    port map (
      inclk0 => clk_in,
      c0     => clk_sys,
      locked => pll_ok
    );

  u_pll_lock_sync : entity utils.cdc_sync
    generic map (
      WIDTH  => 1,
      STAGES => 2
    )
    port map (
      clk  => clk_sys,
      din  => (0 => pll_ok),
      dout => pll_ok_sync_vec
    );

  -- Synchronize PLL lock into clk_sys domain to avoid metastability.
  pll_ok_sync <= pll_ok_sync_vec(0);

  u_reset : entity utils.reset
    port map (
      clk      => clk_sys,
      pll_lock => pll_ok_sync,
      reset_o  => reset
    );

  u_cpu : entity rv32i.rv32i
    port map (
      clk   => clk_sys,
      reset => reset,
      rack  => rack,
      MAR   => mar,
      MDR   => mdr,
      RW    => rw,
      rreq  => rreq,
      debug => debug
    );

  -- Simple tie-offs for now. Replace with real memory/bus later.
  rack <= '0';
  mdr  <= (others => 'Z');

  leds <= debug;
end architecture rtl;
