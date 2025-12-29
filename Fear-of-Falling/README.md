# FOF × aika (baseline → 12 kk) — mixed model -ajamisohje (Composite_Z)

[![K Scripts Smoke Tests](https://github.com/Tupatuko2023/Python-R-Scripts/actions/workflows/smoke-tests.yml/badge.svg)](https://github.com/Tupatuko2023/Python-R-Scripts/actions/workflows/smoke-tests.yml)
[![Analysis Plan](https://img.shields.io/badge/Docs-Analysis_Plan-blue)](docs/ANALYSIS_PLAN.md)

**Official Analysis Plan:** [docs/ANALYSIS_PLAN.md](docs/ANALYSIS_PLAN.md)

**Primary model + QC gate (short):**

- Model: Composite_Z ~ time * FOF_status + age + sex + BMI + (1 | id)
- Required vars: id, time, FOF_status, Composite_Z, age, sex, BMI
- time coding: TODO (confirm from data/data_dictionary.csv)
- FOF_status coding: 0=Ei FOF, 1=FOF (from kaatumisenpelkoOn)
- Long data: (id, time) unique; 2 time levels only
- Missingness: report overall + FOF_status x time
- Delta check: if Delta_Composite_Z exists, verify follow-up - baseline
- QC runner: R-scripts/K18/K18_QC.V1_qc-run.R --data <PATH>
- Stop-the-line: do not model until QC passes
- Outputs: R-scripts/<K_FOLDER>/outputs/<script_label>/
- Audit: manifest/manifest.csv row per artifact

**Primary Analysis:** Longitudinal mixed model (`Composite_Z ~ time * FOF_status + ...`).
**QC Gates:** All data must pass strict checks (n=2 timepoints, correct factors) defined in [QC_CHECKLIST.md](QC_CHECKLIST.md) before modeling.

Tämä README on ajamisohje ("runbook") FOF-alatutkimuksen päätarkastelulle:
**FOF_status × time** -interaktio fyysisen toimintakyvyn muutoksessa
(**Composite_Z**) käyttäen **lineaarista sekamallia** (lmer; satunnaisintersepti
henkilölle: **(1 | id)**). Ajot tuottavat raportointivalmiit taulukot +
(valinnaisen) interaktiokuvan, tallentavat artefaktit
`R-scripts/<K_FOLDER>/outputs/<script_label>/`-hakemistoon (CLAUDE.md Output discipline)
ja kirjaavat ne `manifest/manifest.csv`-tiedostoon (1 rivi per artefakti).

---

## Prerequisites

**Tarvitset:**

- Git
- R (käytä projektin `renv.lock`-tiedoston kanssa yhteensopivaa R-versiota)
- renv (asennetaan tarvittaessa ajon yhteydessä)

**Oletettu reposisrakenne (minimi):**

- `renv.lock`
- `manifest/` (luodaan jos puuttuu)
- `R-scripts/<K_FOLDER>/outputs/<script_label>/` (output discipline; luodaan skripteissä tarvittaessa)
- (suositus) `R/` tai `R-scripts/` jossa ajoskripti ja/tai `analysis_mixed_workflow()`-funktio

**Huom:** Vältä repo-root `outputs/`-hakemistoa (legacy/deprecated); käytä CLAUDE.md:n mukaista polkua.

**Data-politiikka (ei raw-dataa KB:hen):**

- Älä kopioi tai “upload”-ohjeista osallistujatason raakadataa tietopankkiin.
- Käytä aina **polkuja** (esim. `data/external/...`) tai valmiita R-olioita paikallisesti.
- **Variable Standardization:** Käytä `data/VARIABLE_STANDARDIZATION.csv` sarakkeiden nimeämiseen. Katso [VARIABLE_STANDARDIZATION.md](data/VARIABLE_STANDARDIZATION.md).

---

## Quickstart

### Ajo repojuuresta (suositus: Kxx-skriptit)

> Korvaa placeholderit: `<K_FOLDER>`, `<FILE_TAG>`

```bash
# 1) kloonaa ja siirry repojuureen
git clone <REPO_URL> <REPO_PATH>
cd <REPO_PATH>

# 2) valitse haara/commit (tarvittaessa)
git checkout <BRANCH_OR_COMMIT>

# 3) renv restore (AINA ennen ajoa)
R -q -e 'if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv"); renv::restore(prompt = FALSE)'

# 4a) Etsi ajettava Kxx-skripti (vältä oletuksia polusta/tiedostonimestä)
find R-scripts -maxdepth 3 -type f -name "*.R" | head -30

# 4b) Aja valittu Kxx-skripti repojuuresta (esim. K11, K12, ...)
Rscript "R-scripts/<K_FOLDER>/<FILE_TAG>.R"
# Esimerkki: Rscript "R-scripts/K11/K11.R"

# 5) Tarkista output discipline (polku CLAUDE.md:n mukaan)
ls -la "R-scripts/<K_FOLDER>/outputs/<script_label>/"
# Esimerkki: ls -la "R-scripts/K11/outputs/K11/"

# 6) Tarkista manifest-päivitys
cat manifest/manifest.csv | tail -10
```

### Vaihtoehtoinen ajo: driver-skripti (jos olemassa)

Jos repo sisältää driver-skriptin (esim. `R-scripts/run_mixed_fof_time.R`), varmista olemassaolo ennen käyttöä:

```bash
# Tarkista driver
test -f "R-scripts/run_mixed_fof_time.R" && Rscript "R-scripts/run_mixed_fof_time.R" --help || echo "Driver missing; use Kxx script directly"

# Ajo driver-skriptillä (korvaa <DATA_PATH_OR_OBJECT>, <OUTPUT_DIR>)
# HUOM: tarkista että output_dir noudattaa CLAUDE.md Output discipline -polkua
Rscript R-scripts/run_mixed_fof_time.R --data "<DATA_PATH_OR_OBJECT>" --out "R-scripts/<K_FOLDER>/outputs/<script_label>"
```

---

## K1-K4 Analysis Pipelines (Refactored 2025-12-24)

### Overview

K1-K4 scripts provide foundational data processing and transformation pipelines that prepare data for downstream analyses. These scripts have been refactored to comply with CLAUDE.md standards:

- Standard headers with documented variables
- Reproducible paths (`here::here()` + `init_paths()`)
- Manifest logging (all outputs tracked)
- Seed setting for bootstrap (K1.4, K3.4)

### Pipeline Summary

| Pipeline | Purpose | Input | Output | Run Command |
|----------|---------|-------|--------|-------------|
| **K1** | Z-score change analysis | Raw CSV | Z-score change tables | `Rscript R-scripts/K1/K1.7.main.R` |
| **K3** | Original values analysis | Raw CSV (shares K1.1) | Original value tables | `Rscript R-scripts/K3/K3.7.main.R` |
| **K2** | Z-score pivot/transpose | K1 outputs | Transposed z-scores | `Rscript R-scripts/K2/K2.Z_Score_C_Pivot_2G.R` |
| **K4** | Score pivot/transpose | K3 outputs | Transposed scores | `Rscript R-scripts/K4/K4.A_Score_C_Pivot_2G.R` |

### Running K1-K4 (from repo root)

#### K1: Z-Score Change Analysis

```bash
# Full pipeline (K1.1 → K1.2 → K1.3 → K1.4 → K1.5 → K1.6)
Rscript R-scripts/K1/K1.7.main.R

# Outputs appear in:
ls -lh R-scripts/K1/outputs/

# Check manifest logging:
grep '"K1"' manifest/manifest.csv | tail -10
```

**What K1 does:**

1. Loads raw data (`dataset/KaatumisenPelko.csv`)
1. Transforms to analysis variables (Composite_Z0, Composite_Z2, Delta_Composite_Z, FOF_status)
1. Runs statistical tests
1. Calculates effect sizes with bootstrap CI (uses `set.seed(20251124)`)
1. Computes distributional stats (skewness/kurtosis)
1. Exports final table: `K1_Z_Score_Change_2G.csv`

#### K3: Original Values Analysis

```bash
# Full pipeline (K1.1 → K3.2 → K3.3 → K3.4 → K1.5 → K3.6)
# Note: K3 reuses K1.1 (data import) and K1.5 (kurtosis/skewness)
Rscript R-scripts/K3/K3.7.main.R

# Outputs:
ls -lh R-scripts/K3/outputs/

# Check manifest:
grep '"K3"' manifest/manifest.csv | tail -10
```

**What K3 does:**
Similar to K1 but analyzes original test values instead of z-scores.

#### K2: Z-Score Pivot (requires K1 outputs)

```bash
# Transpose z-score results by FOF status
Rscript R-scripts/K2/K2.Z_Score_C_Pivot_2G.R

# Alternative script (if needed):
Rscript R-scripts/K2/K2.KAAOS-Z_Score_C_Pivot_2R.R

# Outputs:
ls -lh R-scripts/K2/outputs/
```

**What K2 does:**
Recodes test names by FOF status and transposes data for presentation.

#### K4: Score Pivot (requires K3 outputs)

```bash
# Transpose score results by FOF status
Rscript R-scripts/K4/K4.A_Score_C_Pivot_2G.R

# Outputs:
ls -lh R-scripts/K4/outputs/
```

**What K4 does:**
Similar to K2 but for original values instead of z-scores.

### Migration Notes (Old → New)

**Old behavior (pre-refactoring):**

- Outputs went to `tables/` (hardcoded Windows paths like `C:/Users/tomik/...`)
- No manifest tracking
- Required manual path editing to run on different machines

**New behavior (post-refactoring):**

- Outputs go to `R-scripts/<K>/outputs/` (portable, `here::here()` based)
- All outputs logged in `manifest/manifest.csv`
- Scripts run from repo root without modification
- Cross-platform compatible

**If you have old outputs in `tables/`:** They are not automatically migrated. Re-run pipelines to generate new outputs in standard locations.

### Dependencies

```
Raw Data (dataset/KaatumisenPelko.csv)
    │
    ├─────────────────────────────────────┐
    │                                     │
    v                                     v
K1 Pipeline                          K3 Pipeline
    │                                     │
    ├─ K1.1 (data import) ────────────────┤ (shared)
    ├─ K1.2 (transformation)              ├─ K3.2 (transformation)
    ├─ K1.3 (statistics)                  ├─ K3.3 (statistics)
    ├─ K1.4 (effect sizes + bootstrap)    ├─ K3.4 (effect sizes + bootstrap)
    ├─ K1.5 (skewness/kurtosis) ──────────┤ (shared)
    └─ K1.6 (export)                      └─ K3.6 (export)
    │                                     │
    v                                     v
K1 outputs                           K3 outputs
    │                                     │
    v                                     v
K2 Pipeline                          K4 Pipeline
    │                                     │
    v                                     v
K2 outputs                           K4 outputs
```

### Troubleshooting K1-K4

**Error: "Raw data file not found"**

- Check that `dataset/KaatumisenPelko.csv` exists
- Or place data in `data/raw/KaatumisenPelko.csv` (preferred)

**Error: "Missing required columns"**

- Verify raw data has: `id`, `ToimintaKykySummary0`, `ToimintaKykySummary2`, `kaatumisenpelkoOn`, `age`, `sex`, `BMI`

**Error: "K1 output not found" (when running K2)**

- Run K1 first: `Rscript R-scripts/K1/K1.7.main.R`
- Check K1 outputs exist: `ls R-scripts/K1/outputs/`

**Error: "K3 output not found" (when running K4)**

- Run K3 first: `Rscript R-scripts/K3/K3.7.main.R`
- Check K3 outputs exist: `ls R-scripts/K3/outputs/`

---

## What gets run

**Kanoninen sisääntulopiste:** `analysis_mixed_workflow()`.

**Malli (kiinteät + satunnaiset):**

- Kiinteät: `Composite_Z ~ time * FOF_status + age + sex + BMI (+ optional covariates)`
- Satunnaiset: `(1 | id)`
- Päätulos: **interaktiotermi `time:FOF_status`** (FOF-ryhmän muutos vs Ei FOF-ryhmän muutos baseline→12 kk)

**FOF_status-koodaus (suositus):**

- `FOF_status = factor(..., levels = c("Ei FOF","FOF"))`

**Manifest + outputs -käytäntö (CLAUDE.md Output discipline):**

- Output-polku: `R-scripts/<K_FOLDER>/outputs/<script_label>/` (script_label = SCRIPT_ID, katso "Naming conventions" alla)
- `manifest/manifest.csv`: 1 rivi per artefakti, pakolliset sarakkeet: **file, date, script, git hash** (jos saatavilla)
  - Legacy/optional sarakkeet: type, filename, description (voidaan säilyttää yhteensopivuuden vuoksi)
- Siemen: `set.seed(20251124)` **vain** kun satunnaisuutta (MI, bootstrap, resampling)—ei deterministisille malleille (lm, lmer)

---

## Inputs and expected data shape

**Suositus:** long-muotoinen data (1 rivi per henkilö per aikapiste).

**Pakolliset sarakkeet:**

- `id` : yksilö-ID (integer/character)
- `time` : aikamuuttuja (tarkista koodaus data_dictionary.csv:st??; esimerkit alla k??ytt??v??t baseline/m12)
- `Composite_Z` : lopputulos (numeric)
- `FOF_status` : ryhmä (factor: `Ei FOF`, `FOF`)
- kovariaatit: `age` (numeric), `sex` (factor), `BMI` (numeric)

**Ajan koodaus (valitse yksi ja dokumentoi):**

1. **Binäärinen 0/1 + faktoriksi** (suositus emmeans-vertailuille):

- baseline = 0 → `"baseline"`
- 12 kk = 1 → `"m12"`

1. Faktoritasot suoraan:

- `factor(time, levels = c("baseline","m12"))`

**Minimitarkistus (ennen mallia):**

- Molemmissa ryhmissä (FOF/Ei FOF) havaintoja molemmilla aikapisteillä
- Ei “tyhjiä” faktoritason kombinaatioita (emmeans antaa helposti varoituksia)

---

## Reproducibility rules (CLAUDE.md mandatory)

**Pakolliset säännöt:**

1. **renv** (paketinhallinta)

```r
# AINA ennen ajoa (restore)
renv::restore(prompt = FALSE)

# VAIN jos paketit muuttuvat (snapshot)
renv::snapshot(prompt = FALSE)
```

**Huom:** Älä snapshottaa joka ajolla—vain kun lisäät/päivität paketteja.

1. **Seed** (satunnaisuus)

**Käytä `set.seed(20251124)` VAIN kun satunnaisuutta:**

```r
# KÄYTÄ seediä: multiple imputation, bootstrap, resampling
if (use_multiple_imputation) {
  set.seed(20251124)
  imputed <- mice(data, m = 5, ...)
}

# ÄLÄ käytä seediä: deterministiset mallit (lm, lmer, glm)
fit <- lmer(outcome ~ predictor + (1|id), data = df)  # ei tarvitse seediä
```

1. **Manifestiin tekninen toistettavuus**

Tallenna **aina** (joka ajolla) tiedostoihin `manifest/`:

- `sessionInfo_<script_label>.txt`
- `renv_diagnostics_<script_label>.txt`

1. **Manifest-kirjaus (CLAUDE.md Output discipline)**

**1 rivi per artefakti**, pakolliset sarakkeet:

- `file` — tiedostopolku (suhteellinen repojuuresta)
- `date` — aikaleima (Sys.time())
- `script` — skripti-ID (esim. K11, K12)
- `git_hash` — Git commit hash (jos saatavilla; muuten NA)

Esimerkki R-koodista:

```r
git_hash <- tryCatch(
  system("git rev-parse --short HEAD", intern = TRUE),
  error = function(e) NA_character_
)

manifest_entry <- tibble(
  file = "R-scripts/K11/outputs/K11/fit_primary_ancova.csv",
  date = Sys.time(),
  script = "K11",
  git_hash = git_hash
)
write_csv(manifest_entry, "manifest/manifest.csv", append = TRUE)
```

1. **Ei raw-datan siirtoa**

Kirjaa manifestiin vain polut + artefaktien nimet, ei osallistujatason dataa.

---

## Naming conventions (CLAUDE.md terms)

Jotta polut ja viittaukset ovat yhtenäisiä, käytä seuraavia termejä:

### SCRIPT_ID

Skripti-tunniste (esim. `K11`, `K12`, `K13`, ...). Jokainen skriptikansio `R-scripts/`-hakemiston alla nimetään SCRIPT_ID:n mukaan.

**Esimerkki:**

- `R-scripts/K11/` → SCRIPT_ID = `K11`
- `R-scripts/K12/` → SCRIPT_ID = `K12`
- `R-scripts/K5/` → SCRIPT_ID = `K5`

### file_tag

Tiedostonimen kuvaava osa (ilman `.R`-päätettä).

**Esimerkkejä:**

- `K11.R` → file_tag = `K11`
- `K5.1.V4_Moderation_analysis.R` → file_tag = `K5.1.V4_Moderation_analysis`
- `K2.Z_Score_C_Pivot_2G.R` → file_tag = `K2.Z_Score_C_Pivot_2G`

### script_label (canonical)

**Kanoninen tunniste** skriptille, johdettu tiedostonimen **prefix ennen `.V`** (jos versioitu) tai koko tiedostonimen runko.

**Esimerkkejä:**

- `K11.R` → `script_label = K11`
- `K5.1.V4_Moderation_analysis.R` → `script_label = K5.1` (prefix ennen `.V4`)
- `K2.Z_Score_C_Pivot_2G.R` → `script_label = K2.Z_Score_C_Pivot_2G` (ei versiota, käytetään koko file_tag)

**Käyttö:** Output-hakemistot ja manifest-merkinnät viittaavat `script_label`:iin yhtenäisyyden varmistamiseksi.

### Output-polku (täydellinen muoto)

```
R-scripts/<K_FOLDER>/outputs/<script_label>/
```

**Esimerkkejä:**

- `R-scripts/K11/outputs/K11/` (K11.R)
- `R-scripts/K5/outputs/K5.1/` (K5.1.V4_Moderation_analysis.R)
- `R-scripts/K12/outputs/K12/` (K12.R)

---

## Outputs

**Oletus:** kaikki artefaktit menevät hakemistoon (CLAUDE.md Output discipline):

- `R-scripts/<K_FOLDER>/outputs/<script_label>/` (esim. `R-scripts/K11/outputs/K11/`)

**Vältä:** repo-root `outputs/` (legacy/deprecated). Käytä aina skriptikohtaista polkua.

**Suositellut tiedostonimet (raportointivalmiit):**

- `fixed_effects.csv` + `fixed_effects.html`
  (estimate, SE, df (jos saatavilla), t, 95% CI, p)
- `interaction_focus.csv` + `interaction_focus.html`
  (vain interaktio + tulkintaa varten tarvittavat sarakkeet)
- `emmeans_time_by_fof.csv` + `emmeans_time_by_fof.html`
  (EMM:t: Composite_Z ajan mukaan, erikseen FOF-ryhmittäin)
- `contrasts_change_over_time.csv` + `contrasts_change_over_time.html`
  (muutos baseline→12 kk per ryhmä)
- `interaction_plot.png` (valinnainen)

**Manifest-kirjaus (CLAUDE.md):**

- `manifest/manifest.csv`: 1 rivi per artefakti
- Pakolliset sarakkeet: **file, date, script, git_hash** (jos saatavilla)
- Legacy/optional: type, filename, description (voidaan säilyttää yhteensopivuuden vuoksi)

---

## R-ajuri (copy-paste)

Tee (tai muokkaa) tiedosto: `R-scripts/run_mixed_fof_time.R`

```r
#!/usr/bin/env Rscript

# =============================================================================
# FOF × time mixed model driver (Composite_Z)
# =============================================================================

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(flag, default = NULL) {
  idx <- match(flag, args)
  if (!is.na(idx) && idx < length(args)) return(args[idx + 1])
  default
}

data_in  <- get_arg("--data", "<DATA_PATH_OR_OBJECT>")
out_dir  <- get_arg("--out",  "<OUTPUT_DIR>")
pr_thr   <- as.numeric(get_arg("--practical", "<PRACTICAL_THRESHOLD>"))

# ---- reproducibility (seed VAIN jos satunnaisuutta; katso CLAUDE.md)
# set.seed(20251124)  # Aktivoi vain jos käytät MI/bootstrap/resampling

# ---- packages (assumed installed via renv::restore)
suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(readr)
  library(knitr)
  library(lme4)
  # lmerTest is optional; if available, it adds df/p-values
  if (requireNamespace("lmerTest", quietly = TRUE)) {
    library(lmerTest)
  }
  library(emmeans)
})

# ---- dirs
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
manifest_dir <- here::here("manifest")
if (!dir.exists(manifest_dir)) dir.create(manifest_dir, recursive = TRUE)
manifest_path <- file.path(manifest_dir, "manifest.csv")

# ---- helpers (pattern consistent with earlier scripts) :contentReference[oaicite:7]{index=7}
save_table_csv_html <- function(df, basename, out_dir) {
  csv_path  <- file.path(out_dir, paste0(basename, ".csv"))
  html_path <- file.path(out_dir, paste0(basename, ".html"))
  readr::write_csv(df, csv_path)

  html_table <- knitr::kable(df, format = "html",
                             table.attr = "border='1' style='border-collapse:collapse;'")
  html_content <- paste0(
    "<html><head><meta charset='UTF-8'></head><body>",
    "<h3>", basename, "</h3>",
    html_table,
    "</body></html>"
  )
  writeLines(html_content, con = html_path)

  invisible(list(csv = csv_path, html = html_path))
}

append_manifest <- function(rows_df, manifest_path) {
  if (!file.exists(manifest_path)) {
    utils::write.table(rows_df, file = manifest_path, sep = ",",
                      row.names = FALSE, col.names = TRUE, append = FALSE, qmethod = "double")
  } else {
    utils::write.table(rows_df, file = manifest_path, sep = ",",
                      row.names = FALSE, col.names = FALSE, append = TRUE, qmethod = "double")
  }
}

# ---- load data (path or object name)
dat <- NULL
if (file.exists(data_in)) {
  if (grepl("\\.rds$", data_in, ignore.case = TRUE)) {
    dat <- readRDS(data_in)
  } else if (grepl("\\.csv$", data_in, ignore.case = TRUE)) {
    dat <- readr::read_csv(data_in, show_col_types = FALSE)
  } else {
    stop("Tuntematon tiedostotyyppi: käytä .csv tai .rds")
  }
} else {
  # try treat as object name in global env (for interactive runs)
  if (exists(data_in, envir = .GlobalEnv)) {
    dat <- get(data_in, envir = .GlobalEnv)
  } else {
    stop("Dataa ei löytynyt polusta eikä oliona: ", data_in)
  }
}
if (!is.data.frame(dat)) stop("Data ei ole data.frame/tibble.")

# ---- minimal required columns
req <- c("id", "time", "Composite_Z", "FOF_status", "age", "sex", "BMI")
miss <- setdiff(req, names(dat))
if (length(miss) > 0) stop("Puuttuvat sarakkeet: ", paste(miss, collapse = ", "))

# ---- enforce factor coding (critical for interpretation)
dat <- dat %>%
  mutate(
    FOF_status = factor(FOF_status, levels = c("Ei FOF", "FOF")),  # :contentReference[oaicite:8]{index=8}
    sex = as.factor(sex),
    # time recommended as factor with baseline reference; adjust levels per data_dictionary.csv
    time = if (is.numeric(time) || is.integer(time)) {
      factor(time, levels = c(0, 1), labels = c("baseline", "m12"))
    } else {
      factor(time, levels = c("baseline", "m12"))
    }
  )

# =============================================================================
# Canonical entrypoint: analysis_mixed_workflow()
# =============================================================================

# If your repo already provides analysis_mixed_workflow(), source/load it here.
# Example:
# source(here::here("R", "analysis_mixed_workflow.R"))

if (!exists("analysis_mixed_workflow")) {
  # Minimal fallback implementation (keeps contract if function is missing)
  analysis_mixed_workflow <- function(data, out_dir, practical_threshold) {

    # Model (random intercept for id)
    fit <- lmer(Composite_Z ~ time * FOF_status + age + sex + BMI + (1 | id),
                data = data, REML = FALSE)

    # Fixed effects table (Wald CI)
    coefs <- summary(fit)$coefficients
    coefs_df <- as.data.frame(coefs) %>%
      tibble::rownames_to_column("term") %>%
      rename(estimate = Estimate, std.error = `Std. Error`, statistic = `t value`) %>%
      mutate(df = if ("df" %in% names(coefs_df)) df else NA_real_)

    # Wald CI from vcov
    V <- as.matrix(vcov(fit))
    se <- sqrt(diag(V))
    ci_low  <- fixef(fit) - 1.96 * se
    ci_high <- fixef(fit) + 1.96 * se
    ci_df <- tibble::tibble(
      term = names(fixef(fit)),
      conf.low = as.numeric(ci_low),
      conf.high = as.numeric(ci_high)
    )

    fixed_tab <- coefs_df %>%
      left_join(ci_df, by = "term") %>%
      mutate(p.value = if ("Pr(>|t|)" %in% colnames(summary(fit)$coefficients)) {
        as.numeric(summary(fit)$coefficients[, "Pr(>|t|)"])
      } else NA_real_) %>%
      select(term, estimate, std.error, df, statistic, conf.low, conf.high, p.value)

    # emmeans: time within FOF group + change baseline->m12
    emm <- emmeans(fit, ~ time | FOF_status)
    emm_df <- as.data.frame(summary(emm, infer = TRUE)) %>%
      rename(estimate = emmean, conf.low = lower.CL, conf.high = upper.CL)

    chg <- contrast(emm, method = "revpairwise")  # m12 - baseline (because time levels baseline,m12)
    chg_df <- as.data.frame(summary(chg, infer = TRUE)) %>%
      rename(estimate = estimate, conf.low = lower.CL, conf.high = upper.CL)

    # Interaction term name detection (robust to coding labels)
    find_interaction_term <- function(tab, v1 = "time", v2 = "FOF_status") {
      cand <- tab$term[grepl(":", tab$term) & grepl(v1, tab$term) & grepl(v2, tab$term)]
      if (length(cand) == 0) return(NA_character_)
      cand[1]
    }
    iterm <- find_interaction_term(fixed_tab, "time", "FOF_status")
    itab  <- fixed_tab %>% filter(term == iterm)

    # Auto-text 4-branch logic (CI + practical threshold)
    auto_text <- NA_character_
    if (!is.na(iterm) && nrow(itab) == 1) {
      est <- itab$estimate
      lo  <- itab$conf.low
      hi  <- itab$conf.high

      ci_excludes_0 <- (lo > 0 && hi > 0) || (lo < 0 && hi < 0)
      ci_width <- hi - lo
      # "narrow" heuristic: CI entirely within +/- practical_threshold
      narrow <- (min(abs(lo), abs(hi)) < practical_threshold) && (max(abs(lo), abs(hi)) < practical_threshold)

      if (ci_excludes_0 && est < 0) {
        auto_text <- sprintf(
          "Interaktio (%s) oli negatiivinen ja 95 %% LV ei sisältänyt nollaa (β = %.3f, 95 %% LV %.3f–%.3f). Tämä viittaa siihen, että FOF-ryhmän muutos baseline→12 kk poikkesi (pienempänä) Ei FOF-ryhmän muutoksesta noin %.3f SD-yksikköä (koodaus: time baseline→m12, FOF_status Ei FOF→FOF).",
          iterm, est, lo, hi, est
        )
      } else if (ci_excludes_0 && est > 0) {
        auto_text <- sprintf(
          "Interaktio (%s) oli positiivinen ja 95 %% LV ei sisältänyt nollaa (β = %.3f, 95 %% LV %.3f–%.3f). Tämä viittaa siihen, että FOF-ryhmän muutos baseline→12 kk poikkesi (suurempana) Ei FOF-ryhmän muutoksesta noin %.3f SD-yksikköä (koodaus: time baseline→m12, FOF_status Ei FOF→FOF).",
          iterm, est, lo, hi, est
        )
      } else if (!ci_excludes_0 && narrow) {
        auto_text <- sprintf(
          "Interaktio (%s) ei ollut selvästi nollasta poikkeava ja 95 %% LV oli kapea (β = %.3f, 95 %% LV %.3f–%.3f), mikä viittaa siihen, että käytännöllisesti merkittävät erot ryhmien muutoksissa (|Δ| ≥ %.2f SD) ovat epätodennäköisiä tämän aineiston perusteella.",
          iterm, est, lo, hi, practical_threshold
        )
      } else {
        auto_text <- sprintf(
          "Interaktio (%s) ei ollut selvästi nollasta poikkeava ja 95 %% LV oli laaja (β = %.3f, 95 %% LV %.3f–%.3f), joten aineisto ei sulje pois käytännöllisesti merkittäviä eroja ryhmien muutoksissa (|Δ| ≥ %.2f SD).",
          iterm, est, lo, hi, practical_threshold
        )
      }
    }

    list(
      model = fit,
      tables = list(
        fixed_effects = fixed_tab,
        emmeans_time_by_fof = emm_df,
        contrasts_change_over_time = chg_df,
        interaction_focus = itab
      ),
      interaction_term = iterm,
      auto_text = auto_text
    )
  }
}

# ---- run workflow
res <- analysis_mixed_workflow(
  data = dat,
  out_dir = out_dir,
  practical_threshold = pr_thr
)

# ---- save outputs
save_table_csv_html(res$tables$fixed_effects, "fixed_effects", out_dir)
save_table_csv_html(res$tables$interaction_focus, "interaction_focus", out_dir)
save_table_csv_html(res$tables$emmeans_time_by_fof, "emmeans_time_by_fof", out_dir)
save_table_csv_html(res$tables$contrasts_change_over_time, "contrasts_change_over_time", out_dir)

# ---- save auto-text
autotxt_path <- file.path(out_dir, "interaction_autotext.txt")
writeLines(res$auto_text %||% "", con = autotxt_path)

# ---- optional plot (emmeans-based)
if (requireNamespace("ggplot2", quietly = TRUE)) {
  library(ggplot2)
  pdat <- res$tables$emmeans_time_by_fof
  p <- ggplot(pdat, aes(x = time, y = estimate, group = FOF_status, linetype = FOF_status)) +
    geom_line() +
    geom_point() +
    geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.1) +
    labs(x = "Aika", y = "Composite_Z (EMM)", title = "Composite_Z ajan mukaan FOF-ryhmittäin (EMM ± 95% LV)")
  ggsave(filename = file.path(out_dir, "interaction_plot.png"), plot = p, width = 7, height = 5, dpi = 300)
}

# ---- save reproducibility artifacts
script_label <- "mixed_fof_time"

sess_path <- file.path(manifest_dir, paste0("sessionInfo_", script_label, ".txt"))
writeLines(capture.output(sessionInfo()), con = sess_path)

diag_path <- file.path(manifest_dir, paste0("renv_diagnostics_", script_label, ".txt"))
writeLines(capture.output(renv::diagnostics()), con = diag_path)

# ---- update manifest (pattern consistent with K14) :contentReference[oaicite:9]{index=9}
manifest_rows <- tibble::tibble(
  script      = script_label,
  type        = c("table","table","table","table","text","figure","meta","meta"),
  filename    = c(
    file.path(basename(out_dir), "fixed_effects.csv"),
    file.path(basename(out_dir), "interaction_focus.csv"),
    file.path(basename(out_dir), "emmeans_time_by_fof.csv"),
    file.path(basename(out_dir), "contrasts_change_over_time.csv"),
    file.path(basename(out_dir), "interaction_autotext.txt"),
    file.path(basename(out_dir), "interaction_plot.png"),
    file.path("manifest", basename(sess_path)),
    file.path("manifest", basename(diag_path))
  ),
  description = c(
    "Mixed model fixed effects (Composite_Z ~ time*FOF_status + covariates; (1|id)).",
    "Interaction-only extract (time:FOF_status term row).",
    "Estimated marginal means: Composite_Z by time within FOF group.",
    "Within-group change baseline->12m (emmeans contrasts).",
    "Auto-generated conservative interpretation text for the interaction.",
    "Optional interaction plot (EMM ± 95% CI).",
    "sessionInfo() for reproducibility.",
    "renv::diagnostics() for reproducibility."
  )
)
append_manifest(manifest_rows, manifest_path)

message("Done. Outputs in: ", out_dir)
message("Manifest updated: ", manifest_path)
```

---

## How to interpret results (conservative)

**Mitä tulkitaan ensisijaisesti:**

- **Interaktio `time:FOF_status`**: kuvaa **ryhmäeroa muutoksessa** baseline→12 kk (FOF vs Ei FOF), kun:

  - `FOF_status` referenssi = `Ei FOF`
  - `time` referenssi = `baseline`
  - (tämä varmistetaan ajurissa `factor(levels=...)`)

**Raportoi aina:**

- β (estimaatti), 95 % luottamusväli (LV), sekä käytännöllisen merkittävyyden
  kynnys **`<PRACTICAL_THRESHOLD>`** (esim. `0.20` SD-yksikköä; aseta
  tutkimuskohtaisesti)

**P-arvot:**

- Pidä toissijaisina (tukevat havaintoa), älä rakenna johtopäätöstä pelkän p-arvon varaan.

**4-haarainen auto-teksti (sama logiikka kuin ajurissa):**

- Aseta `<PRACTICAL_THRESHOLD>` (esim. `0.20`) ja käytä interaktiotermin riviä sellaisenaan (term-name *täsmälleen* taulukosta).

1. **Merkittävä negatiivinen (LV ei sisällä 0, β < 0)**

> "Interaktio (**{term}**) oli negatiivinen ja 95 % LV ei sisältänyt nollaa
> (β = {β}, 95 % LV {lo}–{hi}). Tämä viittaa siihen, että FOF-ryhmän muutos
> baseline→12 kk oli pienempi kuin Ei FOF-ryhmän muutos noin {β} SD-yksikköä
> (koodaus: time baseline→m12, FOF_status Ei FOF→FOF)."

1. **Merkittävä positiivinen (LV ei sisällä 0, β > 0)**

> "Interaktio (**{term}**) oli positiivinen ja 95 % LV ei sisältänyt nollaa
> (β = {β}, 95 % LV {lo}–{hi}). Tämä viittaa siihen, että FOF-ryhmän muutos
> baseline→12 kk oli suurempi kuin Ei FOF-ryhmän muutos noin {β} SD-yksikköä
> (koodaus: time baseline→m12, FOF_status Ei FOF→FOF)."

1. **Ei-merkitsevä, kapea LV (LV sisältää 0 ja kapea suhteessa kynnysarvoon)**

> "Interaktio (**{term}**) ei ollut selvästi nollasta poikkeava ja 95 % LV
> oli kapea (β = {β}, 95 % LV {lo}–{hi}), mikä viittaa siihen, että
> käytännöllisesti merkittävät erot ryhmien muutoksissa (|Δ| ≥ {thr} SD)
> ovat epätodennäköisiä tämän aineiston perusteella."

1. **Ei-merkitsevä, laaja LV (LV sisältää 0 ja laaja)**

> "Interaktio (**{term}**) ei ollut selvästi nollasta poikkeava ja 95 % LV
> oli laaja (β = {β}, 95 % LV {lo}–{hi}), joten aineisto ei sulje pois
> käytännöllisesti merkittäviä eroja ryhmien muutoksissa (|Δ| ≥ {thr} SD)."

**Tulkinnan varovaisuus / rajoitteet (mainitse raportissa):**

- Havainnoiva asetelma → ei kausaalipäätelmiä (assosiaatio ≠ kausaliteetti).
- FOF on usein yksittäiseen kysymykseen perustuva luokittelu (esim. `kaatumisenpelkoOn` → `FOF_status`)
- Seurantapuuttuvuus/attritio voi vinouttaa ryhmävertailuja; dokumentoi puuttuvat aikapisteet.

---

## Troubleshooting

**1) `analysis_mixed_workflow` not found**

- Varmista että funktio on ladattu (`source(...)`) tai että paketti/skripti on
  mukana. Ajuri sisältää minimifallbackin, mutta repossa kannattaa pitää yksi
  "authoritative" toteutus.

### 2) renv restore epäonnistuu

```r
renv::diagnostics()
renv::restore(prompt = FALSE)
```

- Tarkista R-version yhteensopivuus `renv.lock` kanssa.

### 3) lmer-konvergenssi / singular fit

- Tarkista data: liian vähän havaintoja joissakin time×FOF-soluissa.
- Kokeile:

  - skaalaa jatkuvat kovariaatit (age, BMI) ja/tai
  - raportoi singular fit varoituksena ja tee herkkyysanalyysi (esim.
    yksinkertaisempi kovariaattijoukko).

### 4) emmeans varoitukset (non-estimable / empty cells)

- Tarkista että `FOF_status`- ja `time`-tasoyhdistelmät ovat aidosti havaittuja.
- Varmista `time` faktoriksi ja tasojärjestys `baseline`, `m12`.

### 5) "term-nimi ei täsmää" (tulostus vs teksti)

- Älä hardcodea `time:FOF_status`-rivin nimeä; käytä ajurin `find_interaction_term(...)`-logiikkaa.

---

## Internal consistency check

- Interaktiotermin **rivinimi** riippuu faktoritasojen nimistä (esim.
  `timem12:FOF_statusFOF`), joten **poimi termi aina taulukosta** (ajurin
  `find_interaction_term()`), älä kirjoita sitä käsin.
- Tulkinta "FOF-ryhmän muutos vs Ei FOF-ryhmän muutos" edellyttää, että
  referenssitasot ovat `time = baseline` ja `FOF_status = Ei FOF` (ajurissa
  `factor(levels=...)`).
