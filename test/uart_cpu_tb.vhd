library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

library utils;

entity uart_cpu_tb is
end entity uart_cpu_tb;

architecture tb of uart_cpu_tb is
  constant CLK_PERIOD : time := 83.333 ns; -- 12 MHz

  signal clk_uart : std_logic := '0';
  signal clk_cpu  : std_logic := '0';
  signal reset    : std_logic := '1';

  signal rxd : std_logic := '1';
  signal txd : std_logic;

  signal addr : std_logic_vector(31 downto 0) := (others => '0');
  signal data_bus : std_logic_vector(31 downto 0) := (others => 'Z');
  signal data_drive : std_logic_vector(31 downto 0) := (others => '0');
  signal data_drive_en : std_logic := '0';
  signal rw   : std_logic := '0';
  signal rreq : std_logic := '0';
  signal rack : std_logic;

  procedure bus_write(
    signal addr_s : out std_logic_vector(31 downto 0);
    signal rw_s : out std_logic;
    signal data_drive_s : out std_logic_vector(31 downto 0);
    signal data_drive_en_s : out std_logic;
    signal rreq_s : out std_logic;
    signal rack_s : in std_logic;
    signal clk_s : in std_logic;
    constant a : in std_logic_vector(31 downto 0);
    constant d : in std_logic_vector(31 downto 0)) is
  begin
    addr_s <= a;
    rw_s <= '1';
    data_drive_s <= d;
    data_drive_en_s <= '1';
    rreq_s <= '1';

    loop
      wait until rising_edge(clk_s);
      exit when rack_s = '1';
    end loop;

    rreq_s <= '0';
    data_drive_en_s <= '0';
    wait until rising_edge(clk_s);
  end procedure;

  procedure bus_read(
    signal addr_s : out std_logic_vector(31 downto 0);
    signal rw_s : out std_logic;
    signal data_drive_en_s : out std_logic;
    signal rreq_s : out std_logic;
    signal rack_s : in std_logic;
    signal clk_s : in std_logic;
    signal data_bus_s : in std_logic_vector(31 downto 0);
    constant a : in std_logic_vector(31 downto 0);
    variable d : out std_logic_vector(31 downto 0)) is
  begin
    addr_s <= a;
    rw_s <= '0';
    data_drive_en_s <= '0';
    rreq_s <= '1';

    loop
      wait until rising_edge(clk_s);
      exit when rack_s = '1';
    end loop;

    wait for 0 ns;
    d := data_bus_s;

    rreq_s <= '0';
    wait until rising_edge(clk_s);
  end procedure;

  procedure wait_for_rd_valid(
    signal addr_s : out std_logic_vector(31 downto 0);
    signal rw_s : out std_logic;
    signal data_drive_en_s : out std_logic;
    signal rreq_s : out std_logic;
    signal rack_s : in std_logic;
    signal clk_s : in std_logic;
    signal data_bus_s : in std_logic_vector(31 downto 0)) is
    variable ctrl : std_logic_vector(31 downto 0);
    variable tries : integer := 0;
  begin
    loop
      bus_read(addr_s, rw_s, data_drive_en_s, rreq_s, rack_s, clk_s, data_bus_s, x"00000000", ctrl);
      exit when ctrl(1) = '1';
      wait for 50 us;
      tries := tries + 1;
      if tries > 200 then
        assert false report "Timeout waiting for rd_valid" severity failure;
      end if;
    end loop;
  end procedure;

  procedure wait_for_wr_ready(
    signal addr_s : out std_logic_vector(31 downto 0);
    signal rw_s : out std_logic;
    signal data_drive_en_s : out std_logic;
    signal rreq_s : out std_logic;
    signal rack_s : in std_logic;
    signal clk_s : in std_logic;
    signal data_bus_s : in std_logic_vector(31 downto 0)) is
    variable ctrl : std_logic_vector(31 downto 0);
    variable tries : integer := 0;
  begin
    loop
      bus_read(addr_s, rw_s, data_drive_en_s, rreq_s, rack_s, clk_s, data_bus_s, x"00000000", ctrl);
      exit when ctrl(0) = '0';
      wait for 50 us;
      tries := tries + 1;
      if tries > 200 then
        assert false report "Timeout waiting for wr_ready" severity failure;
      end if;
    end loop;
  end procedure;

  procedure wait_for_wr_busy(
    signal addr_s : out std_logic_vector(31 downto 0);
    signal rw_s : out std_logic;
    signal data_drive_en_s : out std_logic;
    signal rreq_s : out std_logic;
    signal rack_s : in std_logic;
    signal clk_s : in std_logic;
    signal data_bus_s : in std_logic_vector(31 downto 0)) is
    variable ctrl : std_logic_vector(31 downto 0);
    variable tries : integer := 0;
  begin
    loop
      bus_read(addr_s, rw_s, data_drive_en_s, rreq_s, rack_s, clk_s, data_bus_s, x"00000000", ctrl);
      exit when ctrl(0) = '1';
      wait for 50 us;
      tries := tries + 1;
      if tries > 200 then
        assert false report "Timeout waiting for wr_busy" severity failure;
      end if;
    end loop;
  end procedure;

begin
  data_bus <= data_drive when data_drive_en = '1' else (others => 'Z');
  rxd <= txd; -- loopback

  clk_uart <= not clk_uart after CLK_PERIOD / 2;
  clk_cpu  <= not clk_cpu  after CLK_PERIOD / 2;

  uut : entity utils.uart_cpu
    port map (
      clk_uart => clk_uart,
      rxd      => rxd,
      txd      => txd,
      clk_cpu  => clk_cpu,
      reset    => reset,
      addr     => addr,
      data     => data_bus,
      rw       => rw,
      rreq     => rreq,
      rack     => rack
    );

  stim : process
    variable rd_data : std_logic_vector(31 downto 0);
  begin
    -- hold reset for a few cycles
    wait until rising_edge(clk_cpu);
    wait until rising_edge(clk_cpu);
    wait until rising_edge(clk_cpu);
    reset <= '0';
    wait until rising_edge(clk_cpu);

    -- write first byte and wait for it to be received
    wait_for_wr_ready(addr, rw, data_drive_en, rreq, rack, clk_cpu, data_bus);
    bus_write(addr, rw, data_drive, data_drive_en, rreq, rack, clk_cpu, x"00000008", x"00000055");
    wait_for_wr_busy(addr, rw, data_drive_en, rreq, rack, clk_cpu, data_bus);
    wait_for_rd_valid(addr, rw, data_drive_en, rreq, rack, clk_cpu, data_bus);
    bus_read(addr, rw, data_drive_en, rreq, rack, clk_cpu, data_bus, x"00000004", rd_data);
    assert rd_data(7 downto 0) = x"55"
      report "UART loopback mismatch on byte 0" severity failure;

    -- write second byte and wait for it to be received
    wait_for_wr_ready(addr, rw, data_drive_en, rreq, rack, clk_cpu, data_bus);
    bus_write(addr, rw, data_drive, data_drive_en, rreq, rack, clk_cpu, x"00000008", x"000000A3");
    wait_for_wr_busy(addr, rw, data_drive_en, rreq, rack, clk_cpu, data_bus);
    wait_for_rd_valid(addr, rw, data_drive_en, rreq, rack, clk_cpu, data_bus);
    bus_read(addr, rw, data_drive_en, rreq, rack, clk_cpu, data_bus, x"00000004", rd_data);
    assert rd_data(7 downto 0) = x"A3"
      report "UART loopback mismatch on byte 1" severity failure;

    -- ensure read-valid clears
    wait for 200 us;
    bus_read(addr, rw, data_drive_en, rreq, rack, clk_cpu, data_bus, x"00000000", rd_data);
    assert rd_data(1) = '0'
      report "UART rd_valid did not clear" severity failure;

    stop;
  end process;
end architecture tb;
