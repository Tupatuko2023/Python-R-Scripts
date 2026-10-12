---
name: fof-transfer-preflight-preview
description: Read-only advisory helper for the Windows<->Termux local file transfer workflow in the Python-R-Scripts repo (Fear-of-Falling). Prepares preflight (--check) and preview commands only, explains user-pasted JSON/JSONL output, and distinguishes VERIFIED transfer vs return receipt vs PLACED placement. Use when a task concerns LOCAL_FILE_TRANSFER_RUNBOOK.md, export_artifacts_to_windows.sh, fof_v2_ssh_adapter.py, fof_kb_pull.py, or place_verified_bundle.py. It never executes commands, accepts digests, activates profiles, or moves files.
---

# FOF transfer — preflight/preview advisor (read-only)

**CANDIDATE — not active.** This file lives at `tasks/03-review/skill-candidates/…`, outside OpenCode's skill-discovery path. Advisory only: it prepares **preflight and preview** commands and explains output; **the human runs every command and enters every digest**. The authoritative procedure is `Fear-of-Falling/docs/LOCAL_FILE_TRANSFER_RUNBOOK.md`; this skill references it and does not restate or replace it.

## Scope (usage boundary — a soft boundary, not a technical block)

The mechanical safety (hard-deny, overwrite protection, conflict stop, fail-closed) lives in the executable scripts, **not** in this skill.

This skill prepares **only preflight and preview** commands.

- **In scope:** identify the direction (A outbound / B pull); prepare the preflight command and the transfer-preview / placement-preview commands; explain the user's pasted output; state what is missing and which human approval is required.
- **Out of scope (do not prepare these commands):** the **transfer `execute`**, the **`approve`**, and the **`pull`/`serve`** steps. For those, point to the runbook section and describe the human approval required (see "Later phases" below).

Never (even if asked):

- Execute shell/SSH commands, or run any `--execute`, `approve`, `pull`, `serve`, or `place … execute`.
- Compute, accept, or substitute `content_digest` / `placement_digest` / `approved-*`.
- Activate or edit a profile (`EMPTY_NOT_EXECUTABLE` → enabled).
- Move, place, delete, or overwrite files.

## Discovery / loading (OpenCode — the current Windows agent's platform)

- **Discoverable** — a file at `.opencode/skills/<name>/SKILL.md` (OpenCode walks up from the working directory to the git-worktree root). Discovery alone does **not** mean the skill was loaded or used.
- **Loaded** — an agent invoked OpenCode's `skill` tool with this ID.
- **Used** — the loaded instructions changed behaviour.

This candidate is intentionally outside `.opencode/skills/` (it is under `tasks/03-review/skill-candidates/`), so it is **not discoverable**. A prose prohibition is **not** a technical block; the location is what keeps it inactive. A Codex-specific variant is possible follow-up work, not part of this first candidate.

## Reading the result (infer from the user's run-correlated evidence — do not assume)

Infer each state **only** from the evidence the user supplies for that specific run (the pasted preview/receipt/`VERIFIED.json` fields such as `status`, `run_id`/`batch_id`, `content_digest`, `file_count`). If the evidence for a state is absent, or belongs to a **different** `run_id`/`batch_id` than the run in question, mark that state **UNVERIFIED** — never fill it in.

1. **Transfer `VERIFIED`** — only if the run's receipt shows a correlated verified state (e.g. `status=VERIFIED` with matching `run_id`/`content_digest`/`file_count`). `SUCCESS/0`, `FAILED/1`, and `UNKNOWN_REMOTE_STATE/3` are the sender-side outcomes to interpret against that evidence.
2. **Return receipt** — a separate delivery concern; read its state from the evidence for **that** run. Do **not** hardcode `NOT_DELIVERED`: state it only when the supplied evidence shows it; otherwise **UNVERIFIED**. (The runbook notes the current channel typically does not deliver the return receipt — a runbook property to check, not a constant to assume.)
3. **`PLACED` placement** — a separate, separately-authorized `PLACE/1` step producing an out-of-repo `PLACE_RECEIPT/1`. A transfer `VERIFIED` alone never implies placement; placement is `PLACED` only when its **own** receipt is supplied for the run.

## Commands to prepare — preflight + preview only (NOT run-ready templates)

These are **incomplete templates**, not runnable commands. Quoted placeholders (`"<…>"`) must be replaced first; an un-replaced template is **not run-ready**. Present them as whole units with the needed environment selections; do not present the adapter `--check` alone as a start command.

**Direction A — Termux → Windows (outbound)** — run from the `Fear-of-Falling` root. Env (Termux, not in Git): `FOF_V2_SSH_ALIAS`, `FOF_V2_RECEIVER_SCRIPT`, `FOF_V2_STAGING_DIR`.

```bash
# NOT RUN-READY TEMPLATE — replace the quoted placeholders first.
python3 scripts/termux/fof_v2_ssh_adapter.py --check                        # preflight: SSH + PowerShell + receiver; no payload
bash scripts/termux/export_artifacts_to_windows.sh --profile "<FOF_RELATIVE_PROFILE_JSON>"   # preview (no SSH)
```

**Direction B — Windows → Termux (pull), Windows-side preview only** (no network). Env (Termux): `FOF_KB_SSH_ALIAS`, `FOF_KB_REMOTE_SCRIPT`, `FOF_KB_REMOTE_BATCH_ROOT`.

```powershell
# NOT RUN-READY TEMPLATE — Windows-side preview only; replace the quoted placeholders first.
python scripts/termux/fof_kb_pull.py preview --source-root "<SOURCE_ROOT>" --profile "<PROFILE_JSON>" --batch-root "<BATCH_ROOT>"
```

**Placement-preview (`PLACE/1`)** — requires an **existing** staging run identifier.

```bash
# NOT RUN-READY TEMPLATE — requires an existing staging run id; replace the quoted placeholders first.
python3 scripts/termux/place_verified_bundle.py preview \
  --staging-run "<STAGING_ROOT>/<RUN_ID>" --target-root "<TARGET_ROOT>" --map "<PLACEMENT_MAP>"
```

## Later phases — reference the runbook, do not prepare the command

- **Transfer execute (direction A/B):** the human runs it after reviewing the preview and approving the `content_digest`. See runbook §3 (A) / §4 (B). Describe the approval; do not prepare the `--execute`/`pull` command.
- **Approve (direction B):** the human records the approval after reviewing the manifest. See runbook §4. Describe it; do not prepare the `approve` command.
- **Placement execute:** the human runs it after reviewing the placement preview and approving the `placement_digest`. See runbook §6. Describe it; do not prepare the `execute` command.

## Command-effect notes (verify from code before suggesting)

- `fof_v2_ssh_adapter.py --check`: builds an `ssh …` command → **network**; no payload.
- `export_artifacts_to_windows.sh` (preview): **no SSH** — SSH is permitted only with `--execute`. May write a bounded `<run_id>.json` diagnostic only if `FOF_V2_DIAG_ROOT` is pre-provisioned (never created by the tool).
- **`fof_kb_pull.py preview`: NOT read-only — local writes, no network.** It creates a new batch dir `new_directory(batch_root, batch_id)` and `snapshots/` (mode 0700), then `write_new(batch/'snapshots/NNNN', data)` for each selected file, plus `manifest.json` and `runtime.json` (refs: `fof_kb_pull.py` `def preview`, `new_directory`, `write_new`). `approve` writes the approval record into that batch; `serve`/`pull` use SSH.
- `place_verified_bundle.py preview`: **no writes**; `execute` writes targets (no-overwrite) plus an out-of-repo receipt.

## Missing info — by phase (use what is already verified; ask only what is missing)

- **Phase 1 — preparing the commands:** direction (A/B); the runbook placeholders the chosen command actually needs (`$Profile`/`$SourceRoot`/`$BatchRoot` for the B-preview; the relevant env selections). For the **placement-preview** phase, ask for the **existing staging run identifier** (`$StagingRoot`/`$RunId`) — that run already exists. Do **not** ask for a digest at this phase.
- **Phase 2 — interpreting the preview output:** the pasted preview output (paths, sizes, SHA-256, `content_digest`, `staging_path`), plus the source-HEAD/repo identity if the tool printed it.
- **Phase 3 — the later approval / result:** the human-approved `content_digest` (transfer) or `placement_digest` (placement) for that run, and the run-correlated receipt evidence to read VERIFIED / return-receipt / PLACED.

## Sources (current documentation vs installed-version verification — keep separate)

- **Current documentation (official, OpenCode):** <https://opencode.ai/docs/skills/> — discovery from `.opencode/skills/<name>/SKILL.md`; frontmatter `name` + `description` required; `name` must equal the directory name.
- **Installed-version verification (local, this machine):** `opencode --version` → `1.18.35` (and `codex-cli 0.160.0` present). These confirm the installed tools, not that this candidate is loaded or used.

## Reference

`Fear-of-Falling/docs/LOCAL_FILE_TRANSFER_RUNBOOK.md` — §1 daily path, §2 principles, §3 outbound, §4 pull, §5 the two previews, §6 placement, §7 recovery, §9 validation status.
