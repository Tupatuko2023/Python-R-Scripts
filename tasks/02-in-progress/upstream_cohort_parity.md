# TASK: Upstream Cohort Parity (Manuscript vs Current)

## STATUS
- State: Done
- Priority: CRITICAL
- Context: Strict replication – cohort parity with manuscript

## OBJECTIVE
Deterministically locate where FOF_No drops from 147 to 144 in upstream cohort construction.

## REQUIRED OUTPUTS (AGGREGATES ONLY)
### A) Raw FOF distribution (no filters)
- n_total_raw
- n_fof0_raw
- n_fof1_raw
- n_invalid_fof_raw

### B) Stepwise inclusion counts
For each step, report: `step`, `n_total`, `n_fof0`, `n_fof1`
Steps:
1. Baseline eligibility
2. Age bounds
3. Registry presence requirement
4. Follow-up construction
5. Death censoring
6. Final analytic cohort

### C) Follow-up sanity
- n_missing_followup
- n_nonpositive_py
- min_followup_days
- median_followup_days

### D) Linkage parity (if link table used)
- pre_link n_fof0 / n_fof1
- post_link n_fof0 / n_fof1

## CONSTRAINTS
- No Table 2 code changes.
- No new model or hospital logic changes.
- Aggregates only; no paths or IDs printed.

## RESULTS (AGGREGATES)
### A) Raw FOF distribution
- n_total_raw=474
- n_fof0_raw=144
- n_fof1_raw=330
- n_invalid_fof_raw=0

### B) Stepwise inclusion counts
- 1_baseline_fof_valid: n_total=474, n_fof0=144, n_fof1=330
- 2_age_nonmissing: n_total=474, n_fof0=144, n_fof1=330
- 3_registry_linked: n_total=474, n_fof0=144, n_fof1=330
- 4_followup_positive: n_total=474, n_fof0=144, n_fof1=330
- 5_death_censoring_na: n_total=474, n_fof0=144, n_fof1=330 (no death_date column in aim2_analysis)
- 6_final_analytic: n_total=473, n_fof0=144, n_fof1=329

### C) Follow-up sanity
- n_missing_followup=0
- n_nonpositive_py=0
- min_followup_days=3652.5
- median_followup_days=3652.5

### D) Linkage parity
- pre_link_n_fof0=144; pre_link_n_fof1=330
- post_link_n_fof0=144; post_link_n_fof1=330

## DECISION
- Manuscript N=147/330 is not reachable with current aim2_analysis snapshot (raw distribution already 144/330).
- Deviation must be documented or upstream cohort snapshot must be provided to match manuscript N.
