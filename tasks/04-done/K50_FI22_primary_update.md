# K50: FI_22 primary frailty update (ANALYSIS_PLAN.md)

## Context

- Post-hoc workflow correction for an already executed documentation change.
- The completed work updated `Fear-of-Falling/docs/ANALYSIS_PLAN.md` so that
  `frailty_index_fi` / `FI_22` is the primary frailty measure and
  Fried-inspired proxy terms are restricted to fallback / sensitivity use.
- Audit conclusion: the document change itself exists, but it was not
  previously traceable through the required `tasks/` workflow.

## Inputs

- `WORKFLOW.md`
- `agent_workflow.md`
- `tasks/_template.md`
- `Fear-of-Falling/docs/ANALYSIS_PLAN.md`
- `Fear-of-Falling/R-scripts/K40/K40_FI_KAAOS.R`

## Outputs

- Auditable retroactive task record for the FI_22 analysis-plan update
- Workflow path from `tasks/00-backlog/` forward, if the human decides to
  formalize review and completion

## Definition of Done (DoD)

- Task exists in the shared `tasks/` structure.
- Task clearly describes the already executed FI_22-primary documentation
  change.
- Task makes explicit that the original work was not initially task-gated.
- No further analysis-document edits are made as part of this process fix.

## Log

- 2026-04-04 00:00:00 Retroactive task created after audit concluded that the FI_22 analysis-plan change was not traceable through the required `tasks/` workflow.

## Blockers

- Workflow compliance cannot be restored retroactively for the original start of
  work; this task only repairs the audit trail from this point forward.

## Links

- `Fear-of-Falling/docs/ANALYSIS_PLAN.md`
- `Fear-of-Falling/R-scripts/K40/K40_FI_KAAOS.R`
