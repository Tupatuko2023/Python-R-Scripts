#!/usr/bin/env python3
"""Build functional-test derived dataset from DATA_ROOT/paper_02/KAAOS_data_sotullinen.xlsx."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from typing import Dict, List, Optional

import numpy as np
import pandas as pd


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create functional-test derived dataset from Excel raw source."
    )
    parser.add_argument(
        "--data-root",
        default=os.getenv("DATA_ROOT", ""),
        help="Absolute DATA_ROOT path. Defaults to DATA_ROOT env var.",
    )
    parser.add_argument(
        "--input-xlsx",
        default="",
        help=(
            "Optional xlsx path; default "
            "DATA_ROOT/paper_02/KAAOS_data_sotullinen.xlsx."
        ),
    )
    parser.add_argument(
        "--sheet",
        default="Taul1",
        help="Sheet name containing participant-level table (default: Taul1).",
    )
    parser.add_argument(
        "--header-row",
        type=int,
        default=2,
        help="1-based header row (default: 2).",
    )
    parser.add_argument(
        "--dataset-version",
        default="v1",
        help="Dataset version tag for metadata.",
    )
    parser.add_argument(
        "--out-csv",
        default="",
        help=(
            "Output csv path "
            "(default: DATA_ROOT/derived/fof_functional_tests_from_excel.csv)."
        ),
    )
    parser.add_argument(
        "--out-meta",
        default="",
        help=(
            "Output metadata json path "
            "(default: DATA_ROOT/derived/fof_functional_tests_from_excel_metadata.json)."
        ),
    )
    parser.add_argument(
        "--write",
        action="store_true",
        help="Write outputs. Without this flag, run as dry-run summary only.",
    )
    return parser.parse_args()


def require_data_root(value: str) -> Path:
    if not value:
        raise SystemExit("ERROR: DATA_ROOT is required (env DATA_ROOT or --data-root).")
    root = Path(value).expanduser().resolve()
    if not root.exists():
        raise SystemExit(f"ERROR: DATA_ROOT does not exist: {root}")
    return root


def default_input_xlsx(data_root: Path, override: str) -> Path:
    if override:
        path = Path(override).expanduser().resolve()
    else:
        path = data_root / "paper_02" / "KAAOS_data_sotullinen.xlsx"
    if not path.exists():
        raise SystemExit(f"ERROR: input xlsx not found: {path}")
    return path


def find_column(columns: List[str], include: List[str], exclude: Optional[List[str]] = None) -> Optional[str]:
    exclude = exclude or []
    for col in columns:
        folded = col.casefold()
        if all(token.casefold() in folded for token in include) and not any(
            ex.casefold() in folded for ex in exclude
        ):
            return col
    return None


def clean_numeric(series: pd.Series) -> pd.Series:
    s = series.astype(str).str.strip().str.replace(",", ".", regex=False)
    s = s.replace({"": np.nan, "nan": np.nan, "NaN": np.nan, "E": np.nan, "E1": np.nan})
    return pd.to_numeric(s, errors="coerce")


def non_missing(series: pd.Series) -> int:
    return int(series.notna().sum())


def to_data_root_relative(path: Path, data_root: Path) -> str:
    resolved = path.expanduser().resolve()
    root = data_root.expanduser().resolve()
    try:
        rel = resolved.relative_to(root)
        return f"DATA_ROOT/{rel.as_posix()}"
    except ValueError:
        return path.name


def split_grip_value(series: pd.Series) -> tuple[pd.Series, pd.Series, pd.Series, Dict[str, object]]:
    """Split mixed grip field into class(1..5), kg_candidate(>5), and value_type."""
    raw = clean_numeric(series)
    class_mask = raw.isin([1, 2, 3, 4, 5])
    kg_mask = raw > 5
    invalid_mask = raw.notna() & ~(class_mask | kg_mask)

    grip_class = raw.where(class_mask)
    grip_raw = raw.where(kg_mask)
    value_type = pd.Series("missing", index=series.index, dtype="object")
    value_type.loc[class_mask] = "class"
    value_type.loc[kg_mask] = "kg_candidate"
    value_type.loc[invalid_mask] = "invalid_or_zero"

    non_missing_total = int(raw.notna().sum())
    summary = {
        "non_missing": non_missing_total,
        "min": float(raw.min()) if non_missing_total else None,
        "max": float(raw.max()) if non_missing_total else None,
        "n_unique": int(raw.nunique(dropna=True)),
        "proportion_le_5": float((raw.le(5) & raw.notna()).mean()) if len(raw) else 0.0,
        "proportion_gt_5": float((raw.gt(5) & raw.notna()).mean()) if len(raw) else 0.0,
        "value_type_counts": value_type.value_counts(dropna=False).to_dict(),
        "top_value_counts": raw.value_counts(dropna=True).head(15).to_dict(),
    }
    return grip_class, grip_raw, value_type, summary


def main() -> None:
    args = parse_args()
    data_root = require_data_root(args.data_root)
    input_xlsx = default_input_xlsx(data_root, args.input_xlsx)

    out_csv = (
        Path(args.out_csv).expanduser().resolve()
        if args.out_csv
        else data_root / "derived" / "fof_functional_tests_from_excel.csv"
    )
    out_meta = (
        Path(args.out_meta).expanduser().resolve()
        if args.out_meta
        else data_root / "derived" / "fof_functional_tests_from_excel_metadata.json"
    )

    df = pd.read_excel(
        input_xlsx,
        sheet_name=args.sheet,
        header=max(args.header_row - 1, 0),
    )
    columns = [str(c) for c in df.columns]

    id_col = find_column(columns, ["potilas", "tunnus"])
    if id_col is None:
        id_col = find_column(columns, ["sotu"])
    if id_col is None:
        id_col = "NRO" if "NRO" in df.columns else None
    if id_col is None:
        raise SystemExit("ERROR: could not locate ID column in Excel.")
    nro_col = "NRO" if "NRO" in df.columns else None

    grip_r0_col = find_column(columns, ["tk", "puristusvoima", "oikea"])
    grip_l0_col = find_column(columns, ["tk", "puristusvoima", "vasen"])
    grip_r2_col = find_column(columns, ["2sk", "puristusvoima", "oikea"])
    grip_l2_col = find_column(columns, ["2sk", "puristusvoima", "vasen"])

    ftsst0_col = find_column(columns, ["tk", "tuolilta", "5", "krt"])
    ftsst2_col = find_column(columns, ["2sk", "tuolilta", "5", "krt"])

    sls_r0_col = find_column(columns, ["tk", "yhdellä", "jalalla", "seisominen", "oikea"])
    sls_l0_col = find_column(columns, ["tk", "yhdellä", "jalalla", "seisominen", "vasen"])
    sls_r2_col = find_column(columns, ["2sk", "yhdellä", "jalalla", "seisominen", "oikea"])
    sls_l2_col = find_column(columns, ["2sk", "yhdellä", "jalalla", "seisominen", "vasen"])

    walk0_sec_col = find_column(columns, ["tk", "10", "metrin", "kävelynopeus"])
    walk2_sec_col = find_column(columns, ["sk2", "10", "metrin", "kävelynopeus"])

    grip_r0_class, grip_r0_raw, grip_r0_type, grip_r0_dist = (
        split_grip_value(df[grip_r0_col]) if grip_r0_col else (
            pd.Series(np.nan, index=df.index),
            pd.Series(np.nan, index=df.index),
            pd.Series("missing", index=df.index, dtype="object"),
            {},
        )
    )
    grip_l0_class, grip_l0_raw, grip_l0_type, grip_l0_dist = (
        split_grip_value(df[grip_l0_col]) if grip_l0_col else (
            pd.Series(np.nan, index=df.index),
            pd.Series(np.nan, index=df.index),
            pd.Series("missing", index=df.index, dtype="object"),
            {},
        )
    )
    grip_r2_class, grip_r2_raw, grip_r2_type, grip_r2_dist = (
        split_grip_value(df[grip_r2_col]) if grip_r2_col else (
            pd.Series(np.nan, index=df.index),
            pd.Series(np.nan, index=df.index),
            pd.Series("missing", index=df.index, dtype="object"),
            {},
        )
    )
    grip_l2_class, grip_l2_raw, grip_l2_type, grip_l2_dist = (
        split_grip_value(df[grip_l2_col]) if grip_l2_col else (
            pd.Series(np.nan, index=df.index),
            pd.Series(np.nan, index=df.index),
            pd.Series("missing", index=df.index, dtype="object"),
            {},
        )
    )

    ftsst0 = clean_numeric(df[ftsst0_col]) if ftsst0_col else pd.Series(np.nan, index=df.index)
    ftsst2 = clean_numeric(df[ftsst2_col]) if ftsst2_col else pd.Series(np.nan, index=df.index)

    sls_r0 = clean_numeric(df[sls_r0_col]) if sls_r0_col else pd.Series(np.nan, index=df.index)
    sls_l0 = clean_numeric(df[sls_l0_col]) if sls_l0_col else pd.Series(np.nan, index=df.index)
    sls_r2 = clean_numeric(df[sls_r2_col]) if sls_r2_col else pd.Series(np.nan, index=df.index)
    sls_l2 = clean_numeric(df[sls_l2_col]) if sls_l2_col else pd.Series(np.nan, index=df.index)

    walk0_sec = clean_numeric(df[walk0_sec_col]) if walk0_sec_col else pd.Series(np.nan, index=df.index)
    walk2_sec = clean_numeric(df[walk2_sec_col]) if walk2_sec_col else pd.Series(np.nan, index=df.index)
    walk_mps0 = pd.Series(np.where(walk0_sec > 0, 10.0 / walk0_sec, np.nan), index=df.index)
    walk_mps2 = pd.Series(np.where(walk2_sec > 0, 10.0 / walk2_sec, np.nan), index=df.index)

    out = pd.DataFrame(
        {
            "id": df[id_col],
            "nro": df[nro_col] if nro_col else np.nan,
            "grip_r0": grip_r0_raw,
            "grip_l0": grip_l0_raw,
            "grip_r2": grip_r2_raw,
            "grip_l2": grip_l2_raw,
            "grip_r0_class": grip_r0_class,
            "grip_l0_class": grip_l0_class,
            "grip_r2_class": grip_r2_class,
            "grip_l2_class": grip_l2_class,
            "grip_r0_value_type": grip_r0_type,
            "grip_l0_value_type": grip_l0_type,
            "grip_r2_value_type": grip_r2_type,
            "grip_l2_value_type": grip_l2_type,
            "Puristus_mean0": pd.concat([grip_r0_raw, grip_l0_raw], axis=1).mean(axis=1, skipna=True),
            "Puristus_mean2": pd.concat([grip_r2_raw, grip_l2_raw], axis=1).mean(axis=1, skipna=True),
            "Puristus_best0": pd.concat([grip_r0_raw, grip_l0_raw], axis=1).max(axis=1, skipna=True),
            "Puristus_best2": pd.concat([grip_r2_raw, grip_l2_raw], axis=1).max(axis=1, skipna=True),
            "Grip_asymmetry0": (grip_r0_raw - grip_l0_raw).abs(),
            "Grip_asymmetry2": (grip_r2_raw - grip_l2_raw).abs(),
            "FTSST0": ftsst0,
            "FTSST2": ftsst2,
            "sls_r0": sls_r0,
            "sls_l0": sls_l0,
            "sls_r2": sls_r2,
            "sls_l2": sls_l2,
            "SLS_mean0": pd.concat([sls_r0, sls_l0], axis=1).mean(axis=1, skipna=True),
            "SLS_mean2": pd.concat([sls_r2, sls_l2], axis=1).mean(axis=1, skipna=True),
            "SLS_best0": pd.concat([sls_r0, sls_l0], axis=1).max(axis=1, skipna=True),
            "SLS_best2": pd.concat([sls_r2, sls_l2], axis=1).max(axis=1, skipna=True),
            "kavelynopeus_m_sek0": walk_mps0,
            "kavelynopeus_m_sek2": walk_mps2,
        }
    )

    metadata: Dict[str, object] = {
        "dataset_version": args.dataset_version,
        "source_type": "excel_raw_harmonized",
        "input_xlsx": to_data_root_relative(input_xlsx, data_root),
        "input_basename": input_xlsx.name,
        "sheet": args.sheet,
        "header_row_1based": args.header_row,
        "rows": int(len(out)),
        "id_source_column": id_col,
        "nro_source_column": nro_col,
        "sources": {
            "grip_r0": grip_r0_col,
            "grip_l0": grip_l0_col,
            "grip_r2": grip_r2_col,
            "grip_l2": grip_l2_col,
            "FTSST0": ftsst0_col,
            "FTSST2": ftsst2_col,
            "SLS_r0": sls_r0_col,
            "SLS_l0": sls_l0_col,
            "SLS_r2": sls_r2_col,
            "SLS_l2": sls_l2_col,
            "kavelynopeus_m_sek0": f"10 / {walk0_sec_col}" if walk0_sec_col else None,
            "kavelynopeus_m_sek2": f"10 / {walk2_sec_col}" if walk2_sec_col else None,
        },
        "non_missing": {
            col: non_missing(out[col]) for col in out.columns if col not in {"id", "nro"}
        },
        "grip_value_rules": {
            "valid_classes": [1, 2, 3, 4, 5],
            "class_rule": "value in {1,2,3,4,5}",
            "raw_kg_candidate_rule": "value > 5",
            "invalid_or_zero_rule": "value <= 0 or non-numeric code",
        },
        "grip_value_distribution": {
            "grip_r0": grip_r0_dist,
            "grip_l0": grip_l0_dist,
            "grip_r2": grip_r2_dist,
            "grip_l2": grip_l2_dist,
        },
        "analysis_policy": {
            "grip_class_primary_analysis": True,
            "grip_class_modeling_scale": "ordinal_5_level",
            "grip_kg_candidate_use": "internal_review_only",
            "grip_pooling_across_sources": "prohibited",
            "policy_note": (
                "Excel grip class (1..5) and CSV grip kg are different "
                "operationalizations and must not be pooled into a single variable."
            ),
        },
    }

    print("DATA_ROOT detected.")
    print(f"Input file detected: {input_xlsx.name} | sheet={args.sheet}")
    print(f"Rows={len(out)} | Columns={len(out.columns)}")
    print(
        "Non-missing summary: "
        f"Puristus_mean0={metadata['non_missing']['Puristus_mean0']}, "
        f"Puristus_best0={metadata['non_missing']['Puristus_best0']}, "
        f"FTSST0={metadata['non_missing']['FTSST0']}, "
        f"SLS_mean0={metadata['non_missing']['SLS_mean0']}, "
        f"kavelynopeus_m_sek0={metadata['non_missing']['kavelynopeus_m_sek0']}"
    )

    if args.write:
        out_csv.parent.mkdir(parents=True, exist_ok=True)
        out.to_csv(out_csv, index=False)
        out_meta.parent.mkdir(parents=True, exist_ok=True)
        with out_meta.open("w", encoding="utf-8") as fh:
            json.dump(metadata, fh, ensure_ascii=False, indent=2)
        print("Dataset written under DATA_ROOT/derived/.")
        print("Metadata written under DATA_ROOT/derived/.")
    else:
        print("Dry-run mode: no files written. Use --write to save outputs.")


if __name__ == "__main__":
    main()
