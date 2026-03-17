# K51 Table 1 enrichment to match K14 scope

## Goal

Keep the deduplicated K50 analytic cohort unchanged for paper_01 Table 1, but
restore the essential K14 baseline rows through a controlled enrichment layer.

## Scope

- keep `analytic_n = 230` as the main Table 1 cohort
- keep shared `R/functions/person_dedup_lookup.R` and current K50 inclusion
  chain unchanged
- add `--table-profile minimal|k14_extended` to K51
- use canonical-direct rows when available
- use raw-backed enrichment only for K14 rows missing from canonical K50 input
- write enriched analytic outputs with explicit scope/profile names

## Definition of Done

- main enriched Table 1 still uses the deduplicated analytic cohort
- K14 row inventory is mapped as `canonical_direct`, `raw_backed`, or
  `drop_pending_verification`
- enriched analytic outputs are written under `R-scripts/K51/outputs/`
- manifest rows exist for the new enriched artifacts
- decision log documents restored rows and any intentionally omitted rows

## Log

- 2026-03-16T00:00:00+02:00 Task created from orchestrator prompt `prompts/8_4cafofv2.txt`.
- 2026-03-16T00:00:00+02:00 Task moved to `tasks/02-in-progress/` for a controlled K51.2 enrichment pass that keeps the deduplicated analytic cohort fixed and expands only Table 1 row handling.
- 2026-03-16T00:00:00+02:00 Inventoried K14 Table 1 rows directly from `R-scripts/K14/K14.R` and classified them into `canonical_direct` vs `raw_backed` candidates for K51 profile handling.
- 2026-03-16T00:00:00+02:00 Added `--table-profile minimal|k14_extended` to `R-scripts/K51/K51.V1_baseline-table-k50-canonical.R`, keeping the existing K51.1 cohort-scope logic and shared `person_dedup_lookup.R` / K50 inclusion chain unchanged.
- 2026-03-16T00:00:00+02:00 Added immutable raw enrichment-path resolution for `KaatumisenPelko.csv`, but verification showed that the locally available K14-style raw source does not cover the current canonical K50 analytic population: `raw_enrichment_status=partial_coverage_missing_person_keys=335`.
- 2026-03-16T00:00:00+02:00 To avoid biased partial enrichment, the `k14_extended` profile now fails closed on raw-backed row coverage: it renders all verified canonical-direct rows for the analytic cohort and writes explicit `drop_pending_verification_rows` / K14 crosscheck lines to the decision log for omitted K14 rows.
- 2026-03-16T00:00:00+02:00 LONG smoke run succeeded for `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript R-scripts/K51/K51.V1_baseline-table-k50-canonical.R --data /data/data/com.termux/files/home/FOF_LOCAL_DATA/paper_01/analysis/fof_analysis_k50_long.rds --shape LONG --cohort-scope analytic --table-profile k14_extended`.
- 2026-03-16T00:00:00+02:00 New enriched-profile artifacts were written to `R-scripts/K51/outputs/`: `k51_long_baseline_table_analytic_k14_extended.csv/html`, `k51_long_decision_log_analytic_k14_extended.txt`, `k51_long_input_receipt_analytic_k14_extended.txt`, and `k51_long_sessioninfo_analytic_k14_extended.txt`.
- 2026-03-16T00:00:00+02:00 The enriched analytic output keeps `analytic_n=230` and adds K14-style labeling for verified canonical rows (`Women`, `Age`, `Body Mass Index`, `Balance difficulties`) while preserving current paper_01 rows `Locomotor capacity at baseline` and `Frailty Index (FI)`.
- 2026-03-16T00:00:00+02:00 Decision log now records the row-registry mapping and crosscheck state explicitly: canonical-direct rows rendered, raw-backed rows omitted due source mismatch, and K14-reference rows missing from the current output listed one by one.
- 2026-03-16T00:00:00+02:00 Review/acceptance pass confirmed that K51.2 is technically successful but not yet a complete K14-scope restoration: the analytic cohort remains correct (`n=230`, `Without FOF=69`, `With FOF=161`), the enriched-profile artifacts write correctly, and the source block is exposed honestly as `raw_enrichment_status=partial_coverage_missing_person_keys=335`.
- 2026-03-16T00:00:00+02:00 Review/acceptance pass also confirmed that the current `k14_extended` output contains only verified direct rows plus current paper_01 direct rows, while all missing K14 raw-backed rows stay explicitly listed in `drop_pending_verification_rows` and `k14_reference_rows_missing_in_current_output`.
- 2026-03-16T00:00:00+02:00 Recommendation: accept K51.2 as technically review-complete and freeze it in this state; resolve missing K14 rows only through a separate verified enrichment-source task, not by further patching current K51 logic or forcing partial enrichment from the current raw source.
