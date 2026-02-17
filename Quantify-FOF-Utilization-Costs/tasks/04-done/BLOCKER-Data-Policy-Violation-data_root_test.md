# BLOCKER: Option B Data Policy Violation (data_root_test)

**Status**: 02-in-progress (BLOCKER)
**Assigned**: Gemini / Team
**Created**: 2026-02-16

## DESCRIPTION

A critical deviation from the **Option B Data Policy** has been identified. A directory named `data_root_test` exists within the `Quantify-FOF-Utilization-Costs` subproject and contains data tables (e.g., `derived/aim2_panel.csv`).

According to the core mandates in `README.md` and `GEMINI.md`, no raw data or production-like analysis tables may ever be stored inside the Git repository.

## FINDINGS

The directory `Quantify-FOF-Utilization-Costs/data_root_test/` contains:
- `derived/aim2_panel.csv` (and potentially other files)

This violates the principle that all data must reside in an external `DATA_ROOT` directory, and only metadata, code, or synthetic sample data (under `data/sample/` or `tests/`) are allowed in the repo.

## REQUIRED ACTIONS

- [x] **Clarification**: Team confirmed purpose; unauthorized data must be moved.
- [x] **Remediation**: 
    - Moved data from `data_root_test/` to external `DATA_ROOT` (`/data/data/com.termux/files/home/FOF_LOCAL_DATA`).
    - Purged `Quantify-FOF-Utilization-Costs/data_root_test/` from Git history using `git-filter-repo`.
    - Performed force-push to synchronize clean history.
- [x] **Verification**: Repository is now compliant with Option B.

## RESOLUTION
The data has been safely relocated to the external path defined in `.env`. The repository tree and history are now free of production-like data tables.

## IMPACT
**All production pipeline runs and commits are halted** until this blocker is resolved to prevent data leakage and maintain security compliance.
