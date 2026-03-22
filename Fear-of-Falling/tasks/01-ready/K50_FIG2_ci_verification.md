# K50 FIG2 CI verification

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

## Log

- 2026-03-20 12:50:16 created as a standalone go/no-go verification task after
  FIG1 editorial cleanup; no FIG2 render or model object was changed in this
  setup step.

## Blockers

- Verification must not cross into raw-data model refitting or other scope
  expansion just to obtain exact CI.

## Links

- `tasks/03-review/K50_FIG2_trajectory.md`
- `tasks/03-review/K50_figure_inventory_audit.md`
