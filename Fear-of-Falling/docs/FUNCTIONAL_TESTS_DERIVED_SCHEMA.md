# Functional Tests Derived Schema

Tämä dokumentti määrittelee functional-test -haaran (ja sen johdannaisten)
vakioidut muuttujanimet, tyypit ja laskentasäännöt raakadatasta (Excel/KaatumisenPelko.csv)
analyysivalmiiksi muuttujiksi.

## Muuttujakartta (Variable Map)

| Muuttuja                                     | Tyyppi         | Lähde / Laskentasääntö                                                  |
| :------------------------------------------- | :------------- | :---------------------------------------------------------------------- |
| `id`                                         | tunniste       | `id` (fallback `NRO`/`Jnro`)                                            |
| `grip_r0`, `grip_l0`, `grip_r2`, `grip_l2`   | raaka          | Puristusvoima oikea/vasen                                               |
| `grip_r*_class`, `grip_l*_class`             | luokka         | Excel-haarassa validi kuntoluokka vain arvoille 1–5                     |
| `grip_r*_value_type`, `grip_l*_value_type`   | QC             | `class` / `kg_candidate` / `invalid_or_zero` / `missing`                |
| `Puristus_mean0`, `Puristus_mean2`           | johdannainen   | `mean(left, right)`                                                     |
| `Puristus_best0`, `Puristus_best2`           | johdannainen   | `max(left, right)`                                                      |
| `Grip_asymmetry0`, `Grip_asymmetry2`         | johdannainen   | `abs(right - left)`                                                     |
| `FTSST0`, `FTSST2`                           | raaka          | `tuoliltanousu0/2` (sekuntia)                                           |
| `sls_r0`, `sls_l0`, `sls_r2`, `sls_l2`       | raaka          | Yhden jalan seisonta oikea/vasen                                        |
| `SLS_mean0`, `SLS_mean2`                     | johdannainen   | `mean(left, right)`                                                     |
| `SLS_best0`, `SLS_best2`                     | johdannainen   | `max(left, right)`                                                      |
| `kavelynopeus_m_sek0`, `kavelynopeus_m_sek2` | raaka/johdettu | Ensisijaisesti valmiit m/s-sarakkeet; fallback `10 / kavelynopeus(sec)` |

## Operointisäännöt

- Aikapistekartta on lukittu functional-test branchissa: suffix `0` = baseline ja suffix `2` = 12 kk.
- Puristusvoimassa säilytetään sekä `mean` että `best` (kätisyys ei tiedossa).
- SLS: päämuuttuja `SLS_mean`, lisäksi `SLS_best` sensitiivisyysanalyyseille.
- FTSST: käytetään aina raakaa `tuoliltanousu0/2`.
- `Tuoli0/2`-sarakkeita ei käytetä FTSST-raakamuuttujina (johdannaismuuttuja).
- Sama `0/2`-aikapistekartta toimii locomotor-CFA:n kolmelle
  lähdekomponentille (`kavelynopeus_m_sek`, `FTSST`, `SLS_mean` /
  `Seisominen`) eikä ole vain `Composite_Z`-haaran konventio.
- Excel-puristuksessa mixed-field-sääntö:
  - arvot `1..5` tulkitaan luokaksi (`*_class`)
  - arvot `>5` tulkitaan kg-ehdokkaiksi (`grip_*`)
  - arvot `<=0` merkitään `invalid_or_zero` ja jätetään pois kg-johdannaisista
