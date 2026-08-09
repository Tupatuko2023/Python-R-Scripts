# Task: FOF_WORKFLOW_CONTRACT_HARDENING

## Status

review

## Workflow

Follow `agent_workflow.md`. Only a task in `tasks/01-ready/` may be started.
The agent moves the task to `tasks/02-in-progress/` before work and to
`tasks/03-review/` after reporting. Only a human may move the task to
`tasks/04-done/`.

## Scope

Remove the completion-semantics inconsistency found in the workflow audit.
Scope is limited to the FOF workflow contract. Do not migrate comparator repos
or change analysis code, raw data, manifests, or outputs.

## Objective

Make `agent_workflow.md` express the same invariant as `tasks/_template.md`:
the agent starts only from `01-ready`, moves work through `02-in-progress`, and
leaves completed work in `03-review`; `04-done` is owned by human approval.
`WORKFLOW.md` remote-sync remains a prerequisite for final done approval but
does not transfer done authority to the agent.

## QC applicability

- Classification: NOT APPLICABLE
- Trigger or reason: Documentation/workflow contract only; no data, variable
  coding, inclusion logic, model frame, K18 code, QC code, or QC artifact change.
- Required command when applicable: None.
- Expected evidence: `git diff --check`, unified diff review, and grep showing no
  remaining normative `agent_workflow.md` rule that allows the agent to move a
  task to `04-done`.

## Constraints

- Do not modify raw data.
- Keep changes minimal, reversible, and documented.
- Do not commit or push unless separately authorized.
- Do not expose secrets or participant-level data.
- Do not modify analysis scripts, manifests, outputs, or comparator repos.

## Acceptance Criteria

- [x] `agent_workflow.md` states that the agent's normal endpoint is
  `tasks/03-review/`.
- [x] `agent_workflow.md` states that only a human moves a task from
  `tasks/03-review/` to `tasks/04-done/`.
- [x] `agent_workflow.md` preserves `WORKFLOW.md` as the remote-sync completion
  gate and does not change `WORKFLOW.md` precedence.
- [x] `tasks/_template.md` and `agent_workflow.md` are semantically aligned on
  completion semantics.
- [x] No analysis code, raw data, output, manifest, or comparator repo files are
  changed.
- [x] `git diff --check` passes.
- [x] Grep validation shows no contradictory agent-can-move-to-done rule remains
  in `agent_workflow.md`.
- [x] Task is left in `tasks/03-review/` for human approval, not moved to
  `tasks/04-done/`.

## Agent Report

Completed and left in `tasks/03-review/` for human approval.

- Changed `agent_workflow.md` only.
- K18/QC: NOT APPLICABLE — workflow documentation only; no data, analysis code,
  QC code, QC artifact, manifest, or output change.
- Validation: `git diff --check` passed.
- Validation: grep confirmed `agent_workflow.md` now ends agent work at
  `tasks/03-review/` and reserves `tasks/04-done/` for human completion.

## Log

- 2026-08-09T14:18:27+03:00 Task created in backlog from the workflow hardening
  prompt. Implementation must wait until a human moves this task to
  `tasks/01-ready/`.
- 2026-08-09T14:34:59+03:00 Human release accepted from the orchestrator prompt;
  task moved `tasks/00-backlog/` -> `tasks/01-ready/`.
- 2026-08-09T14:34:59+03:00 Agent started the ready task and moved it
  `tasks/01-ready/` -> `tasks/02-in-progress/`.
- 2026-08-09T14:35:24+03:00 Updated `agent_workflow.md` completion semantics
  to align with `tasks/_template.md` and `WORKFLOW.md`.
- 2026-08-09T14:35:24+03:00 Ran `git diff --check` and grep validation; moved
  task `tasks/02-in-progress/` -> `tasks/03-review/`.

## Blockers

None.
