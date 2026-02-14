# Task 1: Security Fix - Path Traversal in Data Preprocessing

**Status:** 02-in-progress (Assigned to: Jules / Security Agent)
**Created:** 2026-02-14

## Context
Google Jules identified a Path Traversal vulnerability in `scripts/10_preprocess_tabular.py` (line 76). The code directly joins a user-provided relative path with `DATA_ROOT` without validating if the resolved path escapes the root directory using `../`.

## Acceptance Criteria (DoD)
- [x] A new security utility `safe_join_path` is implemented in `scripts/_io_utils.py` and `scripts/path_resolver.py`.
- [x] `10_preprocess_tabular.py`, `00_inventory_manifest.py`, and `30_qc_summary.py` are refactored to use `safe_join_path`.
- [x] Error handling in `safe_join_path` **does not** leak the absolute path of `DATA_ROOT` to logs.
- [x] Security tests are added to `tests/security/test_path_traversal.py`.
- [x] Tests pass in the Termux environment.
- [x] Task is moved to `02-in-progress`, activity log updated, and finally a Pull Request is opened via `gh pr create`.

## Activity Log (ISO-8601)
* **2026-02-14T22:35:00** - Task 1 created based on orchestrator directive. Waiting for Jules to execute.
* **2026-02-14T22:40:00** - Task moved to 02-in-progress by Jules. Starting implementation of `safe_join_path`.
* **2026-02-14T22:55:00** - Refactored `_io_utils.py`, `path_resolver.py`, `10_preprocess_tabular.py`, `00_inventory_manifest.py`, and `30_qc_summary.py`. All security tests passed. Preparing for PR.
