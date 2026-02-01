# TASK: Verify Aim 2 Pipeline (Synthetic Smoke Test)

## STATUS
- State: 03-done
- Priority: High (Blocker for production run)
- Assignee: Gemini Termux Orchestrator (S-QF)

## BACKGROUND
Previous agents setup the environment (R, tidyverse, ragg) and fixed memory limits.
We now need to prove the pipeline works end-to-end using **synthetic data** to avoid touching protected inputs yet.

## OBJECTIVE
Execute the Aim 2 analysis pipeline using internal synthetic data to generate valid outputs.

## CONSTRAINTS & RULES (Non-negotiable)
1. **Termux-Native**: Use `termux-wake-lock` for all R executions.
2. **Option B**: Do NOT read from external `DATA_ROOT` for this test. Use local synthetic generation if available, or the repo's sample data.
3. **No GUI**: Do not try to open plots. Verify their existence in `outputs/`.

## STEPS
1. **Discovery**: Check if `scripts/10_build_panel_person_period.R` exists.
2. **Inventory**: Run `python3 scripts/00_inventory_manifest.py --scan paper_02` (checks metadata).
3. **Smoke Run (The Core Task)**:
   - Command: `python3 scripts/30_qc_summary.py --use-sample`
   - OR if that script invokes R: Run the R panel builder using the synthetic flag if available.
   - Goal: Produce `outputs/qc_summary_aim2.txt` without errors.
4. **Verification**: List files in `outputs/` to confirm artifact generation.

## DEFINITION OF DONE
- [x] `outputs/qc_summary_aim2.txt` exists and is not empty.
- [x] No "Out of Memory" errors in logs.
- [x] Execution was wrapped in `termux-wake-lock`.
