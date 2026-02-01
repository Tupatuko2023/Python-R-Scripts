# TASK: Discovery of Distinct Outcome Columns (Inpatient vs Outpatient)

## STATUS
- State: 01-ready
- Priority: High
- Assignee: Gemini Termux Orchestrator (S-QF)

## BACKGROUND
The expert pointed out that our current outcome `util_visits_total` lumps together two clinically distinct processes that behave differently:
1.  **"Health care services"** (Polyclinical/Outpatient visits).
2.  **"Hospital treatment periods"** (Inpatient episodes/ward periods).

To replicate the original manuscript's rigor (IRR 1.18 vs 1.70), we must analyze these separately. We need to identify their specific column names in `aim2_panel.csv`.

## OBJECTIVE
Identify and report the exact column names in the panel that correspond to:
1.  Outpatient/Polyclinical visits (e.g., `util_outpatient`, `avohilmo_visits`).
2.  Inpatient/Hospital treatment periods (e.g., `util_inpatient_periods`, `hilmo_periods`).

## STEPS
1.  **Inspect Dictionary**: Check `data/data_dictionary.csv` for definitions.
2.  **Inspect Builder Logic**: Read `scripts/build_real_panel.py` to see how `util_visits_total` was constructed. Is it a sum of specific columns?
3.  **Inspect Data Structure**: Create a temp script `R/99_colname_check.R` that loads the panel and prints `colnames()` matching patterns like "visit", "period", "hosp", "ward", "out", "in".
4.  **Report**: Create a short file `docs/OUTCOME_MAPPING.md` listing the variable names found.

## DEFINITION OF DONE
- [x] `docs/OUTCOME_MAPPING.md` exists.
- [x] It explicitly lists the column name for "Hospital Periods".
- [x] It explicitly lists the column name for "Polyclinical Visits".
- [x] If distinct columns are NOT found (e.g., if we only built the total), report this gap clearly.
