# Task: Rerun K51 Table 1 and K53 Table 2 manuscript tables

## Status

backlog

## Workflow

Follow `agent_workflow.md`. Only a task in `tasks/01-ready/` may be started.
The agent moves the task to `tasks/02-in-progress/` before work and to
`tasks/03-review/` after reporting. Only a human may move the task to
`tasks/04-done/`.

## Scope

- K51 manuscript-facing analytic WIDE modeled Table 1.
- K53 authoritative WIDE Table 2.
- K51 linkage decision dependency and K50 modeled cohort provenance.

## Objective

Regenerate manuscript-facing Table 1 and Table 2 after final cohort/source
confirmation, then verify headers, model-N audit, input provenance, and
table-to-text consistency.

## Constraints

- Do not modify raw data.
- Keep changes minimal, reversible, and documented.
- Do not commit or push unless separately authorized.
- Do not expose secrets or participant-level data.
- Do not change K51 three-key linkage handling unless a separate approved task
  explicitly authorizes it.

## Acceptance Criteria

- [ ] K51 Table 1 is rerun only after the K51 linkage decision is resolved or
  explicitly deemed irrelevant.
- [ ] K53 Table 2 is rerun from the approved K50 WIDE modeled cohort source.
- [ ] Table headers, receipts, and model-N audit agree.
- [ ] `manifest/manifest.csv` receives exactly one valid row per new artifact.
- [ ] No raw data or unrelated analysis code is modified.

## Agent Report

Not started.

## Log

- 2026-07-18T18:01:14+0300 Created from repository audit follow-up: K51/K53
  manuscript table artifacts were present but untracked and need a locked rerun
  before submission export.

## Blockers

None.
