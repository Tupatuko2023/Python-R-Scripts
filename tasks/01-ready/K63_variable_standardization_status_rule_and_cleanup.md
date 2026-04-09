# K63: variable standardization status governance rule (Phase 1)

## Context

- K62 established that
  `Quantify-FOF-Utilization-Costs/data/VARIABLE_STANDARDIZATION.csv` mixes
  frozen-like mappings, `TBD` rows, artifact rows, redacted-source rows, and
  duplicate signals without an explicit lifecycle/status field.
- K62 also showed that only `19 / 493` data rows appear frozen-like, while
  `474` rows remain outside a clearly governed frozen state.
- The main governance bug is not a single bad mapping but the absence of an
  explicit state transition for `INFERRED -> human verification -> freeze`.
- K63 is now released only for Phase 1:
  define and lock an explicit governance rule and status model.
- Cleanup is intentionally deferred to a separate later task after Phase 1 is
  explicit and human-approved.
- K63 must explicitly address duplicate-risk signals, including duplicate
  `(source_dataset, original_variable)` keys and duplicate
  `standard_variable` values, but only as governance inputs in this phase.

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
  status rules before any CSV cleanup is accepted.
- A K63 evidence bundle for a Phase 1-only governance-rule task.
- A narrow handoff specification for a later cleanup task that stays outside
  K63 scope.

## Proposed Scope

- K63 must define an explicit status vocabulary, for example:
  `frozen`, `inferred`, `tbd`, `artifact`, and any additional status only if it
  is justified by the current CSV and documentation.
- K63 must document:
  - what each status means
  - who is allowed to promote a row toward `frozen`
  - what evidence is required for promotion
  - whether pipeline consumption is restricted to `frozen` rows only
- K63 may define what a later cleanup task is allowed to cover, including:
  - `Unnamed:*` artifact rows
  - numeric/list-artifact rows
  - duplicate source/original keys
  - duplicate `standard_variable` values
  - redacted/unclear-source rows
- K63 must not perform cleanup and must not silently invent new standard names.

## Definition of Done (DoD)

- K63 remains separate from K62 and does not reopen the completed audit.
- K63 is explicit Phase 1 only; CSV cleanup is deferred to a later task.
- Duplicate-risk handling is treated as a first-class governance concern, not a
  side note.
- The task states whether the pipeline may consume only `frozen` rows or some
  narrower governed subset.
- Any future CSV edits are blocked until the K63 governance rule is explicit
  and human-approved.
- A K63 evidence bundle exists from the start for the Phase 1 execution.

## Log

- 2026-04-09 00:00:00 Created as a backlog follow-up to K62 to separate
  governance-rule definition from any later CSV cleanup.
- 2026-04-09 00:10:00 Released to `tasks/01-ready/` as a Phase 1-only
  governance-rule task; cleanup remains deferred to a separate later task.

## Blockers

- K63 must not edit
  `Quantify-FOF-Utilization-Costs/data/VARIABLE_STANDARDIZATION.csv` in this
  phase.
- K63 must not invent new standard names or silently freeze inferred rows.
- Duplicate/artifact cleanup must be deferred to a separate later task rather
  than bundled into K63 execution.

## Links

- `tasks/04-done/K62_variable_standardization_governance_audit.md`
- `tasks/04-done/K62_variable_standardization_governance_audit.evidence.md`
- `Quantify-FOF-Utilization-Costs/data/VARIABLE_STANDARDIZATION.csv`
- `Quantify-FOF-Utilization-Costs/docs/DATA_DICTIONARY_WORKFLOW.md`
- `Quantify-FOF-Utilization-Costs/CLAUDE.md`
- `Quantify-FOF-Utilization-Costs/docs/evidence_bundle_template.md`
