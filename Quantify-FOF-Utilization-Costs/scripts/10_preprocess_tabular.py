#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import os
from pathlib import Path
from typing import Dict, List, Optional

from path_resolver import SAMPLE_DIR, get_data_root

PROJECT_ROOT = Path(__file__).resolve().parents[1]
CONFIG_DIR = PROJECT_ROOT / "config"
ENV_FILE = CONFIG_DIR / ".env"
DICT_PATH = PROJECT_ROOT / "data" / "data_dictionary.csv"
OUTPUT_DIR = PROJECT_ROOT / "outputs" / "preprocess"
AGG_DIR = PROJECT_ROOT / "outputs" / "aggregates"


def _parse_dotenv(path: Path) -> Dict[str, str]:
    out: Dict[str, str] = {}
    if not path.exists():
        return out
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            continue
        k, v = line.split("=", 1)
        out[k.strip()] = v.strip().strip('"').strip("'")
    return out


def read_csv_header(path: Path) -> List[str]:
    with path.open("r", encoding="utf-8", newline="") as f:
        r = csv.reader(f)
        return next(r)


def load_required_vars(dict_path: Path, dataset_filter: Optional[str] = None) -> List[str]:
    req: List[str] = []
    with dict_path.open("r", encoding="utf-8", newline="") as f:
        dr = csv.DictReader(f)
        for row in dr:
            if dataset_filter and row.get("dataset") != dataset_filter:
                continue
            if row.get("required", "").strip().lower() == "yes":
                req.append(row["variable"])
    return req


def missingness_profile(path: Path) -> Dict[str, int]:
    counts: Dict[str, int] = {}
    with path.open("r", encoding="utf-8", newline="") as f:
        dr = csv.DictReader(f)
        for row in dr:
            for k, v in row.items():
                counts.setdefault(k, 0)
                if v is None or str(v).strip() == "":
                    counts[k] += 1
    return counts


def _env_allow_aggregates() -> bool:
    env = (os.environ.get("ALLOW_AGGREGATES") or "").strip()
    if env:
        return env in {"1", "true", "TRUE", "yes", "YES"}
    cfg = _parse_dotenv(ENV_FILE)
    v = (cfg.get("ALLOW_AGGREGATES") or "").strip()
    return v in {"1", "true", "TRUE", "yes", "YES"}


def _to_float(x: Optional[str]) -> Optional[float]:
    if x is None:
        return None
    s = str(x).strip()
    if s == "":
        return None
    try:
        return float(s)
    except ValueError:
        return None


def write_aim2_aggregates(path: Path, out_path: Path, min_cell: int = 5) -> None:
    """
    Write non-sensitive Aim 2 aggregates:
    - Group by FOF_status only (default)
    - Suppress metrics if n < min_cell
    - Never include id or row-level exports
    """
    groups: Dict[str, Dict[str, float]] = {}
    counts: Dict[str, int] = {}

    with path.open("r", encoding="utf-8", newline="") as f:
        dr = csv.DictReader(f)
        for row in dr:
            g = str(row.get("FOF_status", "")).strip() or "NA"
            counts[g] = counts.get(g, 0) + 1

            util = _to_float(row.get("util_visits_total"))
            cost = _to_float(row.get("cost_total_eur"))

            groups.setdefault(g, {"util_sum": 0.0, "util_n": 0.0, "cost_sum": 0.0, "cost_n": 0.0})

            if util is not None:
                groups[g]["util_sum"] += util
                groups[g]["util_n"] += 1.0
            if cost is not None:
                groups[g]["cost_sum"] += cost
                groups[g]["cost_n"] += 1.0

    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(
            [
                "FOF_status",
                "n",
                "suppressed",
                "util_visits_total_sum",
                "util_visits_total_mean",
                "cost_total_eur_sum",
                "cost_total_eur_mean",
            ]
        )

        for g in sorted(counts.keys()):
            n = counts[g]
            suppressed = 1 if n < min_cell else 0

            if suppressed:
                w.writerow([g, n, suppressed, "", "", "", ""])
                continue

            util_sum = groups.get(g, {}).get("util_sum", 0.0)
            util_n = groups.get(g, {}).get("util_n", 0.0)
            cost_sum = groups.get(g, {}).get("cost_sum", 0.0)
            cost_n = groups.get(g, {}).get("cost_n", 0.0)

            util_mean = (util_sum / util_n) if util_n else ""
            cost_mean = (cost_sum / cost_n) if cost_n else ""

            util_sum_out = int(round(util_sum)) if util_n else ""
            util_mean_out = round(util_mean, 2) if util_mean != "" else ""
            cost_sum_out = round(cost_sum, 2) if cost_n else ""
            cost_mean_out = round(cost_mean, 2) if cost_mean != "" else ""

            w.writerow([g, n, suppressed, util_sum_out, util_mean_out, cost_sum_out, cost_mean_out])

    return None


def main() -> int:
    ap = argparse.ArgumentParser(description="Preprocess tabular inputs (safe-by-default; no raw data copying).")
    ap.add_argument("--input", default=None, help="Path to input CSV (repo-external or local).")
    ap.add_argument("--dict", default=str(DICT_PATH), help="Path to data dictionary CSV.")
    ap.add_argument("--use-sample", action="store_true", help="Use synthetic sample dataset.")
    ap.add_argument("--allow-aggregates", action="store_true", help="Allow writing non-sensitive aggregate outputs.")
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

    dataset_filter = "synthetic_sample" if args.use_sample else None
    req = load_required_vars(dict_path, dataset_filter=dataset_filter)
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

    print(f"Wrote: {out_profile}")

    if args.allow_aggregates and _env_allow_aggregates():
        out_agg = AGG_DIR / "aim2_aggregates.csv"
        write_aim2_aggregates(in_path, out_agg, min_cell=5)
        print(f"Wrote: {out_agg}")
    else:
        if args.allow_aggregates and not _env_allow_aggregates():
            print("Aggregates requested but ALLOW_AGGREGATES is not enabled. Skipping aggregates.")

    # NOTE: This script intentionally does NOT write participant-level transformed datasets into repo.
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
