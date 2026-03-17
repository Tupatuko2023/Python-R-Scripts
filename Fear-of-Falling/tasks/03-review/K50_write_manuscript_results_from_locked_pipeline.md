# K50 write manuscript results from locked pipeline

## Context

The K50 pipeline is now complete through:

- primary confirmatory analysis
- FI22-adjusted sensitivity analysis
- integrated result synthesis
- forensic code audit
- model diagnostics report
- robustness confirmation

The current review baseline is methodologically complete. The primary,
frailty-adjusted, diagnostic, and robustness stages all support the same
bottom line: fear of falling does not show evidence of a different 12-month
locomotor decline trajectory, and the main remaining caveat is missingness
rather than model instability or pipeline error.

## Inputs

- `tasks/03-review/K50_run_primary_analysis_from_canonical_export.md`
- `tasks/03-review/K50_run_sensitivity_fi22_and_missingness.md`
- `tasks/03-review/K50_write_integrated_results_summary.md`
- `tasks/03-review/K50_model_diagnostics_report.md`
- `tasks/03-review/K50_robustness_check_influence_and_se.md`
- locked K50 output tables under `R-scripts/K50/outputs/`

## Outputs

- one manuscript-oriented K50 results note or draft subsection
- explicit numeric reporting for:
  - primary `WIDE`
  - primary `LONG`
  - FI22-adjusted `WIDE`
  - FI22-adjusted `LONG`
  - `WIDE` robustness confirmation
- a short limitations paragraph retaining the missingness caveat

## Definition of Done (DoD)

- Results text is written from the locked review baseline with no new models.
- The narrative explicitly states that:
  - `WIDE` remains null in primary and robustness checks
  - `LONG` shows a baseline `FOF_status` association before FI22 adjustment
  - the `LONG` baseline association attenuates after FI22 adjustment
  - no `time * FOF_status` interaction appears
- The text explicitly notes that robustness checks did not materially change
  the `WIDE` inference.
- Missingness remains the main methodological caveat.
- `R-scripts/K50/K50.r` remains unchanged.
- `Composite_Z` remains verification-only.
- `FI22_nonperformance_KAAOS` remains sensitivity-only.
- Task moves to `tasks/03-review/` after the manuscript-oriented note is
  written.

## Constraints

- Do not run new models.
- Do not modify `R-scripts/K50/K50.r`.
- Do not introduce aliases.
- Do not relabel `Composite_Z` as `z3`.
- Do not move `FI22_nonperformance_KAAOS` into locomotor outcome construction.
- Do not touch unrelated queue items or the unrelated deletion outside this
  task.

## Canonical work order

1. Re-read the locked K50 review tasks
2. Crosscheck manuscript text directly against the final output tables
3. Write a compact manuscript-oriented results narrative
4. Retain the missingness limitation explicitly
5. Move the task to `tasks/03-review/`

## Links

- `tasks/03-review/K50_write_integrated_results_summary.md`
- `tasks/03-review/K50_model_diagnostics_report.md`
- `tasks/03-review/K50_robustness_check_influence_and_se.md`
- `R-scripts/K50/outputs/`

## Draft Results

In the baseline-adjusted `WIDE` analysis, fear of falling was not associated
with 12-month locomotor capacity. The adjusted `FOF_status` estimate was small
and compatible with the null in the primary model (`estimate=-0.025`,
`p=0.559`, `n=239`) and remained null after FI22 adjustment
(`estimate=-0.006`, `p=0.886`, `n=237`). The narrow `WIDE` robustness checks
did not materially change this conclusion: after removal of the most
influential observation (`id=42`, Cook's distance `1.534`), the
`FOF_status` estimate was `-0.028` (`p=0.469`, `n=238`), and the bootstrap
percentile interval for the primary `FOF_status` coefficient remained
compatible with the null (`-0.099` to `0.051`, `2000` resamples).

In the `LONG` mixed-model analysis, baseline fear of falling was associated
with lower locomotor capacity before frailty adjustment, but there was no
evidence of a different change trajectory over time. In the primary `LONG`
model, the baseline `FOF_status` main effect was negative
(`estimate=-0.097`, `p=0.019`, `n=650`), whereas the `time * FOF_status`
interaction was not detected (`estimate=0.0016`, `p=0.648`). After FI22
adjustment, the baseline `FOF_status` association attenuated toward the null
(`estimate=-0.012`, `p=0.752`, `n=644`), while the interaction remained
absent (`estimate=0.00175`, `p=0.620`). FI22 itself was a strong negative
covariate in the frailty-adjusted `LONG` model (`estimate=-1.752`,
`p<0.001`), indicating that frailty accounted for much of the observed
baseline difference between `FOF_status` groups and supporting the
interpretation that fear of falling behaves more as a frailty marker than as
an independent predictor of 12-month locomotor decline.

The descriptive and model-based figures were consistent with the same
interpretation. The faceted raw-data figure and the predicted
`delta_locomotor_capacity` figure both showed substantial overlap between the
two `FOF_status` groups across the FI22 range and did not suggest a large
FI22-by-FOF gradient in change. These figures are illustrative only and do not
replace the locked primary, sensitivity, diagnostic, or robustness analyses.

Missingness remains the main methodological caveat. The `WIDE` and `LONG`
analyses must be interpreted as different analysis populations, and the
FI22-complete sensitivity stage further reduced modeled sample sizes
(`WIDE n=237` vs `239`; `LONG n=644` vs `650`). Accordingly, the most
defensible overall interpretation is that fear of falling is associated with
poorer baseline locomotor status in the longitudinal branch before frailty
adjustment, but there is no evidence from the locked K50 pipeline that fear of
falling independently predicts a different 12-month locomotor decline
trajectory.

## Log

- 2026-03-14T00:00:00+02:00 Task created from orchestrator prompt
  `24_3cafofv2.txt` and expert note `6_Z_Score_Composite_Advisor.txt`.
- 2026-03-14T00:00:00+02:00 Task added to `tasks/01-ready/` as the first
  writing-stage step after K50 robustness confirmation closed the analysis
  pipeline at review level.
- 2026-03-14T00:00:00+02:00 Task moved to `tasks/02-in-progress/` for
  manuscript-oriented results writing from the locked K50 review baseline. No
  new models were run in this step.
- 2026-03-14T00:00:00+02:00 Table-to-text crosscheck was completed directly
  from the locked primary, FI22-adjusted, robustness, and visualization
  artifacts. The written narrative keeps `WIDE` and `LONG` populations
  separated, reports the `WIDE` robustness result explicitly, and treats the
  FI22/FOF/delta figures as descriptive rather than inferential replacements.
- 2026-03-14T00:00:00+02:00 Manuscript-oriented K50 results text is now ready
  for review. `R-scripts/K50/K50.r` remained unchanged, `Composite_Z`
  remained verification-only, and `FI22_nonperformance_KAAOS` remained
  sensitivity-only.
- 2026-03-14T00:00:00+02:00 Follow-up expert review judged the manuscript
  results text methodologically sound and numerically aligned with the locked
  tables. A small journal-level refinement was incorporated by making the FI22
  attenuation sentence explicit about frailty accounting for much of the
  baseline difference between `FOF_status` groups.
