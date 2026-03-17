# K51 verified enrichment source from sibling upstreams

## Goal

Find a verified person-level enrichment source for the K14-style baseline rows
that can be linked safely to the current deduplicated K50/K51 analytic cohort.

## Scope

- treat the sibling repo Table 1 script as mapping/reference only
- do not use aggregated `table1_patient_characteristics_by_fof.csv` as input
- inventory sibling-script upstream person-level sources and recodes
- test candidate source coverage against the current analytic cohort via the
  shared person key / current dedup chain
- accept a source only if coverage is sufficient and no parallel dedup chooser
  is introduced

## Definition of Done

- sibling-script upstream candidates are enumerated with required columns
- at least one candidate source is assessed for person-level coverage against
  the current analytic cohort
- the decision clearly states whether any source is acceptable for future K51
  enrichment reruns
- no change is made to K50 gating or K51 cohort-scope logic during source
  verification

## Notes

- The sibling script `Quantify-FOF-Utilization-Costs/R/10_table1/12_table1_patient_characteristics_by_fof_wfrailty.R`
  is useful as a row-registry and source-discovery reference, not as a direct
  enrichment source.
- Its aggregate output cannot restore participant-level K51 variables.

## Log

- 2026-03-16T00:00:00+02:00 Task created from orchestrator prompts `prompts/9_4cafofv2.txt` and `prompts/10_4cafofv2.txt`.
- 2026-03-16T15:37:57+02:00 Added shared helper `R/functions/k51_source_inventory.R` and wrapper `R-scripts/K51/K51_source_inventory.R` to inventory sibling-upstream person-level source candidates without changing K50 gating or K51 cohort-scope logic.
- 2026-03-16T15:37:57+02:00 Wrote `R-scripts/K51/outputs/k51_source_inventory.csv`, `R-scripts/K51/outputs/k51_source_verification_report.csv`, and `R-scripts/K51/outputs/k51_source_verification_decision_log.txt`; manifest rows appended under script label `K51_source_verification`.
- 2026-03-16T15:37:57+02:00 Verified current analytic cohort from canonical LONG input `/data/data/com.termux/files/home/FOF_LOCAL_DATA/paper_01/analysis/fof_analysis_k50_long.rds` with `analytic_n=230`.
- 2026-03-16T15:37:57+02:00 Coverage results: `paper_02/KAAOS_data_sotullinen.xlsx` matched `230/230` analytic ids with `duplicate_keys=14`; `derived/kaatumisenpelko.csv` matched `230/230` with `duplicate_keys=12`; `derived/aim2_panel.csv` matched `0/230`; `paper_02/sotut.xlsx` failed unique bridge-sheet verification; `data/kaatumisenpelko.csv` was missing.
- 2026-03-16T15:37:57+02:00 Decision: `acceptable_sources=NONE`. Current sibling-upstream candidates are useful for mapping/reference or partial linkage checks, but none qualifies yet as a verified enrichment source because the acceptance rule requires `coverage_ratio >= 0.9` and `duplicate_keys == 0`.
- 2026-03-16T15:38:00+02:00 Validation: `python ../.codex/skills/fof-preflight/scripts/preflight.py` returned `Preflight status: PASS`. `tools/run-gates.sh` was loaded before finalizing the task.
- 2026-03-16T15:59:35+02:00 Re-opened source verification for newly available `DATA_ROOT/KaatumisenPelko.csv` and added a duplicate-resolution pass in `R/functions/k51_source_inventory.R` using source-local baseline/visit-date/non-missing prioritisation without changing K50 gating or K51 cohort-scope logic.
- 2026-03-16T15:59:35+02:00 Wrote `R-scripts/K51/outputs/k51_source_verification_report_v2.csv` and `R-scripts/K51/outputs/k51_source_verification_decision_log_v2.txt`; manifest rows appended under script label `K51_source_verification`.
- 2026-03-16T15:59:35+02:00 `DATA_ROOT/KaatumisenPelko.csv` structure was inspected directly. Relevant columns for duplicate resolution were `NRO`, `id`, `enter`, `KAAOSVastaanottokäynti`, `pvm0kk`, and `kaatumisenpelkoOn`.
- 2026-03-16T15:59:35+02:00 Result for `root_kaatumisenpelko_csv`: `rows_total=276`, `unique_person_keys=274`, `matched_analytic_ids=68/230`, `coverage_ratio=0.2956521739`, `duplicate_keys_before=2`, `duplicate_keys_after_dedup=0`, `rows_removed_by_dedup=2`.
- 2026-03-16T15:59:35+02:00 Decision update: duplicate resolution succeeded technically for `DATA_ROOT/KaatumisenPelko.csv`, but the source remains rejected because coverage is far below the acceptance threshold (`68/230 < 0.9`). The blocker is now source coverage, not duplicate keys.
- 2026-03-16T16:05:00+02:00 Plain-language conclusion: this is not a coding failure and not a “file not found” problem. The problem is dataset coverage. `DATA_ROOT/KaatumisenPelko.csv` exists and can be deduplicated, but it only covers `68/230` people in the current K50 analytic cohort, so it cannot serve as a verified enrichment source for that cohort.
- 2026-03-16T16:05:00+02:00 Current verified baseline cohort source is the canonical K50 LONG dataset `/data/data/com.termux/files/home/FOF_LOCAL_DATA/paper_01/analysis/fof_analysis_k50_long.rds`, which the existing K51 baseline-eligible run already shows as `baseline_eligible_n=472`, `analytic_n=230`, and `not_analytic_n=242`.
- 2026-03-16T16:05:00+02:00 For the rows already implemented in K51, the needed baseline variables are already in the canonical dataset: `age`, `sex`, `BMI`, `tasapainovaikeus`, baseline `locomotor_capacity`, and `FI22_nonperformance_KAAOS`. This means the current baseline Table 1 can be built directly from the canonical baseline subset without a separate enrichment source.
- 2026-03-16T16:05:00+02:00 Working recommendation: treat baseline Table 1 and analytic selection as two different products. Use the baseline-eligible cohort (`n=472`) for the descriptive baseline table and keep the analytic-vs-not-analytic comparison (`230` vs `242`) as a separate selection table. Do not force `KaatumisenPelko.csv` into the analytic cohort pipeline.
- 2026-03-16T17:14:44+02:00 Updated `R-scripts/K51/K51.V1_baseline-table-k50-canonical.R` so the default/main Table 1 scope is now `baseline_eligible` rather than `analytic`. A default LONG run now writes the main baseline table for `baseline_eligible_n=472`, while the analytic (`n=230`) and selection (`242` not analytic) outputs remain supplementary comparison artifacts.
- 2026-03-16T17:14:44+02:00 Repointed K14-style enrichment from `KaatumisenPelko.csv` to the verified workbook source `DATA_ROOT/paper_02/KAAOS_data_sotullinen.xlsx`, reading sheet `Taul1` with `skip=1` and applying deterministic baseline dedup (`NRO`, earliest visit date, then first row).
- 2026-03-16T17:14:44+02:00 Current status after KAAOS-based baseline enrichment smoke: `raw_enrichment_status=partial_coverage_missing_person_keys=3` for the baseline-eligible cohort. The main population scope bug is fixed, but raw-backed K14 rows still fail closed because three baseline-eligible people do not yet resolve through the current linkage path.
- 2026-03-16T17:58:55+02:00 Added `R-scripts/K51/outputs/k51_missing_person_keys_baseline_eligible.csv` as a deterministic debug artifact for the final unresolved KAAOS enrichment gap. The three unresolved baseline-eligible canonical ids are `18`, `100`, and `102`, all with `FOF_status=1`.
- 2026-03-16T17:58:55+02:00 Deterministic bridge probes were run for those three ids against `KAAOS_data_sotullinen.xlsx`, `KAAOS_data.xlsx`, and `paper_02/sotut.xlsx`. None of the three was found by canonical id or SSN in those probes (`resolution_hint=not_found_in_bridge_probes` for all rows), so no safe bridge-only recovery path was identified.
- 2026-03-16T17:58:55+02:00 Decision freeze: Prompt 15's scope/source correction is accepted as technically successful and should remain frozen. The current baseline-eligible Table 1 (`n=472`) is accepted as the final safe output, while K14 raw-backed rows remain fail-closed with an explicitly documented residual gap of 3 unresolved baseline-eligible keys.
