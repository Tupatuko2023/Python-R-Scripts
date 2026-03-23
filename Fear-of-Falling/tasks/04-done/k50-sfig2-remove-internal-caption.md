# K50 SFIG2 remove internal caption

## Context

The SFIG2 image should no longer contain an internal caption/title because the
manuscript provides the official figure caption separately. This task removes
only the plot-internal caption rendering while keeping provenance text in the
analysis repository.

## Inputs

- `R-scripts/K50/make_sfig2_sensitivity_forest.R`
- `R-scripts/K50/outputs/SFIG2_sensitivity_forest/`

## Outputs

- Updated `R-scripts/K50/make_sfig2_sensitivity_forest.R`
- Regenerated SFIG2 PNG and PDF
- Validation notes in this task log

## Definition of Done (DoD)

- [x] Internal plot caption is removed from PNG and PDF.
- [x] Provenance caption text remains available in `provenance_note.txt`.
- [x] Plot content and analysis logic remain unchanged.
- [x] After validation, task was moved from `tasks/03-review/` to `tasks/04-done/`.

## Log

- 2026-03-23 09:01:22 +0200 Moved task from `tasks/01-ready/` to `tasks/02-in-progress/` before editing.
- 2026-03-23 09:01:22 +0200 Removed only the internal SFIG2 caption rendering from `R-scripts/K50/make_sfig2_sensitivity_forest.R` by deleting the `mtext()` title lines and restoring a tighter outer top margin.
- 2026-03-23 09:01:22 +0200 Kept `caption_text` and `provenance_note.txt` output intact so the analysis repository still records the figure caption as provenance, while the manuscript remains the only publication caption source.
- 2026-03-23 09:01:22 +0200 Validation: `parse(file = "R-scripts/K50/make_sfig2_sensitivity_forest.R")` passed in Debian/proot with PATH repair.
- 2026-03-23 09:01:22 +0200 Validation: `Rscript R-scripts/K50/make_sfig2_sensitivity_forest.R` passed in Debian/proot with PATH repair and regenerated PNG/PDF/sessionInfo artifacts.
- 2026-03-23 09:01:22 +0200 Visual check: regenerated PNG was inspected directly and no internal caption/title remains at the top of the image; the plotting area now has more vertical space.
- 2026-03-23 09:01:22 +0200 Scope check: term reading, plot_df construction, estimates, CI logic, legend, axes, and manuscript-repo scope were left unchanged.
- 2026-03-23 09:01:22 +0200 Created from repo task template for SFIG2 internal-caption removal.

## Blockers

- None currently. Human review can confirm that the image now relies on the manuscript caption only.

## Links

- `R-scripts/K50/make_sfig2_sensitivity_forest.R`
