# K50 S3 CFA loading plot

## Context

The K50 figure audit found upstream CFA loading summaries in K32 and K39, but
no rendered measurement-summary figure suitable for the K50 manuscript
supplement. This task is a pure visualization layer over existing loading
tables.

## Inputs

- `R-scripts/K32/outputs/k32_cfa_primary_loadings.csv`
- `R-scripts/K32/outputs/k32_cfa_primary_summary.txt`
- `R-scripts/K39/outputs/k39_cfa_primary_loadings.csv`
- `R-scripts/K39/outputs/k39_cfa_primary_summary.txt`
- `manifest/manifest.csv`

## Outputs

- New plotting helper under `R-scripts/K50/` or another narrowly scoped
  manuscript-support script location
- `R-scripts/K50/outputs/K50_S3_cfa/` containing:
  - CFA loading / measurement summary figure (`.png` and/or `.pdf`)
  - plotting table snapshot
  - provenance note
  - session info
- One manifest row per new artifact

## Definition of Done (DoD)

- Figure is built only from existing loading tables and summaries.
- No CFA model is rerun.
- The figure stays modest in scope: loading plot or minimalist path diagram,
  not a new psychometric analysis.
- All outputs follow standard output discipline and manifest logging.

## Log

- 2026-03-20 00:24:00 created from accepted K50 figure audit as production task
  for Supplement S3.
- 2026-03-20 19:44:20 rendered supplementary CFA loading summary from locked
  upstream loading artifacts and wrote artifacts under
  `R-scripts/K50/outputs/SFIG3_cfa_loadings/`.

## Blockers

- None currently.

## Review Summary

- New helper script:
  - `R-scripts/K50/make_sfig3_cfa_loadings.R`
- Produced artifacts:
  - `R-scripts/K50/outputs/SFIG3_cfa_loadings/k50_sfig3_cfa_loadings.png`
  - `R-scripts/K50/outputs/SFIG3_cfa_loadings/k50_sfig3_cfa_loadings_plot_data.csv`
  - `R-scripts/K50/outputs/SFIG3_cfa_loadings/provenance_note.txt`
  - `R-scripts/K50/outputs/SFIG3_cfa_loadings/sessionInfo.txt`
- Locked inputs used:
  - `k32_cfa_primary_loadings.csv`
  - `k32_cfa_primary_summary.txt`
  - `k39_cfa_primary_loadings.csv` was inspected as upstream context only
- Canonical source decision:
  - K32 was used as the plotted source because it contains the locomotor
    `Capacity =~ gait + chair + balance` factor
  - K39 was not plotted because it describes a different latent construct and
    would have confused the supplement figure
- Scope guard:
  - no CFA rerun
  - no global fit claims were added for the just-identified three-indicator CFA
- Residual caveat:
  - factor determinacy was not plotted because no locked determinacy artifact
    was available in the inspected upstream outputs

## Links

- `tasks/03-review/K50_figure_inventory_audit.md`
- `R-scripts/K50/outputs/k50_figure_inventory_status.csv`
