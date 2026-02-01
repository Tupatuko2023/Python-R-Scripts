# TASK: Finalize Analysis with 3-Class Frailty (Victory Lap)

## STATUS
- State: 04-done
- Priority: High
- Assignee: Gemini Termux Orchestrator (S-QF)

## BACKGROUND
The cohort expansion was successful (N=486). The "Robust" group now has N=104.
We no longer need the "Binary Frailty" compromise. We can return to the scientifically preferred **3-Class Frailty Model** (Robust / Pre-frail / Frail).

## OBJECTIVE
1. **Revert/Update Models**: Modify `R/30_models_panel_nb_gamma.R` to use `frailty_cat_3` (or equivalent 3-level var) instead of `frailty_binary`.
   - *Important*: Ensure "Robust" is the Reference Level.
2. **Re-Run Visuals**: Update `R/45_visualize_aim2_outputs.R` to plot 3 trend lines (Robust/Pre/Frail) instead of 2.
3. **Execute Full Pipeline**: Run QC -> Models -> Visuals one last time.
4. **Finalize Handover**: Update `docs/FRAILTY_HANDOVER.md` with the final 3-class interaction results.

## STEPS
1. **Model Config**:
   - Edit `R/30_models_panel_nb_gamma.R`.
   - Formula: `~ ... + FOF_status * frailty_cat_3` (ensure 3 levels).
2. **Visual Config**:
   - Edit `R/45_visualize_aim2_outputs.R`.
   - Ensure color palettes handle 3 groups (e.g., Green/Orange/Red).
3. **Execution**:
   - `termux-wake-lock && Rscript R/30_models_panel_nb_gamma.R && Rscript R/45_visualize_aim2_outputs.R && termux-wake-unlock`
4. **Documentation**:
   - Record the final interaction coefficients/IRRs in the Handover doc.

## DEFINITION OF DONE
- [x] Models utilize the full N=486 cohort with 3-class frailty.
- [x] Forest plots and Trend lines show 3 distinct frailty levels.
- [x] Handover document contains the final results for the expert.
