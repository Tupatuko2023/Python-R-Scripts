# K18 QC Requires Data Arg Fix

## Context

### Objective
Unblock K18 QC execution by removing manual ambiguity around mandatory `--data` usage while preserving explicit failure when data cannot be found. Implement a minimal reversible fix that does not touch raw data.

### Reproduction commands
- `cd Python-R-Scripts/Fear-of-Falling`
- `proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; cd Python-R-Scripts/Fear-of-Falling && /usr/bin/Rscript R-scripts/K18/K18_QC.V1_qc-run.R'`
- Expected current failure: `ERROR: --data is required (path to CSV).`

### Proposed minimal fix
- Update `R-scripts/K18/K18_QC.V1_qc-run.R` argument handling:
  - keep `--data` supported as first priority,
  - add `DATA_PATH` env var fallback,
  - if neither is provided, attempt repo-relative candidate search for analysis data using K30-like pattern:
    `data/raw/`, `data/external/`, `data/`, `dataset/`, repo root,
  - if still missing, fail with informative error including all tried paths and exact usage example.
- Optional wrapper fallback (if script policy prefers no parser changes): update `scripts/termux/run_qc_summarizer_proot.sh` or add a K18 runner wrapper that injects resolved `--data`.

## Inputs
- `R-scripts/K18/K18_QC.V1_qc-run.R`
- Existing dataset conventions in repo (`data/raw`, `data/external`, `data`, `dataset`)
- Optional `DATA_PATH` env var

## Outputs
- Updated K18 QC runner behavior/documented usage
- Clear runtime messages for discovered path vs missing path

## Definition of Done (DoD)

### Acceptance criteria
- K18 QC can run without manual confusion:
  - with explicit `--data <path>` works,
  - without `--data`, sensible default discovery or `DATA_PATH` fallback is attempted,
  - if unresolved, script stops with tried paths + exact example command.
- Fix is minimal and reversible.
- No raw dataset files are modified.

## Log

- 2026-02-28 16:58:00 Backlog task created from template to unblock K18 QC `--data` requirement.
- 2026-03-01 03:18:00 Moved task to `tasks/02-in-progress/` before code edits.
- 2026-03-01 03:19:00 Baseline reproduced:
  - Command: `set -a && . config/.env && set +a && proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; cd Python-R-Scripts/Fear-of-Falling && /usr/bin/Rscript R-scripts/K18/K18_QC.V1_qc-run.R'`
  - Result: `ERROR: --data is required (path to CSV).`
- 2026-03-01 03:28:00 Implemented resolver in `R-scripts/K18/K18_QC.V1_qc-run.R`:
  - Added `resolve_data_path()` with order:
    1) explicit `--data`
    2) `DATA_PATH`
    3) repo-relative candidates (`data/`, `data/raw/`, `data/external/`, K30/K31 local outputs)
    4) `DATA_ROOT/paper_01/capacity_scores/*`
    5) K30/K31 receipt pointers
  - Added informative unresolved error listing all tried paths and usage hints.
  - Added console print: `Resolved data path: ...`
  - Added `.rds` and `.csv` support in data loading.
- 2026-03-01 03:35:00 Validation (explicit `--data`): PASS
  - Command: `set -a && . config/.env && set +a && proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; cd Python-R-Scripts/Fear-of-Falling && /usr/bin/Rscript R-scripts/K18/K18_QC.V1_qc-run.R --data data/external/KaatumisenPelko.csv'`
  - Result: `QC OK: all required checks passed.`
- 2026-03-01 03:35:00 Validation (without `--data`, discovery): PASS
  - Command: `set -a && . config/.env && set +a && proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; cd Python-R-Scripts/Fear-of-Falling && /usr/bin/Rscript R-scripts/K18/K18_QC.V1_qc-run.R'`
  - Result: resolved path printed, then `QC OK: all required checks passed.`
- 2026-03-01 03:36:00 End-to-end check: PASS
  - Command: `set -a && . config/.env && set +a && bash scripts/termux/run_qc_summarizer_proot.sh`
  - Result: exit 0; `qc_summary.csv` and `qc_summary.txt` appended and manifest updated.

## Blockers
- None.

## Links
- `prompts/Frailty_Model_Copilot_2.txt`
- Related script: `R-scripts/K18/K18_QC.V1_qc-run.R`
