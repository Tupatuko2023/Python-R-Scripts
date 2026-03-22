# K50 FIG1 analytic sample flow

## Context

K50 figure audit concluded that the manuscript target "analytic sample
derivation / participant flow for WIDE vs LONG" is only partially supported.
The repo already contains a rendered LONG cohort-flow diagram plus helper
counts/placeholders, but no single publication-facing figure that shows both
WIDE and LONG branches together.

## Inputs

- `R-scripts/K50/outputs/k50_long_locomotor_capacity_cohort_flow_counts.csv`
- `R-scripts/K50/outputs/k50_long_locomotor_capacity_cohort_flow_placeholders.csv`
- `diagram/paper_01_cohort_flow.long.locomotor_capacity.png`
- `diagram/paper_01_cohort_flow.long.locomotor_capacity.svg`
- K50 WIDE branch counts from existing K50 aggregate outputs and/or a helper
  generated strictly from already locked K50 artifacts
- `manifest/manifest.csv`

## Outputs

- New figure script under `R-scripts/K50/` for combined branch flow production
- `R-scripts/K50/outputs/K50_FIG1_flow/` containing:
  - combined flow figure (`.png` and/or `.svg` or `.pdf`)
  - provenance note / receipt
  - session info
- One manifest row per new artifact

## Definition of Done (DoD)

- Combined WIDE+LONG flow figure is generated without rerunning K50 primary
  models.
- Existing LONG cohort-flow evidence is reused rather than recomputed from raw
  data.
- The figure makes branch non-identity explicit and remains aggregate-only.
- All artifacts are written under `R-scripts/K50/outputs/K50_FIG1_flow/`.
- `manifest/manifest.csv` gets one row per artifact.
- A single smoke run command is documented in the task log.

## Log

- 2026-03-20 00:24:00 created from accepted K50 figure audit as production task
  for Figure 1.
- 2026-03-20 08:06:03 rendered combined flow figure to
  `R-scripts/K50/outputs/FIG1_flow/k50_fig1_flow.png` using existing LONG
  cohort-flow counts plus locked WIDE/LONG receipt artifacts; appended one
  manifest row for the figure.
- 2026-03-20 09:18:36 editorial rerender removed pipeline-facing wording and
  simplified the WIDE/LONG labels for manuscript use; appended a new manifest
  row for the updated render.
- 2026-03-20 10:23:49 editorial rerender added explicit line breaks to the
  source cohort box and bottom explanatory note, with a small layout-space
  adjustment to prevent cutoff; figure content and counts were unchanged and a
  new manifest row was appended.
- 2026-03-20 12:50:16 editorial rerender removed the bottom note entirely for
  the manuscript-facing panel; branch structure, box text, and counts were
  unchanged and a new manifest row was appended.

## Review Summary

- New helper script: `R-scripts/K50/make_fig1_flow.R`
- Produced artifact:
  - `R-scripts/K50/outputs/FIG1_flow/k50_fig1_flow.png`
- Manifest:
  - five `figure_png` rows under script label `K50_FIG1_flow` (initial render
    + editorial rerender + typography/layout rerender history + bottom-note
    removal rerender)
- Scope guard:
  - no K50 model rerun
  - no raw-data edit
  - figure built from existing aggregate receipts/counts only
- Editorial cleanup:
  - subtitle removed
  - WIDE/LONG labels rewritten in publication-facing language
  - helper/pipeline wording removed from panel text
  - explicit line breaks added to avoid top-box and footnote text clipping
  - bottom note removed entirely so the distinction can live in manuscript
    caption text instead of the panel
- Residual caveat:
  - the figure explicitly distinguishes LONG participant-level helper count
    (`n=230`) from LONG mixed-model row count (`n=630`) for transparency

## Blockers

- WIDE branch flow counts may need to be reconstructed from existing locked K50
  artifacts if no direct rendered counterpart already exists.

## Links

- `tasks/03-review/K50_figure_inventory_audit.md`
- `R-scripts/K50/outputs/k50_figure_inventory_audit.md`
