#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path
import sys

VHDL_EXTS = {".vhd", ".vhdl", ".vho"}

def find_vhdl_files(root: Path) -> list[Path]:
    if not root or not root.exists():
        return []
    return sorted(
        p for p in root.rglob("*")
        if p.is_file() and p.suffix.lower() in VHDL_EXTS
    )

def repo_rel_or_abs_posix(p: Path, repo_root: Path) -> str:
    try:
        return p.relative_to(repo_root).as_posix()
    except ValueError:
        return p.resolve().as_posix()

def immediate_subdirs(p: Path) -> list[Path]:
    return sorted([d for d in p.iterdir() if d.is_dir()])

def write_toml(out_path: Path, libraries: dict[str, list[str]]) -> None:
    lines = []
    lines.append("# Auto-generated. Do not edit by hand.")
    lines.append("[libraries]")
    for libname, files in libraries.items():
        lines.append(f'{libname}.files = [')
        for f in files:
            lines.append(f'  "{f}",')
        lines.append("]")
        lines.append("")
    out_path.write_text("\n".join(lines), encoding="utf-8")

def main() -> int:
    ap = argparse.ArgumentParser(description="Generate vhdl_ls.toml (one library per lib/* subdir).")
    ap.add_argument("--repo", type=Path, default=Path.cwd(), help="Repo root (default: cwd)")
    ap.add_argument("--lib", type=Path, default=Path("lib"), help='Repo-relative lib dir (default: "lib")')
    ap.add_argument("--quartus", type=Path, default=None, help="Directory containing Quartus VHDL files")
    ap.add_argument("--quartus-lib", type=str, default="quartus", help='Library name for Quartus files')
    ap.add_argument("--out", type=Path, default=Path("vhdl_ls.toml"), help='Output file (default: "vhdl_ls.toml")')
    args = ap.parse_args()

    repo_root = args.repo.resolve()
    lib_root = (repo_root / args.lib).resolve() if not args.lib.is_absolute() else args.lib.resolve()
    out_path = (repo_root / args.out).resolve() if not args.out.is_absolute() else args.out.resolve()
    quartus_dir = args.quartus.resolve() if args.quartus else None

    if not lib_root.exists():
        print(f"ERROR: lib dir not found: {lib_root}", file=sys.stderr)
        return 2

    libraries: dict[str, list[str]] = {}

    # One VHDL library per immediate subdirectory of lib/
    for d in immediate_subdirs(lib_root):
        libname = d.name
        files = [repo_rel_or_abs_posix(p, repo_root) for p in find_vhdl_files(d)]
        if files:
            libraries[libname] = files

    # Quartus files in their own library
    if quartus_dir:
        qfiles = [repo_rel_or_abs_posix(p, repo_root) for p in find_vhdl_files(quartus_dir)]
        if qfiles:
            libraries[args.quartus_lib] = qfiles

    if not libraries:
        print("ERROR: no VHDL files found.", file=sys.stderr)
        return 3

    write_toml(out_path, libraries)
    print(f"Wrote: {out_path}")
    print("Libraries:", ", ".join(libraries.keys()))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())

