# K30 Continuous Physical Capability / Locomotor Capacity Scoring

## Context
Implement K30 continuous physical capability scoring from `KaatumisenPelko.csv` according to `Frailty_Model_Copilot_1.txt` and `CLAUDE.md` standards.

Tasks gate rule from orchestrator prompt: if no matching K30 task exists in `tasks/01-ready/`, create this backlog task from template and stop implementation work.

## Inputs
- `KaatumisenPelko.csv` from one of:
  - `data/raw/`
  - `data/external/`
  - `data/`
  - `dataset/`
  - or explicit `DATA_PATH` env var
- Spec references:
  - `Frailty_Model_Copilot_1.txt`
  - `CLAUDE.md`
  - `R/functions/reporting.R` (manifest helper)

## Outputs
- New script:
  - `R-scripts/K30/k30.r`
- New artifacts under:
  - `R-scripts/K30/outputs/`
- Manifest append:
  - one row per artifact in `manifest/manifest.csv`

## Definition of Done (DoD)
- `k30.r` runs in a clean R session and finds data via candidate paths or `DATA_PATH`; otherwise fails with informative error.
- Required variable mapping (`puristus0_clean`, `kavelynopeus_m_sek0`, `oma_arvio_liikuntakyky`) is robust; unresolved mapping fails hard with closest-match suggestions.
- Script writes all audit artifacts, decision log, CFA outputs (primary+sensitivity), z-composite outputs, analysis-ready dataset (`.csv` + `.rds`), and `sessionInfo` under `R-scripts/K30/outputs/`.
- Gait-speed zero handling implemented in dual form:
  - primary: `0 -> NA`
  - sensitivity: `0` retained
- Manifest logging is done via project helper (`append_manifest` from `reporting.R`), one row per artifact.
- Task progression for implementation phase:
  - move to `tasks/02-in-progress/` before coding
  - move to `tasks/03-review/` after validation with run log

## Log
- 2026-02-28 16:03:00 Created backlog task from template because no K30 task was found in `tasks/01-ready/`.
- 2026-02-28 16:34:00 Moved task `00-backlog -> 01-ready -> 02-in-progress` before code changes.
- 2026-02-28 16:39:00 Implemented `R-scripts/K30/k30.r` (robust load, mapping/suggestions, audits, red flags, decision log, CFA primary+sensitivity, z-composites, output dataset, sessionInfo, manifest appends).
- 2026-02-28 16:41:00 Validation run command:
  `proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; cd Python-R-Scripts/Fear-of-Falling && /usr/bin/Rscript R-scripts/K30/k30.r'`
- 2026-02-28 16:41:00 Validation result: success (exit 0).
- 2026-02-28 16:41:00 Warnings observed: lavaan reported negative observed residual variances and could not compute some EBM factor scores for at least one model variant.
- 2026-02-28 16:41:00 Outputs written under `R-scripts/K30/outputs/`; manifest rows appended under `manifest/manifest.csv` for K30 artifacts.
- 2026-02-28 16:52:00 Follow-up prompted by `prompts/Frailty_Model_Copilot_2.txt`: reopened task (`03-review -> 01-ready -> 02-in-progress`) for defensive scoring revision.
- 2026-02-28 16:53:00 Ran `fof-preflight` skill: PASS.
- 2026-02-28 16:54:00 Tried K18 QC workflow prerequisites:
  - `R-scripts/K18/K18_QC.V1_qc-run.R` halted with `--data is required`.
  - `fof-qc-summarizer` script halted due existing manifest `n` column type mismatch (character vs integer) in shared helper path.
- 2026-02-28 16:55:00 Updated `R-scripts/K30/k30.r` to defensive mode:
  - self-report direction auto-selection via correlation sign check,
  - primary score set to z-composite (`capacity_score_primary`),
  - CFA retained as sensitivity/diagnostic only,
  - added `k30_cfa_diagnostics.csv` artifact.
- 2026-02-28 16:55:00 Validation rerun command:
  `proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; cd Python-R-Scripts/Fear-of-Falling && /usr/bin/Rscript R-scripts/K30/k30.r'`
- 2026-02-28 16:55:00 Validation result: success (exit 0). Decision log selected self-report orientation B (A score -0.486, B score +0.486).
- 2026-02-28 16:55:00 CFA diagnostics confirmed inadmissible triad CFA in both variants (negative residual variance, standardized loading >1, score NA share 1.0), so composite remains defensible primary.

## Blockers
- None after successful validation run.

## Links
- Prompt packet: `prompts/1_11cafof.txt`
- Follow-up prompt: `prompts/Frailty_Model_Copilot_2.txt`
