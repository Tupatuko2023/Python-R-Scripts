# TASK: Final Statistical Run (Publication Quality)

## STATUS
- State: 04-done
- Priority: High
- Assignee: Gemini Termux Orchestrator (S-QF)

## BACKGROUND
The expert review confirmed the approach but demanded higher statistical rigor:
1.  **Bootstrap**: Increase $B$ from 50 to 500 for stable CIs.
2.  **Bias Check**: Execute the check for the "Unknown" group.
3.  **Stratified Results**: Report FOF effects *within* each frailty class (Robust, Pre-frail, Frail).

## OBJECTIVE
Execute the final, computation-heavy analysis pipeline.

## STEPS
1.  **Bias Analysis**: Run `R/25_check_unknown_bias.R` and save output to `outputs/qc/unknown_bias.csv`.
2.  **Update Models (`R/30_models...R`)**:
    - Set `B <- 500`.
    - Add code to calculate/extract **Stratified Ratios** (e.g., Effect of FOF | Robust, Effect of FOF | Pre-frail).
3.  **Execution**:
    - Run `termux-wake-lock && Rscript R/25_check_unknown_bias.R && Rscript R/30_models_panel_nb_gamma.R && termux-wake-unlock`.
    - *Note*: This will take time due to B=500.
4.  **Reporting**:
    - Update `FRAILTY_HANDOVER.md` with the stabilized CIs and the Stratified results.

## DEFINITION OF DONE
- [x] Models run with B=500.
- [x] `FRAILTY_HANDOVER.md` shows FOF effects specifically for Robust, Pre-frail, and Frail groups.
- [x] Bias check for "Unknown" group is documented.
