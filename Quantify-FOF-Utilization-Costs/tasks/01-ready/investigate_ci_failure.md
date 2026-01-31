# TASK: GitHub Actions CI Failure Investigation

**Status:** 01-ready
**Created:** 2026-01-31
**Priority:** High

## Context

The GitHub Actions CI pipeline is currently failing. We need to identify the root cause (syntax error, dependency issue, test failure, or environment mismatch) and propose a fix.

## Objectives

1. Identify the specific workflow file(s) causing the failure.
2. Retrieve and analyze the failure logs from the latest run.
3. Verify if the issue is related to the recent monorepo restructuring or R/Python environment setup.
4. Propose a fix or create a blocker issue if external dependencies are broken.

## Definition of Done (DoD)

- [ ] Root cause identified and documented in this task file.
- [ ] Fix implemented in a branch OR detailed instructions for the fix provided.
- [ ] Task file moved to `tasks/02-in-progress` during work and `tasks/03-review` when ready.
- [ ] Changes verified against `SKILLS.md` (no raw data in git, PS7 compliance).

## Resources

- `gh run list`
- `gh run view [run-id] --log`
- `.github/workflows/*.yaml`
- `WORKFLOW.md` (Branch Isolation Rule)
