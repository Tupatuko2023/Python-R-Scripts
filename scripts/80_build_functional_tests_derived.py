#!/usr/bin/env python3
"""Build functional test derived dataset from DATA_ROOT/KaatumisenPelko.csv."""

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
        description="Create functional-test derived dataset (mean + best variants)."
    )
    parser.add_argument(
        "--data-root",
        default=os.getenv("DATA_ROOT", ""),
        help="Absolute DATA_ROOT path. Defaults to DATA_ROOT env var.",
    )
    parser.add_argument(
        "--input-csv",
        default="",
        help="Optional input csv path; default auto-detect under DATA_ROOT.",
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
            "(default: DATA_ROOT/derived/fof_functional_tests_from_csv.csv)."
        ),
    )
    parser.add_argument(
        "--out-meta",
        default="",
        help=(
            "Output metadata json path "
            "(default: DATA_ROOT/derived/fof_functional_tests_from_csv_metadata.json)."
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


def resolve_input_csv(data_root: Path, input_csv: str) -> Path:
    if input_csv:
        path = Path(input_csv).expanduser().resolve()
        if not path.exists():
            raise SystemExit(f"ERROR: input csv not found: {path}")
        return path
    candidates = [data_root / "Kaatumisenpelko.csv", data_root / "KaatumisenPelko.csv"]
    for path in candidates:
        if path.exists():
            return path
    raise SystemExit(
        "ERROR: Could not find Kaatumisenpelko.csv or KaatumisenPelko.csv under DATA_ROOT."
    )


def choose_existing(df: pd.DataFrame, names: List[str]) -> Optional[str]:
    for name in names:
        if name in df.columns:
            return name
    return None


def as_numeric(df: pd.DataFrame, col: Optional[str]) -> pd.Series:
    if col is None:
        return pd.Series(np.nan, index=df.index, dtype="float64")
    return pd.to_numeric(df[col], errors="coerce")


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


def main() -> None:
    args = parse_args()
    data_root = require_data_root(args.data_root)
    input_csv = resolve_input_csv(data_root, args.input_csv)

    out_csv = (
        Path(args.out_csv).expanduser().resolve()
        if args.out_csv
        else data_root / "derived" / "fof_functional_tests_from_csv.csv"
    )
    out_meta = (
        Path(args.out_meta).expanduser().resolve()
        if args.out_meta
        else data_root / "derived" / "fof_functional_tests_from_csv_metadata.json"
    )

    df = pd.read_csv(input_csv, low_memory=False)

    id_col = choose_existing(df, ["id", "NRO", "Jnro"])
    if id_col is None:
        raise SystemExit("ERROR: could not find ID column (expected one of: id, NRO, Jnro).")
    nro_col = choose_existing(df, ["NRO", "Jnro"])

    grip_r0_col = choose_existing(df, ["puristusvoima_kg_oik_0", "Puristusvoima_lka_Oik_0"])
    grip_l0_col = choose_existing(df, ["puristusvoima_kg_vas_0", "Puristusvoima_lka_Vas_0"])
    grip_r2_col = choose_existing(df, ["puristusvoima_kg_oik_2", "Puristusvoima_lka_Oik_2"])
    grip_l2_col = choose_existing(df, ["puristusvoima_kg_vas_2", "Puristusvoima_lka_Vas_2"])

    sls_r0_col = "yhdella_jalalla_seisominen_Oik_0" if "yhdella_jalalla_seisominen_Oik_0" in df.columns else None
    sls_l0_col = "yhdella_jalalla_seisominen_Vas_0" if "yhdella_jalalla_seisominen_Vas_0" in df.columns else None
    sls_r2_col = "yhdella_jalalla_seisominen_Oik_2" if "yhdella_jalalla_seisominen_Oik_2" in df.columns else None
    sls_l2_col = "yhdella_jalalla_seisominen_Vas_2" if "yhdella_jalalla_seisominen_Vas_2" in df.columns else None

    ftsst0_col = "tuoliltanousu0" if "tuoliltanousu0" in df.columns else None
    ftsst2_col = "tuoliltanousu2" if "tuoliltanousu2" in df.columns else None

    walk0_col = "kavelynopeus_m_sek0" if "kavelynopeus_m_sek0" in df.columns else None
    walk2_col = "kavelynopeus_m_sek2" if "kavelynopeus_m_sek2" in df.columns else None
    walk0_sec_col = "kavelynopeus0" if "kavelynopeus0" in df.columns else None
    walk2_sec_col = "kavelynopeus2" if "kavelynopeus2" in df.columns else None

    grip_r0 = as_numeric(df, grip_r0_col)
    grip_l0 = as_numeric(df, grip_l0_col)
    grip_r2 = as_numeric(df, grip_r2_col)
    grip_l2 = as_numeric(df, grip_l2_col)

    sls_r0 = as_numeric(df, sls_r0_col)
    sls_l0 = as_numeric(df, sls_l0_col)
    sls_r2 = as_numeric(df, sls_r2_col)
    sls_l2 = as_numeric(df, sls_l2_col)

    ftsst0 = as_numeric(df, ftsst0_col)
    ftsst2 = as_numeric(df, ftsst2_col)

    if walk0_col is not None:
        walk_mps0 = as_numeric(df, walk0_col)
        walk_source0 = walk0_col
    else:
        sec0 = as_numeric(df, walk0_sec_col)
        walk_mps0 = np.where(sec0 > 0, 10.0 / sec0, np.nan)
        walk_mps0 = pd.Series(walk_mps0, index=df.index, dtype="float64")
        walk_source0 = "derived_from_10m_seconds" if walk0_sec_col is not None else "missing"

    if walk2_col is not None:
        walk_mps2 = as_numeric(df, walk2_col)
        walk_source2 = walk2_col
    else:
        sec2 = as_numeric(df, walk2_sec_col)
        walk_mps2 = np.where(sec2 > 0, 10.0 / sec2, np.nan)
        walk_mps2 = pd.Series(walk_mps2, index=df.index, dtype="float64")
        walk_source2 = "derived_from_10m_seconds" if walk2_sec_col is not None else "missing"

    out = pd.DataFrame(
        {
            "id": df[id_col],
            "nro": df[nro_col] if nro_col else np.nan,
            "grip_r0": grip_r0,
            "grip_l0": grip_l0,
            "grip_r2": grip_r2,
            "grip_l2": grip_l2,
            "Puristus_mean0": pd.concat([grip_r0, grip_l0], axis=1).mean(axis=1, skipna=True),
            "Puristus_mean2": pd.concat([grip_r2, grip_l2], axis=1).mean(axis=1, skipna=True),
            "Puristus_best0": pd.concat([grip_r0, grip_l0], axis=1).max(axis=1, skipna=True),
            "Puristus_best2": pd.concat([grip_r2, grip_l2], axis=1).max(axis=1, skipna=True),
            "Grip_asymmetry0": (grip_r0 - grip_l0).abs(),
            "Grip_asymmetry2": (grip_r2 - grip_l2).abs(),
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
        "source_type": "csv_standardized",
        "input_csv": to_data_root_relative(input_csv, data_root),
        "input_basename": input_csv.name,
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
            "kavelynopeus_m_sek0": walk_source0,
            "kavelynopeus_m_sek2": walk_source2,
            "Tuoli_policy": "Use raw tuoliltanousu0/2; do not use derived Tuoli0/2.",
        },
        "non_missing": {
            col: non_missing(out[col]) for col in out.columns if col not in {"id", "nro"}
        },
        "definitions": {
            "Puristus_mean": "mean(left,right) because handedness is unknown",
            "Puristus_best": "max(left,right) as clinical sensitivity definition",
            "SLS_mean": "mean(left,right) for balance stability",
            "SLS_best": "max(left,right) optional sensitivity/asymmetry analyses",
            "kavelynopeus_m_sek": "prefer raw m/s columns; fallback convert from 10m seconds",
        },
    }

    print("DATA_ROOT detected.")
    print(f"Input file detected: {input_csv.name}")
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
