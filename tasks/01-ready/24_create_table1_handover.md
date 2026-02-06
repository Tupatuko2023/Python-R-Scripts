# TASK: Create Handover Instructions for Codex (Fix Table 1 Logic)

## STATUS
- State: 01-ready
- Priority: Critical
- Assignee: Gemini Termux Orchestrator (S-QF)

## PROBLEM
The Codex agent (3caqf) implemented `12_table1_patient_characteristics_by_fof_wfrailty.R` incorrectly.
It reports N=126 (or 276) instead of the correct **N=486**.
Root Cause: The script currently prioritizes `kaatumisenpelko.csv` (Input Priority #1), which is the old subset. The "Rescued" data lives in `aim2_panel.csv` (Input Priority #2).

## OBJECTIVE
Create a strictly formatted instruction file `docs/TABLE_1_HANDOVER.md` for the Codex agent.
This file must explain *exactly* how to modify the R script to load the correct data and variable.

## STEPS
1.  **Analyze Script**: Confirm that lines ~20-25 define the input discovery order.
2.  **Write `docs/TABLE_1_HANDOVER.md`**:
    -   **Target**: Codex Agent (3caqf).
    -   **Critical Fix 1 (Source)**: Change input logic to force `aim2_panel.csv` as the **PRIMARY** source. The script must NOT read `kaatumisenpelko.csv` if the panel exists.
    -   **Critical Fix 2 (Variable)**: Ensure the script uses `frailty_cat_3` (the 3-class variable robust/pre-frail/frail) found in the panel, NOT the raw components.
    -   **Validation**: Tell Codex to add an assertion: `stopifnot(nrow(df) >= 480)` to ensure it has the full cohort.
3.  **Context**: Include a summary of the N numbers from `FRAILTY_HANDOVER.md`.

## DEFINITION OF DONE
- [ ] `docs/TABLE_1_HANDOVER.md` exists.
- [ ] It explicitly instructs to swap the input priority order.
- [ ] It provides the exact column name `frailty_cat_3`.
