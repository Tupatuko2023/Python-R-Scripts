# K12: Onko FOF:lla voimakkaampi yhteys tiettyjen alakomposiittien (esim.
# kävelynopeus, tasapaino) muutokseen kuin koko komposiittiin?

# ==============================================================================

# ---------------------------------------------------------------
# 0. PACKAGES ---------------------------------------------------
# ---------------------------------------------------------------

library(dplyr)
library(tidyr)
library(ggplot2)
library(forcats)
library(broom)
library(car)       
library(emmeans)   
library(effectsize)
library(mice)
library(knitr)
library(MASS)
library(scales)
library(nlme)
library(quantreg)
library(tibble)

set.seed(20251124)  # jos myöhemmin käytetään satunnaisuutta (esim. bootstrap)

# ==============================================================================
# ---------------------------------------------------------------
# 1: Load the dataset -------------------------------------------
# ---------------------------------------------------------------

file_path <- here::here("data", "external", "KaatumisenPelko.csv")

raw_data <- readr::read_csv(file_path, show_col_types = FALSE)

## Working copy so the original stays untouched
if (!exists("raw_data")) {
  stop("Object 'raw_data' not found. Please load your data as raw_data first.")
}

## Tee raaka- ja työkopio
analysis_data  <- raw_data
glimpse(analysis_data)
names(analysis_data)

# ---------------------------------------------------------------
# 2: Output-kansio K12:n alle ------------------------------------
# ---------------------------------------------------------------

## .../Fear-of-Falling/R-scripts/K12/outputs
outputs_dir <- here::here("R-scripts", "K12", "outputs")
if (!dir.exists(outputs_dir)) {
  dir.create(outputs_dir, recursive = TRUE)
}

## 2.1: --- Skriptin tunniste ---
script_label <- "K12"   

## 2.2: --- Erillinen manifest-kansio projektissa: ./manifest ------------------
# Projektin juurikansio oletetaan olevan .../Fear-of-Falling
manifest_dir <- here::here("manifest")
if (!dir.exists(manifest_dir)) {
  dir.create(manifest_dir, recursive = TRUE)
}
manifest_path <- file.path(manifest_dir, "manifest.csv")

# 2.3: --- Helper to save CSV + simple HTML table ------------------------------

save_table_csv_html <- function(df, basename,
                                out_dir = outputs_dir) {
  
  # Varmista, että kansio on olemassa
  if (!dir.exists(out_dir)) {
    dir.create(out_dir, recursive = TRUE)
  }
  
  csv_path  <- file.path(out_dir, paste0(basename, ".csv"))
  html_path <- file.path(out_dir, paste0(basename, ".html"))
  
  # CSV
  readr::write_csv(df, csv_path)
  
  # HTML-taulukko
  html_table <- knitr::kable(
    df, format = "html",
    table.attr = "border='1' style='border-collapse:collapse;'"
  )
  
  html_content <- paste0(
    "<html><head><meta charset='UTF-8'></head><body>",
    "<h3>", basename, "</h3>",
    html_table,
    "</body></html>"
  )
  
  writeLines(html_content, con = html_path)
  
  invisible(list(csv = csv_path, html = html_path))
}

# ---------------------------------------------------------------
# 3. DATA CHECKING ----------------------------------------------
# ---------------------------------------------------------------

# 3.1: Varmista että analysis_data on olemassa
if (!exists("analysis_data")) {
  stop("Objektia 'analysis_data' ei löytynyt. Lataa data ennen skriptin ajamista.")
}

# 3.2: Yleiskuva
names(analysis_data)
str(analysis_data)

# 3.3: Tarkennettu rakennekatsaus keskeisille muuttujille (muokkaa tarvittaessa)
analysis_data %>% 
  dplyr::select(
    age, sex, BMI, MOIindeksiindeksi, diabetes,
    kaatumisenpelkoOn,
    alzheimer, parkinson, AVH,
    ToimintaKykySummary0, ToimintaKykySummary2,
    dplyr::starts_with("Puristus"),
    dplyr::starts_with("kavely"),
    dplyr::starts_with("Tuoli"),
    dplyr::starts_with("Seisominen"),
    SRH = dplyr::any_of("SRH"),
    koettuterveydentila = dplyr::any_of("koettuterveydentila"),
    oma_arvio_liikuntakyky = dplyr::any_of("oma_arvio_liikuntakyky"),
    PainVAS0 = dplyr::any_of("PainVAS0")
  ) %>% 
  glimpse()

# ---------------------------------------------------------------
# 4. RECODINGS --------------------------------------------------
# ---------------------------------------------------------------


analysis_data_rec <- analysis_data %>%
  mutate(
    # FOF-status
    FOF_status = factor(
      kaatumisenpelkoOn,
      levels = c(0, 1),
      labels = c("nonFOF", "FOF")
    ),
    
    # Ikäluokat
    AgeClass = case_when(
      age < 65                 ~ "65_74",
      age >= 65 & age <= 74    ~ "65_74",
      age >= 75 & age <= 84    ~ "75_84",
      age >= 85                ~ "85plus",
      TRUE                     ~ NA_character_
    ),
    AgeClass = factor(AgeClass, levels = c("65_74", "75_84", "85plus"), ordered = TRUE),
    
    # Neuro
    Neuro_any_num = if_else(
      (alzheimer == 1 | parkinson == 1 | AVH == 1),
      1L, 0L,
      missing = 0L
    ),
    # AVH = aivoverenkiertohäiriö
    AVH_factor = factor(
      AVH,
      levels = c(0, 1),
      labels = c("nonAVH", "AVH")
    ),  
    Neuro_any = factor(
      Neuro_any_num,
      levels = c(0, 1),
      labels = c("no_neuro", "neuro")
    ),
    
    # Sukupuoli: 0 = female, 1 = male
    sex_factor = factor(
      sex,
      levels = c(0, 1),
      labels = c("female", "male")
    )
  )

# ---------------------------------------------------------------
# 5.Outcome-muuttujat: DeltaComposite ja Delta-PBT:t-------------
# ---------------------------------------------------------------

# 5.1 Composite-muutos

# Tarkistetaan ensin, mitä sarakkeita on
has_DeltaComposite    <- "DeltaComposite" %in% names(analysis_data_rec)
has_DeltaComposite_Z  <- "Delta_Composite_Z" %in% names(analysis_data_rec)

if (has_DeltaComposite) {
  # Käytä valmista saraketta sellaisenaan
  message("Using existing DeltaComposite column.")
  
} else if (has_DeltaComposite_Z) {
  # Luo DeltaComposite tästä
  analysis_data_rec <- analysis_data_rec %>%
    mutate(DeltaComposite = Delta_Composite_Z)
  message("Created DeltaComposite from Delta_Composite_Z.")
  
} else {
  # Laske muutos suoraan
  analysis_data_rec <- analysis_data_rec %>%
    mutate(DeltaComposite = ToimintaKykySummary2 - ToimintaKykySummary0)
  message("Created DeltaComposite as ToimintaKykySummary2 - ToimintaKykySummary0.")
}

# 5.2 PBT-muutokset (HGS, MWS, FTSST, SLS)

analysis_data_rec <- analysis_data_rec %>%
  mutate(
    # HGS: positiivinen = parannus
    Delta_HGS = case_when(
      "PuristusMuutos" %in% names(analysis_data_rec) ~ PuristusMuutos,
      "Puristus0" %in% names(analysis_data_rec) & "Puristus2" %in% names(analysis_data_rec) ~ 
        Puristus2 - Puristus0,
      TRUE ~ NA_real_
    ),
    
    # MWS: positiivinen = parannus
    Delta_MWS = case_when(
      "Kävelymuutos" %in% names(analysis_data_rec) ~ Kävelymuutos,
      "kavelynopeus_m_sek0" %in% names(analysis_data_rec) & "kavelynopeus_m_sek2" %in% names(analysis_data_rec) ~
        kavelynopeus_m_sek2 - kavelynopeus_m_sek0,
      TRUE ~ NA_real_
    ),
    
    # FTSST (Tuoli): pienempi aika = parempi -> muutoksen merkki käännetään
    Delta_FTSST = case_when(
      "Tuolimuutos" %in% names(analysis_data_rec) ~ Tuolimuutos * (-1),
      "Tuoli0" %in% names(analysis_data_rec) & "Tuoli2" %in% names(analysis_data_rec) ~
        (Tuoli0 - Tuoli2),  # positiivinen = nopeampi testi
      TRUE ~ NA_real_
    ),
    
    # SLS (Seisominen): suurempi aika = parempi
    Delta_SLS = case_when(
      "TasapainoMuutos" %in% names(analysis_data_rec) ~ TasapainoMuutos,
      "Seisominen0" %in% names(analysis_data_rec) & "Seisominen2" %in% names(analysis_data_rec) ~
        Seisominen2 - Seisominen0,
      TRUE ~ NA_real_
    )
  )

# 5.3: Alias-sarakkeet analyysia varten --------------------------

analysis_data_rec <- analysis_data_rec %>%
  mutate(
    # Baseline-komposiitti
    Composite_Z0      = ToimintaKykySummary0,
    # Muutoskomposiitti; aiemmin loit jo DeltaComposite:n
    Delta_Composite_Z = DeltaComposite,
    # Sukupuoli faktoriksi
    sex = factor(
      sex,
      levels = c(0, 1),
      labels = c("female", "male")
    ),
    # MOI = Mikkelin osteoporoosi-indeksi (osteoporoosiriskin mittari)
    MOI_score = MOIindeksiindeksi
  )

# ---------------------------------------------------------------
# 6. ANALYYSIDATAT PER OUTCOME (COMPLETE CASE)-------------------
# ---------------------------------------------------------------

## 6.1: Helper: rakentaa analyysidatan annetulle outcome + baseline-parille

# ---------------------------------------------------------------
# 6. ANALYYSIDATAT PER OUTCOME (COMPLETE CASE)-------------------
# ---------------------------------------------------------------

## 6.1: Helper: rakentaa analyysidatan annetulle outcome + baseline-parille

build_dat_outcome <- function(data,
                              outcome,
                              baseline_var) {
  data %>%
    dplyr::select(
      id,
      dplyr::all_of(c(outcome, baseline_var)),
      age,
      BMI,
      sex,
      FOF_status,
      MOI_score,
      diabetes,
      alzheimer,
      parkinson,
      AVH,
      previous_falls = kaatuminen,
      psych_score    = mieliala
    ) %>%
    # complete-case: outcome + baseline + keskeiset kovariaatit
    dplyr::filter(
      !is.na(.data[[outcome]]),
      !is.na(.data[[baseline_var]]),
      !is.na(age),
      !is.na(BMI),
      !is.na(sex),
      !is.na(FOF_status)
    ) %>%
    dplyr::mutate(
      FOF_status = stats::relevel(FOF_status, ref = "nonFOF")
    )
}

## 6.2: Komposiitti + alakomponentit -----------------------------

# Komposiitti
dat_comp <- build_dat_outcome(
  analysis_data_rec,
  outcome      = "Delta_Composite_Z",
  baseline_var = "Composite_Z0"
)

# HGS (puristusvoima)
dat_hgs <- build_dat_outcome(
  analysis_data_rec,
  outcome      = "Delta_HGS",
  baseline_var = "Puristus0"
)

# MWS (maksimi kävelynopeus)
dat_mws <- build_dat_outcome(
  analysis_data_rec,
  outcome      = "Delta_MWS",
  baseline_var = "kavelynopeus_m_sek0"
)

# FTSST (tuolista ylösnousu; positiivinen = nopeampi)
dat_fts <- build_dat_outcome(
  analysis_data_rec,
  outcome      = "Delta_FTSST",
  baseline_var = "Tuoli0"
)

# SLS (yhdellä jalalla seisominen)
dat_sls <- build_dat_outcome(
  analysis_data_rec,
  outcome      = "Delta_SLS",
  baseline_var = "Seisominen0"
)

# Lyhyt tarkistus, että kaikki datat näyttävät järkeviltä
purrr::map(
  list(
    Composite = dat_comp,
    HGS       = dat_hgs,
    MWS       = dat_mws,
    FTSST     = dat_fts,
    SLS       = dat_sls
  ),
  ~ summary(.x[[2]])  # 2. sarake = outcome
)

# ---------------------------------------------------------------
# 7. PERUS- JA LAAJENNETUT MALLIT PER OUTCOME -------------------
# ---------------------------------------------------------------

# Helper: Sovittaa perus- ja laajennetut mallit annetulle outcome-muuttujalle
fit_models_for_outcome <- function(dat,
                                   outcome,
                                   baseline_var,
                                   outcome_label) {
  
  # Base-malli: FOF + baseline + age + BMI + sex
  form_base <- stats::as.formula(
    paste0(
      outcome,
      " ~ FOF_status + ",
      baseline_var,
      " + age + BMI + sex"
    )
  )
  
  # Extended-malli: lisätään kliiniset kovariaatit (kuten K11)
  form_ext <- stats::as.formula(
    paste0(
      outcome,
      " ~ FOF_status + ",
      baseline_var,
      " + age + BMI + sex",
      " + MOI_score + diabetes + alzheimer + parkinson + AVH",
      " + previous_falls + psych_score"
    )
  )
  
  mod_base <- stats::lm(form_base, data = dat)
  mod_ext  <- stats::lm(form_ext,  data = dat)
  
  # tidy-taulukot + tunnisteet
  tab_base <- broom::tidy(mod_base, conf.int = TRUE) %>%
    dplyr::mutate(
      model   = "base",
      outcome = outcome_label
    )
  
  tab_ext <- broom::tidy(mod_ext, conf.int = TRUE) %>%
    dplyr::mutate(
      model   = "extended",
      outcome = outcome_label
    )
  
  # FOF-rivit
  fof_base <- tab_base %>%
    dplyr::filter(grepl("^FOF_status", term)) %>%
    dplyr::mutate(
      model   = "base",
      outcome = outcome_label
    )
  
  fof_ext <- tab_ext %>%
    dplyr::filter(grepl("^FOF_status", term)) %>%
    dplyr::mutate(
      model   = "extended",
      outcome = outcome_label
    )
  
  # Standardoidut kertoimet extended-mallille (vain FOF-rivi)
  # Käytetään method = "posthoc", joka EI refittaa mallia
  tab_std_ext <- tryCatch(
    {
      effectsize::standardize_parameters(
        mod_ext,
        method = "posthoc"  # ei refittiä -> vältetään aiempi virhe
      ) %>%
        as.data.frame() %>%
        # Filtteröidään FOF-status -parametri
        dplyr::filter(grepl("^FOF_status", .data$Parameter)) %>%
        dplyr::mutate(
          model   = "extended",
          outcome = outcome_label
        )
    },
    error = function(e) {
      message("Standardized parameters failed for outcome = ", outcome_label,
              ". Returning NA row for std_ext_fof.")
      tibble::tibble(
        Parameter       = "FOF_statusFOF",
        Std_Coefficient = NA_real_,
        CI_low          = NA_real_,
        CI_high         = NA_real_,
        model           = "extended",
        outcome         = outcome_label
      )
    }
  )
  
  list(
    mod_base    = mod_base,
    mod_ext     = mod_ext,
    tidy_base   = tab_base,
    tidy_ext    = tab_ext,
    fof_base    = fof_base,
    fof_ext     = fof_ext,
    std_ext_fof = tab_std_ext
  )
}


# Sovitetaan mallit kaikille outcomeille ------------------------

res_comp <- fit_models_for_outcome(
  dat_comp,
  outcome       = "Delta_Composite_Z",
  baseline_var  = "Composite_Z0",
  outcome_label = "Composite"
)

res_hgs <- fit_models_for_outcome(
  dat_hgs,
  outcome       = "Delta_HGS",
  baseline_var  = "Puristus0",
  outcome_label = "HGS"
)

res_mws <- fit_models_for_outcome(
  dat_mws,
  outcome       = "Delta_MWS",
  baseline_var  = "kavelynopeus_m_sek0",
  outcome_label = "MWS"
)

res_fts <- fit_models_for_outcome(
  dat_fts,
  outcome       = "Delta_FTSST",
  baseline_var  = "Tuoli0",
  outcome_label = "FTSST"
)

res_sls <- fit_models_for_outcome(
  dat_sls,
  outcome       = "Delta_SLS",
  baseline_var  = "Seisominen0",
  outcome_label = "SLS"
)

# ---------------------------------------------------------------
# 8. TIDY-TAULUKOT JA FOF-KOOSTE -------------------------------
# ---------------------------------------------------------------

# Kaikki mallikertoimet samassa taulukossa
lm_all_outcomes <- dplyr::bind_rows(
  res_comp$tidy_base, res_comp$tidy_ext,
  res_hgs$tidy_base,  res_hgs$tidy_ext,
  res_mws$tidy_base,  res_mws$tidy_ext,
  res_fts$tidy_base,  res_fts$tidy_ext,
  res_sls$tidy_base,  res_sls$tidy_ext
)

save_table_csv_html(lm_all_outcomes, "lm_models_all_outcomes")

# FOF_status-rivien kooste
fof_effects <- dplyr::bind_rows(
  res_comp$fof_base, res_comp$fof_ext,
  res_hgs$fof_base,  res_hgs$fof_ext,
  res_mws$fof_base,  res_mws$fof_ext,
  res_fts$fof_base,  res_fts$fof_ext,
  res_sls$fof_base,  res_sls$fof_ext
) %>%
  dplyr::select(
    outcome,
    model,
    term,
    estimate,
    std.error,
    statistic,
    p.value,
    conf.low,
    conf.high
  ) %>%
  dplyr::mutate(
    outcome = factor(
      outcome,
      levels = c("Composite", "HGS", "MWS", "FTSST", "SLS")
    ),
    model = factor(model, levels = c("base", "extended"))
  ) %>%
  dplyr::arrange(outcome, model)

save_table_csv_html(fof_effects, "FOF_effects_by_outcome")

# Standardoidut FOF-kertoimet (extended-mallit)
fof_std_extended <- dplyr::bind_rows(
  res_comp$std_ext_fof,
  res_hgs$std_ext_fof,
  res_mws$std_ext_fof,
  res_fts$std_ext_fof,
  res_sls$std_ext_fof
)

save_table_csv_html(fof_std_extended, "FOF_effects_standardized_extended")

# ---------------------------------------------------------------
# 9. KUVA: FOF-EFEKTIN METSÄKUVA OUTCOMIEN YLI -----------------
# ---------------------------------------------------------------

fof_plot_data <- fof_effects %>%
  dplyr::mutate(
    outcome = forcats::fct_rev(outcome)  # piirteen järjestys y-akselilla
  )

p_fof <- ggplot(fof_plot_data,
                aes(x = estimate,
                    y = outcome,
                    xmin = conf.low,
                    xmax = conf.high,
                    color = model)) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  geom_pointrange(position = position_dodge(width = 0.5)) +
  scale_x_continuous(name = "FOF_status (FOF vs nonFOF), kerroin (muutosyksikköä)") +
  ylab("Outcome") +
  theme_minimal()

plot_path <- file.path(outputs_dir, "FOF_effects_by_outcome_forest.png")
ggplot2::ggsave(filename = plot_path, plot = p_fof,
                width = 7, height = 4, dpi = 300)

# ---------------------------------------------------------------
# 10. MANIFEST: K12:N TAULUKOT JA KUVA --------------------------
# ---------------------------------------------------------------

manifest_rows <- tibble::tibble(
  script   = script_label,
  type     = c(
    # taulukot
    rep("table", 3),
    # kuva
    "plot"
  ),
  filename = c(
    # --- TABLES (CSV) ---
    file.path(script_label, "lm_models_all_outcomes.csv"),
    file.path(script_label, "FOF_effects_by_outcome.csv"),
    file.path(script_label, "FOF_effects_standardized_extended.csv"),
    # --- PLOTS ---
    file.path(script_label, "FOF_effects_by_outcome_forest.png")
  ),
  description = c(
    "Lineaariset perus- ja laajennetut mallit kaikille outcomeille (Composite, HGS, MWS, FTSST, SLS).",
    "FOF-statusin kertoimet (estimate, 95 % LV, p-arvo) per outcome ja malli (base/extended).",
    "FOF-statusin standardoidut kertoimet (extended-mallit) per outcome.",
    "FOF-statusin vaikutus (pistediagrammi, estimate + 95 % LV) eri outcome-muuttujille (base ja extended mallit)."
  )
)

# Kirjoitetaan / päivitetään projektin yhteinen manifest.csv
if (!file.exists(manifest_path)) {
  # Luodaan uusi manifest otsikkoriveineen
  readr::write_csv(manifest_rows, manifest_path)
} else {
  # Lisätään rivit olemassa olevan manifestin jatkoksi
  readr::write_csv(
    manifest_rows,
    manifest_path,
    append   = TRUE,
    col_names = FALSE
  )
}

# End of K12.R