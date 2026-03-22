# K50 png persistence finalization debug

## Context

Selvitä K50-visualisoinnin jäljellä oleva PNG write-finalization / persistence
-vika paikallisesti `R-scripts/K50/K50_visualize_fi22_fof_delta.R`-tiedostossa.

## Inputs

- `tasks/03-review/K50_png_expr_isolation_fix.md`
- `R-scripts/K50/K50_visualize_fi22_fof_delta.R`
- `manifest/manifest.csv`

## Outputs

- pieni PNG-persistence-debug
- yksi debug txt -artefakti
- mahdollinen pieni PNG temp-file + rename -korjaus

## Definition of Done (DoD)

- persistence-kerros on tarkennettu ajo- ja tiedostotasolla
- manifest pysyy rehellisenä
- diff pysyy paikallisena

## Log

- 2026-03-22 04:36:00 +0200 Task created from orchestrator prompt for K50 PNG persistence/finalization debug.
- 2026-03-22 07:41:06 +0200 Moved task to 02-in-progress, added a small PNG persistence debug path, and kept all analysis, note, and sessioninfo logic unchanged.
- 2026-03-22 07:41:06 +0200 Full rerun in Debian PRoot succeeded after forcing a clean Debian PATH inside the PRoot shell; both figure PNGs, the separate persist probe PNG, and the debug txt remained on disk after script exit.
- 2026-03-22 07:41:06 +0200 Debug checkpoints showed both figure PNGs existed at DRAWN_PRE_CLOSE with size 0, then at POST_CLOSE, POST_SLEEP, POST_MANIFEST, and FINAL_BEFORE_EXIT with stable nonzero size and md5.
- 2026-03-22 07:41:06 +0200 Cleanup grep over `R-scripts/K50` found no `file.remove()`, `file.rename()`, `file.copy()`, `tempfile()`, or `graphics.off()` calls that would remove the figure PNGs; only the debug txt and persist-probe reset via `unlink()` at script start.
- 2026-03-22 07:41:06 +0200 Current best conclusion: the previously suspected post-exit disappearance did not reproduce under the clean PRoot PATH rerun, so the persistence layer is not currently failing in the script itself.

## Blockers

- No active blocker for PNG persistence on the current run. Remaining review question is whether the debug instrumentation should stay as-is or be trimmed in a follow-up cleanup-only pass.

## Links

- `/data/data/com.termux/files/home/Python-R-Scripts/prompts/3_7cafofv2.txt`

## Outcome

- Debug artifact: `R-scripts/K50/outputs/k50_visual_fi22_fof_delta_png_persistence_debug.txt`
- Persist probe: `R-scripts/K50/outputs/k50_visual_fi22_fof_delta_png_persist_probe.png`
- Verified on disk after exit:
  - `k50_visual_fi22_fof_delta_raw_facet.png`
  - `k50_visual_fi22_fof_delta_model_based.png`
  - matching PDF/SVG, note, and sessioninfo files
- Manifest status:
  - newest `figure_png` rows now match real on-disk artifacts
- Root-cause statement for this round:
  - the script did not reproduce a true write-finalization or post-exit deletion failure once run from the intended Debian PRoot path with a clean Debian `PATH`
  - the separate persist probe surviving alongside both figure PNGs further argues against a generic PNG persistence failure in the current code path

## Follow-up

- 2026-03-22 07:51:40 +0200 Cleanup-only follow-up removed the temporary PNG persistence diagnostics from the production script.
- 2026-03-22 07:51:40 +0200 Clean-PATH Debian PRoot rerun after cleanup still produced `raw_facet.png` and `model_based.png` on disk, while no debug txt or persist-probe artifact was recreated.
- 2026-03-22 07:51:40 +0200 Current review conclusion: the earlier suspected PNG persistence failure does not reproduce on the intended run path, and the production script is now back to a clean export-only state.
