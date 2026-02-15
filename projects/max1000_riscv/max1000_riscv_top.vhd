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
    sdram_dqm : out std_logic_vector(1 downto 0);
    spi_data  : out std_logic;
    spi_clk   : out std_logic;
    spi_rs    : out std_logic;
    spi_rst   : out std_logic
  );
end entity max1000_riscv_top;

architecture rtl of max1000_riscv_top is
  signal clk_sys     : std_logic;
  signal clk_200k    : std_logic;
  signal pll_ok      : std_logic;
  signal pll_ok_sync : std_logic;
  signal pll_ok_sync_vec : std_logic_vector(0 downto 0);

  signal reset       : std_logic;
  signal reset_200k  : std_logic;
  signal reset_200k_vec : std_logic_vector(0 downto 0);
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

  signal xbar_b_addr : std_logic_vector(31 downto 0);
  signal xbar_b_data : std_logic_vector(31 downto 0);
  signal xbar_b_rreq : std_logic;
  signal xbar_b_rw   : std_logic;
  signal xbar_b_rack : std_logic;

  signal xbar_c_addr : std_logic_vector(31 downto 0);
  signal xbar_c_data : std_logic_vector(31 downto 0);
  signal xbar_c_rreq : std_logic;
  signal xbar_c_rw   : std_logic;
  signal xbar_c_rack : std_logic;
begin
  u_pll : entity work.sys_pll
    port map (
      inclk0 => clk_in,
      c0     => clk_sys,
      c1     => clk_200k,
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

  u_reset_200k_sync : entity utils.cdc_sync
    generic map (
      WIDTH  => 1,
      STAGES => 2
    )
    port map (
      clk  => clk_200k,
      din  => (0 => reset),
      dout => reset_200k_vec
    );

  -- Synchronize reset deassertion into clk_200k domain.
  reset_200k <= reset_200k_vec(0);

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
    generic map ( g_num_ports => 3 )
    port map (
      clk   => clk_sys,
      reset => reset,
      
		addr_m  => mar,
      data_m  => mdr,
      rreq_m  => rreq,
      rw_m    => rw,
      rack_m  => rack,
		
		port_match(0) 	=> "0000",
		addr_s(0) 		=> xbar_a_addr,
		data_s(0) 		=> xbar_a_data,
		rreq_s(0) 		=> xbar_a_rreq,
		rw_s(0)   		=> xbar_a_rw,
		rack_s(0) 		=> xbar_a_rack,
		
		port_match(1) 	=> "1000",
		addr_s(1) 		=> xbar_b_addr,
		data_s(1) 		=> xbar_b_data,
		rreq_s(1) 		=> xbar_b_rreq,
		rw_s(1)   		=> xbar_b_rw,
		rack_s(1) 		=> xbar_b_rack,
		
		port_match(2) 	=> "0100",
		addr_s(2) 		=> xbar_c_addr,
		data_s(2) 		=> xbar_c_data,
		rreq_s(2) 		=> xbar_c_rreq,
		rw_s(2)   		=> xbar_c_rw,
		rack_s(2) 		=> xbar_c_rack,

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

  u_rom : entity utils.rom
    port map (
      clk   => clk_sys,
      reset => reset,
      addr  => xbar_c_addr,
      rw    => xbar_c_rw,
      data  => xbar_c_data,
      rreq  => xbar_c_rreq,
      rack  => xbar_c_rack,
      debug => open
    );

  u_lcd : entity utils.spi_lcd
    port map (
      clk_200k => clk_200k,
      reset   => reset_200k,
      addr    => xbar_b_addr,
      data    => xbar_b_data,
      rw      => xbar_b_rw,
      rreq    => xbar_b_rreq,
      clk     => clk_sys,
      spi_data => spi_data,
      spi_clk  => spi_clk,
      spi_rst  => spi_rst,
      spi_rs   => spi_rs,
      rack    => xbar_b_rack,
      debug   => open
    );

  leds <= (others => '0');
end architecture rtl;
