#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple

from path_resolver import get_data_root, get_paper02_dir
from qc_no_abs_paths_check import scan_paths
from _io_utils import (
    manifest_relative_path,
    normalize_dates,
    normalize_keys,
    read_rows,
)

PROJECT_ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = PROJECT_ROOT / "outputs" / "assembled" / "paper_02"
REPORT_PATH = PROJECT_ROOT / "outputs" / "reports" / "paper_02_integration_map.md"
MANIFEST_PATH = PROJECT_ROOT / "manifest" / "dataset_manifest.csv"

@dataclass
class Source:
    source_id: str
    path: Path


def _slugify(text: str) -> str:
    out = []
    for ch in text.lower():
        if ch.isalnum():
            out.append(ch)
        else:
            out.append("_")
    slug = "".join(out).strip("_")
    while "__" in slug:
        slug = slug.replace("__", "_")
    return slug[:80] if slug else "source"


def _load_rows(path: Path) -> Tuple[List[Dict[str, str]], List[str]]:
    if path.suffix.lower() == ".csv":
        return read_rows(path)
    if path.suffix.lower() in {".xlsx", ".xls"}:
        header_row = 2 if "kaaos" in path.name.lower() else 1
        return read_rows(path, header_row=header_row)
    raise ValueError("Unsupported file type.")


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
            p = base / rel
            if p.suffix.lower() not in {".csv", ".xlsx", ".xls"}:
                continue
            if "kopio" in p.name.lower():
                continue
            sources.append(Source(source_id=logical, path=p))
    return sources


def _collect_sources(input_root: str | None, manifest: str | None) -> List[Source]:
    sources: List[Source] = []
    if input_root:
        sources.extend(_collect_from_dir(Path(input_root)))
    if manifest:
        sources.extend(_collect_from_manifest(Path(manifest)))
    return sources


def _assign_role(source_id: str) -> str:
    name = source_id.lower()
    if "kaynnit" in name or "pkl" in name or "visit" in name:
        return "events"
    if "osastojakso" in name or "episode" in name:
        return "episodes"
    if "diag" in name:
        return "diagnoses"
    if "verrokit" in name or "cohort" in name:
        return "cohort"
    if "cost" in name or "hinta" in name or "kustannus" in name or "kaaos" in name:
        return "cost_or_price"
    if "sotu" in name or "link" in name:
        return "linkage"
    return "other"


def _write_csv(path: Path, rows: List[Dict[str, str]], cols: List[str]) -> None:
    with path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=cols)
        w.writeheader()
        for row in rows:
            w.writerow({c: row.get(c, "") for c in cols})


def _write_integration_map(
    sources: List[Source],
    roles: Dict[str, str],
    primary_id: str | None,
    normalized_outputs: List[str],
    assembled_output: str | None,
) -> None:
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    lines: List[str] = []
    lines.append("# paper_02 integration map (local-only, Option B)")
    lines.append("")
    lines.append("Sources and roles (logical names):")
    if sources:
        for src in sources:
            role = roles.get(src.source_id, "other")
            lines.append(f"- {src.source_id} -> {role}")
    else:
        lines.append("- pkl_kaynnit -> events")
        lines.append("- osastojaksot -> episodes")
        lines.append("- osastojakso_diagnoosit -> diagnoses")
        lines.append("- verrokit -> cohort")
        lines.append("- lifecare -> cost_or_price")
        lines.append("- kaaos -> cost_or_price")
        lines.append("- sotut -> linkage")
        lines.append("- kuolemansyyt -> linkage")
    lines.append("")
    lines.append("Join keys (expected, normalized):")
    lines.append("- person_id (pseudonymized person identifier)")
    lines.append("- event_id / episode_id when present")
    lines.append("")
    lines.append("Temporal rules (expected):")
    lines.append("- episodes join on person_id + start/end dates")
    lines.append("- diagnoses attach to events or episodes by person_id + date proximity")
    lines.append("")
    lines.append("Primary utilization events table:")
    lines.append(f"- {primary_id or 'pkl_kaynnit_or_equivalent'}")
    lines.append("")
    lines.append("Minimal assembled outputs (gitignored):")
    for name in normalized_outputs:
        lines.append(f"- {name}")
    if assembled_output:
        lines.append(f"- {assembled_output}")
    REPORT_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")
    scan_paths([REPORT_PATH])


def main() -> int:
    ap = argparse.ArgumentParser(description="Assemble paper_02 (local-only; Option B).")
    ap.add_argument("--input-root", default=None, help="Local input directory (no paths in logs).")
    ap.add_argument("--manifest", default=None, help="Manifest CSV (default: manifest/dataset_manifest.csv).")
    args = ap.parse_args()

    manifest = args.manifest
    if not manifest and MANIFEST_PATH.exists():
        manifest = str(MANIFEST_PATH)

    sources = _collect_sources(args.input_root, manifest)
    if not sources:
        print("No local inputs found. Provide --input-root or --manifest.")
        _write_integration_map([], {}, None, [], None)
        return 0

    if args.input_root or args.manifest:
        print("Inputs: --input provided locally")

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    roles: Dict[str, str] = {}
    normalized_outputs: List[str] = []
    primary_id: Optional[str] = None
    primary_rows: List[Dict[str, str]] = []
    primary_cols: List[str] = []

    for src in sources:
        if not src.path.exists():
            continue
        if "kopio" in src.path.name.lower():
            continue
        try:
            rows, cols = _load_rows(src.path)
        except zipfile.BadZipFile:
            continue
        except ValueError:
            continue
        if not rows and not cols:
            continue
        rows, cols = normalize_keys(rows, cols)
        normalize_dates(rows, cols)

        role = _assign_role(src.source_id)
        roles[src.source_id] = role
        if role == "events" and primary_id is None:
            primary_id = src.source_id
            primary_rows = rows
            primary_cols = cols

        slug = _slugify(src.source_id)
        out_name = f"normalized_{slug}.csv"
        out_path = OUT_DIR / out_name
        _write_csv(out_path, rows, cols)
        normalized_outputs.append(f"outputs/assembled/paper_02/{out_name}")

    assembled_output: Optional[str] = None
    if primary_id is None and sources:
        primary_id = sources[0].source_id
        try:
            primary_rows, primary_cols = _load_rows(sources[0].path)
            primary_rows, primary_cols = normalize_keys(primary_rows, primary_cols)
            normalize_dates(primary_rows, primary_cols)
        except Exception:
            primary_rows = []
            primary_cols = []

    if primary_rows and primary_cols:
        assembled_name = "assembled_events.csv"
        assembled_path = OUT_DIR / assembled_name
        _write_csv(assembled_path, primary_rows, primary_cols)
        assembled_output = f"outputs/assembled/paper_02/{assembled_name}"

    _write_integration_map(sources, roles, primary_id, normalized_outputs, assembled_output)
    print("Assembly complete.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
