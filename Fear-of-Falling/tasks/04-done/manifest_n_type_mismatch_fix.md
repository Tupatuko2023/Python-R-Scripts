# Manifest N Type Mismatch Fix

## Context

### Objective
Unblock `fof-qc-summarizer` by fixing manifest IO boundary type handling for column `n` (character vs integer mismatch) using a minimal reversible change in shared manifest read/append path.

### Reproduction commands
- `cd Python-R-Scripts/Fear-of-Falling`
- `proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; cd Python-R-Scripts/Fear-of-Falling && /usr/bin/Rscript ../.codex/skills/fof-qc-summarizer/scripts/qc_summarize.R'`
- Expected current failure: `Can't combine '..1$n' <character> and '..2$n' <integer>.`
- Quick type inspection:
  - `proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; cd Python-R-Scripts/Fear-of-Falling && /usr/bin/Rscript -e "m<-read.csv(\"manifest/manifest.csv\", stringsAsFactors=FALSE); cat(\"n class:\", class(m$n), \"\\n\"); print(head(m$n,10));"'`

### Proposed minimal fix
- Update shared manifest helper in `R/functions/reporting.R` (or called helper path) so append path is type-stable:
  - when reading existing manifest, coerce `n` to numeric/integer with blanks -> `NA`,
  - when appending new row, coerce row `n` to same type before `bind_rows`,
  - keep all other columns untouched.
- Avoid historical content rewrites except normal read-time coercion in memory; do not mass-migrate `manifest/manifest.csv` rows.

## Inputs
- `R/functions/reporting.R`
- `manifest/manifest.csv`
- `scripts/termux/run_qc_summarizer_proot.sh`

## Outputs
- Type-stable manifest append path for `n`
- `fof-qc-summarizer` no longer fails on `n` column type mismatch

## Definition of Done (DoD)

### Acceptance criteria
- `bash scripts/termux/run_qc_summarizer_proot.sh` completes past manifest append step without `n` type error.
- Shared manifest helper consistently handles `n` type at IO boundary.
- Fix is minimal, reversible, and does not modify raw datasets.

## Log

- 2026-02-28 16:58:00 Backlog task created from template for manifest `n` type mismatch remediation.
- 2026-03-01 02:47:00 Moved task to `tasks/02-in-progress/` before code edits.
- 2026-03-01 02:49:00 Reproduced failure with env loaded:
  - Command: `set -a && . config/.env && set +a && bash scripts/termux/run_qc_summarizer_proot.sh`
  - Error: `Can't combine ..1$n <character> and ..2$n <integer>.`
- 2026-03-01 02:50:00 Implemented minimal IO-boundary fix in `R/functions/init.R`:
  - Added `normalize_manifest_n()` helper.
  - Coerce `row$n` and existing `old$n` to integer (`as.integer`) with blank -> `NA`.
  - Applied coercion before `dplyr::bind_rows(old, row)`.
  - No wholesale/manual rewrite of historical manifest contents.
- 2026-03-01 02:50:00 Validation:
  - Command: `set -a && . config/.env && set +a && bash scripts/termux/run_qc_summarizer_proot.sh`
  - Result: PASS (previous `n` bind_rows type error resolved).
  - New summary artifacts appended (`qc_summary.csv`, `qc_summary.txt`) and manifest tail printed by runner.
  - Leakage check: no `with_capacity_scores.csv/.rds` files under repo `R-scripts/*/outputs`.

## Blockers
- None.

## Links
- `prompts/Frailty_Model_Copilot_2.txt`
- Related helper: `R/functions/init.R`
- Related runner: `scripts/termux/run_qc_summarizer_proot.sh`
