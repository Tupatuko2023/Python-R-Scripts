# Table 2 (Usage of Injury Related Health Services) — lukittu ohje

## Tavoite
Tuottaa käsikirjoituksen Table 2: “Usage of Injury Related Health Services”. Rakenne, N:t, mittayksikkö ja “Adjusted for age and sex” ovat käsikirjoituslukittuja.

## Rakenne (pakko)
Ryhmät: FOF No (N=147) ja FOF Yes (N=330)

Sarakkeet:
- FOF No: Mean (SE)*
- FOF Yes: Mean (SE)*
- IRR (95% CI)**

Rivit (järjestys):
- Poliklinikkakäynnit ICD-10 -blokeittain: S00-09, S10-19, S20-29, S30-39, S40-49, S50-59, S60-69, S70-79, S80-89, S90-99, T00-14, Total
- Treatment periods in hospital (yksi total-rivi)

Mittayksikkö:
- * Per 1000 pyrs
- ** Adjusted for age and sex

Tulkinta:
- Mean(SE) = ikä- ja sukupuolikorjatut ilmaantuvuudet / 1000 henkilövuotta
- IRR = FOF (Yes vs No), ikä + sex -korjattu

## Data ja muuttujat (ei arvauksia)
Henkilötaso (`aim2_analysis`):
- `id` (pseudonymisoitu osallistuja-ID)
- `FOF_status` (0=No; 1=Yes)
- `age` (years)
- `sex`
- `followup_days`

Rekisterit:
- Poliklinikkakäynnit: `Tutkimusaineisto_pkl_kaynnit_2010_2019.xlsx` (päädiagnoosi `Pdgo`)
- Osastojaksodiagnoosit: `Tutkimusaineisto_osastojakso_diagnoosit (1).xlsx` (päädiagnoosi `Pdgo`)

Pakollinen KB-missing:
- `aim2_analysis$id` on pseudonymisoitu, rekistereissä suora tunniste. Ilman linkitystaulua (id ↔ register_id) yhdistäminen ei ole sallittua. Prosessin tulee fail-closed.

Diagnoosivalinta:
- Oletus = vain `Pdgo` (päädiagnoosi). Sivudiagnoosit vaativat erillisen päätöksen.

## Governance (Option B)
- Kaikki rekisteridata luetaan vain `DATA_ROOT`-polun kautta.
- Ei yksilötason dataa repoihin.
- Ei absoluuttisia polkuja stdout/lokeihin.
- Aggregaatit ovat double-gated: `ALLOW_AGGREGATES=1` ja `INTEND_AGGREGATES=true`.

## Skripti (single file)
Skripti: `Quantify-FOF-Utilization-Costs/R/15_table2/15_table2_usage_injury_services.R`

Pakolliset env-varit (polut):
- `PATH_AIM2_ANALYSIS`
- `PATH_PKL_VISITS_XLSX`
- `PATH_WARD_DIAGNOSIS_XLSX`
- `PATH_LINK_TABLE` (valinnainen, mutta vaaditaan jos ID:t eivät täsmää)

Lisäksi (sarakenimet, ei arvauksia):
- `PKL_ID_COL` (rekisteri-ID:n sarake poliklinikkadatas­ta)
- `WARD_ID_COL` (rekisteri-ID:n sarake osastojaksodatas­ta)
- `LINK_ID_COL` (oletus `id`)
- `LINK_REGISTER_COL` (oletus `register_id`)
- `WARD_EPISODE_ID_COL` (valinnainen; jos puuttuu, käytetään `OsastojaksoAlkuPvm` + `OsastojaksoLoppuPvm`)

Tuotos:
- `Quantify-FOF-Utilization-Costs/R/15_table2/outputs/table2_generated.csv` (gitignored)

## Ajo
- Vain luvan kanssa: `ALLOW_AGGREGATES=1 INTEND_AGGREGATES=true Rscript R/15_table2/15_table2_usage_injury_services.R`

## Huomio
- Skripti ei saa tulostaa henkilö-ID:itä eikä rivi- tai yksilölistoja.
- Jos linkitystaulu puuttuu ja ID:t eivät täsmää, skripti pysähtyy.
