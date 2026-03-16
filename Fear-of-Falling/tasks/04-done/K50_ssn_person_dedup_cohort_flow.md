# K50 SSN-person dedup cohort flow

## Context

K50 cohort-flow helper counts participants at canonical `id` level in both
LONG and WIDE branches. This can double-count the same real person if multiple
rows or ids map to one SSN-backed identity in the verified paper_02 lookup.

The required change is a minimal helper-layer patch in
`R-scripts/K50/K50.1_COHORT_FLOW.V1_derive-cohort-flow.R` that:

- verifies a real bridge key between the canonical K50-ready input and
  `DATA_ROOT/paper_02/KAAOS_data_sotullinen.xlsx`
- derives an in-memory person key from normalized SSN only after verification
- deduplicates person representations before participant gating/counting
- preserves historical raw-id counts while moving downstream cohort counts to a
  deduplicated person basis

## Inputs

- `R-scripts/K50/K50.1_COHORT_FLOW.V1_derive-cohort-flow.R`
- canonical K50-ready LONG/WIDE data resolved by existing helper rules
- `DATA_ROOT/paper_02/KAAOS_data_sotullinen.xlsx` as in-memory identity lookup

## Outputs

- patched K50 cohort-flow helper with fail-closed SSN bridge verification
- updated aggregate count/placeholder/receipt artifacts on rerun
- validation notes and residual risks recorded in task log

## Definition of Done (DoD)

- no raw data is modified
- no SSN, hash, or row-level identity leaks to outputs, manifest, diagrams, or logs
- helper fails closed if no verified bridge key exists
- person-level dedup runs before `missing_tbl`, `valid_id_df`, and `id_gate_df`
- downstream participant counts are derived from deduplicated persons
- at least one smoke validation run is completed and documented

## Constraints

- keep patch scope inside the K50 helper unless a tiny mechanical adjustment is required
- preserve current manifest/output contract
- follow safe mode and max 5 files/run

## Log

- 2026-03-15T18:36:47+02:00 Task created from orchestrator prompt under the
  explicit task-creation exception for K50 SSN-based person deduplication in
  cohort-flow derivation.
- 2026-03-15T18:59:00+02:00 K50 helper patched with in-memory identity lookup,
  verified bridge-column discovery, person-key attachment, and pre-gating
  dedup for both LONG and WIDE branches.
- 2026-03-15T19:00:00+02:00 `fof-preflight` returned WARN only
  (`no manifest logging hints found`); no FAIL guardrails were triggered for
  this patch.
- 2026-03-15T19:06:00+02:00 Synthetic isolated smoke run passed for LONG +
  locomotor_capacity in a temp copy using a fake paper_02 workbook and fake
  canonical K50 CSV. Cohort-flow helper completed, DOT/SVG/PNG rendered, and
  `grep -R -i -E 'hetu|sotu|ssn' R-scripts/K50/outputs diagram manifest`
  returned no hits.
- 2026-03-15T19:06:30+02:00 Residual limitation: real canonical DATA_ROOT was
  not available in this session, so validation used a synthetic local lookup
  bridge instead of the production workbook/input pair. K18 QC was not rerun on
  production-like data in this environment.
- 2026-03-15T19:33:00+02:00 Real workbook check completed from
  `DATA_ROOT/paper_02/KAAOS_data_sotullinen.xlsx` using sheet `Taul1` with
  header row detected after one skipped row. Aggregate identity-column summary:
  rows=630, nonmissing_sotu=541, unique_sotu=527, duplicate_rows=14,
  duplicate_persons=14.
- 2026-03-15T19:34:00+02:00 Current status after real workbook aggregate check:
  duplicates do exist in the real workbook identity column. Final workbook-level
  interpretation: among 541 non-missing `Sotu` observations there are 527 unique
  persons and 14 duplicate persons, so 527 is the correct person-level maximum
  for non-missing workbook identities. Helper code shows person-level dedup
  before `missing_tbl`, `valid_id_df`, and `id_gate_df`.
- 2026-03-15T19:36:00+02:00 Explicit review status: duplicate existence
  verified on the real workbook; end-to-end canonical K50-ready input +
  workbook rerun remains a separate final validation step unless documented in a
  later run.
- 2026-03-15T19:42:00+02:00 Bridge-key mapping diagnosed from real production
  inputs at aggregate level. Canonical K50 LONG input `id` has 551 unique
  values; workbook sheet `Taul1` column `NRO` also has 551 unique values, with
  overlap=551 after string normalization. Workbook `Sotu` has 527 unique
  non-missing values and overlap=0 against canonical `id`, as expected.
- 2026-03-15T19:43:00+02:00 End-to-end rerun failure is now narrowed to bridge
  detection policy, not duplicate existence: current helper requires a shared
  bridge column name, but the real production bridge is a renamed pair
  `id <-> NRO`.
- 2026-03-15T20:10:07+02:00 Production bridge-map fix applied and validated.
  Helper now accepts the real renamed bridge pair `id <-> NRO`, completed the
  LONG + `locomotor_capacity` cohort-flow run successfully, and wrote updated
  aggregate artifacts. The resulting counts confirm workbook-grounded
  deduplication in production-path output:
  `N_RAW_PERSON_LOOKUP=527`, `EX_DUPLICATE_PERSON_LOOKUP=14`,
  `EX_PERSON_CONFLICT_AMBIGUOUS=8`, `N_ANALYTIC_PRIMARY=225`.
- 2026-03-15T20:21:03+02:00 Final review status: ready for human acceptance /
  move to `tasks/04-done`. Production artifacts confirm workbook-grounded
  person lookup (`n_raw_person_lookup=527`, `ex_duplicate_person_lookup=14`)
  and final analytic sample size `participants_modeled=225` without SSN
  exposure in output artifacts.
