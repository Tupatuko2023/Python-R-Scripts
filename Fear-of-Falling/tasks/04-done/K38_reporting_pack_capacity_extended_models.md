# K38 Reporting Pack Capacity Extended Models

## Context

K36 established the extended analysis layer that adds baseline capacity_score_latent_primary terms while preserving canonical primary models.
K37 provided aggregate visualization outputs for interpretation.
K38 compiles manuscript-ready reporting artifacts in English without refitting models.

## Inputs

- `R-scripts/K36/outputs/k36_lmm_primary_fixed_effects.csv`
- `R-scripts/K36/outputs/k36_lmm_extended_fixed_effects.csv`
- `R-scripts/K36/outputs/k36_lmm_model_comparison.csv`
- `R-scripts/K36/outputs/k36_ancova_primary_coefficients.csv`
- `R-scripts/K36/outputs/k36_ancova_extended_coefficients.csv`
- `R-scripts/K36/outputs/k36_ancova_model_comparison.csv`
- `R-scripts/K37/outputs/k37_figure_caption.txt`

## Outputs

- `R-scripts/K38/outputs/k38_table_primary_vs_extended.csv`
- `R-scripts/K38/outputs/k38_results_snippet.txt`
- `R-scripts/K38/outputs/k38_methods_snippet.txt`
- `R-scripts/K38/outputs/k38_discussion_snippet.txt`
- `R-scripts/K38/outputs/k38_figure_callouts.txt`
- `R-scripts/K38/outputs/k38_sessioninfo.txt`

## Definition of Done (DoD)

- Aggregate-only reporting outputs are generated from existing K36/K37 artifacts.
- English snippets are neutral and non-causal.
- Primary vs extended term separation is explicit in the K38 table.
- No patient-level CSV/RDS outputs are created in repo outputs.
- QC summarizer PASS and analysis gates PASS.
- Task moved to `tasks/03-review/`.

## Log

- 2026-03-01 20:07: Task created and moved `00-backlog -> 01-ready -> 02-in-progress`.
- 2026-03-01 20:07: Implemented `R-scripts/K38/k38.r`.
- 2026-03-01 20:08: Ran K38 via proot with in-call `.env` sourcing:
  - `proot-distro login debian --termux-home -- bash -lc '... && /usr/bin/Rscript R-scripts/K38/k38.r'` -> PASS.
- 2026-03-01 20:08: Generated all K38 outputs in `R-scripts/K38/outputs/`.
- 2026-03-01 20:08: Appended manifest rows for K38 artifacts (table + snippets + sessioninfo).
- 2026-03-01 20:09: Validation:
  - `bash scripts/termux/run_qc_summarizer_proot.sh` -> PASS.
  - `bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling` -> PASS.
- 2026-03-01 20:09: Leak-check (`with_capacity_scores*`, `analysis*`) in repo outputs -> empty / PASS.

## Blockers

- None.

## Links

- `R-scripts/K38/k38.r`
- `R-scripts/K36/outputs/`
- `R-scripts/K37/outputs/`
