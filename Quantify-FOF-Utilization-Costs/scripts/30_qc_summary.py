#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List
import zipfile

from path_resolver import SAMPLE_DIR, get_data_root, get_paper02_dir, safe_join_path
from qc_no_abs_paths_check import scan_paths
from _io_utils import (
    iter_date_columns,
    key_columns,
    manifest_relative_path,
    parse_date,
    read_rows,
)

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DICT_PATH = PROJECT_ROOT / "data" / "data_dictionary.csv"

# Use environment variable for output dir if set (Snakemake compatibility)
import os
OUT_ROOT = Path(os.getenv("OUTPUT_DIR")) if os.getenv("OUTPUT_DIR") else PROJECT_ROOT / "outputs"
OUT_DIR = OUT_ROOT / "qc"

@dataclass
class Source:
    source_id: str
    path: Path
    kind: str = "source"


def load_dictionary_vars(dict_path: Path) -> List[str]:
    vars_: List[str] = []
    with dict_path.open("r", encoding="utf-8", newline="") as f:
        dr = csv.DictReader(f)
        for row in dr:
            if row.get("dataset", "").strip() == "":
                continue
            vars_.append(row["variable"])
    return vars_


def _collect_from_dir(base: Path) -> List[Source]:
    sources: List[Source] = []
    for p in sorted(base.rglob("*")):
        if not p.is_file():
            continue
        if p.suffix.lower() not in {".csv", ".xlsx", ".xls"}:
            continue
        if "kopio" in p.name.lower():
            continue
        rel = p.relative_to(base).as_posix()
        sources.append(Source(source_id=f"dir::{rel}", path=p))
    return sources


def _collect_from_manifest(path: Path) -> List[Source]:
    data_root = get_data_root(require=False)
    if not data_root:
        return []
    base = get_paper02_dir(data_root)
    sources: List[Source] = []
    with path.open("r", encoding="utf-8", newline="") as f:
        dr = csv.DictReader(f)
        for row in dr:
            logical = row.get("logical_name", "")
            loc = row.get("location", "")
            if not logical.startswith("paper_02::"):
                continue
            rel = manifest_relative_path(loc)
            if not rel:
                continue
            try:
                p = safe_join_path(base, rel)
            except ValueError:
                continue
            if p.suffix.lower() not in {".csv", ".xlsx", ".xls"}:
                continue
            if "kopio" in p.name.lower():
                continue
            sources.append(Source(source_id=logical, path=p))
    return sources


def _collect_sources(args: argparse.Namespace) -> List[Source]:
    sources: List[Source] = []
    if args.use_sample:
        sources.append(Source(source_id="sample_utilization", path=SAMPLE_DIR / "sample_utilization.csv"))
    if args.input:
        sources.append(Source(source_id="input_local", path=Path(args.input)))
    if args.input_dir:
        sources.extend(_collect_from_dir(Path(args.input_dir)))
    if args.manifest:
        sources.extend(_collect_from_manifest(Path(args.manifest)))
    if args.assembled_dir:
        base = Path(args.assembled_dir)
        for p in sorted(base.rglob("*.csv")):
            rel = p.relative_to(base).as_posix()
            sources.append(Source(source_id=f"assembled::{rel}", path=p, kind="assembled"))
    return sources


def _safe_log_inputs(args: argparse.Namespace) -> None:
    if args.input or args.input_dir or args.manifest:
        print("Inputs: --input provided locally")


def main() -> int:
    ap = argparse.ArgumentParser(description="Produce non-sensitive QC summaries into outputs/qc/.")
    ap.add_argument("--input", default=None, help="Explicit input CSV/XLSX path.")
    ap.add_argument("--input-dir", default=None, help="Directory containing inputs.")
    ap.add_argument("--manifest", default=None, help="Manifest CSV with logical names.")
    ap.add_argument("--assembled-dir", default=None, help="Directory with assembled outputs.")
    ap.add_argument("--use-sample", action="store_true", help="Use synthetic sample dataset.")
    ap.add_argument("--dict", default=str(DICT_PATH), help="Path to data dictionary CSV.")
    args = ap.parse_args()

    dict_path = Path(args.dict)
    if not dict_path.exists():
        print("Missing dictionary.")
        return 2

    sources = _collect_sources(args)
    if not sources:
        data_root = get_data_root(require=False)
        if not data_root:
            print("No inputs provided and DATA_ROOT not set. Use --use-sample or pass --input/--input-dir/--manifest.")
            return 0
        print("No inputs provided. Use --input/--input-dir/--manifest (DATA_ROOT is set).")
        return 0

    _safe_log_inputs(args)

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    now_ts = datetime.now(timezone.utc).isoformat()

    overview_rows: List[Dict[str, str]] = []
    inputs_rows: List[Dict[str, str]] = []
    missing_rows: List[Dict[str, str]] = []
    schema_rows: List[Dict[str, str]] = []
    key_rows: List[Dict[str, str]] = []
    date_rows: List[Dict[str, str]] = []
    join_rows: List[Dict[str, str]] = []

    dict_vars = set(load_dictionary_vars(dict_path))
    person_id_sets: Dict[str, set[str]] = {}

    for src in sources:
        if not src.path.exists():
            continue
        if "kopio" in src.path.name.lower():
            continue
        try:
            header_row = 2 if "kaaos" in src.path.name.lower() else 1
            rows, cols = read_rows(src.path, header_row=header_row)
        except zipfile.BadZipFile:
            continue
        except ValueError:
            continue
        if not rows and not cols:
            continue

        rows_count = len(rows)
        cols_count = len(cols)
        overview_rows.append(
            {
                "timestamp": now_ts,
                "source_ref": src.source_id,
                "kind": src.kind,
                "rows": str(rows_count),
                "cols": str(cols_count),
            }
        )
        inputs_rows.append({"timestamp": now_ts, "source_ref": src.source_id, "input_hash": ""})

        missing: Dict[str, int] = {c: 0 for c in cols}
        key_cols = key_columns(cols)
        key_seen: Dict[str, set[str]] = {k: set() for k, _ in key_cols}
        key_dupes: Dict[str, int] = {k: 0 for k, _ in key_cols}
        date_columns = list(iter_date_columns(cols))
        date_invalid: Dict[str, int] = {c: 0 for c in date_columns}

        for row in rows:
            for c in cols:
                val = row.get(c, "")
                if val is None or str(val).strip() == "":
                    missing[c] += 1
            for key, col in key_cols:
                val = row.get(col, "")
                if val is None or str(val).strip() == "":
                    continue
                if val in key_seen[key]:
                    key_dupes[key] += 1
                else:
                    key_seen[key].add(val)
            for c in date_columns:
                val = row.get(c, "")
                if val is None or str(val).strip() == "":
                    continue
                if parse_date(str(val)) is None:
                    date_invalid[c] += 1

        for c in sorted(missing.keys()):
            missing_rows.append({"source_ref": src.source_id, "variable": c, "missing_count": str(missing[c])})

        cols_set = set(cols)
        extras = sorted(cols_set - dict_vars)
        missing_cols = sorted(dict_vars - cols_set)
        for v in missing_cols:
            schema_rows.append({"source_ref": src.source_id, "kind": "missing_in_input", "variable": v})
        for v in extras:
            schema_rows.append({"source_ref": src.source_id, "kind": "extra_in_input", "variable": v})

        for key, col in key_cols:
            key_rows.append(
                {"source_ref": src.source_id, "key": key, "column": col, "duplicates": str(key_dupes[key])}
            )

        for c in date_columns:
            date_rows.append({"source_ref": src.source_id, "date_col": c, "invalid_count": str(date_invalid[c])})

        if "person_id" in cols:
            person_id_sets[src.source_id] = {row.get("person_id", "") for row in rows if row.get("person_id")}

    assembled_ids = [s.source_id for s in sources if s.kind == "assembled"]
    if assembled_ids and person_id_sets:
        for assembled_id in assembled_ids:
            assembled_set = person_id_sets.get(assembled_id, set())
            if not assembled_set:
                continue
            for other_id, other_set in person_id_sets.items():
                if other_id == assembled_id:
                    continue
                coverage = len(assembled_set & other_set) / len(assembled_set)
                join_rows.append(
                    {
                        "assembled_ref": assembled_id,
                        "other_ref": other_id,
                        "key": "person_id",
                        "coverage": f"{coverage:.6f}",
                    }
                )

    out_overview = OUT_DIR / "qc_overview.csv"
    with out_overview.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["timestamp", "source_ref", "kind", "rows", "cols"])
        w.writeheader()
        for row in overview_rows:
            w.writerow(row)

    out_inputs = OUT_DIR / "qc_inputs.csv"
    with out_inputs.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["timestamp", "source_ref", "input_hash"])
        w.writeheader()
        for row in inputs_rows:
            w.writerow(row)

    out_miss = OUT_DIR / "qc_missingness.csv"
    with out_miss.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["source_ref", "variable", "missing_count"])
        w.writeheader()
        for row in missing_rows:
            w.writerow(row)

    out_schema = OUT_DIR / "qc_schema_drift.csv"
    with out_schema.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["source_ref", "kind", "variable"])
        w.writeheader()
        for row in schema_rows:
            w.writerow(row)

    out_keys = OUT_DIR / "qc_key_uniqueness.csv"
    with out_keys.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["source_ref", "key", "column", "duplicates"])
        w.writeheader()
        for row in key_rows:
            w.writerow(row)

    out_dates = OUT_DIR / "qc_date_sanity.csv"
    with out_dates.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["source_ref", "date_col", "invalid_count"])
        w.writeheader()
        for row in date_rows:
            w.writerow(row)

    out_joins = OUT_DIR / "qc_join_coverage.csv"
    with out_joins.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["assembled_ref", "other_ref", "key", "coverage"])
        w.writeheader()
        for row in join_rows:
            w.writerow(row)

    scan_paths([out_overview, out_inputs, out_miss, out_schema, out_keys, out_dates, out_joins])

    print("Wrote: outputs/qc/qc_overview.csv")
    print("Wrote: outputs/qc/qc_inputs.csv")
    print("Wrote: outputs/qc/qc_missingness.csv")
    print("Wrote: outputs/qc/qc_schema_drift.csv")
    print("Wrote: outputs/qc/qc_key_uniqueness.csv")
    print("Wrote: outputs/qc/qc_date_sanity.csv")
    print("Wrote: outputs/qc/qc_join_coverage.csv")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
