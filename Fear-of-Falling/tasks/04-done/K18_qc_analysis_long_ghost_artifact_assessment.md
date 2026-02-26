# K18 QC analysis_long ghost artifact assessment

## Context
Assess whether `data/processed/analysis_long.csv` is a real pipeline requirement or documentation debt, using repo evidence only.

## Inputs
- Ripgrep evidence for `analysis_long.csv`, `data/processed`, `--data`, `--shape`, `pivot_longer`, and write calls.
- K18 QC runner behavior from `R-scripts/K18/K18_QC.V1_qc-run.R`.
- Output/manifest conventions from AGENTS/CLAUDE/manifests.

## Outputs
- Deterministic recommendation: docs fix only (A) or export-step implementation (B).
- Minimal docs/runbook updates if recommendation is A.

## Definition of Done (DoD)
- Evidence list: where `analysis_long.csv` is referenced and where (if anywhere) it is written.
- Recommendation justified with code-level findings.
- If docs are edited, no raw-data changes and no generated outputs committed.

## Log
- 2026-02-26 00:07: task created in `01-ready`.
- 2026-02-26 00:17: moved to `02-in-progress`.
- 2026-02-26 00:31: repo evidence collected via ripgrep and code read.
- 2026-02-26 00:38: docs updated to remove `data/processed/analysis_long.csv` runbook dependency.
- 2026-02-26 00:42: K18_QC smoke run PASS with `--data data/external/KaatumisenPelko.csv --shape AUTO`.

## Evidence (repo-backed)
- `QC_CHECKLIST.md` and `QC_CHECKLIST_SYNC_STATUS.md` contained explicit `analysis_long.csv` references.
- `R-scripts/K18/K18_QC.V1_qc-run.R` requires `--data`, supports `--shape AUTO|LONG|WIDE`, and converts WIDE to LONG in-memory (`df_long`), so no mandatory on-disk long export.
- `R-scripts/K1/K1.2.data_transformation.R` builds `df_long`/`df_wide` objects but does not write `analysis_long.csv`.
- Write-call scans found no canonical writer for `analysis_long.csv` under pipeline outputs.
- K18_QC run with raw wide input succeeded: `QC OK: all required checks passed.`

## Decision
- **Selected path: A (docs/runbook fix).**
- Rationale: `analysis_long.csv` is a documentation assumption (ghost artifact), not a hard pipeline dependency.
- No new export script was added because runner behavior already supports direct QC from `--data` input (WIDE/LONG/AUTO).

## Validation
- Ripgrep evidence commands executed for:
  - `analysis_long.csv|analysis_long|df_long|pivot_longer|data/processed`
  - K18 runner CLI args `--data|--shape`
  - write calls (`write_csv`, `vroom_write`, `save_table_csv`)
- Runtime smoke (proot Debian):
  - `Rscript R-scripts/K18/K18_QC.V1_qc-run.R --data data/external/KaatumisenPelko.csv --shape AUTO --dict data/data_dictionary.csv`
  - Result: PASS (`QC OK: all required checks passed.`)

## Files changed
- `QC_CHECKLIST.md`
- `QC_CHECKLIST_SYNC_STATUS.md`
- `docs/ANALYSIS_PLAN.md`

## Blockers
- None.

## Links
- `QC_CHECKLIST.md`
- `R-scripts/K18/K18_QC.V1_qc-run.R`
- `R-scripts/K1/K1.2.data_transformation.R`
