# KXX Repo Cleanup And Remote Sync

## Context
Repository worktree contains accumulated scoped analysis changes and generated aggregate artifacts from completed K15-K38 workflow gates.
This task performs deterministic hygiene + remote synchronization while preserving governance:
- no patient-level exports in repo,
- no external DATA_ROOT artifacts committed,
- no manifest history rewrite.

## Inputs
- Current git worktree state (`git status --porcelain`, `git diff --stat`, untracked listing)
- Governance guard patterns for forbidden patient-level artifacts
- Existing project outputs/receipts/tasks/code/docs

## Outputs
- One scoped hygiene/sync commit (if staged changes exist)
- Updated remote branch via `pull --rebase` + `push`
- Task moved to `tasks/03-review/` with command log

## Definition of Done (DoD)
- Worktree audited with deterministic commands.
- Forbidden patient-level patterns in repo are empty.
- Staged set excludes `config/.env` and forbidden export patterns.
- Commit created (or explicitly skipped if nothing staged).
- `git pull --rebase` clean.
- `bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling` PASS.
- `git push` succeeds.
- Task moved to `tasks/03-review/`.

## Log
- 2026-03-01 20:43: Task created and moved `00-backlog -> 01-ready -> 02-in-progress`.
- 2026-03-01 20:44: Audit commands run:
  - `git status --porcelain`
  - `git diff --stat`
  - `git ls-files --others --exclude-standard`
- 2026-03-01 20:45: Forbidden-pattern scan run:
  - `find . -type f (outputs with_capacity_scores/analysis patterns)` -> empty.
  - `grep DATA_ROOT/paper_01` -> code/task text references only.
- 2026-03-01 20:46: Proceeding with allowlist stage/commit/sync sequence.

## Blockers
- None at audit stage.

## Links
- `manifest/manifest.csv`
- `docs/ANALYSIS_PLAN.md`
- `R/functions/init.R`
- `scripts/termux/*.sh`
