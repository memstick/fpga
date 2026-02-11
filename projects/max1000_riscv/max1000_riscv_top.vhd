library ieee;
use ieee.std_logic_1164.all;

library riscv_common;
use riscv_common.rv32i_global.all;

library rv32i;
library sdram;
library utils;

entity max1000_riscv_top is
  port (
    clk_in    : in  std_logic;
    leds      : out std_logic_vector(7 downto 0);
    sdram_a   : out std_logic_vector(13 downto 0);
    sdram_ba  : out std_logic_vector(1 downto 0);
    sdram_clk : out std_logic;
    sdram_cke : out std_logic;
    sdram_ras : out std_logic;
    sdram_cas : out std_logic;
    sdram_we  : out std_logic;
    sdram_cs  : out std_logic;
    sdram_dq  : inout std_logic_vector(15 downto 0);
    sdram_dqm : out std_logic_vector(1 downto 0)
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

  signal xbar_a_addr : std_logic_vector(31 downto 0);
  signal xbar_a_data : std_logic_vector(31 downto 0);
  signal xbar_a_rreq : std_logic;
  signal xbar_a_rw   : std_logic;
  signal xbar_a_rack : std_logic;
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
      rreq  => rreq
    );

  u_xbar : entity utils.crossbar
    port map (
      clk   => clk_sys,
      reset => reset,
      addr  => mar,
      data  => mdr,
      rreq  => rreq,
      rw    => rw,
      rack  => rack,
      a_addr => xbar_a_addr,
      a_data => xbar_a_data,
      a_rreq => xbar_a_rreq,
      a_rw   => xbar_a_rw,
      a_rack => xbar_a_rack,
      b_addr => open,
      b_data => open,
      b_rreq => open,
      b_rw   => open,
      b_rack => '0',
      c_addr => open,
      c_data => open,
      c_rreq => open,
      c_rw   => open,
      c_rack => '0',
      debug  => open
    );

  u_sdram : entity sdram.sdram_ctrl
    port map (
      clki  => clk_sys,
      addr  => xbar_a_addr,
      data  => xbar_a_data,
      rw    => xbar_a_rw,
      rreq  => xbar_a_rreq,
      reset => reset,
      A     => sdram_a,
      BA    => sdram_ba,
      CLK   => sdram_clk,
      CKE   => sdram_cke,
      RAS   => sdram_ras,
      CAS   => sdram_cas,
      WE    => sdram_we,
      CS    => sdram_cs,
      DQ    => sdram_dq,
      DQM   => sdram_dqm,
      rack  => xbar_a_rack,
      debug => open
    );

  leds <= (others => '0');
end architecture rtl;
