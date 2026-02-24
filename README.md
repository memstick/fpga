# FPGA projects

This repo contains small FPGA projects, demos, and reusable blocks.

## Dependencies (install once)
### General
- Git + Git LFS (docs PDFs are stored via LFS).
- Python 3 (used by ROM/MIF generators).
- Make, Bash.

### FPGA toolchain (MAX1000)
- Quartus Prime (Lite is fine) with **MAX 10** device support.
- Device part used by this repo: **10M16SAU169C8G**.
- On Windows/macOS/Linux, ensure Quartus programmer is installed for board flashing.

### Simulation (optional)
- NVC (VHDL simulator).
- UVVM sources (tracked as a git submodule).

### Firmware toolchains (optional)
- RISC-V GNU toolchain in `/opt/riscv/bin` (for C demos):
  - expects `riscv32-unknown-elf-gcc`, `riscv32-unknown-elf-objcopy`, `riscv32-unknown-elf-objdump`, `riscv32-unknown-elf-readelf`.
- Rust toolchain (for Rust demos):
  - `rustup`, `rustc`, and target `riscv32i-unknown-none-elf`.
  - `llvm-tools-preview` component (provides `llvm-objcopy/objdump/readelf`).

## Quick setup
1) Clone with submodules and LFS:
   - `git lfs install`
   - `git submodule update --init --recursive`
2) Install Quartus Prime + MAX 10 device support.
3) (Optional) Install NVC for simulation.
4) (Optional) Install firmware toolchains:
   - C: install RISC-V GCC toolchain under `/opt/riscv`.
   - Rust:
     - `rustup toolchain install stable`
     - `rustup target add riscv32i-unknown-none-elf`
     - `rustup component add llvm-tools-preview`

## Conventions
- HDL: VHDL only.
- Board-specific projects live under `projects/`.

## Structure
- `projects/` : Quartus projects per board
- `lib/`      : reusable VHDL blocks
- `demos/`    : quick experiments

## Simulation (NVC)
- Compile UVVM: `scripts/compile_uvvm_nvc.sh`
- Run reset TB: `scripts/run_reset_tb_nvc.sh`

## Build flows
### FPGA (MAX1000 RISC-V)
- Project: `projects/max1000_riscv`
- Open in Quartus: `projects/max1000_riscv/max1000_riscv.qpf`
- Ensure device: `10M16SAU169C8G`
- Build: Quartus "Compile Design"
- Program: Quartus Programmer with the generated `.sof`

### FPGA (MAX1000 blinky)
- Project: `projects/max1000_blinky`
- Open in Quartus: `projects/max1000_blinky/max1000_blinky.qpf`
- Build + Program as above

### Firmware (C demo)
- Dir: `software/helloworld_c`
- Build ROM image:
  - `make clean && make`
- Outputs:
  - `hello.bin` and `projects/max1000_riscv/rom.mif`

### Firmware (Rust demo)
- Dir: `software/helloworld_rust`
- Build ROM image:
  - `make clean && make`
- Outputs:
  - `hello.bin` and `projects/max1000_riscv/rom.mif`

## End-to-end (typical)
1) Build firmware ROM:
   - C: `cd software/helloworld_c && make clean && make`
   - Rust: `cd software/helloworld_rust && make clean && make`
2) Open Quartus project:
   - `projects/max1000_riscv/max1000_riscv.qpf`
3) Compile design in Quartus.
4) Program FPGA with the generated `.sof`.
