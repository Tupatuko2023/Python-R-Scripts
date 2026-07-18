# Task: Rerun and validate K50 manuscript figure package

## Status

backlog

## Workflow

Follow `agent_workflow.md`. Only a task in `tasks/01-ready/` may be started.
The agent moves the task to `tasks/02-in-progress/` before work and to
`tasks/03-review/` after reporting. Only a human may move the task to
`tasks/04-done/`.

## Scope

- K50 Figure 1, Figure 2, and Supplementary Figures S1-S3.
- Existing K50 producer scripts and their documented outputs.
- Provenance, visual inspection, and table-to-text/plot-data crosschecks.

## Objective

Refresh the manuscript-facing K50 figure package from the current locked K50
analysis source, then verify that plotted values, captions, provenance notes,
and manifest rows are internally consistent.

## Constraints

- Do not modify raw data.
- Keep changes minimal, reversible, and documented.
- Do not commit or push unless separately authorized.
- Do not expose secrets or participant-level data.
- Do not change figure interpretation or model source without explicit review.

## Acceptance Criteria

- [ ] Figure 1, Figure 2, and SFIG1-SFIG3 are regenerated from approved K50
  producer scripts.
- [ ] Every regenerated figure has matching plot-data/provenance evidence where
  the producer supplies it.
- [ ] Caption/results text matches plotted values and source tables.
- [ ] `manifest/manifest.csv` receives exactly one valid row per new artifact.
- [ ] No raw data or unrelated analysis code is modified.

## Agent Report

Not started.

## Log

- 2026-07-18T18:01:14+0300 Created from repository audit follow-up:
  manuscript-facing K50 figure artifacts were present but untracked and should
  be rerun before submission export.

## Blockers

None.
