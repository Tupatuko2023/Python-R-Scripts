# K50 bridge map id to NRO

## Context

The production workbook bridge for K50 person-level dedup is now identified:
canonical K50 LONG input uses `id`, while workbook sheet `Taul1` uses `NRO`.
Current helper logic requires a shared bridge column name and therefore fails
before end-to-end execution even though aggregate overlap is complete.

## Inputs

- `R-scripts/K50/K50.1_COHORT_FLOW.V1_derive-cohort-flow.R`
- `DATA_ROOT/paper_01/analysis/fof_analysis_k50_long.rds`
- `DATA_ROOT/paper_02/KAAOS_data_sotullinen.xlsx`

## Outputs

- minimal bridge-map patch allowing `id <-> NRO`
- updated review note documenting the production bridge mapping
- successful end-to-end helper run if no other blockers remain

## Definition of Done (DoD)

- helper accepts the renamed production bridge pair `id <-> NRO`
- bridge verification no longer fails on the shared-name requirement
- helper completes end-to-end for LONG + `locomotor_capacity`

## Log

- 2026-03-15T20:02:24+02:00 Task created for the minimal production bridge-map
  fix after aggregate verification showed `id <-> NRO` overlap=551.
- 2026-03-15T20:10:07+02:00 Added a minimal bridge alias map to the helper so
  production workbook column `NRO` is accepted as the canonical `id` bridge.
- 2026-03-15T20:10:07+02:00 Validation passed: helper parses successfully and
  the production LONG + `locomotor_capacity` cohort-flow run completed without
  the prior bridge-verification error. Counts artifact shows
  `N_RAW_PERSON_LOOKUP=527`, `EX_DUPLICATE_PERSON_LOOKUP=14`, and
  `N_ANALYTIC_PRIMARY=225`.
- 2026-03-15T20:21:03+02:00 Final review status: ready for human acceptance /
  move to `tasks/04-done`. The production bridge `id <-> NRO` is documented and
  validated by the successful production-path cohort-flow run.
