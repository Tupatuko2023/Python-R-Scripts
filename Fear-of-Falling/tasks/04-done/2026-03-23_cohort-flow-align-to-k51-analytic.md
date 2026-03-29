# Align cohort flow diagram to authoritative K51 analytic population

## Context

Update the paper_01 cohort-flow diagram so that it is rendered deterministically from project placeholders, matches the authoritative K51 manuscript-facing analytic population, and no longer labels the final analytic cohort as the LONG primary branch when the manuscript-facing Table 1 is anchored to the WIDE analytic population.

## Inputs

- `diagram/paper_01_cohort_flow.dot`
- `diagram/render_paper_01_cohort_flow.sh`
- `R-scripts/K50/K50.1_COHORT_FLOW.V1_derive-cohort-flow.R`
- `R-scripts/K50/outputs/k50_wide_locomotor_capacity_input_receipt.txt`
- `R-scripts/K50/outputs/k50_wide_locomotor_capacity_modeled_cohort_provenance.txt`
- `R-scripts/K51/outputs/k51_wide_input_receipt_analytic_wide_modeled_k14_extended.txt`
- `R-scripts/K51/outputs/k51_wide_baseline_table_analytic_wide_modeled_k14_extended.csv`

## Outputs

- `diagram/paper_01_cohort_flow.wide.locomotor_capacity.resolved.dot`
- `diagram/paper_01_cohort_flow.wide.locomotor_capacity.svg`
- `diagram/paper_01_cohort_flow.wide.locomotor_capacity.png`
- `R-scripts/K50/outputs/k50_wide_locomotor_capacity_cohort_flow_placeholders.csv`
- `R-scripts/K50/outputs/k50_wide_locomotor_capacity_cohort_flow_alignment_review_log.txt`

## Definition of Done (DoD)

- [x] Placeholder pipeline is used instead of hand-editing the resolved DOT.
- [x] Resolved DOT title reads `Primary branch: WIDE | outcome: locomotor_capacity`.
- [x] Final analytic cohort equals `230`, with `FOF yes = 161` and `FOF no = 69`.
- [x] Upstream continuity chain is preserved as `1070 -> 535 -> 472 -> 240 -> 230`.
- [x] Review log documents authoritative placeholder provenance and Table 1 crosscheck.
- [x] Task is moved to `tasks/03-review/` after validation.

## Log

- 2026-03-23 15:05:00 +0200 Created cohort-flow alignment task for the authoritative K51 analytic population (`n=230`, `FOF yes=161`, `FOF no=69`).
- 2026-03-23 15:10:00 +0200 Audited the template, current LONG resolved DOT, render script, and absence of `k50_wide_locomotor_capacity_cohort_flow_placeholders.csv`. The existing WIDE render path was not yet materialized; the only resolved example still said `Primary branch: LONG` even though its final cohort already showed `230 / 161 / 69`.
- 2026-03-23 15:25:00 +0200 Updated `K50.1_COHORT_FLOW.V1_derive-cohort-flow.R` so WIDE/locomotor-capacity cohort-flow derivation resolves its input from the authoritative K50 WIDE receipt, validates the final analytic cohort against K50 receipt/provenance plus K51 analytic Table 1 receipt, and emits a WIDE-semantic graph title for paper_01.
- 2026-03-23 15:40:00 +0200 Corrected `diagram/render_paper_01_cohort_flow.sh` to use `python3` when `python` is absent, which was required for deterministic rendering in the current Debian/Termux environment.
- 2026-03-23 15:55:00 +0200 Final alignment fix: the WIDE placeholder CSV now inherits raw-row continuity and missingness from the authoritative LONG cohort-flow placeholders (`1070 -> 535 -> 472 -> 240 -> 230`) while keeping the final modeled cohort locked to the authoritative WIDE/Table-1 authority (`230`, `161`, `69`).
- 2026-03-23 15:59:00 +0200 Rendered `paper_01_cohort_flow.wide.locomotor_capacity.{resolved.dot,svg,png}` from the regenerated placeholder CSV and confirmed the resolved DOT title is `Primary branch: WIDE | outcome: locomotor_capacity`.
- 2026-03-23 16:00:00 +0200 Wrote `k50_wide_locomotor_capacity_cohort_flow_alignment_review_log.txt` documenting placeholder provenance and the crosscheck to K50 receipt/provenance and K51 Table 1 artifacts.
- 2026-03-23 16:00:00 +0200 `fof-preflight` returned only pre-existing manifest-hint warnings for K50/K51 scripts, with no new blocking issue for this cohort-flow alignment pass.

## Blockers

- None. The WIDE cohort-flow pipeline now renders deterministically from project placeholders and matches the authoritative analytic population.

## Links

- `tasks/03-review/2026-03-23_k51-analytic-table1-implementation.md`
- `tasks/03-review/2026-03-23_k50-authoritative-wide-snapshot-fix.md`
