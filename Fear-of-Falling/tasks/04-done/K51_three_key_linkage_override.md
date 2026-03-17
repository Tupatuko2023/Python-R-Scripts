# K51 three-key linkage override

## Goal

Implement a minimal local override for the three audit-approved Table 1
enrichment cases so that K14-extended K51 tables can render without changing
global dedup logic.

Approved mappings:

- `18 -> 314`
- `100 -> 285`
- `102 -> 288`

## Scope

- add a static override map only for the three audited cases
- apply the override only inside K51 Table 1 enrichment
- do not modify `person_dedup_lookup.R`
- do not modify K50 gating or shared compare logic
- rerun only K14-extended K51 outputs after the patch

## Definition of Done

- override map exists in repo
- K51 enrichment uses the map only when person-key/id join fails
- `baseline_eligible_k14_extended` rerun succeeds
- `analytic_k14_extended` rerun succeeds
- decision logs no longer show the previous three-key fail-closed block

## Log

- 2026-03-16T00:00:00+02:00 Task created from orchestrator prompt
  `prompts/23_4cafofv2.txt`.
- 2026-03-16T00:00:00+02:00 Added static override map
  [K51_three_key_override_map.csv](/data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling/R-scripts/K51/K51_three_key_override_map.csv)
  for the three audit-approved cases `18 -> 314`, `100 -> 285`, `102 -> 288`.
- 2026-03-16T00:00:00+02:00 Patched
  [K51.V1_baseline-table-k50-canonical.R](/data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling/R-scripts/K51/K51.V1_baseline-table-k50-canonical.R)
  to apply the override only inside the K14-extended Table 1 enrichment path.
  The final implementation does not change shared dedup logic; it reads the
  three workbook rows directly from `KAAOS_data_sotullinen.xlsx` and uses them
  as a last local fallback by canonical `id`.
- 2026-03-16T00:00:00+02:00 Reran extended outputs on canonical LONG input
  `/data/data/com.termux/files/home/FOF_LOCAL_DATA/paper_01/analysis/fof_analysis_k50_long.rds`
  for both `baseline_eligible + k14_extended` and
  `analytic + analytic_k14_extended`.
- 2026-03-16T00:00:00+02:00 Acceptance state reached:
  `raw_enrichment_status=full_coverage` in both
  [k51_long_decision_log_baseline_eligible_k14_extended.txt](/data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling/R-scripts/K51/outputs/k51_long_decision_log_baseline_eligible_k14_extended.txt)
  and
  [k51_long_decision_log_analytic_k14_extended.txt](/data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling/R-scripts/K51/outputs/k51_long_decision_log_analytic_k14_extended.txt).
  `drop_pending_verification_rows` and
  `k14_reference_rows_missing_in_current_output` are now empty.
- 2026-03-16T00:00:00+02:00 Full K14-style tables now render:
  [k51_long_baseline_table_baseline_eligible_k14_extended.csv](/data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling/R-scripts/K51/outputs/k51_long_baseline_table_baseline_eligible_k14_extended.csv)
  and
  [k51_long_baseline_table_analytic_k14_extended.csv](/data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling/R-scripts/K51/outputs/k51_long_baseline_table_analytic_k14_extended.csv)
  each contain `33` rows. Cohort counts stay unchanged:
  `baseline_eligible_n=472`, `analytic_n=230`, `not_analytic_n=242`.
- 2026-03-16T00:00:00+02:00 Validation:
  `python ../.codex/skills/fof-preflight/scripts/preflight.py`
  returned `Preflight status: PASS`.
- 2026-03-16T00:00:00+02:00 Review acceptance:
  accept this K51 three-key override implementation. The audit-approved local
  override resolved the last source/linkage blocker, extended K14-style tables
  now render with full coverage for both `baseline_eligible` and `analytic`
  scopes, and no global dedup, compare, or K50 gating logic was changed.
