# K50 png expr isolation fix

## Context

Rajaa jäljellä oleva PNG-vika expr-tasolle ja korjaa se pienesti
`R-scripts/K50/K50_visualize_fi22_fof_delta.R`-tiedostossa irrottamalla inline
piirrot deterministisiksi draw-funktioiksi.

## Inputs

- `tasks/03-review/K50_png_device_lifecycle_debug.md`
- `R-scripts/K50/K50_visualize_fi22_fof_delta.R`
- `manifest/manifest.csv`

## Outputs

- pieni paikallinen expr-isolation-fix
- varmennus PDF/SVG/PNG outputeista
- review-yhteenveto juurisyystä ja korjauksesta

## Definition of Done (DoD)

- muutos rajautuu `write_figure()`-polkuun ja draw-funktioihin
- PNG:t joko syntyvät tai pysähdyspiste tarkentuu yksiselitteisesti
- manifest pysyy rehellisenä

## Log

- 2026-03-21 23:37:23 +0200 Task created from orchestrator prompt for K50 PNG expr isolation fix.
- 2026-03-21 23:37:23 +0200 Moved task to 02-in-progress and reviewed prior device-lifecycle debug before editing the plotting path.
- 2026-03-21 23:40:45 +0200 Replaced inline plotting promises with explicit `draw_raw_facet()` and `draw_model_based()` functions and passed those into `write_figure()` per device; kept note/sessioninfo/analyysi unchanged.
- 2026-03-21 23:40:45 +0200 Full rerun completed without PNG-missing console messages, and manifest gained new `figure_png` rows for both figures.
- 2026-03-21 23:40:45 +0200 Post-run filesystem verification on both host and Debian PRoot still showed no `k50_visual_fi22_fof_delta_*.png` files, while PDF and SVG existed normally.
- 2026-03-21 23:40:45 +0200 Unexpected follow-up finding: the debug artifact itself did not persist after the expr-isolation rerun, so the previous instrumented evidence is currently stronger than this round's on-disk evidence.
- 2026-03-21 23:40:45 +0200 Best current conclusion: expr isolation alone did not solve the disappearance, and there is now evidence that `file.exists()` may transiently pass inside the R process for PNG while the file is not present after the process exits.

## Blockers

- Remaining blocker: PNG disappearance still unresolved. The latest run regressed manifest honesty by reintroducing fresh `figure_png` rows without durable PNG files on disk, so this change is not a complete fix.

## Links

- `/data/data/com.termux/files/home/Python-R-Scripts/prompts/3_7cafofv2.txt`

## Expr Isolation Fix Log

Goal: move inline plotting expressions into deterministic draw functions.

Keep par/layout resets local to each draw function.

Validate png/pdf/svg outputs per figure and manifest honesty.

## Outcome

- What changed:
  - `write_figure()` now takes explicit draw functions rather than inline expr promises
  - raw facet plotting moved to `draw_raw_facet()`
  - model-based plotting moved to `draw_model_based()`
- What stayed unchanged:
  - data inputs
  - model fit and prediction logic
  - note text meaning and sessioninfo output
  - PDF/SVG output content role
- Result:
  - PDF and SVG still work
  - PNG still does not persist on disk
  - newest manifest rows again claim PNG artifacts that are not present afterward
- Best current root-cause statement:
  - promise-based expr evaluation was not the only remaining issue
  - there is likely an additional PNG-specific persistence or write-finalization problem occurring after the in-process existence check
