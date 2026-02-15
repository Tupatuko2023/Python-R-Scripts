#!/usr/bin/env python3
from __future__ import annotations

import csv
from datetime import datetime
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple

DATE_HINTS = ("date", "pvm", "paiva")
KEY_CANDIDATES = {
    "person_id": ["person_id", "henkilo_id", "henkiloid", "patient_id", "subject_id", "pseudonym"],
    "event_id": ["event_id", "kaynti_id", "visit_id"],
    "episode_id": ["episode_id", "osastojakso_id", "episodeid"],
}


def normalize_col_name(name: str) -> str:
    return name.strip().lower().replace(" ", "_").replace("/", "_")


def detect_delimiter(path: Path) -> str:
    with path.open("r", encoding="utf-8", newline="") as f:
        line = f.readline()
    return "|" if line.count("|") > line.count(",") else ","


def safe_join_path(base: Path, *parts: str) -> Path:
    """
    Safely join path parts to a base directory, preventing path traversal.
    Raises ValueError if the resulting path is outside the base directory.
    """
    resolved_base = base.resolve()
    # Path.joinpath handles absolute paths by replacing the base, which we want to block if they leave the boundary.
    joined = resolved_base.joinpath(*parts)
    resolved_path = joined.resolve()

    # Use is_relative_to (Python 3.9+) for robust boundary checking.
    # This prevents sibling directory vulnerabilities (e.g., /app/data vs /app/data_sensitive).
    try:
        resolved_path.relative_to(resolved_base)
    except ValueError:
        # Security: Do NOT leak absolute paths in the error message (Option B)
        raise ValueError("Security Violation: Path traversal detected or path outside restricted boundary.")

    return resolved_path


def read_csv_rows(path: Path) -> Tuple[List[Dict[str, str]], List[str]]:
    delim = detect_delimiter(path)
    rows: List[Dict[str, str]] = []
    with path.open("r", encoding="utf-8", newline="") as f:
        dr = csv.DictReader(f, delimiter=delim)
        cols = [normalize_col_name(c) for c in (dr.fieldnames or [])]
        for row in dr:
            rows.append({
                normalize_col_name(k): ("" if v is None else str(v)) for k, v in row.items()
            })
    return rows, cols


def read_xlsx_rows(path: Path, header_row: int = 1, sheet_name: str | None = None) -> Tuple[List[Dict[str, str]], List[str]]:
    try:
        import openpyxl
    except ModuleNotFoundError:
        raise SystemExit("Missing dependency for XLSX parsing.")

    rows_out: List[Dict[str, str]] = []
    cols_out: List[str] = []
    wb = openpyxl.load_workbook(path, read_only=True, data_only=True)
    sheets = [wb[sheet_name]] if sheet_name else wb.worksheets

    for ws in sheets:
        header: Optional[List[str]] = None
        for idx, row in enumerate(ws.iter_rows(values_only=True), start=1):
            if idx < header_row:
                continue
            if idx == header_row:
                header = [normalize_col_name("" if c is None else str(c)) for c in row]
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


def read_rows(path: Path, header_row: int = 1) -> Tuple[List[Dict[str, str]], List[str]]:
    if path.suffix.lower() == ".csv":
        return read_csv_rows(path)
    if path.suffix.lower() in {".xlsx", ".xls"}:
        return read_xlsx_rows(path, header_row=header_row)
    raise ValueError("Unsupported file type.")


def parse_date(value: str) -> Optional[str]:
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


def iter_date_columns(cols: Iterable[str], date_hints: Iterable[str] = DATE_HINTS) -> Iterable[str]:
    for c in cols:
        lc = str(c).lower()
        if any(h in lc for h in date_hints):
            yield c


def normalize_dates(rows: List[Dict[str, str]], cols: List[str], date_hints: Iterable[str] = DATE_HINTS) -> None:
    date_cols = [c for c in cols if any(h in c for h in date_hints)]
    if not date_cols:
        return
    for row in rows:
        for c in date_cols:
            val = row.get(c, "")
            if val is None or str(val).strip() == "":
                continue
            parsed = parse_date(str(val))
            row[c] = parsed if parsed is not None else ""


def key_columns(cols: Iterable[str], key_candidates: Dict[str, List[str]] = KEY_CANDIDATES) -> List[Tuple[str, str]]:
    out: List[Tuple[str, str]] = []
    cols_map = {c.lower(): c for c in cols}
    for key, candidates in key_candidates.items():
        for cand in candidates:
            if cand in cols_map:
                out.append((key, cols_map[cand]))
                break
    return out


def normalize_keys(
    rows: List[Dict[str, str]],
    cols: List[str],
    key_candidates: Dict[str, List[str]] = KEY_CANDIDATES,
) -> Tuple[List[Dict[str, str]], List[str]]:
    cols_map = {c.lower(): c for c in cols}
    for canonical, candidates in key_candidates.items():
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


def normalize_manifest_location(location: str) -> str:
    return location.replace("\\", "/")


def manifest_relative_path(location: str, segment: str = "paper_02") -> Optional[str]:
    loc_norm = normalize_manifest_location(location)
    parts = [p for p in loc_norm.split("/") if p]
    if segment not in parts:
        return None
    idx = parts.index(segment)
    rel_parts = parts[idx + 1 :]
    if not rel_parts:
        return None
    return "/".join(rel_parts)
