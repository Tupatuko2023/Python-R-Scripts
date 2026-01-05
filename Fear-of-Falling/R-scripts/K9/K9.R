#!/usr/bin/env Rscript
# ==============================================================================
# K9 - FOF and functional change in women (subgroup analysis)
# File tag: K9.R
# Purpose: Analyzes FOF-group differences in 12-month change in composite
#          physical function specifically in the female subgroup, with age and
#          BMI adjustment (Sex-stratified ANCOVA)
#
# ==============================================================================
#
# Activate renv environment if not already loaded
if (Sys.getenv("RENV_PROJECT") == "") source("renv/activate.R")

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(forcats)
  library(broom)
  library(car)
  library(emmeans)
  library(here)
})

# --- Standard init (MANDATORY) -----------------------------------------------
# NOTE: K9 does NOT use init_paths() - uses manual dir creation (legacy pattern)
# Derive script_label from --file, supporting file tags like: K9.V1_name.R
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K9"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)  # canonical SCRIPT_ID
if (is.na(script_label) || script_label == "") script_label <- "K9"

# Manual dir setup (legacy - does not use init_paths)
outputs_dir <- here::here("R-scripts", "K9", "outputs")
if (!dir.exists(outputs_dir)) {
  dir.create(outputs_dir, recursive = TRUE)
}

manifest_dir <- here::here("manifest")
if (!dir.exists(manifest_dir)) {
  dir.create(manifest_dir, recursive = TRUE)
}
manifest_path <- file.path(manifest_dir, "manifest.csv")

# seed (set for potential future bootstrap, currently no randomness in main analysis)
set.seed(20251124)

# ==============================================================================
# 01. Load Dataset & Data Checking
# ==============================================================================

file_path <- here::here("data", "external", "KaatumisenPelko.csv")
raw_data <- readr::read_csv(file_path, show_col_types = FALSE)

## Working copy so the original stays untouched
if (!exists("raw_data")) {
  stop("Object 'raw_data' not found. Please load your data as raw_data first.")
}

# --- Required raw columns check (DO NOT INVENT) ------------------------------
req_raw_cols <- c(
  "age", "sex", "BMI", "kaatumisenpelkoOn",
  "ToimintaKykySummary0", "ToimintaKykySummary2",
  "MOIindeksiindeksi", "diabetes", "alzheimer", "parkinson", "AVH"
)

missing_raw_cols <- setdiff(req_raw_cols, names(raw_data))
if (length(missing_raw_cols) > 0) {
  stop("Missing required raw columns: ", paste(missing_raw_cols, collapse = ", "))
}

analysis_data  <- raw_data
glimpse(analysis_data)
names(analysis_data)

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

# 4a. Frekvenssit ------------------------------------------------

# Pääjakaumat
analysis_data_rec %>%
  count(FOF_status)

analysis_data_rec %>%
  count(AgeClass)

analysis_data_rec %>%
  count(Neuro_any)

# Ristiintaulukot
analysis_data_rec %>%
  count(FOF_status, AgeClass) %>%
  arrange(AgeClass, FOF_status)

analysis_data_rec %>%
  count(FOF_status, AgeClass, Neuro_any) %>%
  arrange(AgeClass, FOF_status, Neuro_any)

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
    Delta_HGS = if_else(
      !is.na(Puristus0) & !is.na(Puristus2),
      Puristus2 - Puristus0,
      NA_real_
    ),

    # MWS: positiivinen = parannus
    Delta_MWS = if_else(
      !is.na(kavelynopeus_m_sek0) & !is.na(kavelynopeus_m_sek2),
      kavelynopeus_m_sek2 - kavelynopeus_m_sek0,
      NA_real_
    ),

    # FTSST (Tuoli): pienempi aika = parempi -> muutoksen merkki käännetään
    Delta_FTSST = if_else(
      !is.na(Tuoli0) & !is.na(Tuoli2),
      Tuoli0 - Tuoli2,  # positiivinen = nopeampi testi
      NA_real_
    ),

    # SLS (Seisominen): suurempi aika = parempi
    Delta_SLS = if_else(
      !is.na(Seisominen0) & !is.na(Seisominen2),
      Seisominen2 - Seisominen0,
      NA_real_
    )
  )


# ---------------------------------------------------------------
# 6.Painopiste naisiin (pääanalyysi) ja peruskuvaust-------------
# ---------------------------------------------------------------

data_women <- analysis_data_rec %>% filter(sex_factor == "female")
data_men   <- analysis_data_rec %>% filter(sex_factor == "male")

# 6.1 DESCRIPTIVES IN WOMEN -----------------------------------------------

# DeltaComposite ja Delta-PBT per FOF_status
desc_deltas_women <- data_women %>%
  summarise(
    n = n(),
    .by = FOF_status
  ) %>%
  left_join(
    data_women %>%
      group_by(FOF_status) %>%
      summarise(
        mean_DeltaComposite = mean(DeltaComposite, na.rm = TRUE),
        sd_DeltaComposite   = sd(DeltaComposite, na.rm = TRUE),
        mean_Delta_HGS      = mean(Delta_HGS, na.rm = TRUE),
        sd_Delta_HGS        = sd(Delta_HGS, na.rm = TRUE),
        mean_Delta_MWS      = mean(Delta_MWS, na.rm = TRUE),
        sd_Delta_MWS        = sd(Delta_MWS, na.rm = TRUE),
        mean_Delta_FTSST    = mean(Delta_FTSST, na.rm = TRUE),
        sd_Delta_FTSST      = sd(Delta_FTSST, na.rm = TRUE),
        mean_Delta_SLS      = mean(Delta_SLS, na.rm = TRUE),
        sd_Delta_SLS        = sd(Delta_SLS, na.rm = TRUE),
        .groups = "drop"
      ),
    by = "FOF_status"
  )

desc_deltas_women

# Baseline-taulukko: naiset, ryhmittely FOF_status ja AgeClass

baseline_by_FOF_Age_women <- data_women %>%
  group_by(FOF_status, AgeClass) %>%
  summarise(
    n           = n(),
    mean_age    = mean(age, na.rm = TRUE),
    mean_BMI    = mean(BMI, na.rm = TRUE),
    mean_MOI    = mean(MOIindeksiindeksi, na.rm = TRUE),
    prop_neuro  = mean(Neuro_any == "neuro", na.rm = TRUE),
    mean_PainVAS0 = mean(PainVAS0, na.rm = TRUE),
    # esimerkinomaisia baseline-PBT-arvoja:
    HGS0        = mean(Puristus0, na.rm = TRUE),
    MWS0        = mean(kavelynopeus_m_sek0, na.rm = TRUE),
    FTSST0      = mean(Tuoli0, na.rm = TRUE),
    SLS0        = mean(Seisominen0, na.rm = TRUE),
    .groups = "drop"
  )

baseline_by_FOF_Age_women

# ---------------------------------------------------------------
# 7. Solukokojen tarkistus ja AgeClass_final---------------------
# ---------------------------------------------------------------

# 7. CELL SIZES -------------------------------------------------

cell_counts_women <- data_women %>%
  count(FOF_status, AgeClass) %>%
  arrange(AgeClass, FOF_status)

cell_counts_women

# Esimerkkiratkaisu: yhdistä 65_74 ja 75_84 -> 65_84, pidä 85plus erikseen

data_women <- data_women %>%
  mutate(
    AgeClass_final = fct_collapse(
      AgeClass,
      "65_84"  = c("65_74", "75_84"),
      "85plus" = "85plus"
    ),
    AgeClass_final = factor(AgeClass_final, levels = c("65_84", "85plus"), ordered = TRUE)
  )

# Päivitetyt solukoot
cell_counts_women_final <- data_women %>%
  count(FOF_status, AgeClass_final) %>%
  arrange(AgeClass_final, FOF_status)

cell_counts_women_final

# data_women <- data_women %>%
#   mutate(AgeClass_final = AgeClass)

# ---------------------------------------------------------------
# 8.Primaarit ANCOVA-mallit naisilla (FOF_status × AgeClass_final)
# ---------------------------------------------------------------

# 8.1 ANALYSIS DATASET FOR WOMEN -----------------------------------------

analysis_women_composite <- data_women %>%
  dplyr::select(
    DeltaComposite,
    ToimintaKykySummary0,  # baseline composite
    FOF_status,
    AgeClass_final,
    BMI,
    MOIindeksiindeksi,
    diabetes,
    Neuro_any
  ) %>%
  drop_na()

nrow(analysis_women_composite)

# 8.2 ANCOVA-MALLI --------------------------------------------------------

# Helper to check predictors
check_predictors_validity <- function(df, preds) {
  valid <- c()
  for (p in preds) {
    if (!p %in% names(df)) {
      warning(paste("Predictor missing:", p))
      next
    }
    x <- df[[p]]
    if (all(is.na(x))) {
      warning(paste("Predictor all NA:", p))
      next
    }
    if (is.numeric(x) && var(x, na.rm = TRUE) == 0) {
      warning(paste("Predictor zero variance:", p))
      next
    }
    if ((is.factor(x) || is.character(x)) && length(unique(na.omit(x))) < 2) {
      warning(paste("Predictor <2 levels:", p))
      next
    }
    valid <- c(valid, p)
  }
  return(valid)
}

# Potential predictors (covariates only, main effects forced)
candidate_covars <- c("ToimintaKykySummary0", "BMI", "MOIindeksiindeksi", "diabetes")
valid_covars <- check_predictors_validity(analysis_women_composite, candidate_covars)

# Construct formula: Force FOF_status * AgeClass_final, add valid covariates
# This ensures the primary research question is always addressed.
f_str <- "DeltaComposite ~ FOF_status * AgeClass_final"

if (length(valid_covars) > 0) {
  f_str <- paste(f_str, "+", paste(valid_covars, collapse = " + "))
}

message("Model formula: ", f_str)
model_composite_women <- lm(as.formula(f_str), data = analysis_women_composite)

# Type III -testit (FOF_status, AgeClass_final, interaktio)
# Safely run Anova with alias checking and Type II fallback
anova_composite_women <- tryCatch({
  car::Anova(model_composite_women, type = "III")
}, error = function(e) {
  msg <- conditionMessage(e)
  warning("Anova (Type III) failed: ", msg)
  
  if (grepl("aliased|singular", msg, ignore.case = TRUE)) {
    message("Printing alias info:")
    print(alias(model_composite_women))
  }

  # Fallback 1: Try Type II Anova
  message("Attempting fallback to Type II Anova...")
  tryCatch({
    car::Anova(model_composite_women, type = "II")
  }, error = function(e2) {
    warning("Anova (Type II) also failed: ", conditionMessage(e2))
    
    # Fallback 2: create a dummy table ONLY if MOCK_MODE is enabled
    # This prevents production runs from silently masking real errors
    if (Sys.getenv("MOCK_MODE") == "true") {
      warning("Generating dummy Anova table (MOCK_MODE=true)")
      dummy_res <- as.data.frame(matrix(NA, nrow=1, ncol=4))
      colnames(dummy_res) <- c("Sum Sq", "Df", "F value", "Pr(>F)")
      rownames(dummy_res) <- "Model_Failed_Approximation"
      class(dummy_res) <- c("anova", "data.frame")
      return(dummy_res)
    } else {
      stop("Anova failed (Type III and II). Enable MOCK_MODE=true to fallback to dummy output.")
    }
  })
})

anova_composite_women

# Tidy-taulukko (beta, SE, CI, p)
tidy_composite_women <- broom::tidy(model_composite_women, conf.int = TRUE)
tidy_composite_women

# 8.3 EMMEANS JA KONTRASTIT ----------------------------------------------

emm_composite <- emmeans::emmeans(
  model_composite_women,
  ~ FOF_status | AgeClass_final
)

emm_composite  # säätöjen jälkeen arvioidut keskiarvomuutokset

# Kontrastit: nonFOF - FOF kussakin ikäluokassa
contrast_composite <- contrast(
  emm_composite,
  method = list("nonFOF - FOF" = c(1, -1)),
  by = "AgeClass_final"
)

contrast_composite_df <- broom::tidy(contrast_composite, conf.int = TRUE)
contrast_composite_df

# 8.4 PLOT ---------------------------------------------------------------

emm_composite_df <- broom::tidy(emm_composite, conf.int = TRUE)

p_composite <- ggplot(
  emm_composite_df,
  aes(
    x = AgeClass_final,
    y = estimate,
    ymin = conf.low,
    ymax = conf.high,
    color = FOF_status,
    group = FOF_status
  )
) +
  geom_point(position = position_dodge(width = 0.3)) +
  geom_errorbar(width = 0.1, position = position_dodge(width = 0.3)) +
  geom_line(position = position_dodge(width = 0.3)) +
  labs(
    x = "Age class",
    y = "Adjusted change in composite (DeltaComposite)",
    color = "FOF status",
    title = "Change in composite performance by FOF and age (women)"
  ) +
  theme_minimal()

p_composite

ggsave(
  filename = file.path(outputs_dir, "DeltaComposite_FOF_Age_women.png"),
  plot     = p_composite,
  width    = 7, height = 5, dpi = 300
)

# ---------------------------------------------------------------
# 9. Laajennus: Neuro_any kovariaattina / exploratory 3-way
# ---------------------------------------------------------------

# 9.1 ADJUSTING FOR NEURO_ANY --------------------------------------------

model_composite_women_neuro <- lm(
  DeltaComposite ~ FOF_status * AgeClass_final +
    Neuro_any +
    ToimintaKykySummary0 + BMI + MOIindeksiindeksi + diabetes,
  data = analysis_women_composite
)

car::Anova(model_composite_women_neuro, type = "III")

tidy_composite_women_neuro <- broom::tidy(model_composite_women_neuro, conf.int = TRUE)
tidy_composite_women_neuro

# 9.2 EXPLORATORY 3-WAY INTERACTION --------------------------------------

model_composite_women_3way <- lm(
  DeltaComposite ~ FOF_status * AgeClass_final * Neuro_any +
    ToimintaKykySummary0 + BMI + MOIindeksiindeksi + diabetes,
  data = analysis_women_composite
)

car::Anova(model_composite_women_3way, type = "III")

# ---------------------------------------------------------------
# 10. Miesten deskriptiiviset analyysit (kuvailevat / mahdollisesti alitehoiset)
# ---------------------------------------------------------------

# 10.1 MEN: DESCRIPTIVES -----------------------------------------------------

# Rakennetaan vastaavat Delta-arvot (ne luotiin jo analysis_data_rec:ssa)
data_men <- analysis_data_rec %>%
  filter(sex_factor != "female") %>%
  mutate(AgeClass_final = AgeClass)  # voit yhdistellä luokkia kuten naisilla

# Solukoot miehillä
cell_counts_men <- data_men %>%
  count(FOF_status, AgeClass_final) %>%
  arrange(AgeClass_final, FOF_status)

cell_counts_men

# Deskriptiiviset DeltaComposite-eroavaisuudet
desc_deltas_men <- data_men %>%
  summarise(
    n = n(),
    .by = FOF_status
  ) %>%
  left_join(
    data_men %>%
      group_by(FOF_status) %>%
      summarise(
        mean_DeltaComposite = mean(DeltaComposite, na.rm = TRUE),
        sd_DeltaComposite   = sd(DeltaComposite, na.rm = TRUE),
        .groups = "drop"
      ),
    by = "FOF_status"
  )

desc_deltas_men

# ---------------------------------------------------------------
# 11. Mallidiagnostiikka ja tulostettavat taulukot
# ---------------------------------------------------------------

# 11.1 DIAGNOSTICS ---------------------------------------------------------

par(mfrow = c(2, 2))
plot(model_composite_women)  # resid vs fitted, QQ, scale-location, Cook's

par(mfrow = c(1, 1))

# Mallin kooste
tidy_composite_women
anova_composite_women

# Emmeans-kontrastit (nonFOF - FOF ikäluokittain)
contrast_composite_df

# Solukokotaulukko
cell_counts_women_final

# ---------------------------------------------------------------
# 12. Lisäkuviot: BMI- ja MOI-indeksin efektit (naiset)
# ---------------------------------------------------------------

dat_w <- analysis_women_composite  # lyhyempi alias

# 12.1 BMI-efekti DeltaCompositeen ---------------------------------------

bmi_seq <- seq(
  from = min(dat_w$BMI, na.rm = TRUE),
  to   = max(dat_w$BMI, na.rm = TRUE),
  length.out = 100
)

newdat_bmi <- data.frame(
  FOF_status          = factor("nonFOF", levels = levels(dat_w$FOF_status)),
  AgeClass_final      = factor("65_84", levels = levels(dat_w$AgeClass_final), ordered = TRUE),
  ToimintaKykySummary0 = mean(dat_w$ToimintaKykySummary0, na.rm = TRUE),
  BMI                 = bmi_seq,
  MOIindeksiindeksi   = mean(dat_w$MOIindeksiindeksi, na.rm = TRUE),
  diabetes            = 0  # oletus: ei diabetesta (voit muuttaa 1:ksi)
)

pred_bmi <- predict(
  model_composite_women,
  newdata = newdat_bmi,
  se.fit  = TRUE
)

newdat_bmi$fit      <- pred_bmi$fit
newdat_bmi$lower_CL <- pred_bmi$fit - 1.96 * pred_bmi$se.fit
newdat_bmi$upper_CL <- pred_bmi$fit + 1.96 * pred_bmi$se.fit

p_bmi <- ggplot(
  newdat_bmi,
  aes(x = BMI, y = fit)
) +
  geom_ribbon(
    aes(ymin = lower_CL, ymax = upper_CL),
    alpha = 0.2
  ) +
  geom_line(size = 1) +
  labs(
    title = "Säädetty 12 kk muutos komposiitissa BMI:n funktiona (naiset)",
    x     = "BMI (kg/m²)",
    y     = "Säädetty keskiarvo DeltaComposite",
    caption = "FOF_status = nonFOF, ikäluokka 65–84 v, muut kovariaatit keskiarvoissa"
  ) +
  theme_minimal()

p_bmi

ggsave(
  filename = file.path(outputs_dir, "K9_BMI_effect_women.png"),
  plot     = p_bmi,
  width    = 7,
  height   = 5,
  dpi      = 300
)


# 12.2 MOI-indeksin efekti DeltaCompositeen -------------------------------

moi_seq <- seq(
  from = min(dat_w$MOIindeksiindeksi, na.rm = TRUE),
  to   = max(dat_w$MOIindeksiindeksi, na.rm = TRUE),
  length.out = 100
)

newdat_moi <- data.frame(
  FOF_status          = factor("nonFOF", levels = levels(dat_w$FOF_status)),
  AgeClass_final      = factor("65_84", levels = levels(dat_w$AgeClass_final), ordered = TRUE),
  ToimintaKykySummary0 = mean(dat_w$ToimintaKykySummary0, na.rm = TRUE),
  BMI                 = mean(dat_w$BMI, na.rm = TRUE),
  MOIindeksiindeksi   = moi_seq,
  diabetes            = 0
)

pred_moi <- predict(
  model_composite_women,
  newdata = newdat_moi,
  se.fit  = TRUE
)

newdat_moi$fit      <- pred_moi$fit
newdat_moi$lower_CL <- pred_moi$fit - 1.96 * pred_moi$se.fit
newdat_moi$upper_CL <- pred_moi$fit + 1.96 * pred_moi$se.fit

p_moi <- ggplot(
  newdat_moi,
  aes(x = MOIindeksiindeksi, y = fit)
) +
  geom_ribbon(
    aes(ymin = lower_CL, ymax = upper_CL),
    alpha = 0.2
  ) +
  geom_line(size = 1) +
  labs(
    title = "Säädetty 12 kk muutos komposiitissa MOI-indeksin funktiona (naiset)",
    x     = "MOI-indeksi (0–22 pistettä)",
    y     = "Säädetty keskiarvo DeltaComposite",
    caption = "FOF_status = nonFOF, ikäluokka 65–84 v, muut kovariaatit keskiarvoissa"
  ) +
  theme_minimal()

p_moi

ggsave(
  filename = file.path(outputs_dir, "K9_MOI_effect_women.png"),
  plot     = p_moi,
  width    = 7,
  height   = 5,
  dpi      = 300
)

# ---------------------------------------------------------------
# 13. Manifestin päivitys: K9:n keskeiset tulokset
# ---------------------------------------------------------------

# 13.1 Tallennetaan tärkeimmät taulukot outputs-kansioon --------

# Muutetaan Type III -Anova data.frame-muotoon
anova_composite_women_df <- as.data.frame(anova_composite_women)
anova_composite_women_df$term <- rownames(anova_composite_women_df)
anova_composite_women_df <- dplyr::relocate(anova_composite_women_df, term)

# Tiedostopolut taulukoille
tbl_tidy_path          <- file.path(outputs_dir, "K9_tidy_composite_women.csv")
tbl_anova_path         <- file.path(outputs_dir, "K9_anova_composite_women_typeIII.csv")
tbl_contrast_path      <- file.path(outputs_dir, "K9_contrast_composite_women.csv")
tbl_desc_women_path    <- file.path(outputs_dir, "K9_desc_deltas_women.csv")
tbl_baseline_women_path<- file.path(outputs_dir, "K9_baseline_by_FOF_Age_women.csv")
tbl_cells_women_path   <- file.path(outputs_dir, "K9_cell_counts_women_final.csv")
tbl_desc_men_path      <- file.path(outputs_dir, "K9_desc_deltas_men.csv")
tbl_cells_men_path     <- file.path(outputs_dir, "K9_cell_counts_men.csv")

# Kirjoitetaan CSV:t
readr::write_csv(tidy_composite_women,        tbl_tidy_path)
readr::write_csv(anova_composite_women_df,   tbl_anova_path)
readr::write_csv(contrast_composite_df,      tbl_contrast_path)
readr::write_csv(desc_deltas_women,          tbl_desc_women_path)
readr::write_csv(baseline_by_FOF_Age_women,  tbl_baseline_women_path)
readr::write_csv(cell_counts_women_final,    tbl_cells_women_path)
readr::write_csv(desc_deltas_men,            tbl_desc_men_path)
readr::write_csv(cell_counts_men,            tbl_cells_men_path)

# 13.2 Rivit manifestiin ----------------------------------------

# Relatiiviset polut manifestia varten (script_label/K9/ + tiedostonimi)
manifest_filenames <- c(
  file.path(script_label, basename(tbl_tidy_path)),
  file.path(script_label, basename(tbl_anova_path)),
  file.path(script_label, basename(tbl_contrast_path)),
  file.path(script_label, basename(tbl_desc_women_path)),
  file.path(script_label, basename(tbl_baseline_women_path)),
  file.path(script_label, basename(tbl_cells_women_path)),
  file.path(script_label, basename(tbl_desc_men_path)),
  file.path(script_label, basename(tbl_cells_men_path)),
  file.path(script_label, "DeltaComposite_FOF_Age_women.png"),
  file.path(script_label, "K9_BMI_effect_women.png"),
  file.path(script_label, "K9_MOI_effect_women.png")
)

manifest_types <- c(
  rep("table", 8),  # 8 taulukkoa
  rep("plot",  3)   # 3 kuvaa
)

manifest_descriptions <- c(
  "Naiset: ANCOVA-mallin regressiokertoimet (DeltaComposite, FOF_status × AgeClass_final, kovariaatit).",
  "Naiset: ANCOVA-mallin Type III -varianssianalyysi (FOF_status, AgeClass_final, interaktio ja kovariaatit).",
  "Naiset: emmeans-kontrastit (nonFOF – FOF) DeltaComposite-muutokselle ikäluokittain.",
  "Naiset: deskriptiiviset keskiarvomuutokset DeltaComposite- ja PBT-muuttujissa FOF-ryhmittäin.",
  "Naiset: lähtötilanteen taustatiedot ja PBT-arvot FOF-statuksen ja ikäluokan mukaan.",
  "Naiset: solukoot FOF_status × AgeClass_final -ristiintaulukossa.",
  "Miehet: deskriptiiviset keskiarvomuutokset DeltaComposite-muutoksesta FOF-ryhmittäin.",
  "Miehet: solukoot FOF_status × AgeClass_final -ristiintaulukossa.",
  "Naiset: DeltaComposite-muutos FOF-statuksen ja ikäluokan funktiona (emmeans, ANCOVA).",
  "Naiset: säädetty 12 kk muutos komposiitissa BMI:n funktiona (FOF_status = nonFOF, ikäluokka 65–84 v, muut kovariaatit keskiarvoissa).",
  "Naiset: säädetty 12 kk muutos komposiitissa MOI-indeksin funktiona (FOF_status = nonFOF, ikäluokka 65–84 v, muut kovariaatit keskiarvoissa)."
)

manifest_rows <- tibble::tibble(
  script     = script_label,
  type       = manifest_types,
  filename   = manifest_filenames,
  description= manifest_descriptions
)

# 13.3 Kirjoitetaan/appendataan manifest.csv --------------------

if (!file.exists(manifest_path)) {
  # luodaan uusi manifest-tiedosto otsikkorivillä
  readr::write_csv(manifest_rows, manifest_path)
} else {
  # lisätään rivit olemassa olevan manifestin perään
  readr::write_csv(manifest_rows, manifest_path, append = TRUE)
}


# End of K9.R