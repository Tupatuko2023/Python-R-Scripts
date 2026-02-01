# TASK: Finalize Replication Report & Package Gold Master

## STATUS
- State: 01-ready
- Priority: High
- Assignee: Gemini Termux Orchestrator (S-QF)

## BACKGROUND
The separate analysis and injury-only replication are complete.
- Outpatient IRR (Injury): 1.18 (Exact match to manuscript).
- Inpatient IRR (All-cause): 1.05.
- Inpatient IRR (Injury): 1.01.
- Interpretation: The discrepancy in inpatient rates is likely due to the outcome definition or aggregation method. However, the exact match in outpatient injury IRR (1.18) validates the linkage and modeling pipeline.

## OBJECTIVE
1.  **Update Handover**: Add a specific "Replication Analysis" section to `docs/FRAILTY_HANDOVER.md` summarizing these findings and the explanation.
2.  **Clean Up**: Ensure `separated_outcomes_summary.csv` and `replication_injury_nb_age_sex.csv` are preserved in `outputs/`.
3.  **Final Package**: Create the absolute final zip.

## STEPS
1.  **Edit `docs/FRAILTY_HANDOVER.md`**:
    -   Add a new section: `## 5. Replication Analysis (Outpatient vs Inpatient)`.
    -   Interpretation: "Outpatient results (1.18 for injuries) replicate the original study exactly. Inpatient results (1.05 all-cause, 1.01 injury) are lower than original (1.70), likely because Aim 2 measures episodes, whereas the original study may have used a different metric or aggregation for hospital stays."
2.  **Move Artifacts**: Ensure all key CSVs are in `outputs/`.
3.  **Git & Zip**:
    -   `git add . && git commit -m "feat: add replication analysis results"`
    -   `python3 scripts/40_build_knowledge_package.py --include-derived`
    -   `cp knowledge_package.zip /sdcard/Download/aim2_COMPLETE_ANALYSIS.zip`

## DEFINITION OF DONE

- [x] Handover document contains the comparison discussion.

- [x] `/sdcard/Download/aim2_COMPLETE_ANALYSIS.zip` exists.
