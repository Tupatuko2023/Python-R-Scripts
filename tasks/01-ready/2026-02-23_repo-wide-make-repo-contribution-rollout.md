# Repo-Wide Make-Repo-Contribution Enforcement Rollout

## Context
Roll out PR #101 intent repo-wide so any agent entrypoint capable of contribution actions (issue/branch/commit/PR) must first discover and follow CONTRIBUTING/README/docs plus issue/PR templates, while enforcing global security boundaries that override repo docs.

## Inputs
- Request packet: repo-wide enforcement with single DRY helper, no skill-body duplication.
- Target scope includes root and Fear-of-Falling agent/orchestrator entrypoints.
- Global boundaries: no network access, no outside-working-tree file access, no execution of repo-documented scripts/executables.

## Outputs
- Blocked-until-ready gate outcome documented.
- Proposed future artifacts (after human moves this task to `tasks/01-ready/`):
  - discovery map of entrypoints,
  - shared enforcement helper,
  - wiring updates,
  - SKILLS/docs/checklist updates,
  - 3-commit series (`chore(skills)`, `feat(agents)`, `docs`).

## Definition of Done (DoD)
- This task is moved by human gatekeeper from `tasks/00-backlog/` to `tasks/01-ready/`.
- Baseline availability is resolved inside repo working tree (PR #101 content present locally without network or outside-tree access).
- Only after both gates above are satisfied can implementation begin.

## Log
- 2026-02-23 00:00:00 Created backlog task from template per tasks workflow gate.
- 2026-02-23 00:00:00 Verified task-template exists at repo root (`tasks/_template.md`) and created this file under `tasks/00-backlog/`.
- 2026-02-23 00:00:00 Recorded hard security boundary block: external PR URL and `/mnt/data/...` artifact cannot be used under current rules.

## Blockers
- Hard security block: cannot fetch PR #101 over network and cannot access `/mnt/data/...` because it is outside repo working tree.
- Workflow gate: rollout implementation is not allowed until human moves this task to `tasks/01-ready/`.

## Links
- `tasks/_template.md`
- `tasks/00-backlog/2026-02-23_repo-wide-make-repo-contribution-rollout.md`
- `Fear-of-Falling/agent_workflow.md`

## Baseline Inventory (2026-02-23)
- Gate status:
  - `pr101` baseline fetched locally and checked out from `origin/pull/101/head`.
  - Task workflow gate cleared: task now in `tasks/01-ready/`.
- Skill baseline presence:
  - `.codex/skills/make-repo-contribution/SKILL.md` exists.
  - `.codex/skills/make-repo-contribution/README.md` exists.
  - `.codex/skills/make-repo-contribution/tests.md` exists.
  - `SKILLS.md` references skill path at least at lines containing:
    - `MANDATORY ... .codex/skills/make-repo-contribution/SKILL.md`
    - `Make Repo Contribution skill: .codex/skills/make-repo-contribution/SKILL.md`
- Local PR #101 delta vs `main` (`git diff --name-only main...HEAD`):
  - `.codex/skills/make-repo-contribution/README.md`
  - `.codex/skills/make-repo-contribution/SKILL.md`
  - `.codex/skills/make-repo-contribution/tests.md`
  - `Fear-of-Falling/agents/run_single.py`
  - `Fear-of-Falling/agents/run_workflow.py`
  - `SKILLS.md`

## Repo-Wide Discovery (Initial Map)
- `Fear-of-Falling/agents/run_workflow.py`
  - Role: workflow entrypoint/orchestrator demo (`argparse`, `__main__`).
  - Contribution capability: yes (creates `integrator` with `run_git`, writes files via tool call path).
  - Current enforcement: embeds instruction string to consult contribution skill.
- `Fear-of-Falling/agents/run_single.py`
  - Role: single-run security smoke entrypoint (`__main__`).
  - Contribution capability: yes (invokes `write_file` via agent tool calls).
  - Current enforcement: embeds instruction string to consult contribution skill.
- `Fear-of-Falling/agents/agent_types.py`
  - Role: shared agent runtime abstraction; executes tool calls (`read_file`, `write_file`, `run_git`).
  - Contribution capability: indirect yes (common execution path used by entrypoints).
  - Current enforcement: no shared preflight helper yet; instructions passed in by callers.
- `Fear-of-Falling/agents/codex_mcp.py`
  - Role: Codex MCP wrapper process launcher.
  - Contribution capability: potential, depending on caller wiring.
  - Current enforcement: no contribution preflight injection in this module.

## Next Implementation Scope
- Introduce one shared helper/module for contribution preflight instruction injection.
- Wire all discovered entrypoints to this helper (no duplicated skill body text).
- Extend discovery to any additional repo-level orchestrators if found during wiring phase.

## Post-Review Fixes (2026-02-23)
- 2026-02-23 11:31:09 Applied Sourcery review fixes in commit `0bd93b4`:
  - DRY shared contribution-preflight constants/helpers in `Fear-of-Falling/agents/contribution_preflight.py`.
  - Kept `run_single.py` security-test instructions minimal by explicitly disabling contribution preflight injection for that scenario.
  - Fixed skill heading typo to `Verification (Prerequisites)` in `.codex/skills/make-repo-contribution/SKILL.md`.
