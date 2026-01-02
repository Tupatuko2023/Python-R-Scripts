# AGENTS.md (Fear-of-Falling)

## Mission & scope

Tämä aliprojekti sisältää kaatumisen pelkoon (FOF) liittyvän tutkimus- ja
analyysiputken, jossa pääpaino on R-skripteissä ja raportoinnissa. Agentin
tehtävä on tehdä pieniä, kohdistettuja muutoksia koodiin ja dokumentaatioon
niin, että analyysi pysyy toistettavana ja tulokset eivät muutu vahingossa. Älä
muuta "virallisia" tuloksia, taulukoita tai kuvioita ilman eksplisiittistä
pyyntöä. Älä koske raakadataan tai salaisuuksiin.

## Working directory (pakollinen)

Aja tämän aliprojektin komennot aina kansiosta:

- `Python-R-Scripts/Fear-of-Falling/`

Varmista working directory ennen ajoa:

- Shell (macOS/Linux/WSL/Git Bash): `pwd`
- Windows PowerShell: `Get-Location`
- R: `getwd()`

Jos skripti käyttää suhteellisia polkuja, pidä working directory samana koko
ajon ajan.

## Project map (päivitä tarvittaessa)

Tyypilliset kansiot ja tiedostot tässä aliprojektissa (jos jokin puuttuu,
merkitse TODO ja etsi oikea paikka):

- `renv.lock`, `renv/`, `.Rprofile` (R-ympäristön toistettavuus)
- `outputs/` (tuotetut taulukot, kuviot, tekstit, docx/html yms.)
- `data/` tai vastaava (syötedata; usein gitignored ja/tai salattu)
- `R-scripts/` (Kxx-skriptit ja niiden `outputs/`; TODO: vahvista rakenne)
- `manifest/` (manifest.csv + sessionInfo/diagnostiikka; TODO: vahvista polku)
- `*.R` / `scripts/*.R` (analyysiskriptit, usein Kxx-tyyppinen sarja)
- `*.Rmd` / `*.qmd` (raportit, jos käytössä)
- `.lintr` (R-lint-konfiguraatio, jos käytössä)
- `.vscode/` (VS Code -asetukset, jos käytössä)

## Golden rules for agents

- Älä commitoi dataa, outputteja tai lokitiedostoja ilman pyyntöä.
- Älä commitoi avaimia, tokenia, salasanoja, `.env`-tiedostoja tai
  henkilötietoja.
- Pidä muutokset pieniä ja kohdistettuja. Ei massarefaktoreita ilman pyyntöä.
- Älä muuta analyysin tulkintaa tai "PRIMARY" tuloksia salaa. Jos muutos voi
  vaikuttaa numeroihin, kerro se selvästi.
- Käytä projektin olemassa olevia konventioita (polut, tulosten nimeäminen,
  manifestit, sessionInfo, jne).
- Älä keksi muuttujia tai niiden merkityksiä; jos epäselvää, pyydä
  data_dictionary tai `names(df)` + `glimpse(df)` + pieni otos.
- Kxx-skriptit: standardi intro/header on pakollinen ja Required Vars -lista +
  `req_cols`-tarkistus pitää täsmätä.
- Outputit ja manifesti: kaikki artefaktit `R-scripts/<script_label>/outputs/`
  ja yksi manifest-rivi per artefakti.
- Kerro aina mitä validoit ja millä komennoilla.

## Project-specific source of truth (CLAUDE.md)

- `CLAUDE.md` on tämän aliprojektin lopullinen ohje Kxx-konventioille ja
  raportointisäännöille.
- Määrittelee pakollisen Kxx-otsikkoblokin/templaten (Standard Script Intro) ja
  Kxx-skriptien rakenteen.
- Output-polut ja artefaktien kirjoitus: projektin standardi on
  `R-scripts/<script_label>/outputs/` (käytä täsmällistä polkua kuten
  `CLAUDE.md` määrää); manifestiloki `manifest/manifest.csv` jos määritelty.
- Tiukka muuttujakäytäntö: älä keksi muuttujia; Required Vars -lista ja
  `req_cols`-tarkistus täsmäävät 1:1.
- Toistettavuus: `set.seed(20251124)` vain satunnaisuudessa; tallenna
  `sessionInfo()` / `renv`-diagnostiikka `CLAUDE.md`-ohjeen mukaan.
- Raportoinnin QC: table-to-text crosscheck ennen tulosten kirjoittamista.

Non-negotiables (tiivistelmä):

- Älä muokkaa raakadataa.
- Älä keksi muuttujien merkityksiä/yksiköitä; jos epäselvää, pyydä
  data_dictionary tai `names(df)` + `glimpse(df)` + pieni otos.
- Kirjoita artefaktit standardi-output-polkuun ja kirjaa jokainen artefakti
  manifestiin (jos `CLAUDE.md` näin määrää).
- Uusissa Kxx-skripteissä on pakollinen otsikkoblokki ja `req_cols`-validointi.
- Seed vain satunnaisuudessa; tallenna sessionInfo/renv `CLAUDE.md`-ohjeen mukaan.
- Tee aina table-to-text crosscheck; älä arvaa numeroita.

## Environment setup

### R (suositus)

1. Siirry aliprojektin juureen:

```bash
cd Python-R-Scripts/Fear-of-Falling
```

1. Käynnistä R ja palauta renv (jos `renv.lock` on olemassa):

```r
if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
renv::restore()
```

1. Varmista, että renv aktivoituu:

```r
renv::status()
sessionInfo()
```

### Python (vain jos tätä aliprojektia varten tarvitaan)

Tässä aliprojektissa voi olla Python-apuskriptejä, mutta ensisijainen
Python-ympäristö voi olla repojuuressa.

- TODO: varmista onko Fear-of-Falling -kansiossa `pyproject.toml` tai
  `requirements.txt`.
- Jos ei ole, käytä repojuuren Python-ympäristöä ja aja skriptit aina
  suhteellisilla poluilla.

### If setup fails

Tarkista nämä:

- Onko `renv.lock` olemassa ja onko `renv/` kansio mukana.
- Onko `.Rprofile` olemassa ja latautuuko se (R käynnistettynä tästä kansiosta).
- Onko R-versio yhteensopiva lockfilen kanssa.
- Onko proxy- tai yritysverkko estämässä pakettiasennuksia (tarvittaessa
  CRAN-mirror ja repos-asetukset).

## How to run (yksi selkeä ajopolku)

Koska analyysiputkien rakenne vaihtelee, käytä tätä mallia ja täydennä
TODO-kohdat kun löydät oikeat entrypointit.

### Perusajo (malli)

1. Data ingest / valmistelu

- TODO: tunnista ingest-skripti (esim. `K00...` tai `01_...`).

1. Varsinainen analyysi

- Aja skripti Rscriptillä aliprojektin juuresta:

```bash
Rscript path/to/script.R
```

Esimerkkejä (päivitä vastaamaan todellisia polkuja):

```bash
Rscript K16.R
Rscript K18.R
```

- TODO: jos Kxx-skriptit sijaitsevat `R-scripts/Kxx/`, käytä sitä polkua ja
  varmista Kxx-konventiot (script_label + outputs/manifest).

1. Raportti

- Jos käytössä Quarto:

```bash
quarto render path/to/report.qmd
```

- Jos käytössä R Markdown:

```bash
Rscript -e "rmarkdown::render('path/to/report.Rmd')"
```

### Jos Makefile tai runner on olemassa

- TODO: tarkista onko tässä aliprojektissa `Makefile` tai `justfile`.
- Jos on, suosi yhtä komentoa:

```bash
make <target>
```

## Lint, format, and style

### R

- Lintr (VS Code + languageserver) käyttää yleensä `.lintr` tiedostoa
  projektijuuressa.
- Aja käsin:

```r
lintr::lint_dir(".")
```

- Formatointi (vain jos käytössä ja sovittu):

```r
styler::style_dir(".")
```

Periaate:

- Älä "formattaa kaikkea" ilman pyyntöä. Jos kosket useaan tiedostoon, kerro
  miksi.

### Python

- TODO: jos tässä aliprojektissa on Python-konfiguraatio, dokumentoi ruff/black
  tms.
- Muuten älä lisää uusia Python-työkaluja ilman perustelua.

## Testing & validation

### Minimivalidointi (aina kun teet muutoksen)

- Varmista että olet oikeassa working directoryssä.
- Aja muokattu skripti end-to-end samalla tavalla kuin käyttäjä ajaa sen.
- Tarkista että outputit syntyvät oikeaan paikkaan.
- Tarkista että `git status -sb` näyttää vain tarkoitetut muutokset.
- Jos skripti tuottaa artefakteja, varmista manifest-rivi per artefakti ja
  sessionInfo/diagnostiikka `manifest/`-kansioon (TODO: vahvista polku).
- Jos skripti käyttää satunnaisuutta (MI/bootstrap/resampling), varmista
  `set.seed(20251124)` ja dokumentoi se introon.

### Definition of Done

- Muutettu koodi ajaa onnistuneesti oikeasta kansiosta.
- Ei dataa, salaisuuksia eikä tuotettuja outputteja commitissa ilman pyyntöä.
- Muutos on pieni ja kohdistettu, ja dokumentaatio on päivitetty jos
  käyttäytyminen muuttui.
- Vastauksessa kerrotaan: mitä muuttui, miten validoitiin, ja mikä on
  mahdollinen riski.
- Raportoinnissa taulukko-teksti -ristiintarkistus (TABLE-TO-TEXT) on tehty,
  jos tuloksia raportoidaan.

## Data & outputs boundaries

- Data:
  - Älä muokkaa raakadataa.
  - Oleta, että data on gitignored ja mahdollisesti salattu (git-crypt tms.).
  - Jos data puuttuu, tee muutokset niin että koodi antaa selkeän virheen ja
    ohjeen (ei "silent fail").

- Outputs:
  - Kirjoita tuotetut tiedostot `CLAUDE.md`-ohjeen mukaiseen output-polkuun.
  - Jos käytössä Kxx-konventiot: käytä `R-scripts/<script_label>/outputs/` ja
    kirjaa manifestiin yksi rivi per artefakti (TODO: vahvista).
  - Älä ylikirjoita "virallisia" tuloksia ilman pyyntöä.
  - Suosi versionoitavia nimiä tai alikansioita (esim. `outputs/K18/`), jos se
    on projektin tapa.
  - Älä commitoi outputteja ellei tehtävä sitä vaadi.

## VS Code workflow

Suositellut laajennukset:

- R (REditorSupport) + languageserver
- Python (Microsoft)
- EditorConfig (jos `.editorconfig` käytössä)

Käytännöt:

- Aja komennot VS Coden terminaalista Fear-of-Falling -kansiosta.
- Jos diagnostiikka ei päivity:
  - "Developer: Reload Window"
  - käynnistä R uudelleen
  - varmista että `.lintr` on tässä kansiossa ja että VS Code käyttää tätä
    workspace rootia

## Change management

Commit- ja PR-periaatteet:

- Yksi muutoskokonaisuus per commit.
- Kuvaavat commit-viestit, esimerkiksi:
  - `fix: handle missing input column in K18`
  - `docs: clarify run instructions for Fear-of-Falling`

- Jos muutos voi vaikuttaa tuloksiin, mainitse se näkyvästi ja kerro miten
  vaikutus tarkistettiin.

Raportoi aina vastauksessa:

- Mitä tiedostoja muutit ja miksi.
- Miten ajoit ja validoit (komennot).
- Mahdolliset riskit ja rajoitteet.

## TODOs for maintainers (täytä kun tarkistat reposta)

- TODO: listaa tämän aliprojektin tärkeimmät entrypointit (1-3 skriptiä) ja
  oikeat polut.
- TODO: vahvista onko käytössä `renv.lock` + `renv/` + `.Rprofile` ja mikä on
  "oikea" restore-komento.
- TODO: dokumentoi missä data sijaitsee (polut ja mitä on gitignored), ilman
  että paljastat arkaluonteista tietoa.
- TODO: vahvista output-konventio (esim. `outputs/Kxx/`, manifestit,
  sessionInfo-tiedostot).
- TODO: lisää ohje pienelle testidatalle tai "smoke test" -ajolle, jos
  mahdollista.
- TODO: kerro käytetäänkö Quarto/R Markdown -raportteja ja miten ne
  renderöidään.
- TODO: lisää käytetyt VS Code -asetukset (workspace `.vscode/settings.json`),
  jos haluat vakioida lintr/languageserver-käytöksen.
- TODO: jos aliprojektissa on Python-riippuvuuksia, lisää selkeä asennus ja
  ajopolku (pyproject/requirements).
- TODO: lisää tieto, mitä tiedostoja ei saa muuttaa (esim. lukitut raportit,
  prereg, tms.), jos sellaisia on.

## Termux runner note (Rscript)

Jos ajat agenttia Android Termuxissa ja `Rscript` puuttuu natiivista Termuxista, aja kaikki R-komennot proot-ympäristössä ja käytä aina `/usr/bin/Rscript` (esim. `RSCRIPT_BIN=/usr/bin/Rscript`). Suositeltu malli:

```sh
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling && $RSCRIPT_BIN --version'
```
