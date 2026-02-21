# TODO

- Refactor crossbar interface to use VHDL records (and possibly arrays of records) to reduce port boilerplate when adding more slaves.
- Implement CPU-controlled peripheral reset release (peripheral-specific, synchronized to each clock domain).
- Decide/Document memory access convention (32-bit aligned bus vs unaligned support).
- If trapping misaligned accesses: define trap behavior (mcause/mepc/mtval or simple halt vector) and implement in RV32I core.
- Investigate 100 MHz hang (UART prints hello then stalls; memtest doesn't start).
