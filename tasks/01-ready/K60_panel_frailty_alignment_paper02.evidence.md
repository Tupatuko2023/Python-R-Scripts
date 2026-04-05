# K60 Evidence Bundle

## Purpose

This appendix packages the minimum process evidence for the K60 paper_02
frailty-alignment task so that the audit trail does not depend on reconstructing
the terminal session.

## Gating Proof

- Task created first under `tasks/00-backlog/` as
  `K60_panel_frailty_alignment_paper02.md`.
- Task was moved by explicit human approval to `tasks/01-ready/` before any
  edits to `Quantify-FOF-Utilization-Costs/docs/ANALYSIS_PLAN.md`.
- The K60 task file itself records both the original backlog creation and the
  later ready-state execution decision.

## Commit Evidence

- Commit: `de68e29`
- Message: `K60: frailty alignment decision (FI_22-primary) + log`

This commit contains:

- the paper_02 frailty-line harmonization in
  `Quantify-FOF-Utilization-Costs/docs/ANALYSIS_PLAN.md`
- the K60 task log / blocker-state update in
  `tasks/01-ready/K60_panel_frailty_alignment_paper02.md`

## Diff Summary

- Replaced Fried-primary wording with FI_22-primary wording in the
  heterogeneity objective.
- Replaced the primary frailty definition so that
  `frailty_index_fi` / `frailty_index_fi_z` is the default covariate line.
- Added K40 FI QC fields to the required-fields section.
- Replaced `frailty` placeholders in the primary count and cost templates with
  `frailty_index_fi`.
- Restricted Fried-proxy use to fallback / sensitivity contexts.
- Clarified that FI QC fields support eligibility / completeness assessment and
  may be used for analytic-sample restriction or sensitivity analyses.

## Scope Control

- No edits were made to the closed K50 paper_01 task.
- No edits were made to `Fear-of-Falling/docs/ANALYSIS_PLAN.md`.
- No code changes were made; the K40 script was used only as contract evidence.
- Changes were limited to the paper_02 analysis-plan document and K60 task
  records.

## Consistency Basis

- `Fear-of-Falling/docs/ANALYSIS_PLAN.md` already locks paper_01 to the
  FI_22-primary frailty line.
- `Fear-of-Falling/R-scripts/K40/K40_FI_KAAOS.R` explicitly builds
  `frailty_index_fi` / `frailty_index_fi_z` from `${DATA_ROOT}/paper_02`
  inputs.
- Because the FI contract already exists for paper_02-compatible inputs,
  retaining Fried-proxy as the primary paper_02 frailty line would create an
  avoidable documentation-to-pipeline mismatch.
