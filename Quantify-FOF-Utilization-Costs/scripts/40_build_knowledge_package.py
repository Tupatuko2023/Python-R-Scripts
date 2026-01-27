#!/usr/bin/env python3
from __future__ import annotations

import argparse
import zipfile
from datetime import datetime, timezone
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = PROJECT_ROOT / "outputs" / "knowledge_package"


def add_dir(zipf: zipfile.ZipFile, base: Path, arc_prefix: str) -> None:
    if not base.exists():
        return
    for p in sorted(base.rglob("*")):
        if p.is_file():
            rel = p.relative_to(base)
            zipf.write(p, f"{arc_prefix}/{rel.as_posix()}")


def main() -> int:
    ap = argparse.ArgumentParser(description="Build agent-ready knowledge package (no raw data).")
    ap.add_argument("--out", default=None, help="Output zip path (optional).")
    args = ap.parse_args()

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    out_path = Path(args.out) if args.out else (OUT_DIR / f"knowledge_package_{ts}.zip")

    with zipfile.ZipFile(out_path, "w", compression=zipfile.ZIP_DEFLATED) as z:
        add_dir(z, PROJECT_ROOT / "docs", "docs")
        add_dir(z, PROJECT_ROOT / "data", "data")  # includes only metadata + synthetic sample
        add_dir(z, PROJECT_ROOT / "manifest", "manifest")
        add_dir(z, PROJECT_ROOT / "outputs" / "qc", "outputs/qc")

    print(f"Wrote: {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
