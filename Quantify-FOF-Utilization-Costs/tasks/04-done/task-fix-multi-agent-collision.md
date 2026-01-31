---
title: "Fix Multi-Agent State Collision in Task Queues"
status: done
assignee: unassigned
created: 2026-01-27
priority: high
---

# Context

Current workflow allows `tasks/02-in-progress/` and `tasks/03-review/` files to be merged into `main`.
This causes "State Pollution": when Agent A pulls `main`, they receive Agent B's in-progress files, violating isolation.

# Objective

Refactor the workflow so that `main` branch is always clean of intermediate states.
Tasks should conceptually jump from `01-ready` -> `04-done` on `main`, while the `02` and `03` states exist only on feature branches.

# Inputs

- `WORKFLOW.md`
- Current content of `tasks/02-in-progress/` and `tasks/03-review/`

# Steps

1. **Analyze & Clean Main:**
   - Review all items currently in `tasks/02-in-progress/` and `tasks/03-review/` on `main`.
   - If they are stale/done, move to `04-done` or `archive`.
   - If they are truly backlog items, move to `00-backlog`.
   - Goal: `main` branch should have empty `02` and `03` folders (except `.keep`).

2. **Update WORKFLOW.md:**
   - Add "Branch Isolation Rule":
     > "Files in `tasks/02-in-progress` and `tasks/03-review` MUST NOT be merged to `main` unless they are moved to `04-done` as part of the same merge."
   - Alternatively: Instruct agents to strictly use Feature Branches, and clarify that `main` represents the "Production/Done" state only.

3. **Technical Enforcement (Optional/Investigation):**
   - Investigate if adding `tasks/02-in-progress/*` to `.gitignore` (while keeping `.keep`) is a viable strategy to prevent accidental pushes to main, OR if it hinders the review process.
   - Recommendation: Update `SKILLS.md` or `WORKFLOW.md` with the chosen protocol.

# Deliverables

1. Clean `tasks/02-in-progress/` and `tasks/03-review/` folders on `main`.
2. Updated `WORKFLOW.md` reflecting the isolation strategy.

# Definition of Done

- `git ls-tree -r main --name-only` shows no task files in `02` or `03` (except placeholders).
- A fresh clone of the repo does not show other agents' active work.
