# TASK: Address Sourcery AI review (OUTPUT_DIR centralization, Snakefile quoting, R defaults, subprocess audit)

## STATUS
- State: 02-in-progress

## OBJECTIVE
- Centralize OUTPUT_DIR resolution across scripts.
- Quote OUTPUT_DIR usage in Snakefile shell commands (spaces-safe).
- Align R script defaults with OUTPUT_DIR behavior.
- Audit inventory wrapper execution path safety (no shell invocation risk).

## DEFINITION OF DONE
- Shared helper added for OUTPUT_DIR resolution.
- 50_build_report.py uses shared helper (no inline duplicate getenv pattern).
- Snakefile quotes OUTPUT_DIR in shell commands.
- 30_models_panel_nb_gamma.R defaults to OUTPUT_DIR env when args are missing.
- Inventory wrapper reviewed for subprocess risk and repo-internal script-path safety.
- Rebase + push + remote verify done.
- Task moved to 03-review (not 04-done).

## LOG
- 2026-02-14T22:50:56.1779101+02:00 Created task and moved to 02-in-progress.
- 2026-02-14T22:52:02.3789436+02:00 Implemented OUTPUT_DIR helper + Snakefile quoting + R OUTPUT_DIR defaults.
- 2026-02-14T22:52:02.3789436+02:00 Audited inventory wrapper: no subprocess.run usage; runpy-based execution retained (no code change required).
