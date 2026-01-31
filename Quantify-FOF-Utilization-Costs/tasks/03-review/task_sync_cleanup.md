
# TASK: Sync, Push, and Clean Repository

**Status**: 03-review
**Assigned**: Gemini
**Created**: 2026-01-30

## LOG

* 2026-01-31T12:05:00Z: Task moved to 02-in-progress. Initiating remote sync.
* 2026-01-31T12:35:00Z: Fixed invalid `-q` flag in `tools/check-r-syntax.sh`. Formatted and fixed Markdown linting issues across the subproject. Task moved to 03-review.

## OBJECTIVE

Synchronize local repository state with remote origin, push pending changes, verify branch status, and clean up the local environment to match 'remote origin main' state. This enforces the 'Remote Sync Rule' from WORKFLOW.md and ensures CI integrity.

## INPUTS

* WORKFLOW.md (Remote Sync Rule)
* Local git repository state
* Remote git repository (origin)

## STEPS

1. Verify local git status (ensure no uncommitted critical changes outside of task scope).
2. Execute Remote Sync Rule steps (from WORKFLOW.md):
   * Local changes finalized.
   * Synchronize: `git pull origin main --rebase`
   * Publish: `git push origin [current_branch]`

3. Verify remote integrity and CI status:
   * Ensure remote reflects the current state.
   * **Verify CI status:** Execute `gh run list --limit 1` to confirm the latest workflow triggered by the push shows 'success' (green).
   * (Optional) If running, watch progress: `gh run watch`

4. Clean up merged local branches or artifacts not tracked in git.
5. Ensure local HEAD is aligned with origin/main (if applicable) or current feature branch is fully synced.

## ACCEPTANCE CRITERIA

* [ ] 'git status' is clean.
* [ ] Local changes are successfully pushed to remote.
* [ ] **GitHub Actions workflow for the latest commit has passed (Status: success).**
* [ ] Local history is consistent with 'origin/main'.
* [ ] No untracked/stale files remain in critical directories.
