#!/usr/bin/env python3
"""
32_qc_controls_delivery.py - PASS/FAIL checks for controls delivery files.

Exit codes:
  0 = PASS
  2 = FAIL (QC failed)
  1 = ERROR (unexpected/runtime)

Checks:
  - config keys set: table3.controls_link_table, table3.controls_panel_file
  - files exist under DATA_ROOT
  - controls_link_table columns: id, register_id
  - controls_panel columns: id, case_status, fof_status, age, sex, py
  - non-empty / non-NA values for required IDs
  - uniqueness of link.id, link.register_id, panel.id
  - controls_panel case_status must be only control
  - controls_panel py must be numeric and > 0
  - no orphan IDs between link and panel

Outputs only safe counts and reasons; never prints identifiers.
"""

from __future__ import annotations

import csv
import os
import sys
from dataclasses import dataclass
from typing import Dict, List, Sequence, Tuple

import yaml

try:
    from scripts.path_resolver import get_data_root
except ModuleNotFoundError:
    from path_resolver import get_data_root


@dataclass
class QCResult:
    ok: bool
    code: int
    messages: List[str]
    warnings: List[str]


def _fail(msg: str) -> QCResult:
    return QCResult(ok=False, code=2, messages=[msg], warnings=[])


def _error(msg: str) -> QCResult:
    return QCResult(ok=False, code=1, messages=[msg], warnings=[])


def _pass(msgs: List[str], warns: List[str]) -> QCResult:
    return QCResult(ok=True, code=0, messages=msgs, warnings=warns)


def _read_config(path: str) -> Dict:
    with open(path, encoding="utf-8") as f:
        cfg = yaml.safe_load(f)
    return cfg or {}


def _read_csv(path: str) -> Tuple[List[str], List[Dict[str, str]]]:
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        cols = reader.fieldnames or []
    if not rows:
        raise ValueError(f"empty CSV: {os.path.basename(path)}")
    return cols, rows


def _is_empty(val: str) -> bool:
    v = (val or "").strip()
    return v == "" or v.lower() == "na"


def _to_float(val: str):
    try:
        return float((val or "").strip())
    except Exception:
        return None


def qc_controls_delivery() -> QCResult:
    msgs: List[str] = []
    warns: List[str] = []

    try:
        cfg = _read_config("config/config.yaml")
    except Exception as e:
        return _error(f"Could not read config/config.yaml: {type(e).__name__}: {e}")

    t3 = cfg.get("table3", {}) if isinstance(cfg, dict) else {}
    link_rel = (t3.get("controls_link_table") or "").strip()
    panel_rel = (t3.get("controls_panel_file") or "").strip()

    if not link_rel:
        return _fail("table3.controls_link_table is empty in config/config.yaml")
    if not panel_rel:
        return _fail("table3.controls_panel_file is empty in config/config.yaml")

    try:
        data_root = get_data_root(require=True)
    except SystemExit as e:
        return _fail(str(e))
    except Exception as e:
        return _error(f"Could not resolve DATA_ROOT: {type(e).__name__}: {e}")

    assert data_root is not None
    link_path = os.path.join(str(data_root), link_rel)
    panel_path = os.path.join(str(data_root), panel_rel)

    if not os.path.exists(link_path):
        return _fail("controls_link_table file missing under DATA_ROOT")
    if not os.path.exists(panel_path):
        return _fail("controls_panel_file file missing under DATA_ROOT")

    msgs.append("OK: controls files configured and present under DATA_ROOT")

    try:
        link_cols, link_rows = _read_csv(link_path)
        panel_cols, panel_rows = _read_csv(panel_path)
    except Exception as e:
        return _fail(f"Could not read controls CSV(s): {type(e).__name__}: {e}")

    for col in ("id", "register_id"):
        if col not in link_cols:
            return _fail(f"controls_link_table missing required column: {col}")

    link_ids = [(r.get("id") or "").strip() for r in link_rows]
    link_regs = [(r.get("register_id") or "").strip() for r in link_rows]

    if any(_is_empty(v) for v in link_ids):
        return _fail("controls_link_table has empty/NA id")
    if any(_is_empty(v) for v in link_regs):
        return _fail("controls_link_table has empty/NA register_id")
    if len(set(link_ids)) != len(link_ids):
        return _fail("controls_link_table id must be unique")
    if len(set(link_regs)) != len(link_regs):
        return _fail("controls_link_table register_id must be unique")

    for col in ("id", "case_status", "fof_status", "age", "sex", "py"):
        if col not in panel_cols:
            return _fail(f"controls_panel_file missing required column: {col}")

    panel_ids = [(r.get("id") or "").strip() for r in panel_rows]
    if any(_is_empty(v) for v in panel_ids):
        return _fail("controls_panel_file has empty/NA id")
    if len(set(panel_ids)) != len(panel_ids):
        return _fail("controls_panel_file id must be unique")

    statuses = {((r.get("case_status") or "").strip().lower()) for r in panel_rows}
    if statuses != {"control"}:
        return _fail(f"controls_panel_file case_status must be only control (got {sorted(statuses)})")

    py_vals = [_to_float(r.get("py") or "") for r in panel_rows]
    if any(v is None for v in py_vals) or any(v <= 0 for v in py_vals if v is not None):
        return _fail("controls_panel_file py must be numeric and > 0")

    link_set = set(link_ids)
    panel_set = set(panel_ids)
    if link_set - panel_set:
        return _fail("orphan ids in controls_link_table (missing in controls_panel_file)")
    if panel_set - link_set:
        return _fail("orphan ids in controls_panel_file (missing in controls_link_table)")

    msgs.append("OK: schema, non-empty values, uniqueness, status, py, and orphan checks passed")
    msgs.append(
        "safe_counts: "
        + str(
            {
                "link_rows": len(link_rows),
                "panel_rows": len(panel_rows),
                "shared_ids": len(link_set & panel_set),
            }
        )
    )

    return _pass(msgs, warns)


def main(argv: Sequence[str]) -> int:
    _ = argv
    res = qc_controls_delivery()
    for w in res.warnings:
        print(w)
    for m in res.messages:
        print(m)

    if res.ok:
        print("PASS: controls delivery QC")
        return 0

    print("FAIL: controls delivery QC")
    return res.code


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
