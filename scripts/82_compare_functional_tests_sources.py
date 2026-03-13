#!/usr/bin/env python3
"""Compare harmonized CSV vs Excel functional-test datasets."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from typing import Dict, List, Tuple

import pandas as pd


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create source comparison QC for functional-test derived datasets."
    )
    parser.add_argument(
        "--data-root",
        default=os.getenv("DATA_ROOT", ""),
        help="Absolute DATA_ROOT path. Defaults to DATA_ROOT env var.",
    )
    parser.add_argument(
        "--csv-derived",
        default="",
        help=(
            "Path to CSV-harmonized dataset "
            "(default: DATA_ROOT/derived/fof_functional_tests_from_csv.csv)."
        ),
    )
    parser.add_argument(
        "--excel-derived",
        default="",
        help=(
            "Path to Excel-harmonized dataset "
            "(default: DATA_ROOT/derived/fof_functional_tests_from_excel.csv)."
        ),
    )
    parser.add_argument(
        "--out-json",
        default="",
        help=(
            "Output compare json path "
            "(default: DATA_ROOT/derived/fof_functional_tests_compare.json)."
        ),
    )
    parser.add_argument(
        "--out-md",
        default="",
        help=(
            "Output markdown summary path "
            "(default: DATA_ROOT/derived/fof_functional_tests_compare.md)."
        ),
    )
    parser.add_argument(
        "--corr-threshold",
        type=float,
        default=0.95,
        help="Flag threshold for low correlation.",
    )
    parser.add_argument(
        "--min-overlap",
        type=int,
        default=50,
        help="Flag threshold for low overlap.",
    )
    parser.add_argument(
        "--missing-min-count",
        type=int,
        default=5,
        help="Minimum non-missing count to treat source as available.",
    )
    parser.add_argument(
        "--write",
        action="store_true",
        help="Write output file. Without this flag, run as dry-run summary only.",
    )
    return parser.parse_args()


def require_data_root(value: str) -> Path:
    if not value:
        raise SystemExit("ERROR: DATA_ROOT is required (env DATA_ROOT or --data-root).")
    root = Path(value).expanduser().resolve()
    if not root.exists():
        raise SystemExit(f"ERROR: DATA_ROOT does not exist: {root}")
    return root


def metric_stats(merged: pd.DataFrame, metric: str) -> Dict[str, float]:
    c = pd.to_numeric(merged[f"{metric}_csv"], errors="coerce")
    e = pd.to_numeric(merged[f"{metric}_excel"], errors="coerce")
    overlap = c.notna() & e.notna()
    stats: Dict[str, float] = {
        "non_missing_csv": int(c.notna().sum()),
        "non_missing_excel": int(e.notna().sum()),
        "non_missing_overlap": int(overlap.sum()),
    }
    if overlap.sum() >= 2:
        diff = c[overlap] - e[overlap]
        stats["correlation"] = float(c[overlap].corr(e[overlap]))
        stats["mean_abs_diff"] = float(diff.abs().mean())
        stats["mean_diff_csv_minus_excel"] = float(diff.mean())
    else:
        stats["correlation"] = None
        stats["mean_abs_diff"] = None
        stats["mean_diff_csv_minus_excel"] = None
    return stats


def normalize_key(series: pd.Series) -> pd.Series:
    raw = series.astype(str).str.strip()
    num = pd.to_numeric(raw, errors="coerce")
    out = raw.copy()
    mask = num.notna()
    out.loc[mask] = num.loc[mask].astype("int64").astype(str)
    return out


def to_data_root_relative(path: Path, data_root: Path) -> str:
    resolved = path.expanduser().resolve()
    root = data_root.expanduser().resolve()
    try:
        rel = resolved.relative_to(root)
        return f"DATA_ROOT/{rel.as_posix()}"
    except ValueError:
        return path.name


def diff_thresholds() -> Dict[str, float]:
    return {
        "Puristus_mean0": 2.0,
        "Puristus_mean2": 2.0,
        "Puristus_best0": 2.0,
        "Puristus_best2": 2.0,
        "Grip_asymmetry0": 2.0,
        "Grip_asymmetry2": 2.0,
        "FTSST0": 1.0,
        "FTSST2": 1.0,
        "SLS_mean0": 2.0,
        "SLS_mean2": 2.0,
        "SLS_best0": 2.0,
        "SLS_best2": 2.0,
        "kavelynopeus_m_sek0": 0.1,
        "kavelynopeus_m_sek2": 0.1,
    }


def classify_metric(
    metric: str,
    stats: Dict[str, float],
    corr_threshold: float,
    min_overlap: int,
    missing_min_count: int,
    diff_threshold_map: Dict[str, float],
) -> Tuple[Dict[str, bool], str]:
    n_csv = stats["non_missing_csv"]
    n_excel = stats["non_missing_excel"]
    overlap = stats["non_missing_overlap"]
    corr = stats["correlation"]
    mad = stats["mean_abs_diff"]
    diff_thr = diff_threshold_map.get(metric, 1.0)

    missing_in_one_source = (n_csv < missing_min_count <= n_excel) or (
        n_excel < missing_min_count <= n_csv
    )
    overlap_low = overlap < min_overlap
    corr_below_threshold = corr is not None and corr < corr_threshold
    mean_abs_diff_large = mad is not None and mad > diff_thr

    flags = {
        "missing_in_one_source": missing_in_one_source,
        "overlap_low": overlap_low,
        "corr_below_threshold": corr_below_threshold,
        "mean_abs_diff_large": mean_abs_diff_large,
    }

    if missing_in_one_source or overlap_low or (corr_below_threshold and mean_abs_diff_large):
        status = "RED"
    elif corr_below_threshold or mean_abs_diff_large:
        status = "YELLOW"
    else:
        status = "GREEN"
    return flags, status


def recommended_action(status: str) -> str:
    if status == "GREEN":
        return "usable_across_sources"
    if status == "YELLOW":
        return "document_operationalization_choice"
    return "do_not_pool_sources_without_manual_resolution"


def operationalization_note(metric: str, status: str) -> str:
    if metric.startswith("Puristus_"):
        return (
            "Puristus metrics differ between csv_standardized and "
            "excel_raw_harmonized sources; treat as likely source/preprocessing "
            "difference, not automatic data error."
        )
    if metric.startswith("Grip_asymmetry"):
        return (
            "Grip asymmetry is sensitive to right/left component differences; "
            "use as sensitivity/exploratory metric unless source harmonization "
            "is explicitly resolved."
        )
    if status == "YELLOW":
        return "Minor operationalization difference detected; keep source choice explicit."
    return "Manual review needed before pooling across sources."


def build_markdown(
    report: Dict[str, object],
    metrics: List[str],
    thresholds: Dict[str, float],
    corr_threshold: float,
    min_overlap: int,
) -> str:
    lines = [
        "# Functional Tests Source QC Summary",
        "",
        f"- Source CSV: `{report['source_csv']}`",
        f"- Source Excel: `{report['source_excel']}`",
        f"- Join key used: `{report['join_key_used']}`",
        f"- Rows overlap: `{report['rows_overlap_by_id']}`",
        f"- Thresholds: corr>={corr_threshold}, min_overlap>={min_overlap}",
        "",
        "| Metric | CSV non-missing | Excel non-missing | Overlap | Corr | Mean abs diff | Status | Flags |",
        "|---|---:|---:|---:|---:|---:|---|---|",
    ]
    for metric in metrics:
        m = report["metrics"][metric]
        corr = m["correlation"]
        mad = m["mean_abs_diff"]
        corr_txt = "NA" if corr is None else f"{corr:.3f}"
        mad_txt = "NA" if mad is None else f"{mad:.3f}"
        active_flags = [k for k, v in m["flags"].items() if v]
        flag_txt = ", ".join(active_flags) if active_flags else "-"
        lines.append(
            f"| {metric} | {m['non_missing_csv']} | {m['non_missing_excel']} | "
            f"{m['non_missing_overlap']} | {corr_txt} | {mad_txt} | "
            f"{m['status']} | {flag_txt} |"
        )
    lines.extend(
        [
            "",
            "## Operationalization Notes",
            "",
            "| Metric | Status | Interpretation | Recommended action |",
            "|---|---|---|---|",
        ]
    )
    for metric in metrics:
        m = report["metrics"][metric]
        if m["status"] not in {"RED", "YELLOW"}:
            continue
        lines.append(
            f"| {metric} | {m['status']} | {m['operationalization_note']} | "
            f"{m['recommended_action']} |"
        )
    lines.extend(
        [
            "",
            "## Status Legend",
            "- `GREEN`: no QC flags",
            "- `YELLOW`: potential operationalization difference",
            "- `RED`: needs manual check (availability/overlap mismatch or major discrepancy)",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    args = parse_args()
    data_root = require_data_root(args.data_root)

    csv_path = (
        Path(args.csv_derived).expanduser().resolve()
        if args.csv_derived
        else data_root / "derived" / "fof_functional_tests_from_csv.csv"
    )
    excel_path = (
        Path(args.excel_derived).expanduser().resolve()
        if args.excel_derived
        else data_root / "derived" / "fof_functional_tests_from_excel.csv"
    )
    out_path = (
        Path(args.out_json).expanduser().resolve()
        if args.out_json
        else data_root / "derived" / "fof_functional_tests_compare.json"
    )
    out_md = (
        Path(args.out_md).expanduser().resolve()
        if args.out_md
        else data_root / "derived" / "fof_functional_tests_compare.md"
    )

    if not csv_path.exists():
        raise SystemExit(f"ERROR: csv-derived dataset not found: {csv_path}")
    if not excel_path.exists():
        raise SystemExit(f"ERROR: excel-derived dataset not found: {excel_path}")

    csv_df = pd.read_csv(csv_path, low_memory=False)
    excel_df = pd.read_csv(excel_path, low_memory=False)

    metrics: List[str] = [
        "Puristus_mean0",
        "Puristus_mean2",
        "Puristus_best0",
        "Puristus_best2",
        "Grip_asymmetry0",
        "Grip_asymmetry2",
        "FTSST0",
        "FTSST2",
        "SLS_mean0",
        "SLS_mean2",
        "SLS_best0",
        "SLS_best2",
        "kavelynopeus_m_sek0",
        "kavelynopeus_m_sek2",
    ]

    keep_cols = [c for c in ["id", "nro"] if c in csv_df.columns] + [
        m for m in metrics if m in csv_df.columns
    ]
    csv_df = csv_df[keep_cols].copy()
    keep_cols = [c for c in ["id", "nro"] if c in excel_df.columns] + [
        m for m in metrics if m in excel_df.columns
    ]
    excel_df = excel_df[keep_cols].copy()

    csv_df["id_key"] = normalize_key(csv_df["id"]) if "id" in csv_df.columns else ""
    excel_df["id_key"] = normalize_key(excel_df["id"]) if "id" in excel_df.columns else ""

    join_key = "id_key"
    merged = csv_df.merge(excel_df, on=join_key, how="inner", suffixes=("_csv", "_excel"))
    if len(merged) == 0 and "nro" in csv_df.columns and "nro" in excel_df.columns:
        csv_df["nro_key"] = normalize_key(csv_df["nro"])
        excel_df["nro_key"] = normalize_key(excel_df["nro"])
        join_key = "nro_key"
        merged = csv_df.merge(
            excel_df,
            on=join_key,
            how="inner",
            suffixes=("_csv", "_excel"),
        )

    threshold_map = diff_thresholds()
    comparison = {}
    for metric in metrics:
        stats = metric_stats(merged, metric)
        flags, status = classify_metric(
            metric=metric,
            stats=stats,
            corr_threshold=args.corr_threshold,
            min_overlap=args.min_overlap,
            missing_min_count=args.missing_min_count,
            diff_threshold_map=threshold_map,
        )
        stats["flags"] = flags
        stats["status"] = status
        stats["recommended_action"] = recommended_action(status)
        stats["operationalization_note"] = operationalization_note(metric, status)
        stats["mean_abs_diff_threshold"] = threshold_map.get(metric, 1.0)
        comparison[metric] = stats

    report = {
        "source_csv": to_data_root_relative(csv_path, data_root),
        "source_excel": to_data_root_relative(excel_path, data_root),
        "rows_csv": int(len(csv_df)),
        "rows_excel": int(len(excel_df)),
        "rows_overlap_by_id": int(len(merged)),
        "join_key_used": join_key,
        "thresholds": {
            "corr_threshold": args.corr_threshold,
            "min_overlap": args.min_overlap,
            "missing_min_count": args.missing_min_count,
            "mean_abs_diff_thresholds": threshold_map,
        },
        "metrics": comparison,
    }
    md_text = build_markdown(
        report=report,
        metrics=metrics,
        thresholds=threshold_map,
        corr_threshold=args.corr_threshold,
        min_overlap=args.min_overlap,
    )

    print("DATA_ROOT detected.")
    print(f"Rows overlap by id: {report['rows_overlap_by_id']}")
    print(
        "Quick QC: "
        f"FTSST0 corr={report['metrics']['FTSST0']['correlation']}, "
        f"Puristus_mean0 corr={report['metrics']['Puristus_mean0']['correlation']}"
    )

    if args.write:
        out_path.parent.mkdir(parents=True, exist_ok=True)
        with out_path.open("w", encoding="utf-8") as fh:
            json.dump(report, fh, ensure_ascii=False, indent=2)
        out_md.parent.mkdir(parents=True, exist_ok=True)
        out_md.write_text(md_text, encoding="utf-8")
        print("Comparison JSON written under DATA_ROOT/derived/.")
        print("Comparison markdown written under DATA_ROOT/derived/.")
    else:
        print("Dry-run mode: no files written. Use --write to save outputs.")


if __name__ == "__main__":
    main()
