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
- 2026-02-25 11:01: Committed branch changes `56f6027` and pushed `origin/wip/stash-20260225`.
- 2026-02-25 11:02: Dropped `stash@{0}` after successful branch push.
- 2026-02-25 11:03: Merged branch into `main` with merge commit `090cf53` and pushed `origin/main`.

## Final Status
- Branch push: PASS (`origin/wip/stash-20260225`)
- Main merge: PASS (`090cf53` on `origin/main`)
- Stash handling: PASS (`stash@{0}` dropped after successful push)
- Output/log commit policy: PASS (runtime logs remained untracked and were excluded from commit)
