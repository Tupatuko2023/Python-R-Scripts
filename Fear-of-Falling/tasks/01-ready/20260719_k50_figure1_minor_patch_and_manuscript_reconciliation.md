# Task: K50 Figure 1 minor patch and manuscript reconciliation

## Status

01-ready

## Workflow

Follow `agent_workflow.md`. Only a task in `tasks/01-ready/` may be started.
The agent moves the task to `tasks/02-in-progress/` before work and to
`tasks/03-review/` after reporting. Only a human may move the task to
`tasks/04-done/`.

Current state: `01-ready`. Human approval released this task for the combined
Figure 1 minor patch and manuscript reconciliation.

## Scope

Define the combined follow-up work needed after the K50 Figure 1 post-audit.
This task covers a minor patch to the current dual-branch Figure 1 family and a
mandatory manuscript-wide consistency reconciliation.

This backlog task does not implement the patch. Do not change diagrams, QMD or
manuscript sources, producer scripts, generated outputs, `manifest/manifest.csv`,
analysis models, raw data, or current `tasks/03-review/` records in this task.

## Objective

Apply the expert post-audit minor patch to the K50 Figure 1 dual-branch diagram
and reconcile the complete manuscript chain with the locked Figure 1 provenance.

The current Figure 1 family remains at `03_REVIEW` and must not be promoted to
`MANUSCRIPT_CANDIDATE` until all required Figure-to-Abstract-to-Methods-to-
Results-to-Supplement crosschecks pass.

## Provenance And Implementation Commits

- Count provenance: `485808a`
- Visual rebuild task definition: `7dbf24a`
- Dual-branch render implementation: `e79c26c`

## Expert Post-Audit Decision Record

- Figure rebuild: **PASS WITH MINOR PATCH**
- Manuscript integration: **FAIL**
- Preparation gate: **AMBER**
- Editor mode: **Minor Revision for the figure; mandatory consistency
  correction before manuscript-candidate status**
- Suitability score: **8/10**
- Current repository status `03_REVIEW`: **correct**
- Final recommendation: **KEEP IN MAIN MANUSCRIPT after the minor figure patch
  and mandatory manuscript reconciliation**

## Locked Authoritative Counts

| Context | Unit | Total | FOF present | FOF absent |
| --- | --- | ---: | ---: | ---: |
| Locomotor-capacity source cohort | participants | 535 | NA | NA |
| Valid baseline FOF | participants | 472 | 328 | 144 |
| Baseline-adjusted ANCOVA | participants | 230 | 161 | 69 |
| Repeated-measures mixed-effects analysis | unique participants | 400 | 276 | 124 |
| Repeated-measures mixed-effects analysis | observations | 630 | NA | NA |

Historical or non-current values requiring removal or explicit sourced
explanation:

- `527`
- `486`
- `340/146`

Do not blind-replace `527` with `535`. The 535 source cohort and any manuscript
study-population claim must be reconciled from source objects and tables before
prose is changed.

## Current Decision

The figure is technically and scientifically improved, but it is not yet a
manuscript candidate.

Do not:

- move the visual rebuild task to `04-done`;
- mark the new diagram family `MANUSCRIPT_CANDIDATE`;
- mark the old diagram family `SUPERSEDED`;
- publish the new figure while the manuscript source still uses the historical
  WIDE-only asset or inconsistent counts.

## Manuscript Source Discovery

Repository search found no version-controlled `.qmd` file and no
`Results_Draft_version_2.qmd` under `Fear-of-Falling/` at backlog creation time.
The closest version-controlled manuscript-like source found in the search was
`docs/reports/abstract.md`, which contains a `527` study-population claim.

Future implementation must positively locate the source corresponding to
`Results_Draft_version_2.qmd`. If it is still absent, record a blocker and do
not edit a guessed manuscript path.

## Required Figure Patch

### Reader-Facing Terminology

Replace visible internal pipeline language.

Current internal-language examples:

- `Participants in locked ANCOVA model frame`
- `Unique participants in locked mixed-effects model frame`
- `Required for WIDE branch`
- `Required for LONG branch`

Required reader-facing replacement labels:

- `Participants included in the ANCOVA analysis`
- `Unique participants included in the mixed-effects analysis`
- `Eligibility for the baseline-adjusted analysis`
- `Eligibility for the repeated-measures analysis`

Visible artwork must not contain:

- `locked`
- `model frame`
- `WIDE branch`
- `LONG branch`
- R object names
- QC status labels
- task identifiers

### Explicit First Non-Inclusion

Add to the first transition in the figure or legend:

`Excluded: missing or invalid baseline fear-of-falling status, n = 63`

Calculation:

`535 - 472 = 63`

The producer must verify this difference from authoritative values rather than
storing `63` as an independent manually maintained number.

### Branch-Level Non-Inclusion

The locked branch differences are:

- baseline FOF eligible to ANCOVA: `472 - 230 = 242`
- baseline FOF eligible to mixed-effects analysis: `472 - 400 = 72`

These may be stated in the legend or a compact figure annotation when layout
remains readable.

Do not assign the 242 or 72 participants to specific missingness, dropout,
withdrawal, measurement-failure, unavailable-assessment, or covariate categories
without a verified source table.

### N/n Convention

Use consistent lower-case `n` throughout the flow diagram unless the manuscript
style guide explicitly documents a population-versus-subset `N/n` convention.

The convention must be identical in:

- figure
- legend
- Methods
- Results
- Supplement

## Manuscript-Ready Title

`Figure 1. Derivation of analytic samples for the baseline-adjusted and repeated-measures analyses of locomotor capacity`

Do not embed the title in the artwork unless required by the journal production
specification.

## Manuscript-Ready Legend

`Of 535 participants with locomotor-capacity source data, 472 had valid baseline fear-of-falling status and were considered for the branch-specific analyses. The baseline-adjusted 12-month ANCOVA included 230 participants with complete baseline and 12-month locomotor-capacity scores and complete age, sex, and body mass index data. The repeated-measures mixed-effects analysis included 400 unique participants contributing 630 eligible observations. Fear-of-falling group counts shown in the figure are participant-level counts. Detailed patterns of missingness are reported separately in Supplementary [Table/Figure X]. FOF, fear of falling.`

The legend may use the locked branch-level non-inclusion counts 242 and 72, but
it must not infer unsupported exclusion reasons.

## Mandatory Manuscript Reconciliation

Required manuscript corrections:

1. Abstract
   - resolve the current `527` study-population claim against the locked source
     cohort `535`;
   - do not perform a blind numeric replacement;
   - document whether the two values describe different populations;
   - retain only a value supported by a named source object or table.
2. Results
   - report the LONG analysis as `400 unique participants contributing 630
     observations`;
   - do not report `630 observations` as if it were the participant count.
3. Figure reference
   - replace the historical WIDE-only asset reference
     `paper_01_cohort_flow.wide.locomotor_capacity.png`;
   - use the reviewed `wide_long.locomotor_capacity` figure family and the
     repository's preferred vector/report path.
4. Caption
   - replace the WIDE-only caption;
   - describe both the baseline-adjusted ANCOVA and repeated-measures
     mixed-effects branches;
   - distinguish participants from observations.
5. Missingness
   - resolve historical `340/146` FOF groups against the locked baseline groups
     `328/144`;
   - use the authoritative supplementary missingness source;
   - do not mix population denominators across source cohort, baseline FOF,
     ANCOVA, and mixed-effects samples.
6. Figure roles
   - state that the new Figure 1 describes branch-specific analytic-sample
     derivation;
   - state that detailed missingness is reported separately in Supplementary
     material;
   - remove or archive the historical WIDE-only figure reference according to
     repository policy.

## Mandatory Manuscript-Wide Count Audit

Search Abstract, Methods, Results, figure captions, tables, supplement, QMD
variables, rendered text, and diagram sources for:

- `527`
- `535`
- `486`
- `472`
- `340`
- `146`
- `328`
- `144`
- `230`
- `161`
- `69`
- `400`
- `276`
- `124`
- `630`

For every occurrence record:

- file
- section
- displayed value
- unit
- population
- authoritative source
- current status
- required action
- crosscheck outcome

The number `535` must not replace `527` until the relationship between the
manuscript population and the Figure 1 source cohort is explicitly established.

## Figure-To-Manuscript Crosscheck

The task cannot enter `03-review` until all of the following are `PASS`:

1. Figure to count-provenance CSV.
2. Figure to legend.
3. Figure to Abstract.
4. Figure to Methods.
5. Figure to Results.
6. Figure to Supplement.
7. Participants to observations.
8. FOF group totals to branch totals.
9. Figure path to manuscript reference.
10. Main-figure role to Supplement missingness role.

The authoritative machine-readable provenance table takes precedence over
unsupported prose.

## Renderer And QC Language Patch

The current implementation contains review flags such as:

```r
grayscale_pass <- TRUE
count_pass <- TRUE
```

Do not represent human visual review as an automated measurement.

Required validation fields:

```text
count_authoritative_table_check=PASS
170_mm_resolution_check=PASS
170_mm_human_legibility_review=PASS
grayscale_human_review=PASS
human_reviewer=[identifier]
review_date=[YYYY-MM-DD]
```

Requirements:

- `count_authoritative_table_check` must be calculated from the locked
  provenance table.
- `170_mm_resolution_check` may be derived from pixel width and DPI.
- `170_mm_human_legibility_review` must be explicitly recorded as human review.
- `grayscale_human_review` must be explicitly recorded as human review.
- `human_reviewer` and `review_date` must not be silently fabricated by the
  script.
- The script may require these values as controlled parameters or record
  `PENDING` until supplied.
- A raw value such as `count_pass <- TRUE` is insufficient unless preceded by
  actual authoritative count comparisons.

## Expected Future Implementation Files

Potential modified sources:

- `R-scripts/K50/K50.FIG1_VISUAL_DUAL_BRANCH.V1_render.R`
- `diagram/paper_01_cohort_flow.wide_long.locomotor_capacity.dot`
- version-controlled manuscript QMD located during implementation
- `diagram/README.md`

Expected regenerated or new artifacts under:

`R-scripts/K50/outputs/FIG1_visual_dual_branch/`

Expected review outputs:

- patched resolved DOT
- patched PDF
- patched SVG
- patched PNG
- count and non-inclusion crosscheck
- manuscript-wide count audit
- figure-to-manuscript consistency report
- updated legend draft
- rendering validation report
- human-review record
- sessionInfo
- renv diagnostics when R is used
- rendered manuscript or report validation output when repository tooling
  supports it

Each new or changed generated artifact receives exactly one row in
`manifest/manifest.csv`. Do not append duplicate manifest rows for
deterministically overwritten artifacts when the manifest standard requires
updating the existing artifact record; follow `CLAUDE.md`'s manifest convention.

## Required Execution And Gates

Read `README.md` and the repository `Makefile` before selecting the exact
manuscript render command.

Use repository-provided paths:

- `make run RUN_SCRIPT=...` when applicable
- `make report REPORT=...` for the manuscript/report path when applicable
- `/usr/bin/Rscript` inside PRoot Debian for R work when needed
- `bash tools/run-gates.sh --project Fear-of-Falling`
- K18 QC path when manuscript or QC artifacts require it

Do not run Rscript, Graphviz, or Quarto while this backlog-definition task is
being created.

## Constraints

- Do not modify raw data.
- Do not change analysis models.
- Do not change the current diagram files in this backlog-definition task.
- Do not change QMD/manuscript sources in this backlog-definition task.
- Do not change the producer script in this backlog-definition task.
- Do not change generated outputs in this backlog-definition task.
- Do not change `manifest/manifest.csv` in this backlog-definition task.
- Do not change current `tasks/03-review/` records in this backlog-definition
  task.
- Do not move this task to `01-ready`, `03-review`, or `04-done` automatically.
- Do not expose secrets or participant-level data.

## Acceptance Criteria

- [ ] Internal pipeline terminology is removed from visible artwork.
- [ ] The `n = 63` baseline-FOF non-inclusion is shown in the figure or legend.
- [ ] Branch differences 242 and 72 are documented without unsupported causal
      labels.
- [ ] N/n notation is consistent or a documented N/n rule is applied across the
      manuscript package.
- [ ] New title and legend are used.
- [ ] Manuscript source corresponding to `Results_Draft_version_2.qmd` is
      positively identified, or its absence is recorded as a blocker.
- [ ] Abstract `527` versus source cohort `535` relationship is resolved from
      authoritative sources.
- [ ] Results report 400 unique participants and 630 observations.
- [ ] Manuscript uses the `wide_long.locomotor_capacity` figure family.
- [ ] WIDE-only caption is removed.
- [ ] Missingness `340/146` versus `328/144` is resolved.
- [ ] Figure-Abstract-Methods-Results-Supplement crosscheck passes.
- [ ] Human visual review is distinguished from automated checks.
- [ ] `170_mm_resolution_check` is separate from
      `170_mm_human_legibility_review`.
- [ ] `grayscale_human_review` is separate from automated render QC.
- [ ] `human_reviewer` and `review_date` fields are present in the validation
      report.
- [ ] `count_pass` is not used as a hardcoded `TRUE` without authoritative table
      comparison.
- [ ] One manifest row exists for every new or changed generated artifact.
- [ ] Repository and manuscript gates pass.
- [ ] New diagram family may remain `03_REVIEW` pending human acceptance.
- [ ] No task is moved to `04-done` automatically.

## Agent Report

Blocked before combined implementation. The task was released to `01-ready`,
but repository search did not identify a version-controlled QMD corresponding
to `Results_Draft_version_2.qmd`.

No figure, producer, generated output, manuscript, manifest, analysis, raw-data,
or current `03-review` task changes were made.

## Log

- 2026-07-19T00:00:00+0300 Created from the expert post-audit following visual
  rebuild commit `e79c26c`.
- 2026-07-19T00:00:00+0300 Human approval: released to `01-ready` for the
  combined Figure 1 minor patch and manuscript reconciliation.
- 2026-07-19T00:00:00+0300 Blocked before implementation: no version-controlled
  `.qmd` file and no `Results_Draft_version_2.qmd` were found under
  `Fear-of-Falling/` or the repository parent search path used for this task.

## Blockers

- BLOCKED: Version-controlled `Results_Draft_version_2.qmd` was not found under
  `Fear-of-Falling/`, and no `.qmd` file was found in the subproject. The
  combined figure/manuscript implementation must not proceed until the real
  manuscript QMD source is added or positively identified.
