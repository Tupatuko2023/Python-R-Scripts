# TASK: Debug 'frailty_fried' Column Data Type and Values

## STATUS
- State: 01-ready
- Priority: Critical
- Assignee: Gemini Termux Orchestrator (S-QF)

## BACKGROUND
The Codex agent attempted to derive `frailty_cat_3` from `frailty_fried`, but the results were nonsensical (0 Robust, 335 Unknown).
This implies the mapping logic `case_when(frailty_fried == 0 ~ ...)` failed.
We suspect a data type mismatch (Character vs Numeric) or unexpected values.

## OBJECTIVE
Inspect the `aim2_panel.csv` file directly to reveal the exact nature of the `frailty_fried` column.

## STEPS
1.  **Script**: Create `R/99_inspect_frailty_values.R`.
    -   Load `derived/aim2_panel.csv`.
    -   Print `class(df$frailty_fried)`.
    -   Print `head(df$frailty_fried, 20)`.
    -   Print `table(df$frailty_fried, useNA = "always")`.
    -   Check if any other frailty-related columns exist (`grep("frail", names(df), value=TRUE)`).
2.  **Execute**: `termux-wake-lock && Rscript R/99_inspect_frailty_values.R`.
3.  **Report**: Save the output to `docs/FRAILTY_DEBUG_LOG.md`.

## DEFINITION OF DONE
- [ ] We know exactly why `frailty_fried == 0` failed (e.g., is it "0", 0, or NA?).
