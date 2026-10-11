---
name: fof-transfer-preflight-preview
description: Read-only advisory helper for the Windows<->Termux local file transfer workflow in the Python-R-Scripts repo (Fear-of-Falling). Formats preflight (--check) and preview commands, explains user-pasted JSON/JSONL output, and distinguishes VERIFIED transfer vs return receipt vs PLACED placement. Use when a task concerns LOCAL_FILE_TRANSFER_RUNBOOK.md, export_artifacts_to_windows.sh, fof_v2_ssh_adapter.py, fof_kb_pull.py, or place_verified_bundle.py. It never executes commands, accepts digests, activates profiles, or moves files.
---

# FOF transfer — preflight/preview advisor (read-only)

**CANDIDATE — not active.** This file lives at `tasks/03-review/skill-candidates/…`, outside OpenCode's skill-discovery path. Advisory only: it formats and explains; **the human runs every command and enters every digest**. The authoritative procedure is `Fear-of-Falling/docs/LOCAL_FILE_TRANSFER_RUNBOOK.md`; this skill references it and does not restate or replace it.

## Scope (usage boundary — a soft boundary, not a technical block)

The mechanical safety (hard-deny, overwrite protection, conflict stop, fail-closed) lives in the executable scripts, **not** in this skill.

Allowed (read-only, advisory):

- Identify the transfer direction from the runbook table — direction A (Termux → Windows, outbound, `FOF_ARTIFACT_HANDOFF/2` / `LEGACY/1`) or direction B (Windows → Termux, pull, `FOF_KB_PULL/1`).
- Format the runbook's commands as complete units with the required environment selections (below).
- Explain the output the user pastes back, per direction.
- State what is missing and which human approvals are required, per phase.

Never (even if asked):

- Execute shell/SSH commands, or run any `--execute`, `pull`, or `place … execute`.
- Compute, accept, or substitute `content_digest` / `placement_digest` / `approved-*`.
- Activate or edit a profile (`EMPTY_NOT_EXECUTABLE` → enabled).
- Move, place, delete, or overwrite files.

## Discovery / loading (OpenCode — the current Windows agent's platform)

- **Discoverable** — a file at `.opencode/skills/<name>/SKILL.md` (OpenCode walks up from the working directory to the git-worktree root). Discovery alone does **not** mean the skill was loaded or used.
- **Loaded** — an agent invoked OpenCode's `skill` tool with this ID.
- **Used** — the loaded instructions changed behaviour.

This candidate is intentionally outside `.opencode/skills/` (it is under `tasks/03-review/skill-candidates/`), so it is **not discoverable**. A prose prohibition is **not** a technical block; the location is what keeps it inactive. A Codex-specific variant is possible follow-up work, not part of this first candidate.

## Reading the result (infer from the user's run-correlated evidence — do not assume)

Infer each state **only** from the evidence the user supplies for that specific run (the pasted preview/receipt/`VERIFIED.json` fields such as `status`, `run_id`/`batch_id`, `content_digest`, `file_count`). If the evidence for a state is absent or not correlated to the run, mark that state **UNVERIFIED** — never fill it in.

1. **Transfer `VERIFIED`** — only if the run's receipt shows a correlated verified state (e.g. `status=VERIFIED` with matching `run_id`/`content_digest`/`file_count`). `SUCCESS/0` from the sender, `FAILED/1`, and `UNKNOWN_REMOTE_STATE/3` are the sender-side outcomes to interpret against that evidence.
2. **Return receipt** — a separate delivery concern; its state must be read from the evidence for **that** run. Do **not** hardcode `NOT_DELIVERED`: state it only when the supplied evidence actually shows it; otherwise **UNVERIFIED**. (The runbook notes that in the current channel the return receipt is typically not delivered — but that is a runbook property to check, not a constant to assume.)
3. **`PLACED` placement** — a separate, separately-authorized `PLACE/1` step producing an out-of-repo `PLACE_RECEIPT/1`. A transfer `VERIFIED` alone never implies placement; placement is `PLACED` only when its own receipt is supplied.

## Commands — runbook-complete units (placeholders in `<…>`)

Present these as whole units with the needed environment selections; **not** the adapter `--check` alone as a start command.

**Direction A — Termux → Windows (outbound)** — run from the `Fear-of-Falling` root. Env (Termux, not in Git): `FOF_V2_SSH_ALIAS`, `FOF_V2_RECEIVER_SCRIPT`, `FOF_V2_STAGING_DIR`.

```bash
python3 scripts/termux/fof_v2_ssh_adapter.py --check                    # preflight: SSH + PowerShell + receiver; no payload
bash scripts/termux/export_artifacts_to_windows.sh --profile <FOF-relative-profile.json>   # preview (no SSH)
# human reviews preview and approves the content_digest
bash scripts/termux/export_artifacts_to_windows.sh \
  --profile <FOF-relative-profile.json> \
  --execute --approved-content-digest "<APPROVED_CONTENT_DIGEST>" \
  --local-receiver "<abs>/scripts/termux/fof_v2_ssh_adapter.py"
```

**Direction B — Windows → Termux (pull).** Env (Termux): `FOF_KB_SSH_ALIAS`, `FOF_KB_REMOTE_SCRIPT`, `FOF_KB_REMOTE_BATCH_ROOT`.

```powershell
# [WINDOWS:POWERSHELL] prepare (no network)
python scripts/termux/fof_kb_pull.py preview --source-root <$SourceRoot> --profile <$Profile> --batch-root <$BatchRoot>
# human reviews the manifest -> <$BatchId>, <$Digest>
python scripts/termux/fof_kb_pull.py approve --batch "<$BatchRoot>/<$BatchId>" --approved-content-digest <$Digest>
```

```bash
# [TERMUX] preflight + pull
ssh -T -o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectionAttempts=1 -o ConnectTimeout=10 -o ClearAllForwardings=yes -o PermitLocalCommand=no "$FOF_KB_SSH_ALIAS" 'python --version'
python scripts/termux/fof_kb_pull.py pull --profile <$Profile> --batch-id <$BatchId> \
  --approved-content-digest <$Digest> --staging-root <$StagingRoot> --run-id <$RunId>
```

**Placement (`PLACE/1`, separate authorized step):**

```bash
python3 scripts/termux/place_verified_bundle.py preview \
  --staging-run "<$StagingRoot>/<$RunId>" --target-root <$TargetRoot> --map <$PlacementMap>
# human reviews preview and approves the placement_digest
python3 scripts/termux/place_verified_bundle.py execute \
  --staging-run "<$StagingRoot>/<$RunId>" --target-root <$TargetRoot> --map <$PlacementMap> \
  --approved-placement-digest "<APPROVED_PLACEMENT_DIGEST>" --receipt <$PlacementReceipt>
```

## Command-effect notes (verify from code before suggesting)

- `fof_v2_ssh_adapter.py --check`: builds an `ssh …` command → **network**; no payload.
- `export_artifacts_to_windows.sh` (preview): **no SSH** — SSH is permitted only with `--execute`. May write a bounded `<run_id>.json` diagnostic only if `FOF_V2_DIAG_ROOT` is pre-provisioned (never created by the tool).
- **`fof_kb_pull.py preview`: NOT read-only — local writes, no network.** It creates a new batch dir `new_directory(batch_root, batch_id)` and `snapshots/` (mode 0700), then `write_new(batch/'snapshots/NNNN', data)` for each selected file, plus `manifest.json` and `runtime.json` (refs: `fof_kb_pull.py` `def preview`, `new_directory`, `write_new`). `approve` writes the approval record into that batch. `serve`/`pull` use SSH.
- `place_verified_bundle.py preview`: **no writes**; `execute` writes targets (no-overwrite) plus an out-of-repo receipt.

## Missing info — by phase (use what is already verified; ask only what is missing)

- **Phase 1 — preparing the commands:** direction (A/B); the runbook placeholders that the chosen command actually needs (`$Profile`/`$SourceRoot`/`$BatchRoot` for B-preview; `$StagingRoot`/`$TargetRoot`/`$PlacementMap` for placement; the relevant env selections). Do **not** ask for `run_id` or a digest here — `run_id` does not exist yet and the digest is approved later.
- **Phase 2 — interpreting the preview output:** the pasted preview output (paths, sizes, SHA-256, `content_digest`, `staging_path`), plus the source-HEAD/repo identity if the tool printed it.
- **Phase 3 — the later approval / result:** the human-approved `content_digest` (transfer) or `placement_digest` (placement) for that run, and the run-correlated receipt evidence to read VERIFIED / return-receipt / PLACED.

## Sources (current documentation vs installed-version verification — keep separate)

- **Current documentation (official, OpenCode):** <https://opencode.ai/docs/skills/> — discovery from `.opencode/skills/<name>/SKILL.md`; frontmatter `name` + `description` required; `name` must equal the directory name.
- **Installed-version verification (local, this machine):** `opencode --version` → `1.18.35` (and `codex-cli 0.160.0` present). These confirm the installed tools, not that this candidate is loaded or used.

## Reference

`Fear-of-Falling/docs/LOCAL_FILE_TRANSFER_RUNBOOK.md` — §1 daily path, §2 principles, §3 outbound, §4 pull, §5 the two previews, §6 placement, §7 recovery, §9 validation status.
