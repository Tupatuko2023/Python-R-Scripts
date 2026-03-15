# K50 robustness check influence and SE

## Context

The K50 pipeline is now complete through:

- primary confirmatory analysis
- FI22-adjusted sensitivity analysis
- integrated result synthesis
- forensic code audit
- model diagnostics report

Diagnostics did not identify a coding defect or a major model-form problem, but
they did identify two remaining practical caveats:

- imperfect residual normality in both `WIDE` and `LONG`
- a few influential observations in the `WIDE` branch

The next useful step is therefore a narrow robustness check, not a new modeling
architecture.

## Inputs

- `R-scripts/K50/K50.r`
- `tasks/03-review/K50_model_diagnostics_report.md`
- `tasks/03-review/K50_write_integrated_results_summary.md`
- canonical K50-ready inputs under `DATA_ROOT/paper_01/analysis/`
- primary K50 outputs under `R-scripts/K50/outputs/`
- `manifest/manifest.csv`

## Outputs

- one robustness note addressing:
  - whether `WIDE` results are sensitive to influential observations
  - whether robust SE or bootstrap CI materially change the inference
- robustness artifacts and manifest rows if generated

## Definition of Done (DoD)

- At least one narrow robustness check is executed for the locked primary K50
  branch, preferably targeting:
  - `WIDE` influential-observation sensitivity
  - robust standard errors and/or bootstrap confidence intervals
- The note explicitly reports whether the substantive conclusion changes.
- The task does not reopen outcome architecture or core formula design.
- `R-scripts/K50/K50.r` remains unchanged unless a genuine coding defect is
  separately proven.
- `Composite_Z` remains verification-only.
- `FI22_nonperformance_KAAOS` remains sensitivity-only.
- Task moves to `tasks/03-review/` after the robustness note is written.

## Constraints

- Do not introduce new outcome aliases.
- Do not relabel `Composite_Z` as `z3`.
- Do not move `FI22_nonperformance_KAAOS` into locomotor outcome construction.
- Do not touch unrelated queue items or the unrelated deletion outside this
  task.

## Canonical work order

1. Re-read diagnostics and integrated summary notes
2. Choose the smallest justified robustness check
3. Run the robustness check
4. Compare the result against the locked primary inference
5. Write the robustness note

## Links

- `tasks/03-review/K50_model_diagnostics_report.md`
- `tasks/03-review/K50_write_integrated_results_summary.md`
- `R-scripts/K50/K50.r`

## Robustness Summary

The narrow robustness check was run on the locked primary `WIDE` model only,
matching the diagnostics-led concern about influential observations and
residual non-normality. The primary `FOF_status` coefficient remained null
after both checks:

- primary `WIDE`: `estimate=-0.025`, `p=0.559`, `n=239`
- after removing the max-Cook observation (`id=42`, Cook's distance `1.534`):
  `estimate=-0.028`, `p=0.469`, `n=238`
- bootstrap percentile CI for the primary `FOF_status` coefficient:
  `-0.099` to `0.051` with `2000` resamples

The substantive conclusion therefore did not change. This robustness step did
not reopen outcome architecture, model formulas, or `R-scripts/K50/K50.r`.
Missingness remains the main caveat carried forward from the prior review
stages.

This leaves the K50 analysis package methodologically complete at review
level. The locked primary result, FI22 sensitivity result, diagnostics, and
robustness confirmation now all point in the same direction: the main
remaining caveat is missingness rather than model instability, formula error,
or outcome-architecture ambiguity.

## Log

- 2026-03-14T00:00:00+02:00 Task created from orchestrator prompt
  `19_3cafofv2.txt` and expert note `4_Z_Score_Composite_Advisor.txt`.
- 2026-03-14T00:00:00+02:00 Task added to `tasks/01-ready/` as the next
  optional robustness step after diagnostics review completion.
- 2026-03-14T00:00:00+02:00 Subsequent methodological review confirmed this as
  the correct next step: diagnostics did not reveal a coding or formula defect,
  so the remaining justified work is a narrow robustness check focused on
  `WIDE` influential observations and/or robust inference, not a new model or
  outcome redesign.
- 2026-03-14T00:00:00+02:00 Additional methodological lock confirmed that the
  pipeline is now frozen before robustness: primary analysis, FI22 sensitivity,
  integrated synthesis, forensic audit, and diagnostics are complete, and this
  task is the next narrow confirmation step rather than a reopening of model
  architecture.
- 2026-03-14T00:00:00+02:00 A subsequent methodological confirmation again
  supported the same scope decision: the pipeline is analysis-complete through
  diagnostics, and this task remains the next justified step because it tests
  robustness without changing outcome architecture, core formulas, or the
  locked `K50` implementation.
- 2026-03-14T00:00:00+02:00 Task moved to `tasks/02-in-progress/` and
  executed as a narrow `WIDE` robustness confirmation. No changes were made to
  `R-scripts/K50/K50.r`, `Composite_Z` remained verification-only, and
  `FI22_nonperformance_KAAOS` remained sensitivity-only.
- 2026-03-14T00:00:00+02:00 Robustness artifacts were written under
  `R-scripts/K50/outputs/` and appended to `manifest/manifest.csv` one row per
  artifact: influential-observation table, primary-vs-trimmed comparison
  table, bootstrap summary, robustness note, and session info.
- 2026-03-14T00:00:00+02:00 The locked primary `WIDE` null conclusion was
  materially unchanged by the robustness checks. Removing the max-Cook
  observation (`id=42`) shifted `FOF_status1` only from `estimate=-0.025`,
  `p=0.559`, `n=239` to `estimate=-0.028`, `p=0.469`, `n=238`, and the
  bootstrap percentile CI remained compatible with the null (`-0.099` to
  `0.051`, `2000` resamples).
- 2026-03-14T00:00:00+02:00 Follow-up methodological review confirmed that the
  robustness result is strong enough to close the analysis pipeline at review
  level. The remaining caveat is still missingness, not instability from
  influential observations, residual non-normality, coding defects, or outcome
  design. The next justified step is manuscript-oriented results writing from
  the locked K50 review baseline rather than any further model redesign.
