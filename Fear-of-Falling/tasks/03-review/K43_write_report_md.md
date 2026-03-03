# K43 Write Report Markdown

## Context

This K43 is an analysis-repo documentation task in `Fear-of-Falling`.
It is not a dissertation-repo writing task.

This task documents the already produced K43 conceptual framework figure artifacts for K42 and records deterministic reproduction and governance evidence.

Task-gate status: review (`tasks/03-review/`).

## Objective

Create `docs/reports/k43.md` as a repository-safe report that documents the K43 conceptual model artifacts and links them for manuscript/discussion use.

## Scope

In scope:
- Create report markdown only: `docs/reports/k43.md`.
- Reference only existing repository artifacts:
  - `docs/figures/conceptual_model_k42.svg`
  - `docs/figures/conceptual_model_k42.pdf`
  - `docs/figures/conceptual_model_k42_caption.txt`
- Include K42 anchor statement `corr(capacity, FI) ≈ -0.51` from existing aggregate results.
- Include deterministic reproduction commands for verification.

Out of scope:
- No new analysis models.
- No changes to R scripts.
- No patient-level exports.

## Inputs

- Existing K42 aggregate outputs and logs (already produced).
- Existing K43 figure assets and caption in `docs/figures/`.
- Existing manifest rows in `manifest/manifest.csv`.

## Outputs (Repo, Aggregate-Only)

- `docs/reports/k43.md`
- Task log updates in this card.

## Governance

- Report must not include `DATA_ROOT` paths.
- Report must not include or embed patient-level content.
- References are restricted to repository aggregate artifacts only.

## Reproduction Commands

`[TERMUX]`

```sh
cd Python-R-Scripts/Fear-of-Falling
ls -la docs/figures/conceptual_model_k42.svg docs/figures/conceptual_model_k42.pdf docs/figures/conceptual_model_k42_caption.txt
rg -n "conceptual_model_k42_(svg|pdf|caption)" manifest/manifest.csv
bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling
```

## Acceptance Criteria

- `docs/reports/k43.md` exists.
- Report contains no `DATA_ROOT` references.
- Report contains no patient-level content.
- Report references only repository artifacts under `docs/figures/` listed above.
- Report includes K42 anchor statement `corr(capacity, FI) ≈ -0.51` and states no new analyses were run.
- `bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling` exits `0`.

## Definition of Done

- Report created with sections: Purpose/Scope, Inputs, Artifact List, Governance Note, Repro Commands, Change Log.
- Task moved to `tasks/03-review/` after evidence is logged.

## Log

- 2026-03-03 07:22 created backlog task card for K43 report markdown.
- 2026-03-03 07:23 moved card `00-backlog -> 01-ready -> 02-in-progress` per gate workflow.
- 2026-03-03 07:24 created report file `docs/reports/k43.md` with sections:
  - Purpose and Scope
  - Inputs
  - Artifact List
  - Governance Note
  - Reproduction Commands
  - Change Log
- 2026-03-03 07:25 validation:
  - confirmed `docs/figures/conceptual_model_k42.(svg|pdf)` and caption exist
  - confirmed manifest contains `conceptual_model_k42_svg|pdf|caption` rows
  - `bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling` exit `0`
  - report contains no `DATA_ROOT` paths
- 2026-03-03 07:26 moved task card to `tasks/03-review/` for human approval.

## Blockers

- None.

## Links

- [K43_conceptual_model_k42_figure.md](/data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling/tasks/03-review/K43_conceptual_model_k42_figure.md)
- [conceptual_model_k42.svg](/data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling/docs/figures/conceptual_model_k42.svg)
- [conceptual_model_k42.pdf](/data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling/docs/figures/conceptual_model_k42.pdf)
- [conceptual_model_k42_caption.txt](/data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling/docs/figures/conceptual_model_k42_caption.txt)
