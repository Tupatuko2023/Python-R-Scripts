# Task Sync Cleanup

## Context
Repo state needs synchronization and cleanup after local changes. This task follows the "Remote Sync Rule" from `WORKFLOW.md`.

## Inputs
- PowerShell 7.0 environment
- Git repository status

## Outputs
- Clean repository tree
- Synchronized with origin/main
- CI status check

## Definition of Done (DoD)
- `git status --porcelain` is empty (or only expected changes)
- `git pull origin main --rebase` successful
- `git submodule update --init --recursive` successful
- `git push origin main` successful
- Task moved to `tasks/04-done/`

## Log

- 2026-02-14 12:00:00 Task created.
- 2026-02-14 12:01:00 Moved to 02-in-progress. Started PowerShell sync protocol.

## Blockers
None.

## Links
- [WORKFLOW.md](../../WORKFLOW.md)
