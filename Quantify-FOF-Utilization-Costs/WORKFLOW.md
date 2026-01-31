# Branch Isolation Rule

Files in tasks/02-in-progress and tasks/03-review MUST NOT be merged to main unless moved to 04-done.

## Remote Sync Rule (MANDATORY for gpa1qf-gpa4qf)

A task MUST NOT be moved to 'tasks/04-done/' until all related changes are successfully pushed to the remote repository.

1. Local changes finalized.
2. Synchronize: 'git pull origin main --rebase'
3. Publish: 'git push origin [branch_name]' (or main if permitted)
4. Verify: Ensure remote reflects the current state.
5. Close: Move task file to '04-done'.
