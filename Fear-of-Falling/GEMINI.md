# GEMINI.md — Fear-of-Falling (FOF) R Analysis Pipeline (Gemini CLI Source-of-Truth)

Tämä dokumentti määrittelee pakolliset säännöt, konventiot ja workflow’n Fear-of-Falling (FOF) -projektin R-analyysiputken refaktorointiin ja stabilointiin Gemini CLI -koodausagentilla.

**Tavoite:** turvallinen, toistettava, QA-henkinen kehitys ilman vahinkomuutoksia tuloksiin tai dataan.

## 0) Precedence (ristiriidat)
Jos ohjeet ovat ristiriidassa, noudata tätä järjestystä:
1) `Fear-of-Falling/GEMINI.md` (tämä tiedosto)
2) `Fear-of-Falling/AGENTS.md`
3) `Fear-of-Falling/CLAUDE.md` (legacy reference / taustakonventiot)

> Huom: `CLAUDE.md` sisältää käytännössä samat ydinkonventiot (standard header, output/manifest, QC), mutta GEMINI.md on tämän projektin ensisijainen ohje Gemini CLI -agentille.

---

## 1) CRITICAL RULES (NON-NEGOTIABLE)
1. **Immutable raw data**: Älä muokkaa raakadatatiedostoja. Kaikki transformaatiot koodissa.
2. **No guessing**: Älä arvaa muuttujien merkityksiä/yksiköitä/koodauksia.
   - Jos epäselvää: pyydä **(A)** `data_dictionary.csv`/codebook TAI **(B)** `names(df)` + `glimpse(df)` + 10 riviä dataotetta.
3. **Minimal & reversible changes**: Yksi looginen muutos kerrallaan, perustele mitä/miksi, ja toimita muutos **unified diff** -muodossa kun mahdollista.
4. **Reproducibility**:
   - Käytä `renv`-ympäristöä (restore ennen ajoa).
   - `set.seed(20251124)` **vain** satunnaisuudessa (MI/bootstrap/resampling) ja dokumentoi introon.
   - Tallenna `sessionInfo()` tai `renv::diagnostics()` `manifest/`-kansioon.
5. **Output discipline + manifest**:
   - Kaikki artefaktit: `R-scripts/<script_label>/outputs/`
   - **1 manifest-rivi per artefakti**: `manifest/manifest.csv` (file, date, script, git hash jos saatavilla).
6. **Standard Script Intro on pakollinen** jokaisen Kxx-skriptin alussa (ks. luku 6).
7. **QA**: Tee minimivalidointi aina (req cols, tyypit, uniikkius, missingness, delta-check, FOF_status ∈ {0,1}).
8. **Table-to-Text Crosscheck**: ennen kuin kirjoitat Results-tekstiä, varmista numeroiden vastaavuus taulukoihin.

---

## 2) Working directory (pakollinen)
Aja tämän aliprojektin komennot aina kansiosta:

`Python-R-Scripts/Fear-of-Falling/`

Varmista WD ennen ajoa:
- Shell: `pwd` / PowerShell: `Get-Location`
- R: `getwd()`

Pidä working directory samana koko ajon ajan, jos skripti käyttää suhteellisia polkuja.

---

## 3) Project map (päivitä kun varmistat reposta)
Tyypilliset polut (jos jokin puuttuu, lisää TODO ja etsi oikea paikka):
- `renv.lock`, `renv/`, `.Rprofile` (R-ympäristön toistettavuus)
- `R-scripts/` (Kxx-skriptit ja niiden outputs)
- `R/functions/` (helperit; suosi source() / uudelleenkäyttöä)
- `manifest/manifest.csv` (+ sessionInfo/diagnostiikka)
- `data/` (syötedata; usein gitignored)
- `outputs/` (vain jos projekti käyttää tätä erillisenä; ensisijainen on Kxx-kohtainen outputs)
- `*.Rmd` / `*.qmd` (raportit, jos käytössä)
- `.lintr`, `.editorconfig`, `.vscode/` (työkalutus)

---

## 4) Environment & reproducibility (R / renv)
### Restore (ennen ajoa)
R-konsolissa projektijuuresta:
```r
if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
renv::restore()
renv::status()
sessionInfo()
```

### Seed (vain satunnaisuudessa)

* Käytä `set.seed(20251124)` vain kun koodi käyttää satunnaisuutta (MI/bootstrap/resampling).
* Dokumentoi seed **standard intro** -blokissa.

### R Version Lock-in

The CI environment is pinned to the R version specified in the `Dockerfile` (e.g., `rocker/tidyverse:4.5.1`). This is to ensure a reproducible environment that matches the `renv.lock` file.

**To update the project's R version:**
1.  Update the `FROM` image tag in the `Dockerfile`.
2.  Run `renv::snapshot()` in the new R environment to generate an updated `renv.lock`.
3.  Commit both the `Dockerfile` and `renv.lock` changes together.

---

## 5) How to run (standard)

Jos repo tarjoaa runnerin (Makefile / justfile), suosi sitä (TODO: vahvista).

Muuten perusajo:

```bash
cd Python-R-Scripts/Fear-of-Falling
Rscript path/to/script.R
```

Esimerkki (Kxx):

```bash
Rscript R-scripts/K11/K11_MAIN.V1_primary-ancova.R
```

Session info / diagnostiikka:

```bash
Rscript -e "sessionInfo()" > manifest/sessionInfo.txt
# tai
Rscript -e "renv::diagnostics()" > manifest/renv_diagnostics.txt
```

### Canonical Entrypoints (Primary)

1.  **K1 Main Pipeline**: `R-scripts/K1/K1.7.main.R`
    *   Ajaa koko K1-analyysin (import -> QC -> analysis -> export).
    *   `Rscript R-scripts/K1/K1.7.main.R`
2.  **Smoke Test (Environment)**: `R-scripts/SMOKE/SMOKE_ENV.V1_environment-smoke.R`
    *   Tarkistaa renv-ympäristön ja kirjoitusoikeudet ilman dataa.
    *   `Rscript R-scripts/SMOKE/SMOKE_ENV.V1_environment-smoke.R`

> TODO: Vahvista muut pipeline-entrypointit (esim. K3) kun ne on refaktoroitu vastaamaan GEMINI.md -standardeja.

---

## 6) Kxx conventions (pakolliset)

### 6.1 Script-ID ja tiedostonimi

* **SCRIPT_ID:** `K{number}[.{sub}]_{suffix}` (esim. `K5_MA`, `K5.1_MA`, `K11_MAIN`)
* **File tag / filename:** `{SCRIPT_ID}.V{version}_{name}.R`

  * Tiedostonimen on suositeltavaa alkaa `{SCRIPT_ID}.V` (esim. `K11_MAIN.V1_primary-ancova.R`)
* **script_label:** kanoninen tunniste, joka vastaa `R-scripts/` alla olevaa kansion nimeä (esim. "K1", "K11").
  * Jos SCRIPT_ID on "K11_MAIN", `script_label` tulisi normalisoida muotoon "K11", jotta outputit menevät `R-scripts/K11/outputs/`.

### 6.2 Output + manifest (pakolliset)

* Kaikki artefaktit polkuun: `R-scripts/<script_label>/outputs/`
* Jokainen artefakti → **täsmälleen yksi** rivi `manifest/manifest.csv`
* Käytä `init_paths(script_label)` (tai projektin vastaava standard) output-polkujen resolvoimiseen.

### 6.3 Required vars (älä inventoi)

* Standard intro -blokissa oleva **Required vars** -lista ja koodin `req_cols <- c(...)` on oltava **1:1** vastaavuus.
* Jos muuttuja on epäselvä: pysähdy ja pyydä codebook / sample.

---

## 7) STANDARD SCRIPT INTRO (MANDATORY) — copy/paste template

> Täytä placeholderit. Tämä blokki on oltava ensimmäisenä skriptissä.

```r
#!/usr/bin/env Rscript
# ==============================================================================
# {{SCRIPT_ID}} - {{TITLE}}
# File tag: {{FILE_TAG}}          # e.g. {{SCRIPT_ID}}.V1_short-name.R
# Purpose: {{ONE_LINE_PURPOSE}}
#
# Outcome: {{OUTCOME}}
# Predictors: {{PREDICTORS}}
# Moderator/interaction: {{MODERATOR}}
# Grouping variable: {{GROUP}}
# Covariates: {{COVARIATES}}
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# {{REQUIRED_VARS}}
#
# Mapping example (optional; raw -> analysis; keep minimal + explicit):
# {{MAPPING_EXAMPLE}}
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: {{SEED}} (set only when randomness is used: MI/bootstrap/resampling)
#
# Outputs + manifest:
# - script_label: {{SCRIPT_ID}} (canonical)
# - outputs dir: R-scripts/{{SCRIPT_ID}}/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load raw data (immutable; no edits)
# 03) Standardize vars + QC (sanity checks early)
# 04) Derive/rename vars (document mapping)
# 05) Prepare analysis dataset (complete-case and/or MI flag)
# 06) Fit primary model (ANCOVA or mixed per project strategy)
# 07) Sensitivity models (if feasible; document)
# 08) Reporting tables (estimates + 95% CI; emmeans as needed)
# 09) Save artifacts -> R-scripts/{{SCRIPT_ID}}/outputs/
# 10) Append manifest row per artifact
# 11) Save sessionInfo / renv diagnostics to manifest/
# 12) EOF marker
# ==============================================================================
suppressPackageStartupMessages({
  library(here)
  {{REQUIRED_PACKAGES}}
})

# --- Standard init (MANDATORY) -----------------------------------------------
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "{{SCRIPT_ID}}"  # interactive fallback
}

# Canonical SCRIPT_ID (e.g. K11_MAIN)
script_id_raw <- sub("\.V.*$", "", script_base)
if (is.na(script_id_raw) || script_id_raw == "") script_id_raw <- "{{SCRIPT_ID}}"

# Derive script_label for folder mapping (e.g. K11_MAIN -> K11)
# Adjust logic as needed to match directory structure R-scripts/Kxx/
script_label <- strsplit(script_id_raw, "_")[[1]][1] # Simple heuristic: K11_MAIN -> K11

# init_paths() must set outputs_dir + manifest_path (+ options fof.*)
# Ensure reporting.R or qc.R is loaded for init_paths
source(here::here("R", "functions", "reporting.R"))

paths <- init_paths(script_label)
outputs_dir   <- paths$outputs_dir
manifest_path <- paths$manifest_path

# seed (ONLY when needed):
# set.seed({{SEED}})
```

### “Valid script” checklist (pakollinen)

Kxx-skripti on validi vain jos:

1. Standard intro on kokonaisena alussa
2. `script_label` = `SCRIPT_ID` (tai johdettu `.V`-prefiksin edestä)
3. Kaikki outputit `R-scripts/<script_label>/outputs/`
4. `req_cols` on olemassa ja matchaa Required vars 1:1
5. Jokainen artefakti kirjaa yhden rivin manifestiin
6. Seed käytössä vain satunnaisuudessa ja dokumentoitu
7. Table-to-text crosscheck tehty ennen Results-tekstiä

---

## 8) Data & outputs boundaries

### Data

* Älä muokkaa raakadataa.
* Oleta, että data voi olla gitignored / salattu.
* Jos data puuttuu, anna selkeä virhe + ohje (ei silent fail).

### Outputs

* Älä ylikirjoita “virallisia” tuloksia ilman pyyntöä.
* Älä commitoi outputteja ilman pyyntöä.
* Pidä artefaktit scriptikohtaisissa output-polkuissa.

---

## 9) Verified variable map (ÄLÄ INVENTOI; varmista)

Ennen mallinnusta varmista muuttujat datasta/codebookista ja kirjaa tähän (tai skriptin introon) “verified variable map”.

**Esimerkkikartta (VAIN jos varmistettu datasta/codebookista):**

* id: `id`
* age: `age` / `Age` (TBD)
* sex: `sex` / `Sex` (koodaus varmistettava)
* bmi: `BMI`
* fof_status (0/1): `FOF_status` (lähde voi olla `kaatumisenpelkoOn`)
* composite_z0: `ToimintaKykySummary0`
* composite_z12: `ToimintaKykySummary2`
* delta_composite_z: `ToimintaKykySummary2 - ToimintaKykySummary0`

Jos et pysty vahvistamaan: pysähdy ja pyydä data_dictionary tai sample.

---

## 10) Analysis strategy (ohjaava)

### Wide primary (ANCOVA follow-up)

`composite_z12 ~ FOF_status + composite_z0 + age + sex + BMI (+ perustellut sekoittajat)`

### Secondary (vain perustellusti)

`delta_composite_z ~ FOF_status + composite_z0 + age + sex + BMI`

### Long primary (mixed)

`Composite_Z ~ time * FOF_status + age + sex + BMI + (1 | id)`

> Käytä ID-sarakkeen oikeaa nimeä verified mapin mukaan.

---

## 11) QC — minimicheckit (pakollinen, ajetaan aikaisin)

1. `req_cols` löytyy ja kaikki sarakkeet ovat datassa
2. Tyypit järkevät (numeric/factor) ja muunnokset eksplisiittisiä
3. Uniikkius: wide → `id` uniikki; long → `(id, time)` uniikki
4. `FOF_status ∈ {0,1}` ja factor-labeling eksplisiittinen
5. Delta-tarkistus: `delta == followup - baseline` (toleranssilla)
6. Missingness: overall + FOF-ryhmittäin (raportoi)

---

## 12) Reporting rules

* Raportoi estimaatit + 95% CI (p-arvot toissijaisia).
* Suosi tulkittavia tiivistelmiä:

  * adjusted mean change / group difference (emmeans)
* Interaktioissa: simple slopes / kontrastit.
* Tee **TABLE-TO-TEXT CROSSCHECK** ennen tulostekstiä. Jos ristiriita: korjaa taulukko tai teksti — älä arvaa.

---

## 13) Change management (agentti / kehitys)

* Ei massarefaktoreita ilman pyyntöä.
* Pidä muutos pieni + peruttava; kerro mitä/miksi.
* Näytä unified diff.
* Kerro aina miten validoit (komennot + mitä tarkistit).
* `git status -sb` pitää näyttää vain tarkoitetut muutokset.

---

## 14) TODOs (maintainers)

* **Yhtenäistä `init_paths`**: Repossa on nyt `R/functions/qc.R` ja `R/functions/reporting.R`. Yhdistä kanoniseksi versioksi.
* Listaa 1–3 “canonical entrypoint” -skriptiä ja oikeat ajokomennot.
* Vahvista `init_paths()` sijainti ja optionimet (esim. `fof.outputs_dir`, `fof.manifest_path`).
* Dokumentoi datan sijainti ja mikä on gitignored (ilman arkaluontoista sisältöä).
* Vahvista output-konventio (onko `outputs/` erillinen vai vain Kxx-kohtaiset outputs).
* Lisää smoke test -skripti (jos mahdollista).

---