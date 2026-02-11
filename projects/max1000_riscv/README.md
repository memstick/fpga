# MAX1000 RISC-V project (VHDL)

Quartus project scaffold for the MAX1000 16K board with library-based VHDL layout.

## Library layout
Each subfolder under `lib/` is treated as a separate VHDL library:
- `lib/riscv_common` → library `riscv_common`
- `lib/rv32i` → library `rv32i`
- `lib/utils` → library `utils`
- `lib/sdram` → library `sdram`

This is configured in `max1000_riscv.qsf` using per-file `-library` assignments.

## Top-level
`max1000_riscv_top.vhd` instantiates:
- `sys_pll` (12 MHz → 12 MHz, 0.2 MHz)
- `rv32i` core
- `utils.crossbar` (port A → SDRAM, port C → ROM)
- `sdram.sdram_ctrl`
- `utils.rom`
- `utils.spi_lcd` (port B)

The CPU debug bus is left unconnected. The memory/bus signals are tied off and
intended to be replaced with real memory and peripherals. The LED outputs are
currently tied low.

## Adding new library files
1. Place the VHDL file under the correct `lib/` subfolder.
2. Add a `set_global_assignment -name VHDL_FILE ... -library <name>` line in the QSF.
3. Reference the library in VHDL, e.g.:
   `library utils; use utils.some_pkg.all;`

## Build (Quartus)
1. Open `max1000_riscv.qpf`.
2. Compile.
