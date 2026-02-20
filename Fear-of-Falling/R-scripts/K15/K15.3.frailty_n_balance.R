#!/usr/bin/env Rscript
# ==============================================================================
# K15.3 - Fried-inspired physical frailty proxy variable derivation with balance
# File tag: K15.3.R
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
# (Note: K15.3. code checks for multiple candidate variable names flexibly)
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
# [Frailty indicators] -> frailty_exhaustion, frailty_w
#
# ==============================================================================
# 00. Setup
# ==============================================================================
suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(ggplot2)
})

# --- Standard init (MANDATORY) -----------------------------------------------
# Derive script_label from --file, supporting file tags like: K15.3.V1_name.R
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K15"  # interactive fallback
}

# Override script_label to K15 to ensure outputs go to R-scripts/K15/outputs/
script_label <- "K15"

# Source helper functions (io, checks, modeling, reporting)
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

# K15.3. käyttää omaa muuttujarakennetta, joten säilytetään raw_data myös
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
      "Lisää jompikumpi analysis_dataan ennen K15.3.R-skriptin ajamista."
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

# --- NEW: Balance (single leg stance) cut strategy (align with weakness logic) ---
balance_cut_strategy <- "sex_Q1"
# "sex_Q1" (default) tai "overall_Q1"

gait_cut_m_per_sec <- 0.8 # Slowness: < 0.8 m/s = hidas
low_BMI_threshold <- 21 # Low BMI: BMI < 21
maxwalk_low_cut_m <- 400 # Max kävelymatka < 400 m tulkitaan matalaksi

# Helper: gate sex-stratified cutpoints when sex data is mostly missing/insufficient.
sex_factor_usable <- function(x, min_non_na = 10, min_groups = 2) {
  if (is.null(x)) return(FALSE)
  x <- as.character(x)
  non_na <- x[!is.na(x) & nzchar(x)]
  if (length(non_na) < min_non_na) return(FALSE)
  if (length(unique(non_na)) < min_groups) return(FALSE)
  TRUE
}

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
  warning("Puristus0-muuttuja puuttuu analysis_data:\nweakness-komponentti jää NA:ksi.")
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
  warning("sex-muuttuja puuttuu: sex_factor jää NA:ksi ja weakness-komponentti epäluotettava."
  )
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
  
  use_sex_grip <- sex_factor_usable(analysis_data$sex_factor, min_non_na = 10)
  if (grip_cut_strategy == "sex_Q1" && use_sex_grip) {
    
    grip_cuts <- analysis_data %>%
      filter(!is.na(Puristus0_clean), !is.na(sex_factor)) %>%
      group_by(sex_factor) %>%
      summarise(
        cut_Q1 = quantile(Puristus0_clean, probs = 0.25, na.rm = TRUE),
        .groups = "drop"
      )
    
    message("K15.3.: Weakness-rajat (sex_Q1):")
    print(grip_cuts)
    
    
  } else if (grip_cut_strategy == "literature") {
    
    # TODO: päivitä kirjallisuusrajat tarvittaessa tarkemmin.
    grip_cuts <- tibble(
      sex_factor = factor(c("female", "male"),
                          levels = c("female", "male")),
      cut_Q1    = c(20, 30) # placeholder: naiset <20 kg, miehet <30 kg
    )
    message("K15.3.: Weakness-rajat (literature placeholder,\npäivitä tarvittaessa):")
    print(grip_cuts)
    
    
  } else {
    if (grip_cut_strategy == "sex_Q1" && !use_sex_grip) {
      message("K15.3.: Weakness-rajat: sex_Q1 pyydetty, mutta sex_factor on käyttökelvoton (enimmäkseen NA tai liian vähän havaintoja); fallback overall_Q1.")
    }
    grip_cuts <- analysis_data %>%
      summarise(cut_Q1 = quantile(Puristus0_clean, probs = 0.25, na.rm = TRUE)) %>%
      mutate(sex_factor = NA_character_) %>%
      dplyr::select(sex_factor, cut_Q1)
    message("K15.3.: Weakness-rajat (overall_Q1 / fallback):")
    print(grip_cuts)
  }
  
  grip_cut_vec <- NULL
  grip_cut_overall <- NA_real_
  if (!is.null(grip_cuts)) {
    if (all(is.na(grip_cuts$sex_factor))) {
      grip_cut_overall <- as.numeric(grip_cuts$cut_Q1[[1]])
    } else {
      grip_cut_vec <- setNames(grip_cuts$cut_Q1,
                               as.character(grip_cuts$sex_factor))
    }
  }
  
  analysis_data <- analysis_data %>%
    mutate(
      frailty_weakness = case_when(
        is.null(grip_cut_vec) && is.na(grip_cut_overall) ~ NA_integer_,
        is.null(grip_cut_vec) & !is.na(grip_cut_overall) & is.na(Puristus0_clean) ~ NA_integer_,
        is.null(grip_cut_vec) & !is.na(grip_cut_overall) ~ if_else(Puristus0_clean < grip_cut_overall, 1L, 0L),
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
# 05B. Komponentti: Balance (frailty_balance)  [NEW]
# ==============================================================================
# Tavoite:
# - Etsi single-leg stance -muuttuja datasta (ei arvata nimeä: käytetään alias-listaa)
# - Muodosta frailty_balance = 1 huonoimmassa kvartiilissa (Q1) kuten weakness (sex_Q1),
#   tai vaihtoehtoisesti overall_Q1, jos sex puuttuu.
# - 0 sekuntia tulkitaan hyvin heikoksi tasapainoksi => 1 (frail), ei puuttuvaksi.
# - Negatiiviset arvot tulkitaan virheellisiksi => NA.
#
# HUOM: Tämä ei muuta alkuperäisiä frailty_count_* -muuttujia. Luodaan rinnalle
# laajennettu proxy (weakness + slowness + balance) sekä sen kategoriat.

balance_var <- NULL
balance_aliases <- c(
  "single_leg_stance", "single leg stance", "one_leg_stance", "one-leg stance",
  "one_leg_balance", "one leg balance", "SLS", "sls"
)

# 1) Ensisijaisesti täsmähaku: löytyykö jokin alias-sarakkeen nimi sellaisenaan?
for (nm in names(analysis_data)) {
  if (tolower(nm) %in% tolower(balance_aliases)) {
    balance_var <- nm
    break
  }
}

# 2) Toissijaisesti: osittainen regex-haku (sallitut merkkivariaatiot)
if (is.null(balance_var)) {
  patt <- "(single[_ ]?leg|one[_ -]?leg|sls).*?(stance|balance)?"
  cand <- names(analysis_data)[grepl(patt, names(analysis_data), ignore.case = TRUE)]
  if (length(cand) > 0) balance_var <- cand[1]
}

if (is.null(balance_var)) {
  message("K15.3.: Balance-muuttujaa (single leg stance) ei löytynyt alias-haulla; frailty_balance jää NA:ksi.")
  analysis_data <- analysis_data %>% mutate(frailty_balance = NA_integer_)
} else {
  message("K15.3.: Balance-muuttuja löytyi: ", balance_var)
  
  analysis_data <- analysis_data %>%
    mutate(
      single_leg_stance = as.numeric(.data[[balance_var]]),
      single_leg_stance_clean = case_when(
        is.na(single_leg_stance) ~ NA_real_,
        single_leg_stance < 0 ~ NA_real_,   # virheellinen
        TRUE ~ single_leg_stance
      )
    )
  
  # Diagnostiikka: mahdollinen katto-/lattiavaikutus (vain viesti)
  if (any(!is.na(analysis_data$single_leg_stance_clean))) {
    max_sls <- suppressWarnings(max(analysis_data$single_leg_stance_clean, na.rm = TRUE))
    prop_at_max <- mean(analysis_data$single_leg_stance_clean == max_sls, na.rm = TRUE)
    if (is.finite(max_sls) && prop_at_max >= 0.20) {
      message("K15.3.: HUOM balance: mahdollinen kattoefekti (>=20% maksimiarvossa). max = ",
              round(max_sls, 2), ", osuus = ", round(prop_at_max, 3))
    }
    prop_zero <- mean(analysis_data$single_leg_stance_clean == 0, na.rm = TRUE)
    if (prop_zero >= 0.10) {
      message("K15.3.: HUOM balance: lattiavaikutus (>=10% arvossa 0). osuus = ",
              round(prop_zero, 3))
    }
  }
  
  # Cutpointit
  balance_cuts <- NULL
  
  use_sex_balance <- sex_factor_usable(analysis_data$sex_factor, min_non_na = 10)
  if (balance_cut_strategy == "sex_Q1" && ("sex_factor" %in% names(analysis_data)) && use_sex_balance) {
    
    balance_cuts <- analysis_data %>%
      filter(!is.na(single_leg_stance_clean), !is.na(sex_factor)) %>%
      group_by(sex_factor) %>%
      summarise(
        cut_Q1 = quantile(single_leg_stance_clean, probs = 0.25, na.rm = TRUE),
        .groups = "drop"
      )
    
    message("K15.3.: Balance-rajat (sex_Q1):")
    print(balance_cuts)
    
    balance_cut_vec <- setNames(balance_cuts$cut_Q1, as.character(balance_cuts$sex_factor))
    
    analysis_data <- analysis_data %>%
      mutate(
        frailty_balance = case_when(
          is.na(single_leg_stance_clean) | is.na(sex_factor) ~ NA_integer_,
          single_leg_stance_clean == 0 ~ 1L,
          TRUE ~ if_else(
            single_leg_stance_clean <= balance_cut_vec[as.character(sex_factor)],
            1L, 0L
          )
        )
      )
    
  } else {
    if (balance_cut_strategy == "sex_Q1" && !use_sex_balance) {
      message("K15.3.: Balance-rajat: sex_Q1 pyydetty, mutta sex_factor on käyttökelvoton (enimmäkseen NA tai liian vähän havaintoja); fallback overall_Q1.")
    }
    
    # overall_Q1 (tai fallback jos sex_factor puuttuu)
    cut_overall <- analysis_data %>%
      summarise(cut_Q1 = quantile(single_leg_stance_clean, probs = 0.25, na.rm = TRUE)) %>%
      pull(cut_Q1)
    
    message("K15.3.: Balance-rajat (overall_Q1 / fallback):")
    print(cut_overall)
    
    analysis_data <- analysis_data %>%
      mutate(
        frailty_balance = case_when(
          is.na(single_leg_stance_clean) ~ NA_integer_,
          single_leg_stance_clean == 0 ~ 1L,
          single_leg_stance_clean <= cut_overall ~ 1L,
          TRUE ~ 0L
        )
      )
  }
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
  message("K15.3.: 500 m -muuttujaa (Vaikeus500m / vaikeus_liikkua_500m) ei löytynyt; käytetään muita low_activity-komponentteja.")
}

has_oma <- "oma_arvio_liikuntakyky" %in% names(analysis_data)
has_2km <- "vaikeus_liikkua_2km" %in% names(analysis_data)
has_maxwalk <- "maxkavelymatka_m" %in% names(analysis_data) || "maxkävelymatka" %in% names(analysis_data)

maxwalk_var <- NULL
if ("maxkavelymatka_m" %in% names(analysis_data)) maxwalk_var <- "maxkavelymatka_m"
if (is.null(maxwalk_var) && "maxkävelymatka" %in% names(analysis_data)) maxwalk_var <- "maxkävelymatka"

analysis_data <- analysis_data %>%
  mutate(
    low_activity_flag_oma = case_when(
      !has_oma ~ NA_integer_,
      is.na(oma_arvio_liikuntakyky) ~ NA_integer_,
      oma_arvio_liikuntakyky == 0 ~ 1L,
      TRUE ~ 0L
    ),
    low_activity_flag_500m = case_when(
      is.null(var_500m) ~ NA_integer_,
      is.na(.data[[var_500m]]) ~ NA_integer_,
      .data[[var_500m]] %in% c(1, 2) ~ 1L,
      TRUE ~ 0L
    ),
    low_activity_flag_2km = case_when(
      !has_2km ~ NA_integer_,
      is.na(vaikeus_liikkua_2km) ~ NA_integer_,
      vaikeus_liikkua_2km %in% c(1, 2) ~ 1L,
      TRUE ~ 0L
    ),
    low_activity_flag_maxwalk = case_when(
      is.null(maxwalk_var) ~ NA_integer_,
      is.na(.data[[maxwalk_var]]) ~ NA_integer_,
      .data[[maxwalk_var]] < maxwalk_low_cut_m ~ 1L,
      TRUE ~ 0L
    )
  )

analysis_data <- analysis_data %>%
  mutate(
    frailty_low_activity = case_when(
      # jos kaikki puuttuu -> NA
      is.na(low_activity_flag_oma) &
        is.na(low_activity_flag_500m) &
        is.na(low_activity_flag_2km) &
        is.na(low_activity_flag_maxwalk) ~ NA_integer_,
      # jos joku indikaattori = 1 -> 1
      low_activity_flag_oma == 1 |
        low_activity_flag_500m == 1 |
        low_activity_flag_2km == 1 |
        low_activity_flag_maxwalk == 1 ~ 1L,
      TRUE ~ 0L
    )
  )

# 06B) Objektivoitu low_activity (vain kävelykomponentit)
analysis_data <- analysis_data %>%
  mutate(
    frailty_low_activity_obj_only = case_when(
      is.na(low_activity_flag_500m) &
        is.na(low_activity_flag_2km) &
        is.na(low_activity_flag_maxwalk) ~ NA_integer_,
      low_activity_flag_500m == 1 |
        low_activity_flag_2km == 1 |
        low_activity_flag_maxwalk == 1 ~ 1L,
      TRUE ~ 0L
    ),
    
    # 06C) Vähintään 2 indikaattoria (2plus)
    frailty_low_activity_2plus = case_when(
      is.na(low_activity_flag_oma) &
        is.na(low_activity_flag_500m) &
        is.na(low_activity_flag_2km) &
        is.na(low_activity_flag_maxwalk) ~ NA_integer_,
      (coalesce(low_activity_flag_oma, 0L) +
         coalesce(low_activity_flag_500m, 0L) +
         coalesce(low_activity_flag_2km, 0L) +
         coalesce(low_activity_flag_maxwalk, 0L)) >= 2 ~ 1L,
      TRUE ~ 0L
    )
  )

# ==============================================================================
# 07. Optional: Low BMI (frailty_low_BMI)
# ==============================================================================
if (!("BMI" %in% names(analysis_data))) {
  message("K15.3.: BMI-muuttujaa ei löytynyt; frailty_low_BMI jää NA:ksi.")
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
    
    # --- NEW: weakness + slowness + balance (laajennettu 3-komponenttinen proxy) ---
    frailty_count_3_balance = frailty_weakness +
      frailty_slowness +
      frailty_balance,
    frailty_cat_3_balance = case_when(
      is.na(frailty_count_3_balance) ~ NA_character_,
      frailty_count_3_balance == 0   ~ "robust",
      frailty_count_3_balance == 1   ~ "pre-frail",
      frailty_count_3_balance >= 2   ~ "frail"
    ),
    
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
    
    frailty_cat_3_balance = factor(frailty_cat_3_balance,
                                   levels = c("robust", "pre-frail", "frail")),
    
    frailty_cat_3_obj   = factor(frailty_cat_3_obj,
                                 levels = c("robust", "pre-frail", "frail")),
    frailty_cat_3_2plus = factor(frailty_cat_3_2plus,
                                 levels = c("robust", "pre-frail", "frail"))
  )

# Nopea komponenttien tarkistus
message("K15.3.: komponenttien jakaumat (table, useNA='ifany'):")
print(table(analysis_data$frailty_weakness, useNA = "ifany"))
print(table(analysis_data$frailty_slowness, useNA = "ifany"))
print(table(analysis_data$frailty_low_activity, useNA = "ifany"))
print(table(analysis_data$frailty_low_BMI, useNA = "ifany"))
print(table(analysis_data$frailty_balance, useNA = "ifany"))  # NEW

message("\nK15.3.: SENSITIIVISYYSVERSIOT - low_activity komponentit:")
print(table(analysis_data$frailty_low_activity_obj_only, useNA = "ifany"))
print(table(analysis_data$frailty_low_activity_2plus, useNA = "ifany"))

message("\nK15.3.: SENSITIIVISYYSVERSIOT - frailty kategoriat:")
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

save_table_csv_html(tab_frailty_count_3, "K15.3._frailty_count_3_overall")
save_table_csv_html(tab_frailty_cat_3, "K15.3._frailty_cat_3_overall")
save_table_csv_html(tab_frailty_count_4, "K15.3._frailty_count_4_overall")
save_table_csv_html(tab_frailty_cat_4, "K15.3._frailty_cat_4_overall")

# --- NEW: laajennettu balance-proxy (frailty_count_3_balance / frailty_cat_3_balance) ---
tab_frailty_count_3_balance <- analysis_data %>%
  count(frailty_count_3_balance) %>%
  mutate(proportion = n / sum(n))

tab_frailty_cat_3_balance <- analysis_data %>%
  count(frailty_cat_3_balance) %>%
  mutate(proportion = n / sum(n))

save_table_csv_html(tab_frailty_count_3_balance, "K15.3._frailty_count_3_balance_overall")
save_table_csv_html(tab_frailty_cat_3_balance, "K15.3._frailty_cat_3_balance_overall")

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

save_table_csv_html(tab_frailty_cat3_by_FOF, "K15.3._frailty_cat3_by_FOF")
save_table_csv_html(tab_frailty_cat4_by_FOF, "K15.3._frailty_cat4_by_FOF")

# ==============================================================================
# 10. Plotit (FOF vs frailty)
# ==============================================================================
plot_frailty_cat3_by_FOF <- tab_frailty_cat3_by_FOF %>%
  ggplot(aes(x = FOF_status_factor, y = row_proportion, fill = frailty_cat_3)) +
  geom_col(position = "stack") +
  labs(
    title = "Frailty category (3-component) by FOF-status",
    x = "FOF-status",
    y = "Proportion"
  ) +
  theme_minimal()

plot_path <- file.path(outputs_dir, "K15.3._frailty_cat3_by_FOF.png")
ggsave(plot_path, plot_frailty_cat3_by_FOF, width = 7, height = 5, dpi = 300)

append_manifest(
  manifest_row(
    script_label, "K15.3._frailty_cat3_by_FOF",
    path = plot_path, kind = "figure_png",
    notes = "Stacked proportion plot: frailty_cat_3 distribution by FOF-status."
  ),
  manifest_path
)

# ==============================================================================
# 10B. Mallivertailu: Parantaako balance-laajennus Composite_Z-mallia?  [NEW]
# ==============================================================================
# Huom:
# - K15.3. on ensisijaisesti derivaatioskripti. Tämä osio tekee "quick-check" -mallit
#   Composite_Z-päätemuuttujalle, jotta nähdään tuoko balance lisäselitysvoimaa
#   verrattuna weakness+slowness -proxyyn.
# - Ei lisätä uusia paketteja; käytetään base R -funktioita (lm, anova, AIC/BIC).
# - Selityksen paranemista arvioidaan: ΔR²/Δadj.R², AIC/BIC ja nested F-testi.

# 10B.1 Varmista Composite_Z0 ja Composite_Z3 -muuttujat (flexible mapping)
if (!("Composite_Z0" %in% names(analysis_data))) {
  if ("ToimintaKykySummary0" %in% names(analysis_data)) {
    analysis_data <- analysis_data %>% mutate(Composite_Z0 = ToimintaKykySummary0)
  }
}

if (!("Composite_Z3" %in% names(analysis_data))) {
  if ("ToimintaKykySummary2" %in% names(analysis_data)) {
    analysis_data <- analysis_data %>% mutate(Composite_Z3 = ToimintaKykySummary2)
  } else if ("Composite_Z2" %in% names(analysis_data)) {
    analysis_data <- analysis_data %>% mutate(Composite_Z3 = Composite_Z2)
  }
}

if (!("Composite_Z0" %in% names(analysis_data)) || !("Composite_Z3" %in% names(analysis_data))) {
  message("K15.3.: Composite_Z0/Composite_Z3 ei löytynyt (tai ei saatu mapattua). Ohitetaan mallivertailu-osio.")
} else {
  
  # Base covariates: baseline Composite_Z0 (ANCOVA-tyyppinen)
  base_terms <- c("Composite_Z0")
  
  # Mallimuuttujat (orig vs balance)
  # Käytetään samaa havaintojoukkoa M1 ja M2 -vertailussa (complete cases myös balanceen)
  model_df_common <- analysis_data %>%
    dplyr::select(Composite_Z3, dplyr::all_of(base_terms),
                  frailty_count_2, frailty_count_3_balance) %>%
    tidyr::drop_na()
  
  n_common <- nrow(model_df_common)
  
  # Lisäksi raportoidaan M1:n (orig) käytettävissä oleva N ilman balance-vaatimusta
  model_df_orig <- analysis_data %>%
    dplyr::select(Composite_Z3, dplyr::all_of(base_terms), frailty_count_2) %>%
    tidyr::drop_na()
  n_orig <- nrow(model_df_orig)
  
  message("K15.3.: Mallidatat (N): orig=", n_orig, ", common(orig+balance)=", n_common,
          ", pudotus=", (n_orig - n_common))
  
  if (n_common < 10) {
    warning("K15.3.: Liian pieni N common-sampelessä (<10): mallivertailu epäluotettava.")
    message("K15.3.: Ohitetaan mallivertailu, koska common-sample on liian pieni.")
  } else {
    # 10B.2 Mallit
    f0 <- as.formula(paste("Composite_Z3 ~", paste(base_terms, collapse = " + ")))
    f1 <- as.formula(paste("Composite_Z3 ~", paste(c(base_terms, "frailty_count_2"), collapse = " + ")))
    f2 <- as.formula(paste("Composite_Z3 ~", paste(c(base_terms, "frailty_count_3_balance"), collapse = " + ")))
    
    M0 <- lm(f0, data = model_df_common)
    M1 <- lm(f1, data = model_df_common)
    M2 <- lm(f2, data = model_df_common)
    
    # 10B.3 Mittarit
    get_lm_metrics <- function(mod) {
      s <- summary(mod)
      tibble::tibble(
        n = nobs(mod),
        r2 = unname(s$r.squared),
        adj_r2 = unname(s$adj.r.squared),
        aic = AIC(mod),
        bic = BIC(mod)
      )
    }
    
    metrics <- dplyr::bind_rows(
      get_lm_metrics(M0) %>% dplyr::mutate(model = "M0: base"),
      get_lm_metrics(M1) %>% dplyr::mutate(model = "M1: + frailty_count_2 (weak+slow)"),
      get_lm_metrics(M2) %>% dplyr::mutate(model = "M2: + frailty_count_3_balance (weak+slow+bal)")
    ) %>%
      dplyr::select(model, dplyr::everything())
    
    metrics <- metrics %>%
      dplyr::mutate(
        delta_r2_vs_M0 = r2 - metrics$r2[metrics$model == "M0: base"],
        delta_adj_r2_vs_M0 = adj_r2 - metrics$adj_r2[metrics$model == "M0: base"]
      )
    
    # Nested tests only against base model (M1 and M2 are not nested with each other).
    lrt_01 <- anova(M0, M1)
    lrt_02 <- anova(M0, M2)
    
    # 10B.4 Kertoimet (M1 & M2) taulukkoon
    tidy_lm <- function(mod, model_name) {
      co <- summary(mod)$coefficients
      ci <- suppressMessages(confint(mod))
      out <- tibble::as_tibble(co, rownames = "term") %>%
        dplyr::rename(
          estimate = Estimate,
          se = `Std. Error`,
          statistic = `t value`,
          p_value = `Pr(>|t|)`
        ) %>%
        dplyr::left_join(
          tibble::as_tibble(ci, rownames = "term") %>%
            dplyr::rename(conf_low = `2.5 %`, conf_high = `97.5 %`),
          by = "term"
        ) %>%
        dplyr::mutate(model = model_name) %>%
        dplyr::select(model, term, estimate, se, conf_low, conf_high, p_value)
      out
    }
    
    coef_tab <- dplyr::bind_rows(
      tidy_lm(M1, "M1"),
      tidy_lm(M2, "M2")
    )
    
    # 10B.5 Tallenna taulukot K15.3.-tyyliin
    save_table_csv_html(metrics, "K15.3._balance_model_metrics")
    save_table_csv_html(coef_tab, "K15.3._balance_model_coefficients")
    
    # 10B.6 Tallenna nested-vertailut base-mallia vastaan
    lrt_tab_01 <- tibble::as_tibble(lrt_01, rownames = "model") %>%
      dplyr::rename(df = Df, rss = RSS, ss = `Sum of Sq`, f = F, p_value = `Pr(>F)`)
    lrt_tab_02 <- tibble::as_tibble(lrt_02, rownames = "model") %>%
      dplyr::rename(df = Df, rss = RSS, ss = `Sum of Sq`, f = F, p_value = `Pr(>F)`)
    save_table_csv_html(lrt_tab_01, "K15.3._balance_model_nested_test_M0_vs_M1")
    save_table_csv_html(lrt_tab_02, "K15.3._balance_model_nested_test_M0_vs_M2")
    
    message(
      "K15.3.: Model comparison (non-nested M1 vs M2): ",
      "AIC M0=", round(AIC(M0), 3), ", M1=", round(AIC(M1), 3), ", M2=", round(AIC(M2), 3),
      "; BIC M0=", round(BIC(M0), 3), ", M1=", round(BIC(M1), 3), ", M2=", round(BIC(M2), 3)
    )
    message("K15.3.: Mallivertailu valmis. Katso outputs: K15.3._balance_model_metrics / coefficients / nested_test(M0_vs_M1, M0_vs_M2).")
  }
}

# ==============================================================================
# 11. Save Analysis Data for K16
# ==============================================================================
# Tallenna analysis_data K16:ta varten (sisältää kaikki frailty-muuttujat)
rdata_path <- file.path(outputs_dir, "K15.3._frailty_analysis_data.RData")
save(analysis_data, file = rdata_path)
message("K15.3.: analysis_data tallennettu: ", basename(rdata_path))

message("K15.3.: Fried-inspired physical frailty proxy rakennettu ja perusjakaumat + FOF-vertailut tallennettu.")

# ==============================================================================
# 12. Loppukommentit (Doc-Blokki)
# ==============================================================================
# (alkuperäinen doc-blokki jätetty ennalleen; huomaa että balance-laajennus on lisätty osioon 05B ja 10B)
