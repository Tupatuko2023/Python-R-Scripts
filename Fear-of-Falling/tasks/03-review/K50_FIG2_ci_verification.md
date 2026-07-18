# K50 FIG2 CI verification

## Status

03-review

## Context

The current FIG2 manuscript-facing trajectory is accepted at the point-estimate
layer, but its uncertainty layer uses approximate 95% confidence intervals
reconstructed from exported fixed-effect standard errors. Before manuscript
submission, the preferred next step is a narrow verification pass to determine
whether exact pointwise CI can be derived from existing locked artifacts
without refitting the LONG model.

## Inputs

- `R-scripts/K50/outputs/FIG2_trajectory/k50_fig2_trajectory.png`
- `R-scripts/K50/outputs/k50_long_locomotor_capacity_model_terms_primary.csv`
- any locked saved model object, covariance matrix, emmeans grid, prediction
  grid, or other CI-supporting artifact already present under repo outputs
- `tasks/03-review/K50_FIG2_trajectory.md`
- `manifest/manifest.csv`

## Outputs

- Verification note under `R-scripts/K50/outputs/` or `tasks/03-review/`
  documenting whether exact CI support exists
- If and only if locked support exists without refit:
  - comparison artifact for approximate CI versus emmeans/vcov-based CI
  - recommendation on whether FIG2 should be rerendered
- One manifest row per genuinely new verification artifact

## Definition of Done (DoD)

- The task searches only for existing locked support artifacts and does not
  rerun the K50 full pipeline.
- Go gate:
  - proceed with emmeans/vcov-based CI verification only if a locked model
    object, stored vcov, saved emmeans grid, or equivalent CI-support artifact
    is available without raw-data scope creep or model refit
- No-go gate:
  - if exact CI would require reconstructing or refitting the LONG model from
    raw data or otherwise expanding scope, stop and keep the current FIG2
    render unchanged
- The task states clearly that the current FIG2 point-estimate layer is
  accepted, the current uncertainty layer is approximate, and emmeans/vcov
  verification is nice but not mandatory before submission
- If verification cannot be completed, the outcome explicitly instructs the
  manuscript caption to retain a caveat that approximate 95% CI were derived
  from exported fixed-effect standard errors

## Evidence

- Active plan: `docs/ANALYSIS_PLAN.md` defines the current K50 stage and
  `locomotor_capacity` as the primary outcome; `z3` is fallback/sensitivity and
  `Composite_Z` is legacy bridge only.
- Producer scripts:
  - `R-scripts/K50/K50.V2_make-fig2-trajectory-exact.R`
  - `R-scripts/K50/K50.V3_make-fig2-contrast-focused.R`
- Locked support artifacts:
  - `R-scripts/K50/outputs/k50_long_locomotor_capacity_model_primary.rds`
  - `R-scripts/K50/outputs/k50_long_locomotor_capacity_model_frame_primary.rds`
  - `R-scripts/K50/outputs/FIG2_contrast_focused/k50_fig2_emmeans_panelA.csv`
  - `R-scripts/K50/outputs/FIG2_contrast_focused/k50_fig2_contrasts_panelB.csv`
- CI method from code: `emmeans::emmeans()` on the saved primary LONG `merMod`
  fit, followed by `summary(..., infer = c(TRUE, TRUE))` for adjusted means and
  `contrast(...); summary(..., infer = c(TRUE, TRUE))` for direct contrasts.
- Figure mapping from code: Panel A uses `estimate`, `conf.low`, and
  `conf.high` directly in `geom_line`, `geom_point`, and `geom_errorbar`.
  Panel B uses the same columns directly in `geom_point` and `geom_errorbarh`.

## Validation

- Created QC artifact:
  `R-scripts/K50/outputs/FIG2_CI_verification/k50_fig2_ci_verification_table.csv`.
- Added exactly one manifest row for the new QC artifact under script
  `K50_FIG2_CI_verification`.
- The verification table has 7 data rows: 4 Panel A adjusted means and 3 Panel B
  contrasts.
- Validation command confirmed:
  - every row has 13 CSV fields;
  - 7 rows end in `PASS`;
  - every row satisfies `lower CI <= estimate <= upper CI`;
  - figure lower/estimate/upper values equal source table values exactly;
  - maximum absolute difference is `0` for every row.
- No K50 producer script, model specification, outcome architecture, raw data,
  `docs/ANALYSIS_PLAN.md`, or `renv.lock` was changed.
- No model rerun was performed; sessionInfo and renv diagnostics were not
  regenerated because the verification used existing locked artifacts only.

## Table-to-text Crosscheck

The generated Results text artifact matches Panel B exactly after rounding:

- Baseline FOF minus No FOF contrast: estimate `-0.091`, 95% CI `-0.174` to
  `-0.008`, p = `0.0323`.
- 12-month FOF minus No FOF contrast: estimate `-0.071`, 95% CI `-0.169` to
  `0.027`, p = `0.1538`.
- Difference-in-change contrast: estimate `0.020`, 95% CI `-0.067` to `0.107`,
  p = `0.6561`.

The caption correctly separates Panel A group-specific estimated marginal mean
CIs from Panel B model-based between-group contrasts, and names
`locomotor_capacity` with the saved primary LONG model formula.

## Agent Report

Exact CI support exists in locked K50 artifacts. The current contrast-focused
Figure 2 CI layer is supported by saved-model emmeans/vcov calculations rather
than reconstructed fixed-effect-SE approximations. The primary Figure 2 PNG/PDF
and compact variants can remain unchanged; no rerender is required for this
verification task.

## Log

- 2026-03-20 12:50:16 created as a standalone go/no-go verification task after
  FIG1 editorial cleanup; no FIG2 render or model object was changed in this
  setup step.
- 2026-07-18T20:43:00+0300 Agent started K50 Figure 2 CI verification after
  confirming alignment with the active K50 analysis plan.
- 2026-07-18T21:05:56+0300 Created read-only CI verification table from locked
  K50 Figure 2 V3 outputs and appended exactly one manifest row for the new QC
  artifact.
- 2026-07-18T21:12:00+0300 Completed table-to-figure and table-to-text
  crosschecks; all 7 CI rows passed and the task was moved to `tasks/03-review/`.

## Blockers

None.

## Links

- `tasks/03-review/K50_FIG2_trajectory.md`
- `tasks/03-review/K50_figure_inventory_audit.md`
