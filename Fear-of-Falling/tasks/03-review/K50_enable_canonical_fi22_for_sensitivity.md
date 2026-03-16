# K50 enable canonical FI22 for sensitivity

## Context

The primary K50 confirmatory analysis is complete and locked. The next intended
sensitivity stage uses the existing K50 CLI flag `--fi22 on`, but both `WIDE`
and `LONG` sensitivity runs currently fail closed with the same gate:

`K50 --fi22 on requires canonical FI22_nonperformance_KAAOS`

This means the blocker is not K50 analysis logic. The blocker is that the
current K50-ready upstream export does not yet carry the canonical
`FI22_nonperformance_KAAOS` variable required for the sensitivity-only branch.

## Inputs

- `R-scripts/K50/K50.r`
- current K50-ready exports under `DATA_ROOT/paper_01/analysis/`
- upstream frailty lineage already documented as sensitivity-only
- `tasks/02-in-progress/K50_run_sensitivity_fi22_and_missingness.md`
- `tasks/03-review/K50_run_primary_analysis_from_canonical_export.md`

## Outputs

- canonical K50-ready exports extended to include
  `FI22_nonperformance_KAAOS`
- refreshed upstream QC evidence showing the FI22 sensitivity column is
  available for K50 sensitivity runs
- updated manifest rows for any newly written upstream artifacts

## Definition of Done (DoD)

- A producing-layer upstream step exposes canonical
  `FI22_nonperformance_KAAOS` into the K50-ready dataset without changing the
  primary locomotor outcome construction.
- The FI22 variable is clearly documented and retained as sensitivity-only.
- `R-scripts/K50/K50.r --shape WIDE --outcome locomotor_capacity --fi22 on`
  no longer fails at the missing-column contract gate.
- `R-scripts/K50/K50.r --shape LONG --outcome locomotor_capacity --fi22 on`
  no longer fails at the missing-column contract gate.
- `R-scripts/K50/K50.r` remains analytically unchanged.
- `Composite_Z` remains verification-only.
- The task moves to `tasks/03-review/` after the upstream prerequisite is
  complete and the FI22 gate resolves.

## Constraints

- Do not modify `R-scripts/K50/K50.r` analytically.
- Do not move `FI22_nonperformance_KAAOS` into the primary locomotor outcome
  construction.
- Do not relabel `Composite_Z` as `z3`.
- Do not introduce aliases or uncontrolled bridges.

## Canonical run order

1. Add canonical `FI22_nonperformance_KAAOS` to the K50-ready upstream export
2. Refresh upstream export artifacts
3. Verify the FI22 column is present in the K50-ready input
4. Smoke-run `K50 --fi22 on` for `WIDE`
5. Smoke-run `K50 --fi22 on` for `LONG`
6. Confirm manifest rows and move the prerequisite task to review

## Links

- `R-scripts/K50/K50.r`
- `tasks/02-in-progress/K50_run_sensitivity_fi22_and_missingness.md`
- `tasks/03-review/K50_run_primary_analysis_from_canonical_export.md`

## Log

- 2026-03-14T00:00:00+02:00 Task created after the first FI22 sensitivity
  execution attempt failed closed in both branches with:
  `K50 --fi22 on requires canonical FI22_nonperformance_KAAOS`.
- 2026-03-14T00:00:00+02:00 Task moved to `tasks/02-in-progress/` to extend
  the K50-ready upstream export with canonical
  `FI22_nonperformance_KAAOS`, rerun the export, verify the column in both
  `WIDE` and `LONG` inputs, and then smoke-run `K50 --fi22 on` in both
  branches.
- 2026-03-14T00:00:00+02:00 K32 canonical export was extended to join the
  existing K40 patient-level frailty artifact from `DATA_ROOT/paper_02/`
  `frailty_vulnerability/kaaos_with_frailty_index_k40.rds` and expose
  canonical `FI22_nonperformance_KAAOS` in both K50-ready `WIDE` and `LONG`
  inputs as a sensitivity-only covariate.
- 2026-03-14T00:00:00+02:00 K32 rerun completed successfully. Export QC now
  reports `FI22_nonperformance_KAAOS` present in the canonical `WIDE` export
  and marked `role=sensitivity_only`, while `Composite_Z` remains absent.
- 2026-03-14T00:00:00+02:00 Canonical input verification passed for both
  shapes: `wide_has_fi22=TRUE` and `long_has_fi22=TRUE`.
- 2026-03-14T00:00:00+02:00 `K50 --shape WIDE --outcome locomotor_capacity --fi22 on`
  completed successfully after the upstream export refresh, so the prior
  missing-column gate is resolved in `WIDE`.
- 2026-03-14T00:00:00+02:00 `K50 --shape LONG --outcome locomotor_capacity --fi22 on`
  completed successfully after the upstream export refresh, so the prior
  missing-column gate is resolved in `LONG`.
- 2026-03-14T00:00:00+02:00 FI22 remained sensitivity-only throughout: it was
  added only as canonical `FI22_nonperformance_KAAOS` in the K50-ready inputs,
  not merged into locomotor outcome construction, and `R-scripts/K50/K50.r`
  remained analytically unchanged.
- 2026-03-14T00:00:00+02:00 Manifest rows now include refreshed K50 FI22 smoke
  artifacts for both shapes, including `model_terms_fi22`, and the malformed
  tail row for `k50_wide_locomotor_capacity_missingness_group_time` was
  normalized so the current K50 cluster is machine-readable.
