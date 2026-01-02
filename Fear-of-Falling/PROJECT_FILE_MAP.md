# PROJECT_FILE_MAP.md — FOF-alatutkimus (FOF_status × time) / R-pipeline kartta

Tämä dokumentti kertoo, missä projektin keskeiset tiedostot ja Kxx-skriptit sijaitsevat sekä mitä ne lukevat ja kirjoittavat. Tavoite on helpottaa Claude Code + claude-flow -orchestraatiota (refaktorointi, debuggaus, pipeline-hardenointi) erityisesti FOF_status × time -kysymyksen ympärillä.

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
| K14    | Deskriptiivinen “Table 1” FOF-ryhmittäin (baseline-vertailut; t-/chisq/Fisher p-arvot ilman monen testin korjausta).                                                               | Ensisijaisesti `data_final` (K1), muuten `analysis_data`, muuten `data/external/KaatumisenPelko.csv`.   | `R-scripts/K14/outputs/` (Table 1 -taulukot; CSV/HTML-tyyli) + `manifest/manifest.csv`.   | `FOF_status`/FOF-ryhmä, `age`, `sex`, sairaudet, SRH, MOI, BMI, tupakointi/alkoholi, liikuntakyky/500m, tasapaino, kaatuminen, murtumat, kipu.                                                                                    | Aja K1 → luo `data_final` (tai varmista `analysis_data`) → aja K14 projektin juuresta.                             | OK     |
| K15    | Frailty-proxy (“Fried-inspired”, ei standardi 5/5): muodostaa komponentit ja luokat; tekee jakaumat ja FOF-ristiintaulukot + 1 esimerkkikuva.                                      | Käyttää `analysis_data` jos olemassa; muuten lukee `data/external/KaatumisenPelko.csv`.                 | `R-scripts/K15/outputs/*.csv` + `*.html` (+ mahdollinen kuva) ja `manifest/manifest.csv`. | `FOF_status` (tai `kaatumisenpelkoOn` → recode), `Puristus0`, `kavelynopeus_m_sek0`, `oma_arvio_liikuntakyky`, `vaikeus_liikkua_500m/2km`, `maxkävelymatka`, `BMI`, frailty-derivaatiot (`frailty_count_3/4`, `frailty_cat_3/4`). | Aja projektin juuresta: `Rscript R-scripts/K15/K15.R` (skripti itsessään lukee CSV:n jos `analysis_data` puuttuu). | OK     |
| K16    | **FOF_status × time mixed model** (ensisijainen päätetermi: interaktio time × FOF_status) `analysis_mixed_workflow()`-entrypointin kautta; outcome `Composite_Z` long-formaatissa. | **TARKISTA**: long-data (id/time/FOF_status/Composite_Z) ja missä se syntyy (mahd. K1/K12/K16 preproc). | **TARKISTA**: `outputs/mixed_fof_time/` tai `outputs/K16/` + `manifest/manifest.csv`.     | `id`, `time`, `FOF_status`, `Composite_Z`, (kovariaatit: age/sex/BMI + optional).                                                                                                                                                 | **TODO**: määritä K16:n todellinen polku ja ajokomento; tavoitteena copy-paste “runbook”-ajo.                      | TODO   |

**Optional placeholders (K1–K10 / K12):**

- K1: datan lataus + “data_final” muodostus (viitataan K14:ssa ensisijaisena lähteenä)
- K5: moderointianalyysi (FOF_status × Composite_Z0 → Delta_Composite_Z), mutta käyttää `./outputs/`-konventiota (legacy)
- K12: mahdollinen long-formaatin rakentaja (FOF × time mixed model -polun kannalta kriittinen) — **TARKISTA**

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

## Internal consistency check

- K5 käyttää `./outputs/`-konventiota (legacy), kun taas K9/K11/K13/K14/K15 käyttävät `R-scripts/Kxx/outputs/` — tämä kannattaa normalisoida, jos orchestrator rakentaa yleisiä “artifact check” -sääntöjä.
- Manifestin `filename` ei tyypillisesti sisällä `outputs/`-hakemistoa, vaikka fyysinen tiedosto on `R-scripts/Kxx/outputs/`; task-packeteissa pitää tarkistaa molemmat tai sopia yksi standardi.
- K16 (mixed model, `analysis_mixed_workflow()`) puuttuu tästä aineistosta; sen todellinen skripti/polku pitää lisätä, jotta “FOF_status × time” -ensisijainen ajo on täysin kartoitettu.
- K1/K12 puuttuvat tästä kartasta; niiden rooli datan esikäsittelyssä ja long-formaatin rakentamisessa pitää varmistaa.
