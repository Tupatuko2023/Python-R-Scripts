# K60: panel frailty alignment review for paper_02

## Context

- This is a new, separate workflow task and must not reopen or extend the
  closed K50 paper_01 task.
- `Quantify-FOF-Utilization-Costs/docs/ANALYSIS_PLAN.md` currently describes
  frailty in the Aim 2 panel context primarily as a Fried-proxy in both the
  heterogeneity framing and model-specification sections.
- `Fear-of-Falling/docs/ANALYSIS_PLAN.md` was closed on the FI_22-primary line,
  with `frailty_index_fi` / `frailty_index_fi_z` treated as the primary
  frailty operationalization and simpler frailty proxies limited to fallback /
  sensitivity roles.
- The purpose of this task is to evaluate whether paper_02 should be
  harmonized to the same FI_22-primary line or whether a documented,
  panel-specific deviation should remain intentional.

## Inputs

- `Quantify-FOF-Utilization-Costs/docs/ANALYSIS_PLAN.md`
- `Fear-of-Falling/docs/ANALYSIS_PLAN.md`
- `Fear-of-Falling/R-scripts/K40/K40_FI_KAAOS.R`
- `tasks/_template.md`

## Outputs

- A scoped workflow record for reviewing frailty-line consistency between
  paper_02 and the closed paper_01 / K50 FI_22-primary decision.
- No document changes in this phase.
- If later moved to `tasks/01-ready/`, a targeted consistency review of
  paper_02 frailty language and model logic.

## Definition of Done (DoD)

- A new standalone task exists under `tasks/00-backlog/`.
- The task explicitly states that paper_02 currently uses frailty primarily as
  a Fried-proxy in the panel-data analysis plan.
- The task references the closed paper_01 / K50 FI_22-primary line as the
  comparison point.
- The task states that `Quantify-FOF-Utilization-Costs/docs/ANALYSIS_PLAN.md`
  must not be edited before the task is explicitly moved to
  `tasks/01-ready/`.
- No changes are made in this step to
  `Quantify-FOF-Utilization-Costs/docs/ANALYSIS_PLAN.md`.

## Log

- 2026-04-05 00:00:00 Created as a new backlog task for paper_02 frailty-line
  consistency review after K50 closure.
- 2026-04-05 00:30:00 Reviewed paper_02 against the closed K50 analysis-plan
  line and `K40_FI_KAAOS.R`; decision: harmonize paper_02 to the FI_22-primary
  line because the K40 contract already produces paper_02-compatible
  `frailty_index_fi` / `frailty_index_fi_z` outputs from `${DATA_ROOT}/paper_02`
  inputs, so Fried-proxy is retained only as fallback / sensitivity.

## Blockers

- Execution was blocked until a human moved the task to `tasks/01-ready/`.
- Frailty-line review is now completed; any further work should be limited to
  downstream acceptance, commit / sync, or later follow-up tasks if additional
  panel-specific documentation issues are discovered.

## Links

- `Quantify-FOF-Utilization-Costs/docs/ANALYSIS_PLAN.md`
- `Fear-of-Falling/docs/ANALYSIS_PLAN.md`
- `Fear-of-Falling/R-scripts/K40/K40_FI_KAAOS.R`
