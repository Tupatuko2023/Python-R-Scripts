# TASK: Run Separated Analysis (Outpatient vs Inpatient)

## STATUS
- State: 03-review
- Priority: High
- Assignee: Gemini Termux Orchestrator (S-QF)

## BACKGROUND
The discovery phase confirmed that `aim2_panel.csv` contains distinct columns:
1.  `util_visits_outpatient` (Healthcare services / Poly)
2.  `util_visits_inpatient` (Hospital treatment periods / Ward)

We must now run the statistical models separately for these two outcomes to replicate the original manuscript's finding (where Inpatient IRR was ~1.70 vs Outpatient ~1.18).

## OBJECTIVE
1.  **Consolidate Docs**: Append the findings from `docs/OUTCOME_MAPPING.md` into `docs/DATA_LINKAGE_PROTOCOL.md`, then delete the mapping file.
2.  **Run Targeted Analysis**: Create and execute `R/70_separated_outcomes_analysis.R`.
    -   Model 1: `util_visits_outpatient` (NB, B=500)
    -   Model 2: `util_visits_inpatient` (NB, B=500)
    -   *Crucial*: Use the same 3-class Frailty Interaction model.
3.  **Update Handover**: Add these specific IRRs to `FRAILTY_HANDOVER.md`.

## STEPS
1.  **Doc Cleanup**: Merge mapping info to protocol.
2.  **Create Script (`R/70_separated_outcomes_analysis.R`)**:
    -   Use the code block provided below.
3.  **Execute**: `termux-wake-lock && Rscript R/70_separated_outcomes_analysis.R && termux-wake-unlock`.
4.  **Reporting**: Update the Handover doc with the new separated IRRs.

## DEFINITION OF DONE
 * [x] outputs/separated_outcomes_summary.csv exists.
 * [x] FRAILTY_HANDOVER.md lists distinct IRRs for Outpatient vs Inpatient.
 * [x] docs/OUTCOME_MAPPING.md is removed (content moved to Protocol).
