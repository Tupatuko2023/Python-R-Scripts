#!/usr/bin/env Rscript

# scripts/25_check_unknown_bias.R
# Purpose: Compare participants with 'Unknown' frailty vs 'Known' frailty
# to check for systematic differences (Age, Sex, FOF).

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
})

#-----------------------------
# 0) Inputs
#-----------------------------
DATA_ROOT <- Sys.getenv("DATA_ROOT")
PANEL_PATH <- file.path(DATA_ROOT, "derived", "aim2_panel.csv")

if (!file.exists(PANEL_PATH)) {
  stop("Missing aim2_panel.csv. Run build script first.")
}

panel <- read_csv(PANEL_PATH, show_col_types = FALSE)

# Get unique persons (baseline characteristics)
# Since they are repeated in panel, we take the first occurrence per ID
baseline <- panel %>%
  group_by(id) %>%
  slice(1) %>%
  ungroup()

#-----------------------------
# 1) Bias Analysis
#-----------------------------
message("Starting Unknown Bias Check...")

baseline <- baseline %>%
  mutate(
    frailty_status = if_else(frailty_fried == "unknown", "Unknown", "Known")
  )

# Aggregate Stats
bias_summary <- baseline %>%
  group_by(frailty_status) %>%
  summarise(
    n = n(),
    age_mean = mean(age, na.rm = TRUE),
    age_sd = sd(age, na.rm = TRUE),
    sex_male_pct = mean(sex == 1, na.rm = TRUE) * 100,
    fof_pct = mean(FOF_status == 1, na.rm = TRUE) * 100,
    .groups = "drop"
  )

print(bias_summary)

#-----------------------------
# 2) Save Results
#-----------------------------
output_dir <- "outputs/qc"
if (!dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)) {
  # fallback if in parent
}

write_csv(bias_summary, file.path(output_dir, "unknown_bias_summary.csv"))
message("Results saved to outputs/qc/unknown_bias_summary.csv")

# Final report to console (Aggregates Only)
cat("\n--- BIAS REPORT (Analyzed N=423 vs Unknown N=63) ---
")
k <- bias_summary %>% filter(frailty_status == "Known")
u <- bias_summary %>% filter(frailty_status == "Unknown")

cat(sprintf("Age: Known %.1f (SD %.1f) vs Unknown %.1f (SD %.1f)\n", 
            k$age_mean, k$age_sd, u$age_mean, u$age_sd))
cat(sprintf("Sex (Male %%): Known %.1f%% vs Unknown %.1f%%\n", 
            k$sex_male_pct, u$sex_male_pct))
cat(sprintf("FOF Status (%%): Known %.1f%% vs Unknown %.1f%%\n", 
            k$fof_pct, u$fof_pct))
