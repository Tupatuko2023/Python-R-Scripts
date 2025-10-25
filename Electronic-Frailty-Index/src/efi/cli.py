#!/usr/bin/env python3
"""
EFI CLI — a simple command-line tool for a synthetic worked example.

Usage:
  python src/efi/cli.py --input data/external/synthetic_patients.csv --out out/efi_scores.csv
"""

import argparse
import os
import sys
import json
from typing import List, Dict, Optional
from pathlib import Path

# Avoid extra dependencies. Pandas makes CSV handling easier, so it's assumed available.
try:
    import pandas as pd
except Exception:
    print(
        "Pandas is required. Install the environment using the Makefile 'setup' command.",
        file=sys.stderr,
    )
    raise


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        prog="efi-cli", description="Compute a demo EFI from synthetic data."
    )
    p.add_argument(
        "--input",
        required=True,
        help="Input CSV. Must contain at least columns: id, age, and optional def_* columns.",
    )
    p.add_argument("--out", required=True, help="Output CSV path.")
    p.add_argument("--report-md", default=None, help="Optional path for a Markdown report.")
    p.add_argument(
        "--config", default=None, help='Optional JSON config file. E.g., {"min_deficits": 1}'
    )
    p.add_argument("--seed", type=int, default=42, help="Fallback random seed. Default 42.")
    return p.parse_args()


def load_config(path: Optional[str]) -> Dict:
    if not path:
        return {}
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        print("Warning: failed to read config. Continuing with defaults.", file=sys.stderr)
        return {}


def find_deficit_cols(df: "pd.DataFrame") -> List[str]:
    return [c for c in df.columns if c.lower().startswith("def_")]


def compute_efi(df: "pd.DataFrame", min_deficits: int = 1) -> "pd.DataFrame":
    """
    Demo EFI: efi_score = sum(def_*) / n_deficits

    If there are zero deficit columns the function falls back to using age
    (efi = min(age, 100) / 200). When deficit columns exist the returned
    EFI is the fraction of deficits present. The `min_deficits` parameter
    controls how many measured (non-missing) deficit columns are required
    per-row for the standard calculation; rows with fewer measured
    deficits will receive the fallback value (if `age` exists) or NA.

    This is a demo only, not a scientific implementation.
    """
    if min_deficits is None:
        min_deficits = 1
    try:
        min_deficits = int(min_deficits)
    except Exception:
        raise ValueError("min_deficits must be an integer")
    if min_deficits <= 0:
        raise ValueError("min_deficits must be >= 1")

    def_cols = find_deficit_cols(df)
    n_def = len(def_cols)

    # No deficit columns: use fallback based on age (if available)
    if n_def == 0:
        if "age" in df.columns:
            efi = df["age"].clip(lower=0, upper=100) / 200.0
        else:
            # Be defensive: caller didn't provide age; return missing scores
            print(
                "Warning: no deficit columns and no 'age' column; efi_score set to NA",
                file=sys.stderr,
            )
            efi = pd.Series([pd.NA] * len(df), index=df.index)
        out = df.assign(efi_score=efi)
        return out[["id", "efi_score"]]

    # Ensure binary values for deficits (0/1)
    bin_df = df[def_cols].fillna(0).clip(lower=0, upper=1)

    # Sums and denominator for standard EFI calculation
    sums = bin_df.sum(axis=1)
    denom = float(n_def)
    standard_efi = sums / denom

    # Count how many deficit columns were actually measured (non-missing)
    measured = df[def_cols].notna().sum(axis=1)

    # Prepare result series and apply fallback where measured < min_deficits
    result = standard_efi.copy()

    if min_deficits > 1:
        mask = measured < min_deficits
    else:
        mask = pd.Series(False, index=df.index)

    if mask.any():
        # For masked rows use fallback if age exists, otherwise NA
        if "age" in df.columns:
            fallback = df["age"].clip(lower=0, upper=100) / 200.0
        else:
            fallback = pd.Series([pd.NA] * len(df), index=df.index)
        result = result.where(~mask, other=fallback)

    out = df.assign(efi_score=result)
    return out[["id", "efi_score"]]


def write_report_md(path: str, input_path: str, n_rows: int, n_def: int, out_path: str) -> None:
    parent = Path(path).parent
    # Skip creating when parent is current directory (no explicit directory component)
    if parent != Path("."):
        parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write("# EFI demo report\n\n")
        f.write(f"- Input: `{input_path}`\n")
        f.write(f"- Row count: {n_rows}\n")
        f.write(f"- Deficit columns: {n_def}\n")
        f.write(f"- Output: `{out_path}`\n")
        f.write("\nNote: This is a synthetic demo. Not for clinical use.\n")


def main() -> int:
    args = parse_args()
    cfg = load_config(args.config)

    # Read data
    try:
        df = pd.read_csv(args.input)
    except FileNotFoundError:
        print(f"Input file not found: {args.input}", file=sys.stderr)
        return 2
    except Exception as e:
        print(f"Failed to read CSV: {e}", file=sys.stderr)
        return 2

    required = {"id", "age"}
    if missing := (set(required) - set(df.columns)):
        raise ValueError(f"Missing required columns: {', '.join(sorted(missing))}")

    def_cols = find_deficit_cols(df)
    result = compute_efi(df, min_deficits=int(cfg.get("min_deficits", 1)))

    # Write result
    if out_parent := os.path.dirname(args.out):
        os.makedirs(out_parent, exist_ok=True)
    result.to_csv(args.out, index=False)

    # Optional report
    if args.report_md:
        n_def = len(def_cols)
        write_report_md(args.report_md, args.input, len(df), n_def, args.out)

    print(f"OK: EFI results written to {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
# EOF
