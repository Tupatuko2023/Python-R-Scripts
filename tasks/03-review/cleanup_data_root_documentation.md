# Task: DATA_ROOT Documentation Cleanup (doc-only)

## Type
- Documentation-only change
- No code changes
- No runs
- No DATA_ROOT dependency
- No impact on Table 1

## Goal
- SYSTEM_PROMPT_UPDATE.md contains only a short gate + link to full protocol
- Long DATA_ROOT protocol moved to a single policy file
- No duplicate copies elsewhere

## Scope
- Edit docs only
- Create policy file under Quantify-FOF-Utilization-Costs/docs/policies/

## Non-goals
- Do not touch Table 1 logic or any R/Python code
- Do not run scripts
- Do not refactor anything unrelated to DATA_ROOT docs

## Acceptance criteria
- SYSTEM_PROMPT_UPDATE.md has a short, authoritative DATA_ROOT gate + link
- Full protocol exists in Quantify-FOF-Utilization-Costs/docs/policies/DATA_ROOT_PROTOCOL.md
- No duplicate long protocol text in other files

## Workflow gates
- Follow WORKFLOW.md
- Create in 01-ready, move to 02-in-progress only when starting
- Move to 03-review when done
- 04-done only after review

## Log
- 2026-02-07T11:12:50+02:00 Moved to 02-in-progress and started doc cleanup.
- 2026-02-07T11:14:49+02:00 Siirretty DATA_ROOT-ohje SYSTEM_PROMPT_UPDATE.md -> docs/policies/DATA_ROOT_PROTOCOL.md ja lisätty linkkipointerit.
