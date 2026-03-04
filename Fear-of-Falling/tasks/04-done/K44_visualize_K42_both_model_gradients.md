# K44 Visualize K42 Both-Model Gradients

## Context

This K44 is an analysis-repo visualization task in `Fear-of-Falling`.
It is not a dissertation-repo writing task.

K42 established head-to-head longitudinal models for capacity and frailty index (FI).
K44 adds deterministic, governance-safe figures from K42 BOTH-model fixed effects without refitting models.

Task-gate status: review (`tasks/03-review/`).

## Objective

Produce publication-ready trajectory visualizations from K42 BOTH-model fixed effects:
- Main figure: 2-panel gradient plot (capacity gradient and FI gradient).
- Supplementary figure: 4 extreme model-based reference profiles.

## Scope

In scope:
- Create `R-scripts/K44/k44.r`.
- Create `scripts/termux/run_k44_proot.sh`.
- Create K44 aggregate outputs under `R-scripts/K44/outputs/`.
- Append K44 rows to `manifest/manifest.csv`.

Out of scope:
- No model refitting.
- No changes to K42 model specification.
- No patient-level exports to repository.

## Inputs

Required repository inputs:
- `R-scripts/K42/outputs/k42_lmm_both_coefficients.csv`
- `R-scripts/K42/outputs/k42_capacity_fi_collinearity.csv`
- `R-scripts/K42/outputs/k42_common_sample_counts.csv`

Optional repository input:
- `R-scripts/K42/outputs/k42_lmm_model_comparison.csv`

Optional DATA_ROOT inputs (summary-stat fallback only):
- canonical K33 analysis data
- K32 capacity data
- K40 FI data

## Modeling Rules

- Do not refit the LMM.
- Build predictions from K42 BOTH-model fixed effects only (`effect == "fixed"`).
- Set random intercept contribution to `0`.
- Predict at time `{0, 12}`.
- Stop with informative error if required terms are missing, including:
  - `time:capacity_score_latent_primary`
  - `time:frailty_index_fi_k40_z`

## Figure Outputs

Main figure:
- `R-scripts/K44/outputs/k44_both_gradients.png`
- Panel A: capacity at `{-1 SD, mean, +1 SD}`, FI fixed at mean.
- Panel B: FI at `{-1 SD, mean, +1 SD}`, capacity fixed at mean.

Supplementary figure:
- `R-scripts/K44/outputs/k44_extreme_profiles.png`
- Profiles:
  - cap -1 SD, FI -1 SD
  - cap -1 SD, FI +1 SD
  - cap +1 SD, FI -1 SD
  - cap +1 SD, FI +1 SD

Optional (if input exists):
- `R-scripts/K44/outputs/k44_model_comparison.png`

## Governance

- Repository writes are aggregate-only artifacts, logs, captions, and receipts.
- No patient-level CSV/RDS written to repository.
- If DATA_ROOT is read, only external input receipt is written in repo.

## Required Text/Logs

- `R-scripts/K44/outputs/k44_figure_caption.txt`
- `R-scripts/K44/outputs/k44_decision_log.txt`
- `R-scripts/K44/outputs/k44_sessioninfo.txt`
- `R-scripts/K44/outputs/k44_external_input_receipt.txt` (if DATA_ROOT inputs used)

## Reproduction Commands

`[TERMUX]`

```sh
cd Python-R-Scripts/Fear-of-Falling
bash scripts/termux/run_k44_proot.sh
bash scripts/termux/run_qc_summarizer_proot.sh
bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling
```

## Acceptance Criteria

- `bash scripts/termux/run_k44_proot.sh` exits `0`.
- Main and supplementary figures are produced at documented paths.
- Caption/log/sessioninfo written.
- Manifest contains appended K44 rows for new artifacts.
- No patient-level exports in repository outputs.
- `bash scripts/termux/run_qc_summarizer_proot.sh` exits `0`.
- `bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling` exits `0`.

## Definition of Done

- K44 outputs exist and pass validation checks.
- Task moved to `tasks/03-review/` with command/evidence log.

## Log

- 2026-03-03 18:20 created K44 backlog card.
- 2026-03-03 18:21 moved card `00-backlog -> 01-ready -> 02-in-progress`.
- 2026-03-03 18:39 implemented:
  - `R-scripts/K44/k44.r`
  - `scripts/termux/run_k44_proot.sh`
- 2026-03-03 18:41 executed:
  - `bash scripts/termux/run_k44_proot.sh` (exit `0`)
  - produced:
    - `R-scripts/K44/outputs/k44_both_gradients.png`
    - `R-scripts/K44/outputs/k44_extreme_profiles.png`
    - `R-scripts/K44/outputs/k44_figure_caption.txt`
    - `R-scripts/K44/outputs/k44_decision_log.txt`
    - `R-scripts/K44/outputs/k44_external_input_receipt.txt`
    - `R-scripts/K44/outputs/k44_sessioninfo.txt`
  - manifest rows appended for all K44 artifacts.
- 2026-03-03 18:41 validation:
  - `bash scripts/termux/run_qc_summarizer_proot.sh` (exit `0`)
  - `bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling` (exit `0`)
  - leak-check on K44 outputs: no patient-level CSV/RDS created in repo.
- 2026-03-03 18:42 moved task card to `tasks/03-review/` for human approval.

## Blockers

- None.
