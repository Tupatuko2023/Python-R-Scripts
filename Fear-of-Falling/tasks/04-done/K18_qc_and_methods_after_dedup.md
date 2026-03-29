# K18 QC and methods after dedup

## Context

K50 person-level dedup and the production bridge `id <-> NRO` are now validated.
The next step is to stabilize the analysis state for Paper 01 by rerunning QC on
the canonical K50 long data path and documenting the dedup procedure in methods
notes.

## Inputs

- `R-scripts/K18/K18_QC.V1_qc-run.R`
- `R-scripts/K50/outputs/k50_long_locomotor_capacity_cohort_flow_counts.csv`
- `R-scripts/K20/outputs/k20_duplicate_person_summary.csv`
- `docs/paper01_methods_notes.md`

## Outputs

- rerun K18 QC artifacts against the current K50 long CSV path
- Paper 01 methods notes describing workbook lookup, `id <-> NRO`, and
  person-level dedup before participant gating

## Definition of Done (DoD)

- K18 QC is rerun or a deterministic blocker is documented
- Paper 01 methods notes document the dedup process and resulting analysis state
- analysis starting point is recorded as `N_ANALYTIC_PRIMARY=225`

## Log

- 2026-03-15T21:04:51+02:00 Task created for post-dedup QC rerun and Paper 01
  methods documentation.
- 2026-03-15T21:06:19+02:00 K18 QC rerun attempted against
  `paper_01/analysis/fof_analysis_k50_long.csv` with `--shape LONG` and the
  canonical dictionary. The run reached variable standardization and QC artifact
  writing, then hit the known Termux `readr`/`vroom` manifest bus-error.
- 2026-03-15T21:06:19+02:00 QC blocker classification: environment/runtime
  issue in manifest writing, not a dedup or schema failure. This is consistent
  with prior K18 manifest/runtime issues already documented elsewhere in the
  repo.
- 2026-03-15T21:06:19+02:00 Added `docs/paper01_methods_notes.md` documenting
  the production dedup procedure, bridge `id <-> NRO`, workbook-grounded person
  lookup, duplicate diagnostics (14 duplicate persons; 1 mergeable; 9 true
  conflicts; 4 identical), and the current analysis baseline
  `N_ANALYTIC_PRIMARY=225`.
