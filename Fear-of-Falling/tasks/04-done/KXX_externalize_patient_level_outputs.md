# KXX Externalize Patient-Level Outputs

## Context

### Objective
Externalize patient-level outputs (CSV/RDS) from in-repo `R-scripts/*/outputs/` to `${DATA_ROOT}/paper_01/...` using `config/.env` as the authoritative source for `DATA_ROOT`, while keeping aggregate/review artifacts and manifest discipline intact.

### Reproduction commands
- `cd Python-R-Scripts/Fear-of-Falling`
- Verify env wiring:
  - `test -f config/.env && grep -n "DATA_ROOT" config/.env`
  - `proot-distro login debian --termux-home -- bash -lc 'cd Python-R-Scripts/Fear-of-Falling && set -a && source config/.env && set +a && echo "DATA_ROOT=$DATA_ROOT"'`
- Current K30/K31 runs (still in-repo writes until task implemented):
  - `scripts/termux/run_k30_proot.sh`
  - `scripts/termux/run_k31_proot.sh`

### Proposed minimal fix (for when task moves to 01-ready)
- In K30/K31 scripts (and any other patient-level writers):
  - Keep aggregate diagnostics in `R-scripts/Kxx/outputs/`.
  - Route patient-level dataset outputs (`*.csv`, `*.rds`) to `${DATA_ROOT}/paper_01/<script>/`.
  - Add explicit `DATA_ROOT` validation with informative error if unset.
- Keep manifest entries for all artifacts, using absolute/relative paths consistently.
- Do not modify raw source datasets.

## Inputs
- `config/.env` (`export DATA_ROOT=...`)
- `R-scripts/K30/k30.r`
- `R-scripts/K31/k31.r`
- `R/functions/reporting.R`

## Outputs
- Patient-level outputs written outside repo under `${DATA_ROOT}/paper_01/...`
- In-repo outputs still contain aggregate diagnostics and logs

## Definition of Done (DoD)

### Acceptance criteria
- `DATA_ROOT` loaded from `config/.env` in execution flow.
- Patient-level outputs are externalized to `${DATA_ROOT}/paper_01/...`.
- Aggregate outputs and reproducibility artifacts remain in repo output folders.
- No raw datasets are changed.

## Log

- 2026-02-28 18:53:00 Backlog task created for deterministic DATA_ROOT-based externalization of patient-level outputs.
- 2026-02-28 18:56:00 Moved task to `tasks/02-in-progress/` before code edits.
- 2026-02-28 19:01:00 Updated `R-scripts/K30/k30.r`:
  - patient-level CSV/RDS now write to `${DATA_ROOT}/paper_01/capacity_scores/`
  - added hard fail if `DATA_ROOT` missing
  - added repo receipt `R-scripts/K30/outputs/k30_patient_level_output_receipt.txt`
  - manifest now logs receipt only for patient-level output.
- 2026-02-28 19:02:00 Updated `R-scripts/K31/k31.r`:
  - patient-level CSV/RDS now write to `${DATA_ROOT}/paper_01/capacity_scores/`
  - added hard fail if `DATA_ROOT` missing
  - added repo receipt `R-scripts/K31/outputs/k31_patient_level_output_receipt.txt`
  - manifest now logs receipt only for patient-level output.
- 2026-02-28 19:03:00 Validation run log:
  - `bash scripts/termux/run_k30_proot.sh` -> exit 0
  - `bash scripts/termux/run_k31_proot.sh` -> exit 0
  - receipts present in repo outputs
  - external files present under `${DATA_ROOT}/paper_01/capacity_scores/` with non-zero size
  - manifest appended:
    - `k30_patient_level_output_receipt`
    - `k31_patient_level_output_receipt`
  - warning observed (non-blocking): `renv out-of-sync` status message during runs.

## Blockers
- None.

## Links
- `config/.env`
- `scripts/termux/run_k30_proot.sh`
- `scripts/termux/run_k31_proot.sh`
- `scripts/termux/run_qc_summarizer_proot.sh`
