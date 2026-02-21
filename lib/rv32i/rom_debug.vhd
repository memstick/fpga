library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library riscv_common;
use riscv_common.rv32i_global.all;

package rv32i_rom_debug is
    function rv32i_encode_load(
        offset : in integer range -2047 to 2048;
        rs1    : in integer range 0 to 31;
        funct3 : in integer range 0 to 2;
        extend : in std_logic;
        rd     : in integer range 0 to 31
    ) return std_logic_vector;

    function rv32i_encode_store(
        offset : in integer range -2047 to 2048;
        rs2    : in integer range 0 to 31;
        rs1    : in integer range 0 to 31;
        funct3 : in integer range 0 to 2
    ) return std_logic_vector;

    function rv32i_encode_addi(
        imm    : in integer range -2047 to 2048;
        rs1    : in integer range 0 to 31;
        rd     : in integer range 0 to 31
    ) return std_logic_vector;

    function rv32i_encode_lui(
        imm    : in std_logic_vector(31 downto 0);
        rd     : in integer range 0 to 31
    ) return std_logic_vector;

    function rv32i_encode_jal(
        imm    : in integer range -1048575 to 1048576;
        rd     : in integer range 0 to 31
    ) return std_logic_vector;

    function rv32i_encode_cbranch(
        imm    : in integer range -4096 to 4095;
        rs1    : in integer range 0 to 31;
        rs2    : in integer range 0 to 31;
        funct3 : in integer range 0 to 7
    ) return std_logic_vector;
end package;

package body rv32i_rom_debug is
    function rv32i_encode_load(
        offset : in integer range -2047 to 2048;
        rs1    : in integer range 0 to 31;
        funct3 : in integer range 0 to 2;
        extend : in std_logic;
        rd     : in integer range 0 to 31
    ) return std_logic_vector is
        variable bytecode : std_logic_vector(31 downto 0);
    begin
        bytecode(31 downto 20) := std_logic_vector(to_signed(offset, 12));
        bytecode(19 downto 15) := std_logic_vector(to_unsigned(rs1, 5));
        bytecode(14)           := extend;
        bytecode(13 downto 12) := std_logic_vector(to_unsigned(funct3, 2));
        bytecode(11 downto 7)  := std_logic_vector(to_unsigned(rd, 5));
        bytecode(6 downto 0)   := rv32i_l;
        return bytecode;
    end;

    function rv32i_encode_store(
        offset : in integer range -2047 to 2048;
        rs2    : in integer range 0 to 31;
        rs1    : in integer range 0 to 31;
        funct3 : in integer range 0 to 2
    ) return std_logic_vector is
        variable bytecode : std_logic_vector(31 downto 0);
        variable temp     : std_logic_vector(11 downto 0);
    begin
        temp := std_logic_vector(to_signed(offset, 12));
        bytecode(31 downto 25) := temp(11 downto 5);
        bytecode(24 downto 20) := std_logic_vector(to_unsigned(rs2, 5));
        bytecode(19 downto 15) := std_logic_vector(to_unsigned(rs1, 5));
        bytecode(14)           := '0';
        bytecode(13 downto 12) := std_logic_vector(to_unsigned(funct3, 2));
        bytecode(11 downto 7)  := temp(4 downto 0);
        bytecode(6 downto 0)   := rv32i_s;
        return bytecode;
    end;

    function rv32i_encode_addi(
        imm    : in integer range -2047 to 2048;
        rs1    : in integer range 0 to 31;
        rd     : in integer range 0 to 31
    ) return std_logic_vector is
        variable bytecode : std_logic_vector(31 downto 0);
    begin
        bytecode(31 downto 20) := std_logic_vector(to_signed(imm, 12));
        bytecode(19 downto 15) := std_logic_vector(to_unsigned(rs1, 5));
        bytecode(14 downto 12) := "000";
        bytecode(11 downto 7)  := std_logic_vector(to_unsigned(rd, 5));
        bytecode(6 downto 0)   := rv32i_compi;
        return bytecode;
    end;

    function rv32i_encode_lui(
        imm    : in std_logic_vector(31 downto 0);
        rd     : in integer range 0 to 31
    ) return std_logic_vector is
        variable bytecode : std_logic_vector(31 downto 0);
    begin
        bytecode(31 downto 12) := imm(31 downto 12);
        bytecode(11 downto 7)  := std_logic_vector(to_unsigned(rd, 5));
        bytecode(6 downto 0)   := rv32i_lui;
        return bytecode;
    end;

    function rv32i_encode_jal(
        imm    : in integer range -1048575 to 1048576;
        rd     : in integer range 0 to 31
    ) return std_logic_vector is
        variable bytecode : std_logic_vector(31 downto 0);
        variable temp     : std_logic_vector(20 downto 0);
    begin
        temp := std_logic_vector(to_signed(imm, 21));
        bytecode(31)          := temp(20);
        bytecode(30 downto 21):= temp(10 downto 1);
        bytecode(20)          := temp(11);
        bytecode(19 downto 12):= temp(19 downto 12);
        bytecode(11 downto 7) := std_logic_vector(to_unsigned(rd, 5));
        bytecode(6 downto 0)  := rv32i_jal;
        return bytecode;
    end;

    function rv32i_encode_cbranch(
        imm    : in integer range -4096 to 4095;
        rs1    : in integer range 0 to 31;
        rs2    : in integer range 0 to 31;
        funct3 : in integer range 0 to 7
    ) return std_logic_vector is
        variable bytecode : std_logic_vector(31 downto 0);
        variable temp     : std_logic_vector(12 downto 0);
    begin
        temp := std_logic_vector(to_signed(imm, 13));
        bytecode(31)          := temp(12);
        bytecode(7)           := temp(11);
        bytecode(30 downto 25):= temp(10 downto 5);
        bytecode(11 downto 8) := temp(4 downto 1);
        bytecode(24 downto 20):= std_logic_vector(to_unsigned(rs2, 5));
        bytecode(19 downto 15):= std_logic_vector(to_unsigned(rs1, 5));
        bytecode(14 downto 12):= std_logic_vector(to_unsigned(funct3, 3));
        bytecode(6 downto 0)  := rv32i_b;
        return bytecode;
    end;
end package body;

-- Example hand-assembled ROM (copied from the old rom.vhd for debugging):
--  0  => rv32i_encode_lui((31 => '1', others => '0'), 5),
--  1  => rv32i_encode_addi(72, 0, 4),          -- imm, rs1, rd
--  2  => rv32i_encode_store(0, 4, 5, 2),       -- imm[offset],rs2[src],rs1[base],funct3[2:4B,1:2B,0:1B]
--  3  => rv32i_encode_addi(101, 0, 4),
--  4  => rv32i_encode_store(4, 4, 5, 2),
--  5  => rv32i_encode_addi(105, 0, 4),
--  6  => rv32i_encode_store(8, 4, 5, 2),
--  7  => rv32i_encode_addi(44, 0, 4),
--  8  => rv32i_encode_store(12, 4, 5, 2),
--  9  => rv32i_encode_addi(32, 0, 4),
-- 10  => rv32i_encode_store(16, 4, 5, 2),
-- 11  => rv32i_encode_addi(118, 0, 4),
-- 12  => rv32i_encode_store(20, 4, 5, 2),
-- 13  => rv32i_encode_addi(101, 0, 4),
-- 14  => rv32i_encode_store(24, 4, 5, 2),
-- 15  => rv32i_encode_addi(114, 0, 4),
-- 16  => rv32i_encode_store(28, 4, 5, 2),
-- 17  => rv32i_encode_addi(100, 0, 4),
-- 18  => rv32i_encode_store(32, 4, 5, 2),
-- 19  => rv32i_encode_addi(101, 0, 4),
-- 20  => rv32i_encode_store(36, 4, 5, 2),
-- 21  => rv32i_encode_addi(110, 0, 4),
-- 22  => rv32i_encode_store(40, 4, 5, 2),
-- 23  => rv32i_encode_addi(33, 0, 4),
-- 24  => rv32i_encode_store(44, 4, 5, 2),
-- 25  => rv32i_encode_addi(94, 0, 4),          -- imm, rs1, rd
-- 26  => rv32i_encode_store(48, 4, 0, 2),       -- imm[offset],rs2[src],rs1[base],funct3[2:4B,1:2B,0:1B]
-- 27  => rv32i_encode_load(12, 0, 2, '0', 4),   -- imm[offset],         rs1[base],funct3,extend?,rd
-- 28  => rv32i_encode_store(160, 4, 5, 2),      -- imm[offset],rs2[src],rs1[base],funct3[2:4B,1:2B,0:1B]
-- 29  => rv32i_encode_store(164, 4, 5, 2),      -- imm[offset],rs2[src],rs1[base],funct3[2:4B,1:2B,0:1B]
-- 30  => rv32i_encode_addi(47, 0, 4),           -- imm, rs1, rd
-- 31  => rv32i_encode_store(168, 4, 5, 2),      -- imm[offset],rs2[src],rs1[base],funct3[2:4B,1:2B,0:1B]
-- 32  => rv32i_encode_lui((19 => '1', others => '0'), 1), -- Num cycles before break
-- 33  => rv32i_encode_addi(0, 0, 2), -- Our cycle count before increment
-- 34  => rv32i_encode_addi(58, 0, 3), -- End of count
-- 35  => rv32i_encode_addi(48, 0, 4), -- Current decimal
-- 36  => rv32i_encode_addi(47, 0, 6),
-- 37  => rv32i_encode_store(4, 6, 0, 1), -- here
-- 38  => rv32i_encode_addi(124, 0, 6),
-- 39  => rv32i_encode_store(168, 6, 5, 2),
-- 40  => rv32i_encode_load(4, 0, 2, '0', 7),
-- 41  => rv32i_encode_store(4, 6, 0, 1), -- here
-- 42  => rv32i_encode_addi(0, 7, 6),
-- 43  => rv32i_encode_store(136, 4, 5, 2),
-- 44  => rv32i_encode_addi(1, 4, 4),           -- Increment
-- 45  => rv32i_encode_cbranch(20 , 3, 4, 0 ),   -- A: BEQ
-- 46  => rv32i_encode_addi(1, 2, 2),           -- inc cycle counter
-- 47  => rv32i_encode_cbranch(-4 , 1, 2, 1 ),   -- B: BNE
-- 48  => rv32i_encode_addi(0, 0, 2),           -- Restore cycle counter
-- 49  => rv32i_encode_jal(-40, 0),
-- 50  => rv32i_encode_addi(48, 0, 4),
-- 51  => rv32i_encode_jal(-20, 0),
-- 52  => x"00000000",
