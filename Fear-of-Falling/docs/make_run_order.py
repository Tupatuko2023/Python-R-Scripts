#!/usr/bin/env python3
"""Generate run_order.csv programmatically to avoid line break issues in CSV fields."""

import os
import re
import csv
from pathlib import Path

# Core scripts with verified paths
SCRIPTS = [
    ("K1", "R-scripts/K1/K1.7.main.R"),
    ("K2", "R-scripts/K2/K2.Z_Score_C_Pivot_2G.R"),
    ("K3", "R-scripts/K3/K3.7.main.R"),
    ("K4", "R-scripts/K4/K4.A_Score_C_Pivot_2G.R"),
    ("K18_QC", "R-scripts/K18/K18_QC.V1_qc-run.R"),
    ("K15", "R-scripts/K15/K15.R"),
    ("K16", "R-scripts/K16/K16.R"),
    ("K01_MAIN", "R-scripts/K01_MAIN/K01_MAIN.V1_zscore-change.R"),
    ("K02_MAIN", "R-scripts/K02_MAIN/K02_MAIN.V1_zscore-pivot-2g.R"),
    ("K03_MAIN", "R-scripts/K03_MAIN/K03_MAIN.V1_original-values.R"),
    ("K04_MAIN", "R-scripts/K04_MAIN/K04_MAIN.V1_values-pivot-2g.R"),
    ("K05_MAIN", "R-scripts/K05_MAIN/K05_MAIN.V1_wide-ancova.R"),
    ("K06_MAIN", "R-scripts/K06_MAIN/K06_MAIN.V1_moderators-delta-ancova.R"),
    ("K07_MAIN", "R-scripts/K07_MAIN/K07_MAIN.V1_multidomain-moderators-delta-ancova.R"),
    ("K08_MAIN", "R-scripts/K08_MAIN/K08_MAIN.V1_balance-walk-moderators-delta-ancova.R"),
    ("K09_MAIN", "R-scripts/K09_MAIN/K09_MAIN.V1_women-fof-age-ancova.R"),
    ("K10_MAIN", "R-scripts/K10_MAIN/K10_MAIN.V1_fof-delta-visuals.R"),
    ("K11_MAIN", "R-scripts/K11_MAIN/K11_MAIN.V1_fof-independent-ancova.R"),
    ("K12_MAIN", "R-scripts/K12_MAIN/K12_MAIN.V1_pbt-outcomes-fof-effects.R"),
    ("K13_MAIN", "R-scripts/K13_MAIN/K13_MAIN.V1_fof-interactions.R"),
    ("K14_MAIN", "R-scripts/K14_MAIN/K14_MAIN.V1_baseline-table.R"),
    ("K15_MAIN", "R-scripts/K15_MAIN/K15_MAIN.V1_frailty-proxy.R"),
    ("K16_MAIN", "R-scripts/K16_MAIN/K16_MAIN.V1_frailty-adjusted-ancova-mixed.R"),
    ("K17_MAIN", "R-scripts/K17_MAIN/K17_MAIN.V1_baseline-table-frailty.R"),
    ("K18_MAIN", "R-scripts/K18_MAIN/K18_MAIN.V1_frailty-change-contrasts.R"),
    ("K19_MAIN", "R-scripts/K19_MAIN/K19_MAIN.V1_frailty-vs-fof-evidence-pack.R"),
]

FIELDS = ["script_id", "file_path", "verified", "file_tag", "depends_on",
          "reads_primary", "writes_primary", "run_command", "notes"]


def norm(x):
    """Normalize string: remove line breaks, collapse whitespace."""
    s = "" if x is None else str(x)
    s = re.sub(r"[\r\n]+", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s


def extract_file_tag(path):
    """Extract File tag from script header."""
    try:
        txt = Path(path).read_text(encoding="utf-8", errors="ignore")
        m = re.search(r"File tag:\s*(.+)", txt)
        return norm(m.group(1)) if m else "NA"
    except Exception:
        return "NA"


def main():
    rows = []

    for sid, fp in SCRIPTS:
        ok = os.path.isfile(fp)
        ft = extract_file_tag(fp) if ok else "NA"

        # Minimal depends/IO only for verified core chain
        depends = ""
        reads = ""
        writes = ""
        notes = "Verified: path exists" if ok else "NOT FOUND: path missing"

        # === Legacy scripts (K1-K18_QC) ===
        # Dependencies (verified only)
        if sid == "K2":
            depends = "K1"
        if sid == "K4":
            depends = "K3"
        if sid == "K16":
            depends = "K15"

        # Reads (verified only, minimal)
        if sid in ["K1", "K3"]:
            reads = "data/external/KaatumisenPelko.csv"
        if sid == "K18_QC":
            reads = "CLI --data argument (CSV path)"
        if sid == "K15":
            reads = "data/external/KaatumisenPelko.csv OR analysis_data"
        if sid == "K16":
            reads = "R-scripts/K15/outputs/K15_frailty_analysis_data.RData"

        # Writes (verified only, minimal)
        if sid == "K1":
            writes = "R-scripts/K1/outputs/K1_Z_Score_Change_2G.csv"
        if sid == "K2":
            writes = "R-scripts/K2/outputs/K2_Z_Score_Change_2G_Transposed.csv"
        if sid == "K3":
            writes = "R-scripts/K3/outputs/K3_Values_2G.csv"
        if sid == "K4":
            writes = "R-scripts/K4/outputs/K4_Values_2G_Transposed.csv"
        if sid == "K18_QC":
            writes = "R-scripts/K18/outputs/K18_QC/qc/ (artifacts)"
        if sid == "K15":
            writes = "R-scripts/K15/outputs/K15_frailty_analysis_data.RData"
        if sid == "K16":
            writes = "R-scripts/K16/outputs/ (model CSV outputs)"

        # === _MAIN scripts I/O mappings (grep-verified 2026-01-13) ===
        # K01_MAIN through K19_MAIN
        if sid == "K01_MAIN":
            reads = "data/external/KaatumisenPelko.csv"
            writes = "R-scripts/K01_MAIN/outputs/K1_Z_Score_Change_2G.csv"
            notes = "Grep-verified: reads raw CSV via here::here; writes z-score change"
        elif sid == "K02_MAIN":
            depends = "K01_MAIN"
            reads = "R-scripts/K01_MAIN/outputs/K1_Z_Score_Change_2G.csv"
            writes = "R-scripts/K02_MAIN/outputs/K2_Z_Score_Change_2G_Transposed.csv"
            notes = "Grep-verified: depends on K01_MAIN; transposes z-scores by FOF status"
        elif sid == "K03_MAIN":
            reads = "data/external/KaatumisenPelko.csv"
            writes = "R-scripts/K03_MAIN/outputs/K3_Values_2G.csv"
            notes = "Grep-verified: reads raw CSV; writes original test values"
        elif sid == "K04_MAIN":
            depends = "K03_MAIN"
            reads = "R-scripts/K03_MAIN/outputs/K3_Values_2G.csv"
            writes = "R-scripts/K04_MAIN/outputs/K4_Values_2G_Transposed.csv"
            notes = "Grep-verified: depends on K03_MAIN; transposes original values by FOF status"
        elif sid in ["K05_MAIN", "K06_MAIN", "K07_MAIN", "K08_MAIN", "K09_MAIN",
                     "K10_MAIN", "K11_MAIN", "K12_MAIN", "K13_MAIN", "K14_MAIN"]:
            reads = "data/external/KaatumisenPelko.csv"
            writes = f"R-scripts/{sid}/outputs/ (CSV/PNG artifacts)"
            notes = "Grep-verified: reads raw CSV; writes analysis outputs (ANCOVA/visuals)"
        elif sid == "K15_MAIN":
            reads = "data/external/KaatumisenPelko.csv"
            writes = "R-scripts/K15_MAIN/outputs/K15_frailty_analysis_data.RData"
            notes = "Grep-verified: creates frailty proxy vars; saves RData for K16/K18"
        elif sid == "K16_MAIN":
            depends = "K15_MAIN"
            reads = "R-scripts/K15_MAIN/outputs/K15_frailty_analysis_data.RData"
            writes = "R-scripts/K16_MAIN/outputs/ (CSV model outputs)"
            notes = "Grep-verified: depends on K15_MAIN; frailty-adjusted ANCOVA/mixed models"
        elif sid == "K17_MAIN":
            reads = "data/external/KaatumisenPelko.csv"
            writes = "R-scripts/K17_MAIN/outputs/ (baseline table with frailty)"
            notes = "Grep-verified: reads raw CSV; generates baseline table with frailty vars"
        elif sid == "K18_MAIN":
            depends = "K15_MAIN"
            reads = "R-scripts/K15_MAIN/outputs/K15_frailty_analysis_data.RData"
            writes = "R-scripts/K18_MAIN/outputs/K18_all_models.RData (+ CSV/PNG)"
            notes = "Grep-verified: depends on K15_MAIN; frailty change contrasts; saves model RData"
        elif sid == "K19_MAIN":
            depends = "K18_MAIN"
            reads = "R-scripts/K18_MAIN/outputs/K18_all_models.RData"
            writes = "R-scripts/K19_MAIN/outputs/ (CSV evidence pack)"
            notes = "Grep-verified: depends on K18_MAIN; frailty vs FOF comparison evidence"

        rows.append({
            "script_id": sid,
            "file_path": fp,
            "verified": "TRUE" if ok else "FALSE",
            "file_tag": ft,
            "depends_on": depends,
            "reads_primary": reads,
            "writes_primary": writes,
            "run_command": f"Rscript {fp}",
            "notes": notes
        })

    # Write CSV
    out = Path("docs/run_order.csv")
    out.parent.mkdir(parents=True, exist_ok=True)

    with out.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=FIELDS, quoting=csv.QUOTE_MINIMAL)
        w.writeheader()
        for r in rows:
            w.writerow({k: norm(r.get(k, "")) for k in FIELDS})

    print(f"OK: Wrote {out}")
    print(f"  Total rows: {len(rows)}")
    print(f"  Verified: {sum(1 for r in rows if r['verified'] == 'TRUE')}")
    print(f"  NOT FOUND: {sum(1 for r in rows if r['verified'] == 'FALSE')}")

    # Validate CSV
    try:
        import pandas as pd
        df = pd.read_csv(out)
        print(f"OK: Pandas validation passed: {df.shape}")
    except ImportError:
        # Fallback: basic CSV validation
        with out.open("r", encoding="utf-8") as f:
            import csv as _csv
            rr = _csv.reader(f)
            hdr = next(rr)
            for i, row in enumerate(rr, start=1):
                if len(row) != len(hdr):
                    raise SystemExit(f"CSV ERROR row {i}: {len(row)} cols, expected {len(hdr)}")
        print(f"OK: CSV reader validation passed")


if __name__ == "__main__":
    main()
