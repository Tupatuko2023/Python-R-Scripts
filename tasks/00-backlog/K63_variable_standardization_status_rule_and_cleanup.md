# K63: variable standardization status rule and controlled cleanup

## Context

- K62 established that
  `Quantify-FOF-Utilization-Costs/data/VARIABLE_STANDARDIZATION.csv` mixes
  frozen-like mappings, `TBD` rows, artifact rows, redacted-source rows, and
  duplicate signals without an explicit lifecycle/status field.
- K62 also showed that only `19 / 493` data rows appear frozen-like, while
  `474` rows remain outside a clearly governed frozen state.
- The main governance bug is not a single bad mapping but the absence of an
  explicit state transition for `INFERRED -> human verification -> freeze`.
- K63 is therefore a two-phase follow-up:
  - Phase 1: define and lock an explicit governance rule and status model.
  - Phase 2: perform only the cleanup that is authorized by that model.
- K63 must explicitly address duplicate-risk signals, including duplicate
  `(source_dataset, original_variable)` keys and duplicate
  `standard_variable` values.

## Inputs

- `tasks/04-done/K62_variable_standardization_governance_audit.md`
- `tasks/04-done/K62_variable_standardization_governance_audit.evidence.md`
- `Quantify-FOF-Utilization-Costs/data/VARIABLE_STANDARDIZATION.csv`
- `Quantify-FOF-Utilization-Costs/docs/DATA_DICTIONARY_WORKFLOW.md`
- `Quantify-FOF-Utilization-Costs/CLAUDE.md`
- `Quantify-FOF-Utilization-Costs/docs/evidence_bundle_template.md`
- `tasks/_template.md`

## Outputs

- A decision-ready execution record for introducing explicit mapping-governance
  status rules before any broad CSV cleanup is accepted.
- A K63 evidence bundle that separates Phase 1 governance-rule work from any
  later Phase 2 cleanup authorization.
- A narrow fix plan that can later distinguish:
  - status-model introduction
  - artifact segregation/removal
  - duplicate handling
  - human-verification checkpoints for freeze promotion

## Proposed Scope

- Phase 1 must define an explicit status vocabulary, for example:
  `frozen`, `inferred`, `tbd`, `artifact`, and any additional status only if it
  is justified by the current CSV and documentation.
- Phase 1 must document:
  - what each status means
  - who is allowed to promote a row toward `frozen`
  - what evidence is required for promotion
  - whether pipeline consumption is restricted to `frozen` rows only
- Phase 2 may only begin after Phase 1 is explicit and human-approved.
- Phase 2 may cover:
  - `Unnamed:*` artifact rows
  - numeric/list-artifact rows
  - duplicate source/original keys
  - duplicate `standard_variable` values
  - redacted/unclear-source rows
- K63 must not silently invent new standard names during cleanup.

## Definition of Done (DoD)

- K63 remains separate from K62 and does not reopen the completed audit.
- The two-phase model is explicit in the task record before execution starts.
- Duplicate-risk handling is treated as a first-class governance concern, not a
  side note.
- Any future CSV edits are blocked until Phase 1 governance rules are made
  explicit and human-approved.
- A K63 evidence bundle exists from the start and is ready to capture either a
  Phase 1-only execution or a later split into additional follow-up tasks.

## Log

- 2026-04-09 00:00:00 Created as a backlog follow-up to K62 to separate
  governance-rule definition from any later CSV cleanup.

## Blockers

- K63 must not start by directly editing
  `Quantify-FOF-Utilization-Costs/data/VARIABLE_STANDARDIZATION.csv` without an
  explicit Phase 1 governance-rule decision.
- K63 must not invent new standard names or silently freeze inferred rows.
- If the governance rule cannot be made explicit within K63 scope, Phase 2
  cleanup must be deferred to a later task rather than forced through.

## Links

- `tasks/04-done/K62_variable_standardization_governance_audit.md`
- `tasks/04-done/K62_variable_standardization_governance_audit.evidence.md`
- `Quantify-FOF-Utilization-Costs/data/VARIABLE_STANDARDIZATION.csv`
- `Quantify-FOF-Utilization-Costs/docs/DATA_DICTIONARY_WORKFLOW.md`
- `Quantify-FOF-Utilization-Costs/CLAUDE.md`
- `Quantify-FOF-Utilization-Costs/docs/evidence_bundle_template.md`
