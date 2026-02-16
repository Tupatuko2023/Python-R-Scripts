#!/usr/bin/env python3
"""
31_qc_table3.py - PASS/FAIL QC checks for Table 3 outputs.

Runs lightweight, deterministic checks after:
  snakemake -j 1 --forcerun build_table3_inputs table3
  snakemake -j 1 --forcerun table3

Exit codes:
  0 = PASS
  2 = FAIL (QC failed)
  1 = ERROR (unexpected/runtime)

Checks:
  1) outputs/tables/table3.csv + table3.md exist and non-empty
  2) Both panels/groups populated (WO/FO + ctrl/case columns have some values)
  3) Expected Diagnosis rows present
  4) Derived inputs exist; required columns present; no NA/empty; py > 0
  5) IRR fields populated (not all empty)
  6) Grep logs for suspicious model/runtime keywords (warn-only unless "ERROR"/"FAIL" present)
  7) MD vs CSV row-count consistency (light check)

Notes:
- Does not print absolute paths.
- Prints only safe counts and QC reasons.
"""

from __future__ import annotations

import csv
import os
import re
import sys
from dataclasses import dataclass
from typing import Dict, List, Sequence, Tuple

# Project-local resolver (reads config/.env etc.)
try:
    from scripts.path_resolver import get_data_root  # type: ignore
except Exception as e:  # pragma: no cover
    get_data_root = None  # type: ignore
    _import_err = e


@dataclass
class QCResult:
    ok: bool
    code: int  # 0 pass, 2 qc fail, 1 error
    messages: List[str]
    warnings: List[str]


def _fail(msg: str) -> QCResult:
    return QCResult(ok=False, code=2, messages=[msg], warnings=[])


def _error(msg: str) -> QCResult:
    return QCResult(ok=False, code=1, messages=[msg], warnings=[])


def _pass(msgs: List[str], warns: List[str]) -> QCResult:
    return QCResult(ok=True, code=0, messages=msgs, warnings=warns)


def _read_csv_rows(path: str) -> List[Dict[str, str]]:
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
    if not rows:
        raise ValueError("CSV has no data rows.")
    return rows


def _file_nonempty(rel_path: str) -> bool:
    return os.path.exists(rel_path) and os.path.getsize(rel_path) > 0


def _any_filled(rows: List[Dict[str, str]], col: str) -> bool:
    for row in rows:
        val = (row.get(col) or "").strip()
        if val != "":
            return True
    return False


def _required_diagnosis_rows_present(rows: List[Dict[str, str]]) -> Tuple[bool, List[str]]:
    need = {
        "S00-09",
        "S10-19",
        "S20-29",
        "S30-39",
        "S40-49",
        "S50-59",
        "S60-69",
        "S70-79",
        "S80-89",
        "S90-99",
        "T00-14",
        "Total",
        "Treatment periods",
    }
    got = {
        ((row.get("Diagnosis") or "").strip())
        for row in rows
        if (row.get("Diagnosis") or "").strip()
    }
    missing = sorted(need - got)
    return (len(missing) == 0, missing)


def _read_required_columns_and_basic_py_checks(
    path: str, required_cols: Sequence[str]
) -> Tuple[bool, str, Dict[str, int]]:
    """
    Returns (ok, error_msg, stats)
    stats: counts of empty per required col + py_leq0 count
    """
    empties: Dict[str, int] = {col: 0 for col in required_cols}
    py_leq0 = 0
    total = 0

    with open(path, newline="", encoding="utf-8") as f:
        rdr = csv.DictReader(f)
        if rdr.fieldnames is None:
            return False, "Missing header row.", {}
        missing = [col for col in required_cols if col not in rdr.fieldnames]
        if missing:
            return False, f"Missing required columns: {', '.join(missing)}", {}

        for row in rdr:
            total += 1
            for col in required_cols:
                val = (row.get(col) or "").strip()
                if val == "" or val.lower() == "na":
                    empties[col] += 1

            py_str = (row.get("py") or "").strip()
            try:
                py_val = float(py_str)
                if py_val <= 0:
                    py_leq0 += 1
            except Exception:
                py_leq0 += 1

    if total == 0:
        return False, "No rows found.", {}

    empties_nonzero = {k: v for k, v in empties.items() if v > 0}
    if empties_nonzero:
        return (
            False,
            f"Required columns have empty/NA values: {empties_nonzero}",
            {"rows": total, "py_leq0": py_leq0},
        )

    if py_leq0 > 0:
        return (
            False,
            f"Found py<=0 or invalid py rows: {py_leq0}",
            {"rows": total, "py_leq0": py_leq0},
        )

    return True, "", {"rows": total, "py_leq0": py_leq0}


def _scan_log_for_keywords(path: str) -> Tuple[List[str], List[str]]:
    """
    Returns (errors, warnings) lines (truncated) matching patterns.
    - errors: lines containing ERROR/FAIL (case-insensitive)
    - warnings: lines containing modeling/runtime suspicious keywords
    """
    if not os.path.exists(path):
        return [], [f"Log missing: {os.path.basename(path)}"]

    err_pat = re.compile(r"\b(error|fail(ed)?)\b", re.IGNORECASE)
    warn_pat = re.compile(
        r"(singular|converg|non[- ]?finite|iteration|glm|negbin)", re.IGNORECASE
    )

    errors: List[str] = []
    warns: List[str] = []

    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            line_strip = line.strip()
            if not line_strip:
                continue
            if err_pat.search(line_strip):
                errors.append(line_strip[:240])
            elif warn_pat.search(line_strip):
                warns.append(line_strip[:240])

    return errors[:20], warns[:20]


def qc_table3() -> QCResult:
    msgs: List[str] = []
    warns: List[str] = []

    csv_path = os.path.join("outputs", "tables", "table3.csv")
    md_path = os.path.join("outputs", "tables", "table3.md")
    if not _file_nonempty(csv_path):
        return _fail("Missing or empty outputs/tables/table3.csv")
    if not _file_nonempty(md_path):
        return _fail("Missing or empty outputs/tables/table3.md")
    msgs.append("OK: outputs/tables/table3.csv and table3.md exist and are non-empty")

    try:
        rows = _read_csv_rows(csv_path)
    except Exception as e:
        return _error(f"Could not read table3.csv: {type(e).__name__}: {e}")

    req_cols = ["WO_ctrl_mean_se", "WO_case_mean_se", "FO_ctrl_mean_se", "FO_case_mean_se"]
    missing_cols = [col for col in req_cols if col not in rows[0]]
    if missing_cols:
        return _fail(f"Missing expected columns in table3.csv: {', '.join(missing_cols)}")

    filled = {col: _any_filled(rows, col) for col in req_cols}
    msgs.append(f"OK: group columns filled flags: {filled}")
    if not all(filled.values()):
        return _fail("Expected non-empty values for both control+case in both panels (WO/FO)")

    ok_diag, missing_diag = _required_diagnosis_rows_present(rows)
    if not ok_diag:
        return _fail(f"Missing expected Diagnosis rows: {', '.join(missing_diag)}")
    msgs.append("OK: all expected Diagnosis rows present (buckets + Total + Treatment periods)")

    if get_data_root is None:
        return _error(f"Could not import scripts.path_resolver.get_data_root: {_import_err}")

    data_root = get_data_root()
    if not data_root:
        return _fail("DATA_ROOT not resolved (get_data_root() returned empty/None)")

    vis_in = os.path.join(data_root, "derived", "table3_visits_input.csv")
    trt_in = os.path.join(data_root, "derived", "table3_treat_input.csv")

    for relname, path, req in [
        (
            "visits",
            vis_in,
            ["fof_status", "case_status", "sex", "age", "py", "icd10_code", "event_count"],
        ),
        (
            "treat",
            trt_in,
            ["fof_status", "case_status", "sex", "age", "py", "event_count"],
        ),
    ]:
        if not os.path.exists(path):
            return _fail(f"Missing derived input for {relname}: derived/table3_{relname}_input.csv")
        ok, err, stats = _read_required_columns_and_basic_py_checks(path, req)
        if not ok:
            return _fail(f"{relname} input QC failed: {err}")
        msgs.append(
            f"OK: derived/table3_{relname}_input.csv required cols present; no NA; py>0 (rows={stats.get('rows')})"
        )

    irr_cols = ["WO_irr_ci", "FO_irr_ci"]
    for col in irr_cols:
        if col not in rows[0]:
            return _fail(f"Missing IRR column in table3.csv: {col}")
        n_filled = sum(1 for row in rows if (row.get(col) or "").strip() != "")
        msgs.append(f"OK: {col} filled rows = {n_filled}")
        if n_filled == 0:
            return _fail(f"{col} appears empty for all rows (model may have failed)")

    inputs_log = os.path.join("outputs", "logs", "table3_inputs.log")
    table3_log = os.path.join("outputs", "logs", "table3.log")

    for log_path, tag in [(inputs_log, "table3_inputs.log"), (table3_log, "table3.log")]:
        errs, ws = _scan_log_for_keywords(log_path)
        if errs:
            return _fail(f"Found error markers in {tag}: {errs[0]}")
        if ws:
            warns.append(
                f"WARN: suspicious keywords in {tag} (showing up to 3): " + " | ".join(ws[:3])
            )

    msgs.append("OK: logs contain no ERROR/FAIL markers (keyword scan)")

    try:
        with open(md_path, encoding="utf-8") as f:
            md_lines = f.read().splitlines()
    except Exception as e:
        return _error(f"Could not read table3.md: {type(e).__name__}: {e}")

    md_rows = [line for line in md_lines if line.startswith("| ") and line.count("|") >= 8]
    csv_data_rows = len(rows)

    if len(md_rows) == 0 or csv_data_rows == 0:
        return _fail("Missing table rows in md or csv")
    if len(md_rows) < csv_data_rows:
        return _fail(
            f"MD appears to have fewer table rows than CSV (md_rows={len(md_rows)}, csv_rows={csv_data_rows})"
        )

    msgs.append(f"OK: md/csv row counts look consistent (md_rows={len(md_rows)}, csv_rows={csv_data_rows})")

    return _pass(msgs, warns)


def main(argv: Sequence[str]) -> int:
    _ = argv
    res = qc_table3()
    if res.warnings:
        for warning in res.warnings:
            print(warning)
    for message in res.messages:
        print(message)

    if res.ok:
        print("PASS: Table 3 QC")
        return 0

    print("FAIL: Table 3 QC")
    return res.code


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
