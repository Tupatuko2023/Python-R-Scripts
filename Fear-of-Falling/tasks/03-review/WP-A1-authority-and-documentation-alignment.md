# Task: WP-A1 Authority and Documentation Alignment

## Status

03-review

## Workflow

Follow `agent_workflow.md`. Only a task in `tasks/01-ready/` may be started.
The agent moves the task to `tasks/02-in-progress/` before work and to
`tasks/03-review/` after reporting. Only a human may move the task to
`tasks/04-done/`.

## Trigger and impact classification

- `DOCUMENTATION_ONLY`: SA-03A, SA-03D, SA-05C.
- `AUTHORITY_ALIGNMENT`: SA-01, SA-02B, SA-02C, SA-03B, SA-03C, SA-04A,
  SA-04B.

## Scope

Align authoritative documentation, decision registers, source/export receipts,
and provenance with the frozen Scientific Authority decisions. Reconcile
`docs/ANALYSIS_PLAN.md`, especially FI22 as sensitivity-only, complete-case
language, Z3 fallback status, and the 0.40 producer gate. Pin SA-01 at the
source/export/receipt/decision-register level. Do not change code, models,
cohort construction, data, results, or Figure 1.

Likely affected files are `docs/ANALYSIS_PLAN.md`, the WP-A1 decision evidence
and register, and canonical K32/K50 receipt or provenance text. Any receipt edit
must preserve its hash-pinned source identity and must not regenerate outputs.

## Objective

Make the written authority chain internally consistent without changing any
analysis result. Preserve the approved cohort hierarchy:
`SOURCE_AUTHORIZED_COHORT=535`, FOF-eligible source cohort 472, WIDE primary
population 230, and LONG 400 participants / 630 observations.

## Scientific contract that must not change

- Primary estimand is the standardized baseline-FOF group difference in mean
  12-month locomotor capacity, adjusted for baseline outcome, age, sex, and BMI.
- Primary missing-data strategy is complete-case without unsupported mechanism
  claims.
- `locomotor_capacity` remains primary; Z3 and FI22 remain sensitivity-only.
- Z3 coverage is `MIN_2_OF_3` at each timepoint and paired Z3 analysis requires
  valid baseline and 12-month scores.
- The 0.40 gate remains an implementation/export-QC safeguard, never a row
  eligibility filter.
- SA-01 is authority alignment, not a new cohort-construction decision.

## QC applicability

- Classification: NOT APPLICABLE
- Trigger or reason: documentation and authority metadata only.
- Required command when applicable: `git diff --check` and FOF preflight.
- Expected evidence: scoped documentation diff, unchanged analysis/code/output
  paths, and explicit source/export/receipt/decision-register crosscheck.

## Acceptance Criteria

- [x] Every triggering SA ID is cited with its final impact class.
- [x] FI22, complete-case, Z3, and 0.40-gate wording matches the frozen contract.
- [x] SA-01 authority is pinned without changing the 535 -> 472 -> WIDE/LONG
  hierarchy.
- [x] No model, cohort, data, result, Figure 1, or manuscript artifact changes.
- [x] Task is reported to `tasks/03-review/` only.

## Expected artifacts

- A bounded authority/documentation diff and a cross-reference table connecting
  each changed statement to its SA decision.
- A report confirming that canonical hashes, counts, and analysis outputs did
  not change.

## Dependencies and unblock condition

First downstream WP after human approval of the parent Scientific Authority and
impact-classification tasks and completion of required remote sync. It may run
before analytical changes. Completion unblocks authority-consistent wording for
later implementation receipts; it does not itself authorize implementation.

## Dependency order

1. This authority/documentation WP.
2. Identity/dedup analytical change.
3. Z3 coverage analytical change after the authoritative identity export.
4. Manuscript consumer alignment after all upstream artifacts are review-ready.

## Agent Report

Completed authority/documentation alignment only. `docs/ANALYSIS_PLAN.md` now records SA-03A historical adoption separately from prospective SA decisions; removes FI22 from primary WIDE/LONG formulas; freezes K50 as the canonical analysis entrypoint, K32 as upstream producer, and the chair-rise transform; and adds an authority contradiction-resolution log. `WP-A1-SCI-03-locomotor-construction-verification.md` retains its historical verification findings while adding a source-linked addendum for final SA-05A/B/C dispositions.

File-by-file classification: `docs/ANALYSIS_PLAN.md` is `DOCUMENTATION_ONLY` plus `AUTHORITY_ALIGNMENT` under SA-03A/B/C/D, SA-04A/B, and SA-05C; the SCI-03 addendum is authority provenance under SCI-03A/B and SA-05A/B/C. No executable behavior, data, output, manifest, Figure 1, or manuscript Results text was changed. K18/QC was NOT APPLICABLE.

## Log

- 2026-08-23T20:33:09+0300 Created in `tasks/00-backlog/` from the approved
  WP-A1 impact-classification routing; not released for implementation.
- 2026-08-24T06:00:00+0300 Released only this WP from `00-backlog` to `01-ready`, then selected it into `02-in-progress`; the other three WP files remained in backlog.
- 2026-08-24T06:00:00+0300 Reconciled authority documentation and recorded historical-versus-prospective provenance without analytical implementation.
- 2026-08-24T06:00:00+0300 Validation passed: `git diff --check`, FOF preflight, pre-push smoke, and contradiction scan; K18/QC remained NOT APPLICABLE.
- 2026-08-24T06:00:00+0300 Moved from `tasks/02-in-progress/` to `tasks/03-review/` for human review.

## Blockers

Human review, required remote sync, and human movement to `tasks/04-done/` are required before the identity/dedup analytical-change WP may be released.
