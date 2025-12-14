# --- Kxx template (put at top of every script) -------------------------------
suppressPackageStartupMessages({ library(here); library(dplyr) })

rm(list = ls(pattern = "^(save_|init_paths$|append_manifest$|manifest_row$)"),
   envir = .GlobalEnv)

source(here("R","functions","io.R"))
source(here("R","functions","checks.R"))
source(here("R","functions","modeling.R"))
source(here("R","functions","reporting.R"))

script_label <- sub("\\.R$", "", basename(commandArgs(trailingOnly=FALSE)[grep("--file=", commandArgs())] |> sub("--file=", "", x=_)))
if (is.na(script_label) || script_label == "") script_label <- "K13"
paths <- init_paths(script_label)

set.seed(20251124)


# K13: FOF × ikä, BMI, sukupuoli -interaktioanalyysit (laajennetut mallit)


# ==============================================================================

# ==============================================================================
# 0. PACKAGES ---------------------------------------------------
# ==============================================================================

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
library(here)

source(here::here("R", "functions", "io.R"))
source(here::here("R", "functions", "checks.R"))
source(here::here("R", "functions", "modeling.R"))
source(here::here("R", "functions", "reporting.R"))

set.seed(20251124)  # jos myöhemmin käytetään satunnaisuutta (esim. bootstrap)

# ==============================================================================
# 1: Load the dataset -------------------------------------------
# ==============================================================================

file_path <- here::here("data", "external", "KaatumisenPelko.csv")

raw_data <- readr::read_csv(file_path, show_col_types = FALSE)

## Working copy so the original stays untouched
if (!exists("raw_data")) {
  stop("Object 'raw_data' not found. Please load your data as raw_data first.")
}

## Standardize variable names and run sanity checks
df <- standardize_analysis_vars(raw_data)
qc <- sanity_checks(df)
print(qc)

# ==============================================================================
# 2: Output-kansio K13:n alle ------------------------------------
# ==============================================================================

script_label <- "K13"
paths <- init_paths(script_label)
outputs_dir   <- paths$outputs_dir
manifest_path <- paths$manifest_path

# ==============================================================================
# 3. DATA PREPARATION -------------------------------------------
# ==============================================================================

# Lisätään tarvittavat kovariaatit (df on jo standardisoitu)
analysis_data_rec <- df %>%
  mutate(
    # Ikäluokat
    AgeClass = case_when(
      Age < 65                 ~ "65_74",
      Age >= 65 & Age <= 74    ~ "65_74",
      Age >= 75 & Age <= 84    ~ "75_84",
      Age >= 85                ~ "85plus",
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
    )
  )

# ---------------------------------------------------------------
# Outcome-muuttujat ja alias-sarakkeet (peilaa K11-logiikkaa)
# ---------------------------------------------------------------

has_DeltaComposite   <- "DeltaComposite"    %in% names(analysis_data_rec)
has_Delta_CompositeZ <- "Delta_Composite_Z" %in% names(analysis_data_rec)

if (has_DeltaComposite) {
  message("Using existing DeltaComposite column.")
  
} else if (has_Delta_CompositeZ) {
  analysis_data_rec <- analysis_data_rec %>%
    mutate(DeltaComposite = Delta_Composite_Z)
  message("Created DeltaComposite from Delta_Composite_Z.")
  
} else {
  # lasketaan muutos komposiitista kuten K11:ssä
  analysis_data_rec <- analysis_data_rec %>%
    mutate(DeltaComposite = ToimintaKykySummary2 - ToimintaKykySummary0)
  message("Created DeltaComposite as ToimintaKykySummary2 - ToimintaKykySummary0.")
}

# Alias-sarakkeet analyyseja varten
analysis_data_rec <- analysis_data_rec %>%
  mutate(
    Composite_Z0      = ToimintaKykySummary0,
    Delta_Composite_Z = DeltaComposite,
    # käytä mieluummin tätä kuin sex_factor:ia
    sex = factor(
      sex,
      levels = c(0, 1),
      labels = c("female", "male")
    ),
    MOI_score = MOIindeksiindeksi
  )

# ---------------------------------------------------------------
# Lisämoderaattorit: MOI_c, SRH_3class, SRM_3class, PainVAS0_c
# ---------------------------------------------------------------

analysis_data_rec <- analysis_data_rec %>%
  mutate(
    # Keskitetty MOI (osteroporoosiriski-indeksi)
    MOI_score = MOIindeksiindeksi,
    MOI_c = MOI_score - mean(MOI_score, na.rm = TRUE),
    
    # Keskitetty kipu (0–10 VAS)
    PainVAS0_c = PainVAS0 - mean(PainVAS0, na.rm = TRUE),
    
    # SRH 3-luokkainen (oletus: 0 = huono, 1 = kohtalainen, 2 = hyvä)
    SRH_3class = factor(
      SRH,
      levels = c(0, 1, 2),
      labels = c("poor", "fair", "good"),
      ordered = TRUE
    ),
    
    # SRM 3-luokkainen (oma_arvio_liikuntakyky, 0–2)
    SRM_3class = factor(
      oma_arvio_liikuntakyky,
      levels = c(0, 1, 2),
      labels = c("poor", "fair", "good"),
      ordered = TRUE
    )
  )
str(analysis_data_rec$sex)
table(analysis_data_rec$sex, useNA = "ifany")

##  4.1 K11:n mukainen dat_fof

dat_fof <- analysis_data_rec %>%
  dplyr::select(
    id,
    Delta_Composite_Z,
    Composite_Z0,
    age,
    BMI,
    sex,
    FOF_status,
    MOI_score, MOI_c,
    diabetes,
    alzheimer,
    parkinson,
    AVH,
    previous_falls = kaatuminen,
    psych_score = mieliala,
    PainVAS0, PainVAS0_c,
    SRH, SRH_3class,
    oma_arvio_liikuntakyky, SRM_3class
  ) %>%
  filter(
    !is.na(Delta_Composite_Z),
    !is.na(Composite_Z0),
    !is.na(age),
    !is.na(BMI),
    !is.na(sex),
    !is.na(FOF_status)
  ) %>%
  mutate(
    FOF_status = relevel(FOF_status, ref = "nonFOF")
  )


str(dat_fof)

## 4.2 Keskitetyt ikä- ja BMI-muuttujat + complete-case interaktioanalyyseihin

age_mean <- mean(dat_fof$age, na.rm = TRUE)
bmi_mean <- mean(dat_fof$BMI, na.rm = TRUE)

dat_int_cc <- dat_fof %>%
  mutate(
    age_c = age - age_mean,
    BMI_c = BMI - bmi_mean
  ) %>%
  filter(
    !is.na(MOI_score),
    !is.na(diabetes),
    !is.na(alzheimer),
    !is.na(parkinson),
    !is.na(AVH),
    !is.na(previous_falls),
    !is.na(psych_score),
    !is.na(PainVAS0),
    !is.na(SRH),
    !is.na(oma_arvio_liikuntakyky)
  )

summary(dat_int_cc$age_c)
summary(dat_int_cc$BMI_c)
summary(dat_int_cc$MOI_c)
summary(dat_int_cc$PainVAS0_c)


# ==============================================================================
# 5. LINEAARISET INTERAKTIOMALLIT (laajennetut)
# ==============================================================================

##   Kaikki mallit ovat eksploratiivisia, ja sisältävät:
##   - FOF_status päävaikutuksena
## - FOF_status × moderaattori (ikä, BMI, sukupuoli)
## - Perussetti kovariaatteja: Composite_Z0, age_c/BMI_c/sex (riippuen mallista),
## MOI_score, diabetes, alzheimer, parkinson, AVH, previous_falls, psych_score.

## 5.1 FOF × age_c -interaktio

mod_age_int_ext <- lm(
  Delta_Composite_Z ~ FOF_status * age_c +
    BMI_c + sex +
    Composite_Z0 +
    MOI_score +
    diabetes + alzheimer + parkinson + AVH +
    previous_falls + psych_score,
  data = dat_int_cc
)

## 5.2 FOF × BMI_c -interaktio

mod_BMI_int_ext <- lm(
  Delta_Composite_Z ~ FOF_status * BMI_c +
    age_c + sex +
    Composite_Z0 +
    MOI_score +
    diabetes + alzheimer + parkinson + AVH +
    previous_falls + psych_score,
  data = dat_int_cc
)

## 5.3 FOF × sex -interaktio

mod_sex_int_ext <- lm(
  Delta_Composite_Z ~ FOF_status * sex +
    age_c + BMI_c +
    Composite_Z0 +
    MOI_score +
    diabetes + alzheimer + parkinson + AVH +
    previous_falls + psych_score,
  data = dat_int_cc
)

##(Valinnainen) yhdistelmämalli, jos haluat kaikki interaktiot samaan malliin:
##   Huom. erittäin eksploratiivinen ja alttiimpi tehon puutteelle ylisäätämisen takia.

mod_all_int_ext <- lm(
  Delta_Composite_Z ~
    FOF_status * age_c +
    FOF_status * BMI_c +
    FOF_status * sex +
    Composite_Z0 +
    MOI_score +
    diabetes + alzheimer + parkinson + AVH +
    previous_falls + psych_score,
  data = dat_int_cc
)

# 5.4 FOF × MOI_c (osteroporoosiriski moderaattorina)
mod_MOI_int_ext <- lm(
  Delta_Composite_Z ~ FOF_status * MOI_c +
    age_c + BMI_c + sex +
    Composite_Z0 +
    diabetes + alzheimer + parkinson + AVH +
    previous_falls + psych_score +
    PainVAS0_c + SRH_3class + SRM_3class,
  data = dat_int_cc
)

# 5.5 FOF × PainVAS0_c (kipu moderaattorina)
mod_Pain_int_ext <- lm(
  Delta_Composite_Z ~ FOF_status * PainVAS0_c +
    age_c + BMI_c + sex +
    Composite_Z0 +
    MOI_c +
    diabetes + alzheimer + parkinson + AVH +
    previous_falls + psych_score +
    SRH_3class + SRM_3class,
  data = dat_int_cc
)

# 5.6 FOF × SRH_3class (itsearvioitu terveys moderaattorina)
mod_SRH_int_ext <- lm(
  Delta_Composite_Z ~ FOF_status * SRH_3class +
    age_c + BMI_c + sex +
    Composite_Z0 +
    MOI_c + PainVAS0_c +
    diabetes + alzheimer + parkinson + AVH +
    previous_falls + psych_score +
    SRM_3class,
  data = dat_int_cc
)

# 5.7 FOF × SRM_3class (itsearvioitu liikuntakyky moderaattorina)
mod_SRM_int_ext <- lm(
  Delta_Composite_Z ~ FOF_status * SRM_3class +
    age_c + BMI_c + sex +
    Composite_Z0 +
    MOI_c + PainVAS0_c +
    diabetes + alzheimer + parkinson + AVH +
    previous_falls + psych_score +
    SRH_3class,
  data = dat_int_cc
)


# ==============================================================================
# 6. TIDY-TAULUKOT JA INTERAKTIOKOOSTE
# ==============================================================================

  
  tidy_age <- broom::tidy(mod_age_int_ext, conf.int = TRUE) %>%
  mutate(model = "age_int_ext")
tidy_BMI <- broom::tidy(mod_BMI_int_ext, conf.int = TRUE) %>%
  mutate(model = "BMI_int_ext")
tidy_sex <- broom::tidy(mod_sex_int_ext, conf.int = TRUE) %>%
  mutate(model = "sex_int_ext")
tidy_all <- broom::tidy(mod_all_int_ext, conf.int = TRUE) %>%
  mutate(model = "all_int_ext")
tidy_MOI  <- broom::tidy(mod_MOI_int_ext,  conf.int = TRUE) %>%
  mutate(model = "MOI_int_ext")
tidy_Pain <- broom::tidy(mod_Pain_int_ext, conf.int = TRUE) %>%
  mutate(model = "Pain_int_ext")
tidy_SRH  <- broom::tidy(mod_SRH_int_ext,  conf.int = TRUE) %>%
  mutate(model = "SRH_int_ext")
tidy_SRM  <- broom::tidy(mod_SRM_int_ext,  conf.int = TRUE) %>%
  mutate(model = "SRM_int_ext")

save_table_csv_html(tidy_MOI,  "lm_MOI_int_extended_full")
save_table_csv_html(tidy_Pain, "lm_Pain_int_extended_full")
save_table_csv_html(tidy_SRH,  "lm_SRH_int_extended_full")
save_table_csv_html(tidy_SRM,  "lm_SRM_int_extended_full")

## Tallennetaan täyden mallin kertoimet (voi helpottaa tarkastelua)

save_table_csv_html(tidy_age, "lm_age_int_extended_full")
save_table_csv_html(tidy_BMI, "lm_BMI_int_extended_full")
save_table_csv_html(tidy_sex, "lm_sex_int_extended_full")
save_table_csv_html(tidy_all, "lm_all_int_extended_full")

## 6.1 Kiinnostavat FOF- ja interaktiotermit
### (Käytämme eksplisiittisiä termiä nimiä taulukko–teksti -yhtenäisyyden varmistamiseksi)

fof_terms_age <- tidy_age %>%
  filter(term %in% c("FOF_status1", "FOF_status1:age_c"))

fof_terms_BMI <- tidy_BMI %>%
  filter(term %in% c("FOF_status1", "FOF_status1:BMI_c"))

fof_terms_sex <- tidy_sex %>%
  filter(term %in% c("FOF_status1", "FOF_status1:sex1"))

## 6.2 Interaktiokooste: yksi rivi per moderaattori (FOF × moderaattori)

tab_interactions_overview <- bind_rows(
  fof_terms_age %>% filter(term == "FOF_status1:age_c") %>%
    mutate(moderator = "age_c", model = "age_int_ext"),
  fof_terms_BMI %>% filter(term == "FOF_status1:BMI_c") %>%
    mutate(moderator = "BMI_c", model = "BMI_int_ext"),
  fof_terms_sex %>% filter(term == "FOF_status1:sex1") %>%
    mutate(moderator = "sex", model = "sex_int_ext")
) %>%
  dplyr::select(
    model,
    moderator,
    term,
    estimate,
    std.error,
    statistic,
    p.value,
    conf.low,
    conf.high
  )

save_table_csv_html(tab_interactions_overview, "FOF_interaction_effects_overview")

fof_terms_MOI <- tidy_MOI %>%
  filter(term %in% c("FOF_status1:MOI_c"))
fof_terms_Pain <- tidy_Pain %>%
  filter(term %in% c("FOF_status1:PainVAS0_c"))

tab_interactions_symptoms <- bind_rows(
  fof_terms_MOI  %>% mutate(moderator = "MOI_c",       model = "MOI_int_ext"),
  fof_terms_Pain %>% mutate(moderator = "PainVAS0_c",  model = "Pain_int_ext")
) %>%
  dplyr::select(
    model,
    moderator,
    term,
    estimate,
    std.error,
    statistic,
    p.value,
    conf.low,
    conf.high
  )

save_table_csv_html(tab_interactions_symptoms, "FOF_interaction_effects_symptoms")

results_symptoms_sentences <- tab_interactions_symptoms %>%
  mutate(
    results_line = paste0(
      "FOF × ", moderator, ": β = ",
      sprintf("%.3f", estimate),
      ", 95 % LV ",
      sprintf("%.3f", conf.low), " – ",
      sprintf("%.3f", conf.high),
      ", p = ", sprintf("%.3f", p.value)
    )
  ) %>%
  dplyr::select(moderator, results_line)

results_symptoms_sentences

fof_terms_SRH <- tidy_SRH %>%
  filter(grepl("FOF_status", term) & grepl("SRH_3class", term))

fof_terms_SRM <- tidy_SRM %>%
  filter(grepl("FOF_status", term) & grepl("SRM_3class", term))

tab_interactions_SRH_SRM <- bind_rows(
  fof_terms_SRH %>% mutate(moderator = "SRH_3class", model = "SRH_int_ext"),
  fof_terms_SRM %>% mutate(moderator = "SRM_3class", model = "SRM_int_ext")
) %>%
  dplyr::select(
    model,
    moderator,
    term,
    estimate,
    std.error,
    statistic,
    p.value,
    conf.low,
    conf.high
  )

tab_interactions_SRH_SRM

results_SRH_SRM_sentences <- tab_interactions_SRH_SRM %>%
  mutate(
    results_line = paste0(
      "FOF × ", moderator, ": β = ",
      sprintf("%.3f", estimate),
      ", 95 % LV ",
      sprintf("%.3f", conf.low), " – ",
      sprintf("%.3f", conf.high),
      ", p = ", sprintf("%.3f", p.value)
    )
  ) %>%
  dplyr::select(moderator, term, results_line)

results_SRH_SRM_sentences




## 6.3 (Valinnainen) standardoidut kertoimet: etsitään FOF × moderaattori -parametrit

get_std_interactions <- function(fit, moderator_label, model_label) {
  std_tab <- tryCatch(
    effectsize::standardize_parameters(
      fit,
      method = "posthoc",
      two_sided = TRUE
    ) %>%
      as.data.frame(),
    error = function(e) {
      message("Standardized parameters failed for model = ", model_label)
      NULL
    }
  )
  
  if (is.null(std_tab)) return(NULL)
  
##  effectsize nimeää parametrin muodossa "FOF status [1] * age_c" tms.
  
  std_int <- std_tab %>%
    dplyr::filter(grepl("FOF", .data$Parameter) & grepl(moderator_label, .data$Parameter)) %>%
    dplyr::mutate(
      model = model_label,
      moderator = moderator_label
    )
  
  std_int
}

std_age_int <- get_std_interactions(mod_age_int_ext, "age_c", "age_int_ext")
std_BMI_int <- get_std_interactions(mod_BMI_int_ext, "BMI_c", "BMI_int_ext")
std_sex_int <- get_std_interactions(mod_sex_int_ext, "sex", "sex_int_ext")

tab_std_interactions <- bind_rows(std_age_int, std_BMI_int, std_sex_int)

if (nrow(tab_std_interactions) > 0) {
  save_table_csv_html(tab_std_interactions, "FOF_interaction_effects_standardized")
}

# ==============================================================================
# 7. SIMPLE SLOPES: FOF-EFEKTI ERI IKÄ- / BMI-TASOILLA JA SUKUPUOLITTAIN
# ==============================================================================

##  7.1 FOF × age_c: FOF-efekti eri ikätasoilla

age_c_values <- c(-10, 0, 10) # noin 10 vuoden erot centered-asteikolla
age_values <- age_c_values + age_mean

emm_age <- emmeans(
  mod_age_int_ext,
  ~ FOF_status | age_c,
  at = list(age_c = age_c_values)
)

contr_age <- contrast(
  emm_age,
  method = "revpairwise", # FOF vs nonFOF (koska FOF_status ref = nonFOF)
  by = "age_c",
  adjust = "none"
)

simple_slopes_age <- as.data.frame(
  summary(contr_age, infer = TRUE)
) %>%
  mutate(
    age_c = age_c,
    age = age_c + age_mean,
    effect = "FOF (FOF vs nonFOF)",
    outcome = "Delta_Composite_Z"
  ) %>%
  dplyr::rename(
    estimate = estimate,
    conf.low = lower.CL,
    conf.high = upper.CL
  )

save_table_csv_html(simple_slopes_age, "simple_slopes_FOF_by_age")

plot_FOFxAge <- ggplot(
  simple_slopes_age,
  aes(x = age, y = estimate, ymin = conf.low, ymax = conf.high)
) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_pointrange() +
  labs(
    x = "Ikä (vuotta)",
    y = "FOF-efekti Delta_Composite_Z:ään (kerroin, FOF vs nonFOF)",
    title = "FOF × ikä: FOF-efekti eri ikätasoilla"
  ) +
  theme_minimal()

ggsave(
  filename = file.path(outputs_dir, "FOF_effect_by_age_simple_slopes.png"),
  plot = plot_FOFxAge,
  width = 7, height = 4, dpi = 300
)

## 7.2 FOF × BMI_c: FOF-efekti eri BMI-tasoilla

BMI_c_values <- c(-5, 0, 5)
BMI_values <- BMI_c_values + bmi_mean

emm_BMI <- emmeans(
  mod_BMI_int_ext,
  ~ FOF_status | BMI_c,
  at = list(BMI_c = BMI_c_values)
)

contr_BMI <- contrast(
  emm_BMI,
  method = "revpairwise",
  by = "BMI_c",
  adjust = "none"
)

simple_slopes_BMI <- as.data.frame(
  summary(contr_BMI, infer = TRUE)
) %>%
  mutate(
    BMI_c = BMI_c,
    BMI = BMI_c + bmi_mean,
    effect = "FOF (FOF vs nonFOF)",
    outcome = "Delta_Composite_Z"
  ) %>%
  dplyr::rename(
    estimate = estimate,
    conf.low = lower.CL,
    conf.high = upper.CL
  )

save_table_csv_html(simple_slopes_BMI, "simple_slopes_FOF_by_BMI")

plot_FOFxBMI <- ggplot(
  simple_slopes_BMI,
  aes(x = BMI, y = estimate, ymin = conf.low, ymax = conf.high)
) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_pointrange() +
  labs(
    x = "BMI (kg/m²)",
    y = "FOF-efekti Delta_Composite_Z:ään (kerroin, FOF vs nonFOF)",
    title = "FOF × BMI: FOF-efekti eri BMI-tasoilla"
  ) +
  theme_minimal()

ggsave(
  filename = file.path(outputs_dir, "FOF_effect_by_BMI_simple_slopes.png"),
  plot = plot_FOFxBMI,
  width = 7, height = 4, dpi = 300
)

## 7.3 FOF × sex: FOF-efekti erikseen naisilla ja miehillä

emm_sex <- emmeans(
  mod_sex_int_ext,
  ~ FOF_status | sex
)

contr_sex <- contrast(
  emm_sex,
  method = "revpairwise",
  by = "sex",
  adjust = "none"
)

simple_slopes_sex <- as.data.frame(
  summary(contr_sex, infer = TRUE)
) %>%
  mutate(
    effect = "FOF (FOF vs nonFOF)",
    outcome = "Delta_Composite_Z"
  ) %>%
  dplyr::rename(
    estimate = estimate,
    conf.low = lower.CL,
    conf.high = upper.CL
  )

save_table_csv_html(simple_slopes_sex, "simple_slopes_FOF_by_sex")

plot_FOFxSex <- ggplot(
  simple_slopes_sex,
  aes(x = sex, y = estimate, ymin = conf.low, ymax = conf.high)
) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_pointrange() +
  labs(
    x = "Sukupuoli",
    y = "FOF-efekti Delta_Composite_Z:ään (kerroin, FOF vs nonFOF)",
    title = "FOF × sukupuoli: FOF-efekti naisilla vs miehillä"
  ) +
  theme_minimal()

ggsave(
  filename = file.path(outputs_dir, "FOF_effect_by_sex_simple_slopes.png"),
  plot = plot_FOFxSex,
  width = 6, height = 4, dpi = 300
)


## 7.4 FOF × MOI_c

MOI_c_values <- c(-2, 0, 2)  # noin 2 pistettä alle/yläpuolelle keskiarvon
emm_MOI <- emmeans(
  mod_MOI_int_ext,
  ~ FOF_status | MOI_c,
  at = list(MOI_c = MOI_c_values)
)

contr_MOI <- contrast(
  emm_MOI,
  method = "revpairwise",  # FOF vs nonFOF
  by     = "MOI_c",
  adjust = "none"
)

simple_slopes_MOI <- as.data.frame(
  summary(contr_MOI, infer = TRUE)
) %>%
  mutate(
    MOI_c  = MOI_c,
    MOI    = MOI_c + mean(dat_int_cc$MOI_score, na.rm = TRUE),
    effect = "FOF (FOF vs nonFOF)",
    outcome = "Delta_Composite_Z"
  ) %>%
  dplyr::rename(
    estimate  = estimate,
    conf.low  = lower.CL,
    conf.high = upper.CL
  )

save_table_csv_html(simple_slopes_MOI, "simple_slopes_FOF_by_MOI")

plot_FOFxMOI <- ggplot(
  simple_slopes_MOI,
  aes(x = MOI, y = estimate, ymin = conf.low, ymax = conf.high)
) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_pointrange() +
  labs(
    x = "MOI-score",
    y = "FOF-efekti Delta_Composite_Z:ään (kerroin, FOF vs nonFOF)",
    title = "FOF × MOI: FOF-efekti eri osteoporoosiriskitasoilla"
  ) +
  theme_minimal()

ggsave(
  filename = file.path(outputs_dir, "FOF_effect_by_MOI_simple_slopes.png"),
  plot     = plot_FOFxMOI,
  width    = 7, height = 4, dpi = 300
)

## 7.5 FOF × PainVAS0_c

Pain_c_values <- c(-2, 0, 2)  # ~2 VAS-pisteen ero
emm_Pain <- emmeans(
  mod_Pain_int_ext,
  ~ FOF_status | PainVAS0_c,
  at = list(PainVAS0_c = Pain_c_values)
)

contr_Pain <- contrast(
  emm_Pain,
  method = "revpairwise",
  by     = "PainVAS0_c",
  adjust = "none"
)

simple_slopes_Pain <- as.data.frame(
  summary(contr_Pain, infer = TRUE)
) %>%
  mutate(
    PainVAS0_c = PainVAS0_c,
    PainVAS0   = PainVAS0_c + mean(dat_int_cc$PainVAS0, na.rm = TRUE),
    effect     = "FOF (FOF vs nonFOF)",
    outcome    = "Delta_Composite_Z"
  ) %>%
  dplyr::rename(
    estimate  = estimate,
    conf.low  = lower.CL,
    conf.high = upper.CL
  )

save_table_csv_html(simple_slopes_Pain, "simple_slopes_FOF_by_Pain")

plot_FOFxPain <- ggplot(
  simple_slopes_Pain,
  aes(x = PainVAS0, y = estimate, ymin = conf.low, ymax = conf.high)
) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_pointrange() +
  labs(
    x = "Kipu VAS 0–10",
    y = "FOF-efekti Delta_Composite_Z:ään (kerroin, FOF vs nonFOF)",
    title = "FOF × kipu: FOF-efekti eri kiputasoilla"
  ) +
  theme_minimal()

ggsave(
  filename = file.path(outputs_dir, "FOF_effect_by_Pain_simple_slopes.png"),
  plot     = plot_FOFxPain,
  width    = 7, height = 4, dpi = 300
)


## 7.6 FOF × SRH_3class ja FOF × SRM_3class

# SRH (itsearvioitu terveys)
emm_SRH <- emmeans(
  mod_SRH_int_ext,
  ~ FOF_status | SRH_3class
)

contr_SRH <- contrast(
  emm_SRH,
  method = "revpairwise",
  by     = "SRH_3class",
  adjust = "none"
)

simple_slopes_SRH <- as.data.frame(
  summary(contr_SRH, infer = TRUE)
) %>%
  mutate(
    effect  = "FOF (FOF vs nonFOF)",
    outcome = "Delta_Composite_Z"
  ) %>%
  dplyr::rename(
    estimate  = estimate,
    conf.low  = lower.CL,
    conf.high = upper.CL
  )

save_table_csv_html(simple_slopes_SRH, "simple_slopes_FOF_by_SRH")

plot_FOFxSRH <- ggplot(
  simple_slopes_SRH,
  aes(x = SRH_3class, y = estimate, ymin = conf.low, ymax = conf.high)
) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_pointrange() +
  labs(
    x = "Itsearvioitu terveys (SRH)",
    y = "FOF-efekti Delta_Composite_Z:ään (kerroin, FOF vs nonFOF)",
    title = "FOF × SRH: FOF-efekti eri terveyden itsearvioissa"
  ) +
  theme_minimal()

ggsave(
  filename = file.path(outputs_dir, "FOF_effect_by_SRH_simple_slopes.png"),
  plot     = plot_FOFxSRH,
  width    = 6, height = 4, dpi = 300
)

# SRM (oma_arvio_liikuntakyky)
emm_SRM <- emmeans(
  mod_SRM_int_ext,
  ~ FOF_status | SRM_3class
)

contr_SRM <- contrast(
  emm_SRM,
  method = "revpairwise",
  by     = "SRM_3class",
  adjust = "none"
)

simple_slopes_SRM <- as.data.frame(
  summary(contr_SRM, infer = TRUE)
) %>%
  mutate(
    effect  = "FOF (FOF vs nonFOF)",
    outcome = "Delta_Composite_Z"
  ) %>%
  dplyr::rename(
    estimate  = estimate,
    conf.low  = lower.CL,
    conf.high = upper.CL
  )

save_table_csv_html(simple_slopes_SRM, "simple_slopes_FOF_by_SRM")

plot_FOFxSRM <- ggplot(
  simple_slopes_SRM,
  aes(x = SRM_3class, y = estimate, ymin = conf.low, ymax = conf.high)
) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_pointrange() +
  labs(
    x = "Itsearvioitu liikuntakyky (SRM)",
    y = "FOF-efekti Delta_Composite_Z:ään (kerroin, FOF vs nonFOF)",
    title = "FOF × SRM: FOF-efekti eri liikuntakyvyn itsearvioissa"
  ) +
  theme_minimal()

ggsave(
  filename = file.path(outputs_dir, "FOF_effect_by_SRM_simple_slopes.png"),
  plot     = plot_FOFxSRM,
  width    = 6, height = 4, dpi = 300
)

# ==============================================================================
# 8. MALLIDIAGNOSTIIKKA (VIF + residuaalit, vain koodi)
# ==============================================================================

##  8.1 VIF-taulukot

vif_age <- car::vif(mod_age_int_ext)
vif_BMI <- car::vif(mod_BMI_int_ext)
vif_sex <- car::vif(mod_sex_int_ext)

vif_age_df <- as.data.frame(vif_age) %>%
  tibble::rownames_to_column("term") %>%
  mutate(model = "age_int_ext")
vif_BMI_df <- as.data.frame(vif_BMI) %>%
  tibble::rownames_to_column("term") %>%
  mutate(model = "BMI_int_ext")
vif_sex_df <- as.data.frame(vif_sex) %>%
  tibble::rownames_to_column("term") %>%
  mutate(model = "sex_int_ext")

vif_all_df <- bind_rows(vif_age_df, vif_BMI_df, vif_sex_df)

save_table_csv_html(vif_all_df, "VIF_interaction_models")

## 8.2 (Valinnainen) residuaaliplotit interaktiomalleille
plot(mod_age_int_ext, which = 1) # residuaalit vs fitted
plot(mod_BMI_int_ext, which = 1)
plot(mod_sex_int_ext, which = 1)

# ==============================================================================
# 9. KLIININEN TULKINTA: 4-HAARAINEN LOGIIKKA (AUTOMAATTINEN TEKSTI)
# ==============================================================================

## 9.1 Tulkintafunktio interaktiovaikutuksille
interpret_interaction <- function(moderator_label, est, lwr, upr, p_value) {
  ci_width <- upr - lwr
  
  # Pieni helper kuvaamaan LV:n leveyttä
  ci_band <- dplyr::case_when(
    ci_width <= 0.20 ~ "suhteellisen kapea",
    ci_width <= 0.50 ~ "kohtalaisen leveä",
    TRUE             ~ "laaja"
  )
  
  # 4-haarainen logiikka
  if (!is.na(p_value) && p_value < 0.05 && est > 0) {
    paste0(
      "Merkitsevä positiivinen FOF × ", moderator_label,
      " -interaktio (β = ", round(est, 2),
      ", 95 % LV ", round(lwr, 2), "–", round(upr, 2), "). ",
      "Korkeampi ", moderator_label, "."
    )
  } else if (!is.na(p_value) && p_value < 0.05 && est < 0) {
    paste0(
      "Merkitsevä negatiivinen FOF × ", moderator_label,
      " -interaktio (β = ", round(est, 2),
      ", 95 % LV ", round(lwr, 2), "–", round(upr, 2), "). ",
      "Korkeampi ", moderator_label, "."
    )
  } else if (ci_width <= 0.20) {
    paste0(
      "Ei-merkitsevä FOF × ", moderator_label,
      " -interaktio (β = ", round(est, 2),
      ", 95 % LV ", round(lwr, 2), "–", round(upr, 2),
      ", LV ", ci_band, "). ",
      "LV:n perusteella mahdollinen moderoiva vaikutus näyttää olevan korkeintaan pieni. ",
      "Tämä tukee tulkintaa, että FOF:n vaikutus Delta_Composite_Z:ään ei juuri riipu ",
      moderator_label, "-tasosta."
    )
  } else {
    paste0(
      "Ei-merkitsevä FOF × ", moderator_label,
      " -interaktio (β = ", round(est, 2),
      ", 95 % LV ", round(lwr, 2), "–", round(upr, 2),
      ", LV ", ci_band, "). ",
      "Laaja LV tekee tuloksesta epävarman; data ei sulje pois pieniä tai kohtalaisia ",
      "moderaatiovaikutuksia. Koska interaktioanalyyseja on useita, yksittäisiä p-arvoja ",
      "ei tule ylitulkita."
    )
  }
}

## 9.2 Automaattiset tulkinnat kaikille moderaattoreille

# Yhdistetään kaikki interaktiotaulukot samaan nippuun
tab_interactions_all <- dplyr::bind_rows(
  tab_interactions_overview,   # age_c, BMI_c, sex
  tab_interactions_symptoms,   # MOI_c, PainVAS0_c
  tab_interactions_SRH_SRM     # SRH_3class, SRM_3class
)

interaction_interpretations <- tab_interactions_all %>%
  mutate(
    interpretation = purrr::pmap_chr(
      list(moderator, estimate, conf.low, conf.high, p.value),
      ~ interpret_interaction(..1, ..2, ..3, ..4, ..5)
    )
  )

save_table_csv_html(interaction_interpretations, "FOF_interaction_effects_interpretation")

print(interaction_interpretations)

results_sentences <- interaction_interpretations %>%
  mutate(
    results_line = paste0(
      "FOF × ", moderator, ": β = ",
      sprintf("%.3f", estimate),
      ", 95 % LV ",
      sprintf("%.3f", conf.low), " – ",
      sprintf("%.3f", conf.high),
      ", p = ", sprintf("%.3f", p.value)
    )
  ) %>%
  dplyr::select(moderator, term, results_line)

results_sentences


#==============================================================================
# 11. KLIININEN YHTEENVETO (TEKSTIRUNKO, MUOKKAA TULOSTEN PERUSTEELLA)
#==============================================================================



#==============================================================================
# 11. KLIININEN YHTEENVETO 
#==============================================================================

clinical_summary_template <- c(
  "Kliininen tulkinta (luonnos, muokkaa lopullisten estimaattien mukaan):",
  "",
  "- Nämä interaktioanalyysit (ikä, BMI, sukupuoli, osteoporoosiriski-indeksi, kipu, ",
  "  itsearvioitu terveys ja itsearvioitu liikuntakyky) ovat eksploratiivisia, eikä ",
  "  p-arvoja tule tulkita ilman monen testin riskin huomioimista.",
  "- Mikäli FOF × moderaattori -termit (FOF × age_c, FOF × BMI_c, FOF × sex, ",
  "  FOF × MOI_c, FOF × PainVAS0_c, FOF × SRH_3class, FOF × SRM_3class) ovat ",
  "  johdonmukaisesti pieniä ja 95 % LV:t melko kapeita ja sisältävät nollan, ",
  "  voidaan alustavasti todeta, ettei FOF:n vaikutus Delta_Composite_Z:ään näytä ",
  "  systemaattisesti riippuvan iästä, BMI:stä, sukupuolesta, kivusta, ",
  "  itsearvioidusta terveydentilasta tai itsearvioidusta liikuntakyvystä tässä ",
  "  aineistossa.",
  "- Jos jokin interaktioista osoittaa selkeää trendiä (esim. suurempi FOF-efekti ",
  "  tietyllä kiputasolla tai heikommassa itsearvioidussa liikuntakyvyssä), sitä ",
  "  tulee korostaa vain hypoteesigeneratiivisena löydöksenä, joka vaatii ",
  "  vahvistusta jatkotutkimuksessa."
)

clinical_summary_template

# Save session info
si_path <- file.path(outputs_dir, "sessionInfo_K13.txt")
save_sessioninfo(si_path)
append_manifest(
  manifest_row(script = script_label, label = "sessionInfo",
               path = si_path, kind = "sessioninfo"),
  manifest_path
)

# End of K13.R

save_sessioninfo_manifest()

