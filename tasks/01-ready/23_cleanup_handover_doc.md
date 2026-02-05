# TASK: Cleanup and Finalize FRAILTY_HANDOVER.md (Remove Obsolete Data)

## STATUS
- State: 01-ready
- Priority: High
- Assignee: Gemini Termux Orchestrator (S-QF)

## PROBLEM
The file `docs/FRAILTY_HANDOVER.md` has become a "history log" rather than a clean report.
It currently shows **conflicting data** because old sections were not deleted:
1.  Top of file: Shows N=126 (Obsolete/Wrong).
2.  Middle of file: Shows N=276 (Obsolete).
3.  Bottom of file: Shows N=486 (Correct Final Result).

This is confusing for the expert. We need a single "Source of Truth".

## OBJECTIVE
Rewrite `docs/FRAILTY_HANDOVER.md` completely to remove conflicting history. It must ONLY present the final, correct state.

## CONTENT REQUIREMENTS (The "Gold Master" Version)
The new file must contain ONLY:
1.  **Overview**: Final cohort size is **N=486**.
2.  **Sample Size Table**:
    -   Robust: ~104
    -   Pre-frail: ~179
    -   Frail: ~140
    -   Unknown: ~63
    -   **Total: 486**
3.  **Methodology**: Mention "Raw Data Mining" and "Injury-Only Replication".
4.  **Results (The Correct B=500 Numbers)**:
    -   Outpatient IRR: 1.14 (All-cause) / 1.18 (Injury-Only Replication).
    -   Inpatient IRR: 1.05 (All-cause).
    -   Cost Ratio: 1.16 (CI 0.98-1.39).
5.  **Stratified Results**: The table showing FOF effect by Frailty class.
6.  **Bias Check**: The Age difference (~8 years) for Unknowns.

## STEPS
1.  **Read**: Read the *current* file to grab the correct text for the sections listed above (especially the Replication and Stratified tables from the bottom).
2.  **Rewrite**: Overwrite `docs/FRAILTY_HANDOVER.md` with a clean structure. **Delete** the old "N=126" and "N=276" sections entirely.
3.  **Verify**: Ensure the first table the reader sees shows N=486.

## DEFINITION OF DONE
- [ ] `FRAILTY_HANDOVER.md` no longer mentions "Total matched: 126" or "Robust: 6".
- [ ] The file tells a coherent story of the final analysis.
