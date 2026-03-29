# K50 png device lifecycle debug

## Context

Eristä jäljellä oleva K50-visualisoinnin PNG-vika instrumentoidulla ajolla.
Tavoite on selvittää, onko vika helper/device-lifecyclessa vai varsinaisessa
piirtoexprissä.

## Inputs

- `tasks/03-review/K50_png_export_followup.md`
- `R-scripts/K50/K50_visualize_fi22_fof_delta.R`
- `manifest/manifest.csv`
- `CLAUDE.md`
- `AGENTS.md`

## Outputs

- pieni debug-instrumentointi `write_figure()`-polkuun
- yksi debug txt -artefakti outputs-kansioon
- tarkennettu juurisyyraportti

## Definition of Done (DoD)

- debug txt syntyy
- debug erottaa helper-proben ja varsinaisen exprin PNG-käyttäytymisen
- manifest pysyy rehellisenä
- diff pysyy pienenä ja paikallisena

## Log

- 2026-03-21 22:36:52 +0200 Task created from orchestrator prompt for K50 PNG device lifecycle debug.
- 2026-03-21 22:36:52 +0200 Moved task to 02-in-progress and reviewed `tasks/03-review/K50_png_export_followup.md` before changing `write_figure()`.
- 2026-03-21 23:27:56 +0200 Added one debug artifact `R-scripts/K50/outputs/k50_visual_fi22_fof_delta_png_debug.txt` plus helper-level PNG probe instrumentation inside `write_figure()`; scope remained limited to export/debug logic.
- 2026-03-21 23:27:56 +0200 Full rerun completed successfully: PDF, SVG, note, sessioninfo, and debug txt were written; no new false `figure_png` manifest rows were appended.
- 2026-03-21 23:27:56 +0200 Debug showed helper/device/path are not the remaining root cause: for both figures, PNG `PROBE_CLOSED` had `file.exists.post_close=TRUE`, but the immediately following actual expr on the same PNG device had `file.exists.pre_close=FALSE` and `file.exists.post_close=FALSE` with no warning/error.
- 2026-03-21 23:27:56 +0200 PDF and SVG branches for the same figure expressions both showed `DRAWN` and `CLOSED` with `file.exists.post_close=TRUE`, so the remaining failure is specific to the actual base-graphics expression on PNG, not to device opening, output path resolution, or manifest ordering.

## Blockers

- Remaining blocker: the precise low-level reason why the actual base-graphics expressions do not materialize PNG files, while the helper-level PNG probe does, is still unresolved. The evidence now points to an expression/plotting-state interaction specific to PNG rather than a helper/path/device-lifecycle outage.

## Links

- `/data/data/com.termux/files/home/Python-R-Scripts/prompts/3_7cafofv2.txt`

## Device Lifecycle Debug Log

Add one small debug txt artifact for device open/draw/close/file.exists states.

Compare trivial/helper behavior versus actual plot expression behavior.

Keep manifest conditional on file.exists after dev.off.

## Outcome

- Debug artifact path:
  - `R-scripts/K50/outputs/k50_visual_fi22_fof_delta_png_debug.txt`
- Observed behavior:
  - PDF actual expr: closes cleanly and file exists
  - SVG actual expr: closes cleanly and file exists
  - PNG trivial probe: closes cleanly and file exists
  - PNG actual expr: no warning, no error, but file does not exist before or after `dev.off()`
- Best current root-cause statement:
  - not an output-path problem
  - not a generic PNG/Cairo device outage
  - not the old false-manifest bug
  - most likely an expression-evaluation or base-graphics plotting-state interaction that affects only the real `raw_facet` / `model_based` expressions on PNG
