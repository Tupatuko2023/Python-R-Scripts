# K64: variable standardization phase 2 controlled cleanup

## Context

- K62 audited `Quantify-FOF-Utilization-Costs/data/VARIABLE_STANDARDIZATION.csv`
  and showed that artifact rows, duplicate-risk rows, redacted-source rows, and
  non-frozen mappings are mixed in one table.
- K63 Phase 1 fixed the governance-definition bug by documenting explicit
  statuses (`frozen`, `inferred`, `tbd`, `artifact`), a promotion rule toward
  `frozen`, a frozen-only default pipeline rule, and explicit cleanup deferral.
- K64 is the separate follow-up for controlled cleanup under those K63 rules.
- K64 must not reopen K63 governance-definition work or silently override the
  frozen-only policy.

## Inputs

- `tasks/04-done/K62_variable_standardization_governance_audit.md`
- `tasks/04-done/K62_variable_standardization_governance_audit.evidence.md`
- `tasks/04-done/K63_variable_standardization_status_rule_and_cleanup.md`
- `tasks/04-done/K63_variable_standardization_status_rule_and_cleanup.evidence.md`
- `Quantify-FOF-Utilization-Costs/data/VARIABLE_STANDARDIZATION.csv`
- `Quantify-FOF-Utilization-Costs/docs/DATA_DICTIONARY_WORKFLOW.md`
- `Quantify-FOF-Utilization-Costs/docs/ANALYSIS_PLAN.md`
- `Quantify-FOF-Utilization-Costs/CLAUDE.md`
- `Quantify-FOF-Utilization-Costs/docs/evidence_bundle_template.md`
- `tasks/_template.md`

## Outputs

- A decision-ready cleanup task scoped only to CSV rows that K62/K63 already
  identified as non-pipeline-eligible or governance-risky.
- A K64 evidence bundle prepared from the reusable template.
- A controlled cleanup plan covering only:
  - `Unnamed:*` / header-artifact rows
  - numeric/list-artifact rows
  - duplicate `(source_dataset, original_variable)` keys
  - duplicate `standard_variable` values
  - redacted/unclear-source rows
  - any explicit status-column adoption only if human-approved in this phase

## Proposed Scope

- K64 may clean or segregate only rows that are outside default pipeline use
  under K63 rules.
- K64 must preserve the frozen-only default pipeline rule from K63.
- K64 must not invent new standard names.
- K64 must not silently promote `inferred` or `tbd` rows to `frozen`.
- If a status column or equivalent explicit field is added to the CSV, that
  change must be deliberate, documented, and human-approved within K64 scope.

## Definition of Done (DoD)

- K64 remains separate from K63 and does not reopen the completed governance
  definition task.
- Cleanup scope is limited to artifact, duplicate, redacted-source, and other
  explicitly governed non-frozen rows.
- Any CSV changes remain consistent with the K63 status model and pipeline
  restriction.
- A K64 evidence bundle exists from the start and is ready to capture the
  cleanup diff and approvals.

## Log

- 2026-04-09 00:40:00 Created as a backlog follow-up to K63 for Phase 2
  controlled cleanup under the explicit status-governance model.

## Blockers

- K64 must not start before human approval of the cleanup scope.
- K64 must not weaken the frozen-only default pipeline rule.
- K64 must not bundle unrelated naming refactors or new variable invention into
  cleanup work.

## Links

- `tasks/04-done/K62_variable_standardization_governance_audit.md`
- `tasks/04-done/K62_variable_standardization_governance_audit.evidence.md`
- `tasks/04-done/K63_variable_standardization_status_rule_and_cleanup.md`
- `tasks/04-done/K63_variable_standardization_status_rule_and_cleanup.evidence.md`
- `Quantify-FOF-Utilization-Costs/data/VARIABLE_STANDARDIZATION.csv`
- `Quantify-FOF-Utilization-Costs/docs/DATA_DICTIONARY_WORKFLOW.md`
- `Quantify-FOF-Utilization-Costs/docs/ANALYSIS_PLAN.md`
- `Quantify-FOF-Utilization-Costs/CLAUDE.md`
- `Quantify-FOF-Utilization-Costs/docs/evidence_bundle_template.md`
