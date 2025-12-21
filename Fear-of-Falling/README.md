# FOF × aika (baseline → 12 kk) — mixed model -ajamisohje (Composite_Z)

Tämä README on ajamisohje ("runbook") FOF-alatutkimuksen päätarkastelulle:
**FOF_status × time** -interaktio fyysisen toimintakyvyn muutoksessa
(**Composite_Z**) käyttäen **lineaarista sekamallia** (lmer; satunnaisintersepti
henkilölle: **(1 | id)**). Ajot tuottavat raportointivalmiit taulukot +
(valinnaisen) interaktiokuvan, tallentavat artefaktit `outputs/`-hakemistoon
ja kirjaavat ne `manifest/manifest.csv`-tiedostoon.

---

## Prerequisites

**Tarvitset:**

* Git
* R (käytä projektin `renv.lock`-tiedoston kanssa yhteensopivaa R-versiota)
* renv (asennetaan tarvittaessa ajon yhteydessä)

**Oletettu reposisrakenne (minimi):**

* `renv.lock`
* `manifest/` (luodaan jos puuttuu)
* `outputs/` (luodaan jos puuttuu)
* (suositus) `R/` tai `R-scripts/` jossa ajoskripti ja/tai `analysis_mixed_workflow()`-funktio

**Data-politiikka (ei raw-dataa KB:hen):**

* Älä kopioi tai “upload”-ohjeista osallistujatason raakadataa tietopankkiin.
* Käytä aina **polkuja** (esim. `data/external/...`) tai valmiita R-olioita paikallisesti.

---

## Quickstart

> Korvaa placeholderit: `<REPO_PATH>`, `<DATA_PATH_OR_OBJECT>`, `<OUTPUT_DIR>`

```bash
# 1) kloonaa ja siirry repojuureen
git clone <REPO_URL> <REPO_PATH>
cd <REPO_PATH>

# 2) valitse haara/commit (tarvittaessa)
git checkout <BRANCH_OR_COMMIT>

# 3) renv restore (asentaa lukitut paketit)
R -q -e 'if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv"); renv::restore(prompt = FALSE)'

# 4) aja analyysi (esimerkkiajuri; luo tarvittaessa skripti kohdasta "R-ajuri")
Rscript R-scripts/run_mixed_fof_time.R --data "<DATA_PATH_OR_OBJECT>" --out "<OUTPUT_DIR>"

# 5) tarkista että artefaktit syntyivät ja manifest päivittyi
ls -la "<OUTPUT_DIR>"
ls -la manifest/manifest.csv
```

---

## What gets run

**Kanoninen sisääntulopiste:** `analysis_mixed_workflow()`.

**Malli (kiinteät + satunnaiset):**

* Kiinteät: `Composite_Z ~ time * FOF_status + age + sex + BMI (+ optional covariates)`
* Satunnaiset: `(1 | id)`
* Päätulos: **interaktiotermi `time:FOF_status`** (FOF-ryhmän muutos vs nonFOF-ryhmän muutos baseline→12 kk)

**FOF_status-koodaus (suositus):**

* `FOF_status = factor(..., levels = c("nonFOF","FOF"))`

**Manifest + outputs -käytäntö (linjassa aiempien skriptien kanssa):**

* `outputs_dir` skriptikohtaisesti tai analyysikohtaisesti
* `manifest/manifest.csv` appendoidaan (script/type/filename/description)
* Siemen: `set.seed(20251124)` ennen satunnaisia vaiheita

---

## Inputs and expected data shape

**Suositus:** long-muotoinen data (1 rivi per henkilö per aikapiste).

**Pakolliset sarakkeet:**

* `id` : yksilö-ID (integer/character)
* `time` : aikamuuttuja (katso koodaus alla)
* `Composite_Z` : lopputulos (numeric)
* `FOF_status` : ryhmä (factor: `nonFOF`, `FOF`)
* kovariaatit: `age` (numeric), `sex` (factor), `BMI` (numeric)

**Ajan koodaus (valitse yksi ja dokumentoi):**

1. **Binäärinen 0/1 + faktoriksi** (suositus emmeans-vertailuille):

* baseline = 0 → `"baseline"`
* 12 kk = 1 → `"m12"`

1. Faktoritasot suoraan:

* `factor(time, levels = c("baseline","m12"))`

**Minimitarkistus (ennen mallia):**

* Molemmissa ryhmissä (FOF/nonFOF) havaintoja molemmilla aikapisteillä
* Ei “tyhjiä” faktoritason kombinaatioita (emmeans antaa helposti varoituksia)

---

## Reproducibility rules

**Pakolliset säännöt:**

1. **renv**

```r
renv::restore(prompt = FALSE)
# Jos lisäät/korjaat paketteja, tee lopuksi:
renv::snapshot(prompt = FALSE)
```

1. **Seed**

* Aja aina ennen satunnaisuutta:

```r
set.seed(20251124)
```

(esim. imputointi, bootstrap, resampling)

1. **Manifestiin tekninen toistettavuus**

* Tallenna aina (joka ajolla) tiedostoihin `manifest/`:

  * `sessionInfo_<script_label>.txt`
  * `renv_diagnostics_<script_label>.txt`

1. **Ei raw-datan siirtoa**

* Kirjaa manifestiin vain polut + artefaktien nimet, ei osallistujatason dataa.

---

## Outputs

**Oletus:** kaikki artefaktit menevät hakemistoon:

* `<OUTPUT_DIR>` (esim. `outputs/mixed_fof_time/`)

**Suositellut tiedostonimet (raportointivalmiit):**

* `fixed_effects.csv` + `fixed_effects.html`
  (estimate, SE, df (jos saatavilla), t, 95% CI, p)
* `interaction_focus.csv` + `interaction_focus.html`
  (vain interaktio + tulkintaa varten tarvittavat sarakkeet)
* `emmeans_time_by_fof.csv` + `emmeans_time_by_fof.html`
  (EMM:t: Composite_Z ajan mukaan, erikseen FOF-ryhmittäin)
* `contrasts_change_over_time.csv` + `contrasts_change_over_time.html`
  (muutos baseline→12 kk per ryhmä)
* `interaction_plot.png` (valinnainen)

**Manifest-kirjaus:**

* `manifest/manifest.csv` saa rivit (script, type, filename, description)

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

# ---- reproducibility (seed before stochastic steps)
set.seed(20251124)

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
    FOF_status = factor(FOF_status, levels = c("nonFOF", "FOF")),  # :contentReference[oaicite:8]{index=8}
    sex = as.factor(sex),
    # time recommended as factor with baseline reference
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
          "Interaktio (%s) oli negatiivinen ja 95 %% LV ei sisältänyt nollaa (β = %.3f, 95 %% LV %.3f–%.3f). Tämä viittaa siihen, että FOF-ryhmän muutos baseline→12 kk poikkesi (pienempänä) nonFOF-ryhmän muutoksesta noin %.3f SD-yksikköä (koodaus: time baseline→m12, FOF_status nonFOF→FOF).",
          iterm, est, lo, hi, est
        )
      } else if (ci_excludes_0 && est > 0) {
        auto_text <- sprintf(
          "Interaktio (%s) oli positiivinen ja 95 %% LV ei sisältänyt nollaa (β = %.3f, 95 %% LV %.3f–%.3f). Tämä viittaa siihen, että FOF-ryhmän muutos baseline→12 kk poikkesi (suurempana) nonFOF-ryhmän muutoksesta noin %.3f SD-yksikköä (koodaus: time baseline→m12, FOF_status nonFOF→FOF).",
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

* **Interaktio `time:FOF_status`**: kuvaa **ryhmäeroa muutoksessa** baseline→12 kk (FOF vs nonFOF), kun:

  * `FOF_status` referenssi = `nonFOF`
  * `time` referenssi = `baseline`
  * (tämä varmistetaan ajurissa `factor(levels=...)`)

**Raportoi aina:**

* β (estimaatti), 95 % luottamusväli (LV), sekä käytännöllisen merkittävyyden
  kynnys **`<PRACTICAL_THRESHOLD>`** (esim. `0.20` SD-yksikköä; aseta
  tutkimuskohtaisesti)

**P-arvot:**

* Pidä toissijaisina (tukevat havaintoa), älä rakenna johtopäätöstä pelkän p-arvon varaan.

**4-haarainen auto-teksti (sama logiikka kuin ajurissa):**

* Aseta `<PRACTICAL_THRESHOLD>` (esim. `0.20`) ja käytä interaktiotermin riviä sellaisenaan (term-name *täsmälleen* taulukosta).

1. **Merkittävä negatiivinen (LV ei sisällä 0, β < 0)**

> "Interaktio (**{term}**) oli negatiivinen ja 95 % LV ei sisältänyt nollaa
> (β = {β}, 95 % LV {lo}–{hi}). Tämä viittaa siihen, että FOF-ryhmän muutos
> baseline→12 kk oli pienempi kuin nonFOF-ryhmän muutos noin {β} SD-yksikköä
> (koodaus: time baseline→m12, FOF_status nonFOF→FOF)."

1. **Merkittävä positiivinen (LV ei sisällä 0, β > 0)**

> "Interaktio (**{term}**) oli positiivinen ja 95 % LV ei sisältänyt nollaa
> (β = {β}, 95 % LV {lo}–{hi}). Tämä viittaa siihen, että FOF-ryhmän muutos
> baseline→12 kk oli suurempi kuin nonFOF-ryhmän muutos noin {β} SD-yksikköä
> (koodaus: time baseline→m12, FOF_status nonFOF→FOF)."

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

* Havainnoiva asetelma → ei kausaalipäätelmiä (assosiaatio ≠ kausaliteetti).
* FOF on usein yksittäiseen kysymykseen perustuva luokittelu (esim. `kaatumisenpelkoOn` → `FOF_status`)
* Seurantapuuttuvuus/attritio voi vinouttaa ryhmävertailuja; dokumentoi puuttuvat aikapisteet.

---

## Troubleshooting

**1) `analysis_mixed_workflow` not found**

* Varmista että funktio on ladattu (`source(...)`) tai että paketti/skripti on
  mukana. Ajuri sisältää minimifallbackin, mutta repossa kannattaa pitää yksi
  "authoritative" toteutus.

### 2) renv restore epäonnistuu

```r
renv::diagnostics()
renv::restore(prompt = FALSE)
```

* Tarkista R-version yhteensopivuus `renv.lock` kanssa.

### 3) lmer-konvergenssi / singular fit

* Tarkista data: liian vähän havaintoja joissakin time×FOF-soluissa.
* Kokeile:

  * skaalaa jatkuvat kovariaatit (age, BMI) ja/tai
  * raportoi singular fit varoituksena ja tee herkkyysanalyysi (esim.
    yksinkertaisempi kovariaattijoukko).

### 4) emmeans varoitukset (non-estimable / empty cells)

* Tarkista että `FOF_status`- ja `time`-tasoyhdistelmät ovat aidosti havaittuja.
* Varmista `time` faktoriksi ja tasojärjestys `baseline`, `m12`.

### 5) "term-nimi ei täsmää" (tulostus vs teksti)

* Älä hardcodea `time:FOF_status`-rivin nimeä; käytä ajurin `find_interaction_term(...)`-logiikkaa.

---

## Internal consistency check

* Interaktiotermin **rivinimi** riippuu faktoritasojen nimistä (esim.
  `timem12:FOF_statusFOF`), joten **poimi termi aina taulukosta** (ajurin
  `find_interaction_term()`), älä kirjoita sitä käsin.
* Tulkinta "FOF-ryhmän muutos vs nonFOF-ryhmän muutos" edellyttää, että
  referenssitasot ovat `time = baseline` ja `FOF_status = nonFOF` (ajurissa
  `factor(levels=...)`).
