# Figure 1 Diagram Handoff

## Purpose and Ownership

`diagram/` contains the current publication-facing Figure 1 asset family for
Paper 01 Fear of Falling. The analysis repository owns the K50 producer, numeric
provenance, editable DOT, resolved DOT, and Graphviz renders. The dissertation
repository owns manuscript integration, title and legend text, and downstream
consistency audits.

The canonical handoff is the submodule commit of this repository as consumed by
`FOF-Dissertation-Project`. Downstream consumers must use the submodule asset
path:

`analysis/modules/Python-R-Scripts/Fear-of-Falling/diagram/`

Do not maintain hand-edited parallel copies of Figure 1 assets in the
dissertation repository.

## Current Canonical Family

| Asset | Role | Producer | Usage |
| --- | --- | --- | --- |
| `diagram/paper_01_cohort_flow.wide_long.locomotor_capacity.dot` | Editable DOT source | `R-scripts/K50/K50.FIG1_VISUAL_DUAL_BRANCH.V1_render.R` | Source of record for graph structure |
| `diagram/paper_01_cohort_flow.wide_long.locomotor_capacity.resolved.dot` | Generated resolved DOT | K50 producer | Render input with current labels and counts |
| `diagram/paper_01_cohort_flow.wide_long.locomotor_capacity.pdf` | Primary publication asset | Graphviz render from resolved DOT | Preferred manuscript and publication figure |
| `diagram/paper_01_cohort_flow.wide_long.locomotor_capacity.svg` | Review/interchange vector | Graphviz render from resolved DOT | Review, interchange, and vector inspection |
| `diagram/paper_01_cohort_flow.wide_long.locomotor_capacity.png` | Quarto/report fallback | Graphviz render from resolved DOT | Raster fallback for Quarto and reports |

No other Figure 1 families are current in `diagram/` root. Historical generic,
LONG-only, and WIDE-only assets are archived under `diagram/legacy/`.

## Downstream Contract

The active downstream manuscript consumer is:

`papers/A1_fear-of-falling-physical-performance/manuscript/draft/Results_Draft_version_2.qmd`

The dissertation-side audit paths for this handoff are:

`docs/audit/k50_figure1_figure_abstract_methods_results_supplement_crosscheck.md`

`docs/audit/k50_figure1_manuscript_count_audit.md`

The audit date is 2026-07-20. The audited state was a bounded PASS for the
figure, abstract, methods, results, and supplement crosscheck. This README
records the handoff contract only; do not copy full audit reports into this
analysis repository.

## Format Roles

DOT files are the editable source format. Resolved DOT files are generated
render inputs and should not be manually edited. PDF is the primary publication
asset. SVG is for review and interchange. PNG is a Quarto/report fallback.

All paths in this README are repository-relative. Do not add local absolute
paths.
