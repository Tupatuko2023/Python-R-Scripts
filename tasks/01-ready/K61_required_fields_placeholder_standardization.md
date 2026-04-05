# K61: required-fields placeholder standardization

## Context

- This is a new, separate task and must not reopen or extend K60.
- `Quantify-FOF-Utilization-Costs/docs/ANALYSIS_PLAN.md` explicitly says "Do not
  guess" and requires analysis variables to come from
  `data/VARIABLE_STANDARDIZATION.csv`.
- The same document still contains placeholder-style required-fields entries
  that look like pseudo-standard names rather than locked mapped variables,
  including `person*time`, `morbidity__ / comorbidity**`, and `prior_falls**`.
- This debt was intentionally deferred from K60 because K60 only harmonized the
  paper_02 frailty line; K61 is the narrow follow-up task for documentation
  hardening only.

## Inputs

- `Quantify-FOF-Utilization-Costs/docs/ANALYSIS_PLAN.md`
- `Quantify-FOF-Utilization-Costs/docs/evidence_bundle_template.md`
- `Quantify-FOF-Utilization-Costs/CLAUDE.md`
- `tasks/_template.md`

## Outputs

- A scoped workflow record for removing placeholder-style pseudo-standard names
  from the paper_02 required-fields / standardization sections.
- A completed K61 evidence bundle prepared from the reusable template.
- A minimal doc-only update in `ANALYSIS_PLAN.md` that replaces
  placeholder-style pseudo-standard names with explicit
  `KB missing; needs standardization mapping before run` wording.

## Definition of Done (DoD)

- The task exists as a new standalone workflow item and was executed only after
  release to `tasks/01-ready/`.
- The task remains documentation-only and does not change analysis code.
- The task references the "Do not guess" rule and keeps final variable locking
  tied to standardization mapping rather than invented English aliases.
- The placeholder risks `person*time`, `morbidity__ / comorbidity**`, and
  `prior_falls**` are removed or rewritten in `ANALYSIS_PLAN.md`.
- A completed K61 evidence bundle exists and is based on the reusable template.
- The document diff is minimal and limited to required-fields /
  standardization wording.

## Log

- 2026-04-05 00:00:00 Created as a backlog task for placeholder-style
  required-fields cleanup after K60 intentionally deferred this
  documentation-only debt.
- 2026-04-05 00:15:00 Released to `tasks/01-ready/` and executed as a
  documentation-only cleanup.
- 2026-04-05 00:20:00 Replaced placeholder-style pseudo-standard names in
  `Quantify-FOF-Utilization-Costs/docs/ANALYSIS_PLAN.md` with explicit
  `KB missing; needs standardization mapping before run` wording without
  inventing new standardized variable names.

## Blockers

- K61 must not invent replacement standard names; final naming must come from
  `data/VARIABLE_STANDARDIZATION.csv` or an equivalent approved mapping source.
- Execution cleanup is complete; any further work should be limited to review,
  commit / sync, or later follow-up tasks if additional placeholder debt is
  discovered elsewhere.

## Links

- `Quantify-FOF-Utilization-Costs/docs/ANALYSIS_PLAN.md`
- `Quantify-FOF-Utilization-Costs/docs/evidence_bundle_template.md`
- `Quantify-FOF-Utilization-Costs/CLAUDE.md`
