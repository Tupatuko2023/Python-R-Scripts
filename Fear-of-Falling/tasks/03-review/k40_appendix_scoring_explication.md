# K40 appendix scoring explication

## Context

K40 appendix-export already reconstructs the FI22 appendix deterministically from
the current source-of-truth files. The remaining refinement is manuscript
clarity: `scoring_rule` is still too generic for ordinal items, and appendix
rows should expose parsed level-detail text when the item label contains
explicit category coding.

## Inputs

- `R-scripts/K40/K40_FI_KAAOS.R`
- current appendix CSV and Markdown exports
- existing K40 source-of-truth architecture:
  `deficit_map.csv` + `k40_kaaos_selected_deficits.csv`

## Outputs

- updated appendix CSV and Markdown with more explicit scoring descriptions
- new `level_mapping_detail` column when label parsing succeeds
- review-ready task log

## Definition of Done (DoD)

- Ordinal `scoring_rule` no longer uses the generic “scaled to 0-1” wording.
- Binary `scoring_rule` is explicit about 0/1 interpretation.
- New `level_mapping_detail` column is added without inventing values.
- No upstream FI22/K40 scoring or selection logic changes.

## Log

- 2026-03-19 20:01:00 +0200 created follow-up task for referee-proof appendix scoring text and parsed level-detail output
- 2026-03-19 20:22:00 +0200 updated `R-scripts/K40/K40_FI_KAAOS.R` so appendix `scoring_rule` text is explicit for binary and ordinal items, and added safe label parsing for `level_mapping_detail`
- 2026-03-19 20:27:00 +0200 reran `fof-preflight`; status remained expected `WARN` only because K40 declares documented `dynamic_contract` and skips fixed `req_cols` validation
- 2026-03-19 20:27:17 +0200 reran K40 in Debian PRoot with `ID_COL=1`; latest validated outputs written under `R-scripts/K40/outputs/K40_FI_KAAOS/20260319_182712/`

## Blockers

- None currently; parser must fail safely and leave NA where labels do not encode explicit levels.

## Review Summary

- Changed files: `R-scripts/K40/K40_FI_KAAOS.R`, `manifest/manifest.csv`
- New appendix behavior:
  - `scoring_rule` now states explicit binary 0/1 deficit coding instead of generic wording
  - ordinal rows now state the deterministic ordered mapping to `0, 0.25, 0.5, 0.75, 1`
  - new `level_mapping_detail` column is reconstructed from label text only when explicit coded levels are present
- Source-of-truth unchanged:
  - appendix still reconstructs from `deficit_map.csv` plus `k40_kaaos_selected_deficits.csv`
  - FI22/K40 selection logic and upstream scoring logic were not changed
- Validation:
  - `fof-preflight` = `WARN` with the existing documented `dynamic_contract` exception, not a new failure
  - K40 rerun succeeded with `ID_COL=1`
  - manifest gained one row per newly generated artifact for run `20260319_182712`
- Remaining caveat:
  - if an ordinal label does not encode human-readable category levels, `level_mapping_detail` is intentionally left blank rather than guessed; any extra manuscript phrasing remains outside code

## Links

- `tasks/03-review/k40_appendix_fi22_definitions.md`
- `tasks/03-review/k40_header_preflight_alignment.md`
