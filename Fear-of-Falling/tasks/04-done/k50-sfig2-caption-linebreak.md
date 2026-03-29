# K50 SFIG2 caption linebreak

## Context

The SFIG2 caption is too long for one rendered line in the figure title area.
This task adds only a line break so the full caption remains visible without
changing wording or analysis behavior.

## Inputs

- `R-scripts/K50/make_sfig2_sensitivity_forest.R`

## Outputs

- Updated `R-scripts/K50/make_sfig2_sensitivity_forest.R`
- Regenerated SFIG2 PNG and PDF
- Validation notes in this task log

## Definition of Done (DoD)

- [x] Caption is split across two lines.
- [x] Caption content is unchanged.
- [x] PNG and PDF regenerate.
- [x] Task is moved to `tasks/03-review/` after validation.

## Log

- 2026-03-23 08:47:27 +0200 Moved task from `tasks/01-ready/` to `tasks/02-in-progress/` before editing.
- 2026-03-23 08:49:13 +0200 Updated only `caption_text` / title-layout rendering in `R-scripts/K50/make_sfig2_sensitivity_forest.R` so the existing caption is rendered as two lines without changing its wording or any analysis logic.
- 2026-03-23 08:49:13 +0200 Validation: `parse(file = "R-scripts/K50/make_sfig2_sensitivity_forest.R")` passed in Debian/proot with PATH repair.
- 2026-03-23 08:49:13 +0200 Validation: `Rscript R-scripts/K50/make_sfig2_sensitivity_forest.R` passed in Debian/proot with PATH repair and regenerated both PNG and PDF artifacts.
- 2026-03-23 08:49:13 +0200 Visual check: regenerated PNG was inspected directly and the full two-line caption is visible without shortening the text.
- 2026-03-23 08:49:13 +0200 Scope check: no data, estimates, CI calculations, or other plot components were changed.
- 2026-03-23 08:47:27 +0200 Created from repo task template for SFIG2 caption linebreak fix.

## Blockers

- None currently. Human review can focus on confirming the two-line caption layout in the regenerated PNG/PDF.

## Links

- `R-scripts/K50/make_sfig2_sensitivity_forest.R`
