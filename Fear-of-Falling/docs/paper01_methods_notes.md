# Paper 01 Methods Notes

## Current Analysis State

- Cohort-flow helper now performs person-level deduplication in the production
  path before participant gating.
- Current long-branch cohort-flow starting point:
  `N_ANALYTIC_PRIMARY = 225`.
- Workbook-grounded person lookup summary from the production run:
  `N_RAW_PERSON_LOOKUP = 527`
  `EX_DUPLICATE_PERSON_LOOKUP = 14`
  `EX_PERSON_CONFLICT_AMBIGUOUS = 8`

## Person-Level Dedup Procedure

The dedup procedure uses a verified identity workbook from `paper_02` together
with the canonical analysis-ready K50 input from `paper_01/analysis`.

Production bridge mapping:

- canonical analysis id: `id`
- workbook bridge id: `NRO`
- person identity column in workbook: `Sotu`

Operationally:

1. The canonical K50-ready input is loaded from the analysis dataset.
2. The workbook identity lookup is read from sheet `Taul1`.
3. The bridge pair `id <-> NRO` is used to attach a verified person identity in
   memory only.
4. Person-level deduplication is applied before `missing_tbl`, `valid_id_df`,
   and `id_gate_df` are derived.
5. Downstream cohort-flow counts are then computed on the deduplicated person
   basis.

No SSN values, hashes, or row-level identifiers are written to output
artifacts.

## Duplicate Diagnostics

Duplicate-person diagnostics were run separately after the production dedup
pipeline was validated.

Aggregate diagnostic summary:

- duplicate persons total: 14
- identical rows: 4
- complementary rows: 1
- true conflicts: 9
- mergeable candidates: 1

K50 ambiguity cross-check:

- K50 ambiguous cases: 8
- ambiguous cases classified as true conflicts: 8
- ambiguous cases classified as complementary rows: 0

Interpretation:

- only one duplicate-person case appears potentially mergeable
- all eight K50 ambiguous exclusions behave like true conflicts
- the current conservative K50 dedup strategy remains methodologically
  appropriate

## QC Status

Post-dedup K18 QC rerun was attempted against the production K50 long CSV path.
The run did not fail on data structure; it hit the known Termux-specific
`readr`/`vroom` manifest bus-error when writing QC artifacts. This remains an
environment/runtime blocker rather than a dedup or schema blocker.

## Next Analysis Step

With dedup fixed and diagnostics complete, the next analysis step is to continue
the Paper 01 analysis sequence on the deduplicated dataset, using the current
cohort-flow state (`N_ANALYTIC_PRIMARY = 225`) as the analysis baseline.
