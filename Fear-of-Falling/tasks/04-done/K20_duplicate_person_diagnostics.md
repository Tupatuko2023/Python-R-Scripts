# K20 duplicate person diagnostics

## Context

K50 cohort-flow dedup now works in the production path, but the next research
question is diagnostic rather than infrastructural: what do the 14 duplicate
persons actually contain, and how many of the currently excluded ambiguous cases
are true conflicts versus potentially mergeable complementary rows.

This task must not change K50 helper logic. It only analyzes duplicate-person
structure using the real workbook and canonical K50 LONG input.

## Inputs

- `R-scripts/K50/K50.1_COHORT_FLOW.V1_derive-cohort-flow.R`
- `DATA_ROOT/paper_01/analysis/fof_analysis_k50_long.rds`
- `DATA_ROOT/paper_02/KAAOS_data_sotullinen.xlsx`

## Outputs

- `R-scripts/K20/K20_duplicate_person_diagnostics.R`
- `R-scripts/K20/outputs/k20_duplicate_person_summary.csv`
- `R-scripts/K20/outputs/k20_duplicate_person_diagnostics.csv`

## Definition of Done (DoD)

- all 14 duplicate persons are classified diagnostically
- ambiguous/conflict structure is summarized at aggregate level
- no SSN, bridge id, or row-level personal identifier is written to outputs

## Log

- 2026-03-15T20:26:00+02:00 Task created for duplicate-person diagnostics after
  production K50 dedup validation was completed.
- 2026-03-15T20:36:00+02:00 Added `R-scripts/K20/K20_duplicate_person_diagnostics.R`
  to classify workbook duplicate persons using the production bridge
  `id <-> NRO` and the canonical K50 LONG input.
- 2026-03-15T20:41:00+02:00 Production run completed successfully. Aggregate
  summary: duplicate_persons_total=14, identical_rows=4,
  complementary_rows=1, true_conflicts=9, unknown=0,
  mergeable_candidates=1.
- 2026-03-15T20:41:00+02:00 K50 ambiguity cross-check: k50_ambiguous_total=8,
  k50_ambiguous_true_conflicts=8, k50_ambiguous_complementary_rows=0. This
  indicates all 8 currently excluded ambiguous cases are true conflicts under
  the present diagnostics, while the only mergeable candidate falls outside the
  current K50 ambiguous set.
- 2026-03-15T20:41:00+02:00 Privacy check passed for K20 outputs: no Sotu, SSN,
  bridge id, or workbook path tokens remain in summary, diagnostics, or receipt
  artifacts.
- 2026-03-15T20:57:49+02:00 Final interpretation: only 1 of 14 duplicate-person
  cases is potentially mergeable (`COMPLEMENTARY_ROWS`). All 8 K50 ambiguous
  exclusions are diagnosed as true conflicts, so the current K50 dedup strategy
  is methodologically conservative and does not appear to discard mergeable
  ambiguous cases.
