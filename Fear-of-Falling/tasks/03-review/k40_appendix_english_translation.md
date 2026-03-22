# K40 appendix English translation

## Context

The K40 FI22 appendix export is already methodologically correct and frozen,
but the current manuscript-facing appendix still exposes Finnish text in
reporting-layer fields. This task adds an English-language appendix export
without changing FI construction, item selection, scoring logic, source data,
or source-of-truth architecture.

## Inputs

- `R-scripts/K40/K40_FI_KAAOS.R`
- `R-scripts/K40/outputs/K40_FI_KAAOS/*/k40_fi22_appendix_deficit_definitions.csv`
- `R-scripts/K40/outputs/K40_FI_KAAOS/*/k40_fi22_appendix_deficit_definitions.md`
- `manifest/manifest.csv`
- source-of-truth files resolved by K40:
  - `deficit_map.csv`
  - `k40_kaaos_selected_deficits.csv`

## Outputs

- English-language K40 appendix CSV for manuscript use
- English-language K40 appendix Markdown for manuscript use
- One manifest row per new artifact
- Appendix translation diagnostics/session info if a new run emits them

## Definition of Done (DoD)

- Translation touches only reporting-layer fields: `label`,
  `level_mapping_detail`, and `notes` if present.
- `item_id`, `domain`, `item_type`, `direction`, `scoring_rule`,
  `missing_codes`, numeric mappings, source data, and FI22 logic remain
  unchanged.
- Category structure, ordering, and missing handling remain 1:1 with the
  Finnish appendix.
- English appendix row count remains 22.
- Translated fields contain no residual Finnish wording in the exported English
  appendix.

## Log

- 2026-03-20 15:45:24 created for reporting-layer English translation of the
  K40 FI22 appendix without altering selection or scoring.
- 2026-03-20 15:58:00 updated `R-scripts/K40/K40_FI_KAAOS.R` to emit a second,
  English-language appendix export by translating only `label`,
  `level_mapping_detail`, and `notes` in the appendix reporting layer.
- 2026-03-20 16:03:58 reran `fof-preflight`; status remained expected `WARN`
  only because K40 declares the documented `dynamic_contract` exception.
- 2026-03-20 16:03:58 reran K40 in Debian PRoot with `ID_COL=1` and
  `config/.env` loaded in-shell; validated English appendix artifacts were
  written under `R-scripts/K40/outputs/K40_FI_KAAOS/20260320_140349/`.

## Blockers

- The critical risk is semantic drift from the original Finnish category
  structure; translation must stay 1:1 and must not “clean up” or reinterpret
  categories.

## Review Summary

- Changed files:
  - `R-scripts/K40/K40_FI_KAAOS.R`
  - `manifest/manifest.csv`
- New artifacts:
  - `R-scripts/K40/outputs/K40_FI_KAAOS/20260320_140349/k40_fi22_appendix_deficit_definitions_english.csv`
  - `R-scripts/K40/outputs/K40_FI_KAAOS/20260320_140349/k40_fi22_appendix_deficit_definitions_english.md`
- Reporting-layer scope only:
  - translated only `label`, `level_mapping_detail`, and `notes`
  - left `item_id`, `domain`, `item_type`, `direction`, `scoring_rule`,
    `missing_codes`, and numeric mappings unchanged
  - preserved exact 22-row structure and selector-driven ordering
- Validation:
  - English appendix row count remained 22
  - `scoring_rule` stayed unchanged
  - translated fields showed no Finnish residual wording in the final export
  - missing-coded categories were not reintroduced into
    `level_mapping_detail`
- Runtime note:
  - K40 completed successfully in Debian PRoot with `ID_COL=1`; this run used
    `set -a && . config/.env && set +a` so `DATA_ROOT` was present in-shell
    without changing K40 construction or appendix logic

## Links

- `tasks/03-review/k40_appendix_fi22_definitions.md`
- `tasks/03-review/k40_appendix_scoring_explication.md`
- `tasks/03-review/k40_appendix_missing_code_semantics.md`
