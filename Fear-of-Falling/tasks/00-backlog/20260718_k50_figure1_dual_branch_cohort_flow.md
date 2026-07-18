# Task: K50 Figure 1 dual-branch analytic sample derivation

## Status

00-backlog

## Workflow

Follow `agent_workflow.md`. Only a task in `tasks/01-ready/` may be started.
The agent moves the task to `tasks/02-in-progress/` before work and to
`tasks/03-review/` after reporting. Only a human may move the task to
`tasks/04-done/`.

## Classification

Major Revision; publication figure; blocked by unresolved cohort-count
provenance.

## Scope

Create a provenance-first correction plan for K50 Figure 1. The current
`paper_01_cohort_flow.long.locomotor_capacity.png` may be technically readable,
but it must not be used as the manuscript Figure 1 without revision because it
combines a LONG label with a WIDE complete-case cohort and unresolved count
conflicts.

This backlog task does not authorize rendering, model reruns, raw-data edits,
analysis-plan edits, manifest edits, or changes to existing DOT/SVG/PNG assets.

## Objective

Replace the current single-branch LONG-labelled cohort-flow asset with a
manuscript-ready analytic-sample derivation figure containing a shared source
cohort and separate WIDE ANCOVA and LONG mixed-effects branches. The figure may
be produced only after every displayed count has a verified locked provenance
source.

## Authoritative Scope

- `docs/ANALYSIS_PLAN.md`
- active stage: K50
- primary outcome: `locomotor_capacity`
- fallback/sensitivity outcome: `z3`
- `Composite_Z`: verified legacy bridge only
- raw data are read-only

## Critical Blockers

Do not render or publish the revised figure until all counts are derived from
verified locked sources.

1. Reconcile source cohort N: 527 versus 535.
2. Reconcile valid baseline FOF N: 472 versus 486.
3. Verify WIDE model-frame participants and group counts, including N = 230,
   FOF yes = 161, and FOF no = 69.
4. Derive LONG unique participant N directly from the locked primary LONG
   `merMod` model frame.
5. Report LONG observation count separately from participant N; do not infer
   participant N from 630 observations.
6. Verify LONG inclusion rule from the actual model frame, including at least
   one valid outcome observation, canonical time coding, covariate
   requirements, and any `model.frame` / `na.omit` exclusions.
7. Verify WIDE inclusion rule from the actual model frame, including complete
   baseline and 12-month locomotor-capacity scores plus required age, sex, and
   BMI covariates.
8. Reconcile group-by-time missingness counts: 328/144 versus 340/146 and the
   corresponding outcome-missing counts.
9. Clarify whether follow-up absence reflects attrition, unavailable
   assessment, failed measurement, or derived-score unavailability where the
   data permit this distinction.

## Required Provenance Matrix

Create a machine-readable table with one row per reported quantity and at
least:

- quantity label
- branch
- outcome
- numeric value
- unit: participants or observations
- source dataset/object
- source file
- extraction expression
- inclusion rule
- exclusion rule
- manuscript location
- figure location
- verification status
- reviewer note

Every published number must come from one locked provenance source. Do not copy
counts manually from the current LONG-labelled DOT, PNG, SVG, prose, or
unverified intermediate output.

## Main Figure 1 Design

Title and legend belong in the manuscript, not inside the graphic.

Recommended manuscript title:
`Figure 1. Derivation of the analytic samples for locomotor capacity analyses`

Graphic structure:

1. Source analytic cohort, participants only.
2. Excluded: missing or invalid baseline fear-of-falling status.
3. Participants with valid baseline fear-of-falling status.
4. Two branches:
   - WIDE ANCOVA:
     - complete baseline and 12-month locomotor-capacity scores
     - complete age, sex, and BMI
     - final participant N
     - optional baseline FOF yes/no participant counts
   - LONG mixed-effects:
     - eligible repeated locomotor-capacity observations
     - actual model-frame covariate requirements
     - unique participant N
     - observation n
5. Use explicit labels `participants` and `observations`.

Remove from the main figure:

- embedded title
- `paper_01`
- raw variable names
- internal denominator names such as `N_VALID_ID` or `N_ANALYTIC_PRIMARY`
- Group x Time missingness panel
- FI22 sensitivity note
- zero-exclusion boxes
- percentages based on raw rows
- redundant technical QC details

Use reader-facing labels such as locomotor capacity, baseline fear of falling,
participants, observations, WIDE ANCOVA, and LONG mixed-effects.

## Supplementary Missingness Table

Create a true table, not an image-embedded table, with:

- baseline FOF group
- time point
- eligible participants
- outcome missing n and percent
- age missing
- sex missing
- BMI missing
- exact source/model-frame definition

## Visual And Export Requirements

- neutral publication-safe palette
- information remains interpretable in grayscale
- readable at 170 mm width
- no red-green semantic dependency
- primary export: vector PDF
- secondary exports: SVG and high-resolution PNG
- tightly cropped
- fonts embedded or converted in a journal-safe way
- no title or legend embedded in the asset

## QC Requirements

- verify all columns and types
- verify `id` and `id`-time structure
- verify canonical time 0/12 for LONG
- verify `FOF_status` in 0/1 with explicit labels
- verify outcome branch and model-frame provenance
- verify missingness by FOF group and time
- verify participants versus observations
- figure-to-table-to-text crosscheck across Abstract, Methods, Results, figure
  legend, supplementary table, and model outputs
- table values take precedence over prose
- each new artifact receives exactly one manifest row
- record sessionInfo and renv diagnostics for any rerun

## Expected Artifacts After Approval And Execution

- `R-scripts/K50/outputs/<script_label>/k50_figure1_count_provenance.csv`
- `R-scripts/K50/outputs/<script_label>/paper_01_cohort_flow.wide_long.locomotor_capacity.pdf`
- `R-scripts/K50/outputs/<script_label>/paper_01_cohort_flow.wide_long.locomotor_capacity.svg`
- `R-scripts/K50/outputs/<script_label>/paper_01_cohort_flow.wide_long.locomotor_capacity.png`
- `R-scripts/K50/outputs/<script_label>/supplementary_missingness_by_fof_time.csv`
- `R-scripts/K50/outputs/<script_label>/figure1_crosscheck.md`
- sessionInfo and renv diagnostics if rendering or extraction is rerun
- one manifest row per artifact

## Constraints

- Do not modify raw data.
- Do not modify model specifications.
- Do not refit models solely to improve the figure.
- Do not modify `docs/ANALYSIS_PLAN.md`.
- Do not modify the active analysis-plan outcome hierarchy.
- Do not reuse the current LONG-labelled N = 230 image as manuscript Figure 1.
- Do not modify existing cohort-flow DOT, SVG, or PNG assets before count
  provenance is approved.
- Do not modify the current K50 Figure 2 CI review task or its manifest/QC
  changes.
- Do not commit or push unless separately authorized.
- Do not expose secrets or participant-level data.

## Acceptance Criteria

- [ ] Status remains `00-backlog` until a human approves moving this task to
      `tasks/01-ready/`.
- [ ] The current figure is treated as Major Revision and is not used
      unchanged for publication.
- [ ] All conflicting counts are resolved from locked sources.
- [ ] Source cohort N 527 versus 535 is resolved and documented.
- [ ] Valid baseline FOF N 472 versus 486 is resolved and documented.
- [ ] Missingness count conflicts 328/144 versus 340/146 are resolved and
      documented.
- [ ] WIDE branch N = 230, FOF yes = 161, and FOF no = 69 are validated from a
      locked WIDE ANCOVA model frame, not from the current LONG-labelled DOT.
- [ ] LONG unique participant N is derived directly from the locked primary
      LONG `merMod` model frame.
- [ ] LONG observation n is reported separately from participant N.
- [ ] WIDE and LONG branches use correct branch-specific inclusion rules.
- [ ] Main figure contains a shared source cohort and separate WIDE ANCOVA and
      LONG mixed-effects branches.
- [ ] Main figure excludes the missingness panel, FI22 note, zero-exclusion
      boxes, raw-row percentages, internal variable names, and embedded title.
- [ ] Supplementary missingness is produced as a real table.
- [ ] Final primary delivery format is vector PDF, with SVG and high-resolution
      PNG as secondary exports.
- [ ] Manuscript, figure, legend, supplementary table, and model outputs pass a
      figure-to-table-to-text crosscheck.
- [ ] New artifacts have explicit outcome, branch, and provenance labels.
- [ ] Each new artifact receives exactly one manifest row.
- [ ] Vector PDF passes visual review.
- [ ] Task reaches `03-review`; only a human may move it to `04-done`.

## Agent Report

Not started.

## Log

- 2026-07-18T00:00:00+0300 Created in `00-backlog` from expert Major Revision
  review. Awaiting human review and ready approval.

## Blockers

- Source cohort N conflict: 527 versus 535.
- Valid baseline FOF N conflict: 472 versus 486.
- Group-by-time missingness conflict: 328/144 versus 340/146.
- LONG participant N must be derived from the locked primary LONG `merMod`
  model frame and must not be inferred from 630 observations.
- WIDE N = 230 and FOF yes/no counts must be validated from a locked WIDE
  ANCOVA model frame.
