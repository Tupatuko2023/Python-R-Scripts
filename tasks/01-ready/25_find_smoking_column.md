# TASK: Locate "Smoking" Column for Table 1

## STATUS
- State: 01-ready
- Priority: Critical
- Assignee: Gemini Termux Orchestrator (S-QF)

## BACKGROUND
The Codex agent (3caqf) correctly halted because `aim2_panel.csv` is missing the "smoking" variable.
We know this variable exists in the raw baseline data (`KAAOS_data_sotullinen.xlsx`), but it wasn't carried over during the cohort expansion.

## OBJECTIVE
1.  **Search**: Scan the headers of `KAAOS_data_sotullinen.xlsx`.
2.  **Identify**: Find the column corresponding to smoking status (look for "Tupak", "Smoke", "Suitset").
3.  **Report**: Create `docs/SMOKING_MAPPING.md` with the exact File Name and Column Name.

## STEPS
1.  **Script**: Create a temporary R script `R/99_find_smoking.R`.
    -   Load `readxl`.
    -   Read headers of `KAAOS_data_sotullinen.xlsx`.
    -   Grep for "tupak", "smok", "tobacco".
    -   Print matches.
2.  **Execute**: `termux-wake-lock && Rscript R/99_find_smoking.R`.
3.  **Output**: Save the exact column name to `docs/SMOKING_MAPPING.md`.

## DEFINITION OF DONE
- [ ] `docs/SMOKING_MAPPING.md` contains the exact raw column name for smoking.
