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
- **Frailty Mapping**: Since `frailty_fried` in `aim2_panel.csv` may contain numeric scores (0-3) or even error values (5), you **MUST** use this exact mapping logic:
    ```r
    df_panel <- df_panel %>%
      mutate(frailty_fried = suppressWarnings(as.numeric(as.character(frailty_fried)))) %>%
      mutate(frailty_cat_3 = case_when(
        frailty_fried == 0 ~ "Robust",
        frailty_fried >= 1 & frailty_fried <= 2 ~ "Pre-frail",
        frailty_fried == 3 ~ "Frail",
        frailty_fried > 3 ~ "Unknown", # Handles 5
        is.na(frailty_fried) ~ "Unknown",
        TRUE ~ "Unknown"
      ))
    ```
- **Smoking Join (KAAOS Excel)**: Since `smoking` is missing from `aim2_panel.csv`, join it from `KAAOS_data_sotullinen.xlsx`.
    - **Raw File**: `DATA_ROOT/paper_02/KAAOS_data_sotullinen.xlsx`
    - **Header Row**: 2 (labels are in row 2).
    - **Join Key**: You **MUST** join Panel `id` to Excel **Sotu** (Column 3). 
    - **ID Origin**: Forensics confirmed that `id` in `aim2_panel.csv` contains the **Sotu string** (e.g., "160135-534C"), NOT a numeric research ID.
    - **Normalization**: Note that the script's `normalize_id()` removes hyphens (e.g., "160135-534C" -> "160135534"). Ensure this is applied consistently to both sides of the join.
    - **Smoking Column**: `tupakointi` (Column index 19).

### Fix 3: Add Data Integrity Gates
Add these checks to ensure the data is correct:
1. **Row Count Check**:
```r
if (nrow(df_raw) < 480) {
  stop(paste0("CRITICAL ERROR: Incorrect cohort size. Found N=", nrow(df_raw), ", expected N=486."))
}
```
2. **Join Match Rate Check**:
```r
match_rate <- mean(!is.na(df_raw$frailty_cat_3) & df_raw$frailty_cat_3 != "Unknown")
if (match_rate < 0.70) {
  stop(paste0("CRITICAL: frailty join match_rate too low: ", round(match_rate, 3), ". Ensure you are joining Panel ID to Excel SOTU (not NRO)."))
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
