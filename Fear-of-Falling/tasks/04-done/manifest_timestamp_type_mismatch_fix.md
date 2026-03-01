# Manifest Timestamp Type Mismatch Fix

## Context

### Objective
Fix manifest append type instability for `timestamp` at the IO boundary so `append_manifest()` cannot fail when existing manifest parses `timestamp` as datetime and new rows provide character timestamps.

### Reproduction commands
- `cd Python-R-Scripts/Fear-of-Falling`
- `bash scripts/termux/run_k30_proot.sh`
- Current failure:
  - `Can't combine ..1$timestamp <datetime<UTC>> and ..2$timestamp <character>.`

### Proposed minimal fix
- Update shared manifest append helper in `R/functions/init.R`:
  - normalize `timestamp` type for both `old` (read manifest) and `row` (new row) immediately before `bind_rows(old, row)`.
  - choose one stable type (recommended: character) and coerce both sides consistently.
- Keep fix at IO boundary only; do not rewrite historical manifest file wholesale.
- Preserve existing `n` normalization logic.

## Inputs
- `R/functions/init.R`
- `manifest/manifest.csv`
- `scripts/termux/run_k30_proot.sh`

## Outputs
- Type-stable manifest append for `timestamp` and `n`.
- `run_k30_proot.sh` no longer fails on vctrs timestamp type mismatch.

## Definition of Done (DoD)

### Acceptance criteria
- `bash scripts/termux/run_k30_proot.sh` passes.
- `bash scripts/termux/run_k31_proot.sh` and `bash scripts/termux/run_qc_summarizer_proot.sh` still pass.
- No patient-level leakage to repo outputs.
- No wholesale manifest rewrite.

## Log

- 2026-03-01 11:35:00 Backlog task created after runner-hardening review exposed timestamp type mismatch in manifest append.
- 2026-03-01 11:36:00 Moved task to `tasks/02-in-progress/` before edits.
- 2026-03-01 11:37:00 Reproduction run:
  - Command: `bash scripts/termux/run_k30_proot.sh`
  - Note: run succeeded in this attempt, but blocker had been previously observed with:
    `Can't combine ..1$timestamp <datetime<UTC>> and ..2$timestamp <character>.`
- 2026-03-01 11:40:00 Implemented IO-boundary timestamp normalization in `R/functions/init.R`:
  - Added `normalize_manifest_timestamp()`:
    - POSIXt -> UTC ISO-like string (`%Y-%m-%dT%H:%M:%SZ`)
    - character -> as-is
    - other -> safe `as.character()`
    - blanks -> `NA_character_`
  - Applied to both `row$timestamp` and `old$timestamp` immediately before `bind_rows(old, row)`.
  - Existing `n` normalization retained.
- 2026-03-01 11:45:00 Validation:
  - `bash scripts/termux/run_k30_proot.sh` -> PASS
  - `bash scripts/termux/run_k31_proot.sh` -> PASS (one transient proot/readr bus error observed in an intermediate run; immediate rerun PASS)
  - `bash scripts/termux/run_qc_summarizer_proot.sh` -> PASS
  - leak-check (`with_capacity_scores.csv/.rds` in repo outputs) -> clean
  - manifest append continued successfully; no wholesale manifest rewrite performed.

## Blockers
- None.

## Links
- `R/functions/init.R`
- `scripts/termux/run_k30_proot.sh`
- `manifest/manifest.csv`
