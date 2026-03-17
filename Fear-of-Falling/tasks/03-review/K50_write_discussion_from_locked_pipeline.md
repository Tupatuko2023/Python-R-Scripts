# K50 write discussion from locked pipeline

## Context

The K50 manuscript-oriented Results text is now written from the locked review
baseline. The next writing-stage step is a Discussion section that interprets
the locked findings without reopening the analysis pipeline.

## Inputs

- `tasks/03-review/K50_write_manuscript_results_from_locked_pipeline.md`
- `tasks/03-review/K50_write_integrated_results_summary.md`
- `tasks/03-review/K50_robustness_check_influence_and_se.md`
- `tasks/03-review/K50_visualize_fi22_fof_delta.md`

## Outputs

- one compact Discussion draft for K50
- explicit interpretation of:
  - fear of falling as marker vs predictor
  - attenuation after FI22 adjustment
  - lack of differential 12-month trajectory
  - missingness as the main methodological caveat

## Definition of Done (DoD)

- The Discussion is written from the locked K50 review baseline.
- No new models are run.
- The text does not reopen outcome architecture or model formulas.
- The discussion explicitly distinguishes baseline association from change
  trajectory.
- The discussion retains missingness as the primary limitation.
- `R-scripts/K50/K50.r` remains unchanged.
- `Composite_Z` remains verification-only.
- `FI22_nonperformance_KAAOS` remains sensitivity-only.
- Task moves to `tasks/03-review/` after the Discussion draft is written.

## Constraints

- Do not run new models.
- Do not modify `R-scripts/K50/K50.r`.
- Do not introduce aliases.
- Do not relabel `Composite_Z` as `z3`.
- Do not move `FI22_nonperformance_KAAOS` into locomotor outcome construction.

## Canonical work order

1. Re-read the locked Results draft
2. Re-read the robustness and visualization review notes
3. Write a compact Discussion draft
4. Keep the pipeline closed and move the task to `tasks/03-review/`

## Draft Discussion

The locked K50 pipeline suggests that fear of falling is better interpreted as
a marker of vulnerability than as an independent predictor of 12-month
locomotor decline. In the baseline-adjusted `WIDE` analysis, fear of falling
did not predict follow-up locomotor capacity, and this null result remained
stable after frailty adjustment and after targeted robustness checks. In the
`LONG` analysis, fear of falling was associated with lower baseline locomotor
capacity before frailty adjustment, but there was no evidence of a different
change trajectory over time, and the baseline association attenuated after
including FI22. Taken together, these findings support the interpretation that
fear of falling captures vulnerability already present at baseline rather than
acting as an independent driver of subsequent locomotor decline.

One plausible explanation is that fear of falling reflects a broader frailty
and vulnerability state that overlaps with reduced physiologic reserve,
mobility limitations, and perceived instability. This interpretation is
supported by the FI22-adjusted `LONG` model, in which FI22 showed a strong
negative association with locomotor capacity while the fear-of-falling effect
attenuated toward the null. Under this reading, fear of falling may remain
clinically useful as a screening marker, but the present results do not support
the claim that it independently predicts a different 12-month locomotor
trajectory once underlying frailty is considered.

The study also has several strengths. The locomotor outcome was derived from a
locked CFA-based capacity pipeline rather than a single observed test. The
analysis combined two complementary model families, `WIDE` ANCOVA and `LONG`
mixed-effects modeling, and both pointed to the same substantive bottom line:
no evidence of differential decline trajectory. In addition, the workflow
included forensic code audit, model diagnostics, targeted robustness checks,
and descriptive/model-based visualization, which together strengthen
confidence that the reported interpretation is not an artifact of coding error,
single-model idiosyncrasy, or one influential observation.

The main limitation remains missingness. The `WIDE` and `LONG` analyses rely on
different modeled samples, and the FI22-complete sensitivity stage further
reduced sample size. Accordingly, the results should be interpreted as
complete-case analyses rather than as fully representative estimates of the
entire source cohort. The observational design also limits causal inference,
and the binary `FOF_status` variable may compress heterogeneity in fear of
falling severity. Nevertheless, within the locked K50 pipeline, the overall
evidence is consistent: fear of falling appears to mark frailty-related
baseline vulnerability more than it predicts an independently faster locomotor
decline trajectory over 12 months.

## Log

- 2026-03-14T00:00:00+02:00 Task created from expert prompt
  `9_Z_Score_Composite_Advisor.txt`.
- 2026-03-14T00:00:00+02:00 Task added to `tasks/01-ready/` as the next
  writing-stage step after the K50 Results draft was judged manuscript-ready
  at review level.
- 2026-03-14T00:00:00+02:00 Task moved to `tasks/02-in-progress/` for
  Discussion writing from the locked K50 review baseline. No new models were
  run in this step.
- 2026-03-14T00:00:00+02:00 The Discussion draft was written to distinguish
  baseline association from change trajectory, interpret FI22 attenuation as
  evidence for frailty-related baseline vulnerability, and keep missingness as
  the main methodological caveat rather than reopening the model pipeline.
