#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable, List

PROJECT_ROOT = Path(__file__).resolve().parents[1]
QC_DIR = PROJECT_ROOT / "outputs" / "qc"
AGG_PATH = PROJECT_ROOT / "outputs" / "aggregates" / "aim2_aggregates.csv"
OUT_DIR = PROJECT_ROOT / "outputs" / "reports"
DEFAULT_OUT = OUT_DIR / "aim2_report.md"
RUN_LOG_LOCAL = PROJECT_ROOT / "manifest" / "run_log.local.csv"


def _read_text_lines(path: Path, max_lines: int = 60) -> List[str]:
    if not path.exists():
        return []
    lines = path.read_text(encoding="utf-8").splitlines()
    if len(lines) > max_lines:
        lines = lines[:max_lines] + ["... (truncated)"]
    return lines


def _read_csv_filtered(path: Path, max_lines: int = 60) -> List[str]:
    if not path.exists():
        return []
    lines: List[str] = []
    with path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.reader(f)
        for row in reader:
            if any((cell or "").strip().lower() == "id" for cell in row):
                continue
            lines.append(",".join(row))
            if len(lines) >= max_lines:
                lines.append("... (truncated)")
                break
    return lines


def _append_run_log(out_path: Path, status: str, notes: str) -> None:
    header = [
        "run_id",
        "timestamp",
        "git_commit",
        "config_hash",
        "input_manifest_version",
        "outputs_written",
        "status",
        "notes",
    ]
    RUN_LOG_LOCAL.parent.mkdir(parents=True, exist_ok=True)
    now_ts = datetime.now(timezone.utc).isoformat()
    row = [
        f"report_{now_ts}",
        now_ts,
        "UNKNOWN",
        "UNKNOWN",
        "",  # input_manifest_version
        str(out_path),
        status,
        notes,
    ]

    write_header = not RUN_LOG_LOCAL.exists()
    with RUN_LOG_LOCAL.open("a", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        if write_header:
            w.writerow(header)
        w.writerow(row)


def main() -> int:
    ap = argparse.ArgumentParser(description="Build non-sensitive Aim 2 report from QC + optional aggregates.")
    ap.add_argument("--out", default=str(DEFAULT_OUT), help="Output report path.")
    args = ap.parse_args()

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    qc_overview = QC_DIR / "qc_overview.csv"
    qc_inputs = QC_DIR / "qc_inputs.csv"
    qc_missing = QC_DIR / "qc_missingness.csv"
    qc_schema = QC_DIR / "qc_schema_drift.csv"

    ts = datetime.now(timezone.utc).isoformat()

    parts: List[str] = []
    parts.append(f"# Aim 2 report (non-sensitive)\n\nGenerated: {ts}\n")

    if qc_overview.exists():
        parts.append("## QC overview\n")
        parts.append("```text\n" + "\n".join(_read_csv_filtered(qc_overview)) + "\n```\n")
    else:
        parts.append("## QC overview\n\nMissing: outputs/qc/qc_overview.csv\n")

    if qc_inputs.exists():
        parts.append("## QC inputs\n")
        parts.append("```text\n" + "\n".join(_read_csv_filtered(qc_inputs)) + "\n```\n")
    else:
        parts.append("## QC inputs\n\nMissing: outputs/qc/qc_inputs.csv\n")

    if qc_missing.exists():
        parts.append("## QC missingness\n")
        parts.append("```text\n" + "\n".join(_read_csv_filtered(qc_missing)) + "\n```\n")
    else:
        parts.append("## QC missingness\n\nMissing: outputs/qc/qc_missingness.csv\n")

    if qc_schema.exists():
        parts.append("## QC schema drift\n")
        parts.append("```text\n" + "\n".join(_read_csv_filtered(qc_schema)) + "\n```\n")
    else:
        parts.append("## QC schema drift\n\nMissing: outputs/qc/qc_schema_drift.csv\n")

    if AGG_PATH.exists():
        parts.append("## Aggregates (suppressed where applicable)\n")
        parts.append("```text\n" + "\n".join(_read_csv_filtered(AGG_PATH)) + "\n```\n")
    else:
        parts.append(
            "## Aggregates\n\nNot present (opt-in). If permitted, enable ALLOW_AGGREGATES=1 and run preprocess with --allow-aggregates.\n"
        )

    report = "\n".join(parts)

    if "id," in report.lower() or " id " in report.lower():
        _append_run_log(out_path, "FAILED", "Safety check failed: identifier-like text found")
        raise SystemExit("Safety check failed: report appears to contain identifier-like text (id).")

    out_path.write_text(report, encoding="utf-8")
    _append_run_log(out_path, "OK", "report generated")
    print(f"Wrote: {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
