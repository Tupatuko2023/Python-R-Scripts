#!/usr/bin/env Rscript
# ==============================================================================
# K29_INTERACTION - time × FOF × frailty interaction on Composite_Z (mixed model)
# File tag: K29_INTERACTION.V1_time-fof-frailty-compositeZ.R
# Purpose: Fit mixed models with random intercept (1|id) to test the 3-way
#          interaction: time × FOF × frailty (score and category) on Composite_Z.
#
# Outcome: Composite_Z (long format)
# Predictors: time, FOF_status, frailty_score_3 / frailty_cat_3
# Moderator/interaction: time * FOF_status * frailty
# Grouping variable: id (random intercept)
# Covariates: age, sex, BMI
#
# Required vars (analysis_data - wide; must match req_cols check):
# id, FOF_status, frailty_score_3, frailty_cat_3, age, sex, BMI,
# ToimintaKykySummary0, ToimintaKykySummary2
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: 20251124
#
# Outputs + manifest:
# - script_label: K29_INTERACTION (canonical)
# - outputs dir: R-scripts/K29/outputs/K29_INTERACTION/
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow:
# 01) Init paths + options (init_paths)
# 02) Load canonical data (K15 RData)
# 03) Pivot long & Normalize FOF (fail-closed)
# 04) Save temp analysis_long.csv & Run QC gate (K18_QC)
# 05) Fit mixed models (lmer)
# 06) Extract 3-way terms + post-hoc power/MDE (approx)
# 07) Model-based change estimates (emmeans)
# 08) Plot change by frailty & FOF
# 09) Save artifacts & Update manifest
# 10) Save sessionInfo
# ==============================================================================

# Activate renv if needed
if (Sys.getenv("RENV_PROJECT") == "") {
  if (file.exists("renv/activate.R")) source("renv/activate.R")
}

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(readr)
  library(tidyr)
  library(lme4)
  library(lmerTest)
  library(emmeans)
  library(broom.mixed)
  library(ggplot2)
})

# --- Local Helpers -----------------------------------------------------------
normalize_fof_from_raw <- function(x) {
  # returns factor with levels: c("nonFOF","FOF")
  if (is.factor(x)) x <- as.character(x)

  # numeric/integer 0/1
  if (is.numeric(x) || is.integer(x)) {
    if (all(na.omit(x) %in% c(0, 1))) {
      return(factor(ifelse(x == 1, "FOF", "nonFOF"), levels = c("nonFOF", "FOF")))
    }
  }

  # logical TRUE/FALSE
  if (is.logical(x)) {
    return(factor(ifelse(isTRUE(x), "FOF", "nonFOF"), levels = c("nonFOF", "FOF")))
  }

  # character labels
  xc <- tolower(trimws(as.character(x)))
  yes_set <- c("1", "true", "t", "yes", "y", "kyllä", "kylla", "fof", "with fof")
  no_set  <- c("0", "false", "f", "no", "n", "ei", "no fof", "without fof", "nonfof")

  out <- ifelse(xc %in% yes_set, "FOF",
                ifelse(xc %in% no_set, "nonFOF", NA_character_))

  # If mapping fails, stop with evidence (no guessing)
  if (any(is.na(out) & !is.na(x))) {
    bad <- sort(unique(x[is.na(out) & !is.na(x)]))
    stop("K29_INTERACTION: Unrecognized values in FOF source: ", paste(bad, collapse = ", "),
         ". Please update normalize_fof_from_raw() mapping.")
  }

  factor(out, levels = c("nonFOF", "FOF"))
}

posthoc_power_z <- function(beta, se, alpha = 0.05) {
  if (is.na(beta) || is.na(se) || se <= 0) return(NA_real_)
  z_alpha <- qnorm(1 - alpha/2)
  z_true <- abs(beta)/se
  1 - pnorm(z_alpha - z_true) + pnorm(-z_alpha - z_true)
}

mde_for_power <- function(se, power_target = 0.80, alpha = 0.05) {
  if (is.na(se) || se <= 0) return(NA_real_)
  z_alpha <- qnorm(1 - alpha/2)
  z_pow <- qnorm(power_target)
  (z_alpha + z_pow) * se
}

# --- Standard init (MANDATORY) -----------------------------------------------
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K29_INTERACTION"
}

script_id_raw <- sub("\\.V.*$", "", script_base)
if (is.na(script_id_raw) || script_id_raw == "") script_id_raw <- "K29_INTERACTION"
script_label <- script_id_raw

# Source helper functions (io, checks, reporting)
source(here::here("R", "functions", "io.R"))
source(here::here("R", "functions", "checks.R"))
source(here::here("R", "functions", "reporting.R"))

paths <- init_paths(script_label)
outputs_dir   <- paths$outputs_dir
manifest_path <- paths$manifest_path

set.seed(20251124)

# ==============================================================================
# 01. Load Canonical Data
# ==============================================================================
rdata_path <- here::here("R-scripts", "K15", "outputs", "K15_frailty_analysis_data.RData")
if (!file.exists(rdata_path)) {
  stop("K29_INTERACTION: Missing input RData: ", rdata_path)
}
load(rdata_path) # loads 'analysis_data'

# Required columns (wide format)
req_cols <- c("id", "FOF_status", "frailty_score_3", "frailty_cat_3", "age", "sex", "BMI",
              "ToimintaKykySummary0", "ToimintaKykySummary2")

missing_cols <- setdiff(req_cols, names(analysis_data))
if (length(missing_cols) > 0) {
  stop("K29_INTERACTION: Missing required columns in input data: ", paste(missing_cols, collapse = ", "))
}

cat("✓ Required columns verified:", paste(req_cols, collapse = ", "), "\n")

# ==============================================================================
# 02. Pivot Long & Normalize
# ==============================================================================
analysis_long <- analysis_data %>%
  dplyr::select(all_of(req_cols)) %>%
  pivot_longer(
    cols = c(ToimintaKykySummary0, ToimintaKykySummary2),
    names_to = "time_raw",
    values_to = "Composite_Z"
  ) %>%
  mutate(
    time = ifelse(time_raw == "ToimintaKykySummary0", 0, 12),
    time_f = factor(time, levels = c(0, 12), labels = c("0", "12")),
    FOF_status_f = normalize_fof_from_raw(FOF_status),
    frailty_cat_3 = factor(frailty_cat_3, levels = c("robust", "pre-frail", "frail")),
    sex_f = factor(sex, levels = c(0, 1), labels = c("female", "male"))
  )

# Verify long shape
cat("✓ Long format created:", nrow(analysis_long), "observations\n")

# ==============================================================================
# 03. Save for QC & Run QC Gate
# ==============================================================================
proc_dir <- here::here("data", "processed")
if (!dir.create(proc_dir, recursive = TRUE, showWarnings = FALSE)) {
  # exists or created
}
temp_long_csv <- file.path(proc_dir, "analysis_long_K29_tmp.csv")
readr::write_csv(analysis_long, temp_long_csv)

cat("[*] Running QC Gate (K18_QC)...\n")
qc_script <- here::here("R-scripts", "K18", "K18_QC.V1_qc-run.R")
if (!file.exists(qc_script)) {
  warning("K29_INTERACTION: QC script not found at ", qc_script, ". Skipping gate.")
} else {
  qc_cmd <- c(
    "--data", temp_long_csv,
    "--shape", "LONG",
    "--dict", here::here("data", "data_dictionary.csv")
  )
  
  status <- system2("Rscript", c(qc_script, qc_cmd))
  if (status != 0) {
    stop("K29_INTERACTION: QC Gate FAILED. See K18_QC outputs.")
  }
  cat("✓ QC Gate PASSED.\n")
}

# ==============================================================================
# 04. Fit Models
# ==============================================================================
cat("[*] Fitting mixed models...\n")

# Primary: Continuous frailty score
m_score <- lmer(
  Composite_Z ~ time_f * FOF_status_f * frailty_score_3 + age + sex_f + BMI + (1 | id),
  data = analysis_long,
  REML = FALSE
)

tab_fixed_score <- broom.mixed::tidy(m_score, effects = "fixed", conf.int = TRUE)

# Sensitivity: Categorical frailty
m_cat <- lmer(
  Composite_Z ~ time_f * FOF_status_f * frailty_cat_3 + age + sex_f + BMI + (1 | id),
  data = analysis_long,
  REML = FALSE
)

tab_fixed_cat <- broom.mixed::tidy(m_cat, effects = "fixed", conf.int = TRUE)

# ==============================================================================
# 05. Extract 3-way terms & Post-hoc power
# ==============================================================================
term_pat_score <- "time_f12:FOF_status_fFOF:frailty_score_3"
term_3way_score <- tab_fixed_score %>% filter(term == term_pat_score)

beta_score <- if (nrow(term_3way_score) == 1) term_3way_score$estimate[1] else NA_real_
se_score   <- if (nrow(term_3way_score) == 1) term_3way_score$std.error[1] else NA_real_

power_score <- posthoc_power_z(beta_score, se_score)
mde_80 <- mde_for_power(se_score, power_target = 0.80)

# ==============================================================================
# 06. Change Estimates (emmeans)
# ==============================================================================
cat("[*] Calculating model-based change estimates...\n")

emm_score <- emmeans(
  m_score,
  ~ time_f * FOF_status_f | frailty_score_3,
  at = list(frailty_score_3 = c(0, 1, 2, 3))
)

chg_score <- contrast(emm_score, method = "revpairwise", by = c("FOF_status_f", "frailty_score_3"))
chg_score_df <- as.data.frame(confint(chg_score))

# Normalize confidence interval column names for plotting
if ("lower.CL" %in% names(chg_score_df)) {
  chg_score_df <- chg_score_df %>% rename(LCL = lower.CL, UCL = upper.CL)
} else if ("asymp.LCL" %in% names(chg_score_df)) {
  chg_score_df <- chg_score_df %>% rename(LCL = asymp.LCL, UCL = asymp.UCL)
}

# ==============================================================================
# 07. Plot
# ==============================================================================
cat("[*] Generating interaction plot...\n")

p <- ggplot(chg_score_df, aes(x = frailty_score_3, y = estimate, color = FOF_status_f, group = FOF_status_f)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_line() +
  geom_point() +
  geom_errorbar(aes(ymin = LCL, ymax = UCL), width = 0.1) +
  labs(
    x = "Frailty score (0-3)",
    y = "Predicted change in Composite_Z (12m - 0m)",
    title = "3-way Interaction: Time x FOF x Frailty Score",
    color = "FOF group"
  ) +
  theme_minimal()

plot_path <- file.path(outputs_dir, "K29_interaction_plot_score.png")
ggsave(plot_path, p, width = 8, height = 6, dpi = 300)

# ==============================================================================
# 08. Save & Manifest
# ==============================================================================
# 1. Fixed terms score
fixed_score_csv <- file.path(outputs_dir, "K29_interaction_fixed_terms_score.csv")
write_csv(tab_fixed_score, fixed_score_csv)
append_manifest(manifest_row(script_label, "fixed_terms_score", get_relpath(fixed_score_csv), "table_csv"), manifest_path)

# 2. Fixed terms cat
fixed_cat_csv <- file.path(outputs_dir, "K29_interaction_fixed_terms_cat.csv")
write_csv(tab_fixed_cat, fixed_cat_csv)
append_manifest(manifest_row(script_label, "fixed_terms_cat", get_relpath(fixed_cat_csv), "table_csv"), manifest_path)

# 3. Change estimates score
chg_score_csv <- file.path(outputs_dir, "K29_interaction_change_score.csv")
write_csv(chg_score_df, chg_score_csv)
append_manifest(manifest_row(script_label, "change_estimates_score", get_relpath(chg_score_csv), "table_csv"), manifest_path)

# 4. Plot
append_manifest(manifest_row(script_label, "interaction_plot_score", get_relpath(plot_path), "figure_png"), manifest_path)

# 5. Report
report_path <- file.path(outputs_dir, "K29_interaction_report.md")
report_text <- c(
  "# K29 Interaction Report",
  "",
  "## 3-way Interaction (Time x FOF x Frailty Score)",
  if (nrow(term_3way_score) == 1) {
    paste0("- Term: ", term_pat_score, "\n",
           "- Beta: ", round(beta_score, 3), " (SE ", round(se_score, 3), ")\n",
           "- P-value: ", round(term_3way_score$p.value[1], 3))
  } else {
    "- 3-way term not found."
  },
  "",
  "### Post-hoc Power Assessment (Approximate)",
  "Note: This is an approximate Wald-based power assessment for the observed effect size.",
  paste0("- Post-hoc Power: ", round(power_score * 100, 1), "%\n",
         "- MDE for 80% power: ", round(mde_80, 3))
)
writeLines(report_text, report_path)
append_manifest(manifest_row(script_label, "interaction_report_md", get_relpath(report_path), "text_md"), manifest_path)

# Cleanup temp file
if (file.exists(temp_long_csv)) unlink(temp_long_csv)

save_sessioninfo_manifest()

cat("\n[OK] K29_INTERACTION completed. Outputs in:", outputs_dir, "\n")
