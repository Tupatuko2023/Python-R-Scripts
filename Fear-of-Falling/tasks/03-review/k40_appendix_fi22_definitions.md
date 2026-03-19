# K40 appendix export for FI22 deficit definitions and scoring rules

## Context

K40 needs a publication-facing appendix export that is reconstructed
deterministically from the current source-of-truth files, without changing FI22
selection or scoring logic. The appendix must stay downstream of
`deficit_map.csv` and `k40_kaaos_selected_deficits.csv`.

## Inputs

- `R-scripts/K40/K40_FI_KAAOS.R`
- `deficit_map.csv` resolved by the current K40 search logic
- `k40_kaaos_selected_deficits.csv` as the preferred FI22 selector
- `manifest/manifest.csv`

## Outputs

- K40 appendix CSV under `R-scripts/K40/outputs/...`
- K40 appendix Markdown under `R-scripts/K40/outputs/...`
- session diagnostics artifact in `manifest/`
- review-ready task log with appendix/export caveats
- latest validated run:
  `R-scripts/K40/outputs/K40_FI_KAAOS/20260319_171814/`

## Definition of Done (DoD)

- K40 exports a deterministic appendix table from mapping + selected-deficits.
- Preferred selector is `k40_kaaos_selected_deficits.csv`; fallback is
  `keep == 1` in `deficit_map.csv` only when selector is absent.
- No raw data edits and no changes to FI22/K40 scoring or selection logic.
- One manifest row exists for each new appendix artifact.
- Any ordinal manuscript-only wording gaps are documented as caveats, not
  hardcoded as invented rules.

## Log

- 2026-03-19 19:00:25 +0200 created task card for K40 appendix export from current source-of-truth files
- 2026-03-19 19:00:25 +0200 audited current K40 layout: appendix export belongs in `R-scripts/K40/K40_FI_KAAOS.R` after selected-deficits write step
- 2026-03-19 19:04:00 +0200 added appendix export helpers to `R-scripts/K40/K40_FI_KAAOS.R`; kept FI selection/scoring path unchanged and attached appendix as downstream reporting step
- 2026-03-19 19:12:00 +0200 validated Debian parse and reran K40 via `renv/activate.R` with historical deterministic override `ID_COL=1`; run completed successfully
- 2026-03-19 19:18:00 +0200 confirmed appendix artifacts:
  `k40_fi22_appendix_deficit_definitions.csv`,
  `k40_fi22_appendix_deficit_definitions.md`,
  `manifest/sessionInfo_k40_appendix_fi22_definitions_20260319_171814.txt`
- 2026-03-19 19:18:00 +0200 manifest rows appended one per new appendix artifact; receipt and decision log updated with appendix provenance, selection mode, and ordinal caveat
- 2026-03-19 19:19:00 +0200 review note: appendix used `k40_kaaos_selected_deficits.csv` as selector (`selection_mode=selected_deficits`); keep-fallback path remains implemented but was not exercised in this run
- 2026-03-19 19:20:00 +0200 review note: appendix mapping resolved from `../Quantify-FOF-Utilization-Costs/R/40_FI/deficit_map.csv` because the existing K40 scoring run still reports `deficit_map_loaded=FALSE` in Fear-of-Falling
- 2026-03-19 19:21:00 +0200 review note: `fof-preflight` still fails on pre-existing `K40_FI_KAAOS.R` header convention (`Required vars header missing`); left unchanged to avoid inventing a false fixed `req_cols` list for a dynamic KAAOS sheet reader

## Review Summary

- Changed files:
  `R-scripts/K40/K40_FI_KAAOS.R`
  `manifest/manifest.csv`
  this task card
- Generated appendix artifacts from run `20260319_171814`:
  CSV and Markdown under `R-scripts/K40/outputs/K40_FI_KAAOS/20260319_171814/`
  diagnostics under `manifest/sessionInfo_k40_appendix_fi22_definitions_20260319_171814.txt`
- Selector behavior:
  preferred selector path was exercised successfully via `k40_kaaos_selected_deficits.csv`
  fallback `keep == 1` remains in code for cases where selector file is absent
- Source-of-truth contract:
  appendix is reconstructed from mapping + selected-deficits only
  no FI22 item-selection rules or deficit scoring rules were edited upstream
- Manuscript caveat:
  some ordinal items now carry raw label text with level descriptions from the KAAOS label row
  if a manuscript still needs cleaner prose descriptions for some ordinal levels, that remains a manuscript-layer refinement and was not hardcoded into the export
- Validation:
  Debian proot K40 rerun passed with `ID_COL=1`
  manifest rows present for appendix CSV, appendix Markdown, and diagnostics
  `fof-preflight` fails only on the legacy K40 header/`Required vars` convention

## Blockers

- `deficit_map.csv` is not stored inside `Fear-of-Falling/`; K40 currently resolves it from the existing relative-search chain.

## Links

- `tasks/04-done/K40_build_frailty_index_fi.md`
- `tasks/03-review/K40-domain-overrides-and-export-governance.md`
