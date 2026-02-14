# TASK: Sync, Push, and Clean Repository

**Status**: 03-review
**Assigned**: Gemini
**Created**: 2026-01-30

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

## LOG

* 2026-02-14T16:44:15+02:00: Task moved to 02-in-progress. Starting sync.
* $date_iso: Sync completed, CI verified (success). Moving to 03-review.

## ACCEPTANCE CRITERIA

* [x] 'git status' is clean.
* [x] Local changes are successfully pushed to remote.
* [x] **GitHub Actions workflow for the latest commit has passed (Status: success).**
* [x] Local history is consistent with 'origin/main'.
* [x] No untracked/stale files remain in critical directories.
