#!/usr/bin/env Rscript
# ==============================================================================
# K15 - Fried-inspired physical frailty proxy variable derivation
# File tag: K15.R
# Purpose: Derives a physical frailty proxy based on Fried phenotype criteria
#          (exhaustion, weakness, slowness, low activity) adapted to available
#          dataset variables; creates frailty categories (robust/pre-frail/frail)
#          for subsequent K16 frailty-adjusted analyses
#
# Outcome: None (derives frailty variables as exposures/covariates for K16)
# Predictors: None (this is a data preparation script)
# Moderator/interaction: None
# Grouping variable: frailty_cat_3 (derived: "robust"/"pre-frail"/"frail")
# Covariates: N/A (script generates covariates)
#
# Required vars (raw_data - DO NOT INVENT; must match req_raw_cols check):
# kaatumisenpelkoOn, ToimintaKykySummary0, ToimintaKykySummary2,
# [Frailty component proxies - UNCERTAINTY: exact variable names TBD based on codebook]
# Typical candidates: self-rated exhaustion, grip strength, gait speed, physical activity level
# (Note: K15 code checks for multiple candidate variable names flexibly)
#
# Required vars (analysis df - after frailty derivation):
# FOF_status (from kaatumisenpelkoOn), Composite_Z0, Composite_Z3 (or Composite_Z2),
# frailty_count_3 (sum of frailty indicators), frailty_cat_3 (factor: robust/pre-frail/frail),
# frailty_cat_3_obj (objective measures only), frailty_cat_3_2plus (strict: ≥2 indicators = frail)
#
# Mapping (raw -> analysis; keep minimal + explicit):
# kaatumisenpelkoOn (0/1) -> FOF_status (0/1)
# ToimintaKykySummary0 -> Composite_Z0 (or ToimintaKykySummary0_baseline)
# ToimintaKykySummary2 -> Composite_Z3 (endpoint used by K16)
# [Frailty indicators] -> frailty_exhaustion, frailty_weakness, frailty_slowness, frailty_lowactivity
# Sum of indicators -> frailty_count_3
# frailty_count_3: 0 -> "robust", 1 -> "pre-frail", ≥2 -> "frail"
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: 20251124 (set for reproducibility, though no randomness in derivation)
#
# Outputs + manifest:
# - script_label: K15 (canonical)
# - outputs dir: R-scripts/K15/outputs/K15/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
# - Primary output: K15_frailty_analysis_data.RData (saved for K16 use)
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load raw data (immutable; no edits)
# 03) Check required raw columns (req_raw_cols - flexible for frailty proxies)
# 04) Standardize vars + QC (standardize_analysis_vars + sanity_checks)
# 05) Define frailty thresholds (age/sex-specific if possible; document assumptions)
# 06) Derive frailty component indicators (exhaustion, weakness, slowness, low activity)
# 07) Compute frailty count (sum of indicators)
# 08) Create frailty categories (robust/pre-frail/frail; multiple definitions)
# 09) Validate frailty variables (check distributions, cross-tabs by FOF)
# 10) Save frailty-augmented dataset as RData for K16
# 11) Save frailty derivation summary tables (n/% by category, by FOF group)
# 12) Append manifest row per artifact
# 13) Save sessionInfo to manifest/
# 14) EOF marker
# ==============================================================================
#
suppressPackageStartupMessages({
  library(here)
  library(dplyr)
})

# --- Standard init (MANDATORY) -----------------------------------------------
# Derive script_label from --file, supporting file tags like: K15.V1_name.R
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K15"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)  # canonical SCRIPT_ID
if (is.na(script_label) || script_label == "") script_label <- "K15"

# Source helper functions (io, checks, modeling, reporting)
rm(list = ls(pattern = "^(save_|init_paths$|append_manifest$|manifest_row$)"),
   envir = .GlobalEnv)

source(here("R","functions","io.R"))
source(here("R","functions","checks.R"))
source(here("R","functions","modeling.R"))
source(here("R","functions","reporting.R"))

# init_paths() must set outputs_dir + manifest_path (+ options fof.*)
paths <- init_paths(script_label)

# seed (set for reproducibility, though no randomness in frailty derivation)
set.seed(20251124)

# ==============================================================================
# 01. Load Dataset & Data Checking
# ==============================================================================

# Load data
file_path <- here::here("data", "external", "KaatumisenPelko.csv")
if (!file.exists(file_path)) {
  stop("Tiedostoa data/external/KaatumisenPelko.csv ei löydy.")
}

raw_data <- readr::read_csv(file_path, show_col_types = FALSE)

## Standardize variable names and run sanity checks
df <- standardize_analysis_vars(raw_data)
qc <- sanity_checks(df)
print(qc)

# K15 käyttää omaa muuttujarakennetta, joten säilytetään raw_data myös
analysis_data <- raw_data

# Get paths from init_paths (already called in header)
outputs_dir   <- getOption("fof.outputs_dir")
manifest_path <- getOption("fof.manifest_path")

# ==============================================================================
# 02. FOF-Status ja Perusmuuttujat
# ==============================================================================

# 2.1 FOF_status: oletus 0 = nonFOF, 1 = FOF

if (!("FOF_status" %in% names(analysis_data))) {
if ("kaatumisenpelkoOn" %in% names(analysis_data)) {
analysis_data <- analysis_data %>%
mutate(
FOF_status = if_else(kaatumisenpelkoOn == 1, 1L, 0L)
)
} else {
stop(
"FOF_status-muuttujaa ei löytynyt, eikä kaatumisenpelkoOn-muuttujaa.\n",
"Lisää jompikumpi analysis_dataan ennen K15.R-skriptin ajamista."
)
}
}

# 2.2 FOF_status factor (raportointia varten)

analysis_data <- analysis_data %>%
mutate(
FOF_status = as.integer(FOF_status),
FOF_status_factor = factor(
FOF_status,
levels = c(0, 1),
labels = c("nonFOF", "FOF")
)
)

# ==============================================================================
# 03. Frailty Thresholds (Muokattavissa)
# ==============================================================================

grip_cut_strategy <- "sex_Q1"
# "sex_Q1" (default) tai "literature" (placeholder)
gait_cut_m_per_sec <- 0.8 # Slowness: < 0.8 m/s = hidas
low_BMI_threshold <- 21 # Low BMI: BMI < 21
maxwalk_low_cut_m <- 400 # Max kävelymatka < 400 m tulkitaan matalaksi

# Huom: Weakness-komponentille
# - sex_Q1: sukupuolikohtainen alin kvartiili (Q1) Puristus0:sta
# - literature: kiinteät placeholder-rajat (esim. naisille <20 kg, miehille <30
#   kg) -> helppo muokata skriptin alussa tarpeen mukaan.

# ==============================================================================
# 04. Komponentti: Weakness (frailty_weakness)
# ==============================================================================
# Oletus:
# - Puristus0 = käsipuristusvoiman keskiarvo (kg), baseline
# - 0 kg tulkitaan puuttuvaksi mittaukseksi (esim. ei tehty / tekninen ongelma).

if (!("Puristus0" %in% names(analysis_data))) {
  warning("Puristus0-muuttuja puuttuu analysis_data:
  weakness-komponentti jää NA:ksi.")
}

# 4.1 Sukupuolimuuttuja apuun (sex_factor aina factor)

if ("sex" %in% names(analysis_data)) {

  if (is.factor(analysis_data$sex)) {
    # sex on jo factor, käytetään sellaisenaan
    analysis_data$sex_factor <- analysis_data$sex

  } else if (is.numeric(analysis_data$sex)) {
    # oletus: 0 = female, 1 = male
    analysis_data$sex_factor <- factor(
      analysis_data$sex,
      levels = c(0, 1),
      labels = c("female", "male")
    )

  } else {
    # varmuuden vuoksi: mikä tahansa muu → factor
    analysis_data$sex_factor <- factor(analysis_data$sex)
  }

} else {
  warning("sex-muuttuja puuttuu: sex_factor jää NA:ksi ja weakness-komponentti epäluotettava.")
  analysis_data$sex_factor <- NA
}

# 4.2 Puristus0_clean tehdään erillisessä mutate-lohkossa

analysis_data <- analysis_data %>%
  mutate(
    Puristus0_clean = if_else(
      !is.na(Puristus0) & Puristus0 <= 0,
      NA_real_, # 0 kg => tulkitaan puuttuvaksi
      Puristus0
    )
  )

# 4.3 Cutpointit

grip_cuts <- NULL

if ("Puristus0" %in% names(analysis_data)) {

  if (grip_cut_strategy == "sex_Q1") {

    grip_cuts <- analysis_data %>%
      filter(!is.na(Puristus0_clean), !is.na(sex_factor)) %>%
      group_by(sex_factor) %>%
      summarise(
        cut_Q1 = quantile(Puristus0_clean, probs = 0.25, na.rm = TRUE),
        .groups = "drop"
      )

    message("K15: Weakness-rajat (sex_Q1):")
    print(grip_cuts)


  } else if (grip_cut_strategy == "literature") {

    # TODO: päivitä kirjallisuusrajat tarvittaessa tarkemmin.
    grip_cuts <- tibble(
      sex_factor = factor(c("female", "male"),
                          levels = c("female", "male")),
      cut_Q1    = c(20, 30) # placeholder: naiset <20 kg, miehet <30 kg
    )
    message("K15: Weakness-rajat (literature placeholder,
    päivitä tarvittaessa):")
    print(grip_cuts)


  }

  grip_cut_vec <- NULL
  if (!is.null(grip_cuts)) {
    grip_cut_vec <- setNames(grip_cuts$cut_Q1,
    as.character(grip_cuts$sex_factor))
  }

  analysis_data <- analysis_data %>%
    mutate(
      frailty_weakness = case_when(
        is.null(grip_cut_vec) ~ NA_integer_,
        is.na(Puristus0_clean) | is.na(sex_factor) ~ NA_integer_,
        TRUE ~ if_else(
          Puristus0_clean < grip_cut_vec[as.character(sex_factor)],
          1L, 0L
        )
      )
    )

} else {
  analysis_data <- analysis_data %>%
    mutate(frailty_weakness = NA_integer_)
}

# ==============================================================================
# 05. Komponentti: Slowness (frailty_slowness)
# ==============================================================================
# Oletus:
# - kavelynopeus_m_sek0 = kävelynopeus baseline (m/s).
# - frailty_slowness = 1, jos kävelynopeus < gait_cut_m_per_sec (default 0.8 m/s).
# - Jos kävelynopeus = 0 (ei kävellyt / ei pystynyt), tulkitaan selvästi hitaaksi => 1.

if (!("kavelynopeus_m_sek0" %in% names(analysis_data))) {
  warning("kavelynopeus_m_sek0 puuttuu analysis_data: slowness-komponentti jää NA:ksi.")
  analysis_data <- analysis_data %>%
    mutate(frailty_slowness = NA_integer_)
} else {
  analysis_data <- analysis_data %>%
    mutate(
      frailty_slowness = case_when(
        is.na(kavelynopeus_m_sek0) ~ NA_integer_,
        kavelynopeus_m_sek0 == 0 ~ 1L, # ei pystynyt / ei kävellyt -> hidas
        kavelynopeus_m_sek0 < gait_cut_m_per_sec ~ 1L,
        TRUE ~ 0L
      )
    )
}

# ==============================================================================
# 06. Komponentti: Low Physical Activity / Mobility (frailty_low_activity)
# ==============================================================================
# Käytettävät muuttujat (jos saatavilla):
# - oma_arvio_liikuntakyky:
#   oletus: 0 = Weak, 1 = Moderate, 2 = Good (ks. system_prompt)
# - Vaikeus500m tai vaikeus_liikkua_500m:
#   oletus: 0 = No difficulties, 1 = Difficulties, 2 = Cannot
# - vaikeus_liikkua_2km:
#   oletus: 0 = No difficulties, 1 = Difficulties, 2 = Cannot
# - maxkävelymatka (m):
#   low activity, jos maxkävelymatka < maxwalk_low_cut_m
# Logiikka:
# frailty_low_activity = 1, jos jokin seuraavista:
# - oma_arvio_liikuntakyky viittaa Weak (0)
# - 500 m tai 2 km kävelyssä difficulties/cannot (1/2)
# - maxkävelymatka < maxwalk_low_cut_m
# Muuten 0. Jos kaikki komponentit puuttuvat, NA.

var_500m <- NULL
if ("Vaikeus500m" %in% names(analysis_data)) var_500m <- "Vaikeus500m"
if (is.null(var_500m) && "vaikeus_liikkua_500m" %in% names(analysis_data)) var_500m <- "vaikeus_liikkua_500m"

if (is.null(var_500m)) {
message("K15: 500 m -muuttujaa (Vaikeus500m / vaikeus_liikkua_500m) ei löytynyt; käytetään muita low_activity-komponentteja.")
}

has_oma <- "oma_arvio_liikuntakyky" %in% names(analysis_data)
has_2km <- "vaikeus_liikkua_2km" %in% names(analysis_data)
has_maxw <- "maxkävelymatka" %in% names(analysis_data)

analysis_data <- analysis_data %>%
mutate(
walking500_code = if (!is.null(var_500m)) .data[[var_500m]] else NA_integer_,
walking2km_code = if (has_2km) vaikeus_liikkua_2km else NA_integer_,

# weak_flag: TODO tarkista, että 0=Weak, 1=Moderate, 2=Good pitää paikkansa
flag_weak_SR = if (has_oma) {
  case_when(
    is.na(oma_arvio_liikuntakyky) ~ NA,
    oma_arvio_liikuntakyky == 0   ~ TRUE,   # Weak
    oma_arvio_liikuntakyky %in% c(1, 2) ~ FALSE,
    TRUE ~ NA
  )
} else {
  NA
},

flag_500m_limit = case_when(
  is.na(walking500_code) ~ NA,
  walking500_code %in% c(1, 2) ~ TRUE,
  walking500_code == 0 ~ FALSE,
  TRUE ~ NA
),

flag_2km_limit = case_when(
  is.na(walking2km_code) ~ NA,
  walking2km_code %in% c(1, 2) ~ TRUE,
  walking2km_code == 0 ~ FALSE,
  TRUE ~ NA
),

flag_maxwalk_low = case_when(
  !has_maxw ~ NA,
  is.na(maxkävelymatka) ~ NA,
  maxkävelymatka < maxwalk_low_cut_m ~ TRUE,
  TRUE ~ FALSE
),

any_low_activity_info = !is.na(flag_weak_SR) |
                        !is.na(flag_500m_limit) |
                        !is.na(flag_2km_limit) |
                        !is.na(flag_maxwalk_low),

frailty_low_activity = case_when(
  !any_low_activity_info ~ NA_integer_,
  flag_weak_SR      %in% TRUE ~ 1L,
  flag_500m_limit   %in% TRUE ~ 1L,
  flag_2km_limit    %in% TRUE ~ 1L,
  flag_maxwalk_low  %in% TRUE ~ 1L,
  # jos tiedämme, että kaikki saatavilla olevat komponentit eivät viittaa rajoitteeseen:
  TRUE ~ 0L
),

# 6A) SENSITIIVISYYSVERSIOT: Objektiivinen low_activity (ei subjektiivista oma-arviota)
frailty_low_activity_obj_only = case_when(
  !any_low_activity_info ~ NA_integer_,
  flag_500m_limit  %in% TRUE |
  flag_2km_limit   %in% TRUE |
  flag_maxwalk_low %in% TRUE ~ 1L,
  TRUE ~ 0L
),

# 6B) SENSITIIVISYYSVERSIO: Tiukempi low_activity (vaaditaan ≥2 indikaattoria)
n_low_activity_flags = coalesce(as.integer(flag_weak_SR     %in% TRUE), 0L) +
                       coalesce(as.integer(flag_500m_limit  %in% TRUE), 0L) +
                       coalesce(as.integer(flag_2km_limit   %in% TRUE), 0L) +
                       coalesce(as.integer(flag_maxwalk_low %in% TRUE), 0L),

frailty_low_activity_2plus = case_when(
  !any_low_activity_info ~ NA_integer_,
  n_low_activity_flags >= 2L ~ 1L,
  TRUE ~ 0L
)


)

# ==============================================================================
# 07. Optional Komponentti: Low BMI (frailty_low_BMI)
# ==============================================================================
# Huom: Tämä EI ole painonlasku-komponentti. Käytetään vain BMI-arvoa
# (esim. aliravitsemusta / vähäistä reserviä indikoi BMI < low_BMI_threshold).

if (!("BMI" %in% names(analysis_data))) {
  warning("BMI puuttuu analysis_data: frailty_low_BMI-muuttuja jää NA:ksi.")
  analysis_data <- analysis_data %>%
    mutate(frailty_low_BMI = NA_integer_)
} else {
  analysis_data <- analysis_data %>%
    mutate(
      frailty_low_BMI = case_when(
        is.na(BMI) ~ NA_integer_,
        BMI < low_BMI_threshold ~ 1L,
        TRUE ~ 0L
      )
    )
}

# ==============================================================================
# 08. Summapisteet ja Kategoriat
# ==============================================================================

analysis_data <- analysis_data %>%
  mutate(
    # 3-komponenttinen proxy: weakness + slowness + low_activity
    frailty_count_3 = frailty_weakness +
      frailty_slowness +
      frailty_low_activity,

    frailty_cat_3 = case_when(
      is.na(frailty_count_3)       ~ NA_character_,
      frailty_count_3 == 0         ~ "robust",
      frailty_count_3 == 1         ~ "pre-frail",
      frailty_count_3 >= 2         ~ "frail"
    ),

    # 4-komponenttinen proxy: lisää low_BMI
    frailty_count_4 = frailty_weakness +
                      frailty_slowness +
                      frailty_low_activity +
                      frailty_low_BMI,

    frailty_cat_4 = case_when(
      is.na(frailty_count_4)       ~ NA_character_,
      frailty_count_4 == 0         ~ "robust",
      frailty_count_4 %in% 1:2     ~ "pre-frail",
      frailty_count_4 >= 3         ~ "frail"
    ),

    frailty_cat_3 = factor(
      frailty_cat_3,
      levels = c("robust", "pre-frail", "frail")
    ),
    frailty_cat_4 = factor(
      frailty_cat_4,
      levels = c("robust", "pre-frail", "frail")
    )


)

# 8B) SENSITIIVISYYSVERSIOT: vaihtoehtoiset frailty-scorit

analysis_data <- analysis_data %>%
  mutate(
    # 1) Vain weakness + slowness (ei low_activity:a ollenkaan)
    frailty_count_2 = frailty_weakness + frailty_slowness,

    # 2) 3-komponenttinen score, jossa low_activity = objektiivinen versio
    frailty_count_3_obj = frailty_weakness +
                          frailty_slowness +
                          frailty_low_activity_obj_only,
    frailty_cat_3_obj = case_when(
      is.na(frailty_count_3_obj) ~ NA_character_,
      frailty_count_3_obj == 0   ~ "robust",
      frailty_count_3_obj == 1   ~ "pre-frail",
      frailty_count_3_obj >= 2   ~ "frail"
    ),

    # 3) 3-komponenttinen score, jossa low_activity = vähintään 2 indikaattoria
    frailty_count_3_2plus = frailty_weakness +
                            frailty_slowness +
                            frailty_low_activity_2plus,
    frailty_cat_3_2plus = case_when(
      is.na(frailty_count_3_2plus) ~ NA_character_,
      frailty_count_3_2plus == 0   ~ "robust",
      frailty_count_3_2plus == 1   ~ "pre-frail",
      frailty_count_3_2plus >= 2   ~ "frail"
    ),

    frailty_cat_3_obj   = factor(frailty_cat_3_obj,
                                 levels = c("robust", "pre-frail", "frail")),
    frailty_cat_3_2plus = factor(frailty_cat_3_2plus,
                                 levels = c("robust", "pre-frail", "frail"))
  )

# Nopea komponenttien tarkistus

message("K15: komponenttien jakaumat (table, useNA='ifany'):")
print(table(analysis_data$frailty_weakness, useNA = "ifany"))
print(table(analysis_data$frailty_slowness, useNA = "ifany"))
print(table(analysis_data$frailty_low_activity, useNA = "ifany"))
print(table(analysis_data$frailty_low_BMI, useNA = "ifany"))

message("\nK15: SENSITIIVISYYSVERSIOT - low_activity komponentit:")
print(table(analysis_data$frailty_low_activity_obj_only, useNA = "ifany"))
print(table(analysis_data$frailty_low_activity_2plus, useNA = "ifany"))

message("\nK15: SENSITIIVISYYSVERSIOT - frailty kategoriat:")
print(table(analysis_data$frailty_cat_3, useNA = "ifany"))
print(table(analysis_data$frailty_cat_3_obj, useNA = "ifany"))
print(table(analysis_data$frailty_cat_3_2plus, useNA = "ifany"))

# ==============================================================================
# 09. Deskriptiiviset Taulukot
# ==============================================================================

## 9.1 Jakaumat: count & category (3- ja 4-komponenttinen)

tab_frailty_count_3 <- analysis_data %>%
  count(frailty_count_3) %>%
  mutate(
    proportion = n / sum(n)
  )

tab_frailty_cat_3 <- analysis_data %>%
  count(frailty_cat_3) %>%
  mutate(
    proportion = n / sum(n)
  )

tab_frailty_count_4 <- analysis_data %>%
  count(frailty_count_4) %>%
  mutate(
    proportion = n / sum(n)
  )

tab_frailty_cat_4 <- analysis_data %>%
  count(frailty_cat_4) %>%
  mutate(
    proportion = n / sum(n)
  )

save_table_csv_html(tab_frailty_count_3, "K15_frailty_count_3_overall")
save_table_csv_html(tab_frailty_cat_3, "K15_frailty_cat_3_overall")
save_table_csv_html(tab_frailty_count_4, "K15_frailty_count_4_overall")
save_table_csv_html(tab_frailty_cat_4, "K15_frailty_cat_4_overall")

## 9.2 FOF-ryhmittäiset ristiintaulukot

tab_frailty_cat3_by_FOF <- analysis_data %>%
  filter(!is.na(FOF_status_factor), !is.na(frailty_cat_3)) %>%
  count(FOF_status_factor, frailty_cat_3) %>%
  group_by(FOF_status_factor) %>%
  mutate(
    row_total = sum(n),
    row_proportion = n / row_total
  ) %>%
  ungroup()

tab_frailty_cat4_by_FOF <- analysis_data %>%
  filter(!is.na(FOF_status_factor), !is.na(frailty_cat_4)) %>%
  count(FOF_status_factor, frailty_cat_4) %>%
  group_by(FOF_status_factor) %>%
  mutate(
    row_total = sum(n),
    row_proportion = n / row_total
  ) %>%
  ungroup()

save_table_csv_html(tab_frailty_cat3_by_FOF, "K15_frailty_cat3_by_FOF")
save_table_csv_html(tab_frailty_cat4_by_FOF, "K15_frailty_cat4_by_FOF")

## 9.3 Khiin neliö / Fisher (FOF × frailty_cat)

dat_chi3 <- analysis_data %>%
  filter(!is.na(FOF_status_factor), !is.na(frailty_cat_3))

dat_chi4 <- analysis_data %>%
  filter(!is.na(FOF_status_factor), !is.na(frailty_cat_4))

tbl3 <- table(dat_chi3$FOF_status_factor, dat_chi3$frailty_cat_3)
tbl4 <- table(dat_chi4$FOF_status_factor, dat_chi4$frailty_cat_4)

chi3 <- suppressWarnings(chisq.test(tbl3))
chi4 <- suppressWarnings(chisq.test(tbl4))

tab_chi3 <- broom::tidy(chi3)
tab_chi4 <- broom::tidy(chi4)

save_table_csv_html(tab_chi3, "K15_chisq_FOF_by_frailty_cat3")
save_table_csv_html(tab_chi4, "K15_chisq_FOF_by_frailty_cat4")

# ==============================================================================
# 10. Optional Plots
# ==============================================================================

## 10.1 Proportion plot: frailty_cat_3 × FOF_status

plot_frailty_cat3_by_FOF <- ggplot(
  analysis_data %>%
    filter(!is.na(FOF_status_factor), !is.na(frailty_cat_3)),
  aes(x = frailty_cat_3, fill = FOF_status_factor)
) +
  geom_bar(position = "fill") +
  scale_y_continuous(
    name = "Proportion",
    labels = scales::percent_format(accuracy = 1)
  ) +
  labs(
    x = "Frailty category (3-component proxy)",
    fill = "FOF-status",
    title = "Fried-inspired frailty proxy (3 components) by FOF-status"
  ) +
  theme_minimal()

plot_path <- file.path(outputs_dir, "K15_frailty_cat3_by_FOF.png")
ggsave(
  filename = plot_path,
  plot = plot_frailty_cat3_by_FOF,
  width = 7,
  height = 5,
  dpi = 300
)

append_manifest(
  manifest_row(script = script_label, label = "K15_frailty_cat3_by_FOF",
               path = plot_path, kind = "figure_png",
               notes = "Stacked proportion plot: frailty_cat_3 distribution by FOF-status."),
  manifest_path
)

# TODO: Haluttaessa vastaava kuva frailty_cat_4:lle.

# ==============================================================================
# 11. Save Analysis Data for K16
# ==============================================================================
# Tallenna analysis_data K16:ta varten (sisältää kaikki frailty-muuttujat)
rdata_path <- here::here("R-scripts", "K15", "outputs",
                         "K15_frailty_analysis_data.RData")
save(analysis_data, file = rdata_path)
message("K15: analysis_data tallennettu: ", rdata_path)

message("K15: Fried-inspired physical frailty proxy rakennettu ja perusjakaumat + FOF-vertailut tallennettu.")

# ==============================================================================
# 12. Loppukommentit (Doc-Blokki)
# ==============================================================================
# Tämä skripti rakentaa eksplisiittisesti nimetyn "Fried-inspired physical frailty proxy" -muuttujan.
# Sisältyvät komponentit:
# 1) Weakness (frailty_weakness):
#    - Perustuu baseline-käsipuristusvoimaan (Puristus0) ja sukupuoleen.
#    - Oletusstrategia: sukupuolikohtainen alin kvartiili (Q1) erottaa "matala" vs "normaali" voima.
#    - 0 kg -arvot tulkitaan puuttuviksi mittauksiksi.
# 2) Slowness (frailty_slowness):
#    - Perustuu baseline-kävelynopeuteen (kavelynopeus_m_sek0).
#    - Oletusraja: < 0.8 m/s => hidas (1), muuten 0.
#    - 0 m/s tulkitaan kyvyttömyydeksi kävellä => 1 (frail).
# 3) Low physical activity / mobility limitation (frailty_low_activity):
#    - Perustuu yhdistelmään:
#      * oma_arvio_liikuntakyky (oletus 0=Weak, 1=Moderate, 2=Good),
#      * Vaikeus500m / vaikeus_liikkua_500m (0=No, 1=Difficulties, 2=Cannot),
#      * vaikeus_liikkua_2km (0=No, 1=Difficulties, 2=Cannot),
#      * maxkävelymatka < maxwalk_low_cut_m (oletus 400 m).
#    - frailty_low_activity = 1, jos jokin näistä viittaa selkeään rajoitteeseen,
#      muuten 0; jos mikään ei ole saatavilla, NA.
# 4) Optional: Low BMI (frailty_low_BMI):
#    - Perustuu BMI-muuttujaan.
#    - frailty_low_BMI = 1, jos BMI < low_BMI_threshold (oletus 21 kg/m2),
#      muuten 0.
#    - Tämä komponentti EI ole painonlasku, vaan erillinen low-BMI-indikaattori.
# Summapisteet ja luokat:
# - frailty_count_3 = weakness + slowness + low_activity (0–3)
# - frailty_count_4 = weakness + slowness + low_activity + low_BMI (0–4)
# - frailty_cat_3:
#     0 -> "robust"
#     1 -> "pre-frail"
#     >=2 -> "frail"
# - frailty_cat_4:
#     0 -> "robust"
#     1–2 -> "pre-frail"
#     >=3 -> "frail"
# Rajoitukset:
# - Tämä ei ole standardoitu Friedin 5-komponenttinen frailty-phenotype.
#   (Painonlasku ja uupumus puuttuvat; niiden tilalle ei ole rakennettu pseudo-kriteerejä.)
# - Cut-offit (Q1, 0.8 m/s, BMI < 21, maxkävelymatka < 400 m) ovat tutkijavalintoja;
#   frailtyn tulkinta on aina herkkä näille valinnoille.
# - Komponenttien puuttuvat arvot johtavat summapisteen NA:han, jos jokin
#   tarvittava osa puuttuu; tämä kannattaa huomioida jatkoanalyyseissä
#   (esim. multiple imputation vs. complete case).
# Konteksti:
# - Proxy on suunniteltu käytettäväksi FOF-/toimintakykyprojektin analyysiputkessa
#   (esim. FOF-ryhmittäinen vertailu, jatkoanalyysit muutoksista).
# - K15 tuottaa kuvailevia jakaumia ja FOF-ristiintaulukoita, joita voidaan
#   jatkossa hyödyntää regressio- tai mixed-malleissa osana laajempaa analyysiä.
# Muokattavuus:
# - Tutkija voi säätää threshold-arvoja (grip_cut_strategy, gait_cut_m_per_sec,
#   low_BMI_threshold, maxwalk_low_cut_m) skriptin alussa, ja tarvittaessa
#   päivittää low_activity-luokittelun vastaamaan tarkempaa tietoa muuttujakoodauksesta.

# End of K15.R

save_sessioninfo_manifest()

