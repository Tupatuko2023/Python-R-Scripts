# CHANGELOG

## [Unreleased]

### Added
- **K20-K26 Analysis Pipeline Completion**: Suoritettu koko K20-K26 analyysiputki PowerShell 7 -orkestraattorilla.
  - Ratkaistu kriittiset riippuvuudet (K15 frailty-datan päivitys, `gt` ja `readxl` pakettien asennus).
  - Tuotettu toistettavat analyysitulokset, mallit ja manifest-merkinnät.
- **K24 Visualization & QC**: Suoritettu `K24_VIS.V1_forestplots_table2A_cat_vs_score.R`.
  - Tuotettu Forest-kuvaajat FOF- ja Frailty-efekteille (PNG/PDF).
  - Vahvistettu QC PASS (z-diff < 1.96, ei merkkien flippauksia cat- vs score-mallien välillä).
- **PS7 Gemini CLI Bootstrap Pack**: Lisätty infrastruktuuri Gemini CLI -agentin toistettavaan ja fail-closed -periaatetta noudattavaan ajamiseen PowerShell 7 -ympäristössä.
  - `PS7_GEMINI_CLI_BOOTSTRAP.md`: Step-by-step käyttöönotto-ohjeistus ja työkalujen validointi.
  - `scripts/ps7/run_gemini_orchestrator.ps1`: Natiivi PS7-orkestrointiskripti, joka lataa tehtävät, laskee promptin tiivisteen (SHA256) ja hallinnoi CLI-putkitusta sekä lokitusta (`Start-Transcript`).
  - `ORCHESTRATOR_LOADING_CONTRACT.md`: Dokumentaatio järjestelmäkehotteen päivitysmekanismista ja todentamisesta (Hash/Banner verification).

### Ref
- `README.md`, `AGENTS.md`, `CLAUDE.md`, `PROJECT_FILE_MAP.md`, `agent_workflow.md`: Orkestrointi nojaa tiukasti näiden tiedostojen asettamiin lähdekoodin ja tulosteiden (Output discipline) hallintasääntöihin.

## Added PowerShell 7 orchestrator (S-FOF) + split Termux vs PS7

Tämä osio dokumentoi system promptiin ja agenttikuvaukseen tehdyt päivitykset ja niiden taustalla olevat lähdeviitteet (Source of Truth).

- **Rinnakkaisten järjestelmäohjeiden luonti (Termux ja PowerShell 7):**
  - *Muutos:* Jaettiin aiempi yksi ohje kahteen rinnakkaiseen tiedostoon (`SYSTEM_PROMPT_TERMUX_S-FOF.md` ja `SYSTEM_PROMPT_POWERSHELL7_S-FOF.md`). Molemmat jakavat identtiset projektin invariantit (QC, analyysistrategiat, manifest-kuri), mutta sisältävät täysin erilliset ajo- ja ympäristöohjeet (Bash+PRoot vs. pwsh).
  - *Perustelu:* Mahdollistaa agentin natiivin ja virheettömän toiminnan sekä Android/Termux-laitteilla että perinteisissä Windows PowerShell 7 -ympäristöissä ilman syntaksiristiriitoja.
  - *Ref:* `AGENTS.md` (runnerit ja reunaehdot), `CLAUDE.md` (yleinen toistettavuus ja R-ajot).

- **PS7-natiivit komennot ja putkitus:**
  - *Muutos:* PS7-ohjeeseen päivitettiin Windows-yhteensopivat komennot (`Get-ChildItem`, `Select-String`, `Set-Location`) ja putkitustapa (`Get-Content -Raw | gemini -p`). `termux-wake-lock` korvattiin OS-tason virranhallintaohjeistuksella pitkiä ajoja varten.
  - *Perustelu:* Termux-komennot (kuten `cat` putkitus tai `proot-distro`) aiheuttaisivat kaatumisia PowerShell-ympäristössä.

- **Toistettavuuden varmistaminen (sessionInfo / manifest):**
  - *Muutos:* Molempiin ohjeisiin lisättiin eksplisiittinen vaatimus tallentaa `sessionInfo()` ja `renv::diagnostics()` tulosteet `manifest/`-kansioon `CLAUDE.md`-dokumentin ohjeiden mukaisesti. Jokaista artefaktia kohden (polussa `R-scripts/<K_FOLDER>/outputs/<script_label>/`) kirjataan yksi rivi tiedostoon `manifest/manifest.csv`.
  - *Perustelu:* Varmistaa tuotosten tieteellisen toistettavuuden ja ehkäisee tuloshakemistojen sotkeentumisen kummassakin ympäristössä.
  - *Ref:* `CLAUDE.md` (Kxx-konventiot ja outputs/manifest), `PROJECT_FILE_MAP.md` (Polut ja Kxx-kartta).

- **Prioriteettien (Precedence) tarkennus:**
  - *Muutos:* Molempiin järjestelmäohjeisiin listattiin selkeä sääntöhierarkia, jossa on varmistettu vain olemassaolevien SOT-dokumenttien huomiointi (`WORKFLOW.md` > `agent_workflow.md` > `CLAUDE.md` > jne).
  - *Perustelu:* Estää hallusinaatiot, joissa agentti alkaisi seurata olemattomia SOT-dokumentteja, ja ratkaisee dokumenttien väliset ristiriidat deterministisesti.
  - *Ref:* `agent_workflow.md` (tasks/-workflow ja prioriteetit), `WORKFLOW.md` (Remote sync).

- **Data-varmistus ja Fail-Closed -säännön vahvistaminen:**
  - *Muutos:* "Ei kysymyksiä" -sääntö tuotiin selkeästi esiin. Ainoa poikkeus on koodin kaatuminen sarakevirheisiin tai epäselviin muuttujiin, jolloin agentti pyytää näytteen (esim. `names(df)` + `glimpse(df)`).
  - *Perustelu:* Suojaa arkaluontoista tai monimutkaista raakadataa vahingoilta ja estää arvaukset, jotka voisivat vääristää analyysiä. Table-to-text crosscheck on pakollinen ennen tulosten tekstimuotoilua.
  - *Ref:* `CLAUDE.md` (QC, table-to-text crosscheck), `AGENTS.md` (Agentin tehtävä).

## Uusi: KB-Aware Agent Päivitys

- **Precedence korjattu:** Määritelty selkeä sääntöjen hierarkia: `WORKFLOW.md` > `agent_workflow.md` > Agentin järjestelmäohje. SOT-dokumenttien (CLAUDE.md, AGENTS.md, README.md, PROJECT_FILE_MAP.md) luetteloitu prioriteetti kirkastettu eroon "legacy"-termeistä. (Ref: Tehtävänanto).
  - *Riskiarvio:* Jos prioriteetti on väärin, agentti saattaisi ajaa omia sääntöjään ohi repon SOT-dokumenttien. Tämä voidaan todentaa komennolla `grep -A 5 "PRECEDENCE" SYSTEM_PROMPT_UPDATE.md`.
- **Output & Manifest -polut tarkennettu:** Päivitetty noudattamaan PROJECT_FILE_MAP.md ja CLAUDE.md SOT-tietoa polkurakenteesta `R-scripts/<K_FOLDER>/outputs/<script_label>/` ja tasan yhden rivin manifest-merkinnästä (Ref: PROJECT_FILE_MAP.md).
- **KB UTILIZATION LAYER lisätty:** Lisätty täysin uusi osio ohjaamaan Knowledge Basen käyttöä: SOT-first, KB-fill-gaps, konfliktinratkaisu (SOT voittaa), assumption logging ja tiukka fail-closed ohjeistus hallusinaatioita (esim. GEMINI.md olettamista) vastaan. (Ref: Tehtävänanto).
- **PRoot distro esimerkit:** Varmistettu agentin suoritus ilman virheellisiä oletuksia interaktiivisista sessioista. Rscript kutsutaan turvallisesti bash-putken kautta non-root -ehdoin. (Ref: AGENTS.md).
- **Hallusinoitujen dokumenttien poisto:** Poistettu turhat odotukset, kuten se että GEMINI.md tai ANALYSIS_PLAN.md olisi automaattisesti olemassa SOT-ohjeena, jotta estetään olemattomiin viittaaminen. Tiedostojen olemassaolo varmistetaan aina tiedostojärjestelmästä ensin. (Ref: Tehtävänanto).
