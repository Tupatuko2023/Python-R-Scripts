# K51 analytic-population Table 1 implementation aligned to authoritative K50 WIDE modeled sample

## Context

Implement a new manuscript-facing analytic-population Table 1 anchored to the authoritative K50 WIDE modeled sample, while preserving the current K51 baseline-eligible main Table 1 unchanged.

## Inputs

- `R-scripts/K51/K51.V1_baseline-table-k50-canonical.R`
- `R-scripts/K51/K51.V2_manuscript-facing-analytic-table1-wide.R`
- `R-scripts/K51/outputs/K51_table1_audit/k51_table1_audit_memo.md`
- `R-scripts/K50/outputs/k50_wide_locomotor_capacity_input_receipt.txt`
- `R-scripts/K50/outputs/k50_wide_locomotor_capacity_modeled_cohort_provenance.txt`
- `manifest/manifest.csv`

## Outputs

- New analytic-population Table 1 artifact for the authoritative K50 WIDE modeled sample
- Session/diagnostic artifact
- Implementation review log

## Definition of Done (DoD)

- [x] Baseline-eligible main Table 1 remains unchanged in purpose and naming.
- [x] New analytic-population Table 1 is anchored to authoritative K50 WIDE modeled sample.
- [x] Cohort n matches authoritative K50 WIDE modeled n.
- [x] Manifest rows and session artifact are written for new artifacts.
- [x] Task is moved to `tasks/03-review/` after validation.

## Log

- 2026-03-23 13:05:00 +0200 Created implementation task for a manuscript-facing analytic-population Table 1 tied to the K50 WIDE modeled sample.
- 2026-03-23 13:18:00 +0200 Tested the existing K51 script with `--shape WIDE --cohort-scope analytic --table-profile analytic_k14_extended` against the then-current K50 WIDE receipt input path. This reproduced `analytic_n=230`, confirming that the current analytic scope did not yet represent a manuscript-facing WIDE modeled sample contract.
- 2026-03-23 13:18:00 +0200 Implemented a narrow experimental `analytic_wide_modeled` scope in `K51.V1_baseline-table-k50-canonical.R` plus a companion wrapper `K51.V2_manuscript-facing-analytic-table1-wide.R` to target the K50 WIDE receipt input directly.
- 2026-03-23 13:18:00 +0200 Initial implementation remained blocked because the pre-fix K50 WIDE source of truth was inconsistent (`237` historical receipt vs `228` reproducible paper_01 derivation).
- 2026-03-23 14:30:00 +0200 Upstream blocker resolved by the authoritative K50 WIDE source-of-truth fix: the current authoritative snapshot is `paper_02_2026-03-21`, `rows_modeled=230`, and modeled split `69/161`, with matching input hash in the K50 receipt and modeled-cohort provenance artifacts.
- 2026-03-23 14:30:00 +0200 Updated the K51 manuscript-facing wrapper so it accepts only the authoritative K50 WIDE receipt/provenance pair (`authoritative_lock`, snapshot `paper_02_2026-03-21`, `n=230`, split `69/161`) and no longer treats historical `237` or paper_01 `228` states as publishable authorities.
- 2026-03-23 14:46:00 +0200 Ran `R-scripts/K51/K51.V2_manuscript-facing-analytic-table1-wide.R` in Debian/proot with Debian-first PATH. The delegated K51 receipt now resolves to the authoritative paper_02 WIDE input path, `analytic_wide_modeled_n=230`, and baseline-eligible counts remain `472/230/242` for baseline-eligible / analytic / not-analytic bookkeeping.
- 2026-03-23 14:46:00 +0200 Validated rendered manuscript-facing analytic Table 1 headers against authoritative K50 provenance: `Without FOF (n=69)` and `With FOF (n=161)` match the authoritative K50 modeled split exactly, and the implementation review log records the table-to-text crosscheck plus missingness contract.
- 2026-03-23 14:47:00 +0200 Manifest rows were appended for the regenerated analytic-population CSV, HTML, decision log, receipt, sessionInfo, and implementation review log. `fof-preflight` returned only the pre-existing K51 V1 warning about missing manifest hints, with no new blocker for this manuscript-facing wrapper path.
- 2026-03-23 14:47:00 +0200 Validation complete. Task moved to `tasks/03-review/` with baseline-eligible main Table 1 preserved and the manuscript-facing analytic Table 1 anchored exclusively to the authoritative K50 WIDE current cohort (`n=230`, split `69/161`).

## Blockers

- None after the authoritative K50 WIDE source-of-truth fix. Historical `237` and paper_01 `228` states are no longer upstream authorities for this manuscript-facing table.

## Links

- Upstream K50 authority review: `tasks/03-review/2026-03-23_k50-authoritative-wide-snapshot-fix.md`
- K51 descriptive-table audit: `tasks/03-review/2026-03-23_k51-table1-audit.md`
