# K50 WIDE source-of-truth resolution for 237 vs 228 modeled cohort

## Context

Resolve whether the authoritative K50 WIDE modeled population is the historical receipt value `rows_modeled=237` or the currently reproducible canonical value `rows_modeled=228`, using K50 provenance rather than K51 wrapper logic or manuscript expectations.

## Inputs

- `R-scripts/K50/K50.r`
- `R/functions/person_dedup_lookup.R`
- `R-scripts/K50/outputs/k50_wide_locomotor_capacity_input_receipt.txt`
- Canonical K50 WIDE input `.rds` referenced by the receipt
- `R-scripts/K51/K51.V1_baseline-table-k50-canonical.R`
- `R-scripts/K51/K51.V2_manuscript-facing-analytic-table1-wide.R`
- `tasks/02-in-progress/2026-03-23_k51-analytic-table1-implementation.md`
- `manifest/manifest.csv`

## Outputs

- Discrepancy memo under `R-scripts/K50/outputs/K50_wide_source_truth_audit/`
- Provenance artifacts (input hash, git-history excerpt)
- Manifest rows for created audit artifacts
- Review-ready resolution task log

## Definition of Done (DoD)

- [x] Receipt provenance is documented from canonical K50 artifacts.
- [x] Current canonical K50 WIDE modeled cohort is reproduced from the currently available snapshots that now occupy the historical receipt path and the current HEAD default path; the original locked receipt snapshot itself is no longer locally available.
- [x] The 237 vs 228 divergence is explained by an explicit root-cause category.
- [x] The memo ends with one authority decision: `237`, `228`, or unresolved/block publication.
- [x] K51 manuscript-facing Table 1 remains blocked unless authority is resolved.
- [x] Task is moved to `tasks/03-review/` after validation.

## Log

- 2026-03-23 15:38:00 +0200 Created a dedicated K50 provenance-audit task to resolve the authoritative WIDE modeled cohort (`237` vs `228`) before any K51 manuscript-facing Table 1 can be marked review-ready.

- 2026-03-23 16:09:00 +0200 Audited the historical K50 WIDE receipt against current upstream snapshots. The receipt still records `rows_modeled=237`, but its `input_md5` no longer matches the current file at the same `paper_01` path.
- 2026-03-23 16:09:00 +0200 Verified that the current `paper_01` snapshot now has `535` rows and yields `228` modeled records under the receipt-era field filters (`68/160`), while the current `paper_02` snapshot used by HEAD K50 path resolution also has `535` rows but yields `230` modeled records (`69/161`).
- 2026-03-23 16:09:00 +0200 Wrote `R-scripts/K50/outputs/K50_wide_source_truth_audit/k50_wide_source_truth_resolution_memo.md`, `input_sha256.txt`, and `k50_git_history_excerpt.txt`; appended manifest rows for all three artifacts.
- 2026-03-23 16:09:00 +0200 Resolution outcome: `unresolved`. The receipt preserves a historical `237`, but the original md5-locked input snapshot is no longer present locally, and current HEAD evidence splits between `228` (`paper_01`) and `230` (`paper_02`). K51 manuscript-facing Table 1 remains blocked pending a K50 source-of-truth fix.

## Blockers

- Publication remains blocked until K50 freezes one authoritative WIDE snapshot and modeled-cohort provenance export.

## Links
