# Task: HFRS & CCI Feasibility and Calculation

**Status:** Ready
**Assignee:** Gemini Agent
**Created:** 2026-01-29

## Objective
Calculate Hospital Frailty Risk Score (HFRS) and Charlson Comorbidity Index (CCI) for the Paper 02 cohort.

## Input Data
- `Tutkimusaineisto_osastojakso_diagnoosit (1).xlsx` (Inpatient)
- `Tutkimusaineisto_pkl_kaynnit_2010_2019.csv` (Outpatient)
- `verrokitjatutkimushenkilöt.xlsx` (Linkage)
- `KAAOS_data.xlsx` (FOF Status)

## Outputs
- `outputs/hfrs_scores.csv`
- `outputs/cci_scores.csv`
- `outputs/feasibility_memo.md` (Completed)

## Steps
1. [x] Inventory and Feasibility Check.
2. [ ] Define Index Date for each subject.
3. [ ] Filter diagnoses relative to Index Date (e.g., lookback 2 years).
4. [ ] Map ICD-10 codes to HFRS and CCI weights.
5. [ ] Aggregate scores per subject.
6. [ ] Generate final CSVs.

## Notes
- See `outputs/feasibility_memo.md` for coverage details.
- Controls have high rate of zero utilization (55%).
