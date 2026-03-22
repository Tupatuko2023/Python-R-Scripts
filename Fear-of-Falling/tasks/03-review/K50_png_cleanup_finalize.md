# K50 png cleanup finalize

## Context

Poista tilapäinen PNG-persistence-diagnostiikka
`R-scripts/K50/K50_visualize_fi22_fof_delta.R`-tiedostosta nyt kun clean
Debian PATH + intended PRoot -ajopolku on varmennettu toimivaksi.

## Inputs

- `tasks/03-review/K50_png_persistence_finalization_debug.md`
- `R-scripts/K50/K50_visualize_fi22_fof_delta.R`
- `manifest/manifest.csv`

## Outputs

- pieni cleanup-only patch tuotantoskriptiin
- varmennettu PNG/PDF/SVG/note/sessioninfo-ajotulos ilman debug-artefakteja

## Definition of Done (DoD)

- tilapäinen PNG-debug ja persist-probe on poistettu tuotantoajosta
- `file.exists()`-pohjainen manifest-kirjaus säilyy rehellisenä
- raw/model PDF/SVG/PNG sekä note/sessioninfo syntyvät edelleen

## Log

- 2026-03-22 07:41:06 +0200 Task created from orchestrator prompt for K50 PNG cleanup finalize.
- 2026-03-22 07:51:40 +0200 Removed temporary PNG persistence diagnostics and persist-probe code from `R-scripts/K50/K50_visualize_fi22_fof_delta.R` while preserving the working `write_figure()` + `draw_fun` export structure and `file.exists()`-guarded manifest append.
- 2026-03-22 07:51:40 +0200 Full rerun with clean Debian PATH inside Debian PRoot succeeded, producing raw/model PDF, SVG, and PNG outputs plus note and sessioninfo without recreating debug txt or persist-probe artifacts.
- 2026-03-22 07:51:40 +0200 Host-side output verification confirmed both PNG files remained on disk and the extra diagnostic artifacts were absent after the production run.
- 2026-03-22 07:51:40 +0200 Manifest verification confirmed the newest `figure_png` rows match real on-disk PNG files for both K50 visualization figures.

## Blockers

- None.

## Links

- `/data/data/com.termux/files/home/Python-R-Scripts/prompts/3_7cafofv2.txt`

## Outcome

- Removed:
  - PNG persistence debug txt writing
  - persist-probe PNG generation
  - checkpoint logging and temporary sleep/md5 diagnostics
- Preserved:
  - explicit `draw_raw_facet()` / `draw_model_based()` drawing functions
  - PDF/SVG/PNG export
  - manifest append only after `file.exists(path)` succeeds
  - note and sessioninfo production

## Final review summary

Production script is cleaned of temporary PNG persistence diagnostics.

Working export set confirmed on clean Debian PATH inside PRoot:

- `raw_facet.pdf/svg/png`
- `model_based.pdf/svg/png`
- `note.txt`
- `sessioninfo.txt`

No debug txt or persist-probe artifacts are produced in normal runs.

Manifest review should focus only on the latest `K50_visual_fi22_fof_delta`
rows, because `manifest.csv` is rewritten as a whole on append.

Current status: ready for human review in `03-review`; not moved to
`04-done`.
