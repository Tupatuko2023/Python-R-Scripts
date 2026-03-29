# K50 FIG2 adjusted marginal means trajectory

## Context

K50 figure audit found no rendered primary locomotor-capacity trajectory figure,
but the locked LONG model and manuscript narrative already support the target
visual: lower overall level in the FOF group with no detectable
`time * FOF_status` interaction.

## Inputs

- `R-scripts/K50/outputs/k50_long_locomotor_capacity_model_terms_primary.csv`
- canonical locked LONG K50 input or reconstructed prediction support from
  existing K50-ready outputs only
- `README.md` optional interaction-plot guidance
- `tasks/03-review/K50_write_manuscript_results_from_locked_pipeline.md`
- `manifest/manifest.csv`

## Outputs

- New figure helper script under `R-scripts/K50/`
- `R-scripts/K50/outputs/K50_FIG2_trajectory/` containing:
  - adjusted marginal means trajectory figure (`.png` and/or `.pdf`)
  - prediction table used for plotting
  - provenance note
  - session info
- One manifest row per new artifact

## Definition of Done (DoD)

- Figure uses the locked LONG model estimand and does not rerun or alter K50
  core analysis logic.
- Visual shows time on x-axis and adjusted locomotor-capacity level on y-axis
  by baseline `FOF_status`.
- Output contract and manifest discipline follow K50 conventions.
- Smoke run command is documented and reproducible from `Fear-of-Falling/`.

## Log

- 2026-03-20 00:24:00 created from accepted K50 figure audit as production task
  for Figure 2.
- 2026-03-20 08:06:19 rendered trajectory figure to
  `R-scripts/K50/outputs/FIG2_trajectory/k50_fig2_trajectory.png` from the
  locked LONG term table and canonical K50 LONG input; appended one manifest
  row for the figure.
- 2026-03-20 09:19:11 editorial rerender cleaned the x-axis, removed the
  shaded ribbon, switched uncertainty display to pointwise error bars, and
  removed technical subtitle text; appended a new manifest row for the updated
  render.

## Review Summary

- New helper script: `R-scripts/K50/make_fig2_trajectory.R`
- Produced artifact:
  - `R-scripts/K50/outputs/FIG2_trajectory/k50_fig2_trajectory.png`
- Manifest:
  - two `figure_png` rows under script label `K50_FIG2_trajectory` (initial
    render + editorial rerender)
- Scope guard:
  - no K50 full pipeline rerun
  - no raw-data edit
  - figure reconstructed from locked fixed-effect term export plus canonical
    covariate means from existing K50 LONG input
- Editorial cleanup:
  - x-axis reduced to two labeled time points only
  - CI ribbon replaced with error bars
  - technical subtitle removed from the panel
- Residual caveat:
  - point estimates follow the locked LONG model directly, but 95% CI bands had
  to be reconstructed from exported term SEs because no stored `emmeans` or
    fixed-effect covariance artifact was available in repo outputs

## Blockers

- If stored model objects are unavailable, the helper must derive plotting data
  strictly from existing locked support tables or separately approved model
  reconstruction inputs.

## Links

- `tasks/03-review/K50_figure_inventory_audit.md`
- `R-scripts/K50/outputs/k50_figure_inventory_status.csv`
