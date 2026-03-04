# K37 Visualize K36 Capacity Effects

## Context
K36 added K32 latent capacity into the canonical K26-path as an extended model layer.
This task creates manuscript-ready, aggregate-only visualizations for interpretation without changing model specifications.

## Inputs
- `R-scripts/K36/outputs/k36_lmm_extended_fixed_effects.csv`
- `R-scripts/K36/outputs/k36_lmm_model_comparison.csv`
- `R-scripts/K36/outputs/k36_ancova_model_comparison.csv`
- `${DATA_ROOT}/paper_01/analysis/fof_analysis_k33_long.rds`
- `${DATA_ROOT}/paper_01/analysis/fof_analysis_k33_wide.rds`
- `${DATA_ROOT}/paper_01/capacity_scores/kaatumisenpelko_with_capacity_scores_k32.rds`

## Outputs
- `R-scripts/K37/outputs/k37_predicted_trajectories.png`
- `R-scripts/K37/outputs/k37_model_comparison.png`
- `R-scripts/K37/outputs/k37_capacity_vs_baseline.png`
- `R-scripts/K37/outputs/k37_figure_caption.txt`
- `R-scripts/K37/outputs/k37_sessioninfo.txt`

## Definition of Done (DoD)
- Three PNG figures are generated and manuscript-readable (`theme_classic`, labeled axes, legend).
- Figure captions are written in neutral interpretation language.
- No patient-level CSV/RDS outputs are written into repo outputs.
- `run_qc_summarizer_proot.sh` PASS.
- `run-gates.sh --mode analysis --project Fear-of-Falling` PASS.
- Task moved to `tasks/03-review/`.

## Log
- 2026-03-01 19:25: Created task file and moved through gate: `00-backlog -> 01-ready -> 02-in-progress`.
- 2026-03-01 19:28: Implemented `R-scripts/K37/k37.r`.
- 2026-03-01 19:29: Ran K37 in proot with in-call `.env` sourcing:
  - `proot-distro login debian --termux-home -- bash -lc '... && /usr/bin/Rscript R-scripts/K37/k37.r'` -> PASS (exit 0).
- 2026-03-01 19:29: Generated outputs under `R-scripts/K37/outputs/`:
  - `k37_predicted_trajectories.png`
  - `k37_model_comparison.png`
  - `k37_capacity_vs_baseline.png`
  - `k37_figure_caption.txt`
  - `k37_sessioninfo.txt`
- 2026-03-01 19:30: Validation pipeline:
  - `bash scripts/termux/run_qc_summarizer_proot.sh` -> PASS
  - `bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling` -> PASS
- 2026-03-01 19:30: Leak-check (`analysis*.csv`, `capacity_scores*.csv`, `with_capacity_scores*.rds` under repo outputs) -> empty / PASS.

## Blockers
- None.

## Links
- `R-scripts/K37/k37.r`
- `R-scripts/K36/outputs/k36_lmm_extended_fixed_effects.csv`
- `R-scripts/K36/outputs/k36_lmm_model_comparison.csv`
- `R-scripts/K36/outputs/k36_ancova_model_comparison.csv`
