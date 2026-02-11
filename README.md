# FPGA projects

This repo contains small FPGA projects, demos, and reusable blocks.

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
