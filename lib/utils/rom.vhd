library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity rom is
  port (
    clk   : in std_logic;
    reset : in std_logic;

    addr  : in    std_logic_vector(31 downto 0);
    rw    : in    std_logic;
    data  : inout std_logic_vector(31 downto 0);
    rreq  : in    std_logic;
    rack  : out   std_logic := '0';

    debug : out   std_logic_vector(7 downto 0)
  );
end rom;

architecture rtl of rom is

  type t_ram_state is (RAM_INIT, RAM_READ, RAM_WRITE, RAM_DONE);

  signal rstate : t_ram_state := RAM_INIT;

  signal data_o  : std_logic_vector(31 downto 0);
  signal rom_addr     : std_logic_vector(9 downto 0);
  signal rom_addr_reg : std_logic_vector(9 downto 0);
  signal rom_q    : std_logic_vector(31 downto 0);

begin

  data <= data_o when (rw = '0') else (others => 'Z');

  rom_addr <= rom_addr_reg;

  u_rom : altsyncram
    generic map (
      clock_enable_input_a => "BYPASS",
      clock_enable_output_a => "BYPASS",
      init_file => "rom.mif",
      numwords_a => 1024,
      operation_mode => "ROM",
      outdata_reg_a => "UNREGISTERED",
      widthad_a => 10,
      width_a => 32,
      width_byteena_a => 1,
      lpm_hint => "ENABLE_RUNTIME_MOD=NO",
      lpm_type => "altsyncram"
    )
    port map (
      address_a => rom_addr,
      clock0 => clk,
      rden_a => '1',
      q_a => rom_q,
      data_a => (others => '0'),
      wren_a => '0'
    );

  process(clk, reset)

    variable idx : integer range 0 to 1023;

  begin

    if falling_edge(clk) then

      if reset = '1' then
        -- Reset
        rstate <= RAM_INIT;
        rack <= '0';

        data_o <= x"00000076";

        debug <= (others => '0');

      else
        case rstate is

          when RAM_INIT =>

            if rreq = '1' then

              debug(0) <= '1';

              if rw = '0' then
                idx := to_integer(unsigned(addr(11 downto 2)));
                rom_addr_reg <= addr(11 downto 2);
              end if;

              rstate <= RAM_READ;
            end if;

          when RAM_READ =>

            if rw = '0' then
              data_o <= rom_q;
            end if;

            rack <= '1';
            rstate <= RAM_DONE;

          when RAM_DONE =>

            if rreq = '0' then
              rack <= '0';
              rstate <= RAM_INIT;
            end if;

          when others =>
            -- error
        end case;
      end if;

    end if;
  end process;

end rtl;
