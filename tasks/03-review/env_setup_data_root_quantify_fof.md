# TASK: DATA_ROOT env setup (Option B, no path leakage)

## STATUS
- State: 01-ready
- Priority: High
- Assignee: Codex

## OBJECTIVE
- Configure Option B env loading for Quantify-FOF-Utilization-Costs without leaking absolute paths.

## SCOPE
- Create or update env loader files with placeholder only: DATA_ROOT=<ABSOLUTE_PATH_TO_EXTERNAL_DATA>.
- Ensure fallback bootstrap script and gitignore rules exist.
- Add safe smoke checks (0/1 and OK/FAIL only).

## DEFINITION OF DONE
- Quantify-FOF-Utilization-Costs/config/.env exists locally and is not committed (placeholder only if created).
- Quantify-FOF-Utilization-Costs/config/.env.example contains placeholder.
- Quantify-FOF-Utilization-Costs/.envrc loads config/.env and fail-closed without printing values.
- Quantify-FOF-Utilization-Costs/scripts/bootstrap_env.sh exists and is executable.
- .gitignore contains Quantify-FOF-Utilization-Costs/config/.env, .env, .envrc.allow.
- Savetests defined, do not print DATA_ROOT values.

## LOG
- 2026-02-07T06:24:24+02:00 Created task (orchestrator override). No DATA_ROOT values logged.
- 2026-02-07T06:25:22+02:00 Updated .env.example, added .envrc, added bootstrap_env.sh, updated .gitignore. No DATA_ROOT values logged.

## SAVETEST (no path leakage)
- Set? (0/1 only):
  bash -lc 'source Quantify-FOF-Utilization-Costs/scripts/bootstrap_env.sh >/dev/null 2>&1; python -c "import os; print(1 if os.getenv(\"DATA_ROOT\") else 0)"'
- Dir exists? (OK/FAIL only):
  bash -lc 'source Quantify-FOF-Utilization-Costs/scripts/bootstrap_env.sh >/dev/null 2>&1; test -d "$DATA_ROOT" && echo OK || echo FAIL'
- 2026-02-07T06:33:36+02:00 Gates run: tools/run-gates.sh --project Quantify-FOF-Utilization-Costs --mode analysis (exit 0). Task moved to 03-review.
- 2026-02-07T06:34:17+02:00 Gate metadata outputs set to local-only via .gitignore; generated files removed from working tree.
