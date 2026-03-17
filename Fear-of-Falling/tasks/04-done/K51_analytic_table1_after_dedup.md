# K51 analytic Table 1 after dedup

## Goal

Update `K51` so the main paper_01 Table 1 follows the deduplicated updated K50
analytic cohort instead of the older baseline-eligible descriptive cohort.

## Scope

- keep the canonical K51 input/output skeleton
- reuse shared `R/functions/person_dedup_lookup.R`
- reuse the same K50-style inclusion chain used by the current deduplicated
  cohort-flow path
- add `--cohort-scope analytic|baseline_eligible|selection_compare`
- write separate artifacts for:
  - analytic Table 1
  - baseline-eligible supplementary Table 1
  - analytic vs not analytic selection table

## Definition of Done

- main K51 Table 1 is restricted to the deduplicated K50 analytic cohort
- local LONG smoke run reproduces `N_ANALYTIC_PRIMARY = 230`
- K51 does not implement its own parallel person-dedup chooser
- separate supplementary baseline-eligible and selection-table artifacts are
  written under `R-scripts/K51/outputs/`
- manifest rows are appended for new K51.1 artifacts

## Log

- 2026-03-16T00:00:00+02:00 Task created from orchestrator prompt `prompts/6_4cafofv2.txt`.
- 2026-03-16T00:00:00+02:00 Task moved to `tasks/02-in-progress/` for a minimal K51.1 follow-up scoped to deduplicated cohort selection.
- 2026-03-16T00:00:00+02:00 Added `R-scripts/K51/K51.V1_baseline-table-k50-canonical.R` back to the current branch with canonical `--data` + explicit `--shape LONG|WIDE` input handling, shared `person_dedup_lookup.R`, and new `--cohort-scope analytic|baseline_eligible|selection_compare`.
- 2026-03-16T00:00:00+02:00 Reused the current K50 cohort-flow inclusion chain on the deduplicated person basis (`FOF valid -> branch eligible -> complete primary outcome -> complete age/sex/BMI covariates`) so K51 no longer maintains a parallel person chooser.
- 2026-03-16T00:00:00+02:00 LONG smoke runs succeeded against `/data/data/com.termux/files/home/FOF_LOCAL_DATA/paper_01/analysis/fof_analysis_k50_long.rds` for all three scopes: `analytic`, `baseline_eligible`, and `selection_compare`.
- 2026-03-16T00:00:00+02:00 The deduplicated LONG cohort sizes matched the current cohort-flow state: `baseline_eligible_n=472`, `analytic_n=230`, `not_analytic_n=242`.
- 2026-03-16T00:00:00+02:00 New artifacts written under `R-scripts/K51/outputs/` include `k51_long_baseline_table_analytic.csv/html`, `k51_long_baseline_table_baseline_eligible.csv/html`, and `k51_long_selection_table_analytic_vs_not_analytic.csv/html`, plus scope-specific decision logs, receipts, and session info files.
- 2026-03-16T00:00:00+02:00 Decision logs now state explicitly that, after person-level deduplication in updated K50, the main Table 1 follows the deduplicated analytic cohort (`n=230` user-reported target) while baseline-eligible and selection tables are supplementary.
- 2026-03-16T00:00:00+02:00 Acceptance/review pass confirmed that the three K51.1 scopes remain explicit and internally consistent: analytic main table (`n=230`), baseline-eligible supplementary table (`n=472`), and selection comparison (`472 - 230 = 242` not analytic).
- 2026-03-16T00:00:00+02:00 Acceptance/review pass also confirmed that all scope-specific decision logs and receipts point to the same canonical LONG input path and md5, and that manifest rows exist for CSV, HTML, decision-log, input-receipt, and sessioninfo artifacts for each new scope.
- 2026-03-16T00:00:00+02:00 Recommendation: accept K51.1 as review-complete and treat any future population drift as a rerun requirement from the shared K50 inclusion chain, not as a reason to restore the old baseline-only main Table 1 scope.
