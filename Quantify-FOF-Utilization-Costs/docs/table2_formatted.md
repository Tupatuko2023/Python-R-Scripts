# Table 2 (käsikirjoitusmuoto)

Alla on Table 2 muotoiltuna käsikirjoituksen tyyliin käyttäen viimeisintä `table2_generated.csv`-ajoa (FOF No n=144, FOF Yes n=330). Kaikki luvut ovat ikä- ja sukupuolikorjattuja ja raportoidaan per 1000 henkilövuotta; IRR on FOF Yes vs No.

Table 2 version tag: `TABLE2_LOCKED_v2_collapsed_dx_days`

Huomio: “Hospital treatment days” -rivin bootstrap-SE on tässä ajossa numeerisesti epästabiili (hyvin suuri), vaikka mean/IRR ovat järkeviä. Tämä on tyypillinen bootstrapin “harvinaiset/äärinäytteet” -ilmiö; siistimpi SE vaatii uudelleenajon tai vaihtoehtoisen SE-menetelmän. Taulukko on silti muotoiltu suoraan CSV:n mukaan.

**Table 2. Injury-related outpatient visits (ICD-10 blocks) and hospital treatment days**

| Outcome | FOF No (n=144) Mean (SE) | FOF Yes (n=330) Mean (SE) | IRR (95% CI) |
| --- | --- | --- | --- |
| S00–09 | 52.5 (11.8) | 47.9 (6.8) | 0.91 (0.56, 1.48) |
| S10–19 | 7.1 (7.7) | 9.0 (11.1) | 1.26 (0.09, 18.42) |
| S20–29 | 11.3 (4.1) | 15.4 (4.3) | 1.37 (0.56, 3.35) |
| S30–39 | 38.6 (16.4) | 19.6 (6.1) | 0.51 (0.20, 1.30) |
| S40–49 | 31.3 (8.8) | 56.0 (11.7) | 1.79 (0.83, 3.85) |
| S50–59 | 45.1 (12.6) | 43.2 (8.0) | 0.96 (0.47, 1.93) |
| S60–69 | 9.3 (3.3) | 19.6 (7.4) | 2.10 (0.76, 5.85) |
| S70–79 | 75.6 (21.4) | 74.9 (11.9) | 0.99 (0.49, 2.02) |
| S80–89 | 65.9 (19.6) | 64.7 (17.8) | 0.98 (0.42, 2.27) |
| S90–99 | 4.7 (2.7) | 9.9 (3.0) | 2.09 (0.59, 7.46) |
| T00–14 | 1.5 (0.9) | 1.4 (67.0) | 0.95 (0.20, 4.48) |
| Total | 321.3 (34.5) | 367.2 (30.1) | 1.14 (0.86, 1.52) |
| Hospital treatment days | 386.6 (3.86e+14) | 501.5 (1.17e+10) | 1.30 (0.80, 2.10) |

**Alaviite (liitettäväksi käsikirjoitukseen)**

Mean (SE) = ikä- ja sukupuolikorjattu arvio per 1000 henkilövuotta.  
IRR (95% CI) = FOF Yes vs FOF No, vakioitu iällä ja sukupuolella (offset = log(person-years)).
