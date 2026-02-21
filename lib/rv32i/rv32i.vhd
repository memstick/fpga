library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

library riscv_common;
use riscv_common.rv32i_global.all;
use work.rv32i_pkg.all;

entity rv32i is
    port (

             -- Input clock
             clk        : in  std_logic;

             reset      : in std_logic;

             rack       : in std_logic;

             MAR : out std_logic_vector( 31 downto 0) := (others => '0');

             MDR : inout std_logic_vector( 31 downto 0) := (others => '0');

             RW : out std_logic := '0';

             rreq : out std_logic := '0';

             -- Generic debug port (8 bits).
             debug		: out std_logic_vector(7 downto 0) := (others => '0')

         );
end rv32i;

architecture rtl of rv32i is

    type t_reg_bank is array (0 to 31) of std_logic_vector(31 downto 0);

    -- State machine (execution cycle)
    signal state : t_cpu_state := INIT;
    signal rstate : t_ram_state := RAM_INIT;

    -- MDR I/O (tristated)
    signal MDR_i : std_logic_vector(63 downto 0) := (others => '0');
    signal MDR_o : std_logic_vector(63 downto 0) := (others => '0');

    -- Program counter
    signal PC : unsigned( 31 downto 0 );
    -- The next PC
    signal nPC : unsigned( 31 downto 0);

    -- Registers
    signal GPR : t_reg_bank := (others => (others => '0'));
    signal GPR_RD  : std_logic_vector(31 downto 0);
    signal GPR_RS1 : std_logic_vector(31 downto 0);
    signal GPR_RS2 : std_logic_vector(31 downto 0);

    -- OP code (instruction) register
    signal OP : std_logic_vector(6 downto 0) := (others => '0');

    -- Immediate register
    signal IMM : std_logic_vector(31 downto 0); --

    -- rs1 and rs2 register
    signal RS1 : integer range 0 to 31; --(4 downto 0) := (others => '0');
    signal RS2 : integer range 0 to 31; --(4 downto 0) := (others => '0');

    signal RD : integer range 0 to 31;

    -- Funct register
    signal FUNCT3 : std_logic_vector(2 downto 0) := (others => '0');
    signal FUNCT7 : std_logic_vector(6 downto 0) := (others => '0');

    --signal rack_sticky : std_logic := '0';
    --signal rack_sticky_clear : std_logic := '0';

    signal read2   : std_logic := '0';
    signal write2  : std_logic := '0';

begin

    -- I think this saves me for all that of checking on source registers
    GPR_RS1 <= (others => '0') when RS1 = 0 else GPR(RS1);
    GPR_RS2 <= (others => '0') when RS2 = 0 else GPR(RS2);
    GPR(RD) <= GPR_RD when (RD /= 0) and (state = WRITEBACK);
    --GPR(RD) <= (others => '0') when RD = 0 else GPR_RD;

    debug <= std_logic_vector(PC(9 downto 2));

    --debug(3 downto 0) <= "0000" when state = ROM_INIT else
    --			"0001" when state = INIT else
    --			"0010" when state = FETCH else
    --			"0011" when state = DECODE else
    --			"0100" when state = EXECUTE else
    --			"0101" when state = WRITEBACK else
    --			"0110" when state = HALTED else
    --			"0111" when state = ERROR else
    --			"1000";

    --debug(7) <= '1' when state = EXECUTE else '0';

    --debug(5 downto 4) <= "00" when rstate = RAM_INIT else
    --			"01" when rstate = RAM_READ else
    --			"10" when rstate = RAM_DONE else
    --			"11";
    --
    --debug(7) <= rack;
    --debug(6 downto 0) <= OP(6 downto 0);

    -- The MDR register must be tri-stated		
    MDR <= MDR_o(31 downto 0) when (rstate = RAM_WRITE) else (others => 'Z');
    MDR_i(63 downto 32) <= MDR;

    process(clk,reset)

        -- I use this to figure out where in the word to read from in load/store logic
        variable offset : integer range 0 to 63;--std_logic_vector(1 downto 0);

    begin

        if falling_edge(clk) then
            if reset = '1' then

                FUNCT3 <= (others => '0');
                FUNCT7 <= (others => '0');
                RS1 <= 0;
                RS2 <= 0;
                RD <= 0;
                IMM <= (others => '0');
                OP <= (others => '0');
                PC <= (x"40000000");
                nPC <= (others => '0');
                MDR_o <= (others => '0');
                rreq <= '0';
                RW <= '0';

                state <= ROM_INIT;
                rstate <= RAM_INIT;

            else

                -- ####################### --
                --     STATE MACHINERY     --
                -- ####################### --
                case state is

                    when ROM_INIT =>

                        state <= FETCH;

                    when FETCH =>

                        case rstate is

                            when RAM_INIT =>

                                rreq <= '1';
                                RW <= '0';
                                MAR <= std_logic_vector(PC);
                                rstate <= RAM_READ;

                            when RAM_READ =>

                                if rack = '1' then

                                    rreq <= '0';
                                    rstate <= RAM_READ_DONE;

                                    MDR_i(31 downto 0) <= MDR_i(63 downto 32);

                                end if;

                            when RAM_READ_DONE =>

                                if rack = '0' then

                                    rstate <= RAM_INIT;
                                    state <= DECODE;
                                    nPC <= PC + 4;
                                end if;

                            when others =>
                        -- Error

                        end case;

                    when DECODE =>

                        case MDR_i(6 downto 0) is

                            when rv32i_compr =>
                                rv32i_decode_r(MDR_i, FUNCT7, RS2, RS1, FUNCT3, RD, OP);

                            when rv32i_compi =>

                                case MDR_i(13 downto 12) is

                                    when "01" =>
                                        rv32i_decode_r(MDR_i, FUNCT7, RS2, RS1, FUNCT3, RD, OP);

                                    when others =>
                                        rv32i_decode_i(MDR_i, IMM, RS1, FUNCT3, RD, OP);

                                end case;

                            when rv32i_l | rv32i_jalr | rv32i_fence | rv32i_system =>
                                rv32i_decode_i(MDR_i, IMM, RS1, FUNCT3, RD, OP);

                            when rv32i_s =>
                                rv32i_decode_s(MDR_i, IMM, RS1, RS2, FUNCT3, OP);

                            when rv32i_b =>
                                rv32i_decode_b(MDR_i, IMM, RS1, RS2, FUNCT3, OP);

                            when rv32i_lui | rv32i_auipc =>
                                rv32i_decode_u(MDR_i, IMM, RD, OP);

                            when rv32i_jal =>
                                rv32i_decode_j(MDR_i, IMM, RD, OP);

                            when others =>
                                state <= WRITEBACK;
                        --error
                        end case;

                        --OP <= MDR_i(6 downto 0);

                        state <= EXECUTE;
                        rstate <= RAM_INIT;

                    when EXECUTE =>

                        case OP is
                            when rv32i_lui =>
                                rv32i_execute_lui(IMM, GPR_RD, state);

                            when rv32i_auipc =>
                                rv32i_execute_auipc(IMM, PC, GPR_RD, state);

                            when rv32i_jal =>
                                rv32i_execute_jal(IMM, PC, nPC, GPR_RD, state);

                            when rv32i_jalr =>
                                rv32i_execute_jalr(IMM, PC, GPR_RS1, nPC, GPR_RD, state);

                            when rv32i_b =>
                                rv32i_execute_b(FUNCT3, GPR_RS1, GPR_RS2, IMM, PC, nPC, state);

                            when rv32i_l =>
                                rv32i_execute_l(rstate, rreq, RW, MAR, offset, read2, rack, FUNCT3, IMM, GPR_RS1, MDR_i, GPR_RD, state);

                            when rv32i_s =>
                                rv32i_execute_s(rstate, rreq, RW, MAR, offset, read2, write2, rack, FUNCT3, IMM, GPR_RS1, GPR_RS2, MDR_i, MDR_o, state);

                            when rv32i_compi =>
                                rv32i_execute_compi(FUNCT3, FUNCT7, RS2, GPR_RS1, IMM, GPR_RD, state);

                            when rv32i_compr =>
                                rv32i_execute_compr(FUNCT3, FUNCT7, GPR_RS1, GPR_RS2, GPR_RD, state);

                            when rv32i_fence =>
                                state <= WRITEBACK;
                            -- Ignore for now

                            when rv32i_system =>
                                state <= WRITEBACK;
                            -- Ignore for now

                            when others =>

                        end case;

                    when WRITEBACK =>

                        PC <= nPC;

                        state <= FETCH;
                        rstate <= RAM_INIT;

                    when ERROR =>

                    when others =>

                end case;

            end if;

        end if;

    end process;

end rtl;
