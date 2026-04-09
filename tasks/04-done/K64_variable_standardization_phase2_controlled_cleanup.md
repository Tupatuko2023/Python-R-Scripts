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

## Allowed Operations (Phase 2)

- Remove rows where the effective governed role is `artifact` and the row has
  no analytic meaning.
- Segregate artifact, duplicate-risk, and redacted/unclear-source rows from
  the active mapping set when traceability is preserved.
- Flag duplicate mappings for governed handling rather than silently choosing a
  winner, unless a documented resolution rule already exists inside K64 scope.
- Introduce an explicit status column or equivalent field only if the change
  does not silently alter mapping semantics and is documented as part of the
  cleanup design.

## Forbidden Operations

- Promote any row to `frozen` during cleanup.
- Invent new `standard_variable` names.
- Resolve duplicate mappings without a documented resolution rule.
- Delete risky rows in a way that destroys audit traceability.
- Expand K64 into general naming refactoring or governance-rule rewriting.

## Definition of Done (DoD)

- K64 remains separate from K63 and does not reopen the completed governance
  definition task.
- Cleanup scope is limited to artifact, duplicate, redacted-source, and other
  explicitly governed non-frozen rows.
- Any CSV changes remain consistent with the K63 status model and pipeline
  restriction.
- A K64 evidence bundle exists from the start and is ready to capture the
  cleanup diff and approvals.
- Execution reports before/after row counts and distinguishes removed,
  flagged, and unchanged rows.

## Log

- 2026-04-09 00:40:00 Created as a backlog follow-up to K63 for Phase 2
  controlled cleanup under the explicit status-governance model.
- 2026-04-09 01:00:00 Released to `tasks/01-ready/` and executed under the
  explicit allowed/forbidden operation guardrails.
- 2026-04-09 01:10:00 Removed `275` mechanically identified artifact rows
  (`Unnamed:*` and list-number rows from K62/K63-identified artifact
  datasets), flagged `167` remaining duplicate-`standard_variable` rows in
  `notes`, and left `51` rows unchanged.
- 2026-04-09 01:15:00 Resulting CSV contains `218` rows; remaining
  duplicate-key rows = `0`, remaining redacted rows = `0`, and no status-column
  adoption was performed in this phase.
- 2026-04-09 01:20:00 Execution commit `4a1620f` pushed to `origin/main`;
  evidence bundle updated with final metadata.
- 2026-04-09 01:30:00 K64 closed as a completed controlled cleanup task;
  unresolved duplicate-`standard_variable` cases move to a separate K65
  governance/policy follow-up.

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
