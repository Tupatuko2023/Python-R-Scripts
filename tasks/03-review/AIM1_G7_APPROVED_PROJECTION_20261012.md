# AIM1 G7 approved operational projection

## Context

Owner approved publication of exactly six G7 decision metadata fields on 2026-10-12.
This task mirrors the approved decision into the AIM1 Guidance Package; it does
not change scientific authority or authorize analysis.

## Inputs

- Owner-approved six-field scope in the task packet `aim1-g7-ready-task-and-publication-20261012`.
- Private six-field review artifacts validated against canonical origin/main.
- Existing AIM1 Analysis Guidance Package and repository governance.

## Outputs

- `AIM1_ANALYSIS_GUIDANCE_PACKAGE/ANALYSIS_DECISIONS.md`
- `AIM1_ANALYSIS_GUIDANCE_PACKAGE/EXECUTION_PLAN.md`
- Governed PR for the bounded decision-only projection.

## Definition of Done (DoD)

- Only the six approved fields are projected: G7_PRIMARY ADOPTED;
  baseline age and sex; E1-E4 scope; E5/E6 NEEDS_VERIFICATION;
  causal minimal sufficiency NOT_CLAIMED; analysis authorization NO.
- Existing G4 routing and all other open gates remain unchanged.
- Protected handoff and private preparation artifacts are excluded from the diff.
- Static, routing, scope and lifecycle checks pass; K18/QC is not applicable.
- Work moves to review for human approval; agent does not approve its own work.

## Log

- 2026-10-12T09:37:30+00:00 Static field/scope/routing checks PASS; git diff --check PASS; tools/run-gates.sh --mode pre-push --smoke PASS. K18/QC NOT APPLICABLE: documentation-only projection.
- 2026-10-12T09:37:30+00:00 Local markdownlint unavailable (npx --no-install); required GitHub markdownlint workflow will validate PR.
- 2026-10-12T09:37:30+00:00 Moved IN_PROGRESS -> REVIEW for human PR review.

- 2026-10-12T09:36:29+00:00 Moved READY -> IN_PROGRESS before Guidance Package implementation.

- 2026-10-12T09:36:20+00:00 READY task created by Owner direction; source classification and scientific decision approvals already granted.

## Blockers

- No local markdownlint binary; CI markdownlint remains required.
- Human PR review and branch protection remain mandatory.

## Links

- AIM1 Guidance Package (repository-relative paths above).
