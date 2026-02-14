# TASK: Add Collapsed Injury-Days QC Metric (Table 2)

## STATUS
- State: 03-review
- Priority: High
- Assignee: Codex

## BACKGROUND
We need a QC metric that counts injury-related hospital days from dxfile without double counting overlaps.

## OBJECTIVE
Add a new QC metric in `R/15_table2/qc/qc_table2_raw_rates.R`:
`injury_hosp_days_collapsed_dx_rate_1000py` (FOF_No / FOF_Yes / Overall).

## CONSTRAINTS
- No path or ID values printed.
- Use existing env vars (DX_ID_COL fallback, DX_START_COL/DX_END_COL).
- No day-expansion for the full dataset; use interval union per person.

## DEFINITION OF DONE
- QC script outputs `injury_hosp_days_collapsed_dx_rate_1000py`.
