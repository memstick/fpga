#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
simlib_dir="$repo_root/simlib/uvvm"
lib_dir="$repo_root/lib"
tb_file="$repo_root/test/reset_tb.vhd"

if ! command -v ghdl >/dev/null 2>&1; then
  echo "ghdl not found in PATH" >&2
  exit 2
fi

if [[ ! -d "$simlib_dir" ]]; then
  echo "UVVM simlib not found at $simlib_dir" >&2
  echo "Run: scripts/compile_uvvm_ghdl.sh" >&2
  exit 3
fi

if [[ ! -f "$tb_file" ]]; then
  echo "Testbench not found: $tb_file" >&2
  exit 4
fi

workdir="$repo_root/simlib/work"
mkdir -p "$workdir"

ghdl -a --std=08 --work=utils --workdir="$workdir" \
  "$lib_dir/utils/reset.vhd" \
  "$lib_dir/utils/cdc_sync.vhd"

ghdl -a --std=08 --work=work --workdir="$workdir" -P"$workdir" "$tb_file"
ghdl -e --std=08 --work=work --workdir="$workdir" -P"$workdir" reset_tb
ghdl -r --std=08 --work=work --workdir="$workdir" -P"$workdir" reset_tb --assert-level=error

echo "reset_tb completed"
