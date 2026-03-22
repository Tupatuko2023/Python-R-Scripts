# K40 appendix missing-code semantics

## Context

K40 appendix-export is now deterministic and manuscript-readable, but ordinal
rows still risk implying that missing codes such as `ei tietoa` are part of the
deficit scale. This is a reporting-layer issue only: upstream FI22/K40 scoring
and selection remain correct and must stay unchanged.

## Inputs

- `R-scripts/K40/K40_FI_KAAOS.R`
- latest appendix CSV and Markdown outputs
- current source-of-truth structure:
  `deficit_map.csv` + `k40_kaaos_selected_deficits.csv`

## Outputs

- appendix export where `level_mapping_detail` excludes missing-coded levels
- ordinal `scoring_rule` text that explicitly states missing codes are excluded
  before scoring
- parser cleanup that preserves meaningful inner parentheses in level labels
- review-ready task log

## Definition of Done (DoD)

- Ordinal appendix rows no longer imply that missing codes map to the worst
  deficit level.
- `level_mapping_detail` is reconstructed only from valid scored levels when
  `missing_codes` identifies excluded codes.
- Parser no longer truncates examples like `(hyvä)` or `(< 3cm)`.
- No upstream FI22/K40 selection or scoring logic changes.

## Log

- 2026-03-19 20:36:00 +0200 created follow-up task for appendix missing-code
  semantics and level-detail cleanup
- 2026-03-19 20:45:00 +0200 updated `R-scripts/K40/K40_FI_KAAOS.R` so appendix
  level parsing excludes `missing_codes` from `level_mapping_detail` and
  ordinal `scoring_rule` text now states that missing codes are excluded prior
  to scoring
- 2026-03-19 20:47:00 +0200 hardened the level parser to preserve meaningful
  inner parentheses such as `(hyvä)` and `(< 3cm)` and to avoid treating
  `E1=...` fragments as numeric level mappings
- 2026-03-19 20:54:59 +0200 reran K40 in Debian PRoot with `ID_COL=1`; latest
  validated outputs written under
  `R-scripts/K40/outputs/K40_FI_KAAOS/20260319_185452/`

## Blockers

- None currently; reporting layer must remain deterministic and source-of-truth
  driven.

## Review Summary

- Changed files: `R-scripts/K40/K40_FI_KAAOS.R`, `manifest/manifest.csv`
- Reporting fix:
  - ordinal `level_mapping_detail` now excludes levels whose codes are listed in
    `missing_codes`
  - ordinal `scoring_rule` now states that only valid categories are mapped to
    0-1 and that missing codes are excluded before scoring
  - binary appendix rows also stop listing missing-coded levels in
    `level_mapping_detail`, leaving `missing_codes` as the explicit missingness
    field
- Parser cleanup:
  - preserved inner parenthetical descriptors such as `(hyvä)` and `(< 3cm)`
  - prevented `E1`-style missing tokens from being parsed as ordinal levels
- Source-of-truth unchanged:
  - appendix still reconstructs from `deficit_map.csv` plus
    `k40_kaaos_selected_deficits.csv`
  - FI22/K40 upstream selection and scoring logic were not changed
- Validation:
  - latest rerun succeeded with `ID_COL=1`
  - latest appendix outputs are under
    `R-scripts/K40/outputs/K40_FI_KAAOS/20260319_185452/`
  - manifest gained one row per newly generated artifact for run
    `20260319_185452`
- Residual caveat:
  - if labels omit human-readable category wording entirely, the appendix still
    leaves `level_mapping_detail` blank rather than inventing manuscript text
