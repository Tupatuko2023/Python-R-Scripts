# K50 visualize FI22 FOF delta

## Context

The K50 analysis pipeline is locked through robustness confirmation. The next
step is a visualization-only stage using the canonical `WIDE` K50 input. This
step must not reopen model architecture or alter `R-scripts/K50/K50.r`.

## Inputs

- canonical `WIDE` input under `DATA_ROOT/paper_01/analysis/fof_analysis_k50_wide.rds`
- `tasks/03-review/K50_write_integrated_results_summary.md`
- `tasks/03-review/K50_robustness_check_influence_and_se.md`
- `manifest/manifest.csv`

## Outputs

- Figure A: faceted raw-data figure with
  `x = FI22_nonperformance_KAAOS`,
  `y = delta_locomotor_capacity`,
  `facet = FOF_status`
- Figure B: model-based predicted figure with 95% CI using
  `delta_locomotor_capacity ~ FOF_status * FI22_nonperformance_KAAOS + age + sex + BMI`
- one short note stating that the figures are descriptive / illustrative and do
  not replace the locked primary and sensitivity models

## Definition of Done (DoD)

- Canonical `WIDE` input is used.
- `delta_locomotor_capacity = locomotor_capacity_12m - locomotor_capacity_0`
  is used as the plotted change variable.
- Figure A and Figure B are written to `R-scripts/K50/outputs/`.
- The figures use the name `delta_locomotor_capacity`, not new aliases.
- Manifest rows are appended one per new artifact.
- `R-scripts/K50/K50.r` remains unchanged.
- `Composite_Z` remains verification-only.
- `FI22_nonperformance_KAAOS` remains sensitivity-only.
- Task moves to `tasks/03-review/` after the figures and note are written.

## Constraints

- Do not modify `R-scripts/K50/K50.r`.
- Do not run new primary or sensitivity models.
- Do not relabel `Composite_Z` as `z3`.
- Do not move `FI22_nonperformance_KAAOS` into locomotor outcome construction.
- Any 3D visualization is optional appendix-only and not part of the primary
  deliverable.

## Canonical work order

1. Read canonical `WIDE` input
2. Construct `delta_locomotor_capacity`
3. Produce faceted raw-data figure
4. Produce model-based predicted figure with 95% CI
5. Write a short visualization note
6. Append manifest rows and move task to review

## Log

- 2026-03-14T00:00:00+02:00 Task created from orchestrator prompt
  `25_3cafofv2.txt` and expert note `7_Z_Score_Composite_Advisor.txt`.
- 2026-03-14T00:00:00+02:00 Task moved to `tasks/02-in-progress/` for a
  visualization-only stage using canonical `WIDE` input. `K50.r` remained
  unchanged, `Composite_Z` remained verification-only, and
  `FI22_nonperformance_KAAOS` remained sensitivity-only.
- 2026-03-14T00:00:00+02:00 Canonical variables were confirmed in
  `fof_analysis_k50_wide.rds`: `FI22_nonperformance_KAAOS`, `FOF_status`,
  `locomotor_capacity_0`, and `locomotor_capacity_12m`. The plotted change
  variable was defined canonically as
  `delta_locomotor_capacity = locomotor_capacity_12m - locomotor_capacity_0`.
- 2026-03-14T00:00:00+02:00 `ggplot2` was not available in the current R
  runtime, so the figures were generated as publication-ready base-R PDF
  artifacts rather than PNG/ggplot outputs. This did not change the requested
  visual content or the locked analysis pipeline.
- 2026-03-14T00:00:00+02:00 Figure A and Figure B were written under
  `R-scripts/K50/outputs/` as
  `k50_visual_fi22_fof_delta_raw_facet.pdf` and
  `k50_visual_fi22_fof_delta_model_based.pdf`, accompanied by a short
  descriptive note and session info file. `manifest/manifest.csv` received one
  row per new artifact.
