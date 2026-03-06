# K40 FI22 Methods and QC Appendix

## Methods (Locked Variant)
Frailty was operationalized as a deficit accumulation index from the single-sheet KAAOS baseline block (`paper_02/KAAOS_data.xlsx`).
The locked construct is `FI22_nonperformance_KAAOS` and is used as a `sensitivity_index`.

Deterministic preprocessing and scoring steps:
- label-row detection and removal before candidate screening
- sentinel/missing code handling (`E`, `E1`, and map-defined `missing_codes`) recoded to `NA`
- map-controlled domain/type/direction/cutoff overrides via `R/40_FI/deficit_map.csv`
- deterministic hard exclusions for performance tests, FOF/leakage, lifestyle exposures, and non-health background variables
- map drop-audit to explain keep=1 inclusion/exclusion outcomes

Eligibility gates:
- missingness threshold: primary `pmiss <= 0.20`, sensitivity branch `pmiss <= 0.30` when primary selected deficits are insufficient
- minimum observed deficits per participant: `N_deficits_min = 10`
- minimum coverage per participant: `coverage_min = 0.60`

## QC Appendix (Source-of-Truth Run)
Run ID: `20260306_065213`

Variant and governance:
- `fi_variant=FI22_nonperformance_KAAOS`
- `fi_variant_role=sensitivity_index`
- patient-level exports written only under `DATA_ROOT/paper_02/frailty_vulnerability/`

Key run metrics:
- `n_selected_deficits=22`
- `n_selected_deficits_after_map=22`
- `deficit_map_loaded=TRUE`
- `deficit_map_rows=22`
- `map_missing_codes_applied_n=946`
- `mapped_type_overrides_n=1`
- `mapped_exclusions_n=0`
- `pmiss_thr_used=0.30`
- `used_sensitivity=TRUE`

Distribution / ceiling checks:
- `P95 = 0.5556`
- `P99 = 0.6140`
- `p_over_0.70 = 0`
- `p_over_0.66 = 0.001992`

QC red flags:
- `selected_deficits_lt_10 = 0`
- `selected_deficits_lt_30 = 1`
- `fi_all_na = 0`

Interpretation:
- This run is reproducible and methodologically stable for a non-performance sensitivity FI.
- Under current single-sheet KAAOS input constraints, the pool is exhausted for full-length (~30+) non-performance FI without new baseline variables.

## Process Notes
- Process note (audit): an earlier agent message incorrectly stated that `prompts/Frailty_Index_Research_Assistant_9.txt` was missing.
- Impact assessment: implementation remained aligned with correct methodological direction; no detected analytical deviation in locked FI22 outputs.

## Reproducibility Environment Recommendation
Normalize timezone for future runs to keep session metadata deterministic:
- recommended export: `TZ=Europe/Helsinki`
- accepted alternative: `TZ=UTC`
