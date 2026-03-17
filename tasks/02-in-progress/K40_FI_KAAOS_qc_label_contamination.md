# K40 FI KAAOS QC Label Contamination

## Context

K40 KAAOS -ajossa on viitteitä siitä, että XLSX:n ensimmäinen rivi sisältää koodikirja-/seliteriviä (esim. `NRO`, `0=...`), joka voi vuotaa datariveihin ja vääristää tyypitystä, scoringia sekä domain-priorisointia.

## Blocker

- KAAOS sheetissä ensimmäinen rivi näyttää sisältävän label/seliteriviä, mikä sekoittaa candidate inventoryä ja domain-cap -käyttäytymistä.

## Scope

- Muokataan vain `Quantify-FOF-Utilization-Costs/R/40_FI/K40_FI_KAAOS.R`.
- Potilastaso pysyy vain `DATA_ROOT`-polussa.
- Repoon vain aggregaatit + metat.

## Done Criteria

- Label-rivi tunnistetaan deterministisesti ja poistetaan datariveistä.
- Labelit talletetaan `var_labels`-mappiin ja domain/priority hyödyntää labelia jos saatavilla.
- Konservatiivinen optional scrub poistaa harvinaiset label-kontaminaatiot.
- Exclusion huomioi demografiat labelin perusteella (`age/ikä`, `sex/gender/sukupuoli`).
- Decision log sisältää: `label_row_detected`, `label_row_removed`, `n_labels_captured`, `scrub_enabled`, `scrub_values_replaced`.
- FI-jakauma + ceiling-check tuotetaan edelleen; governance säilyy ennallaan.

## Log

- 2026-03-05 19:38:19 +0200 task created for KAAOS label-row contamination remediation and domain-label mapping.
