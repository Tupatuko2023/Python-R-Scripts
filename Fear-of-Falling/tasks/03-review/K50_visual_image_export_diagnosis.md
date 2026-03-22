# K50 visual image export diagnosis

## Context

Selvitä miksi `R-scripts/K50/K50_visualize_fi22_fof_delta.R` ei tuota
`.png`- tai `.svg`-kuvia, vahvista mitä artefakteja skripti oikeasti kirjoittaa,
ja tee vasta sitten pieni paikallinen export-korjaus tarvittaessa.

## Inputs

- `R-scripts/K50/K50_visualize_fi22_fof_delta.R`
- `R-scripts/K50/K50_robustness_check_influence_and_se.R`
- `manifest/manifest.csv`
- `CLAUDE.md`
- `AGENTS.md`
- `README.md`
- `agent_workflow.md`

## Outputs

- juurisyyraportti kuvaexportin puutteesta
- varmennus syntyvistä artefakteista ennen mahdollista korjausta
- mahdollinen minimaalinen patch kuvaexport-apuun
- review-yhteenveto diffistä ja manifestivaikutuksista

## Definition of Done (DoD)

- juurisyy on vahvistettu grep/sed/ajo-tasolla
- visualisointiskripti on ajettu ja syntyneet artefaktit listattu
- robustness-skriptin rooli kuvaverrokkina on tarkistettu
- mahdollinen export-patch on minimaalinen ja manifestoi uudet kuvaformaatit

## Log

- 2026-03-21 22:11:04 +0200 Task created from orchestrator prompt for K50 image export diagnosis.
- 2026-03-21 22:11:04 +0200 Moved task to 02-in-progress and inspected `K50_visualize_fi22_fof_delta.R` plus `K50_robustness_check_influence_and_se.R`.
- 2026-03-21 22:14:10 +0200 Confirmed by grep and rerun that the original visualization script wrote only `.pdf` figures plus note/sessioninfo text; manifest contained only `figure_pdf` rows for the two figures.
- 2026-03-21 22:14:10 +0200 Confirmed `K50_robustness_check_influence_and_se.R` is not a valid positive image-export comparator: it writes csv/txt/sessioninfo artifacts and has no image device calls.
- 2026-03-21 22:15:56 +0200 Applied a minimal local patch to `write_figure()` to add `.png` and `.svg` exports while preserving existing `.pdf` output and one manifest row per artifact.
- 2026-03-21 22:16:00 +0200 Follow-up probe showed standalone `grDevices::png()` works in the same Debian PRoot environment, so missing PNG files are not explained by a global headless device failure.
- 2026-03-21 22:20:41 +0200 Refined the patch to close each graphics device immediately after drawing; `.svg` outputs materialized successfully, but `.png` files still did not appear on disk even though manifest rows were appended.
- 2026-03-21 22:25:25 +0200 Additional `cairo-png` probe succeeded as a standalone device test, but rerunning the full K50 visualization script still did not leave `k50_visual_fi22_fof_delta*.png` files anywhere under `/data/data/com.termux/files/home`.

## Blockers

- PNG export remains unresolved in the full visualization script: manifest rows are appended for `figure_png`, but the corresponding files are not present on disk after a successful rerun. Root cause is narrower than the original problem, but not fully closed in this turn.

## Links

- `/data/data/com.termux/files/home/Python-R-Scripts/prompts/2_7cafofv2.txt`

## End State

- Confirmed original root cause: `write_figure()` only opened `grDevices::pdf()` and therefore the script did not even attempt PNG/SVG export before the patch.
- Confirmed original produced artifacts before patch:
  - `k50_visual_fi22_fof_delta_raw_facet.pdf`
  - `k50_visual_fi22_fof_delta_model_based.pdf`
  - `k50_visual_fi22_fof_delta_note.txt`
  - `k50_visual_fi22_fof_delta_sessioninfo.txt`
- Confirmed robustness script is not an image-export comparator.
- After patch:
  - `.pdf` outputs still regenerate
  - `.svg` outputs now regenerate and exist on disk
  - `.png` manifest rows are appended, but `.png` files still do not remain on disk after the full script run

## Review Note

This task is reviewable as a diagnosis with a partial export patch, but not fully closed as a complete PNG/SVG success. The original failure mode is proven. The remaining issue is specifically that PNG export behaves differently inside the full `write_figure()` flow than in standalone device probes.
