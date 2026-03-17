# K50 run sensitivity FI22 and missingness

## Context

The primary confirmatory K50 analysis is now complete and locked as the review
baseline:

- canonical upstream export from `R-scripts/K32/k32.r` works end-to-end
- `R-scripts/K50/K50.r` remains analytically unchanged
- primary outcome stays `locomotor_capacity`
- `Composite_Z` stays verification-only
- fallback `z3` stays a robustness check
- `FI22_nonperformance_KAAOS` stays sensitivity-only

The next stage is no longer primary modeling. It is a sensitivity and
robustness stage focused on FI22 adjustment and missingness bias review.

## Inputs

- `R-scripts/K50/K50.r`
- `R-scripts/K50/outputs/`
- `tasks/03-review/K50_run_primary_analysis_from_canonical_export.md`
- canonical K50 inputs under `DATA_ROOT/paper_01/analysis/`
- `manifest/manifest.csv`

## Outputs

- FI22-adjusted K50 output artifacts for `WIDE` and `LONG`
- updated K50 sensitivity review notes
- manifest rows for each produced FI22 sensitivity artifact

## Definition of Done (DoD)

- `R-scripts/K50/K50.r` runs successfully for:
  - `--shape WIDE --outcome locomotor_capacity --fi22 on`
  - `--shape LONG --outcome locomotor_capacity --fi22 on`
- FI22-adjusted result tables are inspected against the locked primary
  confirmatory baseline.
- Review explicitly states whether FI22 adjustment changes:
  - the `FOF_status` result in `WIDE`
  - the `FOF_status` main effect in `LONG`
  - the `time * FOF_status` interaction in `LONG`
- Missingness robustness review is updated using the existing
  `Group x Time` missingness artifacts and the already observed population
  difference between `WIDE` (`n=239`) and `LONG` (`n=650`).
- `manifest/manifest.csv` gets one row per produced FI22 sensitivity artifact.
- `R-scripts/K50/K50.r` stays analytically unchanged.
- `Composite_Z` remains verification-only.
- `FI22_nonperformance_KAAOS` remains sensitivity-only and does not become part
  of locomotor outcome construction.
- Task moves to `tasks/03-review/` after successful execution.

## Constraints

- Do not modify `R-scripts/K50/K50.r` analytically.
- Do not change canonical outcome naming.
- Do not introduce aliases or bridges.
- Do not relabel `Composite_Z` as `z3`.
- Do not move `FI22_nonperformance_KAAOS` into primary locomotor construction.
- Do not touch unrelated queue items or the unrelated deletion outside this
  task.

## Canonical run order

1. `Rscript R-scripts/K50/K50.r --shape WIDE --outcome locomotor_capacity --fi22 on`
2. `Rscript R-scripts/K50/K50.r --shape LONG --outcome locomotor_capacity --fi22 on`
3. Inspect FI22-adjusted output tables under `R-scripts/K50/outputs/`
4. Compare FI22-adjusted results against the locked primary review baseline
5. Recheck missingness robustness notes and `WIDE` versus `LONG` population
   difference
6. Inspect `manifest/manifest.csv`

## Links

- `R-scripts/K50/K50.r`
- `tasks/03-review/K50_run_primary_analysis_from_canonical_export.md`
- `manifest/manifest.csv`

## Log

- 2026-03-14T00:00:00+02:00 Task created from orchestrator prompt
  `12_3cafofv2.txt`.
- 2026-03-14T00:00:00+02:00 Task added to `tasks/01-ready/` for the next
  sensitivity stage: FI22-adjusted models, missingness robustness review, and
  `WIDE` versus `LONG` population-difference crosscheck.
- 2026-03-14T00:00:00+02:00 Task moved to `tasks/02-in-progress/` for
  execution: run `K50` with `--fi22 on` for `WIDE` and `LONG`, inspect output
  artifacts, compare against the locked primary baseline, and verify manifest
  rows before review handoff.
- 2026-03-14T00:00:00+02:00 Both FI22-adjusted runs failed closed at the same
  K50 contract gate before model fitting:
  `K50 --fi22 on requires canonical FI22_nonperformance_KAAOS`.
- 2026-03-14T00:00:00+02:00 No new K50 sensitivity artifacts were produced and
  no new K50 manifest rows were appended; the manifest remains at the prior
  14-row primary run cluster for timestamp prefix `2026-03-14 07:09:`.
- 2026-03-14T00:00:00+02:00 The blocker is upstream input availability rather
  than K50 runtime logic. `K50.r` remained analytically unchanged, and the next
  prerequisite is to materialize canonical `FI22_nonperformance_KAAOS` into the
  K50-ready export layer before this sensitivity task can be completed.
- 2026-03-14T00:00:00+02:00 Upstream prerequisite was subsequently resolved by
  extending the canonical K32 export with sensitivity-only
  `FI22_nonperformance_KAAOS`; both `WIDE` and `LONG` K50-ready inputs now
  contain the canonical FI22 column, and the earlier missing-column gate no
  longer triggers in `K50 --fi22 on` smoke runs.
- 2026-03-14T00:00:00+02:00 This sensitivity task remains open for the actual
  FI22-adjusted result comparison and missingness-robustness interpretation,
  now that the upstream prerequisite has been satisfied.
- 2026-03-14T00:00:00+02:00 Continuing with the actual sensitivity-stage
  execution and result comparison: rerun FI22-adjusted `WIDE` and `LONG`
  models sequentially, inspect `model_terms_fi22` outputs, compare against the
  locked primary baseline, verify manifest rows, and move to review only after
  the comparison is written.
- 2026-03-14T00:00:00+02:00 FI22-adjusted `WIDE` sensitivity run completed
  successfully with `rows_loaded=551`, `rows_modeled=237`,
  `fi22_enabled=TRUE`, and `allow_composite_z_verified=FALSE`.
- 2026-03-14T00:00:00+02:00 FI22-adjusted `LONG` sensitivity run completed
  successfully with `rows_loaded=1102`, `rows_modeled=644`,
  `fi22_enabled=TRUE`, and `allow_composite_z_verified=FALSE`.
- 2026-03-14T00:00:00+02:00 Review comparison against the locked primary
  baseline found that `WIDE` remains null for `FOF_status`: primary baseline
  was `estimate=-0.025`, `p=0.559`, `n=239`, and FI22-adjusted sensitivity is
  `estimate=-0.006`, `p=0.886`, `n=237`.
- 2026-03-14T00:00:00+02:00 Review comparison against the locked primary
  baseline found that the `LONG` baseline `FOF_status` main effect is
  materially attenuated by FI22 adjustment: primary baseline was
  `estimate=-0.097`, `p=0.019`, `n=650`, while FI22-adjusted sensitivity is
  `estimate=-0.012`, `p=0.752`, `n=644`.
- 2026-03-14T00:00:00+02:00 The `LONG` `time * FOF_status` interaction remains
  non-detectable after FI22 adjustment: primary baseline was
  `estimate=0.0016`, `p=0.648`, and FI22-adjusted sensitivity is
  `estimate=0.00175`, `p=0.620`.
- 2026-03-14T00:00:00+02:00 FI22 itself behaves as a strong negative covariate
  in the `LONG` model (`estimate=-1.752`, `p<0.001`) and a borderline negative
  covariate in the `WIDE` model (`estimate=-0.390`, `p=0.053`), while remaining
  explicitly sensitivity-only rather than part of locomotor outcome
  construction.
- 2026-03-14T00:00:00+02:00 Missingness robustness note remains review-only and
  unchanged in direction: the `Group x Time` missingness tables are the same as
  in the primary stage, and interpretation continues to keep `WIDE` (`n=237`
  under FI22 completeness) and `LONG` (`n=644` under FI22 completeness) as
  different analysis populations rather than pooling them.
- 2026-03-14T00:00:00+02:00 Both FI22 QC gate files remained fully green with
  `fi22_gate=TRUE`, `composite_z_gate=TRUE`, and grip excluded from the core
  locomotor branch.
- 2026-03-14T00:00:00+02:00 Manifest verification for the final FI22 sensitivity
  execution found 16 machine-readable K50 rows for the `2026-03-14 09:28` and
  `2026-03-14 09:29` timestamp clusters: 8 `WIDE` artifacts and 8 `LONG`
  artifacts, including `model_terms_fi22`, QC gates, missingness summaries,
  receipts, decision logs, and session info.
- 2026-03-14T00:00:00+02:00 Task is ready for `tasks/03-review/`. `K50.r`
  remained analytically unchanged, `Composite_Z` remained verification-only, and
  `FI22_nonperformance_KAAOS` remained a sensitivity-only covariate.
- 2026-03-15T00:00:00+02:00 Publication note: the reviewed K50 sensitivity
  package was published directly to `origin/main` in commit `f16d704`. This
  means the effective merge already occurred at push time, so no artificial
  follow-up PR is opened for the same change set.
