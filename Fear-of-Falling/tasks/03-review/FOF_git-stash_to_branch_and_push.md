# FOF: Move git stash to new branch and push/merge

## Context
Materialize existing stash (`stash@{0}`) into a dedicated branch, push to origin, and attempt merge to `main` if allowed.

## Inputs
- Base branch: `main`
- Stash: `stash@{0}` (`WIP preserve: local scripts/docs/logs before cleanup`)
- New branch: `wip/stash-20260225`

## Outputs
- Branch created and stash applied
- Branch pushed to origin
- Merge attempt to main recorded

## Definition of Done (DoD)
- Stash applied on branch and pushed
- No output artifacts/logs committed
- Task moved to `03-review` with command log and result

## Log
- 2026-02-25 10:58: Created task file and moved workflow state to in-progress.
- 2026-02-25 10:59: Verified `main` is up to date (`git pull --ff-only origin main`).
- 2026-02-25 10:59: Verified `stash@{0}` exists and inspected stats/diff.
- 2026-02-25 11:00: Created `wip/stash-20260225` from `main` and applied `stash@{0}`.
- 2026-02-25 11:00: Excluded runtime logs from commit and prepared push/merge.

## Blockers
- None at task execution time.

## Links
- Branch: `wip/stash-20260225`
