# Task: K05 template standardization and smoke validation

## Status

00-backlog

## Classification

Legacy/deferred task. This task is outside the active K50 scope defined by
`docs/ANALYSIS_PLAN.md`, where the current primary outcome is
`locomotor_capacity`. Do not move this task to ready or execute it without a new
explicit human decision and a documented compatibility review against the
current `locomotor_capacity`, `z3`, `FI_22`, and K50 modeling architecture.

## Workflow

Follow `agent_workflow.md`. Only a task in `tasks/01-ready/` may be started.
The agent moves the task to `tasks/02-in-progress/` before work and to
`tasks/03-review/` after reporting. Only a human may move the task to
`tasks/04-done/`.

## Scope

- Primary target: `R-scripts/K05_MAIN/K05_MAIN.V1_wide-ancova.R` and directly
  related K05 template/header conventions.
- Existing legacy `R-scripts/K5/` context only as naming/provenance background.
- K05 output discipline, manifest rows, `sessionInfo()` or `renv` diagnostics,
  and minimal QC/smoke validation.
- Historical note only: K05 is not part of the active
  `docs/ANALYSIS_PLAN.md` K50 analysis line unless a later human decision
  updates the plan compatibility status.

## Objective

Standardize the K05 script or template to the `CLAUDE.md` Standard Script Intro
structure while preserving analysis logic. After human ready approval, run a
minimal smoke validation, write artifacts under the K05 script-label output
standard, and add exactly one manifest row per artifact.

The locked analysis strategy is wide-data ANCOVA primary analysis for
12-month follow-up adjusted for baseline. Use baseline `ToimintaKykySummary0`,
follow-up `ToimintaKykySummary2`, and delta
`ToimintaKykySummary2 - ToimintaKykySummary0` only after the variables are
confirmed from the data dictionary or codebook context.

## Constraints

- Do not modify raw data.
- Keep changes minimal, reversible, and documented.
- Do not commit or push unless separately authorized.
- Do not expose secrets or participant-level data.
- Do not modify K06-K16 scripts or tasks as part of this task.
- Do not invent variables; verify `data_dictionary.csv` or codebook context
  before any variable-using analysis change.
- Derive `FOF_status` only from verified `kaatumisenpelkoOn` semantics or a
  data-confirmed equivalent column.
- Do not label or recode `sex` without verifying the source coding.
- Treat `R-scripts/K5/` as reference-only legacy context unless a separate
  approved task authorizes edits there.
- Follow the `CLAUDE.md` QC minimum, including output, manifest,
  `sessionInfo()` or `renv` diagnostic discipline.
- Do table-to-text crosschecks before writing or updating result text.
- Do not commit generated outputs, raw data, manifest rows, or `renv.lock`
  unless separately approved.
- Do not execute this task from backlog. A later K05 run requires a new explicit
  human approval, a plan-compatibility review, and a documented re-evaluation of
  purpose, expected outputs, and effects on the active K50 analysis
  architecture.

## Acceptance Criteria

- [ ] K05 has the mandatory `CLAUDE.md` Standard Script Intro/header structure.
- [ ] The primary script path is
  `R-scripts/K05_MAIN/K05_MAIN.V1_wide-ancova.R`.
- [ ] The intro Required Vars list matches the code `req_cols` check 1:1.
- [ ] Analysis logic is preserved except for necessary path/header/template
  standardization.
- [ ] Wide-data primary analysis remains ANCOVA on 12-month follow-up adjusted
  for baseline.
- [ ] Baseline `ToimintaKykySummary0`, follow-up `ToimintaKykySummary2`, delta
  derivation, `FOF_status`, and `sex` coding are verified before use.
- [ ] QC minimum covers required columns and types, unique IDs in the wide data,
  allowed `FOF_status` values, delta derivation, and missingness by FOF group.
- [ ] A minimal smoke validation runs after the task is moved to
  `tasks/01-ready/` by a human.
- [ ] Artifacts are written under
  `R-scripts/K05_MAIN/outputs/<script_label>/` or the K05 standard path
  confirmed from project documentation.
- [ ] Each generated artifact has exactly one valid `manifest/manifest.csv` row.
- [ ] `sessionInfo()` and `renv` diagnostics are saved according to `CLAUDE.md`.
- [ ] No raw data, K06-K16 files, unrelated analysis code, generated outputs,
  `manifest/manifest.csv`, or `renv.lock` are committed without separate
  approval.
- [ ] Before any future ready move, a human confirms that K05 is compatible with
  the active `docs/ANALYSIS_PLAN.md` K50 scope or explicitly changes the
  analysis plan.

## Agent Report

Not started.

## Log

- 2026-07-18T20:01:10+0300 Created from repo-scan gate after confirming no
  existing K05 task in `tasks/` and no task was eligible to start in this run.
- 2026-07-18T20:10:00+0300 Human review approved the K05 task and moved it to
  `tasks/01-ready/`.
- 2026-07-18T20:24:00+0300 Human workflow correction reversed the ready move:
  active `docs/ANALYSIS_PLAN.md` scope is K50 with `locomotor_capacity` as the
  current primary outcome, so K05 was deferred to `tasks/00-backlog/`.

## Blockers

None.
