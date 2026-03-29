# K51 linkage vs K50 population discrepancy disposition

## Context

Decide whether the K51 three-key linkage evidence can explain the modeled-WIDE population discrepancy (`237` vs `228` vs `230`), and lock the repair order without changing K50/K51 analysis logic.

## Inputs

- `tasks/03-review/K51_three_key_linkage_audit.md`
- `tasks/03-review/2026-03-23_k51-table1-audit.md`
- `tasks/03-review/2026-03-23_k50-wide-source-of-truth-resolution.md`
- `R-scripts/K51/K51_three_key_linkage_audit.R`
- `R-scripts/K51/outputs/k51_three_key_linkage_audit.csv`
- `R-scripts/K51/outputs/k51_three_key_linkage_audit.txt`
- `R-scripts/K51/K51_three_key_override_map.csv`
- `R-scripts/K50/outputs/K50_wide_source_truth_audit/k50_wide_source_truth_resolution_memo.md`
- `tasks/02-in-progress/2026-03-23_k51-analytic-table1-implementation.md`
- `manifest/manifest.csv`

## Outputs

- Disposition memo under `R-scripts/K51/outputs/K51_linkage_population_disposition/`
- Manifest row for the memo
- Review-ready task log

## Definition of Done (DoD)

- [x] Memo answers explicitly whether K51 three-key linkage explains `237/228/230`.
- [x] Memo assigns the blocking issue to the correct subsystem.
- [x] Memo locks the implementation order: K50 source-of-truth first, K51 publication second.
- [x] No K50/K51 analysis code is changed in this pass.
- [x] Task is moved to `tasks/03-review/` after validation.

## Log

- 2026-03-23 16:18:00 +0200 Created a disposition-only task to decide whether the K51 three-key linkage evidence can explain the K50 WIDE population discrepancy.
- 2026-03-23 16:18:00 +0200 Confirmed from `K51_three_key_linkage_audit.md`, `k51_three_key_linkage_audit.txt`, and `k51_three_key_linkage_audit.csv` that the linkage audit scope is only three local unresolved canonical ids (`18`, `100`, `102`) and that all three were evaluated solely for a narrow Table 1 override decision.
- 2026-03-23 16:18:00 +0200 Confirmed from the K50 source-of-truth audit that the modeled-WIDE blocker is provenance-level: historical receipt `237`, current `paper_01=228`, and current `paper_02=230`.
- 2026-03-23 16:18:00 +0200 Wrote disposition memo `R-scripts/K51/outputs/K51_linkage_population_disposition/k51_linkage_vs_k50_population_disposition_memo.md`, appended a manifest row, and left K51 manuscript-facing analytic Table 1 blocked pending a K50 authoritative WIDE snapshot fix.

## Blockers

- K51 manuscript-facing analytic Table 1 remains blocked until K50 publishes one authoritative hash-locked WIDE snapshot and modeled-cohort provenance export.

## Links
