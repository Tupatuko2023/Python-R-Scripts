# K51 three-key linkage audit

## Goal

Audit only the three unresolved baseline/canonical cases behind the current
K51 fail-closed enrichment gap and determine whether a local Table 1 override
would be safe without changing global dedup or compare logic.

Target canonical ids:

- 18
- 100
- 102

Current unresolved status:

- `partial_coverage_missing_person_keys=3`
- current unresolved ids are documented in
  `R-scripts/K51/outputs/k51_missing_person_keys_baseline_eligible.csv`

## Scope

- do not change K50 gating
- do not relax global `compare_cols` in shared dedup logic
- do not use "first row wins"
- do not modify raw data
- inspect only workbook / bridge candidates relevant to canonical ids 18, 100,
  and 102
- decide only whether a local Table 1 override is safe for these three cases

## Definition of Done

- one audit row exists per canonical id (`18`, `100`, `102`)
- each row lists workbook/bridge candidates and the exact source used
- each row lists full compare-field differences
- each row marks which differences are Table 1-relevant
- each row has a binary `safe_override_for_table1` decision with rationale
- no global K51/person-dedup logic change is made before the audit is complete

## Proposed outputs

- `R-scripts/K51/outputs/k51_three_key_linkage_audit.csv`
- `R-scripts/K51/outputs/k51_three_key_linkage_audit.txt`

## Required evidence per case

- `canonical_id`
- candidate workbook row / `candidate_nro`
- source used to find the candidate (`KAAOS_data_sotullinen.xlsx`,
  `KAAOS_data.xlsx`, `sotut.xlsx`)
- `core_match_fof`
- `core_match_sex`
- `core_match_bmi`
- `full_compare_diff_cols`
- `table1_relevant_diff_cols`
- `safe_override_for_table1`
- `override_rule_notes`

## Notes

- Gemini's hypothesis is plausible but not yet accepted.
- The current repository artifacts prove only that the unresolved set is now
  small and localised, not that a global compare relaxation is safe.
- If all three cases are confirmed safe for Table 1, the preferred follow-up is
  a narrow local override or similarly scoped patch only for those cases.
- If any case differs on a Table 1-reported variable, keep the current
  fail-closed outcome.

## Log

- 2026-03-16T00:00:00+02:00 Task created from orchestrator prompt
  `prompts/21_4cafofv2.txt`.
- 2026-03-16T00:00:00+02:00 Current working assumption: Gemini's finding is
  `plausible but not yet accepted`; audit first, patch second.
- 2026-03-16T20:04:27+02:00 Added audit runner `R-scripts/K51/K51_three_key_linkage_audit.R` and wrote `R-scripts/K51/outputs/k51_three_key_linkage_audit.csv` plus `R-scripts/K51/outputs/k51_three_key_linkage_audit.txt`; manifest rows appended under script label `K51_three_key_linkage_audit`.
- 2026-03-16T20:04:27+02:00 Audit result: all three unresolved canonical ids (`18`, `100`, `102`) have exact-SSN candidates in `KAAOS_data_sotullinen.xlsx` with candidate NRO values `314`, `285`, and `288`.
- 2026-03-16T20:04:27+02:00 Core audit fields matched for every case: `core_match_fof=TRUE`, `core_match_sex=TRUE`, `core_match_bmi=TRUE`. No Table 1-relevant difference columns were detected in the audit output, so all three cases were marked `safe_override_for_table1=TRUE`.
- 2026-03-16T20:04:27+02:00 No global K51/person-dedup logic was changed during the audit. Current status is now: audit evidence supports a future narrow local override for these three cases, but the override/rerun patch remains a separate follow-up step.
