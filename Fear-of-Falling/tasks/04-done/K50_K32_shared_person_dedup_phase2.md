# K50/K32 shared person dedup phase 2

## Context

Shared person dedup is already active in K50 main, K50 cohort-flow, and K32
upstream export. The remaining phase-2 gap is to wire the ancillary K50
consumer scripts to the same shared helper and to document in K32 validation
that upstream K32 output is already person-deduplicated.

## Inputs

- `R-scripts/K50/K50_robustness_check_influence_and_se.R`
- `R-scripts/K50/K50_standardized_effect_sizes_and_interaction_power.R`
- `R-scripts/K50/K50_visualize_fi22_fof_delta.R`
- `R-scripts/K32/k32_validation.r`

## Outputs

- ancillary K50 scripts using the shared person dedup helper
- K32 validation note documenting upstream workbook-grounded person dedup

## Definition of Done (DoD)

- ancillary K50 scripts do not consume analysis-ready K50 data without the
  shared helper
- `k32_validation.r` documents upstream dedup without adding a second dedup pass
- no new dedup algorithm is introduced

## Log

- 2026-03-16T03:48:00+02:00 Phase-2 task created to finish ancillary K50
  shared-helper wiring and add an upstream-dedup note to K32 validation.
- 2026-03-16T03:53:00+02:00 Patched
  `K50_robustness_check_influence_and_se.R`,
  `K50_standardized_effect_sizes_and_interaction_power.R`, and
  `K50_visualize_fi22_fof_delta.R` to source the shared
  `person_dedup_lookup.R` helper and deduplicate canonical K50 inputs before
  building analysis data frames.
- 2026-03-16T03:53:00+02:00 Patched `k32_validation.r` only at note level:
  validation now writes an upstream-dedup note stating that `k32.r` performs
  workbook-grounded person dedup before score derivation and canonical K50
  export. No second dedup pass was added.
- 2026-03-16T03:55:00+02:00 Parse validation passed for all four patched
  scripts, and grep confirmed the three ancillary K50 scripts now reference the
  shared helper directly.
- 2026-03-16T03:56:00+02:00 Cohort-flow control rerun still produced the same
  validated reference counts:
  `N_RAW_PERSON_LOOKUP=527`,
  `EX_DUPLICATE_PERSON_LOOKUP=14`,
  `EX_PERSON_CONFLICT_AMBIGUOUS=8`,
  `N_ANALYTIC_PRIMARY=225`.
- 2026-03-16T03:56:00+02:00 Privacy grep still flags existing stale K32 output
  artifacts from earlier runs (`k32_columns_after_clean_names.txt`,
  `k32_decision_log.txt`, `k32_patient_level_output_receipt.txt`). This phase-2
  task did not rerun K32 because the known runtime blockers remain separate
  environment issues; newly patched scripts avoid introducing new dedup or
  privacy logic.
