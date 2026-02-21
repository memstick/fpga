library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package rv32i_pkg is
    type t_cpu_state is (ROM_INIT, INIT, FETCH, DECODE, EXECUTE, WRITEBACK, HALTED, ERROR);
    type t_ram_state is (RAM_INIT, RAM_READ, RAM_READ2, RAM_WRITE, RAM_READ_DONE, RAM_WRITE_DONE);

    procedure rv32i_decode_r(
        signal mdr_i  : in  std_logic_vector(63 downto 0);
        signal funct7 : out std_logic_vector(6 downto 0);
        signal rs2    : out integer;
        signal rs1    : out integer;
        signal funct3 : out std_logic_vector(2 downto 0);
        signal rd     : out integer;
        signal op     : out std_logic_vector(6 downto 0)
    );

    procedure rv32i_decode_i(
        signal mdr_i  : in  std_logic_vector(63 downto 0);
        signal imm    : out std_logic_vector(31 downto 0);
        signal rs1    : out integer;
        signal funct3 : out std_logic_vector(2 downto 0);
        signal rd     : out integer;
        signal op     : out std_logic_vector(6 downto 0)
    );

    procedure rv32i_decode_s(
        signal mdr_i  : in  std_logic_vector(63 downto 0);
        signal imm    : out std_logic_vector(31 downto 0);
        signal rs1    : out integer;
        signal rs2    : out integer;
        signal funct3 : out std_logic_vector(2 downto 0);
        signal op     : out std_logic_vector(6 downto 0)
    );

    procedure rv32i_decode_b(
        signal mdr_i  : in  std_logic_vector(63 downto 0);
        signal imm    : out std_logic_vector(31 downto 0);
        signal rs1    : out integer;
        signal rs2    : out integer;
        signal funct3 : out std_logic_vector(2 downto 0);
        signal op     : out std_logic_vector(6 downto 0)
    );

    procedure rv32i_decode_u(
        signal mdr_i  : in  std_logic_vector(63 downto 0);
        signal imm    : out std_logic_vector(31 downto 0);
        signal rd     : out integer;
        signal op     : out std_logic_vector(6 downto 0)
    );

    procedure rv32i_decode_j(
        signal mdr_i  : in  std_logic_vector(63 downto 0);
        signal imm    : out std_logic_vector(31 downto 0);
        signal rd     : out integer;
        signal op     : out std_logic_vector(6 downto 0)
    );

    procedure rv32i_execute_lui(
        signal imm    : in  std_logic_vector(31 downto 0);
        signal gpr_rd : out std_logic_vector(31 downto 0);
        signal state  : out t_cpu_state
    );

    procedure rv32i_execute_auipc(
        signal imm    : in  std_logic_vector(31 downto 0);
        signal pc     : in  unsigned(31 downto 0);
        signal gpr_rd : out std_logic_vector(31 downto 0);
        signal state  : out t_cpu_state
    );

    procedure rv32i_execute_jal(
        signal imm    : in  std_logic_vector(31 downto 0);
        signal pc     : in  unsigned(31 downto 0);
        signal npc    : inout unsigned(31 downto 0);
        signal gpr_rd : out std_logic_vector(31 downto 0);
        signal state  : out t_cpu_state
    );

    procedure rv32i_execute_jalr(
        signal imm     : in  std_logic_vector(31 downto 0);
        signal pc      : in  unsigned(31 downto 0);
        signal gpr_rs1 : in  std_logic_vector(31 downto 0);
        signal npc     : inout unsigned(31 downto 0);
        signal gpr_rd  : out std_logic_vector(31 downto 0);
        signal state   : out t_cpu_state
    );

    procedure rv32i_execute_b(
        signal funct3  : in  std_logic_vector(2 downto 0);
        signal gpr_rs1 : in  std_logic_vector(31 downto 0);
        signal gpr_rs2 : in  std_logic_vector(31 downto 0);
        signal imm     : in  std_logic_vector(31 downto 0);
        signal pc      : in  unsigned(31 downto 0);
        signal npc     : inout unsigned(31 downto 0);
        signal state   : out t_cpu_state
    );

    procedure rv32i_execute_l(
        signal rstate  : inout t_ram_state;
        signal rreq    : out std_logic;
        signal rw      : out std_logic;
        signal mar     : out std_logic_vector(31 downto 0);
        variable offset : inout integer;
        signal read2   : inout std_logic;
        signal rack    : in  std_logic;
        signal funct3  : in  std_logic_vector(2 downto 0);
        signal imm     : in  std_logic_vector(31 downto 0);
        signal gpr_rs1 : in  std_logic_vector(31 downto 0);
        signal mdr_i   : inout std_logic_vector(63 downto 0);
        signal gpr_rd  : out std_logic_vector(31 downto 0);
        signal state   : out t_cpu_state
    );

    procedure rv32i_execute_s(
        signal rstate  : inout t_ram_state;
        signal rreq    : out std_logic;
        signal rw      : out std_logic;
        signal mar     : out std_logic_vector(31 downto 0);
        variable offset : inout integer;
        signal read2   : inout std_logic;
        signal write2  : inout std_logic;
        signal rack    : in  std_logic;
        signal funct3  : in  std_logic_vector(2 downto 0);
        signal imm     : in  std_logic_vector(31 downto 0);
        signal gpr_rs1 : in  std_logic_vector(31 downto 0);
        signal gpr_rs2 : in  std_logic_vector(31 downto 0);
        signal mdr_i   : in  std_logic_vector(63 downto 0);
        signal mdr_o   : inout std_logic_vector(63 downto 0);
        signal state   : out t_cpu_state
    );

    procedure rv32i_execute_compi(
        signal funct3  : in  std_logic_vector(2 downto 0);
        signal funct7  : in  std_logic_vector(6 downto 0);
        signal rs2     : in  integer;
        signal gpr_rs1 : in  std_logic_vector(31 downto 0);
        signal imm     : in  std_logic_vector(31 downto 0);
        signal gpr_rd  : out std_logic_vector(31 downto 0);
        signal state   : out t_cpu_state
    );

    procedure rv32i_execute_compr(
        signal funct3  : in  std_logic_vector(2 downto 0);
        signal funct7  : in  std_logic_vector(6 downto 0);
        signal gpr_rs1 : in  std_logic_vector(31 downto 0);
        signal gpr_rs2 : in  std_logic_vector(31 downto 0);
        signal gpr_rd  : out std_logic_vector(31 downto 0);
        signal state   : out t_cpu_state
    );
end package;

package body rv32i_pkg is
    procedure rv32i_decode_r(
        signal mdr_i  : in  std_logic_vector(63 downto 0);
        signal funct7 : out std_logic_vector(6 downto 0);
        signal rs2    : out integer;
        signal rs1    : out integer;
        signal funct3 : out std_logic_vector(2 downto 0);
        signal rd     : out integer;
        signal op     : out std_logic_vector(6 downto 0)
    ) is
    begin
        funct7 <= std_logic_vector(mdr_i(31 downto 25));
        rs2 <= to_integer(unsigned(mdr_i(24 downto 20)));
        rs1 <= to_integer(unsigned(mdr_i(19 downto 15)));
        funct3 <= std_logic_vector(mdr_i(14 downto 12));
        rd <= to_integer(unsigned(mdr_i(11 downto 7)));
        op <= mdr_i(6 downto 0);
    end procedure rv32i_decode_r;

    procedure rv32i_decode_i(
        signal mdr_i  : in  std_logic_vector(63 downto 0);
        signal imm    : out std_logic_vector(31 downto 0);
        signal rs1    : out integer;
        signal funct3 : out std_logic_vector(2 downto 0);
        signal rd     : out integer;
        signal op     : out std_logic_vector(6 downto 0)
    ) is
    begin
        imm <= std_logic_vector(resize(signed(mdr_i(31 downto 20)), imm'length));
        rs1 <= to_integer(unsigned(mdr_i(19 downto 15)));
        funct3 <= mdr_i(14 downto 12);
        rd <= to_integer(unsigned(mdr_i(11 downto 7)));
        op <= mdr_i(6 downto 0);
    end procedure rv32i_decode_i;

    procedure rv32i_decode_s(
        signal mdr_i  : in  std_logic_vector(63 downto 0);
        signal imm    : out std_logic_vector(31 downto 0);
        signal rs1    : out integer;
        signal rs2    : out integer;
        signal funct3 : out std_logic_vector(2 downto 0);
        signal op     : out std_logic_vector(6 downto 0)
    ) is
        variable temp : std_logic_vector(11 downto 0);
    begin
        temp := mdr_i(31 downto 25) & mdr_i(11 downto 7);
        imm <= std_logic_vector(resize(signed(temp), imm'length));
        rs1 <= to_integer(unsigned(mdr_i(19 downto 15)));
        rs2 <= to_integer(unsigned(mdr_i(24 downto 20)));
        funct3 <= mdr_i(14 downto 12);
        op <= mdr_i(6 downto 0);
    end procedure rv32i_decode_s;

    procedure rv32i_decode_b(
        signal mdr_i  : in  std_logic_vector(63 downto 0);
        signal imm    : out std_logic_vector(31 downto 0);
        signal rs1    : out integer;
        signal rs2    : out integer;
        signal funct3 : out std_logic_vector(2 downto 0);
        signal op     : out std_logic_vector(6 downto 0)
    ) is
        variable temp : std_logic_vector(12 downto 0);
    begin
        temp := mdr_i(31) & mdr_i(7) & mdr_i(30 downto 25) & mdr_i(11 downto 8) & '0';
        imm <= std_logic_vector(resize(signed(temp), imm'length));
        rs1 <= to_integer(unsigned(mdr_i(19 downto 15)));
        rs2 <= to_integer(unsigned(mdr_i(24 downto 20)));
        funct3 <= mdr_i(14 downto 12);
        op <= mdr_i(6 downto 0);
    end procedure rv32i_decode_b;

    procedure rv32i_decode_u(
        signal mdr_i  : in  std_logic_vector(63 downto 0);
        signal imm    : out std_logic_vector(31 downto 0);
        signal rd     : out integer;
        signal op     : out std_logic_vector(6 downto 0)
    ) is
        variable temp : std_logic_vector(31 downto 0);
    begin
        temp := mdr_i(31 downto 12) & x"000";
        imm <= temp;
        rd <= to_integer(unsigned(mdr_i(11 downto 7)));
        op <= mdr_i(6 downto 0);
    end procedure rv32i_decode_u;

    procedure rv32i_decode_j(
        signal mdr_i  : in  std_logic_vector(63 downto 0);
        signal imm    : out std_logic_vector(31 downto 0);
        signal rd     : out integer;
        signal op     : out std_logic_vector(6 downto 0)
    ) is
        variable temp : std_logic_vector(20 downto 0);
    begin
        temp := mdr_i(31) & mdr_i(19 downto 12) & mdr_i(20) & mdr_i(30 downto 21) & '0';
        imm <= std_logic_vector(resize(signed(temp), imm'length));
        rd <= to_integer(unsigned(mdr_i(11 downto 7)));
        op <= mdr_i(6 downto 0);
    end procedure rv32i_decode_j;

    procedure rv32i_execute_lui(
        signal imm    : in  std_logic_vector(31 downto 0);
        signal gpr_rd : out std_logic_vector(31 downto 0);
        signal state  : out t_cpu_state
    ) is
    begin
        gpr_rd <= std_logic_vector(imm);
        state <= WRITEBACK;
    end procedure rv32i_execute_lui;

    procedure rv32i_execute_auipc(
        signal imm    : in  std_logic_vector(31 downto 0);
        signal pc     : in  unsigned(31 downto 0);
        signal gpr_rd : out std_logic_vector(31 downto 0);
        signal state  : out t_cpu_state
    ) is
    begin
        gpr_rd <= std_logic_vector(unsigned(imm) + pc);
        state <= WRITEBACK;
    end procedure rv32i_execute_auipc;

    procedure rv32i_execute_jal(
        signal imm    : in  std_logic_vector(31 downto 0);
        signal pc     : in  unsigned(31 downto 0);
        signal npc    : inout unsigned(31 downto 0);
        signal gpr_rd : out std_logic_vector(31 downto 0);
        signal state  : out t_cpu_state
    ) is
    begin
        gpr_rd <= std_logic_vector(pc + 4);
        npc <= unsigned(imm) + pc;
        state <= WRITEBACK;
    end procedure rv32i_execute_jal;

    procedure rv32i_execute_jalr(
        signal imm     : in  std_logic_vector(31 downto 0);
        signal pc      : in  unsigned(31 downto 0);
        signal gpr_rs1 : in  std_logic_vector(31 downto 0);
        signal npc     : inout unsigned(31 downto 0);
        signal gpr_rd  : out std_logic_vector(31 downto 0);
        signal state   : out t_cpu_state
    ) is
    begin
        gpr_rd <= std_logic_vector(pc + 4);
        npc <= unsigned(std_logic_vector(unsigned(imm) + unsigned(gpr_rs1)) and x"FFFFFFFE");
        state <= WRITEBACK;
    end procedure rv32i_execute_jalr;

    procedure rv32i_execute_b(
        signal funct3  : in  std_logic_vector(2 downto 0);
        signal gpr_rs1 : in  std_logic_vector(31 downto 0);
        signal gpr_rs2 : in  std_logic_vector(31 downto 0);
        signal imm     : in  std_logic_vector(31 downto 0);
        signal pc      : in  unsigned(31 downto 0);
        signal npc     : inout unsigned(31 downto 0);
        signal state   : out t_cpu_state
    ) is
    begin
        case funct3 is
            when "000" => -- BEQ
                if gpr_rs1 = gpr_rs2 then
                    npc <= unsigned(imm) + pc;
                end if;
            when "001" => -- BNE
                if gpr_rs1 /= gpr_rs2 then
                    npc <= unsigned(imm) + pc;
                end if;
            when "100" => -- BLT
                if signed(gpr_rs1) < signed(gpr_rs2) then
                    npc <= unsigned(imm) + pc;
                end if;
            when "101" => -- BGE
                if signed(gpr_rs1) >= signed(gpr_rs2) then
                    npc <= unsigned(imm) + pc;
                end if;
            when "110" => -- BLTU
                if unsigned(gpr_rs1) < unsigned(gpr_rs2) then
                    npc <= unsigned(imm) + pc;
                end if;
            when "111" => -- BGEU
                if unsigned(gpr_rs1) >= unsigned(gpr_rs2) then
                    npc <= unsigned(imm) + pc;
                end if;
            when others =>
        end case;
        state <= WRITEBACK;
    end procedure rv32i_execute_b;

    procedure rv32i_execute_l(
        signal rstate  : inout t_ram_state;
        signal rreq    : out std_logic;
        signal rw      : out std_logic;
        signal mar     : out std_logic_vector(31 downto 0);
        variable offset : inout integer;
        signal read2   : inout std_logic;
        signal rack    : in  std_logic;
        signal funct3  : in  std_logic_vector(2 downto 0);
        signal imm     : in  std_logic_vector(31 downto 0);
        signal gpr_rs1 : in  std_logic_vector(31 downto 0);
        signal mdr_i   : inout std_logic_vector(63 downto 0);
        signal gpr_rd  : out std_logic_vector(31 downto 0);
        signal state   : out t_cpu_state
    ) is
    begin
        case rstate is
            when RAM_INIT =>
                rreq <= '1';
                rw <= '0';
                mar <= std_logic_vector(unsigned(imm) + unsigned(gpr_rs1)) and x"FFFFFFFC";
                offset := to_integer(shift_left(unsigned(std_logic_vector(unsigned(imm) + unsigned(gpr_rs1)) and x"00000003"), 3));
                rstate <= RAM_READ;
                read2 <= '0';
                case funct3 is
                    when "010" => -- LW
                        if offset > 0 then
                            read2 <= '1';
                        end if;
                    when "001" => -- LH
                        if offset = 24 then
                            read2 <= '1';
                        end if;
                    when "101" => -- LHU
                        if offset = 24 then
                            read2 <= '1';
                        end if;
                    when "000" => -- LB
                    when "100" => -- LBU
                    when others =>
                end case;
            when RAM_READ =>
                if rack = '1' then
                    mdr_i(31 downto 0) <= mdr_i(63 downto 32);
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
                        mar <= std_logic_vector(unsigned(imm) + unsigned(gpr_rs1) + to_unsigned(4, 32)) and x"FFFFFFFC";
                        read2 <= '0';
                        rreq <= '1';
                    else
                        case funct3 is
                            when "010" => -- LW
                                gpr_rd <= mdr_i((offset + 31) downto offset);
                            when "001" => -- LH
                                gpr_rd <= std_logic_vector(resize(signed(mdr_i((offset + 15) downto offset)), 32));
                            when "101" => -- LHU
                                gpr_rd <= x"0000" & mdr_i((offset + 15) downto offset);
                            when "000" => -- LB
                                gpr_rd <= std_logic_vector(resize(signed(mdr_i((offset + 7) downto offset)), 32));
                            when "100" => -- LBU
                                gpr_rd <= x"000000" & mdr_i((offset + 7) downto offset);
                            when others =>
                        end case;
                        state <= WRITEBACK;
                    end if;
                end if;
            when others =>
        end case;
    end procedure rv32i_execute_l;

    procedure rv32i_execute_s(
        signal rstate  : inout t_ram_state;
        signal rreq    : out std_logic;
        signal rw      : out std_logic;
        signal mar     : out std_logic_vector(31 downto 0);
        variable offset : inout integer;
        signal read2   : inout std_logic;
        signal write2  : inout std_logic;
        signal rack    : in  std_logic;
        signal funct3  : in  std_logic_vector(2 downto 0);
        signal imm     : in  std_logic_vector(31 downto 0);
        signal gpr_rs1 : in  std_logic_vector(31 downto 0);
        signal gpr_rs2 : in  std_logic_vector(31 downto 0);
        signal mdr_i   : in  std_logic_vector(63 downto 0);
        signal mdr_o   : inout std_logic_vector(63 downto 0);
        signal state   : out t_cpu_state
    ) is
    begin
        case rstate is
            when RAM_INIT =>
                rreq <= '1';
                mar <= std_logic_vector(unsigned(imm) + unsigned(gpr_rs1)) and x"FFFFFFFC";
                offset := to_integer(shift_left(unsigned(std_logic_vector(unsigned(imm) + unsigned(gpr_rs1)) and x"00000003"), 3));
                read2 <= '0';
                write2 <= '0';
                case funct3 is
                    when "000" => -- SB
                        rstate <= RAM_READ;
                        rw <= '0';
                        read2 <= '0';
                        write2 <= '0';
                        rreq <= '1';
                    when "001" => -- SH
                        if offset = 24 then
                            rstate <= RAM_READ;
                            read2 <= '1';
                            write2 <= '1';
                            rw <= '0';
                        else
                            mdr_o((offset + 15) downto offset) <= gpr_rs2(15 downto 0);
                            rstate <= RAM_WRITE;
                            rw <= '1';
                            rreq <= '1';
                        end if;
                    when "010" => -- SW
                        if offset > 0 then
                            rstate <= RAM_READ;
                            read2 <= '1';
                            write2 <= '1';
                            rw <= '0';
                        else
                            mdr_o(31 downto 0) <= gpr_rs2;
                            rstate <= RAM_WRITE;
                            rw <= '1';
                            rreq <= '1';
                        end if;
                    when others =>
                end case;
            when RAM_READ =>
                if rack = '1' then
                    mdr_o(31 downto 0) <= mdr_i(63 downto 32);
                    rstate <= RAM_READ_DONE;
                end if;
            when RAM_READ2 =>
                if rack = '1' then
                    mdr_o(63 downto 32) <= mdr_i(63 downto 32);
                    rstate <= RAM_READ_DONE;
                end if;
            when RAM_READ_DONE =>
                rreq <= '0';
                if rack = '0' then
                    if read2 = '1' then
                        rstate <= RAM_READ2;
                        mar <= std_logic_vector(unsigned(imm) + unsigned(gpr_rs1) + to_unsigned(4, 32)) and x"FFFFFFFC";
                        read2 <= '0';
                        rreq <= '1';
                    else
                        rstate <= RAM_WRITE;
                        case funct3 is
                            when "000" => -- SB
                                mdr_o((offset + 7) downto offset) <= gpr_rs2(7 downto 0);
                            when "001" => -- SH
                                mdr_o((offset + 15) downto offset) <= gpr_rs2(15 downto 0);
                            when "010" => -- SW
                                mdr_o((offset + 31) downto offset) <= gpr_rs2;
                            when others =>
                        end case;
                        mar <= std_logic_vector(unsigned(imm) + unsigned(gpr_rs1)) and x"FFFFFFFC";
                        rw <= '1';
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
                        mar <= std_logic_vector(unsigned(imm) + unsigned(gpr_rs1) + to_unsigned(4, 32)) and x"FFFFFFFC";
                        write2 <= '0';
                        rreq <= '1';
                        mdr_o(31 downto 0) <= mdr_o(63 downto 32);
                        rstate <= RAM_WRITE;
                    else
                        state <= WRITEBACK;
                    end if;
                end if;
            when others =>
        end case;
    end procedure rv32i_execute_s;

    procedure rv32i_execute_compi(
        signal funct3  : in  std_logic_vector(2 downto 0);
        signal funct7  : in  std_logic_vector(6 downto 0);
        signal rs2     : in  integer;
        signal gpr_rs1 : in  std_logic_vector(31 downto 0);
        signal imm     : in  std_logic_vector(31 downto 0);
        signal gpr_rd  : out std_logic_vector(31 downto 0);
        signal state   : out t_cpu_state
    ) is
    begin
        case funct3 is
            when "000" => -- ADDI
                gpr_rd <= std_logic_vector(unsigned(gpr_rs1) + unsigned(imm));
            when "010" => -- SLTI
                if signed(gpr_rs1) < signed(imm) then
                    gpr_rd <= (0 => '1', others => '0');
                else
                    gpr_rd <= (others => '0');
                end if;
            when "011" => -- SLTIU
                if unsigned(gpr_rs1) < unsigned(imm) then
                    gpr_rd <= (0 => '1', others => '0');
                else
                    gpr_rd <= (others => '0');
                end if;
            when "100" => -- XORI
                gpr_rd <= gpr_rs1 xor imm;
            when "110" => -- ORI
                gpr_rd <= gpr_rs1 or imm;
            when "111" => -- ANDI
                gpr_rd <= gpr_rs1 and imm;
            when "001" => -- SLLI
                gpr_rd <= std_logic_vector(unsigned(gpr_rs1) sll rs2);
            when "101" => -- SRLI / SRAI
                case funct7(5) is
                    when '0' => -- SRLI
                        gpr_rd <= std_logic_vector(unsigned(gpr_rs1) srl rs2);
                    when '1' => -- SRAI
                        gpr_rd <= std_logic_vector(shift_right(signed(gpr_rs1), rs2));
                end case;
            when others =>
        end case;
        state <= WRITEBACK;
    end procedure rv32i_execute_compi;

    procedure rv32i_execute_compr(
        signal funct3  : in  std_logic_vector(2 downto 0);
        signal funct7  : in  std_logic_vector(6 downto 0);
        signal gpr_rs1 : in  std_logic_vector(31 downto 0);
        signal gpr_rs2 : in  std_logic_vector(31 downto 0);
        signal gpr_rd  : out std_logic_vector(31 downto 0);
        signal state   : out t_cpu_state
    ) is
    begin
        case funct3 is
            when "000" => -- ADD/SUB
                case funct7(5) is
                    when '0' => -- ADD
                        gpr_rd <= std_logic_vector(unsigned(gpr_rs1) + unsigned(gpr_rs2));
                    when '1' => -- SUB
                        gpr_rd <= std_logic_vector(unsigned(gpr_rs1) - unsigned(gpr_rs2));
                end case;
            when "001" => -- SLL
                gpr_rd <= std_logic_vector(unsigned(gpr_rs1) sll to_integer(unsigned(gpr_rs2(4 downto 0))));
            when "010" => -- SLT
                if signed(gpr_rs1) < signed(gpr_rs2) then
                    gpr_rd <= (0 => '1', others => '0');
                else
                    gpr_rd <= (others => '0');
                end if;
            when "011" => -- SLTU
                if unsigned(gpr_rs1) < unsigned(gpr_rs2) then
                    gpr_rd <= (0 => '1', others => '0');
                else
                    gpr_rd <= (others => '0');
                end if;
            when "100" => -- XOR
                gpr_rd <= gpr_rs1 xor gpr_rs2;
            when "101" => -- SRL/SRA
                case funct7(5) is
                    when '0' => -- SRL
                        gpr_rd <= std_logic_vector(unsigned(gpr_rs1) srl to_integer(unsigned(gpr_rs2(4 downto 0))));
                    when '1' => -- SRA
                        gpr_rd <= std_logic_vector(shift_right(signed(gpr_rs1), to_integer(unsigned(gpr_rs2(4 downto 0)))));
                end case;
            when "110" => -- OR
                gpr_rd <= gpr_rs1 or gpr_rs2;
            when "111" => -- AND
                gpr_rd <= gpr_rs1 and gpr_rs2;
            when others =>
        end case;
        state <= WRITEBACK;
    end procedure rv32i_execute_compr;
end package body;
