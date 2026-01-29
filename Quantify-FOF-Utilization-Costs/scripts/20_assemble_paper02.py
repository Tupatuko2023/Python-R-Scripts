#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import zipfile
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple

from path_resolver import get_data_root, get_paper02_dir

PROJECT_ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = PROJECT_ROOT / "outputs" / "assembled" / "paper_02"
REPORT_PATH = PROJECT_ROOT / "outputs" / "reports" / "paper_02_integration_map.md"
MANIFEST_PATH = PROJECT_ROOT / "manifest" / "dataset_manifest.csv"

DATE_HINTS = ("date", "pvm", "paiva")
KEY_CANDIDATES = {
    "person_id": ["person_id", "henkilo_id", "henkiloid", "patient_id", "subject_id", "pseudonym"],
    "event_id": ["event_id", "kaynti_id", "visit_id"],
    "episode_id": ["episode_id", "osastojakso_id", "episodeid"],
}


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


def _normalize_col_name(name: str) -> str:
    return name.strip().lower().replace(" ", "_").replace("/", "_")


def _detect_delimiter(path: Path) -> str:
    with path.open("r", encoding="utf-8", newline="") as f:
        line = f.readline()
    return "|" if line.count("|") > line.count(",") else ","


def _read_csv_rows(path: Path) -> Tuple[List[Dict[str, str]], List[str]]:
    delim = _detect_delimiter(path)
    rows: List[Dict[str, str]] = []
    with path.open("r", encoding="utf-8", newline="") as f:
        dr = csv.DictReader(f, delimiter=delim)
        cols = [_normalize_col_name(c) for c in (dr.fieldnames or [])]
        for row in dr:
            rows.append({
                _normalize_col_name(k): ("" if v is None else str(v)) for k, v in row.items()
            })
    return rows, cols


def _read_xlsx_rows(path: Path) -> Tuple[List[Dict[str, str]], List[str]]:
    try:
        import openpyxl
    except ModuleNotFoundError:
        raise SystemExit("Missing dependency for XLSX parsing.")

    rows_out: List[Dict[str, str]] = []
    cols_out: List[str] = []
    wb = openpyxl.load_workbook(path, read_only=True, data_only=True)
    use_header = 2 if "kaaos" in path.name.lower() else 1

    for ws in wb.worksheets:
        header: Optional[List[str]] = None
        for idx, row in enumerate(ws.iter_rows(values_only=True), start=1):
            if idx < use_header:
                continue
            if idx == use_header:
                header = [_normalize_col_name("" if c is None else str(c)) for c in row]
                if not cols_out:
                    cols_out = header
                continue
            if header is None:
                continue
            out_row: Dict[str, str] = {}
            for c, v in zip(header, row):
                out_row[c] = "" if v is None else str(v)
            rows_out.append(out_row)
    return rows_out, cols_out


def _load_rows(path: Path) -> Tuple[List[Dict[str, str]], List[str]]:
    if path.suffix.lower() == ".csv":
        return _read_csv_rows(path)
    if path.suffix.lower() in {".xlsx", ".xls"}:
        return _read_xlsx_rows(path)
    raise ValueError("Unsupported file type.")


def _normalize_keys(rows: List[Dict[str, str]], cols: List[str]) -> Tuple[List[Dict[str, str]], List[str]]:
    cols_map = {c.lower(): c for c in cols}
    for canonical, candidates in KEY_CANDIDATES.items():
        if canonical in cols_map:
            continue
        for cand in candidates:
            if cand in cols_map:
                old = cols_map[cand]
                cols = [canonical if c == old else c for c in cols]
                for row in rows:
                    row[canonical] = row.pop(old, "")
                cols_map[canonical] = canonical
                break
    return rows, cols


def _parse_date(value: str) -> Optional[str]:
    raw = value.strip()
    if not raw:
        return None
    for fmt in (
        "%Y-%m-%d",
        "%Y/%m/%d",
        "%d.%m.%Y",
        "%d/%m/%Y",
        "%Y-%m-%d %H:%M:%S",
    ):
        try:
            return datetime.strptime(raw, fmt).date().isoformat()
        except ValueError:
            continue
    try:
        return datetime.fromisoformat(raw).date().isoformat()
    except ValueError:
        return None


def _normalize_dates(rows: List[Dict[str, str]], cols: List[str]) -> None:
    date_cols = [c for c in cols if any(h in c for h in DATE_HINTS)]
    if not date_cols:
        return
    for row in rows:
        for c in date_cols:
            val = row.get(c, "")
            if val is None or str(val).strip() == "":
                continue
            parsed = _parse_date(str(val))
            row[c] = parsed if parsed is not None else ""


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
            marker = "/paper_02/"
            if marker not in loc:
                continue
            rel = loc.split(marker, 1)[1]
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
        rows, cols = _normalize_keys(rows, cols)
        _normalize_dates(rows, cols)

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
            primary_rows, primary_cols = _normalize_keys(primary_rows, primary_cols)
            _normalize_dates(primary_rows, primary_cols)
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
