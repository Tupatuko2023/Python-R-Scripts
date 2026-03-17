# K40 FI KAAOS QC Exclusions and RunID

## Context

K40 KAAOS -pipeline tarvitsee uuden metodologisen QC-kierroksen, jossa varmistetaan
non-performance-mandaatti ja estetään eri ajojen artefaktien sekoittuminen.

## Blockers

- Valituissa defisiiteissä on ollut K40-mandaatin ulkopuolisia muuttujia (performance/FOF/lifestyle/non-health tausta).
- Output-artefakteja on voinut jäädä samalle polulle eri ajoista (esim. 29 vs 32), mikä heikentää toistettavuutta.

## Scope

- Muokataan vain `Quantify-FOF-Utilization-Costs/R/40_FI/K40_FI_KAAOS.R`.
- Potilastaso pysyy vain `DATA_ROOT`-polussa.
- Repoon vain aggregaatit/metat (ei patient-level dataa).

## Done Criteria

- Outputit kirjoitetaan `run_id`-eroteltuun kansioon `R/40_FI/outputs/<run_id>/`.
- Receipt + decision log sisältävät `run_id`.
- Label-aware hard exclusions käytössä:
  - performance-testit
  - FOF/leakage
  - lifestyle-exposures
  - non-health/background
  - optional falls-history (`exclude_falls_by_label`, default TRUE)
- `excluded_vars.csv` sisältää selkeät reason-arvot.
- Ajo onnistuu (`R_EXIT_CODE=0`) ja raportoitavat aggregaatit tulevat samasta `run_id`-kansiosta.

## Log

- 2026-03-05 20:02:24 +0200 task created for exclusions+run_id remediation.
- 2026-03-05 20:02:24 +0200 next: patch K40 script, rerun with DATA_ROOT+ID_COL, report same-run artifacts.
- 2026-03-05 20:04:51 +0200 run completed with run_id=20260305_200451 (R_EXIT_CODE=0): n_selected_deficits=20, rows_exported=552, ceiling p_over_0_70=0.0277, excluded_vars confirms performance/FOF/lifestyle/non-health/falls exclusions.
