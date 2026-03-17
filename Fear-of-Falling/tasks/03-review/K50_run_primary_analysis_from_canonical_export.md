# K50 run primary analysis from canonical export

## Context

`K32` now provides canonical K50-ready wide and long upstream exports, and the
review baseline confirms the export-layer hardening:

- canonical export lives in `R-scripts/K32/k32.r`
- `R-scripts/K50/K50.r` remains an unchanged consumer
- `Composite_Z` stays verification-only
- `FI22_nonperformance_KAAOS` stays sensitivity-only and outside locomotor
  construction

The next task is no longer blocker analysis or architecture work. It is the
first actual K50 analysis run on top of the canonical upstream export.

## Inputs

- `R-scripts/K32/k32.r`
- `R-scripts/K50/K50.r`
- `R-scripts/K32/outputs/k32_canonical_export_qc.csv`
- `R-scripts/K32/outputs/k32_cfa_diagnostics.csv`
- `R-scripts/K32/outputs/k32_mapping_audit.csv`
- `tasks/03-review/K50_canonical_upstream_export.md`
- `tasks/03-review/K50_upstream_input_and_runtime_hardening.md`
- canonical upstream exports under `DATA_ROOT/paper_01/analysis/`

## Outputs

- refreshed canonical K32 exports under `DATA_ROOT/paper_01/analysis/`
- first actual K50 result artifacts under `R-scripts/K50/outputs/`
- updated `manifest/manifest.csv` rows for produced K50 artifacts

## Definition of Done (DoD)

- `R-scripts/K32/k32.r` rerun completes successfully before K50.
- `k32_canonical_export_qc.csv` remains green for:
  - `primary_cfa_admissible`
  - locomotor and z3 completeness gates
  - long/wide coherence
  - `Composite_Z` absent from canonical export
  - `FI22_nonperformance_KAAOS` absent from canonical export
- `R-scripts/K50/K50.r` completes successfully for:
  - `--shape WIDE --outcome locomotor_capacity`
  - `--shape LONG --outcome locomotor_capacity`
- K50 result tables and QC artifacts are written under `R-scripts/K50/outputs/`
  using repo-native conventions.
- `manifest/manifest.csv` gets one row per produced K50 artifact.
- `R-scripts/K50/K50.r` stays analytically unchanged.
- Task remains in `03-review` after execution; nothing is moved to `04-done/`.

## Constraints

- Do not modify `R-scripts/K50/K50.r` analytically.
- Do not reintroduce alias bridges.
- Do not relabel `Composite_Z` as `z3`.
- Do not move `FI22_nonperformance_KAAOS` into locomotor construction.
- Do not touch unrelated queue items or the unrelated deletion outside this
  task.

## Canonical run order

1. `Rscript R-scripts/K32/k32.r`
2. Inspect `R-scripts/K32/outputs/k32_canonical_export_qc.csv`
3. `Rscript R-scripts/K50/K50.r --shape WIDE --outcome locomotor_capacity`
4. `Rscript R-scripts/K50/K50.r --shape LONG --outcome locomotor_capacity`
5. Inspect `R-scripts/K50/outputs/`
6. Inspect `manifest/manifest.csv`

## Links

- `R-scripts/K32/k32.r`
- `R-scripts/K50/K50.r`
- `tasks/03-review/K50_canonical_upstream_export.md`
- `tasks/03-review/K50_upstream_input_and_runtime_hardening.md`

## Log

- 2026-03-14T00:00:00+02:00 Task created from orchestrator prompt `10_3cafofv2.txt`.
- 2026-03-14T00:00:00+02:00 Task added directly to `tasks/01-ready/` per
  repo workflow and orchestration exception for task creation.
- 2026-03-14T00:00:00+02:00 Task moved to `tasks/02-in-progress/` for
  execution run: rerun `K32`, verify export QC, run `K50` primary `WIDE` and
  `LONG`, then inspect outputs and manifest rows.
- 2026-03-14T00:00:00+02:00 `K32` rerun completed successfully and refreshed
  canonical `fof_analysis_k50_wide` and `fof_analysis_k50_long` exports under
  `DATA_ROOT/paper_01/analysis/`.
- 2026-03-14T00:00:00+02:00 `R-scripts/K32/outputs/k32_canonical_export_qc.csv`
  remained green: `primary_cfa_admissible=TRUE`, completeness gates `TRUE`,
  long/wide coherence `TRUE`, `Composite_Z` absent, and
  `FI22_nonperformance_KAAOS` absent.
- 2026-03-14T00:00:00+02:00 `K50` primary analyses completed successfully for
  `--shape WIDE --outcome locomotor_capacity` and
  `--shape LONG --outcome locomotor_capacity`.
- 2026-03-14T00:00:00+02:00 `R-scripts/K50/outputs/` now contains 14 produced
  artifacts for this run: 7 `WIDE` artifacts and 7 `LONG` artifacts, including
  QC gates, missingness summaries, primary model terms, z3 fallback model
  terms, input receipts, decision logs, and `sessioninfo`.
- 2026-03-14T00:00:00+02:00 `manifest/manifest.csv` contains exactly one row
  per produced K50 artifact for this run: 14 unique K50 labels at timestamp
  prefix `2026-03-14 07:09:`.
- 2026-03-14T00:00:00+02:00 Task moved to `tasks/03-review/` after successful
  execution. `R-scripts/K50/K50.r` remained analytically unchanged,
  `Composite_Z` remained verification-only, and
  `FI22_nonperformance_KAAOS` remained sensitivity-only.
- 2026-03-14T00:00:00+02:00 Review crosscheck confirmed the provenance of the
  two primary runs from input receipts and decision logs:
  `fof_analysis_k50_wide.rds` with `rows_loaded=551` and `rows_modeled=239`,
  and `fof_analysis_k50_long.rds` with `rows_loaded=1102` and
  `rows_modeled=650`; in both runs `outcome=locomotor_capacity`,
  `fi22_enabled=FALSE`, `allow_composite_z_verified=FALSE`, and fallback `z3`
  was executed in parallel.
- 2026-03-14T00:00:00+02:00 Review crosscheck of result tables found:
  `WIDE` primary ANCOVA showed no detectable adjusted `FOF_status` effect on
  `locomotor_capacity_12m` (`estimate=-0.025`, `p=0.559`, `n=239`), while
  `LONG` primary mixed model showed a negative baseline `FOF_status` main
  effect (`estimate=-0.097`, `p=0.019`, `n=650`) but no `time * FOF_status`
  interaction (`estimate=0.0016`, `p=0.648`).
- 2026-03-14T00:00:00+02:00 Fallback `z3` review was directionally aligned
  with the primary latent branch: `WIDE` showed no detectable `FOF_status`
  effect (`estimate=-0.043`, `p=0.503`), while `LONG` showed a negative
  `FOF_status` main effect (`estimate=-0.146`, `p=0.043`) and no
  `time * FOF_status` interaction (`estimate=0.00075`, `p=0.890`).
- 2026-03-14T00:00:00+02:00 Both K50 QC gate files remained fully green.
  Missingness-by-Group×Time showed higher outcome missingness at 12 months than
  baseline in both `FOF_status` groups, with the larger burden in
  `FOF_status=1` (`56/340` at baseline and `146/340` at 12 months) than in
  `FOF_status=0` (`16/146` at baseline and `74/146` at 12 months). Review note
  keeps the `WIDE` (`n=239`) and `LONG` (`n=650`) modeled samples explicitly
  separated.
- 2026-03-14T00:00:00+02:00 Primary confirmatory K50 analysis is now locked as
  the review baseline: canonical upstream export resolved end-to-end, primary
  outcome remained `locomotor_capacity`, latent CFA score remained the current
  confirmatory branch, `FI22` remained disabled, `Composite_Z` remained
  verification-only, and fallback `z3` remained a robustness check rather than
  the current primary outcome.
- 2026-03-14T00:00:00+02:00 The next analysis stage is sensitivity and
  robustness rather than additional primary modeling. A separate ready task
  will cover `--fi22 on` runs, missingness robustness review, and explicit
  `WIDE` versus `LONG` population-difference checking, while this primary task
  remains in `tasks/03-review/`.
- 2026-03-15T00:00:00+02:00 Publication note: the locked K50 package containing
  this primary review baseline was published directly to `origin/main` by
  commit `f16d704` (`Lock and publish K50 pipeline through results,
  diagnostics, robustness, visualization, and manuscript support`). No
  retroactive PR+merge step is required for this already-published change set.
