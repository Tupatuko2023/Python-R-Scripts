#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import hashlib
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Iterable, List

from path_resolver import get_data_root, get_paper02_dir

PROJECT_ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = PROJECT_ROOT / "manifest" / "dataset_manifest.csv"


def sha256_file(path: Path, chunk_size: int = 1024 * 1024) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        while True:
            b = f.read(chunk_size)
            if not b:
                break
            h.update(b)
    return h.hexdigest()


def iter_files(base: Path, patterns: List[str]) -> Iterable[Path]:
    for pat in patterns:
        yield from base.glob(pat)


def load_manifest_rows() -> List[Dict[str, str]]:
    if not MANIFEST_PATH.exists():
        return []
    with MANIFEST_PATH.open("r", encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def write_manifest_rows(rows: List[Dict[str, str]], fieldnames: List[str]) -> None:
    MANIFEST_PATH.parent.mkdir(parents=True, exist_ok=True)
    with MANIFEST_PATH.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        for r in rows:
            w.writerow({k: r.get(k, "") for k in fieldnames})


def main() -> int:
    ap = argparse.ArgumentParser(
        description=(
            "Scan repo-external DATA_ROOT inputs and update dataset_manifest.csv "
            "(metadata only; no file copying)."
        )
    )
    ap.add_argument("--scan", default=None, help="Logical scan target (e.g., paper_02).")
    ap.add_argument(
        "--patterns",
        nargs="+",
        default=["*.csv", "*.xlsx", "*.pdf", "*.pptx"],
        help="Glob patterns.",
    )
    ap.add_argument("--dry-run", action="store_true", help="Do not write manifest; print only.")
    args = ap.parse_args()

    data_root = get_data_root(require=False)
    if not data_root or not data_root.exists():
        print("DATA_ROOT is not set or does not exist. Nothing to scan.")
        print("Create config/.env from config/.env.example and set DATA_ROOT to your secure repo-external folder.")
        return 0

    if not args.scan:
        print("No --scan target provided. Use --help to see options.")
        return 0

    if args.scan == "paper_02":
        base = get_paper02_dir(data_root)
    else:
        print(f"Unknown scan target: {args.scan}")
        return 2

    if not base.exists():
        print(f"Scan base does not exist: {base}")
        return 0

    files = sorted({p for p in iter_files(base, args.patterns) if p.is_file()})
    if not files:
        print(f"No files matched under: {base}")
        return 0

    now = datetime.now(timezone.utc).isoformat()
    print(f"Found {len(files)} files under {base}")

    rows = load_manifest_rows()
    default_fields = [
        "logical_name",
        "file_glob",
        "location",
        "sha256",
        "rows",
        "cols",
        "schema_ref",
        "version",
        "updated_at",
        "owner",
        "permit_id",
        "sensitivity_level",
        "notes",
    ]
    fieldnames = list(rows[0].keys()) if rows else default_fields
    existing_index = {r.get("logical_name", ""): i for i, r in enumerate(rows)}

    updates: List[Dict[str, str]] = []
    for p in files:
        rel = p.relative_to(base)
        logical = f"paper_02::{rel.as_posix()}"
        entry = {
            "logical_name": logical,
            "file_glob": "",
            "location": f"repo_external:${{DATA_ROOT}}/paper_02/{rel.as_posix()}",
            "sha256": sha256_file(p),
            "rows": "",
            "cols": "",
            "schema_ref": "",
            "version": "",
            "updated_at": now,
            "owner": "controller",
            "permit_id": "PERMIT_TODO",
            "sensitivity_level": "high",
            "notes": "Checksum only; file not copied into repo.",
        }
        updates.append(entry)

    if args.dry_run:
        for u in updates[:10]:
            print(u["logical_name"], u["sha256"])
        if len(updates) > 10:
            print("... (truncated)")
        return 0

    for u in updates:
        key = u["logical_name"]
        if key in existing_index:
            rows[existing_index[key]] = {**rows[existing_index[key]], **u}
        else:
            rows.append(u)

    write_manifest_rows(rows, fieldnames=fieldnames)
    print(f"Updated manifest: {MANIFEST_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
