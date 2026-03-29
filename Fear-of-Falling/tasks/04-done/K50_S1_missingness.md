# K50 S1 missingness plot

## Context

The K50 figure audit found that missingness support already exists as aggregate
tables, but no manuscript-facing figure has been rendered. This task converts
existing `missingness_group_time` outputs into a supplementary plot without
rerunning K50.

## Inputs

- `R-scripts/K50/outputs/k50_long_locomotor_capacity_missingness_group_time.csv`
- `R-scripts/K50/outputs/k50_wide_locomotor_capacity_missingness_group_time.csv`
- `R-scripts/K50/outputs/k50_long_locomotor_capacity_cohort_flow_missingness_group_time.csv`
- `tasks/03-review/K50_run_sensitivity_fi22_and_missingness.md`
- `manifest/manifest.csv`

## Outputs

- New plotting helper under `R-scripts/K50/`
- `R-scripts/K50/outputs/K50_S1_missingness/` containing:
  - missingness figure (`.png` and/or `.pdf`)
  - plotting data snapshot if transformed
  - provenance note
  - session info
- One manifest row per new artifact

## Definition of Done (DoD)

- Figure is built only from existing aggregate missingness tables.
- No raw data and no locked model outputs are modified.
- Manuscript-facing grouping by FOF group and time is explicit.
- All artifacts land under `R-scripts/K50/outputs/K50_S1_missingness/`.

## Log

- 2026-03-20 00:24:00 created from accepted K50 figure audit as production task
  for Supplement S1.
- 2026-03-20 19:44:05 rendered supplementary missingness figure from locked
  WIDE and LONG group-time missingness tables and wrote artifacts under
  `R-scripts/K50/outputs/SFIG1_missingness/`.

## Blockers

- None currently.

## Review Summary

- New helper script:
  - `R-scripts/K50/make_sfig1_missingness.R`
- Produced artifacts:
  - `R-scripts/K50/outputs/SFIG1_missingness/k50_sfig1_missingness.png`
  - `R-scripts/K50/outputs/SFIG1_missingness/k50_sfig1_missingness_plot_data.csv`
  - `R-scripts/K50/outputs/SFIG1_missingness/provenance_note.txt`
  - `R-scripts/K50/outputs/SFIG1_missingness/sessionInfo.txt`
- Locked inputs used:
  - `k50_wide_locomotor_capacity_missingness_group_time.csv`
  - `k50_long_locomotor_capacity_missingness_group_time.csv`
- Decision taken:
  - proportions were used because explicit denominators `n` were present in the
    locked missingness tables
  - WIDE and LONG were shown as separate panels rather than pooled
  - rows with missing baseline `FOF_status` were excluded from the displayed
    supplement figure
- Scope guard:
  - no raw data edit
  - no model adjustment
  - no K50 full pipeline rerun
- Residual caveat:
  - this is a descriptive missingness figure only and does not imply a formal
    missing-data model

## Links

- `tasks/03-review/K50_figure_inventory_audit.md`
- `R-scripts/K50/outputs/k50_figure_inventory_status.csv`
