# TASK: Remove path examples from env templates (Option B hardening)

## STATUS
- State: 02-in-progress

## OBJECTIVE
- Replace any path-like examples in .env.example / .env.template with placeholders.
- Ensure docs/README do not include concrete path examples.

## DEFINITION OF DONE
- config/.env.example uses:
  - DATA_ROOT=__SET_ME__
  - ALLOW_AGGREGATES=0
  - OUTPUT_DIR=outputs
- config/.env.template has no concrete paths (placeholder only).
- Task moved to 03-review.
- Rebase + push + remote verify completed.

## LOG
- 2026-02-15T15:21:32.9740795+02:00 Created task and moved to 02-in-progress.
