library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

library riscv_common;
use riscv_common.rv32i_global.all;

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

    -- Typedefs
    type t_cpu_state IS (ROM_INIT,INIT,FETCH,DECODE,EXECUTE,WRITEBACK,HALTED,ERROR);
    type t_ram_state IS (RAM_INIT,RAM_READ,RAM_READ2,RAM_WRITE,RAM_READ_DONE,RAM_WRITE_DONE);

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
        variable size    : integer range 0 to 32;

        -- DECODING PROCEDURES

        procedure rv32i_decode_r is

        begin
            FUNCT7 <= std_logic_vector(MDR_i(31 downto 25));
            RS2 <= to_integer(unsigned(MDR_i(24 downto 20)));
            RS1 <= to_integer(unsigned(MDR_i(19 downto 15)));
            FUNCT3 <= std_logic_vector(MDR_i(14 downto 12));
            RD <= to_integer(unsigned(MDR_i(11 downto 7)));
            OP <= MDR_i(6 downto 0);
        end procedure rv32i_decode_r;

        procedure rv32i_decode_i is

        begin
            IMM <= std_logic_vector(resize(signed(MDR_i(31 downto 20)), IMM'length));
            RS1 <= to_integer(unsigned(MDR_i(19 downto 15)));
            FUNCT3 <= MDR_i(14 downto 12);
            RD <= to_integer(unsigned(MDR_i(11 downto 7)));
            OP <= MDR_i(6 downto 0);
        end procedure rv32i_decode_i;

        procedure rv32i_decode_s is

            variable temp : std_logic_vector(11 downto 0);

        begin

            temp := MDR_i(31 downto 25) & MDR_i(11 downto 7);
            IMM <= std_logic_vector(resize(signed(temp), IMM'length));
            RS1 <= to_integer(unsigned(MDR_i(19 downto 15)));
            RS2 <= to_integer(unsigned(MDR_i(24 downto 20)));
            FUNCT3 <= MDR_i(14 downto 12);
            OP <= MDR_i(6 downto 0);
        end procedure rv32i_decode_s;

        procedure rv32i_decode_b is

            variable temp : std_logic_vector(12 downto 0);

        begin

            temp := MDR_i(31) & MDR_i(7) & MDR_i(30 downto 25) & MDR_i(11 downto 8) & '0';
            IMM <= std_logic_vector(resize(signed(temp), IMM'length));
            RS1 <= to_integer(unsigned(MDR_i(19 downto 15)));
            RS2 <= to_integer(unsigned(MDR_i(24 downto 20)));
            FUNCT3 <= MDR_i(14 downto 12);
            OP <= MDR_i(6 downto 0);
        end procedure rv32i_decode_b;

        procedure rv32i_decode_u is

            variable temp : std_logic_vector(31 downto 0);

        begin

            temp := MDR_i(31 downto 12) & x"000";
            IMM <= temp;--std_logic_vector(resize(signed(temp), IMM'length));
            RD <= to_integer(unsigned(MDR_i(11 downto 7)));
            OP <= MDR_i(6 downto 0);
        end procedure rv32i_decode_u;

        procedure rv32i_decode_j is

            variable temp : std_logic_vector(20 downto 0);

        begin

            temp := MDR_i(31) & MDR_i(19 downto 12) & MDR_i(20) & MDR_i(30 downto 21) & '0';
            IMM <= std_logic_vector(resize(signed(temp), IMM'length));
            RD <= to_integer(unsigned(MDR_i(11 downto 7)));
            OP <= MDR_i(6 downto 0);
        end procedure rv32i_decode_j;

        -- EXECUTION PROCEDURES

        procedure rv32i_execute_lui is
        begin
            GPR_RD <= std_logic_vector(IMM);
            state <= WRITEBACK;
        end procedure rv32i_execute_lui;

        procedure rv32i_execute_auipc is
        begin
            GPR_RD <= std_logic_vector(unsigned(IMM) + PC);
            state <= WRITEBACK;
        end procedure rv32i_execute_auipc;

        procedure rv32i_execute_jal is

        begin

            GPR_RD <= std_logic_vector(PC+4);
            nPC <= unsigned(IMM) + PC;

            state <= WRITEBACK;

        end procedure rv32i_execute_jal;

        procedure rv32i_execute_jalr is

        begin

            GPR_RD <= std_logic_vector(PC+4);
            nPC <= unsigned(
                   std_logic_vector(unsigned(IMM) + unsigned(GPR_RS1)) and x"FFFFFFFE"
               );

            state <= WRITEBACK;

        end procedure rv32i_execute_jalr;

        procedure rv32i_execute_b is
        begin

            case funct3 is

                when "000" => -- BEQ
                    if GPR_RS1 = GPR_RS2 then
                        nPC <= unsigned(IMM) + PC;
                    end if;

                when "001" => -- BNE
                    if GPR_RS1 /= GPR_RS2 then
                        nPC <= unsigned(IMM) + PC;
                    end if;

                when "100" => -- BLT
                    if signed(GPR_RS1) < signed(GPR_RS2) then
                        nPC <= unsigned(IMM) + PC;
                    end if;

                when "101" => -- BGE
                    if signed(GPR_RS1) >= signed(GPR_RS2) then
                        nPC <= unsigned(IMM) + PC;
                    end if;

                when "110" => -- BLTU
                    if unsigned(GPR_RS1) < unsigned(GPR_RS2) then
                        nPC <= unsigned(IMM) + PC;
                    end if;

                when "111" => -- BGEU
                    if unsigned(GPR_RS1) >= unsigned(GPR_RS2) then
                        nPC <= unsigned(IMM) + PC;
                    end if;

                when others =>
            -- error
            end case;

            state <= WRITEBACK;

        end procedure rv32i_execute_b;

        procedure rv32i_execute_l is

        begin

            case rstate is
                when RAM_INIT =>

                    rreq <= '1';
                    RW   <= '0';

                    MAR <= (std_logic_vector(unsigned(IMM) + unsigned(GPR_RS1))) and x"FFFFFFFC";
                    offset := to_integer(shift_left(unsigned(std_logic_vector(unsigned(IMM) + unsigned(GPR_RS1)) and x"00000003"), 3));

                    --GPR_RD <= MDR_i;

                    rstate <= RAM_READ;

                    read2 <= '0';

                    case FUNCT3 is
                        when "010" => --LW
                            if offset > 0 then
                                read2 <= '1';
                            end if;
                        when "001" => --LH
                            if offset > 15 then
                                read2 <= '1';
                            end if;
                        when "101" => --LHU
                            if offset > 15 then
                                read2 <= '1';
                            end if;
                        when "000" => --LB
                        when "100" => --LBU
                        when others =>
                    -- Error
                    end case;

                when RAM_READ =>

                    if rack = '1' then

                        --MDR_i(31 downto 0) <= MDR_i((offset+31) downto offset);
                        MDR_i(31 downto 0) <= MDR_i(63 downto 32);

                        rstate <= RAM_READ_DONE;

                    end if;

                when RAM_READ2 =>

                    if rack = '1' then

                        rstate <= RAM_READ_DONE;

                    end if;

                when RAM_READ_DONE =>

                    rreq <= '0';

                    if rack = '0' then

                        if read2 = '1' then
                            rstate <= RAM_READ2;
                            MAR    <= (std_logic_vector(unsigned(IMM) + unsigned(GPR_RS1) + to_unsigned(4, 32))) and x"FFFFFFFC";
                            read2  <= '0';
                            rreq   <= '1';
                        else

                            case FUNCT3 is
                                when "010" => --LW
                                    GPR_RD <= MDR_i((offset + 31) downto offset);
                                when "001" => --LH
                                    GPR_RD <= std_logic_vector(resize(signed(MDR_i((offset + 15) downto offset)), 32));
                                when "101" => --LHU
                                    GPR_RD <= x"0000" & MDR_i((offset + 15) downto offset);
                                when "000" => --LB
                                    GPR_RD <= std_logic_vector(resize(signed(MDR_i((offset + 7) downto offset)), 32));
                                when "100" => --LBU
                                    GPR_RD <= x"000000" & MDR_i((offset + 7) downto offset);
                                when others =>
                            -- Error
                            end case;

                            state <= WRITEBACK;
                        end if;
                    end if;

                when others =>
            -- Error

            end case;

        end procedure rv32i_execute_l;

        procedure rv32i_execute_s is

        begin

            case rstate is
                when RAM_INIT =>

                    rreq <= '1';

                    MAR <= (std_logic_vector(unsigned(IMM) + unsigned(GPR_RS1))) and x"FFFFFFFC";
                    offset := to_integer(shift_left(unsigned(std_logic_vector(unsigned(IMM) + unsigned(GPR_RS1)) and x"00000003"), 3));

                    read2 <= '0';
                    write2 <= '0';

                    case FUNCT3 is
                        when "000" => --SB


                            --FIX : endre denne til RAM_READ og fikse logikken, vi skriver bare en av fire bytes
                            -- FIX: 
                            --MDR_o((offset + 7) downto offset) <= GPR_RS2(7 downto 0);
                            rstate <= RAM_WRITE;
                            RW   <= '1';
                            rreq <= '1';

                        when "001" => --SH

                            if offset > 16 then

                                rstate <= RAM_READ;
                                read2 <= '1';
                                write2 <= '1';
                                RW   <= '0';

                            else
                                MDR_o((offset + 15) downto offset) <= GPR_RS2(15 downto 0);
                                rstate <= RAM_WRITE;
                                RW   <= '1';
                                rreq <= '1';
                            end if;

                        when "010" => --SW
                            if offset > 0 then

                                rstate <= RAM_READ;
                                read2 <= '1';
                                write2 <= '1';
                                RW   <= '0';

                            else
                                MDR_o(31 downto 0) <= GPR_RS2;
                                rstate <= RAM_WRITE;
                                RW   <= '1';
                                rreq <= '1';
                            end if;
                        when others =>
                    end case;

                when RAM_READ =>

                    if rack = '1' then

                        MDR_o(31 downto 0) <= MDR_i(63 downto 32);

                        rstate <= RAM_READ_DONE;

                    end if;

                when RAM_READ2 =>

                    if rack = '1' then

                        MDR_o(63 downto 32) <= MDR_i(63 downto 32);

                        rstate <= RAM_READ_DONE;

                    end if;

                when RAM_READ_DONE =>

                    rreq <= '0';

                    if rack = '0' then

                        if read2 = '1' then
                            rstate <= RAM_READ2;
                            MAR    <= (std_logic_vector(unsigned(IMM) + unsigned(GPR_RS1) + to_unsigned(4, 32))) and x"FFFFFFFC";
                            read2  <= '0';
                            rreq   <= '1';
                        else
                            rstate <= RAM_WRITE;

                            case FUNCT3 is
                                when "000" => -- SB
                                    MDR_o((offset + 7) downto offset) <= GPR_RS2(7 downto 0);
                                when "001" => -- SH
                                    MDR_o((offset + 15) downto offset) <= GPR_RS2(15 downto 0);
                                when "010" => -- SW
                                    MDR_o((offset + 31) downto offset) <= GPR_RS2;
                                when others =>
                            -- Error!
                            end case;

                            MAR <= (std_logic_vector(unsigned(IMM) + unsigned(GPR_RS1))) and x"FFFFFFFC";
                            RW <= '1';
                            rreq <= '1';
                        end if;	
                    end if;

                when RAM_WRITE =>

                    if rack = '1' then
                        rstate <= RAM_WRITE_DONE;
                    end if;

                when RAM_WRITE_DONE =>

                    rreq <= '0';

                    if rack = '0' then

                        if write2 = '1' then

                            MAR    <= (std_logic_vector(unsigned(IMM) + unsigned(GPR_RS1) + to_unsigned(4, 32))) and x"FFFFFFFC";
                            write2 <= '0';
                            rreq <= '1';
                            MDR_o(31 downto 0) <= MDR_o(63 downto 32);
                            rstate <= RAM_WRITE;
                        else
                            state <= WRITEBACK;
                        end if;
                    end if;

                when others =>
            -- Error
            end case;

        end procedure rv32i_execute_s;

        procedure rv32i_execute_compi is

        begin

            case funct3 is
                when "000" => -- ADDI
                    GPR_RD <= std_logic_vector(unsigned(GPR_RS1) + unsigned(IMM));
                when "010" => -- SLTI
                    if signed(GPR_RS1) < signed(IMM) then
                        GPR_RD <= (0 => '1', others => '0');
                    end if;
                when "011" => -- SLTIU
                    if unsigned(GPR_RS1) < unsigned(IMM) then
                        GPR_RD <= (0 => '1', others => '0');
                    end if;
                when "100" => -- XORI
                    GPR_RD <= GPR_RS1 xor IMM;
                when "110" => -- ORI
                    GPR_RD <= GPR_RS1 or IMM;
                when "111" => -- ANDI
                    GPR_RD <= GPR_RS1 and IMM;
                when "001" => -- SLLI ; This and the one below I have decoded as "R" - so the amount to be shifted is in "RS2", and the imm is in FUNCT7
                    GPR_RD <= std_logic_vector(unsigned(GPR_RS1) sll RS2);
                when "101" => -- SRLI / SRAI
                    case funct7(5) is -- Bit30 of the instruction tells us the final type

                        when '0' => -- SRLI
                            GPR_RD <= std_logic_vector(unsigned(GPR_RS1) srl RS2);

                        when '1' => -- SRAI arithmetic shift
                            GPR_RD <= std_logic_vector(shift_right(signed(GPR_RS1), RS2));

                    end case;
                when others =>
            -- error!
            end case;

            state <= WRITEBACK;

        end procedure rv32i_execute_compi;

        procedure rv32i_execute_compr is
        begin

            case funct3 is

                when "000" => -- ADD/SUB

                    case funct7(5) is
                        when '0' => -- ADD
                            GPR_RD <= std_logic_vector(unsigned(GPR_RS1) + unsigned(GPR_RS2));

                        when '1' => -- SUB
                            GPR_RD <= std_logic_vector(unsigned(GPR_RS1) - unsigned(GPR_RS2));

                    end case;

                when "001" => -- SLL
                    GPR_RD <= std_logic_vector( unsigned(GPR_RS1) sll to_integer(unsigned(GPR_RS2(4 downto 0))));

                when "010" => -- SLT

                    if signed(GPR_RS1) < signed(GPR_RS2) then
                        GPR_RD <= (0 => '1', others => '0');
                    end if;

                when "011" => -- SLTU

                    if unsigned(GPR_RS1) < unsigned(GPR_RS2) then
                        GPR_RD <= (0 => '1', others => '0');
                    end if;

                when "100" => -- XOR

                    GPR_RD <= GPR_RS1 xor GPR_RS2;

                when "101" => -- SRL/SRA

                    case funct7(5) is
                        when '0' => -- SRL
                            GPR_RD <= std_logic_vector( unsigned(GPR_RS1) srl to_integer(unsigned(GPR_RS2(4 downto 0))));

                        when '1' => -- SRA
                            GPR_RD <= std_logic_vector( shift_right(signed(GPR_RS1), to_integer(unsigned(GPR_RS2(4 downto 0)))));

                    end case;

                when "110" => -- OR
                    GPR_RD <= GPR_RS1 or GPR_RS2;

                when "111" => -- AND
                    GPR_RD <= GPR_RS1 and GPR_RS2;

                when others =>
            --error		
            end case;

            state <= WRITEBACK;

        end procedure rv32i_execute_compr;

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
                                rv32i_decode_r;

                            when rv32i_compi =>

                                case MDR_i(13 downto 12) is

                                    when "01" =>
                                        rv32i_decode_r;

                                    when others =>
                                        rv32i_decode_i;

                                end case;

                            when rv32i_l | rv32i_jalr | rv32i_fence | rv32i_system =>
                                rv32i_decode_i;

                            when rv32i_s =>
                                rv32i_decode_s;

                            when rv32i_b =>
                                rv32i_decode_b;

                            when rv32i_lui | rv32i_auipc =>
                                rv32i_decode_u;

                            when rv32i_jal =>
                                rv32i_decode_j;

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
                                rv32i_execute_lui;

                            when rv32i_auipc =>
                                rv32i_execute_auipc;

                            when rv32i_jal =>
                                rv32i_execute_jal;

                            when rv32i_jalr =>
                                rv32i_execute_jalr;

                            when rv32i_b =>
                                rv32i_execute_b;

                            when rv32i_l =>
                                rv32i_execute_l;

                            when rv32i_s =>
                                rv32i_execute_s;

                            when rv32i_compi =>
                                rv32i_execute_compi;

                            when rv32i_compr =>
                                rv32i_execute_compr;

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
