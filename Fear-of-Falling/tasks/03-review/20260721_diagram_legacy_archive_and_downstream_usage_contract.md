# Task: Archive legacy diagrams and document downstream usage contract

## Status

03-review

## Workflow

Follow `agent_workflow.md`. Only a task in `tasks/01-ready/` may be started.
The agent moves the task to `tasks/02-in-progress/` before work and to
`tasks/03-review/` after reporting. Only a human may move the task to
`tasks/04-done/`.

Current state: `03-review`. Implementation completed and awaiting human review.

## Scope

This task defines a future file-organization and documentation change for the
`diagram/` directory.

In scope:

- move historical diagram families into `diagram/legacy/` using `git mv`;
- create `diagram/legacy/README.md`;
- rewrite `diagram/README.md` as the current Figure 1 usage contract;
- update references and manifest paths idempotently when files move;
- validate that current K50 Figure 1 production and render paths still work.

Out of scope:

- no raw-data changes;
- no analysis model changes;
- no numeric provenance changes;
- no visible Figure 1 content changes;
- no K50 result table changes;
- no dissertation-repository changes;
- no manuscript text edits in the dissertation repository;
- no task movement to `tasks/04-done/`.

This backlog-definition task does not implement the moves.

## Objective

Simplify the Fear-of-Falling `diagram/` root by moving historical cohort-flow
sources and renders into `diagram/legacy/`, while retaining the current
authoritative `wide_long.locomotor_capacity` Figure 1 family in the root.

Document how the analysis repository owns the canonical Figure 1 source and how
`FOF-Dissertation-Project` and the AIM1 manuscript consume it through the
versioned analysis submodule.

## Current Evidence Snapshot

Read-before-implementation sources for this task:

- `WORKFLOW.md`
- `agent_workflow.md`
- `CLAUDE.md`
- `AGENTS.md`
- `PROJECT_FILE_MAP.md`
- `diagram/README.md`
- `tasks/_template.md`
- `manifest/manifest.csv`
- `R-scripts/K50/K50.FIG1_VISUAL_DUAL_BRANCH.V1_render.R`
- `tasks/03-review/20260719_k50_figure1_visual_dual_branch_rebuild.md`
- `tasks/01-ready/20260719_k50_figure1_minor_patch_and_manuscript_reconciliation.md`

Inventory checks used to scope the future implementation:

- `find diagram -maxdepth 2 -type f -printf '%p\t%s bytes\n' | sort`
- `git ls-files diagram`
- `rg -n 'paper_01_cohort_flow\.dot|render_paper_01_cohort_flow\.sh|paper_01_cohort_flow\.wide\.|paper_01_cohort_flow\.long\.|paper_01_cohort_flow\.wide_long\.' --glob '!.git/**' .`
- `rg -n 'paper_01_cohort_flow|diagram/' manifest/manifest.csv`
- `rg -n 'paper_01_cohort_flow\.dot|render_paper_01_cohort_flow\.sh' R-scripts/K50/K50.FIG1_VISUAL_DUAL_BRANCH.V1_render.R`

The current K50 dual-branch producer uses:

```text
paper_01_cohort_flow.wide_long.locomotor_capacity
```

No current producer dependency on `diagram/paper_01_cohort_flow.dot` or
`diagram/render_paper_01_cohort_flow.sh` was found in
`R-scripts/K50/K50.FIG1_VISUAL_DUAL_BRANCH.V1_render.R`.

## Target Root Inventory

After implementation, `diagram/` should contain only:

- `README.md`
- `legacy/`
- `paper_01_cohort_flow.wide_long.locomotor_capacity.dot`
- `paper_01_cohort_flow.wide_long.locomotor_capacity.resolved.dot`
- `paper_01_cohort_flow.wide_long.locomotor_capacity.pdf`
- `paper_01_cohort_flow.wide_long.locomotor_capacity.svg`
- `paper_01_cohort_flow.wide_long.locomotor_capacity.png`

An active helper may remain in `diagram/` root only if the current K50 producer
or a documented current rendering workflow directly invokes it. That dependency
must be demonstrated by source search before retaining the helper in root.

## Legacy Moves

Move tracked historical files with `git mv` into `diagram/legacy/`.

Planned legacy moves:

| Original path | New path | Status |
| --- | --- | --- |
| `diagram/paper_01_cohort_flow.dot` | `diagram/legacy/paper_01_cohort_flow.dot` | historical generic template |
| `diagram/render_paper_01_cohort_flow.sh` | `diagram/legacy/render_paper_01_cohort_flow.sh` | historical render helper if no current dependency exists |
| `diagram/paper_01_cohort_flow.long.locomotor_capacity.resolved.dot` | `diagram/legacy/paper_01_cohort_flow.long.locomotor_capacity.resolved.dot` | historical LONG-only resolved DOT |
| `diagram/paper_01_cohort_flow.long.locomotor_capacity.svg` | `diagram/legacy/paper_01_cohort_flow.long.locomotor_capacity.svg` | historical LONG-only SVG |
| `diagram/paper_01_cohort_flow.long.locomotor_capacity.png` | `diagram/legacy/paper_01_cohort_flow.long.locomotor_capacity.png` | historical LONG-only PNG |
| `diagram/paper_01_cohort_flow.wide.locomotor_capacity.resolved.dot` | `diagram/legacy/paper_01_cohort_flow.wide.locomotor_capacity.resolved.dot` | historical WIDE-only resolved DOT |
| `diagram/paper_01_cohort_flow.wide.locomotor_capacity.svg` | `diagram/legacy/paper_01_cohort_flow.wide.locomotor_capacity.svg` | historical WIDE-only SVG, if tracked or intentionally retained |
| `diagram/paper_01_cohort_flow.wide.locomotor_capacity.png` | `diagram/legacy/paper_01_cohort_flow.wide.locomotor_capacity.png` | historical WIDE-only PNG, if tracked or intentionally retained |

Before moving, verify which listed files are tracked and exist. Do not create
fake placeholder files for absent or historically untracked renders. Do not
delete legacy files or provenance.

## Legacy README Requirements

Create:

```text
diagram/legacy/README.md
```

For each retained legacy asset family, record:

- original path;
- current legacy path;
- file role;
- original producer;
- numeric or model-frame limitation;
- manuscript status;
- replacement family;
- related task or commit;
- whether rerendering is supported;
- explicit `DO_NOT_USE` or `SUPERSEDED` status.

Use `SUPERSEDED` only when the applicable human decision record supports it.
Until then, use `DO_NOT_USE`, `QC_ONLY`, or another documented current workflow
status from `diagram/README.md` and task history.

The historical WIDE-only and LONG-only families must not be presented as current
manuscript assets.

## Current Canonical Family

The current manuscript-facing family is:

```text
paper_01_cohort_flow.wide_long.locomotor_capacity.*
```

Canonical producer:

```text
R-scripts/K50/K50.FIG1_VISUAL_DUAL_BRANCH.V1_render.R
```

Canonical numeric and QC outputs:

```text
R-scripts/K50/outputs/FIG1_visual_dual_branch/
```

The `diagram/` directory is a manuscript-facing source and render handoff. It
does not replace K50 canonical analysis outputs.

## README Requirements

Rewrite `diagram/README.md` into concise operational sections:

1. Purpose and ownership.
2. Current canonical Figure 1 family.
3. Format roles.
4. Downstream consumers.
5. Cross-repository evidence.
6. Rendering and validation commands.
7. Legacy archive.
8. Manifest and update rules.

Move detailed obsolete inventory content to `diagram/legacy/README.md`.

### Current Assets Table

`diagram/README.md` must include a Current Assets table that lists only the
current `wide_long.locomotor_capacity` family:

| Asset | Role | Producer | Status |
| --- | --- | --- | --- |
| `paper_01_cohort_flow.wide_long.locomotor_capacity.dot` | editable structural source | `R-scripts/K50/K50.FIG1_VISUAL_DUAL_BRANCH.V1_render.R` | current Figure 1 source |
| `paper_01_cohort_flow.wide_long.locomotor_capacity.resolved.dot` | generated resolved DOT | same producer | generated intermediate; do not hand-edit |
| `paper_01_cohort_flow.wide_long.locomotor_capacity.pdf` | primary vector publication asset | Graphviz from resolved DOT | current publication-format candidate |
| `paper_01_cohort_flow.wide_long.locomotor_capacity.svg` | review/interchange vector asset | Graphviz from resolved DOT | current review asset |
| `paper_01_cohort_flow.wide_long.locomotor_capacity.png` | Quarto/report fallback and raster review asset | Graphviz from resolved DOT | current fallback asset |

### Canonical Ownership

State explicitly:

- the Fear-of-Falling analysis repository owns the producer, locked numeric
  provenance, editable DOT, resolved DOT, and rendered Figure 1 family;
- `FOF-Dissertation-Project` consumes the assets through a pinned analysis
  submodule;
- the dissertation repository owns manuscript wording, figure inclusion,
  caption, legend, and manuscript-wide consistency audits;
- neither repository should maintain an independently edited copy of the same
  Figure 1 artwork;
- updating the consuming submodule commit is the manuscript handoff mechanism.

### Downstream Consumers

Add a table with at least:

| Consumer | Use | Consumer path | Analysis asset | Evidence | Pin |
| --- | --- | --- | --- | --- | --- |
| `FOF-Dissertation-Project` | Dissertation manuscript and audit trail | repository-relative manuscript path | `paper_01_cohort_flow.wide_long.locomotor_capacity.*` | audit markdown paths | analysis submodule commit |
| AIM1 article | Main-paper Figure 1 | `papers/A1_fear-of-falling-physical-performance/manuscript/draft/Results_Draft_version_2.qmd` | prefer PDF; PNG for report rendering when required | Figure/manuscript crosscheck | analysis submodule commit |

Use the dissertation submodule asset path:

```text
analysis/modules/Python-R-Scripts/Fear-of-Falling/diagram/
```

Use repository-relative paths and commit hashes. Do not use local absolute
filesystem paths.

### Cross-Repository Evidence

Record repository-relative evidence paths:

```text
docs/audit/k50_figure1_figure_abstract_methods_results_supplement_crosscheck.md
docs/audit/k50_figure1_manuscript_count_audit.md
```

For each evidence record, include:

- repository name;
- path;
- audit date;
- result;
- consuming manuscript path;
- analysis submodule commit;
- dissertation commit when known.

Do not copy the full audit reports into the analysis repository. Store only the
consumer repository name, paths, audit date, audit result, and commit pins.

### Publication Format Contract

Document format roles:

- PDF: primary vector publication asset;
- SVG: review and interchange vector asset;
- PNG: Quarto/report fallback and raster review asset;
- DOT: editable structural source;
- resolved DOT: generated intermediate; do not hand-edit.

### Status Policy

The root inventory contains the current family regardless of whether workflow
status is `03_REVIEW` or `MANUSCRIPT_CANDIDATE`.

Status promotion is separate from file organization.

Do not:

- move any task to `tasks/04-done/`;
- claim publication acceptance;
- mark legacy files current;
- mark an asset `SUPERSEDED` without the applicable human decision record.

Where the completed manuscript audit supports active manuscript use, document
that fact separately from broader publication-readiness claims.

## Reference Audit Requirements

Before moving files, search:

- R scripts;
- shell scripts;
- Makefiles;
- README files;
- `PROJECT_FILE_MAP.md`;
- `manifest/manifest.csv`;
- tasks;
- CI and gates;
- tests;
- manuscript handoff documentation.

Classify each old-path reference as:

- update to legacy path;
- update to current `wide_long` path;
- preserve as historical prose;
- remove as obsolete.

No reference may be silently broken.

Minimum reference-audit commands:

```sh
rg -n 'paper_01_cohort_flow\.dot|render_paper_01_cohort_flow\.sh|paper_01_cohort_flow\.wide\.|paper_01_cohort_flow\.long\.' --glob '!.git/**' .
rg -n 'paper_01_cohort_flow|diagram/' manifest/manifest.csv
rg -n 'paper_01_cohort_flow\.dot|render_paper_01_cohort_flow\.sh' R-scripts/K50/K50.FIG1_VISUAL_DUAL_BRANCH.V1_render.R
```

Also validate the downstream submodule consumer path in
`FOF-Dissertation-Project`, but do not modify the dissertation repository in
this analysis-repository task.

## Manifest Handling

Follow the exact `CLAUDE.md` manifest convention.

When an artifact path changes:

- update the existing artifact record when the manifest model treats it as the
  same retained artifact;
- do not append duplicate rows merely because a file moved;
- preserve producer, checksum, and status semantics;
- add one row only for genuinely new documentation artifacts when required by
  project policy.

Canonical numeric and QC outputs must remain under:

```text
R-scripts/K50/outputs/FIG1_visual_dual_branch/
```

Do not move canonical K50 numeric or QC outputs into `diagram/legacy/`.

## Required Validation

Implementation cannot move to `tasks/03-review/` until these checks pass:

- current K50 producer smoke run;
- current resolved DOT generation;
- Graphviz PDF/SVG/PNG render;
- PNG signature validation;
- vector PDF inspection;
- root inventory allowlist;
- legacy inventory completeness;
- no broken old-path references;
- manifest validation;
- `git diff --check`;
- `bash tools/run-gates.sh --project Fear-of-Falling` from the repository root,
  or the equivalent project gate documented by current repository policy.

If QC artifacts are affected, run the README-defined K18/Termux QC runner.

The legacy move must not break the current K50 producer smoke run,
Graphviz-rendering, repository gates, reference validation, or manifest checks.

## Constraints

- Do not modify raw data.
- Do not expose secrets or participant-level data.
- Do not delete legacy diagram files.
- Do not create placeholder renders for absent files.
- Do not change analysis methods, models, or results.
- Do not change Figure 1 visible content as part of the legacy archive task.
- Do not edit dissertation manuscript text from this repository task.
- Do not modify the dissertation repository in this task.
- Do not copy dissertation audit reports into the analysis repository.
- Do not use local absolute filesystem paths in documentation.
- Do not commit generated outputs unless the implementing task explicitly
  requires and validates them.
- Do not move any task to `tasks/04-done/`.

## Acceptance Criteria

- [ ] The `diagram/` root contains only the current `wide_long` family,
      `README.md`, and `legacy/`.
- [ ] Historical generic, WIDE-only, and LONG-only files are retained under
      `diagram/legacy/`.
- [ ] All file moves preserve Git history through `git mv`.
- [ ] `diagram/legacy/README.md` documents provenance and non-current status.
- [ ] Legacy README records original path, legacy path, producer, known
      limitation, replacement asset, related task or commit, rerendering support,
      and use status for each retained legacy family.
- [ ] `diagram/README.md` clearly identifies canonical analysis-repository
      ownership.
- [ ] `diagram/README.md` includes a Current Assets table only for the current
      `paper_01_cohort_flow.wide_long.locomotor_capacity` family.
- [ ] `diagram/README.md` includes a Downstream Consumers section.
- [ ] `FOF-Dissertation-Project` is named as the downstream consumer.
- [ ] AIM1 manuscript QMD is named:
      `papers/A1_fear-of-falling-physical-performance/manuscript/draft/Results_Draft_version_2.qmd`.
- [ ] Dissertation submodule asset path is named:
      `analysis/modules/Python-R-Scripts/Fear-of-Falling/diagram/`.
- [ ] Cross-repository evidence paths are named:
      `docs/audit/k50_figure1_figure_abstract_methods_results_supplement_crosscheck.md`
      and `docs/audit/k50_figure1_manuscript_count_audit.md`.
- [ ] Downstream commit pins are recorded in README without local absolute
      paths.
- [ ] PDF is documented as the primary publication asset.
- [ ] SVG is documented as the review/interchange asset.
- [ ] PNG is documented as the Quarto/report fallback asset.
- [ ] Canonical QC and numeric outputs remain in
      `R-scripts/K50/outputs/FIG1_visual_dual_branch/`.
- [ ] Reference audit is completed before legacy moves.
- [ ] Manifest path updates are idempotent and do not create duplicate artifact
      rows.
- [ ] Current producer smoke, Graphviz render, repository gate, and reference
      validations pass.
- [ ] Current `wide_long` manuscript status is preserved according to the
      approved workflow status; no automatic promotion to `tasks/04-done/`.

## Agent Report

Implemented.

- Moved tracked generic, LONG-only, and WIDE-only resolved Figure 1 legacy
  assets into `diagram/legacy/` with `git mv`.
- Moved ignored/untracked local WIDE-only SVG/PNG renders out of `diagram/`
  root into `diagram/legacy/` without adding them to Git.
- Rewrote `diagram/README.md` as the current `wide_long` handoff contract for
  `FOF-Dissertation-Project` and the AIM1 manuscript.
- Added `diagram/legacy/README.md` with per-family original path, legacy path,
  producer, limitation, replacement, task/commit, and usage status.
- Updated the archived shell helper to read and write under `diagram/legacy/`
  so it no longer targets current root Figure 1 paths.
- Updated retained legacy diagram paths in `manifest/manifest.csv` and removed
  duplicate retained LONG diagram artifact rows.

Validation completed:

- `Rscript R-scripts/K50/K50.FIG1_VISUAL_DUAL_BRANCH.V1_render.R` -> PASS.
- Graphviz PDF/SVG/PNG render commands completed.
- `file` validated PDF, SVG, and PNG; PNG signature was
  `89 50 4e 47 0d 0a 1a 0a`.
- PDF vector inspection found embedded font/vector stream content.
- `diagram/` root allowlist contains only `README.md`, `legacy/`, and the
  current `wide_long` family.
- `diagram/legacy/` contains the retained generic, LONG-only, and WIDE-only
  legacy families.
- Manifest diagram duplicate check returned `diagram_duplicates 0`.
- `bash scripts/fof-preflight.sh` -> PASS.
- `bash tools/run-gates.sh --project Fear-of-Falling` -> PASS from repository
  root.

The K50 smoke run generated visible/render side effects because the current
producer script and tracked renders are not byte-equivalent. Those generated
side effects were reverted to preserve this task's constraint that Figure 1
visible content does not change.

## Log

- 2026-07-21T00:00:00+0300 Created backlog definition for diagram legacy
  archive and downstream usage contract.
- 2026-07-21T00:00:00+0300 Human approval: released to `01-ready` for
  implementation.
- 2026-07-21T12:39:52+0300 K50 Figure 1 visual dual-branch smoke run returned
  PASS; generated render side effects were reverted after validation to keep
  this archive task content-neutral.
- 2026-07-21T12:44:11+0300 Repository gate
  `bash tools/run-gates.sh --project Fear-of-Falling` returned PASS.
- 2026-07-21T12:45:00+0300 K18/QC Termux runner was attempted; local
  `proot-distro` reports installed `debian`, but the runner's rootfs path gate
  did not detect it and `proot-distro install debian` failed because the
  container already exists.

## Blockers

No repository blocker for this diagram archive task. Environment note: the
K18/QC Termux runner needs proot container path reconciliation before it can be
used in this Termux environment.
