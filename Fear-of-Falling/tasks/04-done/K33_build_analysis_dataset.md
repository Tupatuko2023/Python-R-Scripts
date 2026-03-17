# K33 Build Analysis Dataset

## Context

Implement canonical analysis dataset build for `docs/ANALYSIS_PLAN.md` using a strict tasks-gated workflow.

K20 numbering is reserved; this task uses K33.

This task must not run models. It only builds canonical analysis datasets and validates data structure/QC preconditions for K34.

## Inputs

- `docs/ANALYSIS_PLAN.md`
- `config/.env` (`DATA_ROOT` mandatory)
- Externalized patient-level inputs under `${DATA_ROOT}/paper_01/`
  - K32 capacity outputs
  - K15 frailty outputs
  - source columns for FOF/balance/covariates
- `R-scripts/K18/K18_QC.V1_qc-run.R`

## Outputs

- Canonical **long** analysis dataset (patient-level, external only):
  - exactly 2 rows per `id`
  - `time` in `{0, 12}`
- Canonical **wide** analysis dataset (patient-level, external only):
  - one row per `id`
  - baseline + 12m + delta fields
- In-repo receipt + aggregate QC summary only (no patient-level repo writes)
- Manifest rows for in-repo receipt/artifacts only

## Canonical Variable Contract (must match analysis plan exactly)

- `id`
- `time`
- `FOF_status`
- `frailty_cat_3`
- `tasapainovaikeus`
- `Composite_Z`
- `age`
- `sex`
- `BMI`

## Critical Balance Distinction (non-negotiable)

- `tasapainovaikeus` is an **exposure** variable in the analysis models.
- Objective balance (`Seisominen*`) belongs to capacity measurement lineage (K32 context) and must **not** replace `tasapainovaikeus` in K33 canonical exposure fields.
- Any attempt to substitute `Seisominen*` for `tasapainovaikeus` fails K33.

## Required QC Gates Before K34

K33 is PASS only if all conditions hold:

1. K18 QC runner PASS on the resolved dataset input.
2. `time` has exactly 2 levels: `{0, 12}`.
3. Wide dataset has unique `id` (1 row per id).
4. Delta identity check: `Delta = FollowUp - Baseline` with tolerance `1e-8`.
5. Exposure level checks for `frailty_cat_3` and `tasapainovaikeus` are explicit and valid.

## Governance Rules

- Patient-level I/O only under `${DATA_ROOT}`.
- No patient-level CSV/RDS under repo `R-scripts/*/outputs/`.
- Repo retains only aggregate outputs and receipt pointers.

## Proposed Implementation (when moved to 01-ready)

1. Resolve and print all input paths (deterministic resolver; fail fast if missing).
2. Build long and wide canonical datasets with exact variable names.
3. Run K18 QC and assert PASS.
4. Write patient-level datasets to `${DATA_ROOT}/paper_01/analysis/`.
5. Write in-repo receipt (paths, nrow/ncol, timestamp, checksums).
6. Append manifest rows for receipt/aggregate artifacts only.

## Definition of Done (DoD)

- Canonical long+wide datasets created externally.
- QC gates PASS and logged.
- No repo patient-level leakage.
- K34 can be moved to `01-ready` only after K33 PASS evidence exists.

## Log

- 2026-03-01 15:52: Backlog task created from template and populated from `docs/ANALYSIS_PLAN.md`.
- 2026-03-01 16:00: Implemented `R-scripts/K33/k33.r` (canonical long+wide dataset builder with DATA_ROOT-mandatory externalization, QC gates, K18-QC invocation, receipt + manifest logging).
- 2026-03-01 16:01: Ran `proot-distro login debian --termux-home -- bash -lc '... /usr/bin/Rscript R-scripts/K33/k33.r'` -> PASS.
- 2026-03-01 16:01: K18 QC result from K33 run: `QC OK: all required checks passed.` (`k18_qc_status=0` in K33 receipt).
- 2026-03-01 16:02: Verified K33 QC gates output:
  - `wide_id_unique=TRUE`
  - `time_exact_levels_0_12=TRUE`
  - `long_2_rows_per_id=TRUE`
  - `delta_identity_tol_1e8=TRUE`
  - `frailty_levels_valid=TRUE`
  - `tasapainovaikeus_levels_valid=TRUE`
- 2026-03-01 16:03: Ran `bash scripts/termux/run_qc_summarizer_proot.sh` -> PASS.
- 2026-03-01 16:03: Verified governance:
  - patient-level outputs written externally to `${DATA_ROOT}/paper_01/analysis/`
  - repo contains only K33 aggregate artifacts + receipt (`R-scripts/K33/outputs/`)
  - no `with_capacity_scores*.csv/.rds` leakage under repo outputs.

## Produced Artifacts

- Script: `R-scripts/K33/k33.r`
- In-repo aggregate artifacts:
  - `R-scripts/K33/outputs/k33_qc_gates.csv`
  - `R-scripts/K33/outputs/k33_patient_level_output_receipt.txt`
  - `R-scripts/K33/outputs/k33_sessioninfo.txt`
- External patient-level artifacts:
  - `${DATA_ROOT}/paper_01/analysis/fof_analysis_k33_long.csv`
  - `${DATA_ROOT}/paper_01/analysis/fof_analysis_k33_long.rds`
  - `${DATA_ROOT}/paper_01/analysis/fof_analysis_k33_wide.csv`
  - `${DATA_ROOT}/paper_01/analysis/fof_analysis_k33_wide.rds`

## Blockers

- None.

## Links

- `docs/ANALYSIS_PLAN.md`
- `R-scripts/K18/K18_QC.V1_qc-run.R`
