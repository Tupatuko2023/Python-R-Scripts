# Task: Carry BMI Into Derived CSV Inputs

Status: DONE — derived/kaatumisenpelko.csv created with baseline fields incl. bmi and FTSST (TK); Table 1 mapping unblocked.

## Summary
Add BMI to the derived CSV inputs used by Table 1 by carrying it from raw KAAOS data.

## Scope (DO)
- Update the derivation pipeline that produces:
  - DATA_ROOT/derived/aim2_panel.csv and/or DATA_ROOT/derived/kaatumisenpelko.csv
- Source raw BMI from:
  - DATA_ROOT/paper_02/KAAOS_data.xlsx
  - Column: Painoindeksi (BMI)
- Standardize the derived column name to `bmi` (numeric; kg/m²).

## Out of scope (DO NOT)
- Do NOT modify Table 1 script input discovery (keep CSV-only).
- Do NOT add raw data to the repo.
- Do NOT print row-level data or absolute paths.

## Security / Privacy
- No row-level output (no head(), print(), glimpse(), etc.).
- Redact absolute paths in logs/console.

## Gates / Steps
1) Use `Quantify-FOF-Utilization-Costs/scripts/build_real_panel.py` (panel derivation).
2) Add BMI extraction/mapping from KAAOS_data.xlsx into derived outputs.
3) Run the derivation with DATA_ROOT sourced from config/.env (wakelock).
4) Verify derived CSV header includes `bmi` (schema-only header check).
5) Re-run Table 1 fail-closed pass to confirm BMI mapping proceeds.

## Commands (Termux; use wakelock)
[TERMUX]
cd ~/Python-R-Scripts

set -a
. Quantify-FOF-Utilization-Costs/config/.env
set +a

termux-wake-lock && Rscript <derivation_script>.R && termux-wake-unlock
termux-wake-lock && python3 Quantify-FOF-Utilization-Costs/scripts/build_real_panel.py && termux-wake-unlock

# header-only check (no row data)
termux-wake-lock && Rscript -e 'suppressPackageStartupMessages({library(readr)}); p<-file.path(Sys.getenv("DATA_ROOT"),"derived","aim2_panel.csv"); h<-read_csv(p,n_max=0,show_col_types=FALSE,progress=FALSE); message("has_bmi: ", "bmi" %in% names(h))' && termux-wake-unlock

## Definition of Done
- Derived CSV(s) include `bmi` column in header.
- Table 1 fail-closed run passes BMI mapping and fails only on ALLOW_AGGREGATES gate (expected).
