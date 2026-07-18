# Task: Document diagram provenance and rendering

## Status

00-backlog

## Workflow

Follow `agent_workflow.md`. Only a task in `tasks/01-ready/` may be started.
The agent moves the task to `tasks/02-in-progress/` before work and to
`tasks/03-review/` after reporting. Only a human may move the task to
`tasks/04-done/`.

## Scope

Create `diagram/README.md` as the durable source of truth for the purpose,
lineage, rendering, validation, and manuscript status of files under
`diagram/`.

Do not create `diagram/AGENTS.md` in this task. Repository-root `AGENTS.md`,
`CLAUDE.md`, and the tasks workflow remain authoritative. Add a subdirectory
`AGENTS.md` only if future work identifies truly different agent permissions,
prohibitions, or validation rules for `diagram/`.

## Objective

Document how `diagram/` stores editable diagram sources, resolved/intermediate
sources, rendered preview or manuscript assets, and superseded artifacts. The
README must make diagram provenance recoverable without relying on chat history
and without using `diagram/` as a free-form replacement for the existing
`R-scripts/Kxx/outputs/<script_label>/` and `manifest/manifest.csv`
conventions.

## Rationale

The cohort-flow lineage, branch identity, numerical source, rendering command,
Git LFS behavior, and manuscript suitability were no longer obvious after
several months. This caused a `.png` path to contain a Git LFS pointer instead
of image bytes and made the LONG-labelled N = 230 cohort-flow asset appear more
manuscript-ready than its current review status supports.

## Current Inventory Context

Known files currently include:

- `diagram/paper_01_cohort_flow.dot`
- `diagram/render_paper_01_cohort_flow.sh`
- `diagram/paper_01_cohort_flow.wide.locomotor_capacity.resolved.dot`
- `diagram/paper_01_cohort_flow.wide.locomotor_capacity.svg`
- `diagram/paper_01_cohort_flow.wide.locomotor_capacity.png`
- `diagram/paper_01_cohort_flow.long.locomotor_capacity.resolved.dot`
- `diagram/paper_01_cohort_flow.long.locomotor_capacity.svg`
- `diagram/paper_01_cohort_flow.long.locomotor_capacity.png`

PNG files are Git LFS-managed. DOT files are text sources or resolved sources.
SVG files are rendered vector previews/interchange files. Some rendered files
may be untracked, superseded, or review-only; existence alone does not imply
current manuscript status.

## Required README Sections

### 1. Directory Purpose

Explain whether `diagram/` contains:

- editable diagram source files;
- resolved intermediate files;
- manuscript asset candidates;
- technical preview renders;
- superseded assets.

State that `diagram/` is not a free-form replacement for
`R-scripts/Kxx/outputs/<script_label>/`.

### 2. File-Role Taxonomy

Document:

- `.dot` template/source;
- `.resolved.dot` generated source with substituted values;
- `.svg` vector preview/interchange;
- `.pdf` preferred publication vector format;
- `.png` raster preview or journal fallback.

State which formats are edited and which are regenerated. Rendered formats must
not be edited by hand.

### 3. Current File Inventory

For every current diagram family, record:

- file path;
- role;
- branch;
- outcome;
- producer or generation source;
- numerical source/model frame;
- render command;
- Git/LFS status;
- manuscript status;
- superseded-by field;
- related task/review file.

### 4. Cohort-Flow Lineage

Document the current chain:

```text
paper_01_cohort_flow.dot
-> paper_01_cohort_flow.long.locomotor_capacity.resolved.dot
-> SVG/PNG renders
```

Also document the WIDE resolved/rendered family where retained:

```text
paper_01_cohort_flow.dot
-> paper_01_cohort_flow.wide.locomotor_capacity.resolved.dot
-> SVG/PNG renders
```

Record that the current LONG-labelled N = 230 image is technically renderable
but scientifically classified as Major Revision / DO_NOT_USE for the final
manuscript Figure 1. Link the scientific correction task:

`tasks/00-backlog/20260718_k50_figure1_dual_branch_cohort_flow.md`

### 5. Rendering Commands

Document Graphviz commands from the Fear-of-Falling project root:

```sh
dot -Tpdf diagram/<SOURCE>.resolved.dot -o diagram/<TARGET>.pdf
dot -Tsvg diagram/<SOURCE>.resolved.dot -o diagram/<TARGET>.svg
dot -Tpng -Gdpi=300 diagram/<SOURCE>.resolved.dot -o diagram/<TARGET>.png
```

State that publication rendering should prefer vector PDF.

### 6. Validation Commands

Document:

```sh
dot -V
file diagram/<TARGET>
stat -c '%n %s bytes' diagram/<TARGET>
od -An -tx1 -N8 diagram/<TARGET>.png
```

Expected PNG signature:

```text
89 50 4e 47 0d 0a 1a 0a
```

### 7. Git LFS Pointer Failure

Document the observed failure mode:

- filename ends in `.png`;
- `file` reports `ASCII text`;
- first bytes spell `version `;
- file content begins with `version https://git-lfs.github.com/spec/v1`;
- the file is a Git LFS pointer rather than image bytes.

Such a file cannot be opened as an image. It must be restored through Git LFS
or deterministically rerendered from a verified source.

### 8. Naming Convention

Require names to encode:

- manuscript or figure identifier;
- branch: `wide`, `long`, or `wide_long`;
- outcome;
- state when necessary: `template`, `resolved`, `draft`, `review`;
- extension.

Avoid internal variable names in the visible publication graphic even if
canonical names remain in filenames.

### 9. Numerical Provenance

No number may be typed manually into a final diagram without a locked source.

For every reported number, retain:

- participant or observation unit;
- dataset/object;
- model frame;
- extraction expression;
- inclusion rule;
- source table;
- task/review status;
- crosscheck result.

Participants, rows, and repeated observations must never be conflated.

### 10. Output And Manifest Policy

Analysis-derived artifacts belong under:

`R-scripts/<K_FOLDER>/outputs/<script_label>/`

Each new artifact receives one row in:

`manifest/manifest.csv`

Explain when a tracked `diagram/` asset is a manuscript source/asset versus an
analysis output. Do not duplicate the same uncontrolled artifact in both
locations without a documented canonical source.

### 11. Manuscript Status Labels

Use:

- `DRAFT`
- `QC_ONLY`
- `03_REVIEW`
- `MANUSCRIPT_CANDIDATE`
- `SUPERSEDED`
- `DO_NOT_USE`

No rendered file is presumed current solely because it exists.

### 12. Crosschecks

Before manuscript use, require:

- figure-to-source-table check;
- figure-to-legend check;
- figure-to-Methods/Results check;
- participant-versus-observation unit check;
- branch and outcome check;
- filename and manuscript-reference check;
- grayscale and 170 mm readability check;
- vector PDF inspection.

### 13. Update Rule

Update `diagram/README.md` whenever any of these change:

- producer;
- source dataset/model frame;
- branch;
- outcome;
- inclusion rule;
- published counts;
- render command;
- canonical filename;
- manuscript status;
- supersession status.

## Constraints

- Do not modify raw data.
- Do not modify analysis code or model specifications.
- Do not modify existing diagram DOT, SVG, PNG, or shell assets in this task.
- Do not render diagrams in this task.
- Do not create `diagram/README.md` until this backlog task is moved to
  `tasks/01-ready/` by a human.
- Do not create `diagram/AGENTS.md` unless a future task identifies genuinely
  different directory-specific agent rules.
- Do not modify `manifest/manifest.csv`.
- Do not modify the current K50 Figure 1 dual-branch backlog task.
- Do not commit or push unless separately authorized.
- Do not expose secrets or participant-level data.

## Acceptance Criteria

- [ ] Status remains `00-backlog` until a human approves moving this task to
      `tasks/01-ready/`.
- [ ] `diagram/README.md` is created as the intended documentation artifact.
- [ ] `diagram/AGENTS.md` is not created.
- [ ] README documents the purpose of `diagram/`.
- [ ] README distinguishes template DOT, resolved DOT, SVG, PDF, and PNG roles.
- [ ] README states what is edited by hand and what is regenerated.
- [ ] README documents Graphviz rendering commands for PDF, SVG, and PNG.
- [ ] README documents `file`, `stat`, and PNG-signature validation.
- [ ] README documents the Git LFS pointer failure mode.
- [ ] README documents branch, outcome, state, and format naming.
- [ ] README includes a file inventory/provenance table.
- [ ] README records the current LONG-labelled N = 230 cohort-flow asset as
      Major Revision / DO_NOT_USE for final manuscript Figure 1.
- [ ] README links
      `tasks/00-backlog/20260718_k50_figure1_dual_branch_cohort_flow.md`.
- [ ] README forbids manual numeric edits without a locked source table.
- [ ] README requires figure-to-table-to-text crosscheck before manuscript use.
- [ ] README documents manuscript status labels and supersession rules.
- [ ] README states when it must be updated.
- [ ] AGENTS.md, diagram assets, manifest, analysis outputs, and analysis code
      remain unchanged in this backlog-definition task.
- [ ] Task reaches `03-review` after README creation; only a human may move it
      to `04-done`.

## Agent Report

Not started.

## Log

- 2026-07-18T00:00:00+0300 Created in `00-backlog` after loss of
  diagram-generation context was identified.

## Blockers

- Awaiting human approval to move this documentation task to `tasks/01-ready/`.
