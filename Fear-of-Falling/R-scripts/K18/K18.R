#!/usr/bin/env Rscript
# ==============================================================================
# K18 - Frailty Change Contrasts (Δ and ΔΔ) with emmeans
# File tag: K18.R
# Purpose: Builds on K16 frailty models to produce explicit 0→12 month CHANGE
#          estimates (Δ) and change-difference contrasts (ΔΔ) between frailty
#          groups and FOF status using mixed models + emmeans contrasts; includes
#          ML-based LRT comparisons and comprehensive reporting (tables/plots/texts)
#          + manifest + sessionInfo following K16 conventions
#
# Outcome: Composite_Z over time (mixed models for change contrasts)
# Predictors: FOF_status (factor: "nonFOF"/"FOF"), frailty_cat_3 (factor: "Robust"/"Pre-frail"/"Frail")
# Moderator/interaction: time_f × frailty_cat_3 (M1), time_f × FOF_status × frailty_cat_3 (M2)
# Grouping variable: ID (random intercept for mixed models)
# Covariates: age, sex, BMI
#
# Required vars (K15 RData - DO NOT INVENT; must be present in K15 output):
# ID (or Jnro/NRO), FOF_status (or FOF_status_factor), Composite_Z0, Composite_Z12 (ToimintaKykySummary2),
# age, sex, BMI, frailty_cat_3, frailty_cat_3_obj, frailty_cat_3_2plus, frailty_score_3
#
# Required vars (analysis df - after harmonization in script):
# ID, FOF_status (factor: "nonFOF"/"FOF"), Composite_Z0, Composite_Z12, Delta_Composite_Z (12-month change),
# age, sex (factor: "female"/"male"), BMI, frailty_cat_3 (factor: "Robust"/"Pre-frail"/"Frail"),
# frailty_score_3 (continuous), time_f (factor: "0"/"12")
#
# Mapping (K15 RData -> analysis; keep minimal + explicit):
# Jnro/NRO -> ID (harmonized in script)
# ToimintaKykySummary0 -> Composite_Z0 (baseline)
# ToimintaKykySummary2 -> Composite_Z12 (12 months follow-up)
# FOF_status (0/1 or factor) -> FOF_status (factor: "nonFOF"/"FOF", releveled)
# sex (0/1) -> sex (factor: "female"/"male", releveled)
# frailty_cat_3 (character/factor) -> frailty_cat_3 (factor: "Robust"/"Pre-frail"/"Frail", releveled)
# frailty_count_3 -> frailty_score_3
# Delta_Composite_Z = Composite_Z12 - Composite_Z0 (derived, 12-month change)
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: 20251124 (set for reproducibility)
#
# Outputs + manifest:
# - script_label: K18 (canonical)
# - outputs dir: R-scripts/K18/outputs/K18/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load frailty-augmented data from K15 (K15_frailty_analysis_data.RData)
# 03) Harmonize variable names (ID, Composite_Z0/Z12, FOF_status, sex, frailty_cat_3)
# 04) Check required frailty variables (frailty_cat_3, frailty_score_3, etc.)
# 05) Derive Delta_Composite_Z = Composite_Z12 - Composite_Z0 (12-month change)
# 06) Prepare long-format data for mixed models (time_f = 0/12)
# 07) Fit M0/M1/M2 models (REML=TRUE for reporting, ML for LRT)
# 08) Run ML-based LRT comparisons (M0_ml vs M1_ml; M1_ml vs M2_ml)
# 09) Compute emmeans contrasts: Δ(12-0), ΔΔ frailty, ΔΔ FOF, ΔΔΔ (if M2)
# 10) Create Word tables (Δ, ΔΔ, model comparisons, effect sizes)
# 11) Create PNG plots (change contrasts forest, predicted trajectories)
# 12) Generate Results text (English + Finnish, referencing SD units)
# 13) Save all artifacts to outputs/K18/
# 14) Append manifest row per artifact
# 15) Save sessionInfo to manifest/
# 16) EOF marker
# ==============================================================================
#
suppressPackageStartupMessages({
  library(here)
  library(dplyr)
})

# --- Standard init (MANDATORY) -----------------------------------------------
# Derive script_label from --file, supporting file tags like: K18.V1_name.R
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K18"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)  # canonical SCRIPT_ID
if (is.na(script_label) || script_label == "") script_label <- "K18"

# Source helper functions (io, checks, modeling, reporting)
rm(list = ls(pattern = "^(save_|init_paths$|append_manifest$|manifest_row$)"),
   envir = .GlobalEnv)

source(here("R","functions","io.R"))
source(here("R","functions","checks.R"))
source(here("R","functions","modeling.R"))
source(here("R","functions","reporting.R"))

# init_paths() must set outputs_dir + manifest_path (+ options fof.*)
paths <- init_paths(script_label)

# seed (set for reproducibility)
set.seed(20251124)

# Get paths from init_paths (already called in header)
outputs_dir   <- getOption("fof.outputs_dir")
manifest_path <- getOption("fof.manifest_path")
output_dir    <- outputs_dir  # alias for compatibility

suppressPackageStartupMessages({
  library(tidyr)
  library(lme4)
  library(lmerTest)
  library(broom)
  library(broom.mixed)
  library(flextable)
  library(officer)
  library(ggplot2)

  # Check emmeans availability (CRITICAL for deliverable)
  if (!requireNamespace("emmeans", quietly = TRUE)) {
    message("WARNING: emmeans not installed. This is REQUIRED for K18 deliverable.")
    message("Install it with: install.packages('emmeans')")
    message("Checking for marginaleffects fallback...")

    if (!requireNamespace("marginaleffects", quietly = TRUE)) {
      stop("FATAL: Neither emmeans nor marginaleffects is available.\n",
           "K18 requires emmeans for change contrasts. Please install:\n",
           "  install.packages('emmeans')")
    } else {
      message("marginaleffects available but emmeans is preferred for K18.\n",
              "Proceeding with emmeans required...")
      stop("Please install emmeans: install.packages('emmeans')")
    }
  }
  library(emmeans)

  # Optional: performance/partR2 for effect sizes
  has_performance <- requireNamespace("performance", quietly = TRUE)
  has_partR2 <- requireNamespace("partR2", quietly = TRUE)

  if (!has_performance) {
    message("INFO: 'performance' not available. R² will be computed manually if needed.")
  }
  if (!has_partR2) {
    message("INFO: 'partR2' not available. Partial R² will be skipped.")
  }
})

library(conflicted)
conflicted::conflict_prefer("select", "dplyr")
conflicted::conflict_prefer("filter", "dplyr")
conflicted::conflict_prefer("recode", "dplyr")
conflicted::conflict_prefer("lmer", "lmerTest")

# ==============================================================================
# FORMATTING HELPERS & MULTIPLICITY POLICY
# ==============================================================================

# P-value formatting: unified across all tables/plots/texts
p_fmt <- function(p) {
  ifelse(is.na(p), NA_character_,
         ifelse(p < 0.001, "<0.001", sprintf("%.3f", p)))
}

# Confidence interval formatting
ci_fmt <- function(lo, hi) {
  sprintf("[%.3f, %.3f]", lo, hi)
}

# Multiplicity adjustment policies
primary_adjust <- "sidak"       # For M1 primary contrasts (emmeans auto-switches from tukey for interaction contrasts)
exploratory_adjust <- "holm"    # For M2 exploratory contrasts

message("\n", strrep("=", 80))
message("K18: FRAILTY CHANGE CONTRASTS (Δ and ΔΔ) WITH EMMEANS")
message(strrep("=", 80), "\n")

# ==============================================================================
# 01. Load Data with Frailty Variables
# ==============================================================================

message("01) Loading analysis data with frailty variables from K15...")

force_reload <- TRUE
if (force_reload && exists("analysis_data")) rm(analysis_data)

# Check if analysis_data already exists in environment
if (!exists("analysis_data")) {
  # Try to load from K15 RData file
  k15_rdata <- here::here("R-scripts", "K15", "outputs",
                         "K15_frailty_analysis_data.RData")

  if (file.exists(k15_rdata)) {
    load(k15_rdata)
    message("✓ Loaded analysis_data from: ", k15_rdata)
  } else {
    # Run K15.R to generate the data
    message("Running K15.R to generate frailty variables...")
    source(here::here("R-scripts", "K15", "K15.R"))
  }
}

# ==============================================================================
# 02. Harmonize Variable Names (K16 style)
# ==============================================================================

message("\n02) Harmonizing variable names...")

# ID (K11/K9-datassa usein Jnro)
if (!("ID" %in% names(analysis_data))) {
  if ("Jnro" %in% names(analysis_data)) {
    analysis_data <- analysis_data %>% mutate(ID = Jnro)
  } else if ("NRO" %in% names(analysis_data)) {
    analysis_data <- analysis_data %>% mutate(ID = NRO)
  } else {
    stop("K18: ID puuttuu eikä löytynyt Jnro/NRO-korviketta.")
  }
}

# Composite baseline + follow-up: mapataan ToimintaKykySummary0/2 -> Composite_Z0/12
if (!("Composite_Z0" %in% names(analysis_data))) {
  if ("ToimintaKykySummary0" %in% names(analysis_data)) {
    analysis_data <- analysis_data %>% mutate(Composite_Z0 = ToimintaKykySummary0)
  } else {
    stop("K18: Composite_Z0 puuttuu eikä löytynyt ToimintaKykySummary0-korviketta.")
  }
}

if (!("Composite_Z12" %in% names(analysis_data))) {
  # K16 mapping: ToimintaKykySummary2 = 12 months
  if ("ToimintaKykySummary2" %in% names(analysis_data)) {
    analysis_data <- analysis_data %>% mutate(Composite_Z12 = ToimintaKykySummary2)
  } else if ("Composite_Z3" %in% names(analysis_data)) {
    # Fallback: Composite_Z3 may exist as legacy 12-month
    message("INFO: Composite_Z12 not found, using Composite_Z3 as 12-month follow-up")
    analysis_data <- analysis_data %>% mutate(Composite_Z12 = Composite_Z3)
  } else if ("Composite_Z2" %in% names(analysis_data)) {
    # Another fallback
    message("INFO: Composite_Z12 not found, using Composite_Z2 as 12-month follow-up")
    analysis_data <- analysis_data %>% mutate(Composite_Z12 = Composite_Z2)
  } else {
    stop("K18: Composite_Z12 puuttuu eikä löytynyt ToimintaKykySummary2/Composite_Z3/Composite_Z2-korviketta.")
  }
}

# Backward compatibility: create Composite_Z3 alias if legacy code needs it
if (!("Composite_Z3" %in% names(analysis_data)) && ("Composite_Z12" %in% names(analysis_data))) {
  analysis_data <- analysis_data %>% mutate(Composite_Z3 = Composite_Z12)
}

# Frailty categorical: fix if needed
if ("frailty_count_3" %in% names(analysis_data) &&
    all(is.na(analysis_data$frailty_cat_3))) {

  analysis_data <- analysis_data %>%
    mutate(
      frailty_cat_3 = case_when(
        is.na(frailty_count_3) ~ NA_character_,
        frailty_count_3 == 0   ~ "robust",
        frailty_count_3 == 1   ~ "pre-frail",
        frailty_count_3 >= 2   ~ "frail"
      ),
      frailty_cat_3 = factor(frailty_cat_3, levels = c("robust","pre-frail","frail"))
    )
}

# Frailty continuous score: K15 tuottaa frailty_count_3 -> käytetään sitä score:na
if (!("frailty_score_3" %in% names(analysis_data))) {
  if ("frailty_count_3" %in% names(analysis_data)) {
    analysis_data <- analysis_data %>% mutate(frailty_score_3 = as.numeric(frailty_count_3))
  } else {
    stop("K18: frailty_score_3 puuttuu eikä löytynyt frailty_count_3-korviketta.")
  }
}

# FOF_status: oletus 0 = nonFOF, 1 = FOF
if ("FOF_status_factor" %in% names(analysis_data)) {
  analysis_data <- analysis_data %>%
    mutate(FOF_status = droplevels(FOF_status_factor))
} else {
  # fallback (jos factor puuttuu): tunnista myös "nonFOF"
  analysis_data <- analysis_data %>%
    mutate(
      FOF_status = trimws(as.character(FOF_status)),
      FOF_status = case_when(
        FOF_status %in% c("nonFOF","No_FOF","No FOF","NoFOF","0","FALSE","False") ~ "nonFOF",
        FOF_status %in% c("FOF","1","TRUE","True") ~ "FOF",
        TRUE ~ NA_character_
      ),
      FOF_status = factor(FOF_status, levels = c("nonFOF","FOF"))
    )
}

# sex: tee sama (0/1 -> female/male)
analysis_data <- analysis_data %>%
  mutate(
    sex = trimws(as.character(sex)),
    sex = case_when(
      sex %in% c("0", "female", "Female", "F") ~ "female",
      sex %in% c("1", "male", "Male", "M") ~ "male",
      TRUE ~ sex
    ),
    sex = factor(sex)
  )

# Fix frailty labels to standardized format
fix_frailty <- function(x){
  x0 <- tolower(trimws(as.character(x)))
  out <- dplyr::case_when(
    x0 %in% c("robust") ~ "Robust",
    grepl("pre", x0) ~ "Pre-frail",
    x0 %in% c("frail") ~ "Frail",
    TRUE ~ NA_character_
  )
  factor(out, levels = c("Robust","Pre-frail","Frail"))
}

analysis_data <- analysis_data %>%
  mutate(
    frailty_cat_3       = fix_frailty(frailty_cat_3),
    frailty_cat_3_obj   = fix_frailty(frailty_cat_3_obj),
    frailty_cat_3_2plus = fix_frailty(frailty_cat_3_2plus)
  )

# Verify required frailty variables exist
required_vars <- c("frailty_cat_3", "frailty_score_3", "FOF_status",
                   "Composite_Z0", "Composite_Z12", "ID", "age", "sex", "BMI")

missing_vars <- setdiff(required_vars, names(analysis_data))
if (length(missing_vars) > 0) {
  stop("Missing required variables: ", paste(missing_vars, collapse = ", "))
}

message("✓ All required variables present")
message("  - frailty_cat_3: ", sum(!is.na(analysis_data$frailty_cat_3)), " valid cases")
message("  - Composite_Z0: ", sum(!is.na(analysis_data$Composite_Z0)), " valid cases")
message("  - Composite_Z12: ", sum(!is.na(analysis_data$Composite_Z12)), " valid cases")

# ==============================================================================
# 03. Derive Delta and Create Long Format
# ==============================================================================

message("\n03) Deriving Delta_Composite_Z and creating long-format data...")

# Derive Delta
analysis_data <- analysis_data %>%
  mutate(
    Delta_Composite_Z = Composite_Z12 - Composite_Z0  # 12-month change
  )

# Create long-format data for mixed models
analysis_long <- analysis_data %>%
  dplyr::select(
    ID, FOF_status, frailty_cat_3, frailty_cat_3_obj, frailty_cat_3_2plus,
    frailty_score_3, age, sex, BMI,
    Composite_Z0, Composite_Z12
  ) %>%
  pivot_longer(
    cols = c(Composite_Z0, Composite_Z12),
    names_to = "timepoint",
    values_to = "Composite_Z"
  ) %>%
  mutate(
    time_months = ifelse(timepoint == "Composite_Z0", 0, 12),
    time_f = factor(time_months, levels = c(0, 12), labels = c("0", "12"))
  )

# Set reference levels for factors (CRITICAL for emmeans contrasts)
analysis_long <- analysis_long %>%
  mutate(
    time_f        = relevel(time_f, ref = "0"),
    FOF_status    = relevel(FOF_status, ref = "nonFOF"),
    frailty_cat_3 = relevel(frailty_cat_3, ref = "Robust"),
    sex           = relevel(sex, ref = "female")
  )

# ==============================================================================
# FACTOR-LEVEL SANITY CHECKS
# ==============================================================================

message("\nFACTOR-LEVEL SANITY CHECKS...")

stopifnot(
  "time_f must have levels: '0', '12'" =
    identical(levels(analysis_long$time_f), c("0", "12"))
)

stopifnot(
  "FOF_status must have levels: 'nonFOF', 'FOF'" =
    identical(levels(analysis_long$FOF_status), c("nonFOF", "FOF"))
)

stopifnot(
  "frailty_cat_3 must have levels: 'Robust', 'Pre-frail', 'Frail'" =
    identical(levels(analysis_long$frailty_cat_3), c("Robust", "Pre-frail", "Frail"))
)

message("✓ Factor levels verified")

# QC checks for long data
message("QC: Checking long-format data integrity...")

# Check ID × time uniqueness
id_time_counts <- analysis_long %>%
  count(ID, time_f) %>%
  filter(n > 1)

if (nrow(id_time_counts) > 0) {
  stop("QC FAIL: Non-unique ID × time_f combinations found. Check data structure.")
}

# Check factor levels
stopifnot(
  "time_f must have levels: 0, 12" = all(levels(analysis_long$time_f) == c("0", "12")),
  "FOF_status must have levels: nonFOF, FOF" = all(levels(analysis_long$FOF_status) == c("nonFOF", "FOF")),
  "frailty_cat_3 must have levels: Robust, Pre-frail, Frail" = all(levels(analysis_long$frailty_cat_3) == c("Robust", "Pre-frail", "Frail")),
  "sex must have female as first level" = levels(analysis_long$sex)[1] == "female"
)

# Check for missing FOF_status
fof_na_count <- sum(is.na(analysis_long$FOF_status))
if (fof_na_count > 0) {
  message("WARNING: ", fof_na_count, " rows with missing FOF_status will be excluded from analysis")
}

message("✓ QC checks passed")
message("  - Long format: ", nrow(analysis_long), " observations (",
        length(unique(analysis_long$ID)), " participants × 2 timepoints)")
message("  - time_f levels: ", paste(levels(analysis_long$time_f), collapse = ", "))
message("  - FOF_status levels: ", paste(levels(analysis_long$FOF_status), collapse = ", "))
message("  - frailty_cat_3 levels: ", paste(levels(analysis_long$frailty_cat_3), collapse = ", "))

# ==============================================================================
# 04. Fit Mixed Models (REML for reporting)
# ==============================================================================

message("\n04) Fitting mixed models with REML=TRUE...")

# M0: time × FOF + frailty_cat_3 (no time × frailty interaction)
message("  - Fitting M0: time × FOF + frailty_cat_3...")
mod_M0 <- lmer(
  Composite_Z ~ time_f * FOF_status + frailty_cat_3 + age + sex + BMI + (1 | ID),
  data = analysis_long,
  REML = TRUE
)

# M1: time × FOF + time × frailty_cat_3 (add time × frailty)
message("  - Fitting M1: time × FOF + time × frailty_cat_3...")
mod_M1 <- lmer(
  Composite_Z ~ time_f * FOF_status + time_f * frailty_cat_3 + age + sex + BMI + (1 | ID),
  data = analysis_long,
  REML = TRUE
)

# M2: time × FOF × frailty_cat_3 (3-way interaction)
message("  - Fitting M2: time × FOF × frailty_cat_3 (3-way)...")
mod_M2 <- lmer(
  Composite_Z ~ time_f * FOF_status * frailty_cat_3 + age + sex + BMI + (1 | ID),
  data = analysis_long,
  REML = TRUE
)

# Optional: continuous frailty score
message("  - Fitting optional continuous model: time × FOF + time × frailty_score_3...")
mod_M_cont <- lmer(
  Composite_Z ~ time_f * FOF_status + time_f * frailty_score_3 + age + sex + BMI + (1 | ID),
  data = analysis_long,
  REML = TRUE
)

message("✓ REML models fitted")

# ==============================================================================
# 05. ML-based LRT Comparisons
# ==============================================================================

message("\n05) Running ML-based LRT comparisons...")

# Refit models with ML for LRT
message("  - Refitting models with ML=FALSE (REML=FALSE)...")
mod_M0_ml <- update(mod_M0, REML = FALSE)
mod_M1_ml <- update(mod_M1, REML = FALSE)
mod_M2_ml <- update(mod_M2, REML = FALSE)

# LRT: M0 vs M1 (tests time × frailty_cat_3 addition)
lrt_M0_M1 <- anova(mod_M0_ml, mod_M1_ml)
message("  - LRT M0 vs M1 (time × frailty): ",
        "χ²(", lrt_M0_M1$Df[2], ") = ", sprintf("%.2f", lrt_M0_M1$Chisq[2]),
        ", p = ", sprintf("%.4f", lrt_M0_M1$`Pr(>Chisq)`[2]))

# LRT: M1 vs M2 (tests 3-way interaction addition)
lrt_M1_M2 <- anova(mod_M1_ml, mod_M2_ml)
message("  - LRT M1 vs M2 (3-way): ",
        "χ²(", lrt_M1_M2$Df[2], ") = ", sprintf("%.2f", lrt_M1_M2$Chisq[2]),
        ", p = ", sprintf("%.4f", lrt_M1_M2$`Pr(>Chisq)`[2]))

# Model comparison table (AIC/BIC from REML for reporting, but note LRT from ML)
model_comparison <- data.frame(
  Model = c("M0: time×FOF + frailty",
            "M1: time×FOF + time×frailty",
            "M2: time×FOF×frailty (3-way)"),
  AIC_REML = c(AIC(mod_M0), AIC(mod_M1), AIC(mod_M2)),
  BIC_REML = c(BIC(mod_M0), BIC(mod_M1), BIC(mod_M2)),
  AIC_ML = c(AIC(mod_M0_ml), AIC(mod_M1_ml), AIC(mod_M2_ml)),
  BIC_ML = c(BIC(mod_M0_ml), BIC(mod_M1_ml), BIC(mod_M2_ml))
)

# Add LRT p-values
model_comparison$LRT_vs_previous <- c(
  NA,  # M0 is baseline
  lrt_M0_M1$`Pr(>Chisq)`[2],
  lrt_M1_M2$`Pr(>Chisq)`[2]
)

message("✓ ML-based LRT completed")

# ==============================================================================
# 06. emmeans Change Contrasts (Δ and ΔΔ) - PRIMARY (M1) & EXPLORATORY (M2)
# ==============================================================================

message("\n06) Computing emmeans change contrasts...")

# ------------------------------------------------------------------------------
# PRIMARY CONTRASTS FROM M1 (common-by-design; no 3-way interaction)
# ------------------------------------------------------------------------------

message("\nPRIMARY CONTRASTS (M1 - common-by-design):")
message("  M1 does NOT include time×FOF×frailty, so:")
message("  - Frailty ΔΔ is common across FOF groups (not stratified)")
message("  - FOF ΔΔ is common across frailty levels (not stratified)")

# P1: Δ(12-0) for each frailty×FOF cell (descriptive, from M1)
message("\n  P1: Computing Δ(12-0) within each frailty×FOF cell (M1)...")
emm_M1 <- emmeans(mod_M1, ~ time_f | frailty_cat_3 * FOF_status)

# Explicit contrast: 12 - 0 within each cell
chg_M1 <- contrast(emm_M1,
                   method = list("12-0" = c(-1, 1)),
                   by = c("frailty_cat_3", "FOF_status"))
chg_M1_df <- as.data.frame(summary(chg_M1, infer = TRUE))

# P2: PRIMARY ΔΔ frailty (common across FOF groups) — adjust = primary_adjust
message("  P2: Computing PRIMARY ΔΔ frailty (common; adjustment via primary_adjust)...")

emm_M1_frailty <- emmeans(mod_M1, ~ time_f * frailty_cat_3)

dd_frailty_M1 <- contrast(
  emm_M1_frailty,
  interaction = c("consec", "pairwise"),  # (12-0) then pairwise between frailty
  adjust = primary_adjust
)

dd_frailty_M1_df <- as.data.frame(summary(dd_frailty_M1, infer = TRUE))
names(dd_frailty_M1_df)[names(dd_frailty_M1_df) == "frailty_cat_3_pairwise"] <- "contrast"

# --- HARD QA GUARDS (fail fast) ---
stopifnot("P2 must have exactly 3 pairwise rows" = nrow(dd_frailty_M1_df) == 3)
stopifnot("P2 estimate must not be NA" = !anyNA(dd_frailty_M1_df$estimate))
stopifnot("P2 contrast labels must exist" = "contrast" %in% names(dd_frailty_M1_df))

# P3: ΔΔ FOF (common across frailty levels)
message("  P3: Computing PRIMARY ΔΔ FOF (common; no adjustment)...")
# Get emmeans at time × FOF (marginal over frailty, averaged by M1 design)
emm_M1_time_fof <- emmeans(mod_M1, ~ time_f * FOF_status)

# Compute interaction contrast: (FOF,12 - FOF,0) - (nonFOF,12 - nonFOF,0)
# This is the time×FOF interaction effect (ΔΔ FOF)
# emmeans grid order is typically: (time_f, FOF_status) combinations
# Assuming factor order: time_f = ("0", "12"), FOF_status = ("nonFOF", "FOF")
# Grid: [0×nonFOF, 12×nonFOF, 0×FOF, 12×FOF]
# ΔΔ = (12×FOF - 0×FOF) - (12×nonFOF - 0×nonFOF)
#    = 0×nonFOF - 12×nonFOF + 0×FOF + 12×FOF
#    = [+1, -1, -1, +1]
dd_fof_M1 <- contrast(emm_M1_time_fof,
                      method = list("FOF ΔΔ (time×FOF interaction)" = c(1, -1, -1, 1)),
                      adjust = "none")
dd_fof_M1_df <- as.data.frame(summary(dd_fof_M1, infer = TRUE))

message("✓ PRIMARY contrasts computed (M1)")

# ------------------------------------------------------------------------------
# EXPLORATORY CONTRASTS FROM M2 (stratified; always computed)
# ------------------------------------------------------------------------------

message("\nEXPLORATORY CONTRASTS (M2 - stratified):")
message("  M2 INCLUDES time×FOF×frailty, allowing stratified contrasts")
message("  These are ALWAYS computed as exploratory (regardless of LRT significance)")

# E1: Δ(12-0) for each frailty×FOF cell (from M2; same as M1 structure but different model)
message("\n  E1: Computing Δ(12-0) within each frailty×FOF cell (M2)...")
emm_M2 <- emmeans(mod_M2, ~ time_f | frailty_cat_3 * FOF_status)
chg_M2 <- contrast(emm_M2,
                   method = list("12-0" = c(-1, 1)),
                   by = c("frailty_cat_3", "FOF_status"))
chg_M2_df <- as.data.frame(summary(chg_M2, infer = TRUE))

# E2: ΔΔ frailty STRATIFIED by FOF (exploratory)
message("  E2: Computing EXPLORATORY ΔΔ frailty (stratified by FOF; Holm adjustment)...")
dd_frailty_M2 <- contrast(chg_M2, method = "pairwise", by = "FOF_status", adjust = exploratory_adjust)
dd_frailty_M2_df <- as.data.frame(summary(dd_frailty_M2, infer = TRUE))

# E3: ΔΔ FOF STRATIFIED by frailty (exploratory)
message("  E3: Computing EXPLORATORY ΔΔ FOF (stratified by frailty; Holm adjustment)...")
# For each frailty level, compute time×FOF interaction
# Get emmeans at time × FOF × frailty from M2
emm_M2_time_fof_frailty <- emmeans(mod_M2, ~ time_f * FOF_status | frailty_cat_3)

# Compute interaction contrasts within each frailty level
# For each frailty: (FOF,12 - FOF,0) - (nonFOF,12 - nonFOF,0)
# Within each by-group, grid is: [0×nonFOF, 12×nonFOF, 0×FOF, 12×FOF]
# Interaction = [+1, -1, -1, +1]
dd_fof_M2 <- contrast(emm_M2_time_fof_frailty,
                      method = list("FOF ΔΔ (time×FOF interaction)" = c(1, -1, -1, 1)),
                      by = "frailty_cat_3",
                      adjust = exploratory_adjust)
dd_fof_M2_df <- as.data.frame(summary(dd_fof_M2, infer = TRUE))

message("✓ EXPLORATORY contrasts computed (M2)")

# Legacy names for compatibility (use M1 for primary)
chg_df <- chg_M1_df
dd_frailty_df <- dd_frailty_M1_df
dd_fof_df <- dd_fof_M1_df
emm <- emm_M1
chg <- chg_M1
dd_frailty <- dd_frailty_M1
dd_fof <- dd_fof_M1

message("\n✓ All emmeans contrasts computed (PRIMARY + EXPLORATORY)")

# ==============================================================================
# 07. Effect Size Calculations (Optional)
# ==============================================================================

message("\n07) Computing effect sizes...")

# Note: Composite_Z is already in Z-score units (SD units)
# Therefore, Δ and ΔΔ are already standardized effect sizes (ΔZ/ΔΔZ)

effect_size_note <- paste0(
  "Effect Size Interpretation:\n",
  "- Composite_Z is a z-scored outcome (standardized to SD units)\n",
  "- Δ(12-0) estimates represent change in SD units (ΔZ)\n",
  "- ΔΔ estimates represent difference-in-differences in SD units (ΔΔZ)\n",
  "- These are already standardized effect sizes (no further standardization needed)\n"
)

message(effect_size_note)

# Optional: R² partitioning (if performance/partR2 available)
if (has_performance) {
  message("  - Computing R² (Nakagawa) with performance package...")
  r2_M0 <- performance::r2_nakagawa(mod_M0)
  r2_M1 <- performance::r2_nakagawa(mod_M1)
  r2_M2 <- performance::r2_nakagawa(mod_M2)

  r2_table <- data.frame(
    Model = c("M0", "M1", "M2"),
    R2_marginal = c(r2_M0$R2_marginal, r2_M1$R2_marginal, r2_M2$R2_marginal),
    R2_conditional = c(r2_M0$R2_conditional, r2_M1$R2_conditional, r2_M2$R2_conditional)
  )
  message("✓ R² computed")
} else {
  r2_table <- NULL
  message("  - performance not available, skipping R²")
}

if (has_partR2) {
  message("  - Computing partial R² with partR2 package...")
  # This is computationally intensive, skip for now
  message("  - partR2 available but skipped (computationally intensive)")
  partR2_results <- NULL
} else {
  partR2_results <- NULL
  message("  - partR2 not available, skipping partial R²")
}

# ==============================================================================
# 08. Create Word Tables (PRIMARY + EXPLORATORY)
# ==============================================================================

message("\n08) Creating Word tables...")

# ------------------------------------------------------------------------------
# PRIMARY TABLES (M1 - common-by-design)
# ------------------------------------------------------------------------------

# Table P1: Δ(12-0) for each frailty × FOF cell (M1)
message("  - Creating Table P1 (PRIMARY Δ from M1)...")
table_P1 <- chg_M1_df %>%
  mutate(
    CI = ci_fmt(lower.CL, upper.CL),
    p_formatted = p_fmt(p.value)
  ) %>%
  select(Frailty = frailty_cat_3, FOF = FOF_status,
         Contrast = contrast, Estimate = estimate, SE, CI,
         t = t.ratio, df, p = p_formatted)

ft_table_P1 <- flextable(table_P1) %>%
  set_caption(paste0(
    "Table P1: PRIMARY Change in Composite Physical Function (Δ, 0→12 months) by Frailty and FOF Status (M1)\n",
    "Note: From M1 (no 3-way interaction); descriptive within-cell changes."
  )) %>%
  autofit() %>%
  theme_booktabs()

# Table P2: PRIMARY ΔΔ frailty (common across FOF groups)
message("  - Creating Table P2 (PRIMARY ΔΔ frailty - common)...")

# Check which CI column names are present (depends on contrast method)
has_lower_CL <- "lower.CL" %in% names(dd_frailty_M1_df)
has_asymp_LCL <- "asymp.LCL" %in% names(dd_frailty_M1_df)

table_P2 <- dd_frailty_M1_df %>%
  mutate(
    CI = if (has_lower_CL) {
      ci_fmt(lower.CL, upper.CL)
    } else if (has_asymp_LCL) {
      ci_fmt(asymp.LCL, asymp.UCL)
    } else {
      "CI not available"
    },
    p_formatted = p_fmt(p.value)
  ) %>%
  select(Contrast = contrast, Estimate = estimate, SE,  CI,
         df, p = p_formatted)

ft_table_P2 <- flextable(table_P2) %>%
  set_caption(paste0(
    "Table P2: PRIMARY Frailty-Level Differences in Change (ΔΔ frailty) - COMMON ACROSS FOF GROUPS (M1)\n",
    "Note: M1 design → frailty ΔΔ is common (not stratified by FOF). Sidak adjustment applied (emmeans auto-switched from Tukey for interaction contrasts).\n",
    "Adjustment: ", primary_adjust
  )) %>%
  autofit() %>%
  theme_booktabs()

# Table P3: PRIMARY ΔΔ FOF (common across frailty levels)
message("  - Creating Table P3 (PRIMARY ΔΔ FOF - common)...")
table_P3 <- dd_fof_M1_df %>%
  mutate(
    CI = ci_fmt(lower.CL, upper.CL),
    p_formatted = p_fmt(p.value)
  ) %>%
  select(Contrast = contrast, Estimate = estimate, SE, CI,
         t = t.ratio, df, p = p_formatted)

ft_table_P3 <- flextable(table_P3) %>%
  set_caption(paste0(
    "Table P3: PRIMARY FOF Difference in Change (ΔΔ FOF) - COMMON ACROSS FRAILTY LEVELS (M1)\n",
    "Note: M1 design → FOF ΔΔ is common (not stratified by frailty). No adjustment (single contrast)."
  )) %>%
  autofit() %>%
  theme_booktabs()

# Table P4: Continuous frailty model (mod_M_cont) - time_f12:frailty_score_3
message("  - Creating Table P4 (Continuous frailty interaction from M_cont)...")
# Extract time_f12:frailty_score_3 coefficient from mod_M_cont summary
mod_M_cont_summary <- summary(mod_M_cont)
coef_table <- as.data.frame(coef(mod_M_cont_summary))
coef_table$term <- rownames(coef_table)

# Find the time_f12:frailty_score_3 term
target_term <- "time_f12:frailty_score_3"
if (target_term %in% coef_table$term) {
  p4_row <- coef_table[coef_table$term == target_term, ]
  
  # Calculate 95% CI using t-distribution (Wald-based)
  df_val <- p4_row$df
  ci_lower <- p4_row$Estimate - qt(0.975, df_val) * p4_row$`Std. Error`
  ci_upper <- p4_row$Estimate + qt(0.975, df_val) * p4_row$`Std. Error`
  
  table_P4 <- data.frame(
    Term = target_term,
    Estimate = p4_row$Estimate,
    SE = p4_row$`Std. Error`,
    CI = ci_fmt(ci_lower, ci_upper),
    t = p4_row$`t value`,
    df = df_val,
    p = p_fmt(p4_row$`Pr(>|t|)`)
  )
  
  ft_table_P4 <- flextable(table_P4) %>%
    set_caption(paste0(
      "Table P4: Continuous Frailty Proxy Interaction (M_cont)\n",
      "Note: Interaction effect of time×frailty_score_3 (continuous). Per +1 frailty point, 12-month change differs by Estimate SD units."
    )) %>%
    autofit() %>%
    theme_booktabs()
    
  # Store for Results text
  p4_estimate <- p4_row$Estimate
  p4_ci_lower <- ci_lower
  p4_ci_upper <- ci_upper
  p4_p <- p4_row$`Pr(>|t|)`
} else {
  warning("Could not find time_f12:frailty_score_3 in mod_M_cont. Creating placeholder table.")
  table_P4 <- data.frame(Note = "time_f12:frailty_score_3 not found in model")
  ft_table_P4 <- flextable(table_P4) %>%
    set_caption("Table P4: Continuous Frailty Proxy (NOT AVAILABLE)") %>%
    autofit() %>%
    theme_booktabs()
  p4_estimate <- NA
  p4_ci_lower <- NA
  p4_ci_upper <- NA
  p4_p <- NA
}

# ------------------------------------------------------------------------------
# EXPLORATORY TABLES (M2 - stratified)
# ------------------------------------------------------------------------------

# Table E1: Δ(12-0) for each frailty × FOF cell (M2)
message("  - Creating Table E1 (EXPLORATORY Δ from M2)...")
table_E1 <- chg_M2_df %>%
  mutate(
    CI = ci_fmt(lower.CL, upper.CL),
    p_formatted = p_fmt(p.value)
  ) %>%
  select(Frailty = frailty_cat_3, FOF = FOF_status,
         Contrast = contrast, Estimate = estimate, SE, CI,
         t = t.ratio, df, p = p_formatted)

ft_table_E1 <- flextable(table_E1) %>%
  set_caption(paste0(
    "Table E1: EXPLORATORY Change in Composite Physical Function (Δ, 0→12 months) by Frailty and FOF Status (M2)\n",
    "Note: From M2 (includes 3-way interaction); descriptive within-cell changes."
  )) %>%
  autofit() %>%
  theme_booktabs()

# Table E2: EXPLORATORY ΔΔ frailty STRATIFIED by FOF
message("  - Creating Table E2 (EXPLORATORY ΔΔ frailty - stratified)...")
table_E2 <- dd_frailty_M2_df %>%
  mutate(
    CI = ci_fmt(lower.CL, upper.CL),
    p_formatted = p_fmt(p.value)
  ) %>%
  select(FOF = FOF_status, Contrast = contrast,
         Estimate = estimate, SE, CI,
         t = t.ratio, df, p = p_formatted)

ft_table_E2 <- flextable(table_E2) %>%
  set_caption(paste0(
    "Table E2: EXPLORATORY Frailty-Level Differences in Change (ΔΔ frailty) - STRATIFIED BY FOF (M2)\n",
    "Note: M2 allows stratification. These are exploratory contrasts (interpret with caution).\n",
    "Adjustment: ", exploratory_adjust
  )) %>%
  autofit() %>%
  theme_booktabs()

# Table E3: EXPLORATORY ΔΔ FOF STRATIFIED by frailty
message("  - Creating Table E3 (EXPLORATORY ΔΔ FOF - stratified)...")
table_E3 <- dd_fof_M2_df %>%
  mutate(
    CI = ci_fmt(lower.CL, upper.CL),
    p_formatted = p_fmt(p.value)
  ) %>%
  select(Frailty = frailty_cat_3, Contrast = contrast,
         Estimate = estimate, SE, CI,
         t = t.ratio, df, p = p_formatted)

ft_table_E3 <- flextable(table_E3) %>%
  set_caption(paste0(
    "Table E3: EXPLORATORY FOF Differences in Change (ΔΔ FOF) - STRATIFIED BY FRAILTY (M2)\n",
    "Note: M2 allows stratification. These are exploratory contrasts (interpret with caution).\n",
    "Adjustment: ", exploratory_adjust
  )) %>%
  autofit() %>%
  theme_booktabs()

# ------------------------------------------------------------------------------
# MODEL COMPARISON TABLE
# ------------------------------------------------------------------------------

# Table M: Model comparisons (AIC/BIC + LRT)
message("  - Creating Table M (Model comparisons)...")
table_M <- model_comparison %>%
  mutate(
    LRT_p = p_fmt(LRT_vs_previous)
  ) %>%
  mutate(LRT_p = ifelse(is.na(LRT_vs_previous), "-", LRT_p)) %>%
  select(Model, AIC_REML, BIC_REML, AIC_ML, BIC_ML, LRT_p)

ft_table_M <- flextable(table_M) %>%
  set_caption("Table M: Model Comparisons (AIC/BIC and Likelihood Ratio Tests)") %>%
  colformat_double(j = c("AIC_REML", "BIC_REML", "AIC_ML", "BIC_ML"), digits = 1) %>%
  autofit() %>%
  theme_booktabs()

# ------------------------------------------------------------------------------
# EFFECT SIZE TABLE
# ------------------------------------------------------------------------------

# Table ES: Effect sizes (optional)
message("  - Creating Table ES (Effect sizes)...")
if (!is.null(r2_table)) {
  ft_table_ES <- flextable(r2_table) %>%
    set_caption("Table ES: Effect Sizes (R² Nakagawa)") %>%
    colformat_double(j = c("R2_marginal", "R2_conditional"), digits = 3) %>%
    autofit() %>%
    theme_booktabs()
} else {
  # Create placeholder noting units
  table_ES_placeholder <- data.frame(
    Note = c(
      "Composite_Z is z-scored (SD units)",
      "Δ estimates are in SD units (ΔZ)",
      "ΔΔ estimates are in SD units (ΔΔZ)",
      "These are already standardized effect sizes"
    )
  )
  ft_table_ES <- flextable(table_ES_placeholder) %>%
    set_caption("Table ES: Effect Size Notes") %>%
    autofit() %>%
    theme_booktabs()
}

# ------------------------------------------------------------------------------
# SAVE WORD DOCUMENTS
# ------------------------------------------------------------------------------

# Save PRIMARY tables
message("  - Saving PRIMARY tables (M1) to Word document...")
doc_primary <- read_docx() %>%
  body_add_par("PRIMARY CONTRASTS (M1 - Common-by-Design)", style = "heading 1") %>%
  body_add_par("") %>%
  body_add_flextable(ft_table_P1) %>%
  body_add_par("") %>%
  body_add_flextable(ft_table_P2) %>%
  body_add_par("") %>%
  body_add_flextable(ft_table_P3) %>%
  body_add_par("") %>%
  body_add_flextable(ft_table_P4) %>%
  body_add_par("") %>%
  body_add_par("MODEL COMPARISONS", style = "heading 1") %>%
  body_add_par("") %>%
  body_add_flextable(ft_table_M) %>%
  body_add_par("") %>%
  body_add_flextable(ft_table_ES)

docx_primary_path <- file.path(output_dir, "K18_PRIMARY_tables_M1.docx")
print(doc_primary, target = docx_primary_path)
append_manifest(
  manifest_row(script = getOption("fof.script"),
               label  = "PRIMARY frailty change contrasts tables (M1)",
               path   = docx_primary_path,
               kind   = "table_docx",
               n      = nrow(analysis_data)),
  getOption("fof.manifest_path")
)

message("✓ Saved PRIMARY Word tables: ", docx_primary_path)

# Save EXPLORATORY tables
message("  - Saving EXPLORATORY tables (M2) to Word document...")
doc_exploratory <- read_docx() %>%
  body_add_par("EXPLORATORY CONTRASTS (M2 - Stratified)", style = "heading 1") %>%
  body_add_par("") %>%
  body_add_flextable(ft_table_E1) %>%
  body_add_par("") %>%
  body_add_flextable(ft_table_E2) %>%
  body_add_par("") %>%
  body_add_flextable(ft_table_E3) %>%
  body_add_par("") %>%
  body_add_par("MODEL COMPARISONS", style = "heading 1") %>%
  body_add_par("") %>%
  body_add_flextable(ft_table_M) %>%
  body_add_par("") %>%
  body_add_flextable(ft_table_ES)

docx_exploratory_path <- file.path(output_dir, "K18_EXPLORATORY_tables_M2.docx")
print(doc_exploratory, target = docx_exploratory_path)
append_manifest(
  manifest_row(script = getOption("fof.script"),
               label  = "EXPLORATORY frailty change contrasts tables (M2)",
               path   = docx_exploratory_path,
               kind   = "table_docx",
               n      = nrow(analysis_data)),
  getOption("fof.manifest_path")
)

message("✓ Saved EXPLORATORY Word tables: ", docx_exploratory_path)

# ==============================================================================
# 09. Create PNG Plots (PRIMARY + EXPLORATORY)
# ==============================================================================

message("\n09) Creating PNG plots...")

# ------------------------------------------------------------------------------
# PRIMARY PLOT: M1 contrasts (common-by-design)
# ------------------------------------------------------------------------------

message("  - Creating PRIMARY change contrasts forest plot (M1)...")

# Combine PRIMARY Δ and ΔΔ for plotting
plot_data_primary_delta <- chg_M1_df %>%
  mutate(
    Type = "P1: Δ (12-0) by cell",
    Group = paste(frailty_cat_3, FOF_status, sep = " / "),
    Label = paste0(frailty_cat_3, "\n", FOF_status),
    p_text = p_fmt(p.value)
  ) %>%
  select(Type, Group, Label, estimate, lower.CL, upper.CL, p.value, p_text)

plot_data_primary_dd_frailty <- dd_frailty_M1_df %>%
  mutate(
    Type = "P2: ΔΔ Frailty (common)",
    Group = "Common across FOF",
    Label = gsub("\\(|\\)", "", contrast),
    p_text = p_fmt(p.value),
    # Handle both column naming conventions
    LCL = if ("lower.CL" %in% names(.)) lower.CL else if ("asymp.LCL" %in% names(.)) asymp.LCL else NA,
    UCL = if ("upper.CL" %in% names(.)) upper.CL else if ("asymp.UCL" %in% names(.)) asymp.UCL else NA
  ) %>%
  select(Type, Group, Label, estimate, LCL, UCL, p.value, p_text) %>%
  rename(lower.CL = LCL, upper.CL = UCL)

plot_data_primary_dd_fof <- dd_fof_M1_df %>%
  mutate(
    Type = "P3: ΔΔ FOF (common)",
    Group = "Common across frailty",
    Label = gsub("\\(|\\)", "", contrast),
    p_text = p_fmt(p.value)
  ) %>%
  select(Type, Group, Label, estimate, lower.CL, upper.CL, p.value, p_text)

plot_data_primary <- bind_rows(
  plot_data_primary_delta,
  plot_data_primary_dd_frailty,
  plot_data_primary_dd_fof
) %>%
  mutate(
    sig = ifelse(p.value < 0.05, "p < 0.05", "p >= 0.05"),
    Label = factor(Label, levels = rev(unique(Label))),
    # Use lower.CL/upper.CL directly (PRIMARY contrasts always have these)
    LCL = lower.CL,
    UCL = upper.CL
  )

p_primary <- ggplot(plot_data_primary, aes(x = estimate, y = Label, color = sig)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  geom_point(size = 3) +
  geom_errorbarh(aes(xmin = LCL, xmax = UCL), height = 0.2) +
  geom_text(aes(label = p_text), hjust = -0.2, size = 3, show.legend = FALSE) +
  facet_wrap(~ Type, scales = "free_y", ncol = 1) +
  labs(
    title = "PRIMARY Change Contrasts (M1 - Common-by-Design)",
    subtitle = "Estimates with 95% confidence intervals (SD units); p-values formatted with p_fmt()",
    x = "Estimate (Z-score change)",
    y = NULL,
    color = "Significance"
  ) +
  scale_color_manual(values = c("p < 0.05" = "red", "p >= 0.05" = "black")) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    strip.text = element_text(face = "bold", size = 11)
  )

ggsave(file.path(output_dir, "K18_PRIMARY_contrasts_M1.png"),
       p_primary, width = 10, height = 12, dpi = 300)
append_manifest(
  manifest_row(
    script = getOption("fof.script"),
    label  = "PRIMARY change contrasts forest plot (M1)",
    path   = file.path(output_dir, "K18_PRIMARY_contrasts_M1.png"),
    kind   = "plot_png",
    n      = nrow(analysis_data)
  ),
  getOption("fof.manifest_path")
)

message("✓ Saved PRIMARY change contrasts plot")

# ------------------------------------------------------------------------------
# EXPLORATORY PLOT: M2 contrasts (stratified)
# ------------------------------------------------------------------------------

message("  - Creating EXPLORATORY change contrasts forest plot (M2)...")

# Combine EXPLORATORY Δ and ΔΔ for plotting
plot_data_exp_delta <- chg_M2_df %>%
  mutate(
    Type = "E1: Δ (12-0) by cell",
    Group = paste(frailty_cat_3, FOF_status, sep = " / "),
    Label = paste0(frailty_cat_3, "\n", FOF_status),
    p_text = p_fmt(p.value)
  ) %>%
  select(Type, Group, Label, estimate, lower.CL, upper.CL, p.value, p_text)

plot_data_exp_dd_frailty <- dd_frailty_M2_df %>%
  mutate(
    Type = "E2: ΔΔ Frailty (stratified by FOF)",
    Group = paste("Stratified:", FOF_status),
    Label = paste0(gsub("\\(|\\)", "", contrast), "\n", FOF_status),
    p_text = p_fmt(p.value)
  ) %>%
  select(Type, Group, Label, estimate, lower.CL, upper.CL, p.value, p_text)

plot_data_exp_dd_fof <- dd_fof_M2_df %>%
  mutate(
    Type = "E3: ΔΔ FOF (stratified by frailty)",
    Group = paste("Stratified:", frailty_cat_3),
    Label = paste0(gsub("\\(|\\)", "", contrast), "\n", frailty_cat_3),
    p_text = p_fmt(p.value)
  ) %>%
  select(Type, Group, Label, estimate, lower.CL, upper.CL, p.value, p_text)

plot_data_exploratory <- bind_rows(
  plot_data_exp_delta,
  plot_data_exp_dd_frailty,
  plot_data_exp_dd_fof
) %>%
  mutate(
    sig = ifelse(p.value < 0.05, "p < 0.05", "p >= 0.05"),
    Label = factor(Label, levels = rev(unique(Label))),
    # Use lower.CL/upper.CL directly (EXPLORATORY contrasts always have these)
    LCL = lower.CL,
    UCL = upper.CL
  )

p_exploratory <- ggplot(plot_data_exploratory, aes(x = estimate, y = Label, color = sig)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  geom_point(size = 3) +
  geom_errorbarh(aes(xmin = LCL, xmax = UCL), height = 0.2) +
  geom_text(aes(label = p_text), hjust = -0.2, size = 3, show.legend = FALSE) +
  facet_wrap(~ Type, scales = "free_y", ncol = 1) +
  labs(
    title = "EXPLORATORY Change Contrasts (M2 - Stratified)",
    subtitle = "Estimates with 95% confidence intervals (SD units); p-values formatted with p_fmt()",
    x = "Estimate (Z-score change)",
    y = NULL,
    color = "Significance"
  ) +
  scale_color_manual(values = c("p < 0.05" = "red", "p >= 0.05" = "black")) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    strip.text = element_text(face = "bold", size = 11)
  )

ggsave(file.path(output_dir, "K18_EXPLORATORY_contrasts_M2.png"),
       p_exploratory, width = 10, height = 14, dpi = 300)
append_manifest(
  manifest_row(
    script = getOption("fof.script"),
    label  = "EXPLORATORY change contrasts forest plot (M2)",
    path   = file.path(output_dir, "K18_EXPLORATORY_contrasts_M2.png"),
    kind   = "plot_png",
    n      = nrow(analysis_data)
  ),
  getOption("fof.manifest_path")
)

message("✓ Saved EXPLORATORY change contrasts plot")

# ------------------------------------------------------------------------------
# TRAJECTORY PLOT (from M1 for primary interpretation)
# ------------------------------------------------------------------------------

message("  - Creating predicted trajectories plot (M1)...")

# Get predicted means from M1 emmeans
emm_M1_summary <- as.data.frame(summary(emm_M1, infer = TRUE))

# Add Delta annotations using p_fmt
delta_annotations <- chg_M1_df %>%
  mutate(
    time_f = "12",  # Place annotation at 12-month timepoint
    label_text = sprintf("Δ = %.2f\n(p %s)", estimate, p_fmt(p.value))
  )

p_trajectories <- ggplot(emm_M1_summary, aes(x = time_f, y = emmean,
                                          color = frailty_cat_3,
                                          group = interaction(frailty_cat_3, FOF_status),
                                          linetype = FOF_status)) +
  geom_line(linewidth = 1) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = lower.CL, ymax = upper.CL), width = 0.1) +
  facet_wrap(~ FOF_status, labeller = labeller(FOF_status = c("nonFOF" = "No FOF", "FOF" = "FOF"))) +
  labs(
    title = "Predicted Physical Function Trajectories (0→12 months) - M1",
    subtitle = "By frailty status and FOF (adjusted for covariates; from PRIMARY model M1)",
    x = "Time (months)",
    y = "Predicted Composite Physical Function (Z-score)",
    color = "Frailty Status",
    linetype = "FOF Status"
  ) +
  scale_x_discrete(labels = c("0" = "0", "12" = "12")) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    strip.text = element_text(face = "bold", size = 11)
  )

ggsave(file.path(output_dir, "K18_predicted_trajectories_M1.png"),
       p_trajectories, width = 12, height = 6, dpi = 300)
append_manifest(
  manifest_row(
    script = getOption("fof.script"),
    label  = "Predicted trajectories by frailty and FOF (M1)",
    path   = file.path(output_dir, "K18_predicted_trajectories_M1.png"),
    kind   = "plot_png",
    n      = nrow(analysis_data)
  ),
  getOption("fof.manifest_path")
)

message("✓ Saved predicted trajectories plot")

# ==============================================================================
# 10. Generate Results Texts (EN and FI) - PRIMARY + EXPLORATORY
# ==============================================================================

message("\n10) Generating Results texts...")

# Extract key statistics for text (using M1 PRIMARY results)
# LRT results
lrt_time_frailty_p <- model_comparison$LRT_vs_previous[2]  # M0 vs M1
lrt_3way_p <- model_comparison$LRT_vs_previous[3]  # M1 vs M2

# English Results
results_text_en <- paste0(
  "RESULTS: Frailty Change Contrasts Analysis (K18)\n",
  "================================================\n\n",

  "Analysis Overview\n",
  "-----------------\n",
  "This analysis examined 12-month changes (Δ) in composite physical function (Z-score) ",
  "and tested whether these changes differ between frailty groups (ΔΔ frailty) and FOF status (ΔΔ FOF) ",
  "using mixed models with emmeans contrasts.\n\n",

  "Units: All estimates are in standard deviation (SD) units, as Composite_Z is z-scored. ",
  "Δ represents within-group change; ΔΔ represents between-group differences in change.\n\n",

  "Model Structure\n",
  "---------------\n",
  "M1 (PRIMARY): time×FOF + time×frailty (NO 3-way interaction)\n",
  "  → Frailty ΔΔ is COMMON across FOF groups (by design)\n",
  "  → FOF ΔΔ is COMMON across frailty levels (by design)\n\n",

  "M2 (EXPLORATORY): time×FOF×frailty (includes 3-way interaction)\n",
  "  → Allows stratified contrasts (frailty ΔΔ within FOF; FOF ΔΔ within frailty)\n",
  "  → Exploratory only; interpret with caution\n\n",

  "Model Comparisons (LRT)\n",
  "-----------------------\n",
  "M0 vs. M1 (tests time×frailty addition): p ", p_fmt(lrt_time_frailty_p), "\n",
  ifelse(lrt_time_frailty_p < 0.05,
         "  → Significant: Changes differ between frailty groups.\n\n",
         "  → Not significant: Changes do not differ between frailty groups.\n\n"),

  "M1 vs. M2 (tests 3-way interaction): p ", p_fmt(lrt_3way_p), "\n",
  ifelse(lrt_3way_p < 0.05,
         "  → Significant: Frailty moderates the FOF×time effect (stratified contrasts warranted).\n\n",
         "  → Not significant: No evidence for 3-way moderation (M1 preferred).\n\n"),

  "===============================================================================\n",
  "PRIMARY RESULTS (M1 - Common-by-Design Contrasts)\n",
  "===============================================================================\n\n",

  "P1: Change Estimates (Δ, 12-month within-cell changes)\n",
  "------------------------------------------------------\n"
)

# Add PRIMARY Δ for each cell (from M1)
for (i in 1:nrow(chg_M1_df)) {
  row <- chg_M1_df[i, ]
  results_text_en <- paste0(results_text_en,
    sprintf("  %s / %s: Δ = %.3f (95%% CI %s, p %s)\n",
            row$frailty_cat_3, row$FOF_status, row$estimate,
            ci_fmt(row$lower.CL, row$upper.CL), p_fmt(row$p.value)))
}

results_text_en <- paste0(results_text_en, "\n",
  "P2: PRIMARY Frailty ΔΔ (COMMON across FOF groups)\n",
  "--------------------------------------------------\n",
  "Note: M1 does NOT include 3-way interaction, so frailty contrasts are averaged over FOF.\n",
  "Adjustment: ", primary_adjust, " (emmeans auto-switched from Tukey for interaction contrasts)\n\n"
)

# Add PRIMARY ΔΔ frailty (common)
for (i in 1:nrow(dd_frailty_M1_df)) {
  row <- dd_frailty_M1_df[i, ]
  # Handle both column naming conventions
  lcl <- if("lower.CL" %in% names(row)) row$lower.CL else if("asymp.LCL" %in% names(row)) row$asymp.LCL else NA
  ucl <- if("upper.CL" %in% names(row)) row$upper.CL else if("asymp.UCL" %in% names(row)) row$asymp.UCL else NA
  results_text_en <- paste0(results_text_en,
    sprintf("  %s: ΔΔ = %.3f (95%% CI %s, p %s)\n",
            row$contrast, row$estimate,
            ci_fmt(lcl, ucl), p_fmt(row$p.value)))
}

results_text_en <- paste0(results_text_en, "\n",
  "P3: PRIMARY FOF ΔΔ (COMMON across frailty levels)\n",
  "-------------------------------------------------\n",
  "Note: M1 does NOT include 3-way interaction, so FOF contrast is averaged over frailty.\n\n"
)

# Add PRIMARY ΔΔ FOF (common)
for (i in 1:nrow(dd_fof_M1_df)) {
  row <- dd_fof_M1_df[i, ]
  results_text_en <- paste0(results_text_en,
    sprintf("  %s: ΔΔ = %.3f (95%% CI %s, p %s)\n",
            row$contrast, row$estimate,
            ci_fmt(row$lower.CL, row$upper.CL), p_fmt(row$p.value)))
}

# Add P4: Continuous frailty interaction
if (!is.na(p4_estimate)) {
  results_text_en <- paste0(results_text_en,
    "\nP4: Continuous Frailty Proxy (M_cont)\n",
    "--------------------------------------\n",
    "Note: Interaction effect from continuous frailty model (time×frailty_score_3).\n\n",
    sprintf("  time_f12:frailty_score_3: Estimate = %.3f (95%% CI %s, p %s)\n",
            p4_estimate, ci_fmt(p4_ci_lower, p4_ci_upper), p_fmt(p4_p)),
    sprintf("  Interpretation: Per +1 frailty point, 12-month change differs by %.3f SD units.\n",
            p4_estimate)
  )
}

results_text_en <- paste0(results_text_en, "\n",
  "===============================================================================\n",
  "EXPLORATORY RESULTS (M2 - Stratified Contrasts)\n",
  "===============================================================================\n",
  "CAUTION: These are exploratory contrasts from M2. Interpret with appropriate skepticism.\n\n",

  "E2: EXPLORATORY Frailty ΔΔ (STRATIFIED by FOF)\n",
  "----------------------------------------------\n",
  "Adjustment: ", exploratory_adjust, "\n\n"
)

# Add EXPLORATORY ΔΔ frailty (stratified)
for (i in 1:nrow(dd_frailty_M2_df)) {
  row <- dd_frailty_M2_df[i, ]
  # Check if columns exist
  lcl <- if("lower.CL" %in% names(row)) row$lower.CL else row$asymp.LCL
  ucl <- if("upper.CL" %in% names(row)) row$upper.CL else row$asymp.UCL
  results_text_en <- paste0(results_text_en,
    sprintf("  %s (in %s): ΔΔ = %.3f (95%% CI %s, p %s)\n",
            row$contrast, row$FOF_status, row$estimate,
            ci_fmt(lcl, ucl), p_fmt(row$p.value)))
}

results_text_en <- paste0(results_text_en, "\n",
  "E3: EXPLORATORY FOF ΔΔ (STRATIFIED by frailty)\n",
  "----------------------------------------------\n",
  "Adjustment: ", exploratory_adjust, "\n\n"
)

# Add EXPLORATORY ΔΔ FOF (stratified)
for (i in 1:nrow(dd_fof_M2_df)) {
  row <- dd_fof_M2_df[i, ]
  # Check if columns exist
  lcl <- if("lower.CL" %in% names(row)) row$lower.CL else row$asymp.LCL
  ucl <- if("upper.CL" %in% names(row)) row$upper.CL else row$asymp.UCL
  results_text_en <- paste0(results_text_en,
    sprintf("  %s (in %s): ΔΔ = %.3f (95%% CI %s, p %s)\n",
            row$contrast, row$frailty_cat_3, row$estimate,
            ci_fmt(lcl, ucl), p_fmt(row$p.value)))
}

results_text_en <- paste0(results_text_en, "\n",
  "===============================================================================\n",
  "PRIMARY INTERPRETATION (from M1)\n",
  "===============================================================================\n",
  ifelse(lrt_time_frailty_p < 0.05,
         "Changes in physical function over 12 months differ significantly between frailty groups. ",
         "Changes in physical function over 12 months do not differ significantly between frailty groups. "),
  ifelse(lrt_3way_p < 0.05,
         paste0("The 3-way interaction (M2) is significant (p ", p_fmt(lrt_3way_p), "), ",
                "suggesting frailty moderates the FOF×time effect. ",
                "However, M1 contrasts (common-by-design) remain the PRIMARY inference. ",
                "M2 stratified contrasts are EXPLORATORY."),
         paste0("The 3-way interaction (M2) is not significant (p ", p_fmt(lrt_3way_p), "), ",
                "supporting M1 as the preferred model. ",
                "M1 contrasts are common across groups by design.")),
  "\n\n",
  "All estimates are in SD units (Z-scores), providing standardized effect sizes.\n",
  "P-values formatted with p_fmt() for consistency.\n",
  "PRIMARY contrasts use adjustment: ", primary_adjust, "\n",
  "EXPLORATORY contrasts use adjustment: ", exploratory_adjust, "\n"
)

# Finnish Results (simplified translation of English structure)
results_text_fi <- paste0(
  "TULOKSET: Haurausmuutosten kontrastianalyysi (K18)\n",
  "==================================================\n\n",

  "Analyysin yleiskatsaus\n",
  "----------------------\n",
  "Tämä analyysi tarkasteli 12 kuukauden muutoksia (Δ) yhdistelmätoimintakyvyssä (Z-pistemäärä) ",
  "ja testasi, eroavatko nämä muutokset haurausryhmien (ΔΔ hauraus) ja FOF-statuksen (ΔΔ FOF) välillä.\n\n",

  "Yksiköt: Kaikki estimaatit ovat keskihajonnan (SD) yksiköissä.\n\n",

  "Mallien rakenne\n",
  "---------------\n",
  "M1 (PRIMÄÄRI): aika×FOF + aika×hauraus (EI 3-suuntaista yhdysvaikutusta)\n",
  "  → Hauraus ΔΔ on YHTEINEN FOF-ryhmille (mallin suunnitelman mukaan)\n",
  "  → FOF ΔΔ on YHTEINEN hauraustasoille (mallin suunnitelman mukaan)\n\n",

  "M2 (EKSPLORATIIVINEN): aika×FOF×hauraus (sisältää 3-suuntaisen yhdysvaikutuksen)\n",
  "  → Mahdollistaa stratifioidut kontrastit\n",
  "  → Vain eksploratiivinen; tulkittava varoen\n\n",

  "Mallien vertailut (LRT)\n",
  "-----------------------\n",
  "M0 vs. M1: p ", p_fmt(lrt_time_frailty_p), "\n",
  "M1 vs. M2: p ", p_fmt(lrt_3way_p), "\n\n",

  "===============================================================================\n",
  "PRIMÄÄRIT TULOKSET (M1)\n",
  "===============================================================================\n",
  "Katso englannikielinen versio yksityiskohtaisiin tuloksiin.\n\n"
)

# Add P4 to Finnish results
if (!is.na(p4_estimate)) {
  results_text_fi <- paste0(results_text_fi,
    "\nP4: Jatkuva haurausindeksi (M_cont)\n",
    "------------------------------------\n",
    sprintf("  time_f12:frailty_score_3: Estimaatti = %.3f (95%% LV %s, p %s)\n",
            p4_estimate, ci_fmt(p4_ci_lower, p4_ci_upper), p_fmt(p4_p)),
    sprintf("  Tulkinta: Jokaista +1 haurauspistettä kohden 12 kk muutos eroaa %.3f SD-yksikköä.\n\n",
            p4_estimate)
  )
}

results_text_fi <- paste0(results_text_fi,
  "===============================================================================\n",
  "EKSPLORATIIVISET TULOKSET (M2)\n",
  "===============================================================================\n",
  "Katso englannikielinen versio yksityiskohtaisiin tuloksiin.\n\n",

  "Kaikki estimaatit ovat SD-yksiköissä (Z-pisteet).\n",
  "P-arvot muotoiltu p_fmt()-funktiolla.\n",
  "PRIMÄÄRIT kontrastit: säätö = ", primary_adjust, "\n",
  "EKSPLORATIIVISET kontrastit: säätö = ", exploratory_adjust, "\n"
)

# Save Results texts
results_en_path <- file.path(output_dir, "K18_Results_EN.txt")
writeLines(results_text_en, results_en_path)
append_manifest(
  manifest_row(
    script = getOption("fof.script"),
    label  = "Results text (English)",
    path   = results_en_path,
    kind   = "text",
    n      = nrow(analysis_data)
  ),
  getOption("fof.manifest_path")
)

message("✓ Saved English Results: ", results_en_path)

results_fi_path <- file.path(output_dir, "K18_Results_FI.txt")
writeLines(results_text_fi, results_fi_path)
append_manifest(
  manifest_row(
    script = getOption("fof.script"),
    label  = "Results text (Finnish)",
    path   = results_fi_path,
    kind   = "text",
    n      = nrow(analysis_data)
  ),
  getOption("fof.manifest_path")
)

message("✓ Saved Finnish Results: ", results_fi_path)

# ==============================================================================
# 11. Save Model Objects and Artifacts
# ==============================================================================

message("\n11) Saving model objects and artifacts...")

# Save all models and emmeans results (PRIMARY + EXPLORATORY)
all_models <- list(
  models = list(
    M0 = mod_M0,
    M1 = mod_M1,
    M2 = mod_M2,
    M_cont = mod_M_cont,
    M0_ml = mod_M0_ml,
    M1_ml = mod_M1_ml,
    M2_ml = mod_M2_ml
  ),
  primary_emmeans_M1 = list(
    emm_M1 = emm_M1,
    emm_M1_frailty = emm_M1_frailty,  # Updated: for interaction contrast P2
    emm_M1_time_fof = emm_M1_time_fof,
    chg_M1 = chg_M1,
    dd_frailty_M1 = dd_frailty_M1,
    dd_fof_M1 = dd_fof_M1
  ),
  exploratory_emmeans_M2 = list(
    emm_M2 = emm_M2,
    chg_M2 = chg_M2,
    dd_frailty_M2 = dd_frailty_M2,
    dd_fof_M2 = dd_fof_M2
  ),
  primary_tables = list(
    chg_M1_df = chg_M1_df,
    dd_frailty_M1_df = dd_frailty_M1_df,
    dd_fof_M1_df = dd_fof_M1_df
  ),
  exploratory_tables = list(
    chg_M2_df = chg_M2_df,
    dd_frailty_M2_df = dd_frailty_M2_df,
    dd_fof_M2_df = dd_fof_M2_df
  ),
  model_comparison = model_comparison,
  effectsizes = list(
    note = effect_size_note,
    r2_table = r2_table,
    r2_results = if(exists("r2_M0")) list(M0 = r2_M0, M1 = r2_M1, M2 = r2_M2) else NULL,
    partR2_results = partR2_results
  ),
  metadata = list(
    primary_adjust = primary_adjust,
    exploratory_adjust = exploratory_adjust,
    script_version = "K18_patched_2025-12-27",
    contrast_policy = "M1=PRIMARY(common), M2=EXPLORATORY(stratified)"
  )
)

rdata_path <- file.path(output_dir, "K18_all_models.RData")
save(all_models, file = rdata_path)
append_manifest(
  manifest_row(
    script = getOption("fof.script"),
    label  = "All frailty change models and emmeans results (PRIMARY+EXPLORATORY)",
    path   = rdata_path,
    kind   = "rdata",
    n      = nrow(analysis_data)
  ),
  getOption("fof.manifest_path")
)

message("✓ Saved model objects: ", rdata_path)

# ==============================================================================
# 12. Summary
# ==============================================================================

message("\n", strrep("=", 80))
message("K18 ANALYSIS COMPLETE - PATCHED VERSION (2025-12-27)")
message(strrep("=", 80))
message("\nKey Findings:")
message("✓ Model comparisons (LRT):")
message("  - M0 vs M1 (time×frailty): p ", p_fmt(lrt_time_frailty_p))
message("  - M1 vs M2 (3-way): p ", p_fmt(lrt_3way_p))
message("✓ PRIMARY contrasts (M1 - common-by-design):")
message("  - Frailty ΔΔ: COMMON across FOF (Sidak adj)")
message("  - FOF ΔΔ: COMMON across frailty (no adj)")
message("✓ EXPLORATORY contrasts (M2 - stratified):")
message("  - Frailty ΔΔ: STRATIFIED by FOF (Holm adj)")
message("  - FOF ΔΔ: STRATIFIED by frailty (Holm adj)")
message("✓ All estimates in SD units (z-score changes)")
message("✓ p-values formatted with p_fmt() throughout")
message("\nOutputs saved to: ", output_dir)
message("✓ PRIMARY tables (M1): K18_PRIMARY_tables_M1.docx")
message("✓ EXPLORATORY tables (M2): K18_EXPLORATORY_tables_M2.docx")
message("✓ PRIMARY contrasts plot: K18_PRIMARY_contrasts_M1.png")
message("✓ EXPLORATORY contrasts plot: K18_EXPLORATORY_contrasts_M2.png")
message("✓ Trajectories plot: K18_predicted_trajectories_M1.png")
message("✓ Results text (EN): K18_Results_EN.txt")
message("✓ Results text (FI): K18_Results_FI.txt")
message("✓ Model objects (RData): K18_all_models.RData")
message("\nContrast Policy:")
message("  PRIMARY (M1): ", primary_adjust, " adjustment")
message("  EXPLORATORY (M2): ", exploratory_adjust, " adjustment")
message(strrep("=", 80), "\n")

# End of K18.R

save_sessioninfo_manifest()
