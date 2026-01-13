# PROJECT_FILE_MAP.md — FOF-alatutkimus (FOF_status × time) / R-pipeline kartta

Tämä dokumentti kertoo, missä projektin keskeiset tiedostot ja Kxx-skriptit sijaitsevat sekä mitä ne lukevat ja kirjoittavat. Tavoite on helpottaa Claude Code + claude-flow -orchestraatiota (refaktorointi, debuggaus, pipeline-hardenointi) erityisesti FOF_status × time -kysymyksen ympärillä.

**Päivitys 2026-01-13:** Lisätty grep-varmistettuja I/O-kartoituksia _MAIN-skripteille (K01_MAIN-K19_MAIN). Kattava I/O-taulukko: `docs/run_order.csv`, ajojärjestysrunbook: `docs/R_RUN_ORDER.md`.

## Miten karttaa käytetään (Claude-task-packetien pohjana)

- Kun käyttäjä sanoo “aja Kxx end-to-end”, tästä näet: **inputit**, **outputit**, **ajotapa**, ja **mitä artefakteja pitäisi syntyä**.
- Kun käyttäjä sanoo “refaktoroi mixed model workflow”, tästä näet: mitkä skriptit jo käyttävät yhteisiä konventioita (outputs + manifest) ja mitkä ovat “legacy”-tyylisiä.
- Kun agentti tarvitsee QC-tarkistuksia, tästä näet minimi-odotukset (analysis_data / data_final -objekti, data/external/KaatumisenPelko.csv, manifest/manifest.csv).

## Repo-rakenne (kansioiden roolit)

Alla oleva rakenne on **osittain varmistettu** skriptikatkelmista (here::here-viittaukset ja kommentit). Varmistetut polut on merkitty “(varmistettu)”.

- `Fear-of-Falling/` — projektin juuri (oletus; here::here) (varmistettu useissa skripteissä, esim. K9/K11/K13/K14/K15)
- `R-scripts/` — skriptit alikansioissa `R-scripts/Kxx/` (varmistettu)
  - `R-scripts/K9/outputs/` (varmistettu)
  - `R-scripts/K11/outputs/` (varmistettu)
  - `R-scripts/K13/outputs/` (varmistettu)
  - `R-scripts/K14/outputs/` (varmistettu)
  - `R-scripts/K15/outputs/` (varmistettu)

- `data/external/KaatumisenPelko.csv` — oletusdata (varmistettu K13/K14/K15)
- `manifest/manifest.csv` — audit-loki (taulukot/kuvat; skripti, tyyppi, tiedostonimi, kuvaus) (varmistettu K9/K11/K13/K14/K15)

**TARKISTA / placeholderit (ei varmistettu tästä aineistosta):**

- `R/` tai `functions/` — jaetut funktiot (esim. `analysis_mixed_workflow()`)
- `docs/` — README/RUNBOOK, codebook, tämä kartta
- `outputs/` — mahdollinen “legacy” output-kansio (näkyy K5-tyylisessä skriptissä)

## Kxx-skriptikartta

### Kxx Script Map

| Script | Purpose                                                                                                                                                                            | Reads (inputs)                                                                                          | Writes (outputs)                                                                          | Key variables                                                                                                                                                                                                                     | How to run                                                                                                         | Status |
| ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ | ------ |
| K9     | ANCOVA/lineaariset mallit DeltaComposite/Delta\_\*-muutoksille; eksploratiivisia interaktioita (esim. FOF_status × AgeClass_final; myös 3-way) erikseen naisille/miehille.         | `analysis_data` (vaaditaan; skripti stop jos puuttuu).                                                  | `R-scripts/K9/outputs/*.csv` + `*.png`; lisäksi rivit `manifest/manifest.csv`.            | `FOF_status`, `AgeClass_final`, `DeltaComposite`, `ToimintaKykySummary0`, `BMI`, `MOIindeksiindeksi`, (esim.) `Neuro_any`, `diabetes`.                                                                                            | **TARKISTA** polku skriptiin; konsepti: lataa/luo `analysis_data` (esim. K1), sitten aja K9 projektin juuresta.    | OK     |
| K11    | “Prognostic marker” -tyyppinen analyysi: FOF vaikutus toimintakyvyn muutokseen; mukana perus- ja laajennettu malli, MI (mice) ja responder/ordinaali-analyysejä.                   | `analysis_data` (vaaditaan; skripti stop jos puuttuu).                                                  | `R-scripts/K11/outputs/*.csv` + `*.html`; manifest-päivitykset `manifest/manifest.csv`.   | `FOF_status`, `Delta_Composite_Z`, `Composite_Z0`/`ToimintaKykySummary0/2`, kovariaatit (esim. `age`, `sex`, `BMI`, jne.).                                                                                                        | Aja R-istunnossa, jossa `analysis_data` on jo olemassa; aja projektin juuresta (here::here-polut).                 | OK     |
| K13    | FOF × moderaattori -interaktiot (ikä/BMI/sukupuoli; laajennetut mallit), simple slopes -taulukot ja kuvat; sisältää myös MI-työkaluja (mice) joissain osissa.                      | `data/external/KaatumisenPelko.csv` (lukee itse).                                                       | `R-scripts/K13/outputs/*.csv` + `*.html` + `*.png`; manifestiin useita rivejä.            | `FOF_status`, `Delta_Composite_Z`, `age` (centered, esim. `age_c`), `BMI` (centered), `sex`.                                                                                                                                      | Aja projektin juuresta (here::here): `Rscript R-scripts/K13/K13.R` (**TARKISTA** tarkka tiedostonimi).             | OK     |
| K14    | Deskriptiivinen "Table 1" FOF-ryhmittäin (baseline-vertailut; t-/chisq/Fisher p-arvot ilman monen testin korjausta).                                                               | **Grep-varmistettu (K14_MAIN):** `data/external/KaatumisenPelko.csv` (lukee suoraan; ei vaadi K1:tä).   | `R-scripts/K14/outputs/` (Table 1 -taulukot; CSV/HTML-tyyli) + `manifest/manifest.csv`.   | `FOF_status`/FOF-ryhmä, `age`, `sex`, sairaudet, SRH, MOI, BMI, tupakointi/alkoholi, liikuntakyky/500m, tasapaino, kaatuminen, murtumat, kipu.                                                                                    | Aja projektin juuresta: `Rscript R-scripts/K14/K14.R` (tai K14_MAIN-versio).                               | OK     |
| K15    | Frailty-proxy ("Fried-inspired", ei standardi 5/5): muodostaa komponentit ja luokat; tekee jakaumat ja FOF-ristiintaulukot + 1 esimerkkikuva.                                      | **Grep-varmistettu (K15_MAIN):** `data/external/KaatumisenPelko.csv` (lukee suoraan).                   | **Grep-varmistettu:** `R-scripts/K15/outputs/K15_frailty_analysis_data.RData` + CSV/HTML/PNG; manifest. | `FOF_status` (tai `kaatumisenpelkoOn` → recode), `Puristus0`, `kavelynopeus_m_sek0`, `oma_arvio_liikuntakyky`, `vaikeus_liikkua_500m/2km`, `maxkävelymatka`, `BMI`, frailty-derivaatiot (`frailty_count_3/4`, `frailty_cat_3/4`). | Aja projektin juuresta: `Rscript R-scripts/K15/K15.R` (tai K15_MAIN). RData tarvitaan K16/K18 -skripteille.        | OK     |
| K16    | **FOF_status × time mixed model** (ensisijainen päätetermi: interaktio time × FOF_status); frailty-adjusted ANCOVA/mixed models.                                                   | **Grep-varmistettu (K16_MAIN):** `R-scripts/K15/outputs/K15_frailty_analysis_data.RData` (riippuvuus K15). | **Grep-varmistettu:** `R-scripts/K16/outputs/` (CSV model outputs) + `manifest/manifest.csv`.          | `id`, `time`, `FOF_status`, `Composite_Z`, `frailty_cat_3`, `frailty_score_3` (kovariaatit: age/sex/BMI).                                                                                                                         | Aja K15 ensin → sitten `Rscript R-scripts/K16/K16.R` (tai K16_MAIN). Katso: `docs/R_RUN_ORDER.md` Chain B/D.       | OK     |

**Grep-varmistetut lisäskriptit (K1–K4, refactored _MAIN-versiot):**

- **K1 / K01_MAIN:** Z-score change analysis (baseline → 12m); lukee `data/external/KaatumisenPelko.csv`, kirjoittaa `K1_Z_Score_Change_2G.csv`
- **K2 / K02_MAIN:** Transposes K1 z-scores by FOF status; riippuu K1:stä
- **K3 / K03_MAIN:** Original test values (ei z-scoreja); lukee raw CSV, kirjoittaa `K3_Values_2G.csv`
- **K4 / K04_MAIN:** Transposes K3 values by FOF status; riippuu K3:sta
- **K5-K10, K12:** ANCOVA/visuals/moderators; lukevat `data/external/KaatumisenPelko.csv` suoraan (_MAIN-versiot noudattavat `R-scripts/Kxx_MAIN/outputs/` -konventiota)
- **K17_MAIN:** Baseline table with frailty; lukee raw CSV
- **K18_MAIN:** Frailty change contrasts; riippuu K15:stä, tallentaa `K18_all_models.RData`
- **K19_MAIN:** Frailty vs FOF evidence pack; riippuu K18:stä

**Katso:** `docs/run_order.csv` ja `docs/R_RUN_ORDER.md` täydellisille I/O-kartoille ja ajojärjestyksille.

## Yhteiset resurssit (helpers, config, metadata)

- **Data-oletuspolku:** `data/external/KaatumisenPelko.csv` (useissa skripteissä fallback)
- **In-memory data-objektit:**
  - `analysis_data` (vaaditaan esim. K9/K11; K14/K15 voivat luoda sen fallbackina)
  - `data_final` (K14 ensisijaisesti; syntyy todennäköisesti K1:ssä)

- **Manifest:** `manifest/manifest.csv` (append/luonti skriptien sisällä; käytössä K9/K11/K13/K14/K15)
- **Helperit skripteissä:** `save_table_csv_html()`, `update_manifest()` (K11/K15 eksplisiittisesti; K13/K9 kirjoittaa myös manifest-rivejä)
- **Mixed model -entrypoint:** `analysis_mixed_workflow()` (tämän kartan kannalta kriittinen, mutta sijainti repoissa **TARKISTA**).

## Konventiot (output-polut ja manifest)

- Uudempi/yleinen konventio: `outputs_dir <- here::here("R-scripts", "Kxx", "outputs")` ja kirjoitukset sinne.
- `manifest/manifest.csv` päivitetään joko:
  - “rivi kerrallaan” `update_manifest()`-helperillä (K11/K15-tyyli), tai
  - muodostamalla `manifest_rows`-taulukko ja `write_csv(..., append=TRUE)` (K9/K13-tyyli).

- Huomio orchestratorille: manifestin `filename`-kenttä näyttää usein muotoa `Kxx/<tiedosto>` (ei sisällä `outputs/`-osaa), vaikka fyysinen tiedosto on `R-scripts/Kxx/outputs/<tiedosto>`. Tämä on tärkeää, kun rakennetaan “verify artifacts” -askelia.

## Internal consistency check (päivitetty 2026-01-13 grep-varmistuksen perusteella)

- ✅ **K16 varmistettu:** K16/K16_MAIN nyt täysin kartoitettu; lukee K15 RData:n, ei vaadi `analysis_mixed_workflow()` helperiä
- ✅ **K1-K4 pipeline lisätty:** K1→K2 (z-scores) ja K3→K4 (original values) -ketjut grep-varmistettu
- ✅ **K14 data source korjattu:** K14 lukee suoraan `data/external/KaatumisenPelko.csv`, ei vaadi K1:n `data_final`-objektia
- ✅ **_MAIN-versiot kartoitettu:** K01_MAIN-K19_MAIN I/O-riippuvuudet varmistettu; kaikki noudattavat `R-scripts/Kxx_MAIN/outputs/` -konventiota
- ⚠️ **Legacy konventiot:** Vanhat K5-K8 skriptit voivat käyttää `./outputs/`-konventiota; _MAIN-versiot normalisoitu
- 📋 **Manifest filename -konventio:** Manifestin `filename`-kenttä ei sisällä `outputs/`-osaa; task-packeteissa tarkista `R-scripts/Kxx/outputs/<filename>` fyysiselle polulle

**Jatkotoimet:**
- Legacy K5-K14 (ei _MAIN) skriptien I/O-mappaus jätetty tulevaisuuteen (fokus nyt _MAIN-versioissa)
- Testaa end-to-end _MAIN-pipeline: K01_MAIN→K02_MAIN ja K15_MAIN→K16_MAIN→K18_MAIN→K19_MAIN
