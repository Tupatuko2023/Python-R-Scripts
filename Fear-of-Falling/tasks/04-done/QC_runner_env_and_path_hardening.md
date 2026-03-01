# QC Runner Env And PATH Hardening

## Context

### Objective
Harden Termux/PRoot QC runners so QC can be run deterministically without manual environment preload steps by ensuring `PATH` and optional `config/.env` are handled safely inside the runner process.

### Reproduction commands
- `cd Python-R-Scripts/Fear-of-Falling`
- Current manual-safe run pattern:
  - `set -a && . config/.env && set +a && bash scripts/termux/run_qc_summarizer_proot.sh`
- Expected improvement target:
  - `bash scripts/termux/run_qc_summarizer_proot.sh` works directly (no manual env preload) and remains deterministic.

### Proposed minimal fix
- Update `scripts/termux/run_qc_summarizer_proot.sh` (and optionally `run_k30_proot.sh`, `run_k31_proot.sh`) to:
  - set Debian `PATH` inside the same `proot ... bash -lc` call:
    - `export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin`
  - source `config/.env` safely if present:
    - e.g. `if [ -f config/.env ]; then set -a; . config/.env; set +a; fi`
  - guard against `set -u` failures for unset vars (notably `DATA_ROOT`) by using safe defaults or explicit checks before expansion.
- Keep behavior read-only regarding raw data; do not alter analysis logic.

## Inputs
- `scripts/termux/run_qc_summarizer_proot.sh`
- `scripts/termux/run_k30_proot.sh` (optional same hardening pattern)
- `scripts/termux/run_k31_proot.sh` (optional same hardening pattern)
- `config/.env`

## Outputs
- Runner(s) execute deterministically without manual `set -a && . config/.env && set +a`
- No regressions in qc-summarizer or analysis gate behavior

## Definition of Done (DoD)

### Acceptance criteria
- `bash scripts/termux/run_qc_summarizer_proot.sh` succeeds without manual env preload.
- Runner sets PATH safely inside proot execution context.
- No `DATA_ROOT: unbound variable` failures.
- `qc-summarizer` remains PASS and no patient-level data leaks into repo outputs.
- Changes are minimal, reversible, and isolated to runner scripts.

## Log

- 2026-03-01 09:55:00 Backlog task created for runner hardening (PATH + safe auto `.env` load) after milestone freeze.
- 2026-03-01 11:20:00 Moved task to `tasks/02-in-progress/` before edits.
- 2026-03-01 11:26:00 Implemented runner hardening:
  - `scripts/termux/run_qc_summarizer_proot.sh`:
    - source `config/.env` only if file exists
    - safe handling for unset `DATA_ROOT` under `set -u`
    - corrected in-proot variable expansion so `DATA_ROOT` is read inside proot shell
  - `scripts/termux/run_k30_proot.sh`:
    - source `config/.env` only if file exists
    - safe handling for unset `DATA_ROOT` under `set -u`
  - `scripts/termux/run_k31_proot.sh`:
    - source `config/.env` only if file exists
    - safe handling for unset `DATA_ROOT` under `set -u`
- 2026-03-01 11:30:00 Validation:
  - `bash scripts/termux/run_qc_summarizer_proot.sh` -> PASS (no manual env preload)
  - `bash scripts/termux/run_k30_proot.sh` -> PASS
  - `bash scripts/termux/run_k31_proot.sh` -> PASS
  - No `DATA_ROOT: unbound variable` failures observed.

## Blockers
- None.

## Links
- `scripts/termux/run_qc_summarizer_proot.sh`
- `scripts/termux/run_k30_proot.sh`
- `scripts/termux/run_k31_proot.sh`
- `config/.env`
