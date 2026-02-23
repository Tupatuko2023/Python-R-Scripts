# Optional Hygiene Follow-up: MCP Stdout + Doc Drift

## Context

This is an optional post-merge hygiene follow-up after PR #103 rollout completion.
Core enforcement behavior is already merged and validated on `main`. This task targets
two non-blocking quality improvements raised in review:

1. `Fear-of-Falling/agents/codex_mcp.py` emits unexpected stdout in `__main__`.
2. Possible wording drift risk between docs and code around contribution preflight path references.

## Inputs

- Existing merged implementation from PR #103.
- Sourcery follow-up comments (post-merge hygiene).
- Current canonical code helper:
  - `Fear-of-Falling/agents/contribution_preflight.py`
  - `MAKE_REPO_CONTRIBUTION_SKILL_PATH`

## Outputs

- Small follow-up PR scope (when/if moved to `tasks/01-ready/`) limited to:
  1. Gate/remove default debug stdout from `Fear-of-Falling/agents/codex_mcp.py` in normal MCP mode.
  2. Adjust `SKILLS.md` wording to reduce doc/code drift risk while keeping Python constant canonical.

## Definition of Done (DoD)

- Task remains optional hygiene and is implemented only after human moves it to `tasks/01-ready/`.
- Proposed implementation (future) is limited to these files:
  - `Fear-of-Falling/agents/codex_mcp.py`
  - `SKILLS.md`
  - optional doc touchpoint if needed:
    - `.codex/skills/make-repo-contribution/tests.md` or
    - `docs/repo-wide-contribution-enforcement-checklist.md`
- Acceptance criteria for future PR:
  - No extra stdout by default in MCP server mode.
  - Contribution-enforcement behavior unchanged.
  - `python -m compileall -q Fear-of-Falling/agents` passes.
  - Existing helper-based smoke still returns `SMOKE_OK`.

## Non-Goals

- No change to merged contribution-enforcement semantics.
- No network-dependent rollout steps.
- No execution of repo documentation embedded scripts.
- No attempt to "share one constant" across Python and Markdown.

## Log

- 2026-02-23 11:45:00 Created optional backlog follow-up task from `tasks/_template.md`.
- 2026-02-23 11:45:00 Scope fixed to hygiene only (MCP stdout gating + doc wording drift mitigation).
- 2026-02-23 11:45:00 Task intentionally kept in `tasks/00-backlog/`; no implementation started.

## Blockers

- None (optional task). Execution blocked by workflow gate until moved to `tasks/01-ready/` by human.

## Links

- `tasks/04-done/2026-02-23_repo-wide-make-repo-contribution-rollout.md`
- `Fear-of-Falling/agents/codex_mcp.py`
- `Fear-of-Falling/agents/contribution_preflight.py`
- `SKILLS.md`
