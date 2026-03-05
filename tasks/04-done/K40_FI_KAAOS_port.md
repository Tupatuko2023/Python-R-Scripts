# K40 FI KAAOS Port

## Context
Portataan K40 Frailty Index -rakennus Quantify-FOF-Utilization-Costs -aliprojektiin siten, että datalähteenä on vain RAW Excel `${DATA_ROOT}/paper_02/KAAOS_data.xlsx`.

## Inputs
- RAW XLSX: `${DATA_ROOT}/paper_02/KAAOS_data.xlsx`
- Referenssilogiikka: deterministic K40 FI flow (inventory -> screening -> redundancy -> FI/FI_z -> red flags -> patient export)

## Outputs
- Script: `Quantify-FOF-Utilization-Costs/R/40_FI/K40_FI_KAAOS.R`
- Aggregate artifacts (outputs/manifest)
- Patient-level export only under DATA_ROOT

## Definition of Done (DoD)
- Script builds FI from RAW Excel deterministically.
- Script resolves helpers in monorepo layout (local subproject first, Fear-of-Falling fallback).
- Script fails fast with clear message if `DATA_ROOT` is missing.
- Aggregates stay repo-local; patient-level outputs go only to DATA_ROOT.

## Tehdyt muutokset
- Lisätty/korjattu `K40_FI_KAAOS.R`:
  - subproject root-ankkurointi
  - helper fallback
  - `helpers_origin` decision logiin
  - `DATA_ROOT` fail-fast

## Seuraavat stepit
1. Aja skripti DATA_ROOT asetettuna.
2. Varmista outputs/manifest + DATA_ROOT-exportit.
3. Tarkista red_flags/decision_log.
4. Tarkista `git diff`.

## Branch Isolation Rule
- `tasks/02-in-progress` ja `tasks/03-review` sisältöä ei mergata `main`-haaraan ennen siirtoa `tasks/04-done`.

## Remote Sync Rule
- Taskia EI saa siirtää `tasks/04-done/` ennen kuin muutokset on pushattu remoteen:
1. finalize local
2. `git pull origin main --rebase`
3. `git push origin [branch_name]`
4. verify remote
5. vasta sitten siirrä task `tasks/04-done/`

## Log
- 2026-03-05 17:51:09 +0200 task created in `tasks/02-in-progress`
- 2026-03-05 18:06:25 +0200 blocker: ID-saraketta ei tunnisteta KAAOS xlsx:stä (colnames -> ...1/...2), script fails at id resolution; next: inspect sheet names + columns; implement deterministic id inference fallback; rerun

## Blockers
- DATA_ROOT puuttuu tässä sessiossa; ajotesti odottaa ympäristömuuttujaa.
- ID-saraketta ei tunnisteta KAAOS xlsx:stä (colnames -> ...1/...2), script fails at id resolution.

## Links
- `WORKFLOW.md`
- `Quantify-FOF-Utilization-Costs/R/40_FI/K40_FI_KAAOS.R`
