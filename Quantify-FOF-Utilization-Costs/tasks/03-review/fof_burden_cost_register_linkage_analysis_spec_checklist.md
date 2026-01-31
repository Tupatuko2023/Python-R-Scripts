# TASK: FOF Burden & Cost – rekisterilinkitys ja analyysiaineiston spesifikaatio (checklist)

**Status**: 01-ready
**Assigned**: Codex
**Created**: 2026-01-29

## OBJECTIVE

Tuottaa ei-arkaluonteinen, toteutuskelpoinen spesifikaatio analyysivalmiille pseudonymisoidulle datasetille ja sen muodostuslogiikalle, jotta voidaan estimoida FOF:n yhteys palvelunkäyttöön ja kustannuksiin (NB + Gamma GLM / two-part, offset person-time), huomioiden frailty (Fried proxy), demografiat, komorbiditeetti ja aiemmat kaatumiset.

Tietosuoja (Option B): tämä työ tuottaa vain dokumentaatiota/metadataa/skeemoja ja (tarvittaessa) synteettistä esimerkkidataa. Ei raakadataa eikä henkilötason rekisteritietoja repoon.

## INPUTS

- Quantify-FOF-Utilization-Costs/README.md (Option B + projektin rakenne)
- Quantify-FOF-Utilization-Costs/docs/runbook.md (Option B ajopolku + guardrailit)
- Quantify-FOF-Utilization-Costs/data/data_dictionary.csv (nykyinen muuttujasanakirja, jos käytössä)
- Toimituspyynnön checklist (tämän taskin STEPS-kohtien mukaiset vaatimukset)
- Mahdolliset rekisterinpitäjien määrittelydokumentit (ei sisällä tunnisteita; vain koodistot ja algoritmikuvaus)

## STEPS

1. A) Aineistokuvaus ja rakenne (pakollinen)
   1.1 Laadi/ylläpidä data dictionary / codebook kaikista lähteistä:
   - taulujen nimet ja lyhyt kuvaus (cohort, encounters, episodes, costs, home care, rehab, jne.)
   - sarakenimet, tyypit (int/double/date/factor), arvot/luokat, puuttuvien koodit
   - avainkentät (pseudonym id), aikakentät (start/end), linkityskentät (episode_id tms.)
     1.2 Laadi aikarakennespeksi:
   - baseline-päivä ja seurannan loppu (12 kk tai censorointi)
   - censorointi-eventit (kuolema, muutto, hoivasiirtymä tms.) ja lähde
   - person-time laskenta (pt_days, pt_years) ja toimitetaanko valmiina
   - analyysiyksikkö: henkilötaso 0–12 kk ja/tai periodipaneeli (0–6, 6–12); suositus: molemmat, jos mahdollista

2. B) Altisteet ja kovariaatit (pakollinen)
   2.1 FOF-muuttuja:
   - kysymyksen tarkka muoto, koodaus (0/1; don’t know/missing), mittausajankohta (baseline), toistot jos on
     2.2 Frailty (Fried proxy):
   - komponentit ja luokituslogiikka (robust/prefrail/frail tai piste)
   - baseline-aikapiste ja puuttuvien käsittelysääntö
     2.3 Keskeiset sekoittajat:
   - ikä, sukupuoli, mahdollinen SES/education
   - komorbiditeetti-indeksi (Charlson/Elixhauser tms.), laskentasääntö + koodilista tai valmis indeksi
   - aiemmat kaatumiset: aikajänne ennen baselinea (esim. 12 kk), määritelmä (ICD-koodit / rekisterilähde)

3. C) Palvelunkäytön outcome-määrittely (pakollinen)
   - outcome-lista + operatiiviset määritelmät: ED, inpatient, outpatient, rehab, home-care (kontaktit/tunnit), mahdolliset muut
   - mukaanotto/poissulku (palveluluokat, yksiköt, erikoisalat)
   - aikaleima (start/end) ja periodille kohdistamisen logiikka
   - offset person-time count-outcomeille
   - toimitetaanko valmiit countit per henkilö/per periodi + person_time vai tapahtumataso

4. D) Episode-konsolidointi (pakollinen, jos episodeja käytetään)
   - episode-algoritmin dokumentti:
   - gap-sääntö (X päivää ilman kontaktia = uusi episode)
   - koodistot (ICD/NCSP/DRG tms.) ja rooli
   - siirrot ja ketjutus (ED → osasto)
   - episode-muuttujat: episode_id, episode_start, episode_end, episode_type, cost (jos saatavilla)
   - episode-tyyppiluokittelun säännöt

5. E) Kustannusdata (pakollinen)
   - costing map: taulu + sarakkeet (cost_amount, valuutta, hintavuosi)
   - kohdistusyksikkö: kontakti/episode/periodi/henkilö
   - kustannuskomponentit (in/out/ambulance/rehab/homecare jne.)
   - suora toteuma vs laskennallinen + laskentasääntö
   - nollakustannukset: 0 euroa vs puuttuva (NA vs 0)
   - hintavuosi ja mahdollinen indeksointi/deflatointi (ja indeksilähde) tai analyysi toteumina

6. F) Aggregoinnit ja toimitusformaatti (toivottu)
   - suositellut analyysitaulut:
     - person_level_012 (1 rivi/henkilö)
     - person_period (1 rivi/henkilö/periodi)
     - episodes (jos mahdollista)
   - nimikonventiot:
     - id, baseline_date, fu_start, fu_end, period
     - pt_days, pt_years
     - fof (0/1), frailty_cat / frailty_score
     - count: n_ed, n_inpatient, n_outpatient, n_rehab, n_homecare
     - cost: c_total, c_inpatient, c_outpatient, c_ambulance, c_rehab, c_homecare
   - tietosuoja: ei tunnisteita; päivämäärät tarvittaessa suhteellisina (päivät baselineen)

7. G) Minimitarkistukset ennen toimitusta (pyydetty)
   - lyhyt QC-raportti (ei-arkaluonteinen): n, seuranta-ajan jakauma, outcomejen perusjakaumat, kustannusten 0-osuus ja puuttuvat
   - frailty/FOF puuttuvuus
   - muutosloki (v1/v2…): muuttujat ja luokitukset

8. Tuotosten sijoittelu ja repo-hygienia
   - dokumentit (ei-arkaluonteiset) voivat mennä docs/ alle
   - kaikki ajon tuottamat artefaktit outputs/ (gitignored) ja mahdollinen derived_text docs/derived_text/ (gitignored)
   - ei koskaan commitoida outputs/ tai mitään DATA_ROOT:sta kopioitua sisältöä

## ACCEPTANCE CRITERIA

- [ ] Task-templaatin mukainen tehtävä on valmis ja kattaa kohdat A–G.
- [ ] Spesifikaatio listaa toimitettavat taulut, avaimet, aikakentät, outcome/cost/episode-määritelmät ja nimikonventiot.
- [ ] Option B -tietosuojarajaus on eksplisiittinen (ei raakadataa repoon; DATA_ROOT repo-ulkoinen).
- [ ] Tuotokset sijoittuvat vain outputs/ ja docs/derived_text/ (gitignored), eikä mitään arkaluonteista commitoida.
- [ ] CI-safe testit läpäisevät synteettisellä datalla:
  - python -m unittest discover -s Quantify-FOF-Utilization-Costs/tests
  - python -m unittest Quantify-FOF-Utilization-Costs.tests.test_end_to_end_smoke

## Log

- 2026-01-29T21:38:12+02:00 Started dependency unblock + RUN 3A prep per request.
- 2026-01-29T22:12:53+02:00 Resuming RUN 3A dependency/dictionary work after prior agent crash.
- 2026-01-29T22:15:02+02:00 Installed xlrd via pip (Termux pkg unavailable) and reran RUN 3A dictionary script; .xlsx files still unreadable (OLE2).
- 2026-01-30T03:04:30+02:00 Stashed unrelated changes; restored task + dictionary script; added FILE_UNREADABLE marker for unreadable copy files.
- 2026-01-30T03:23:43+02:00 Moved checklist to tasks/03-review and added RUN 3B spec.
