#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
simlib_dir="$repo_root/simlib/uvvm/nvc"
lib_dir="$repo_root/lib"
tb_file="$repo_root/test/reset_tb.vhd"

if ! command -v nvc >/dev/null 2>&1; then
  echo "nvc not found in PATH" >&2
  exit 2
fi

if [[ ! -d "$simlib_dir" ]]; then
  echo "UVVM simlib not found at $simlib_dir" >&2
  echo "Run: scripts/compile_uvvm_nvc.sh" >&2
  exit 3
fi

if [[ ! -f "$tb_file" ]]; then
  echo "Testbench not found: $tb_file" >&2
  exit 4
fi

workdir="$repo_root/simlib/work_nvc"
mkdir -p "$workdir"

(
  cd "$workdir"
  nvc --std=2008 -L . -L "$simlib_dir" --work=utils -a --relaxed \
    "$lib_dir/utils/reset.vhd" \
    "$lib_dir/utils/cdc_sync.vhd"

  nvc --std=2008 -L . -L "$simlib_dir" --work=work -a --relaxed "$tb_file"
  nvc --std=2008 -L . -L "$simlib_dir" --work=work -e reset_tb
  nvc --std=2008 -L . -L "$simlib_dir" --work=work -r reset_tb
)

echo "reset_tb completed"
