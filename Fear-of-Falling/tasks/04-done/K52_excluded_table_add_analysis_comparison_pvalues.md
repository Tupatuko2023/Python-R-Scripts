# K52 excluded table add analysis comparison p-values

## Goal

Add one new comparison column to the K52 excluded-population table so each row
shows whether the excluded-population value differs from the analytic
population value within the same FOF stratum.

## Scope

- update only `R-scripts/K52/K52.V1_selection-and-excluded-baseline-tables.R`
- keep K51 and K50 unchanged
- keep `k52_long_analysis_vs_excluded_table.*` as a separate artifact
- preserve current K52 population definitions and counts

## Required behavior

- keep current excluded-table columns intact
- add one new column:
  `P vs analytic (same FOF stratum)`
- format each cell as:
  `Without FOF: ... | With FOF: ...`
- compute:
  excluded without FOF vs analytic without FOF
  excluded with FOF vs analytic with FOF

## Acceptance targets

- excluded table still shows `Without FOF (n=75)` and `With FOF (n=167)`
- new same-stratum comparison column exists in CSV and HTML
- current `P-value` column for excluded internal With vs Without FOF stays
- analysis-vs-excluded table remains separate and unchanged in scope
- K52 counts remain `472 / 230 / 242`

## Log

- 2026-03-17T00:00:00+02:00 Task created from orchestrator prompt
  `prompts/28_4cafofv2.txt`.
- 2026-03-17T00:00:00+02:00 Updated
  [K52.V1_selection-and-excluded-baseline-tables.R](/data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling/R-scripts/K52/K52.V1_selection-and-excluded-baseline-tables.R)
  with a small K52.1 patch that adds one new excluded-table column
  `P vs analytic (same FOF stratum)`.
- 2026-03-17T00:00:00+02:00 LONG rerun succeeded on canonical input
  `/data/data/com.termux/files/home/FOF_LOCAL_DATA/paper_01/analysis/fof_analysis_k50_long.rds`.
  Updated excluded output:
  [k52_long_excluded_population_table.csv](/data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling/R-scripts/K52/outputs/k52_long_excluded_population_table.csv)
  now has columns:
  `Variable`, `Without FOF (n=75)`, `With FOF (n=167)`, `P-value`,
  `P vs analytic (same FOF stratum)`.
- 2026-03-17T00:00:00+02:00 Sample rendered cells confirm the new format:
  `Without FOF: ... | With FOF: ...`.
  Example rows now show values such as
  `Without FOF: 0.709 | With FOF: 0.298` and
  `Without FOF: 0.298 | With FOF: 0.017`.
- 2026-03-17T00:00:00+02:00 Verified that
  [k52_long_analysis_vs_excluded_table.csv](/data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling/R-scripts/K52/outputs/k52_long_analysis_vs_excluded_table.csv)
  remains a separate 33-row artifact with unchanged scope.
- 2026-03-17T00:00:00+02:00 Verified that K52 population definitions remain
  unchanged in
  [k52_long_decision_log.txt](/data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling/R-scripts/K52/outputs/k52_long_decision_log.txt):
  `472 / 230 / 242`, excluded `75 / 167`, and the decision log now explicitly
  documents the new same-stratum analytic comparison column.
- 2026-03-17T00:00:00+02:00 Validation:
  `python ../.codex/skills/fof-preflight/scripts/preflight.py`
  returned `Preflight status: PASS`.
- 2026-03-17T00:00:00+02:00 Review acceptance:
  accept this K52.1 follow-up implementation. The excluded table keeps its
  internal excluded FOF `P-value` column, adds the new
  `P vs analytic (same FOF stratum)` column, preserves the separate
  analysis-vs-excluded artifact, and leaves K52 population definitions
  unchanged at `472 / 230 / 242` with excluded `75 / 167`.
