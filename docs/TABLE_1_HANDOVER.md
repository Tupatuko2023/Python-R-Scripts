# HANDOVER: Fix Data Source and Frailty Variable for Table 1

**Target Agent**: Codex Agent (3caqf)  
**Context**: Finalizing Aim 2 Statistical Rigor (N=486)

## 1. Problem
The script `Quantify-FOF-Utilization-Costs/R/10_table1/12_table1_patient_characteristics_by_fof_wfrailty.R` is currently reporting a cohort size of **N=126** (or N=276) because it prioritizes the old subset `kaatumisenpelko.csv`. 

The correct, expanded cohort (**N=486**) lives in `aim2_panel.csv`.

## 2. Required Changes (CRITICAL)

### Fix 1: Update Input Discovery Priority
Modify the `locate_input` function (around line 105) to prioritize the panel data.
- **Change**: Move `aim2_panel.csv` to the **first** position in the `candidates` vector.
- **Goal**: Ensure the script loads the "Rescued" dataset (N=486).

### Fix 2: Use Correct Frailty and Smoking Variables
The script currently tries to map variables from raw components or old column names.
- **Frailty**: Update `col_frailty` mapping (around line 208) to explicitly use `frailty_cat_3`.
- **Smoking**: Since `smoking` is missing from `aim2_panel.csv`, you must join it from `KAAOS_data_sotullinen.xlsx`.
    - **Raw File**: `DATA_ROOT/paper_02/KAAOS_data_sotullinen.xlsx`
    - **Header Row**: 2 (labels are in row 2).
    - **Smoking Column**: `tupakointi` (Column index 19).
    - **Linkage**: Use `Sotu` (Column 3) to match `id` in the panel.

### Fix 3: Add Data Integrity Assertion
Add a row count check immediately after reading `df_raw` (around line 125):
```r
if (nrow(df_raw) < 480) {
  stop(paste0("CRITICAL ERROR: Incorrect cohort size. Found N=", nrow(df_raw), ", expected N=486. Check input priority."))
}
```

## 3. Reference N-Numbers (Source: FRAILTY_HANDOVER.md)
The final distribution in `aim2_panel.csv` should be:
- **Robust**: 104
- **Pre-frail**: 179
- **Frail**: 140
- **Unknown**: 63 (Note: Table 1 usually excludes 'Unknown' from the FOF comparison, so N ~ 423 is expected in the final table columns).

## 4. Execution
After making these changes, run the script with:
```bash
export DATA_ROOT="/path/to/data"
export ALLOW_AGGREGATES=1
Rscript Quantify-FOF-Utilization-Costs/R/10_table1/12_table1_patient_characteristics_by_fof_wfrailty.R
```

---
*Prepared by Gemini Termux Orchestrator (S-QF) - 2026-02-05*
