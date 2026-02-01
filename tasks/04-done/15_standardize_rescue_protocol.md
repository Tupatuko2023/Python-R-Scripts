# TASK: Standardize Data Linkage Protocol & Update Metadata

## STATUS
- State: 04-done
- Priority: Medium
- Assignee: Gemini Termux Orchestrator (S-QF)

## BACKGROUND
The "Rescue" operation (Task 13) successfully utilized raw data from `KAAOS_data_sotullinen.xlsx` to expand the cohort.
However, this logic is currently only inside `scripts/build_real_panel.py`. The official documentation in `data/` is outdated.
To ensure reproducibility by future agents (and humans), we must document the raw columns and the ID linking logic.

## OBJECTIVE
1. **Create Protocol**: Write `docs/DATA_LINKAGE_PROTOCOL.md`.
   - Explain the "Raw Data Mining" method.
   - List the specific raw columns used for Frailty (Strength, Speed, Activity).
   - Document the ID matching hierarchy (Sotu > NRO > Fallback).
2. **Update Dictionary**: Append the new frailty-related variables to `data/data_dictionary.csv`.
   - Variables: `frailty_score_raw`, `frailty_cat_3`, `handgrip_raw`, `walk_speed_raw`.
3. **Verify Unknown Bias**: Create a lightweight script `R/25_check_unknown_bias.R` to compare the "Analyzed" (N=423) vs "Unknown" (N=63) groups (Age, Sex, FOF).

## STEPS
1. **Analyze Build Script**: Read `scripts/build_real_panel.py` to extract the exact column names and logic used.
2. **Write Protocol**: Create the MD file describing *how* to reproduce the panel from raw data.
3. **Update CSV**: Add rows to `data/data_dictionary.csv` defining the new variables.
4. **Create Bias Check**: Write `R/25_check_unknown_bias.R` (don't run the full analysis yet, just create the tool).

## DEFINITION OF DONE
- [x] `docs/DATA_LINKAGE_PROTOCOL.md` exists and is detailed.
- [x] `data/data_dictionary.csv` includes the new frailty variables.
- [x] `R/25_check_unknown_bias.R` is created.
