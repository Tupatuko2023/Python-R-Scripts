#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
from pathlib import Path
from typing import Iterable, List

TEXT_SUFFIXES = {".csv", ".tsv", ".txt", ".md", ".json", ".jsonl"}

ABS_PATTERNS = [
    re.compile(r"[A-Za-z]:\\\\[^\\s]+"),
    re.compile(r"[A-Za-z]:/[^\\s]+"),
    re.compile(r"~/(?:[^\\s]+)"),
    re.compile(r"(?<![A-Za-z0-9_.-])/(?:[^\\s]+)"),
]


def iter_files(paths: Iterable[Path]) -> Iterable[Path]:
    for p in paths:
        if p.is_dir():
            yield from (fp for fp in p.rglob("*") if fp.is_file())
        elif p.is_file():
            yield p


def _looks_like_text(path: Path) -> bool:
    return path.suffix.lower() in TEXT_SUFFIXES


def scan_paths(paths: List[Path]) -> None:
    for path in iter_files(paths):
        if not _looks_like_text(path):
            continue
        data = path.read_text(encoding="utf-8", errors="ignore")
        for pat in ABS_PATTERNS:
            if pat.search(data):
                raise SystemExit(
                    "Absolute path-like string detected in QC artifacts. "
                    "Remove paths and rerun."
                )


def main() -> int:
    ap = argparse.ArgumentParser(description="Fail closed if absolute paths appear in outputs.")
    ap.add_argument("--path", action="append", required=True, help="File or directory to scan.")
    args = ap.parse_args()

    paths = [Path(p) for p in args.path]
    scan_paths(paths)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
