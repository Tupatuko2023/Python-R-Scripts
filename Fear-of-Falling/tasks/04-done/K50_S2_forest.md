# K50 S2 sensitivity forest plot

## Context

The K50 figure audit confirmed that all numeric ingredients for a sensitivity
summary figure already exist, including primary, z3 fallback, FI22 sensitivity,
and standardized helper tables. What is missing is only the rendered
manuscript-facing forest/effect figure.

## Inputs

- `R-scripts/K50/outputs/k50_wide_locomotor_capacity_model_terms_primary.csv`
- `R-scripts/K50/outputs/k50_long_locomotor_capacity_model_terms_primary.csv`
- `R-scripts/K50/outputs/k50_wide_z3_model_terms_fallback.csv`
- `R-scripts/K50/outputs/k50_long_z3_model_terms_fallback.csv`
- `R-scripts/K50/outputs/k50_wide_locomotor_capacity_model_terms_fi22.csv`
- `R-scripts/K50/outputs/k50_long_locomotor_capacity_model_terms_fi22.csv`
- `R-scripts/K50/outputs/k50_wide_standardized_effects.csv`
- `R-scripts/K50/outputs/k50_long_standardized_effects.csv`
- `manifest/manifest.csv`

## Outputs

- New forest-plot helper under `R-scripts/K50/`
- `R-scripts/K50/outputs/K50_S2_forest/` containing:
  - sensitivity forest/effect figure (`.png` and/or `.pdf`)
  - combined plotting table
  - provenance note
  - session info
- One manifest row per new artifact

## Definition of Done (DoD)

- Figure is built from existing K50 term/effect tables only.
- WIDE and LONG remain visually separated as distinct estimands.
- Primary, z3, and FI22 branches are labeled explicitly.
- No K50 model rerun occurs.
- Artifacts follow K50 output and manifest conventions.

## Log

- 2026-03-20 00:24:00 created from accepted K50 figure audit as production task
  for Supplement S2.
- 2026-03-20 19:43:49 rendered supplementary forest plot from locked K50 term
  exports only and wrote artifacts under
  `R-scripts/K50/outputs/SFIG2_sensitivity_forest/`.

## Blockers

- None currently.

## Review Summary

- New helper script:
  - `R-scripts/K50/make_sfig2_sensitivity_forest.R`
- Produced artifacts:
  - `R-scripts/K50/outputs/SFIG2_sensitivity_forest/k50_sfig2_sensitivity_forest.png`
  - `R-scripts/K50/outputs/SFIG2_sensitivity_forest/k50_sfig2_sensitivity_forest_plot_data.csv`
  - `R-scripts/K50/outputs/SFIG2_sensitivity_forest/provenance_note.txt`
  - `R-scripts/K50/outputs/SFIG2_sensitivity_forest/sessionInfo.txt`
- Locked inputs used:
  - `k50_wide_locomotor_capacity_model_terms_primary.csv`
  - `k50_long_locomotor_capacity_model_terms_primary.csv`
  - `k50_wide_z3_model_terms_fallback.csv`
  - `k50_long_z3_model_terms_fallback.csv`
  - `k50_wide_locomotor_capacity_model_terms_fi22.csv`
  - `k50_long_locomotor_capacity_model_terms_fi22.csv`
- Scope guard:
  - only `FOF_status1` and `time:FOF_status1` terms were plotted
  - no age sex BMI or FI_22 coefficient rows were included
  - no WIDE interaction rows were fabricated
  - no K50 full pipeline rerun occurred
- Residual caveat:
  - WIDE and LONG rows summarize related but non-identical estimands and must
    stay grouped explicitly in downstream manuscript assembly

## Links

- `tasks/03-review/K50_figure_inventory_audit.md`
- `tasks/03-review/K50_standardized_effect_sizes_and_interaction_power.md`
