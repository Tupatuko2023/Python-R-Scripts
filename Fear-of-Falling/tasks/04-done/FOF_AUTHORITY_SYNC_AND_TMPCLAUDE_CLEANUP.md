# FOF authority sync and tmpclaude cleanup

## Scope

Reconcile active navigation and QC documentation with
`docs/ANALYSIS_PLAN.md` v1.2 (`Active`, 2026-08-24), preserve historical and
implementation-only references, and remove explicitly approved obsolete
`tmpclaude*` files from the Fear-of-Falling root.

## Definition of Done

- Active README, QC and agent/runbook descriptions route current scientific
  truth to the Analysis Plan and use its outcome roles.
- Historical, legacy, implementation and provenance references remain intact.
- Exact `tmpclaude*` inventory is checked before and after deletion.
- Documentation links, preflight and repository smoke gates pass.
- K18/QC is recorded as not applicable for this documentation-only change.

## Log

- 2026-08-29T15:15:00+03:00 — Created from orchestrator packet
  `fcot2-fof-authority-sync-and-tmpclaude-cleanup-20260829` in `01-ready`.
- 2026-08-29T15:16:00+03:00 — Selected and transitioned to `02-in-progress`;
  verified Analysis Plan v1.2, status Active, dated 2026-08-24.
- 2026-08-29T15:18:00+03:00 — Classified targeted repository hits and recorded
  the pre-deletion inventory of 65 ordinary root-level ASCII files whose
  basenames begin with `tmpclaude`; no directories, symlinks, raw-data files,
  canonical authorities, active dependencies, or repository references found.


## Exact pre-deletion inventory

`tmpclaude-0004-cwd`, `tmpclaude-012c-cwd`, `tmpclaude-0edb-cwd`, `tmpclaude-1018-cwd`, `tmpclaude-1221-cwd`, `tmpclaude-1266-cwd`, `tmpclaude-149f-cwd`, `tmpclaude-1f4d-cwd`, `tmpclaude-21c6-cwd`, `tmpclaude-240d-cwd`, `tmpclaude-2730-cwd`, `tmpclaude-2b01-cwd`, `tmpclaude-303e-cwd`, `tmpclaude-3113-cwd`, `tmpclaude-3482-cwd`, `tmpclaude-3ea4-cwd`, `tmpclaude-4eba-cwd`, `tmpclaude-507e-cwd`, `tmpclaude-55a9-cwd`, `tmpclaude-58ef-cwd`, `tmpclaude-5bd1-cwd`, `tmpclaude-5cee-cwd`, `tmpclaude-5fcb-cwd`, `tmpclaude-61f4-cwd`, `tmpclaude-62a1-cwd`, `tmpclaude-62eb-cwd`, `tmpclaude-6743-cwd`, `tmpclaude-6a9d-cwd`, `tmpclaude-6de7-cwd`, `tmpclaude-7139-cwd`, `tmpclaude-77d5-cwd`, `tmpclaude-77fa-cwd`, `tmpclaude-7b71-cwd`, `tmpclaude-8170-cwd`, `tmpclaude-8d48-cwd`, `tmpclaude-915c-cwd`, `tmpclaude-925e-cwd`, `tmpclaude-9473-cwd`, `tmpclaude-9a7d-cwd`, `tmpclaude-a647-cwd`, `tmpclaude-aa80-cwd`, `tmpclaude-ad59-cwd`, `tmpclaude-af2b-cwd`, `tmpclaude-af56-cwd`, `tmpclaude-b372-cwd`, `tmpclaude-b3fb-cwd`, `tmpclaude-bb40-cwd`, `tmpclaude-bb63-cwd`, `tmpclaude-bbd5-cwd`, `tmpclaude-c163-cwd`, `tmpclaude-c297-cwd`, `tmpclaude-c63a-cwd`, `tmpclaude-caa7-cwd`, `tmpclaude-d125-cwd`, `tmpclaude-d2c4-cwd`, `tmpclaude-d376-cwd`, `tmpclaude-d3e6-cwd`, `tmpclaude-d6a0-cwd`, `tmpclaude-e08c-cwd`, `tmpclaude-e8d4-cwd`, `tmpclaude-ee72-cwd`, `tmpclaude-f090-cwd`, `tmpclaude-f1df-cwd`, `tmpclaude-f360-cwd`, `tmpclaude-fe52-cwd`.

## Classification and correction trace

| Scope | Class | Reason and minimal action |
|---|---|---|
| `docs/ANALYSIS_PLAN.md` v1.2 | `CURRENT_CORRECT` | Active scientific authority; inspected, not edited. |
| `docs/FOF_UPSTREAM_LOCOMOTOR_OUTCOME_SPEC.md` | `CURRENT_CORRECT` | Agrees with Analysis Plan; preserved. |
| `README.md` opening | `CURRENT_STALE` | Presented `Composite_Z` mixed model as current primary; replaced with authority links and labelled the retained remainder as a legacy runbook. |
| `QC_CHECKLIST.md` current-scope narrative | `CURRENT_STALE` | Presented Composite_Z-only QC as universal; added current outcome roles and scoped retained checks/examples to the selected branch or verified legacy bridge without removing gates. |
| `CLAUDE.md` project goal/default strategy | `CURRENT_STALE` | Presented Composite_Z/delta as current primary; routed roles to the active Analysis Plan and labelled retained formulas legacy implementation. |
| `SYSTEM_PROMPT_TERMUX_S-FOF.md` strategy | `CURRENT_STALE` | Hard-coded Composite_Z as deterministic primary; added Analysis Plan precedence and legacy scope. |
| `PROJECT_FILE_MAP.md`, `docs/R_RUN_ORDER.md` and Kxx descriptions | `IMPLEMENTATION_ONLY` | Script/I/O inventory, not current scientific authority; preserved. |
| completed/review task cards, reports and manifest records | `HISTORICAL` / `PROVENANCE_ONLY` | Preserve claims as evidence of their runs and decisions. |
| named Composite_Z analyses and output fields | `LEGACY_VALID` | Retained because the Analysis Plan explicitly permits a verified bridge. |
| examples and refactoring notes | `EXAMPLE` | Retained where they do not purport to override current authority. |

## Completion log

- 2026-08-29T15:28:00+03:00 — Corrected four active current-state documents using Analysis Plan v1.2; no scientific decision, QC gate, code, variable, data, output, manifest or Analysis Plan edit.
- 2026-08-29T15:30:00+03:00 — Deleted all 65 inventoried ordinary `tmpclaude*` files under the explicit approval; deletion is permanent from the working filesystem and no protected match was removed.
- 2026-08-29T15:34:00+03:00 — Validation: README authority links PASS; `fof-preflight` PASS; repository pre-push smoke gates PASS; whitespace PASS; post-deletion `tmpclaude*` count 0; Analysis Plan SHA-256 unchanged (`2a6cdafadc01060e417243c3947267cbb081f090e1557ac27c16993331da1d64`). K18/QC: NOT APPLICABLE — documentation/authority-label and obsolete temporary-file cleanup only; no data, variable, derivation, missingness, model-frame, QC-code or QC-artifact change.
- 2026-08-29T15:35:00+03:00 — DoD satisfied; transitioned `02-in-progress → 03-review` for human review.

## Final independent review — 2026-08-29

Disposition: `PASS`

- Independently re-read the live README, repository instructions, active Analysis Plan and all five active agent/navigation/QC documents.
- Confirmed Analysis Plan v1.2, dated 2026-08-24, status `Active`; SHA-256 remains `2a6cdafadc01060e417243c3947267cbb081f090e1557ac27c16993331da1d64`.
- Re-ran the repository-wide semantic/lexical search. Classification remains: Analysis Plan and upstream specification `CURRENT_CORRECT`; README/QC/CLAUDE/SYSTEM corrections `CURRENT_CORRECT`; script maps and run order `IMPLEMENTATION_ONLY`; completed tasks/reports/manifests `HISTORICAL` or `PROVENANCE_ONLY`; named Composite_Z branches/fields `LEGACY_VALID`; refactoring snippets `EXAMPLE`.
- Review found one additional `CURRENT_STALE` active instruction: `GEMINI.md` declared agent precedence while hard-coding Composite_Z wide/long primary formulas. Minimal correction added Analysis Plan scientific precedence and labelled those formulas legacy-bridge examples. No other unresolved active-current-state conflict remains.
- QC gates 0, 0.5 and 1–10 remain present; the diff changes framing only and removes no applicable QC check.
- Post-cleanup filesystem count is zero and no surviving live reference depends on a deleted `tmpclaude*` file.
- Task-scoped diff contains only README/QC/agent-instruction authority framing, the review record, and the previously approved temporary-file cleanup; no raw data, code, scientific result, model specification, output, manifest, Analysis Plan, Git policy or unrelated file was changed by this task.
- Validation: `fof-preflight` PASS; affected internal links PASS; `git diff --check` PASS; pre-push smoke gates PASS.
- K18/QC: NOT APPLICABLE — final review and documentation authority-label correction only; no data, derivation, coding, missingness, inclusion, model-frame, QC-code or QC-artifact change.
- 2026-08-29T15:52:00+03:00 — All final acceptance gates passed. Closed under orchestrator-approved review gate and transitioned `03-review → 04-done`.
