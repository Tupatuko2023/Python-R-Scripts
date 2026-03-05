# K40 FI KAAOS FI_v4 Augmentation

## Context
K40 FI -runi on leakage-safe ja non-performance, mutta valittuja defisiittejä jäi 20.
Tarvitaan deterministinen augment-kierros, joka nostaa deficit-määrää ilman poissulkujen rikkomista.

## Blockers
- `n_selected_deficits=20` (lyhyt FI; stabiliteettiriski).
- Puuttui erillinen `var_labels`-artefakti seuraavan candidate-registry-vaiheen tueksi.

## Scope
- Muokataan vain `Quantify-FOF-Utilization-Costs/R/40_FI/K40_FI_KAAOS.R`.
- Ei muutoksia DATA_ROOT-governanceen.
- Repoon vain koodi + task-dokumentaatio.

## Done Criteria
- Kirjoitetaan `k40_kaaos_var_labels.csv` (var_name,label) run_id-kansioon.
- Auto-augment käytössä:
  - `try_sensitivity_if_selected_lt <- 30L`
  - jos primary selected < 30, rerun screening `pmiss_thr=0.30`
- Decision log sisältää: `augmentation_used`, `pmiss_thr_used`, `try_sensitivity_if_selected_lt`.
- Ajo onnistuu ja kaikki raportoitavat artefaktit tulevat samasta run_id-kansiosta.

## Log
- 2026-03-05 20:44:05 +0200 task created for FI_v4 augmentation and var-labels artifact.
- 2026-03-05 20:44:23 +0200 run completed (run_id=20260305_204423, R_EXIT_CODE=0): augmentation_used=TRUE, pmiss_thr_used=0.30, selected_deficits=20, rows_exported=552.
