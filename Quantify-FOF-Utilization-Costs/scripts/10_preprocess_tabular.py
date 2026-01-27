#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from pathlib import Path
from typing import Dict, List

from path_resolver import SAMPLE_DIR, get_data_root

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DICT_PATH = PROJECT_ROOT / "data" / "data_dictionary.csv"
OUTPUT_DIR = PROJECT_ROOT / "outputs" / "preprocess"


def read_csv_header(path: Path) -> List[str]:
    with path.open("r", encoding="utf-8", newline="") as f:
        r = csv.reader(f)
        return next(r)


def load_required_vars(dict_path: Path) -> List[str]:
    req: List[str] = []
    with dict_path.open("r", encoding="utf-8", newline="") as f:
        dr = csv.DictReader(f)
        for row in dr:
            if row.get("required", "").strip().lower() == "yes":
                req.append(row["variable"])
    return req


def missingness_profile(path: Path) -> Dict[str, int]:
    counts: Dict[str, int] = {}
    with path.open("r", encoding="utf-8", newline="") as f:
        dr = csv.DictReader(f)
        for row in dr:
            for k, v in row.items():
                if k not in counts:
                    counts[k] = 0
                if v is None or str(v).strip() == "":
                    counts[k] += 1
    return counts


def main() -> int:
    ap = argparse.ArgumentParser(description="Preprocess tabular inputs (safe-by-default; no raw data copying).")
    ap.add_argument("--input", default=None, help="Path to input CSV (repo-external or local).")
    ap.add_argument("--dict", default=str(DICT_PATH), help="Path to data dictionary CSV.")
    ap.add_argument("--use-sample", action="store_true", help="Use synthetic sample dataset.")
    args = ap.parse_args()

    dict_path = Path(args.dict)
    if not dict_path.exists():
        print(f"Missing data dictionary: {dict_path}")
        return 2

    if args.use_sample:
        in_path = SAMPLE_DIR / "sample_utilization.csv"
    else:
        if args.input:
            in_path = Path(args.input)
        else:
            data_root = get_data_root(require=False)
            if not data_root:
                print("No input provided and DATA_ROOT is not set. Use --use-sample or set DATA_ROOT.")
                return 0
            print("DATA_ROOT is set, but --input was not provided. Pass explicit --input to a repo-external file.")
            return 0

    if not in_path.exists():
        print(f"Input does not exist: {in_path}")
        return 0

    req = load_required_vars(dict_path)
    header = read_csv_header(in_path)
    missing = [c for c in req if c not in header]
    if missing:
        print(f"Schema validation failed. Missing required columns: {', '.join(missing)}")
        return 3

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    prof = missingness_profile(in_path)
    out_profile = OUTPUT_DIR / "missingness_profile.csv"
    with out_profile.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["variable", "missing_count"])
        for k in sorted(prof.keys()):
            w.writerow([k, prof[k]])

    # NOTE: This script intentionally does NOT write participant-level transformed datasets into repo.
    # Allowed future extension: write only aggregated tables if explicitly permitted.

    print(f"Wrote: {out_profile}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
