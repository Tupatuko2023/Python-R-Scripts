# TASK: Frailty Diagnostic & Refinement (Merge Robust/Pre-frail)

## STATUS
- State: 02-done
- Priority: High
- Assignee: Gemini Termux Orchestrator (S-QF)

## BACKGROUND
Expert feedback indicates the "Unknown" frailty rate (360/486) is suspicious and likely a join failure or population mismatch.
Also, the "Robust" group (N=6-14) is too small for interaction models.
We need to:
1. Diagnose the merge quality (IDs matching).
2. Switch to a 2-class Frailty variable (Non-Frail vs. Frail) to solve the small sample size issue.

## OBJECTIVE
1. **Run Diagnostics**: Execute the expert-provided R snippet to check ID matching and NA rates.
2. **Refine Data Build**:
   - Update `scripts/build_real_panel.py` (or R builder) to collapse Frailty into 2 classes:
     - `Non-Frail` (Robust + Pre-frail)
     - `Frail` (Frail)
   - Ensure IDs are treated consistently (e.g., stripping leading zeros) during merge.
3. **Re-Run Models**: Update models to use the new 2-class variable for interaction (`FOF * frailty_binary`).
4. **Visuals**: Update dashboard and add "Absolute Scale" plots if possible.

## STEPS
1. **Diagnostic Script**:
   - Create `R/99_frailty_check.R` with the code provided by the expert (see below).
   - Run it: `termux-wake-lock && Rscript R/99_frailty_check.R`.
   - *Decision Point*: If match rate is low (<50%), fix ID formats in `build_real_panel.py` and re-run build.
2. **Refine Variable**:
   - Modify build script to create `frailty_binary` column (0=Non-Frail, 1=Frail).
3. **Update Models**:
   - Change `scripts/30_models_panel_nb_gamma.R` to use `frailty_binary`.
4. **Execution**:
   - Run Build -> Models -> Dashboard.

## DEFINITION OF DONE
- [x] Diagnostics run and log analyzed.
- [x] aim2_panel.csv has frailty_binary.
- [x] Models run with 2-class interaction (stable CIs).
- [x] Dashboard updated.
