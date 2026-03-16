# K50 paper_01 cohort flow diagram

## Context

`K50` already produces canonical primary-analysis artifacts for `locomotor_capacity`,
including `qc_gates` and `missingness_group_time`, but it does not yet emit a
sequential participant-derivation table that can fill a paper-ready cohort-flow
diagram.

The next task is to add a minimal helper layer for the paper_01 cohort-flow /
missingness figure without changing the locked K50 model logic:

- derive sequential participant-level counts for the declared primary branch
- keep branch selection explicit as `LONG` or `WIDE`
- keep `locomotor_capacity` as the current primary line
- keep `z3` as fallback / sensitivity only
- keep `Composite_Z` as verified legacy bridge only
- render a sequential exclusion diagram plus a `Group x Time` missingness note

## Inputs

- `docs/ANALYSIS_PLAN.md`
- `QC_CHECKLIST.md`
- `CLAUDE.md`
- `R-scripts/K50/K50.V1_confirmatory-fof-locomotor-analysis.R` or verified K50 entrypoint
- `R-scripts/K50/outputs/` existing `qc_gates` and `missingness_group_time` artifacts
- reference structure `../Quantify-FOF-Utilization-Costs/diagram/aim2_cohort_flow.dot`

## Outputs

- `R-scripts/K50/outputs/k50_<shape>_<outcome>_cohort_flow_counts.csv`
- `R-scripts/K50/outputs/k50_<shape>_<outcome>_cohort_flow_placeholders.csv`
- `diagram/paper_01_cohort_flow.dot`
- `diagram/paper_01_cohort_flow.<shape>.<outcome>.svg`
- `diagram/paper_01_cohort_flow.<shape>.<outcome>.png`
- manifest rows for each new artifact

## Definition of Done (DoD)

- A new helper script derives sequential cohort-flow counts using the same
  canonical gates as K50 primary model preparation.
- The helper writes outputs under `R-scripts/K50/outputs/` and appends one
  manifest row per artifact.
- The helper emits placeholders that mechanically fill the DOT template.
- The DOT template preserves a sequential exclusion backbone and ends in
  `FOF Yes` / `FOF No`.
- The DOT note reports at minimum `FOF_status 0/1 x time 0/12` cells and
  outcome missingness counts.
- A smoke run succeeds for `LONG` + `locomotor_capacity`.
- K18 QC is rerun before the cohort-flow smoke run.
- Existing K50 model logic and current primary outputs remain analytically
  unchanged.
- Task moves to `tasks/03-review/` after implementation and smoke validation.

## Constraints

- Do not modify raw data or patient-level exports.
- Do not change existing K50 model formulas or current artifact semantics.
- Do not use `AUTO` for final primary branch logic.
- Do not mix `z3` or `Composite_Z` into the primary cohort-flow backbone.
- Keep changes within the minimal helper scope: derivation script, DOT template,
  render command, and only minimal docs/task bookkeeping if needed.

## Canonical run order

1. `python .codex/skills/fof-preflight/scripts/preflight.py`
2. `Rscript R-scripts/K18/K18_QC.V1_qc-run.R --data data/external/KaatumisenPelko.csv --shape AUTO --dict data/data_dictionary.csv`
3. `Rscript R-scripts/K50/K50.V1_confirmatory-fof-locomotor-analysis.R --data data/external/KaatumisenPelko.csv --shape LONG --outcome locomotor_capacity`
4. `Rscript R-scripts/K50/K50.1_COHORT_FLOW.V1_derive-cohort-flow.R --data data/external/KaatumisenPelko.csv --shape LONG --outcome locomotor_capacity`
5. `bash diagram/render_paper_01_cohort_flow.sh LONG locomotor_capacity`
6. Inspect `R-scripts/K50/outputs/`, `diagram/`, and `manifest/manifest.csv`

## Log

- 2026-03-15T00:00:00+02:00 Task created from orchestrator prompt `prompts/1_4cafofv2.txt`.
- 2026-03-15T00:00:00+02:00 Task added to `tasks/01-ready/` per orchestration exception for task creation.
- 2026-03-15T00:00:00+02:00 Task moved to `tasks/02-in-progress/` for implementation of the new cohort-flow helper, DOT template, and render command.
- 2026-03-15T00:00:00+02:00 Added `R-scripts/K50/K50.1_COHORT_FLOW.V1_derive-cohort-flow.R` to mirror K50 branch gates and emit sequential cohort-flow counts plus DOT placeholders under `R-scripts/K50/outputs/`.
- 2026-03-15T00:00:00+02:00 Added `diagram/paper_01_cohort_flow.dot` with a sequential exclusion backbone and embedded `Group x Time` missingness note.
- 2026-03-15T00:00:00+02:00 Added `diagram/render_paper_01_cohort_flow.sh` to resolve placeholders, render DOT -> SVG/PNG, and append manifest rows without depending on the broken local `readr::read_csv(manifest)` path.
- 2026-03-15T00:00:00+02:00 `fof-preflight` passed from repo root after the scoped Fear-of-Falling diff was in place.
- 2026-03-15T00:00:00+02:00 Direct `K18_QC` rerun from `data/external/KaatumisenPelko.csv` could not be completed in this environment: first Termux `renv` autoload failed on missing `cli`, and after `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE` the QC script hit a `readr/vroom` bus error while reading `manifest/manifest.csv`.
- 2026-03-15T00:00:00+02:00 Because the raw CSV is not a K50-ready canonical input (`FOF_status` absent), the cohort-flow helper smoke run was validated instead against the previously locked canonical LONG dataset at `/data/data/com.termux/files/home/FOF_LOCAL_DATA/paper_01/analysis/fof_analysis_k50_long.rds`.
- 2026-03-15T00:00:00+02:00 Smoke run completed successfully for `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript R-scripts/K50/K50.1_COHORT_FLOW.V1_derive-cohort-flow.R --data /data/data/com.termux/files/home/FOF_LOCAL_DATA/paper_01/analysis/fof_analysis_k50_long.rds --shape LONG --outcome locomotor_capacity`.
- 2026-03-15T00:00:00+02:00 Render completed successfully for `bash diagram/render_paper_01_cohort_flow.sh LONG locomotor_capacity`, producing resolved DOT, SVG, and PNG under `diagram/`.
- 2026-03-15T00:00:00+02:00 Final LONG cohort-flow counts are `N_RAW_ROWS=1102`, `N_RAW_ID=551`, `EX_FOF_MISSING_OR_INVALID=65`, `N_WITH_FOF=486`, `EX_BRANCH_STRUCTURE=0`, `EX_OUTCOME_MISSING_PRIMARY=237`, `N_OUTCOME_COMPLETE=249`, `EX_COVARIATE_MISSING_PRIMARY=10`, `N_ANALYTIC_PRIMARY=239`, `FOF_YES_ANALYTIC=169`, and `FOF_NO_ANALYTIC=70`.
- 2026-03-15T00:00:00+02:00 Manifest rows were appended for the new cohort-flow counts CSV, placeholders CSV, missingness CSV, input receipt, session info, resolved DOT, SVG, and PNG artifacts.
- 2026-03-15T00:00:00+02:00 Task moved to `tasks/03-review/`; residual review risk is that the sequential LONG cohort counts are participant-level complete-pair derivations and therefore intentionally differ from K50 mixed-model row counts (`rows_modeled=644`).
- 2026-03-15T00:00:00+02:00 Review/acceptance pass confirmed that the LONG counts CSV, placeholders CSV, resolved DOT, SVG/PNG, and manifest rows are internally consistent for the participant-level complete-pair cohort-flow chain (`551 - 65 = 486`, `486 - 237 = 249`, `249 - 10 = 239`, `169 + 70 = 239`).
- 2026-03-15T00:00:00+02:00 Review/acceptance pass also confirmed that the resolved DOT filename is normalized to `paper_01_cohort_flow.long.locomotor_capacity.resolved.dot`, that no unresolved `__PLACEHOLDER__` tokens remain, and that `K18/QC` stays explicitly documented as an infra/environment blocker rather than an acceptance basis for this task.
- 2026-03-15T00:00:00+02:00 Recommendation: accept this cohort-flow implementation as review-complete and treat any future K18/readr-vroom repair as a separate infrastructure task, not as a blocker for the paper_01 cohort-flow artifact set.
