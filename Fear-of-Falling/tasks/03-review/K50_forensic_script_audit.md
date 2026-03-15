# K50 forensic script audit

## Context

Primary confirmatory analysis, FI22-adjusted sensitivity analysis, and the
integrated review summary are complete at review level. An independent
methodological assessment judged the current K50 pipeline and interpretation
strongly aligned with the analysis plan, with no evidence of outcome-governance
or reporting drift.

The next useful non-modeling step is a forensic script audit before paper
writing. This is a code-and-contract validation task, not a new analysis run.

## Inputs

- `R-scripts/K50/K50.r`
- `tasks/03-review/K50_run_primary_analysis_from_canonical_export.md`
- `tasks/03-review/K50_run_sensitivity_fi22_and_missingness.md`
- `tasks/03-review/K50_write_integrated_results_summary.md`
- `docs/ANALYSIS_PLAN.md`

## Outputs

- one audit note confirming or challenging:
  - `WIDE` ANCOVA specification
  - `LONG` time coding
  - `FOF_status` reference coding
  - mixed-model formula fidelity
- review-ready findings list if any discrepancies are found

## Definition of Done (DoD)

- Audit explicitly verifies whether `WIDE` ANCOVA is coded as intended:
  `follow-up outcome ~ baseline outcome + FOF_status + age + sex + BMI`
  and optional `+ FI22_nonperformance_KAAOS` only in sensitivity mode.
- Audit explicitly verifies whether `LONG` time coding is locked to `{0, 12}`.
- Audit explicitly verifies whether `FOF_status` reference coding is correct
  (`0` reference vs `1` exposed group).
- Audit explicitly verifies whether the mixed-model formula matches the analysis
  plan, including `time * FOF_status` and `(1 | id)`.
- Audit keeps `Composite_Z` verification-only.
- Audit keeps `FI22_nonperformance_KAAOS` sensitivity-only.
- No new models are run.
- `R-scripts/K50/K50.r` remains unchanged unless a real coding defect is found
  and separately approved.

## Constraints

- Do not run new models by default.
- Do not modify `R-scripts/K50/K50.r` unless a genuine coding defect is proven.
- Do not introduce aliases.
- Do not relabel `Composite_Z` as `z3`.
- Do not move `FI22_nonperformance_KAAOS` into locomotor outcome construction.
- Do not touch unrelated queue items or the unrelated deletion outside this
  task.

## Canonical work order

1. Read `R-scripts/K50/K50.r`
2. Crosscheck formulas and coding rules against `docs/ANALYSIS_PLAN.md`
3. Confirm `WIDE` ANCOVA structure
4. Confirm `LONG` time coding and interaction structure
5. Confirm `FOF_status` reference coding
6. Write forensic audit note

## Links

- `R-scripts/K50/K50.r`
- `docs/ANALYSIS_PLAN.md`
- `tasks/03-review/K50_write_integrated_results_summary.md`

## Forensic Findings

Forensic code audit confirms the intended `WIDE` and `LONG` formulas relative
to `docs/ANALYSIS_PLAN.md`.

- `WIDE` ANCOVA is coded as:
  `locomotor_capacity_12m ~ locomotor_capacity_0 + FOF_status + age + sex + BMI`
  with optional `+ FI22_nonperformance_KAAOS` only when `--fi22 on`.
- `LONG` mixed model is coded as:
  `locomotor_capacity ~ time * FOF_status + age + sex + BMI + (1 | id)`
  with optional `+ FI22_nonperformance_KAAOS` only when `--fi22 on`.
- Canonical long-format time coding is enforced through `normalize_time()` and
  the QC gate `time_exact_levels_0_12`, which accepts only `{0,12}`.
- `FOF_status` reference coding is correct: `normalize_fof()` returns a factor
  with levels `c(0L, 1L)`, so `0` is the reference level and `1` is the
  exposed group.
- Baseline covariate usage is correct in `WIDE`: the baseline outcome enters
  only as `outcome_0`, and there is no undocumented delta substitution.
- `Composite_Z` remains verification-only behind
  `--allow-composite-z VERIFIED`.
- `FI22_nonperformance_KAAOS` remains sensitivity-only and is gated behind
  `--fi22 on`; it is not used in the primary default branch or locomotor
  outcome construction.

No genuine coding defect was identified in `R-scripts/K50/K50.r`.

## Log

- 2026-03-14T00:00:00+02:00 Task created from orchestrator prompt
  `16_3cafofv2.txt` and expert note `2_Z_Score_Composite_Advisor.txt`.
- 2026-03-14T00:00:00+02:00 Task added to `tasks/01-ready/` as the next
  pre-writing forensic code audit step. No new model run is requested in this
  task.
- 2026-03-14T00:00:00+02:00 Task moved to `tasks/02-in-progress/` for
  forensic code-contract audit against `docs/ANALYSIS_PLAN.md`. No new model
  run is part of this step.
- 2026-03-14T00:00:00+02:00 Forensic audit confirmed the intended `WIDE`
  ANCOVA formula, `LONG` mixed-model formula, canonical `{0,12}` time coding,
  `FOF_status` reference coding with `0` as reference, correct baseline
  covariate usage, and the governance gates that keep `Composite_Z`
  verification-only and `FI22_nonperformance_KAAOS` sensitivity-only.
- 2026-03-14T00:00:00+02:00 No genuine coding defect was found, so
  `R-scripts/K50/K50.r` remained unchanged.
