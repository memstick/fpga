#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
uvvm_dir="$repo_root/third_party/uvvm"
out_dir="$repo_root/simlib/uvvm"

if [[ ! -d "$uvvm_dir" ]]; then
  echo "UVVM not found at $uvvm_dir" >&2
  exit 2
fi

if [[ -f "$uvvm_dir/.git" ]] && [[ ! -d "$uvvm_dir/script" ]]; then
  echo "UVVM submodule not checked out yet. Try: git submodule update --init --recursive" >&2
  exit 4
fi

if ! command -v nvc >/dev/null 2>&1; then
  echo "nvc not found in PATH" >&2
  exit 5
fi

mkdir -p "$out_dir"

compile_script="$uvvm_dir/script/compile_all.sh"
if [[ ! -f "$compile_script" ]]; then
  echo "UVVM compile script not found: $compile_script" >&2
  exit 3
fi

bash "$compile_script" nvc "$out_dir"

echo "UVVM compiled to $out_dir/nvc"
