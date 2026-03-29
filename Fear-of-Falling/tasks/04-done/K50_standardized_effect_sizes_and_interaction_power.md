# K50 standardized effect sizes and interaction power

## Context

Primary analysis, FI22 sensitivity, diagnostics, robustness, visualization,
Results writing, and Discussion writing are complete. The next optional helper
step is a manuscript-supporting supplement that computes standardized or
semi-standardized effect sizes and, if possible, a simulation-based interaction
power estimate for the locked `LONG` interaction term.

## Inputs

- canonical `WIDE` input under `DATA_ROOT/paper_01/analysis/fof_analysis_k50_wide.rds`
- canonical `LONG` input under `DATA_ROOT/paper_01/analysis/fof_analysis_k50_long.rds`
- locked K50 output tables under `R-scripts/K50/outputs/`
- `manifest/manifest.csv`

## Outputs

- `k50_wide_standardized_effects.csv`
- `k50_long_standardized_effects.csv`
- `k50_standardized_effects_and_power_note.txt`
- `k50_standardized_effects_and_power_sessioninfo.txt`
- optional `k50_long_interaction_power.csv` only if `simr` is available

## Definition of Done (DoD)

- Helper output is produced without modifying `R-scripts/K50/K50.r`.
- Canonical `WIDE` and `LONG` inputs are used from the repo’s known K50-ready
  paths.
- Continuous covariates receive standardized beta-style estimates and binary
  terms receive semi-standardized outcome-SD estimates.
- The interaction interpretation remains cautious: “no interaction detected”
  and, if needed, “limited power to detect small interaction effects.”
- `Composite_Z` remains verification-only.
- `FI22_nonperformance_KAAOS` remains sensitivity-only.
- Task moves to `tasks/03-review/` after helper artifacts are written.

## Constraints

- Do not modify `R-scripts/K50/K50.r`.
- Do not reopen outcome architecture or primary model formulas.
- Do not introduce aliases.
- Do not relabel `Composite_Z` as `z3`.
- Do not move `FI22_nonperformance_KAAOS` into locomotor outcome construction.

## Log

- 2026-03-14T00:00:00+02:00 Task created from orchestrator prompt
  `28_3cafofv2.txt` and expert note `13_Z_Score_Composite_Advisor.txt`.
- 2026-03-14T00:00:00+02:00 Task moved to `tasks/02-in-progress/` as an
  optional helper stage. `K50.r` remained unchanged, `Composite_Z` remained
  verification-only, and `FI22_nonperformance_KAAOS` remained sensitivity-only.
- 2026-03-14T00:00:00+02:00 Canonical `WIDE` and `LONG` K50-ready inputs were
  confirmed available at the expected repo paths, and both included the
  canonical FI22 sensitivity covariate.
- 2026-03-14T00:00:00+02:00 Post-hoc standardized helper estimates were
  written from locked K50 output tables plus canonical input SDs:
  `k50_wide_standardized_effects.csv` and
  `k50_long_standardized_effects.csv`.
- 2026-03-14T00:00:00+02:00 `simr` was not available in the current runtime,
  so simulation-based interaction power was skipped fail-closed and recorded in
  `k50_standardized_effects_and_power_note.txt` with conservative manuscript
  guidance: report the interaction as “no interaction detected” and, if
  helpful, note limited power to detect small interaction effects.
- 2026-03-14T00:00:00+02:00 Manifest rows were appended one per produced helper
  artifact. This helper stage does not replace the locked primary or FI22
  sensitivity results; it provides manuscript-supporting standardized effect
  summaries only.
