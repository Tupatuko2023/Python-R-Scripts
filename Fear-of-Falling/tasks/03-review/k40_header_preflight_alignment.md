# K40 header and preflight alignment after appendix export

## Context

K40 appendix export already works and its source-of-truth logic must stay
unchanged. The remaining repo-compliance issue is that `fof-preflight` fails on
`K40_FI_KAAOS.R` because the script still uses a legacy header with no
`Required vars` block.

## Inputs

- `R-scripts/K40/K40_FI_KAAOS.R`
- `fof-preflight` validator code
- `CLAUDE.md`
- `AGENTS.md`
- `README.md`

## Outputs

- compliant K40 header and/or narrowly scoped validator adjustment
- passing `fof-preflight` result for this diff
- rerun validation log for K40 with `ID_COL=1`
- latest validated rerun:
  `R-scripts/K40/outputs/K40_FI_KAAOS/20260319_174201/`

## Definition of Done (DoD)

- No fake static `req_cols` list is added to the dynamic KAAOS reader.
- `fof-preflight` no longer fails on `Required vars header missing` for K40.
- K40 reruns successfully with `ID_COL=1`.
- Appendix export logic and FI selection/scoring remain unchanged.

## Log

- 2026-03-19 19:24:00 +0200 created compliance follow-up after appendix export review left a preflight blocker on legacy K40 header conventions
- 2026-03-19 19:27:00 +0200 audited validator behavior: failure was caused first by missing `Required vars` header, and the existing preflight logic would still expect a parsable/fixed requirements declaration unless given a narrow exception
- 2026-03-19 19:30:00 +0200 added a truthful K40 header block describing the dynamic KAAOS raw-sheet contract without inventing a static `req_cols` vector
- 2026-03-19 19:31:00 +0200 added a narrow validator path in `fof-preflight` for `R-scripts/K40/K40_FI_KAAOS.R` only when the script explicitly declares the dynamic raw-sheet contract
- 2026-03-19 19:33:00 +0200 reran `fof-preflight`: status is now `WARN`, not `FAIL`; requirements source reports `dynamic_contract`, and the only warning documents why fixed `req_cols` is skipped for this script
- 2026-03-19 19:42:00 +0200 reran K40 in Debian PRoot with `ID_COL=1` and sourced `config/.env`; run completed and appendix artifacts regenerated under run id `20260319_174201`
- 2026-03-19 19:42:00 +0200 confirmed appendix contract stayed unchanged: appendix rows=22, `appendix_selection_source=selected_deficits`, fallback behavior remained unexercised, and appendix map source stayed `../Quantify-FOF-Utilization-Costs/R/40_FI/deficit_map.csv`
- 2026-03-19 19:43:00 +0200 manifest updated only with genuinely new rerun artifacts from `20260319_174201`, one row per artifact

## Review Summary

- Changed files:
  `R-scripts/K40/K40_FI_KAAOS.R`
  `.codex/skills/fof-preflight/scripts/preflight.py`
  `manifest/manifest.csv`
  this task card
- Compliance resolution:
  combined fix
  script side: added a truthful `Required vars` section describing the dynamic KAAOS reader contract
  validator side: added a narrowly scoped `dynamic_contract` branch only for `R-scripts/K40/K40_FI_KAAOS.R`
- Why this is honest:
  K40 does not have a stable static raw column inventory suitable for a truthful `req_cols <- c(...)`
  the script reads a raw KAAOS sheet, resolves the identifier column dynamically, and screens candidate deficit columns from the live sheet contents
  a fake fixed `req_cols` list would have misrepresented the actual contract
- Validation outcome:
  `fof-preflight` no longer fails on `Required vars header missing`
  current status is `WARN` with explicit documentation: `dynamic K40 raw-sheet contract declared; skipped fixed req_cols check`
  K40 rerun with `ID_COL=1` succeeded and produced a fresh appendix-export run at `20260319_174201`
- Non-changes:
  no FI22/K40 selection logic changed
  no deficit scoring logic changed
  no appendix source-of-truth logic changed
  no changes were made to `tasks/03-review/K51_three_key_linkage_audit.md`

## Blockers

- None currently; fix must stay at compliance/validator level and not alter analysis logic.

## Links

- `tasks/03-review/k40_appendix_fi22_definitions.md`
