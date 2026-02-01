# TASK: Finalize Replication Report & Package Gold Master

## STATUS
- State: 01-ready
- Priority: High
- Assignee: Gemini Termux Orchestrator (S-QF)

## BACKGROUND
The separate analysis is complete.
- Outpatient IRR: 1.14 (Replicates manuscript's 1.18 well).
- Inpatient IRR: 1.05 (Lower than manuscript's 1.70).
- Interpretation: The discrepancy in inpatient rates is likely due to the outcome definition. Manuscript used "Injury-related" (ICD S00-T98), while Aim 2 used "All-cause". This "All-cause dilution" explains the lack of signal.

## OBJECTIVE
1.  **Update Handover**: Add a specific "Replication Analysis" section to `docs/FRAILTY_HANDOVER.md` summarizing these findings and the explanation.
2.  **Clean Up**: Ensure `separated_outcomes_summary.csv` is preserved in `outputs/tables/`.
3.  **Final Package**: Create the absolute final zip.

## STEPS
1.  **Edit `docs/FRAILTY_HANDOVER.md`**:
    -   Add a new section: `## 5. Replication Analysis (Outpatient vs Inpatient)`.
    -   Insert table with the new IRRs.
    -   Add the "Interpretation": "Outpatient results (1.14) replicate the original study (1.18) closely. Inpatient results (1.05) are lower than original (1.70), likely because Aim 2 measures *all-cause* utilization, whereas the original study focused on *injury-related* episodes, creating a dilution effect."
2.  **Move Artifacts**: `mv separated_outcomes_summary.csv outputs/tables/` (if not already there).
3.  **Git & Zip**:
    -   `git add . && git commit -m "feat: add replication analysis results"`
    -   `python3 scripts/40_build_knowledge_package.py --include-derived`
    -   `cp knowledge_package.zip /sdcard/Download/aim2_COMPLETE_ANALYSIS.zip`

## DEFINITION OF DONE
- [ ] Handover document contains the comparison discussion.
- [ ] `/sdcard/Download/aim2_COMPLETE_ANALYSIS.zip` exists.
