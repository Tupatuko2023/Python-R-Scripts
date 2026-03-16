# K50 env loader for cohort flow

## Context

`K50.r` and the cohort-flow helper resolve canonical input from
`Sys.getenv("DATA_ROOT")`, but the visible code does not automatically load
`config/.env`. In this shell, `DATA_ROOT` is empty unless `config/.env` is
explicitly sourced before `Rscript`.

The cohort-flow helper now has an additional paper_02 workbook dependency for
person-level dedup, so a missing `DATA_ROOT` causes avoidable failures even
when `config/.env` already defines the correct path.

## Inputs

- `R-scripts/K50/K50.r`
- `R-scripts/K50/K50.1_COHORT_FLOW.V1_derive-cohort-flow.R`
- `config/.env`

## Outputs

- minimal helper-side fallback that loads `config/.env` only when `DATA_ROOT`
  is absent from the process environment
- verification notes distinguishing canonical input resolution from workbook
  resolution

## Definition of Done (DoD)

- code evidence is collected for `K50.r` canonical-input-only behavior
- code evidence is collected for prior helper environment behavior
- helper can resolve `DATA_ROOT` from `config/.env` without requiring shell
  `source`, when the variable is otherwise absent

## Log

- 2026-03-15T19:12:00+02:00 Task created for path-resolution verification and a
  minimal `config/.env` fallback in the K50 cohort-flow helper.
- 2026-03-15T19:16:00+02:00 Verified from code that `R-scripts/K50/K50.r`
  resolves only canonical analysis-ready input via `DATA_ROOT/paper_01/analysis`
  or `--data`; no `paper_02`, workbook path, or `read_excel` call appears in
  the script.
- 2026-03-15T19:17:00+02:00 Verified from code and shell that prior cohort-flow
  helper behavior depended on `Sys.getenv("DATA_ROOT")` and did not load
  `config/.env` automatically. In this shell, plain `Rscript` saw empty
  `DATA_ROOT`, while `set -a && . config/.env && set +a` made it visible.
- 2026-03-15T19:19:00+02:00 Added minimal helper fallback:
  `load_data_root_from_env_file()` reads `config/.env` only when `DATA_ROOT` is
  absent, then `resolve_data_root()` uses that value.
- 2026-03-15T19:20:00+02:00 Validation passed: helper parses successfully, and
  `env -u DATA_ROOT ... Rscript --vanilla R-scripts/K50/K50.1_COHORT_FLOW...`
  now advances past missing-env handling into workbook verification. Prior
  review log confirms earlier workbook validation was synthetic only.
