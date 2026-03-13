# Functional Tests Derived Dataset (FOF)

## Tavoite
Tuottaa tutkimuskelpoinen johdettu datasetti toimivatestimittareista käyttäen vain `DATA_ROOT`-lähdedataa.

## Lähde
- Ensisijainen syöte: `${DATA_ROOT}/KaatumisenPelko.csv` (tai `${DATA_ROOT}/Kaatumisenpelko.csv`).
- Vain DATA_ROOT-luku; ei repoon kirjoitettavaa potilastason dataa.

## Output
- `${DATA_ROOT}/derived/fof_functional_tests_from_csv.csv`
- `${DATA_ROOT}/derived/fof_functional_tests_from_csv_metadata.json`
- `${DATA_ROOT}/derived/fof_functional_tests_from_excel.csv`
- `${DATA_ROOT}/derived/fof_functional_tests_from_excel_metadata.json`
- `${DATA_ROOT}/derived/fof_functional_tests_compare.json`
- `${DATA_ROOT}/derived/fof_functional_tests_compare.md`

Metadatassa käytetään kenttiä:
- `dataset_version` (esim. `v1`)
- `source_type` (`csv_standardized` tai `excel_raw_harmonized`)

## Muuttujat
| Muuttuja | Tyyppi | Määritelmä |
|---|---|---|
| `id` | tunniste | `id` (fallback `NRO`/`Jnro`) |
| `grip_r0`, `grip_l0`, `grip_r2`, `grip_l2` | raaka | Puristusvoima oikea/vasen |
| `grip_r*_class`, `grip_l*_class` | luokka | Excel-haarassa validi kuntoluokka vain arvoille 1–5 |
| `grip_r*_value_type`, `grip_l*_value_type` | QC | `class` / `kg_candidate` / `invalid_or_zero` / `missing` |
| `Puristus_mean0`, `Puristus_mean2` | johdannainen | `mean(left, right)` |
| `Puristus_best0`, `Puristus_best2` | johdannainen | `max(left, right)` |
| `Grip_asymmetry0`, `Grip_asymmetry2` | johdannainen | `abs(right - left)` |
| `FTSST0`, `FTSST2` | raaka | `tuoliltanousu0/2` (sekuntia) |
| `sls_r0`, `sls_l0`, `sls_r2`, `sls_l2` | raaka | Yhden jalan seisonta oikea/vasen |
| `SLS_mean0`, `SLS_mean2` | johdannainen | `mean(left, right)` |
| `SLS_best0`, `SLS_best2` | johdannainen | `max(left, right)` |
| `kavelynopeus_m_sek0`, `kavelynopeus_m_sek2` | raaka/johdettu | Ensisijaisesti valmiit m/s-sarakkeet; fallback `10 / kavelynopeus(sec)` |

## Operointisäännöt
- Puristusvoimassa säilytetään sekä `mean` että `best` (kätisyys ei tiedossa).
- SLS: päämuuttuja `SLS_mean`, lisäksi `SLS_best` sensitiivisyysanalyyseille.
- FTSST: käytetään aina raakaa `tuoliltanousu0/2`.
- `Tuoli0/2`-sarakkeita ei käytetä FTSST-raakamuuttujina (johdannaismuuttuja).
- Excel-puristuksessa mixed-field-sääntö:
  - arvot `1..5` tulkitaan luokaksi (`*_class`)
  - arvot `>5` tulkitaan kg-ehdokkaiksi (`grip_*`)
  - arvot `<=0` merkitään `invalid_or_zero` ja jätetään pois kg-johdannaisista

## Suositus analyysiin
- Pääanalyysi:
  - Puristus: Excel `grip_*_class` (ordinaalinen 1–5)
  - `SLS_mean*`
  - `FTSST*`
  - `kavelynopeus_m_sek*`
- Sensitiivisyysanalyysi:
  - CSV `Puristus_mean*`
  - CSV `Puristus_best*`
  - `SLS_best*`

## Puristus Policy (Lukittu)
- `grip_class_primary_analysis = true`
- `grip_class_modeling_scale = ordinal_5_level`
- `grip_kg_candidate_use = internal_review_only`
- `grip_pooling_across_sources = prohibited`
- Käytännössä:
  - Excel: `*_class` pääanalyysiin (ordinaalinen 1–5)
  - CSV: kg-mittarit sensitiivisyysanalyyseihin
  - Ei yhdistetä Excel-luokkaa ja CSV-kg:tä samaksi puristusmuuttujaksi

## Pipeline-järjestys
1. Rakenna CSV-haara (`scripts/80_build_functional_tests_derived.py --write`)
2. Rakenna Excel-haara (`scripts/81_build_functional_tests_from_excel.py --write`)
3. Aja vertailu (`scripts/82_compare_functional_tests_sources.py --write`)

## QC-flagit (compare)
Vertailu tuottaa automaattisesti mittarikohtaiset flagit:
- `corr_below_threshold`
- `mean_abs_diff_large`
- `overlap_low`
- `missing_in_one_source`

Lisäksi joka mittarille annetaan status:
- `GREEN`: ei lippuja
- `YELLOW`: mahdollinen operationalisointiero
- `RED`: vaatii käsitarkistuksen
