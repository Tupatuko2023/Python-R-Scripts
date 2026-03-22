# K50 png export followup

## Context

Ratkaise jäljellä oleva K50-visualisoinnin PNG-export-vika paikallisesti
`R-scripts/K50/K50_visualize_fi22_fof_delta.R`-tiedostossa. PDF toimii,
SVG toimii, mutta PNG-manifest-rivejä on syntynyt ilman levylle jääviä
PNG-tiedostoja.

## Inputs

- `tasks/03-review/K50_visual_image_export_diagnosis.md`
- `R-scripts/K50/K50_visualize_fi22_fof_delta.R`
- `manifest/manifest.csv`
- `CLAUDE.md`
- `AGENTS.md`
- `README.md`
- `agent_workflow.md`

## Outputs

- paikallinen korjaus `write_figure()`-funktioon
- varmennus siitä, että PNG syntyy oikeasti levylle
- manifest vain olemassa oleville PNG-artefakteille
- lyhyt follow-up review-raportti

## Definition of Done (DoD)

- PNG-jalkivian juurisyy on todennettu ajo/file.exists-tasolla
- korjaus rajautuu kuvaexport-apuun
- PDF/SVG säilyvät toimivina
- PNG syntyy levylle niille kuville, joille manifest kirjoitetaan

## Log

- 2026-03-21 22:36:52 +0200 Task created from orchestrator prompt for K50 PNG export follow-up.
- 2026-03-21 22:36:52 +0200 Reviewed prior K50 image-export diagnosis and confirmed the remaining scope is PNG only; PDF already worked and SVG already worked after the previous patch.
- 2026-03-21 22:45:53 +0200 Replaced unconditional manifest append in `write_figure()` with explicit open-draw-close-check logic and conditional manifest append only when `file.exists(path)` is TRUE after `dev.off()`.
- 2026-03-21 22:45:53 +0200 Switched PNG open call from `type = "cairo-png"` to `type = "cairo"` because standalone Cairo probe had succeeded in the same Debian PRoot environment.
- 2026-03-21 22:45:53 +0200 Full rerun result: script printed `Figure export missing on disk, skipping manifest entry` for both PNG targets, while PDF and SVG regenerated successfully and note/sessioninfo remained present.
- 2026-03-21 22:45:53 +0200 Verified outputs after rerun: `raw_facet.pdf`, `raw_facet.svg`, `model_based.pdf`, `model_based.svg`, note txt, and sessioninfo txt exist; both expected PNG files are still absent.
- 2026-03-21 22:45:53 +0200 Verified new manifest tail from this rerun contains only PDF/SVG/text/sessioninfo rows; no new false `figure_png` rows were appended.
- 2026-03-21 22:45:53 +0200 Additional filesystem search found no PNG outputs under alternate names or paths from this rerun; standalone PNG probes still exist and confirm the device can write in this environment outside the full figure flow.

## Blockers

- Remaining blocker: the precise full-run PNG disappearance cause is still unresolved. It is no longer a manifest-order bug, because the script now checks for file existence after device close and skips manifest append when the PNG is absent.

## Links

- `/data/data/com.termux/files/home/Python-R-Scripts/prompts/2_7cafofv2.txt`

## PNG Follow-up Log

Objective: isolate and fix remaining PNG export failure only.

Required checks:

- PNG file exists on disk after full script run
- figure_png manifest rows only for existing files
- PDF and SVG outputs preserved
- no change to analysis/note/sessioninfo semantics

## Outcome

- Partial success:
  - local export helper is now deterministic and manifest-safe
  - no new false `figure_png` rows are written when PNG is missing
  - PDF and SVG still work
  - note and sessioninfo outputs remain unchanged in role and presence
- Remaining failure:
  - `k50_visual_fi22_fof_delta_raw_facet.png` does not exist after full run
  - `k50_visual_fi22_fof_delta_model_based.png` does not exist after full run
- Best current root-cause statement:
  - the previous bug was definitely unconditional manifesting without post-close existence verification
  - after fixing that, PNG still fails specifically inside the full `write_figure()` execution path, not in standalone PNG/Cairo probes
  - this points to a narrower graphics-lifecycle or expression-evaluation interaction inside the full plotting flow rather than a global PNG device outage
