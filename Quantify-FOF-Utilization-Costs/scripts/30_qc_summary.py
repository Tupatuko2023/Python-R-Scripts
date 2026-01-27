#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List

from path_resolver import SAMPLE_DIR, get_data_root, get_paper02_dir

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DICT_PATH = PROJECT_ROOT / "data" / "data_dictionary.csv"
OUT_DIR = PROJECT_ROOT / "outputs" / "qc"


def load_dictionary_vars(dict_path: Path) -> List[str]:
    vars_: List[str] = []
    with dict_path.open("r", encoding="utf-8", newline="") as f:
        dr = csv.DictReader(f)
        for row in dr:
            if row.get("dataset", "").strip() == "":
                continue
            vars_.append(row["variable"])
    return vars_


def count_rows_cols(path: Path) -> Dict[str, int]:
    with path.open("r", encoding="utf-8", newline="") as f:
        dr = csv.DictReader(f)
        rows = 0
        for _ in dr:
            rows += 1
        cols = len(dr.fieldnames or [])
    return {"rows": rows, "cols": cols}


def missingness(path: Path) -> Dict[str, int]:
    miss: Dict[str, int] = {}
    with path.open("r", encoding="utf-8", newline="") as f:
        dr = csv.DictReader(f)
        for row in dr:
            for k, v in row.items():
                if k not in miss:
                    miss[k] = 0
                if v is None or str(v).strip() == "":
                    miss[k] += 1
    return miss


def main() -> int:
    ap = argparse.ArgumentParser(description="Produce non-sensitive QC summaries into outputs/qc/.")
    ap.add_argument("--input", default=None, help="Explicit input CSV path.")
    ap.add_argument("--use-sample", action="store_true", help="Use synthetic sample dataset.")
    ap.add_argument("--dict", default=str(DICT_PATH), help="Path to data dictionary CSV.")
    args = ap.parse_args()

    dict_path = Path(args.dict)
    if not dict_path.exists():
        print(f"Missing dictionary: {dict_path}")
        return 2

    if args.use_sample:
        in_path = SAMPLE_DIR / "sample_utilization.csv"
    elif args.input:
        in_path = Path(args.input)
    else:
        data_root = get_data_root(require=False)
        if not data_root:
            print("No input and DATA_ROOT not set. Use --use-sample or pass --input.")
            return 0
        base = get_paper02_dir(data_root)
        print(f"DATA_ROOT set. Provide --input to a specific file under: {base}")
        return 0

    if not in_path.exists():
        print(f"Input missing: {in_path}")
        return 0

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    now_ts = datetime.now(timezone.utc).isoformat()

    shape = count_rows_cols(in_path)
    out_overview = OUT_DIR / "qc_overview.csv"
    with out_overview.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["timestamp", "input_path", "rows", "cols"])
        w.writerow([now_ts, str(in_path), shape["rows"], shape["cols"]])

    out_inputs = OUT_DIR / "qc_inputs.csv"
    with out_inputs.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["timestamp", "input_path", "input_hash"])
        w.writerow([now_ts, str(in_path), ""])

    miss = missingness(in_path)
    out_miss = OUT_DIR / "qc_missingness.csv"
    with out_miss.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["variable", "missing_count"])
        for k in sorted(miss.keys()):
            w.writerow([k, miss[k]])

    dict_vars = set(load_dictionary_vars(dict_path))
    with in_path.open("r", encoding="utf-8", newline="") as f:
        dr = csv.DictReader(f)
        cols = set(dr.fieldnames or [])
    extras = sorted(cols - dict_vars)
    missing_cols = sorted(dict_vars - cols)

    out_schema = OUT_DIR / "qc_schema_drift.csv"
    with out_schema.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["kind", "variable"])
        for v in missing_cols:
            w.writerow(["missing_in_input", v])
        for v in extras:
            w.writerow(["extra_in_input", v])

    print(f"Wrote: {out_overview}")
    print(f"Wrote: {out_inputs}")
    print(f"Wrote: {out_miss}")
    print(f"Wrote: {out_schema}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
