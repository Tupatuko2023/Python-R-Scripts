#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import zipfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable, List, Dict

PROJECT_ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = PROJECT_ROOT / "outputs" / "knowledge"
ZIP_PATH = OUT_DIR / "knowledge_package.zip"
INDEX_PATH = OUT_DIR / "index.json"

INCLUDE_DIRS = [
    PROJECT_ROOT / "data",
    PROJECT_ROOT / "manifest",
    PROJECT_ROOT / "docs",
    PROJECT_ROOT / "tests",
]

EXCLUDE_PATHS = {
    PROJECT_ROOT / "config" / ".env",
}

EXCLUDE_DIR_NAMES = {"__pycache__", ".pytest_cache"}
IDENT_TOKENS = ("id,", " id ")


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def sha256_file(path: Path, chunk_size: int = 1024 * 1024) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        while True:
            chunk = f.read(chunk_size)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()


def get_git_commit() -> str:
    try:
        out = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=str(PROJECT_ROOT), text=True).strip()
        return out
    except Exception:
        return "UNKNOWN"


def iter_files() -> Iterable[Path]:
    for d in INCLUDE_DIRS:
        if not d.exists():
            continue
        for p in d.rglob("*"):
            if p.is_dir():
                if p.name in EXCLUDE_DIR_NAMES:
                    continue
                continue
            if p in EXCLUDE_PATHS:
                continue
            if "outputs" in p.parts:
                continue
            yield p


def safety_check_identifier(paths: List[Path]) -> None:
    for p in paths:
        if p.suffix.lower() not in {".jsonl", ".txt", ".md", ".csv", ".json"}:
            continue
        try:
            txt = p.read_text(encoding="utf-8", errors="ignore").lower()
        except Exception:
            continue
        for tok in IDENT_TOKENS:
            if tok in txt:
                raise SystemExit(f"Safety check failed: identifier-like token found in {p}")


def build_index(entries: List[Dict[str, str]], zip_sha256: str) -> Dict[str, object]:
    return {
        "generated_at": utc_now_iso(),
        "git_commit": get_git_commit(),
        "zip_path": str(ZIP_PATH),
        "zip_sha256": zip_sha256,
        "allow_aggregates_env": (os.environ.get("ALLOW_AGGREGATES") or ""),
        "file_count": len(entries),
        "files": entries,
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Build agent-ready knowledge package (non-sensitive).")
    ap.add_argument("--out", default=str(ZIP_PATH), help="Output zip path.")
    ap.add_argument("--include-derived", action="store_true", help="Include docs/derived_text if present.")
    args = ap.parse_args()

    out_zip = Path(args.out)
    out_zip.parent.mkdir(parents=True, exist_ok=True)

    paths = list(iter_files())

    derived_dir = PROJECT_ROOT / "docs" / "derived_text"
    derived_paths: List[Path] = []
    if args.include_derived and derived_dir.exists():
        for p in derived_dir.rglob("*"):
            if p.is_file():
                paths.append(p)
                derived_paths.append(p)

    paths = [p for p in paths if p not in EXCLUDE_PATHS and "outputs" not in p.parts]
    # Defense-in-depth: only check derived_text content for identifier-like tokens.
    if derived_paths:
        safety_check_identifier(derived_paths)

    entries: List[Dict[str, str]] = []
    with zipfile.ZipFile(out_zip, "w", compression=zipfile.ZIP_DEFLATED) as z:
        for p in sorted(set(paths)):
            rel = p.relative_to(PROJECT_ROOT).as_posix()
            z.write(p, arcname=rel)
            entries.append({"path": rel, "sha256": sha256_file(p)})

    zip_sha = sha256_file(out_zip)
    idx = build_index(entries, zip_sha)
    INDEX_PATH.write_text(json.dumps(idx, ensure_ascii=True, indent=2), encoding="utf-8")
    print(f"Wrote: {out_zip}")
    print(f"Wrote: {INDEX_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
