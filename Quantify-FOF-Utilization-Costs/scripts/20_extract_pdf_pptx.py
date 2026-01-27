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

    # TODO (layout-aware extraction):
    # Plain text extraction often destroys table structure. Prefer a layout-aware pipeline:
    # - Extract tables as separate chunks (e.g., Markdown tables) with page references.
    # - Keep narrative text chunks separate from tables.
    # - Write JSONL with chunk metadata:
    #   {source_file, page, chunk_type(text|table), content_md, bbox(optional), created_at}
    #
    # Keep dependencies optional and off-by-default. Ensure no raw PDFs/PPTX are copied into repo paths and
    # outputs stay non-sensitive (derived_text is gitignored; do not store confidential content if not permitted).

    msg = (
        "Extraction skeleton only. Next step: implement layout-aware chunking (tables as Markdown chunks) "
        "into docs/derived_text/*.jsonl with page metadata. No extraction performed."
    )
    if not args.dry_run:
        write_placeholder(DERIVED_DIR / "extract_log.json", msg)
    print(msg)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
