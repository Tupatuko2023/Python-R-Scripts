
# TASK: Sync, Push, and Clean Repository

**Status**: 01-ready
**Assigned**: Gemini
**Created**: 2026-01-30

## OBJECTIVE

Synchronize local repository state with remote origin, push pending changes, verify branch status, and clean up the local environment to match 'remote origin main' state. This enforces the 'Remote Sync Rule' from WORKFLOW.md.

## INPUTS

* WORKFLOW.md (Remote Sync Rule)
* Local git repository state
* Remote git repository (origin)

## STEPS

1. Verify local git status (ensure no uncommitted critical changes outside of task scope).
2. Execute Remote Sync Rule steps (from WORKFLOW.md):
* Local changes finalized.
* Synchronize: 'git pull origin main --rebase'
* Publish: 'git push origin [current_branch]'


3. Verify remote reflects the current state.
4. Clean up merged local branches or artifacts not tracked in git.
5. Ensure local HEAD is aligned with origin/main (if applicable) or current feature branch is fully synced.

## ACCEPTANCE CRITERIA

* [ ] 'git status' is clean.
* [ ] Local changes are successfully pushed to remote.
* [ ] Local history is consistent with 'origin/main'.
* [ ] No untracked/stale files remain in critical directories.
