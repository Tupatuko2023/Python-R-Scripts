# K50 write integrated results summary

## Context

The current K50 analysis package is now complete at review level:

- primary confirmatory analysis is complete and documented
- FI22-adjusted sensitivity analysis is complete and documented
- canonical K32 to K50 pipeline works end-to-end
- `R-scripts/K50/K50.r` remained analytically unchanged
- `Composite_Z` stayed verification-only
- `FI22_nonperformance_KAAOS` stayed sensitivity-only

The next task is not another model run. It is integrated result synthesis for
the combined K50 review summary.

## Inputs

- `tasks/03-review/K50_run_primary_analysis_from_canonical_export.md`
- `tasks/03-review/K50_run_sensitivity_fi22_and_missingness.md`
- K50 output tables under `R-scripts/K50/outputs/`
- `manifest/manifest.csv`

## Outputs

- one integrated K50 review summary note combining primary and FI22-adjusted
  results
- explicit table-to-text crosscheck before narrative conclusions
- review-ready synthesis of missingness caveat and analysis population
  differences

## Definition of Done (DoD)

- The integrated summary explicitly reports:
  - primary `WIDE` result
  - primary `LONG` result
  - FI22-adjusted `WIDE` result
  - FI22-adjusted `LONG` result
- The summary explicitly states that:
  - `WIDE` remains null before and after FI22 adjustment
  - the `LONG` baseline `FOF_status` effect attenuates after FI22 adjustment
  - no `time * FOF_status` interaction appears in either primary or
    FI22-adjusted `LONG`
- Missingness caveat is retained.
- `WIDE` and `LONG` populations remain explicitly separated, including the
  smaller FI22-complete samples in the sensitivity stage.
- Narrative text is based on table-to-text crosscheck rather than paraphrase by
  memory.
- No new models are run.
- `R-scripts/K50/K50.r` remains unchanged.

## Constraints

- Do not modify `R-scripts/K50/K50.r`.
- Do not run new models.
- Do not introduce aliases.
- Do not relabel `Composite_Z` as `z3`.
- Do not move `FI22_nonperformance_KAAOS` into locomotor outcome construction.
- Do not touch unrelated queue items or the unrelated deletion outside this
  task.

## Canonical work order

1. Re-read the primary review note and linked K50 output tables
2. Re-read the FI22 sensitivity review note and linked K50 output tables
3. Crosscheck key estimates, p-values, and modeled sample sizes
4. Write one integrated K50 review summary
5. Keep current analysis tasks in `tasks/03-review/`

## Links

- `tasks/03-review/K50_run_primary_analysis_from_canonical_export.md`
- `tasks/03-review/K50_run_sensitivity_fi22_and_missingness.md`
- `R-scripts/K50/outputs/`
- `manifest/manifest.csv`

## Integrated Summary

Primary confirmatory analysis and FI22-adjusted sensitivity analysis support a
single coherent K50 interpretation. In `WIDE`, the adjusted `FOF_status` result
is null before and after FI22 adjustment: primary `estimate=-0.025`,
`p=0.559`, `n=239`; FI22-adjusted `estimate=-0.006`, `p=0.886`, `n=237`.

In `LONG`, the primary model shows a negative baseline `FOF_status` main effect
without evidence of differential change over time: primary `FOF_status`
`estimate=-0.097`, `p=0.019`, `n=650`, while `time * FOF_status`
`estimate=0.0016`, `p=0.648`. After FI22 adjustment, the baseline
`FOF_status` effect attenuates away (`estimate=-0.012`, `p=0.752`, `n=644`)
while the interaction remains absent (`estimate=0.00175`, `p=0.620`).

The integrated interpretation is therefore: baseline fear of falling is
associated with poorer locomotor capacity in the longitudinal branch before
frailty adjustment, but this association attenuates after FI22 adjustment and
there is no evidence in any model that fear of falling is associated with a
different 12-month change trajectory.

Missingness remains an explicit caveat. Follow-up missingness is higher than
baseline in both `FOF_status` groups, the burden is larger in `FOF_status=1`,
and `WIDE` versus `LONG` must be treated as different analysis populations.
This remains true in the FI22-complete sensitivity stage, where the modeled
samples are smaller than the primary baseline (`WIDE n=237` vs `239`; `LONG
n=644` vs `650`).

## Log

- 2026-03-14T00:00:00+02:00 Task created from orchestrator prompt
  `14_3cafofv2.txt`.
- 2026-03-14T00:00:00+02:00 Task added to `tasks/01-ready/` for integrated
  K50 result synthesis after primary and FI22 sensitivity review completion.
- 2026-03-14T00:00:00+02:00 Task moved to `tasks/02-in-progress/` for
  table-to-text crosscheck and integrated K50 review synthesis. No new models
  will be run in this step.
- 2026-03-14T00:00:00+02:00 Table-to-text crosscheck completed directly from
  `model_terms_primary` and `model_terms_fi22` tables for all four core
  results: primary `WIDE`, primary `LONG`, FI22-adjusted `WIDE`, and
  FI22-adjusted `LONG`.
- 2026-03-14T00:00:00+02:00 Integrated summary written with explicit statements
  that `WIDE` remains null before and after FI22, the `LONG` baseline
  `FOF_status` effect attenuates after FI22 adjustment, no `time * FOF_status`
  interaction appears in any model, and missingness plus population
  differences remain part of the final review caveat.
- 2026-03-14T00:00:00+02:00 No new models were run. `R-scripts/K50/K50.r`
  remained unchanged, `Composite_Z` remained verification-only, and
  `FI22_nonperformance_KAAOS` remained sensitivity-only.
- 2026-03-14T00:00:00+02:00 Independent methodological review and z-score
  composite advisory assessment both supported the current K50 interpretation:
  implementation fidelity, model specification fidelity, interpretation
  fidelity, and pipeline governance were all judged strong, while the remaining
  substantive caveats were limited to missingness bias risk, interaction power,
  and ordinary latent-score measurement uncertainty rather than pipeline error.
