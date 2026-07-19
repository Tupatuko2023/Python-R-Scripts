# Task: K50 Figure 1 visual dual-branch rebuild

## Status

00-backlog

## Workflow

Follow `agent_workflow.md`. Only a task in `tasks/01-ready/` may be started.
The agent moves the task to `tasks/02-in-progress/` before work and to
`tasks/03-review/` after reporting. Only a human may move the task to
`tasks/04-done/`.

Current state: `00-backlog`. A human must explicitly move this task to
`tasks/01-ready/` before implementation. This task must not be moved directly to
`tasks/04-done/`.

## Scope

Create the next implementation task for rebuilding manuscript Figure 1 as a
simplified dual-branch analytic-sample derivation diagram. This task is visual
and technical only. It must not redefine, refit, or reinterpret the WIDE ANCOVA
or LONG mixed-effects analyses.

The implementation must use only the authoritative counts validated by the K50
Figure 1 count-provenance gate committed in `485808a`.

Out of scope until this task is approved and moved to `01-ready`:

- editing or rendering Graphviz DOT, PDF, SVG, or PNG assets;
- changing `diagram/README.md`;
- changing `manifest/manifest.csv`;
- changing provenance outputs, analysis models, raw data, manuscript text, or
  `docs/ANALYSIS_PLAN.md`;
- marking historical assets `SUPERSEDED`.

## Objective

Rebuild manuscript Figure 1 as a reader-facing dual-branch analytic-sample
derivation figure with one shared source cohort and separate WIDE ANCOVA and
LONG mixed-effects branches.

The final figure must show participants and observations as different units and
must not reuse the historical LONG-labelled `N = 230` figure as the manuscript
Figure 1.

## Authoritative Sources

Primary machine-readable sources:

- `R-scripts/K50/outputs/FIG1_count_provenance/k50_fig1_count_provenance.csv`
- `R-scripts/K50/outputs/FIG1_count_provenance/k50_fig1_discrepancy_resolution.csv`
- `R-scripts/K50/outputs/FIG1_count_provenance/k50_fig1_proposed_counts.csv`
- `R-scripts/K50/outputs/FIG1_count_provenance/k50_fig1_supplementary_missingness.csv`
- `R-scripts/K50/outputs/FIG1_count_provenance/k50_fig1_table_to_text_crosscheck.txt`

Scientific and editorial decision record:

- `tasks/03-review/20260718_k50_figure1_dual_branch_cohort_flow.md`

Diagram provenance and rendering rules:

- `diagram/README.md`

## Locked Counts

Use these values exactly. They are locked by commit `485808a`.

| Stage | Unit | Total | FOF yes | FOF no |
| --- | --- | ---: | ---: | ---: |
| Source analytic cohort | participants | 535 | NA | NA |
| Valid baseline FOF | participants | 472 | 328 | 144 |
| WIDE ANCOVA model frame | participants | 230 | 161 | 69 |
| LONG primary model frame | unique participants | 400 | 276 | 124 |
| LONG primary model frame | observations | 630 | NA | NA |

The values `527`, `486`, and `340/146` are historical or not reproducible from
the locked K50 sources. They must not be presented as authoritative Figure 1
counts.

## Required Figure Structure

Use one shared start and two clearly separated analysis branches:

1. Source analytic cohort:
   - `Participants with locomotor-capacity source data, N = 535`
2. Baseline FOF restriction:
   - `Valid baseline fear-of-falling status, n = 472`
   - `Fear of falling present, n = 328`
   - `Fear of falling absent, n = 144`
3. WIDE ANCOVA branch:
   - label the branch as `Baseline-adjusted 12-month analysis`;
   - `Participants in the locked ANCOVA model frame, n = 230`;
   - `Fear of falling present, n = 161`;
   - `Fear of falling absent, n = 69`;
   - reader-facing exclusion label:
     `Missing baseline or 12-month locomotor-capacity score or required model covariate`.
4. LONG mixed-effects branch:
   - label the branch as `Repeated-measures analysis`;
   - `Unique participants in the locked mixed-effects model frame, n = 400`;
   - `Fear of falling present, n = 276`;
   - `Fear of falling absent, n = 124`;
   - separately: `Repeated observations included, n = 630`.

Participants and observations must never be combined into one denominator or
displayed as equivalent units.

## Missingness Decision

Do not place the detailed missingness table in the main figure.

Use the validated supplementary source
`R-scripts/K50/outputs/FIG1_count_provenance/k50_fig1_supplementary_missingness.csv`
for a separate Supplementary Table task or artifact.

Do not label missing follow-up data as withdrawal, dropout, measurement
failure, unavailable assessment, or any other mechanism unless a verified source
variable supports that interpretation.

## Manuscript Title

`Figure 1. Derivation of the analytic samples for locomotor capacity analyses`

Do not embed this title inside the artwork unless the journal production
specification explicitly requires it. The normal manuscript caption remains
outside the figure.

## Legend Requirements

Use the expert-review legend draft in
`tasks/03-review/20260718_k50_figure1_dual_branch_cohort_flow.md` as the
editorial source.

The legend must state:

- the diagram describes derivation of analytic samples rather than participant
  recruitment;
- the WIDE branch represents the locked baseline-adjusted 12-month ANCOVA
  model frame;
- the LONG branch represents the locked repeated-measures mixed-effects model
  frame;
- LONG `n = 400` refers to unique participants;
- LONG `n = 630` refers to repeated observations;
- FOF group counts are participant-level counts;
- detailed missingness is reported separately in Supplementary material.

## Visible-Language Requirements

Use reader-facing terminology in the visible figure:

- `Fear of falling present`
- `Fear of falling absent`
- `Baseline-adjusted 12-month analysis`
- `Repeated-measures analysis`
- `Unique participants`
- `Repeated observations`

Do not expose internal pipeline names, R object names, variable names, task
identifiers, QC labels, or model-frame implementation details in the visible
figure.

## Visual Requirements

- simplified dual-branch flow;
- balanced branch widths;
- restrained neutral grey and blue styling;
- no decorative gradients;
- no redundant zero-exclusion boxes;
- consistent box dimensions and typography;
- sufficient white space;
- readable in grayscale;
- readable at 170 mm final width;
- participant and observation units visually distinct;
- no embedded internal title or repository labels.

## File Lineage And Naming

Create a new diagram family rather than overwriting the historical LONG-only
family before review.

Planned naming:

- `diagram/paper_01_cohort_flow.wide_long.locomotor_capacity.dot`
- `diagram/paper_01_cohort_flow.wide_long.locomotor_capacity.resolved.dot`
- `diagram/paper_01_cohort_flow.wide_long.locomotor_capacity.pdf`
- `diagram/paper_01_cohort_flow.wide_long.locomotor_capacity.svg`
- `diagram/paper_01_cohort_flow.wide_long.locomotor_capacity.png`

Follow this lineage:

`editable DOT -> resolved DOT -> PDF/SVG/PNG`

The existing `paper_01_cohort_flow.long.locomotor_capacity.*` files remain
`DO_NOT_USE` until the replacement passes human review. Mark them `SUPERSEDED`
only after acceptance of the new diagram family.

## Producer And Reproducibility

The resolved DOT must be produced from the locked provenance CSV files. Do not
manually type the authoritative counts into an otherwise untracked render-only
file.

The producer must record:

- provenance input paths;
- extracted values;
- units;
- output paths;
- render commands;
- timestamp;
- script version or commit;
- crosscheck result.

All changes must be small, reversible, and documented.

## Required Output Discipline

Producer and QC outputs belong under:

`R-scripts/K50/outputs/FIG1_visual_dual_branch/`

Each new artifact receives exactly one row in:

`manifest/manifest.csv`

Tracked manuscript sources and selected renders may additionally be placed
under `diagram/` according to `diagram/README.md`, with the K50 output directory
retained as the reproducible producer source.

Do not commit raw data.

## Required Renders

Primary publication asset:

- vector PDF

Review and interchange assets:

- SVG
- PNG

The PDF must be inspected as the publication source. PNG alone is not
sufficient for acceptance.

## Technical Validation

Required checks:

```sh
dot -V
dot -Tpdf <RESOLVED_DOT> -o <PDF>
dot -Tsvg <RESOLVED_DOT> -o <SVG>
dot -Tpng -Gdpi=300 <RESOLVED_DOT> -o <PNG>
file <DOT> <PDF> <SVG> <PNG>
stat -c '%n %s bytes' <PDF> <SVG> <PNG>
od -An -tx1 -N8 <PNG>
```

Expected PNG signature:

```text
89 50 4e 47 0d 0a 1a 0a
```

Also validate:

- no clipping;
- tight crop;
- PDF vector content;
- grayscale readability;
- legibility at 170 mm;
- no Git LFS pointer in place of image data.

## Mandatory Scientific Crosscheck

Before the task can enter `03-review`, compare:

1. figure labels and counts against `k50_fig1_count_provenance.csv`;
2. branch totals against `k50_fig1_proposed_counts.csv`;
3. historical exclusions against `k50_fig1_discrepancy_resolution.csv`;
4. legend against Figure 1;
5. Figure 1 against Methods and Results;
6. participants against observations;
7. main figure against the Supplementary missingness source;
8. rendered filenames against manuscript references.

The machine-readable provenance table takes precedence if prose conflicts with
a displayed number.

## Deliverables

Expected implementation deliverables:

- editable DOT;
- resolved DOT;
- vector PDF;
- SVG;
- PNG;
- producer or resolver script;
- figure-count crosscheck report;
- rendering validation report;
- sessionInfo and renv diagnostics when R is used;
- manifest row for every generated artifact;
- updated diagram inventory/status documentation when the replacement reaches
  review.

## Constraints

- Do not refit or alter the analyses.
- Do not modify raw data.
- Do not replace authoritative counts.
- Do not use `527`, `486`, or `340/146` as current counts.
- Do not merge participants and observations.
- Do not place the full missingness table in the main figure.
- Do not overwrite the historical diagram family before review.
- Do not mark old assets `SUPERSEDED` before human acceptance.
- Do not edit manuscript claims without a separate approved task.
- Do not move this task directly to `04-done`.
- Do not expose secrets or participant-level data.

## Acceptance Criteria

- [ ] Status remains `00-backlog` until a human approves moving this task to
      `tasks/01-ready/`.
- [ ] Dual-branch design matches the expert decision record.
- [ ] Every visible number matches the locked provenance artifacts from commit
      `485808a`.
- [ ] Source cohort uses `N = 535`.
- [ ] Valid baseline FOF uses `n = 472`, with participant-level FOF yes/no
      `328/144`.
- [ ] WIDE ANCOVA branch uses `n = 230`, with participant-level FOF yes/no
      `161/69`.
- [ ] LONG mixed-effects branch uses `400` unique participants and `630`
      repeated observations.
- [ ] LONG participant-level FOF yes/no is `276/124`.
- [ ] Values `527`, `486`, and `340/146` do not appear as authoritative
      current Figure 1 counts.
- [ ] WIDE and LONG branches are unambiguous.
- [ ] Participants and observations are visibly distinct units.
- [ ] Main Figure 1 contains no detailed missingness table.
- [ ] Supplementary missingness is handled outside the main figure.
- [ ] Title and legend are manuscript-ready.
- [ ] Visible labels are reader-facing and omit internal pipeline labels.
- [ ] Visual style uses neutral grey/blue, remains grayscale-readable, and is
      legible at 170 mm width.
- [ ] PDF is the primary vector publication asset.
- [ ] SVG and PNG review versions pass technical validation.
- [ ] New diagram family uses `wide_long.locomotor_capacity` naming.
- [ ] Editable DOT, resolved DOT, PDF, SVG, and PNG follow documented lineage.
- [ ] Figure-to-source-table-to-legend-to-manuscript crosscheck passes.
- [ ] All producer outputs have exactly one manifest row per artifact.
- [ ] Historical assets remain traceable and are not overwritten.
- [ ] Task reaches `03-review`, not `04-done`, after successful implementation.

## Agent Report

Not started. Created as the next backlog task after count-provenance gate
`PASS` and commit `485808a`.

## Log

- 2026-07-19T00:00:00+0300 Created after count-provenance gate `PASS` and
  commit `485808a`.

## Blockers

Awaiting human approval to move this task to `tasks/01-ready/`.
