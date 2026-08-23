# Task: Validate the lightweight smoke-gate path

## State

- State: `01-ready`
- Type: CI integration probe
- Scope: task-only documentation change

## Purpose

Validate the path-aware smoke gate introduced by PR #141 in GitHub Actions.
This task-only pull request must start the required workflow without running the
heavy K scripts smoke tests.

## Acceptance criteria

- `Detect Smoke-Relevant Changes` passes.
- `Run K Scripts Smoke Tests` is skipped and does not run the heavy test suite.
- The required workflow completes successfully.
- The pull request remains mergeable.
- No analysis, data, output, manifest, or workflow files are changed.

The probe does not need to be merged after the integration result is recorded.
