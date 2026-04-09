# K65: duplicate mapping resolution policy

## Context

- K62 identified large duplicate-risk signals in
  `Quantify-FOF-Utilization-Costs/data/VARIABLE_STANDARDIZATION.csv`.
- K63 defined the governing status model and frozen-only default pipeline rule.
- K64 removed artifact/redacted/duplicate-key rows and flagged the remaining
  duplicate-`standard_variable` cases without resolving them.
- K65 is the separate follow-up for deciding how duplicate-standard mappings
  may be resolved under explicit governance, without reopening K63 or silently
  extending K64 cleanup.

## Inputs

- `tasks/04-done/K62_variable_standardization_governance_audit.md`
- `tasks/04-done/K62_variable_standardization_governance_audit.evidence.md`
- `tasks/04-done/K63_variable_standardization_status_rule_and_cleanup.md`
- `tasks/04-done/K63_variable_standardization_status_rule_and_cleanup.evidence.md`
- `tasks/04-done/K64_variable_standardization_phase2_controlled_cleanup.md`
- `tasks/04-done/K64_variable_standardization_phase2_controlled_cleanup.evidence.md`
- `Quantify-FOF-Utilization-Costs/data/VARIABLE_STANDARDIZATION.csv`
- `Quantify-FOF-Utilization-Costs/docs/DATA_DICTIONARY_WORKFLOW.md`
- `Quantify-FOF-Utilization-Costs/CLAUDE.md`
- `Quantify-FOF-Utilization-Costs/docs/evidence_bundle_template.md`
- `tasks/_template.md`

## Outputs

- A policy-only task that defines how duplicate `standard_variable` mappings
  may be reviewed, classified, and resolved.
- A K65 evidence bundle prepared from the reusable template.
- A decision-ready rule set covering:
  - which duplicate patterns are acceptable vs unacceptable
  - whether some duplicates are aliases, longitudinal repeats, or true
    conflicts
  - who can approve a duplicate resolution
  - what evidence is required before any CSV resolution task is authorized

## Proposed Scope

- K65 must stay at policy/rule level and must not edit
  `VARIABLE_STANDARDIZATION.csv`.
- K65 may inventory duplicate classes and propose a governed resolution model.
- K65 must not silently choose a winning mapping among duplicate rows.
- K65 must preserve the K63 frozen-only default pipeline rule.
- K65 may recommend a later execution task only after duplicate classes and
  approval rules are explicit.

## Definition of Done (DoD)

- K65 remains separate from K64 and does not reopen cleanup execution.
- Duplicate-resolution governance is made explicit before any duplicate rows are
  modified.
- The task states who can approve duplicate resolution and what evidence is
  required.
- A K65 evidence bundle exists from the start and is ready for a policy-only
  audit.

## Log

- 2026-04-09 01:30:00 Created as a backlog follow-up to K64 for duplicate
  mapping resolution policy after artifact cleanup completed.

## Blockers

- K65 must not edit `VARIABLE_STANDARDIZATION.csv`.
- K65 must not weaken the frozen-only default pipeline rule.
- K65 must not resolve duplicates by intuition or by convenience.

## Links

- `tasks/04-done/K62_variable_standardization_governance_audit.md`
- `tasks/04-done/K62_variable_standardization_governance_audit.evidence.md`
- `tasks/04-done/K63_variable_standardization_status_rule_and_cleanup.md`
- `tasks/04-done/K63_variable_standardization_status_rule_and_cleanup.evidence.md`
- `tasks/04-done/K64_variable_standardization_phase2_controlled_cleanup.md`
- `tasks/04-done/K64_variable_standardization_phase2_controlled_cleanup.evidence.md`
- `Quantify-FOF-Utilization-Costs/data/VARIABLE_STANDARDIZATION.csv`
- `Quantify-FOF-Utilization-Costs/docs/DATA_DICTIONARY_WORKFLOW.md`
- `Quantify-FOF-Utilization-Costs/CLAUDE.md`
- `Quantify-FOF-Utilization-Costs/docs/evidence_bundle_template.md`
