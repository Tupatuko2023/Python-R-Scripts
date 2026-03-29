# K40 appendix English polish

## Context

The K40 English FI22 appendix is already methodologically correct and
submission-ready. This follow-up is limited to final manuscript-facing wording
polish in the English appendix export and, if applicable, a narrow source
switch so manuscript rendering points to the English appendix rather than the
Finnish internal/source artifact.

## Inputs

- `R-scripts/K40/K40_FI_KAAOS.R`
- `tasks/03-review/k40_appendix_english_translation.md`
- latest English appendix outputs under `R-scripts/K40/outputs/K40_FI_KAAOS/`
- `manifest/manifest.csv`
- any manuscript or supplementary appendix references to appendix source files

## Outputs

- Updated English appendix CSV and Markdown with minor wording polish only
- One manifest row per newly emitted artifact
- Review-ready task log describing the non-critical polish scope

## Definition of Done (DoD)

- Only minor wording changes are made in English `label`,
  `level_mapping_detail`, and `notes`.
- `scoring_rule`, `missing_codes`, `item_id`, `domain`, `item_type`,
  `direction`, numeric mappings, missing handling, and FI22 logic remain
  unchanged.
- English appendix row count remains 22.
- If a manuscript/supplementary source reference exists, it points to the
  English appendix file only.
- Finnish appendix remains present as an internal/source artifact.

## Log

- 2026-03-20 16:10:00 created for non-critical manuscript polish of the K40
  English appendix and manuscript-facing source selection.
- 2026-03-20 17:00:00 updated the K40 English appendix translation lookup with
  four manuscript-facing wording refinements only: `uses glasses` ->
  `requires glasses`, `moderate mood` -> `moderately low mood`,
  `sleeps variably` -> `variable sleep`, and `TK: VAS` ->
  `Pain intensity (VAS)`.
- 2026-03-20 17:00:00 added receipt/log-level manuscript source locking so the
  manuscript-facing appendix is explicitly the English markdown file while the
  Finnish appendix remains the internal/source artifact.
- 2026-03-20 17:01:31 reran `fof-preflight`; status remained expected `WARN`
  only because K40 declares the documented `dynamic_contract` exception.
- 2026-03-20 17:01:31 reran K40 in Debian PRoot with `config/.env` sourced and
  `ID_COL=1`; polished English appendix artifacts were written under
  `R-scripts/K40/outputs/K40_FI_KAAOS/20260320_150123/`.

## Blockers

- Wording polish must not drift into semantic reinterpretation of categories or
  alter the validated 1:1 structure.

## Review Summary

- Changed files:
  - `R-scripts/K40/K40_FI_KAAOS.R`
  - `manifest/manifest.csv`
- New polished artifacts:
  - `R-scripts/K40/outputs/K40_FI_KAAOS/20260320_150123/k40_fi22_appendix_deficit_definitions_english.csv`
  - `R-scripts/K40/outputs/K40_FI_KAAOS/20260320_150123/k40_fi22_appendix_deficit_definitions_english.md`
- Non-critical wording changes only:
  - `uses glasses` -> `requires glasses`
  - `moderate mood` -> `moderately low mood`
  - `sleeps variably` -> `variable sleep`
  - `TK: VAS` / `TK VAS` -> `Pain intensity (VAS)`
- Structural validation:
  - row count remained 22
  - `item_id`, `domain`, `item_type`, `direction`, `scoring_rule`,
    `missing_codes`, and `priority` were unchanged between the previous and
    polished English appendix exports
  - only `label`, `level_mapping_detail`, and `notes` changed, affecting 8
    translated fields across 4 appendix rows
- Manuscript-source handling:
  - no separate manuscript/supplementary render config referencing the appendix
    was present in the repo
  - manuscript-facing source selection was therefore locked in
    `k40_kaaos_patient_level_output_receipt.txt` and
    `k40_kaaos_decision_log.txt` via
    `appendix_manuscript_source=k40_fi22_appendix_deficit_definitions_english.md`
    while preserving the Finnish appendix as
    `appendix_internal_source=k40_fi22_appendix_deficit_definitions.md`

## Links

- `tasks/03-review/k40_appendix_english_translation.md`
- `tasks/03-review/k40_appendix_fi22_definitions.md`
