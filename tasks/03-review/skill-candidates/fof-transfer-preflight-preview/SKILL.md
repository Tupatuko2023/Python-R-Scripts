---
name: fof-transfer-preflight-preview
description: Read-only advisory helper for the Windows<->Termux local file transfer workflow in the Python-R-Scripts repo (Fear-of-Falling). Formats preflight (--check) and preview commands, explains user-pasted JSON/JSONL output, and distinguishes VERIFIED transfer vs return receipt vs PLACED placement. Use when a task concerns LOCAL_FILE_TRANSFER_RUNBOOK.md, export_artifacts_to_windows.sh, fof_v2_ssh_adapter.py, fof_kb_pull.py, or place_verified_bundle.py. It never executes commands, accepts digests, activates profiles, or moves files.
---

# FOF transfer — preflight/preview advisor (read-only)

**CANDIDATE — not active.** This file lives at `tasks/03-review/skill-candidates/…`, outside every OpenCode/Codex skill-discovery path. Advisory only: it formats and explains; **the human runs every command and enters every digest**. The authoritative procedure is `Fear-of-Falling/docs/LOCAL_FILE_TRANSFER_RUNBOOK.md`; this skill references it and does not restate or replace it.

## Three states (keep them distinct)

1. **Discoverable** — the file sits in a directory a CLI scans (OpenCode: `.opencode/skills/<name>/SKILL.md`; Codex: `.codex/skills/` or `.agents/skills/`). Discovery alone does **not** mean the skill was loaded or used.
2. **Loaded** — an agent invoked the `skill` tool with this ID and read the body.
3. **Used** — the loaded instructions changed the agent's behaviour.

A path is only "inactive" if it is outside every discovery path. This candidate is placed accordingly; a prohibition in prose is **not** a technical block.

## Scope (usage boundary — a soft boundary, not a technical block)

The mechanical safety (hard-deny, overwrite protection, conflict stop, fail-closed) lives in the executable scripts, **not** in this skill.

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

## Three distinct transfer states (do not conflate)
1. **Transfer `VERIFIED`** — the sender/receiver receipt (`VERIFIED.json` in staging); proves technical integrity only. Local `VERIFIED` ≠ return-receipt delivery — the return receipt to Windows is `NOT_DELIVERED` in this channel.
2. **Return receipt** — a separate delivery concern; `NOT_DELIVERED` here.
3. **`PLACED` placement** — a separate, separately-authorized `PLACE/1` step producing an out-of-repo `PLACE_RECEIPT/1`. A transfer `VERIFIED` alone never implies placement.

## Command-effect notes (verify from code before suggesting)
- `fof_v2_ssh_adapter.py --check`: builds an `ssh …` command → **network**; no payload.
- `export_artifacts_to_windows.sh` (preview): **no SSH** — SSH is permitted only with `--execute`. May write a bounded `<run_id>.json` diagnostic only if `FOF_V2_DIAG_ROOT` is pre-provisioned (never created by the tool).
- **`fof_kb_pull.py preview`: NOT read-only — local writes, no network.** It creates a new batch dir `new_directory(batch_root, batch_id)` and `snapshots/` (mode 0700), then `write_new(batch/'snapshots/NNNN', data)` for each selected file (copying its bytes), plus `manifest.json` and `runtime.json` (refs: `fof_kb_pull.py` `def preview`, `new_directory`, `write_new`). `approve` writes the approval record into that batch. `serve`/`pull` use SSH.
- `place_verified_bundle.py preview`: **no writes**; `execute` writes targets (no-overwrite) plus an out-of-repo receipt.

## Missing-info checklist
Ask for: direction; the runbook placeholders (`$Profile`, `$SourceRoot`, `$BatchRoot`, `$StagingRoot`); the `run_id`; the pasted output; and confirmation of the human approvals (`content_digest`, `placement_digest`) — never fill these in.

## Sources (current documentation vs installed-version verification — keep separate)
- **Current documentation (official):**
  - OpenCode skills: https://opencode.ai/docs/skills/ — discovery from `.opencode/skills/<name>/SKILL.md`; frontmatter `name` + `description` required; `name` must equal the directory name.
  - Codex skills: https://developers.openai.com/codex/skills and https://developers.openai.com/codex/build-skills — `SKILL.md` with `name` + `description`.
- **Installed-version verification (local, this machine):** `codex --version` → `codex-cli 0.160.0`; `opencode --version` → `1.18.35`. These confirm the installed tools, not that this candidate is loaded or used.

## Reference
`Fear-of-Falling/docs/LOCAL_FILE_TRANSFER_RUNBOOK.md` — §1 daily path, §2 principles, §3 outbound, §4 pull, §5 the two previews, §6 placement, §7 recovery, §9 validation status.
