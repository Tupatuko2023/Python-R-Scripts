# K26_VIS composite delta predicted plots

## Context
Create reviewer-facing K26 visualizations from canonical K26/K15 artifacts without changing analysis logic.

## Objective
Generate deterministic predicted `Delta_Composite_Z` figures from K26 moderation models (cat + score sensitivity), write provenance/QC artifacts, and append manifest rows.

## Inputs
- `R-scripts/K26/outputs/K26/K26_LMM_MOD/K26_model_moderation_cat.rds`
- `R-scripts/K26/outputs/K26/K26_LMM_MOD/K26_model_moderation_score.rds` (optional score figure)
- `R-scripts/K15/outputs/K15_frailty_analysis_data.RData`

## Outputs
- `R-scripts/K26/outputs/K26_VIS/figures/K26_VIS_predicted_delta_by_frailtycat_x_fof.{png,pdf}`
- `R-scripts/K26/outputs/K26_VIS/figures/K26_VIS_moderation_delta_vs_baseline_by_frailtycat.{png,pdf}`
- `R-scripts/K26/outputs/K26_VIS/figures/K26_VIS_predicted_delta_by_frailtyscore_x_fof.{png,pdf}` (if score model available)
- `R-scripts/K26/outputs/K26_VIS/K26_VIS_provenance.txt`
- `R-scripts/K26/outputs/K26_VIS/qc_summary.csv`
- `R-scripts/K26/outputs/K26_VIS/sessionInfo.txt`
- Manifest rows in `manifest/manifest.csv`

## DoD
- New script `R-scripts/K26/K26_VIS.V1_composite-delta-predicted-plots.R` runs with one command.
- At least two reviewer figures generated (frailty_cat × FOF and moderation vs baseline).
- Provenance and QC artifacts generated and manifest-logged with unique keys.
- README and K26 review task updated with run command and artifact summary.
- Task remains in `03-review` (human approval required for `04-done`).

## Run command
```bash
Rscript R-scripts/K26/K26_VIS.V1_composite-delta-predicted-plots.R --format=both
```
