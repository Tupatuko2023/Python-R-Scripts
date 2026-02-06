# TASK: Finalize Table 1 Script (Numeric Mapping Fix)

## STATUS
- State: 01-ready
- Priority: Critical
- Assignee: Gemini Termux Orchestrator (S-QF)

## BACKGROUND
The `aim2_panel.csv` contains `frailty_fried` as **NUMERIC** values (observed: 1, 2, 5), contrary to previous reports of text labels.
We must instruct the Codex agent to handle this specific numeric mapping within the R script to generate Table 1 successfully.

## OBJECTIVE
Update `docs/TABLE_1_HANDOVER.md` with the **FINAL** mapping logic and instruct Codex to execute.

## MAPPING LOGIC (CRITICAL)
Since our proxy uses 3 components (Max score 3), any value > 3 (like 5) must be treated as "Unknown".
- **0** -> "Robust"
- **1, 2** -> "Pre-frail"
- **3** -> "Frail"
- **>3 (e.g. 5)** -> "Unknown"
- **NA** -> "Unknown"

## INSTRUCTIONS FOR CODEX (3caqf)
1.  **Read** `aim2_panel.csv`.
2.  **Join Smoking**: Left join `tupakointi` from `KAAOS_data_sotullinen.xlsx` (as previously instructed).
3.  **Mutate Frailty**:
    ```r
    df <- df %>%
      mutate(frailty_cat_3 = case_when(
        frailty_fried == 0 ~ "Robust",
        frailty_fried >= 1 & frailty_fried <= 2 ~ "Pre-frail",
        frailty_fried == 3 ~ "Frail",
        frailty_fried > 3 ~ "Unknown", # Handle the '5' values
        TRUE ~ "Unknown"
      ))
    ```
4.  **Execute**: Run `12_table1_patient_characteristics_by_fof_wfrailty.R` with `ALLOW_AGGREGATES=1`.

## DEFINITION OF DONE
- [ ] `docs/TABLE_1_HANDOVER.md` is updated with this specific numeric logic.
- [ ] Codex is triggered to run the script.
