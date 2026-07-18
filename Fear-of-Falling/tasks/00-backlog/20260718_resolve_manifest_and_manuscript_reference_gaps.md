# Task: Resolve manifest and manuscript-reference gaps

## Status

backlog

## Workflow

Follow `agent_workflow.md`. Only a task in `tasks/01-ready/` may be started.
The agent moves the task to `tasks/02-in-progress/` before work and to
`tasks/03-review/` after reporting. Only a human may move the task to
`tasks/04-done/`.

## Scope

- `manifest/manifest.csv` quality issues identified by the broad audit.
- Missing canonical manuscript source path or export checklist.
- Explicit mapping of manuscript Figure/Table references to repository outputs.

## Objective

Create a verified manuscript-reference map and manifest-quality note so future
audits can distinguish final manuscript references from task/report references
and avoid relying on malformed or duplicate manifest rows.

## Constraints

- Do not modify raw data.
- Keep changes minimal, reversible, and documented.
- Do not commit or push unless separately authorized.
- Do not expose secrets or participant-level data.
- Do not rewrite or migrate `manifest/manifest.csv` without a separate explicit
  approval.

## Acceptance Criteria

- [ ] Canonical manuscript source path or source-of-truth export checklist is
  documented.
- [ ] Each manuscript Figure/Table reference maps to an output path or is marked
  `REFERENCED_BUT_MISSING`.
- [ ] Manifest malformed/duplicate row issues are summarized without changing
  the manifest unless separately approved.
- [ ] No raw data, analysis code, output, or manifest rows are modified.

## Agent Report

Not started.

## Log

- 2026-07-18T18:01:14+0300 Created from repository audit follow-up: the audit
  found no `manuscript/` directory and noted repeated/malformed legacy-looking
  manifest rows.

## Blockers

None.
