# K40 FI KAAOS FI_v5 Sentinels and Continuous

## Context

FI_v4 (augmentation + var_labels) jäi 20 defisiittiin. Seuraava pullonkaula on
sentinel-koodit (E/E1) sekä continuous-cutoffien puute.

## Blockers

- Sentinel-koodit (`E`, `E1`) voivat estää tyyppiinferenssiä (categorical instead of numeric/ordinal).
- `continuous_thresholds_defined` oli käytännössä rajallinen eikä coverage kasvanut FI_v4:ssä.

## Scope

- Muokataan vain `Quantify-FOF-Utilization-Costs/R/40_FI/K40_FI_KAAOS.R`.
- Potilastaso pysyy DATA_ROOTissa.
- Repoon vain koodi + task-dokumentaatio.

## Done Criteria

- Ennen tyyppiinferenssiä recode: `E`/`E1` -> `NA` (deterministic).
- Continuous-cutoffit lisätty FI_v5 minimissä (BMI + TK VAS).
- Uusi aggregated artefakti: `k40_kaaos_numeric_candidates.csv`.
- Ajo onnistuu, decision/receipt pysyy run_id-yhtenäisenä.
- Raportoidaan `n_selected_deficits`, `continuous_thresholds_defined` ja ceiling-metriikat.

## Log

- 2026-03-05 21:01:07 +0200 task created for FI_v5 sentinel recode + continuous cutoffs.
- 2026-03-05 21:02:23 +0200 run completed (run_id=20260305_210223, R_EXIT_CODE=0): selected_deficits=22, continuous_thresholds_defined=2, augmentation_used=TRUE.
