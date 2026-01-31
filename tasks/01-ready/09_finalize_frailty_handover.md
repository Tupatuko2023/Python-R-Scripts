# TASK: Finalize Frailty Integration & Create Expert Handover

## STATUS
- State: 01-ready
- Priority: High
- Assignee: Gemini Termux Orchestrator (S-QF)

## BACKGROUND
Frailty data has been linked. We have updated scripts and produced artifacts.
However, `scripts/45_visualize_aim2_outputs.R` is in the wrong directory (should be `R/`).
Crucially, the "Robust" group has only N=6, which risks statistical instability. We need to assess this before showing results to the expert.

## OBJECTIVE
1. **Refactor**: Move `scripts/45_visualize_aim2_outputs.R` to `R/45_visualize_aim2_outputs.R`.
2. **Analyze Results**: Check `outputs/panel_models_summary.csv` for the interaction terms. Are the Confidence Intervals (CI) extremely wide?
3. **Report**: Create `docs/FRAILTY_HANDOVER.md`.

## CONTENT REQUIREMENTS (`docs/FRAILTY_HANDOVER.md`)
1.  **Data Source**: Explicitly state we linked `K15_MAIN` from `Fear-of-Falling` project.
2.  **Sample Size Alert**: Highlight the distribution: Unknown (360), Pre-frail (71), Frail (49), Robust (6).
3.  **Model Diagnostics**:
    * Did the model converge?
    * Are the estimates for "Robust" stable, or should we recommend merging "Robust + Pre-frail" in the next iteration?
4.  **Visuals**: Reference `trend_visits_by_frailty.png`.
5.  **Questions for Expert**:
    * "Given N=6 for Robust, should we merge Robust and Pre-frail as the reference group?"
    * "Is the 'Unknown' group systematically different?"

## STEPS
1.  **Move Script**: `mv scripts/45_... R/45_...`
2.  **Read Outputs**: `cat outputs/panel_models_summary.csv` (look for rows with `frailty` in the term).
3.  **Write Doc**: Generate the markdown file.
4.  **Commit**: Git add/commit.

## DEFINITION OF DONE
- [ ] Script moved to `R/`.
- [ ] `docs/FRAILTY_HANDOVER.md` exists with specific sample size warnings and expert questions.
