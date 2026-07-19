# Diagram Provenance And Rendering

## Purpose And Bounds

`diagram/` stores manuscript-facing diagram sources and retained rendered
assets for Fear-of-Falling figures. It may contain editable DOT templates,
resolved DOT intermediates, technical preview renders, manuscript asset
candidates, and superseded assets retained for traceability.

`diagram/` is not a free-form replacement for analysis outputs under
`R-scripts/Kxx/outputs/<script_label>/`. Analysis-derived artifacts still belong
under the producing script's output directory and require `manifest/manifest.csv`
entries according to the project output policy.

## File Roles

| Format | Role | Edit policy |
| --- | --- | --- |
| `.dot` | Editable Graphviz template or source. May contain placeholders. | Edit by hand when changing diagram structure or labels. |
| `.resolved.dot` | Generated DOT source after placeholder substitution. | Regenerate from a verified template and locked numeric source. Do not hand-edit for final use. |
| `.pdf` | Preferred publication vector render. | Regenerate from resolved DOT. Do not hand-edit. |
| `.svg` | Vector preview/interchange render. | Regenerate from resolved DOT. Do not hand-edit. |
| `.png` | Raster preview or journal fallback render. | Regenerate from resolved DOT. Do not hand-edit. |

Rendered formats are products of sources, not sources themselves. A rendered
file is not manuscript-current solely because it exists.

## Current Inventory

| Path | Role | Branch | Outcome | Producer/source | Numeric source/model frame | Render/status | Git/LFS | Manuscript status | Superseded-by | Related task |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `diagram/paper_01_cohort_flow.dot` | Editable DOT template | Parameterized | Parameterized | Created by `tasks/04-done/K50_paper01_cohort_flow_diagram.md`; consumed by `diagram/render_paper_01_cohort_flow.sh` | Placeholders produced outside this file; numeric provenance must be verified before final use | Source template, not rendered | Tracked text | `DRAFT` | Future dual-branch Figure 1 source | `tasks/00-backlog/20260718_k50_figure1_dual_branch_cohort_flow.md` |
| `diagram/render_paper_01_cohort_flow.sh` | Placeholder substitution and render helper | `wide` or `long` argument | Outcome argument | Reads template, placeholder CSV, Graphviz `dot`; appends manifest rows when run | Default placeholder CSV: `R-scripts/K50/outputs/k50_<branch>_<outcome>_cohort_flow_placeholders.csv` | Do not run in this docs-only task | Tracked text executable | `QC_ONLY` | Future documented renderer if retained | `tasks/04-done/K50_paper01_cohort_flow_diagram.md` |
| `diagram/paper_01_cohort_flow.long.locomotor_capacity.resolved.dot` | Resolved DOT | `long` label | `locomotor_capacity` | `diagram/render_paper_01_cohort_flow.sh` from `paper_01_cohort_flow.dot` | K50 LONG placeholder CSV lineage; current N = 230 interpretation is under Major Revision review | Renderable resolved source | Tracked text | `DO_NOT_USE` for final manuscript Figure 1 | Planned `wide_long` corrected Figure 1 | `tasks/00-backlog/20260718_k50_figure1_dual_branch_cohort_flow.md` |
| `diagram/paper_01_cohort_flow.long.locomotor_capacity.svg` | SVG render | `long` label | `locomotor_capacity` | Graphviz render from LONG resolved DOT | Same as LONG resolved DOT | Technical vector render | Tracked, not LFS | `DO_NOT_USE` for final manuscript Figure 1 | Planned `wide_long` corrected Figure 1 | `tasks/00-backlog/20260718_k50_figure1_dual_branch_cohort_flow.md` |
| `diagram/paper_01_cohort_flow.long.locomotor_capacity.png` | PNG render | `long` label | `locomotor_capacity` | Graphviz render from LONG resolved DOT | Same as LONG resolved DOT | Technical raster render; bytes currently validate as PNG | Tracked with Git LFS attributes | `DO_NOT_USE` / Major Revision for final manuscript Figure 1 | Planned `wide_long` corrected Figure 1 | `tasks/00-backlog/20260718_k50_figure1_dual_branch_cohort_flow.md` |
| `diagram/paper_01_cohort_flow.wide.locomotor_capacity.resolved.dot` | Resolved DOT | `wide` | `locomotor_capacity` | `diagram/render_paper_01_cohort_flow.sh` from `paper_01_cohort_flow.dot` | K50 WIDE placeholder CSV lineage; modeled WIDE analytic counts require source-table crosscheck | Renderable resolved source | Tracked text | `03_REVIEW` / `QC_ONLY` | Planned `wide_long` corrected Figure 1 | `tasks/03-review/investigate_k50_cohort_flow_unique_id_mismatch.md` |
| `diagram/paper_01_cohort_flow.wide.locomotor_capacity.svg` | SVG render | `wide` | `locomotor_capacity` | Graphviz render from WIDE resolved DOT | Same as WIDE resolved DOT | Technical vector render | Ignored/untracked local file at inventory time | `QC_ONLY` | Planned `wide_long` corrected Figure 1 | `tasks/03-review/investigate_k50_cohort_flow_unique_id_mismatch.md` |
| `diagram/paper_01_cohort_flow.wide.locomotor_capacity.png` | PNG render | `wide` | `locomotor_capacity` | Graphviz render from WIDE resolved DOT | Same as WIDE resolved DOT | Technical raster render | Ignored/untracked local file at inventory time; PNG pattern has Git LFS attributes | `QC_ONLY` | Planned `wide_long` corrected Figure 1 | `tasks/03-review/investigate_k50_cohort_flow_unique_id_mismatch.md` |
| `diagram/paper_01_cohort_flow.wide_long.locomotor_capacity.dot` | Editable DOT template | `wide_long` | `locomotor_capacity` | `R-scripts/K50/K50.FIG1_VISUAL_DUAL_BRANCH.V1_render.R` | Locked K50 Figure 1 provenance CSVs; source cohort 535, valid baseline FOF 472, WIDE 230 participants, LONG 400 participants / 630 observations | Source template with placeholders | Tracked text | `03_REVIEW` | None | `tasks/03-review/20260719_k50_figure1_visual_dual_branch_rebuild.md` |
| `diagram/paper_01_cohort_flow.wide_long.locomotor_capacity.resolved.dot` | Resolved DOT | `wide_long` | `locomotor_capacity` | `R-scripts/K50/K50.FIG1_VISUAL_DUAL_BRANCH.V1_render.R` from editable DOT and locked provenance CSVs | Same locked K50 Figure 1 provenance CSVs; all visible counts crosschecked by producer report | Renderable resolved source | Tracked text | `03_REVIEW` | None | `tasks/03-review/20260719_k50_figure1_visual_dual_branch_rebuild.md` |
| `diagram/paper_01_cohort_flow.wide_long.locomotor_capacity.pdf` | PDF render | `wide_long` | `locomotor_capacity` | Graphviz render from `paper_01_cohort_flow.wide_long.locomotor_capacity.resolved.dot` | Same as wide_long resolved DOT | Primary vector publication candidate | Tracked render | `03_REVIEW` | None | `tasks/03-review/20260719_k50_figure1_visual_dual_branch_rebuild.md` |
| `diagram/paper_01_cohort_flow.wide_long.locomotor_capacity.svg` | SVG render | `wide_long` | `locomotor_capacity` | Graphviz render from `paper_01_cohort_flow.wide_long.locomotor_capacity.resolved.dot` | Same as wide_long resolved DOT | Review/interchange vector render | Tracked render | `03_REVIEW` | None | `tasks/03-review/20260719_k50_figure1_visual_dual_branch_rebuild.md` |
| `diagram/paper_01_cohort_flow.wide_long.locomotor_capacity.png` | PNG render | `wide_long` | `locomotor_capacity` | Graphviz 300 dpi render from `paper_01_cohort_flow.wide_long.locomotor_capacity.resolved.dot` | Same as wide_long resolved DOT | Review raster render; bytes validate as PNG | Tracked render with Git LFS attributes where configured | `03_REVIEW` | None | `tasks/03-review/20260719_k50_figure1_visual_dual_branch_rebuild.md` |

## Cohort-Flow Lineage

Current LONG-labelled family:

```text
paper_01_cohort_flow.dot
-> paper_01_cohort_flow.long.locomotor_capacity.resolved.dot
-> paper_01_cohort_flow.long.locomotor_capacity.svg
-> paper_01_cohort_flow.long.locomotor_capacity.png
```

Current WIDE family where retained:

```text
paper_01_cohort_flow.dot
-> paper_01_cohort_flow.wide.locomotor_capacity.resolved.dot
-> paper_01_cohort_flow.wide.locomotor_capacity.svg
-> paper_01_cohort_flow.wide.locomotor_capacity.png
```

Current WIDE+LONG review family:

```text
paper_01_cohort_flow.wide_long.locomotor_capacity.dot
-> paper_01_cohort_flow.wide_long.locomotor_capacity.resolved.dot
-> paper_01_cohort_flow.wide_long.locomotor_capacity.pdf
-> paper_01_cohort_flow.wide_long.locomotor_capacity.svg
-> paper_01_cohort_flow.wide_long.locomotor_capacity.png
```

The current LONG-labelled N = 230 asset is technically renderable, but it is
scientifically classified as Major Revision / `DO_NOT_USE` for final manuscript
Figure 1. The new `wide_long` family is the corrected Figure 1 review candidate
pending human acceptance; old assets are not marked `SUPERSEDED` until that
acceptance is recorded.

## Rendering Commands

Run Graphviz commands from the Fear-of-Falling project root. Prefer vector PDF
for publication rendering.

```sh
dot -Tpdf diagram/<SOURCE>.resolved.dot -o diagram/<TARGET>.pdf
dot -Tsvg diagram/<SOURCE>.resolved.dot -o diagram/<TARGET>.svg
dot -Tpng -Gdpi=300 diagram/<SOURCE>.resolved.dot -o diagram/<TARGET>.png
```

`diagram/render_paper_01_cohort_flow.sh` also resolves placeholders and writes
manifest rows when run, so use it only when that full behavior is intended and
the placeholder source has been verified.

## Validation Commands

Use these checks before treating a render as usable:

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

## Git LFS Pointer Failure

A Git LFS pointer can look like a `.png` path while not containing image bytes.
The failure mode is:

- the filename ends in `.png`;
- `file` reports `ASCII text`;
- the first bytes spell `version `;
- file content begins with `version https://git-lfs.github.com/spec/v1`.

Such a file cannot be opened as an image. Restore it through Git LFS or
deterministically rerender it from a verified source.

## Naming Convention

Diagram filenames must encode:

- manuscript or figure identifier, for example `paper_01_cohort_flow`;
- branch: `wide`, `long`, or `wide_long`;
- outcome, for example `locomotor_capacity`;
- state when needed: `template`, `resolved`, `draft`, or `review`;
- extension.

Avoid internal variable names in the visible publication graphic even when
canonical names remain in filenames.

## Numerical Provenance

No number may be typed manually into a final diagram without a locked source
table. For every reported number, retain:

- participant or observation unit;
- dataset or object;
- model frame;
- extraction expression;
- inclusion rule;
- source table;
- task or review status;
- crosscheck result.

Participants, rows, and repeated observations are separate units and must never
be conflated.

## Output And Manifest Policy

Analysis-derived artifacts belong under:

```text
R-scripts/<K_FOLDER>/outputs/<script_label>/
```

Each new analysis artifact receives one row in:

```text
manifest/manifest.csv
```

A tracked `diagram/` asset is appropriate when it is a manuscript source,
manuscript candidate, or retained review artifact. It is not a substitute for
the canonical analysis output that generated its numbers. Do not duplicate the
same uncontrolled artifact in both locations without documenting which path is
canonical.

## Manuscript Status Labels

Use these labels in inventory rows, task cards, and manuscript handoff notes:

- `DRAFT`: source or render is being shaped and is not ready for review.
- `QC_ONLY`: useful for technical or numerical inspection, not manuscript use.
- `03_REVIEW`: ready for human review under the task workflow.
- `MANUSCRIPT_CANDIDATE`: passed required checks and can be considered for the manuscript.
- `SUPERSEDED`: retained only for history because a newer artifact replaced it.
- `DO_NOT_USE`: known unsuitable for manuscript use.

No rendered file is presumed current solely because it exists.

## Crosschecks Before Manuscript Use

Before manuscript use, complete and record:

- figure-to-source-table check;
- figure-to-legend check;
- figure-to-Methods/Results check;
- participant-versus-observation unit check;
- branch and outcome check;
- filename and manuscript-reference check;
- grayscale and 170 mm readability check;
- vector PDF inspection.

## Update Rule

Update this README whenever any of these change:

- producer;
- source dataset or model frame;
- branch;
- outcome;
- inclusion rule;
- published counts;
- render command;
- canonical filename;
- manuscript status;
- supersession status.
