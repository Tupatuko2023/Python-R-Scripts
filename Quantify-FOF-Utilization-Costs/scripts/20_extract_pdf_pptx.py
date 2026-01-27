#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

from path_resolver import get_data_root, get_paper02_dir

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DERIVED_DIR = PROJECT_ROOT / "docs" / "derived_text"


def write_placeholder(log_path: Path, message: str) -> None:
    log_path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "SKIPPED",
        "message": message,
    }
    log_path.write_text(json.dumps(payload, ensure_ascii=True, indent=2), encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser(description="Extract text from PDF/PPTX into docs/derived_text (safe-by-default).")
    ap.add_argument("--scan", default="paper_02", help="Scan target (default: paper_02).")
    ap.add_argument("--dry-run", action="store_true", help="Do not write outputs.")
    args = ap.parse_args()

    data_root = get_data_root(require=False)
    if not data_root or not data_root.exists():
        msg = "DATA_ROOT not set; nothing to extract."
        if not args.dry_run:
            write_placeholder(DERIVED_DIR / "extract_log.json", msg)
        print(msg)
        return 0

    if args.scan != "paper_02":
        msg = f"Unknown scan target: {args.scan}"
        if not args.dry_run:
            write_placeholder(DERIVED_DIR / "extract_log.json", msg)
        print(msg)
        return 2

    base = get_paper02_dir(data_root)
    if not base.exists():
        msg = f"Scan base missing: {base}"
        if not args.dry_run:
            write_placeholder(DERIVED_DIR / "extract_log.json", msg)
        print(msg)
        return 0

    msg = (
        "Extraction skeleton only. Install optional libs (PyPDF2, python-pptx) locally if permitted, "
        "then implement extraction."
    )
    if not args.dry_run:
        write_placeholder(DERIVED_DIR / "extract_log.json", msg)
    print(msg)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
