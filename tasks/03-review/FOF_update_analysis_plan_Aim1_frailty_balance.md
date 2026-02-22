# TASK: FOF Analysis Plan Aim 1 Update (FOF + Frailty + Balance)

## Context

Fear-of-Falling `docs/ANALYSIS_PLAN.md` was FOF-only in Objective/Primary Comparison and models. Requested update is to align Aim 1 framing to FOF + frailty + balance with explicit operationalization of independent vs relative effects.

## Inputs

- User task packet objective and acceptance criteria.
- `Fear-of-Falling/docs/ANALYSIS_PLAN.md`
- Repo variable evidence from K15/K18/K19 and K08/K14 scripts.

## Outputs

- Updated `Fear-of-Falling/docs/ANALYSIS_PLAN.md`
- New `Fear-of-Falling/docs/CHANGELOG_NOTE.md`

## Definition of Done (DoD)

- [x] Objective + Primary Comparison reflect FOF + frailty + balance at 12 months.
- [x] Data & Variables include `frailty_cat_3` and `frailty_score_3` and balance variable handling without invented aliases.
- [x] LMM + ANCOVA sections explicitly include independent/relative effects operationalization.
- [x] QC section extended minimally (frailty/balance checks).
- [x] CHANGELOG note added with updates + TODO items.

## Log

- 2026-02-21 18:54:15 Created task from `tasks/_template.md` and moved `01-ready -> 02-in-progress`.
- 2026-02-21 18:54:15 Verified target analysis plan path: `Fear-of-Falling/docs/ANALYSIS_PLAN.md`.
- 2026-02-21 18:54:15 Searched for `Tutkimussuunnitelma.qmd` / variants in-repo; file not found.
- 2026-02-21 18:54:15 Verified canonical variable usage from repo context:
  - frailty: `frailty_cat_3`, `frailty_score_3`
  - balance: `tasapainovaikeus`; objective candidates `Seisominen0/Seisominen2` and `SLS0/SLS2`
- 2026-02-21 18:54:15 Updated `docs/ANALYSIS_PLAN.md` Objective, Variables, Models, and QC gates.
- 2026-02-21 18:54:15 Added `docs/CHANGELOG_NOTE.md` including TODO for objective balance canonical naming.

## Blockers

- `Tutkimussuunnitelma.qmd` was not found in repository paths searched; update applied from explicit task packet Aim text and repository variable conventions.

## Links

- `Fear-of-Falling/docs/ANALYSIS_PLAN.md`
- `Fear-of-Falling/docs/CHANGELOG_NOTE.md`
