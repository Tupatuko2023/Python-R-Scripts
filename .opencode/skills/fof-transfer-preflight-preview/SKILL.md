---
name: fof-transfer-preflight-preview
description: Read-only advisory helper for the Windows<->Termux local file transfer workflow in the Python-R-Scripts repo (Fear-of-Falling). Formats preflight (--check) and preview commands, explains user-pasted JSON/JSONL output, and distinguishes VERIFIED transfer vs return receipt vs PLACED placement. Use when a task concerns LOCAL_FILE_TRANSFER_RUNBOOK.md, export_artifacts_to_windows.sh, fof_v2_ssh_adapter.py, fof_kb_pull.py, or place_verified_bundle.py. It never executes commands, accepts digests, activates profiles, or moves files.
---

# FOF transfer — preflight/preview advisor (read-only)

Advisory only. This skill formats and explains; **the human runs every command and enters every digest**. The authoritative procedure is `Fear-of-Falling/docs/LOCAL_FILE_TRANSFER_RUNBOOK.md`; this skill references it and does not restate or replace it.

## Scope (usage boundary — a soft boundary, not a technical block)

The mechanical safety (hard-deny, overwrite protection, conflict stop, fail-closed) lives in the executable scripts, **not** in this skill. Treat this as a usage contract for the agent, not a sandbox.

Allowed (read-only, advisory):
- Identify the transfer direction from the runbook table — direction A (Termux → Windows, outbound, `FOF_ARTIFACT_HANDOFF/2` / `LEGACY/1`) or direction B (Windows → Termux, pull, `FOF_KB_PULL/1`).
- Format the preflight command (`python3 scripts/termux/fof_v2_ssh_adapter.py --check`) and the preview commands (`export_artifacts_to_windows.sh --profile …`; `fof_kb_pull.py preview`; `place_verified_bundle.py preview`).
- Explain the output the user pastes back: `SUCCESS/0`, `FAILED/1`, `UNKNOWN_REMOTE_STATE/3`; `EMPTY_NOT_EXECUTABLE`; `PLACE_REJECTED: <CODE>`; per-file states (`ABSENT`/`ALREADY_PRESENT`/`CONFLICT`, `CREATED`).
- State what is missing and which human approvals are required.

Never (even if asked):
- Execute shell/SSH commands, or run any `--execute`, `pull`, or `place … execute`.
- Compute, accept, or substitute `content_digest` / `placement_digest` / `approved-*`.
- Activate or edit a profile (`EMPTY_NOT_EXECUTABLE` → enabled).
- Move, place, delete, or overwrite files.

## Three distinct states (do not conflate)
1. **Transfer `VERIFIED`** — the sender/receiver receipt (`VERIFIED.json` in staging); proves technical integrity only. Local `VERIFIED` ≠ return-receipt delivery — the return receipt to Windows is `NOT_DELIVERED` in this channel.
2. **Return receipt** — a separate delivery concern; `NOT_DELIVERED` here.
3. **`PLACED` placement** — a separate, separately-authorized `PLACE/1` step that produces an out-of-repo `PLACE_RECEIPT/1`. A transfer `VERIFIED` alone never implies placement.

## Command-effect notes (check before suggesting a command)
- `fof_v2_ssh_adapter.py --check`: builds an `ssh …` command → **network**; no payload.
- `export_artifacts_to_windows.sh` (preview): **no SSH** — SSH is permitted only with `--execute`. May write a bounded `<run_id>.json` diagnostic only if `FOF_V2_DIAG_ROOT` is pre-provisioned (never created by the tool).
- `fof_kb_pull.py preview/approve`: local preparation (**no network**); `serve`/`pull` use SSH.
- `place_verified_bundle.py preview`: **no writes**; `execute` writes targets (no-overwrite) plus an out-of-repo receipt.

## Missing-info checklist
Ask for: direction; the runbook placeholders (`$Profile`, `$SourceRoot`, `$BatchRoot`, `$StagingRoot`); the `run_id`; the pasted output; and confirmation of the human approvals (`content_digest`, `placement_digest`) — never fill these in.

## Reference
`Fear-of-Falling/docs/LOCAL_FILE_TRANSFER_RUNBOOK.md` — §1 daily path, §2 principles, §3 outbound, §4 pull, §5 the two previews, §6 placement, §7 recovery, §9 validation status.
