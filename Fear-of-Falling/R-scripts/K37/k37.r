#!/usr/bin/env Rscript
# ==============================================================================
# K37 - Aggregate Capacity Visualizations
# File tag: K37.V1_capacity-visualizations.R
# Purpose: Build aggregate visualizations from K36 primary/fallback outcome outputs and canonical K50 inputs.
#
# Outcome: Aggregate figures and captions
# Predictors: locomotor_capacity, z3, FOF_status
# Moderator/interaction: time x FOF_status
# Grouping variable: id
# Covariates: age, BMI
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# id
# time
# locomotor_capacity
# age
# BMI
# locomotor_capacity_0
# z3_0
#
# Mapping example (optional; raw -> analysis; keep minimal + explicit):
# fof_analysis_k50_long$locomotor_capacity -> primary long outcome
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: NA (set only when randomness is used: MI/bootstrap/resampling)
#
# Outputs + manifest:
# - script_label: K37 (canonical)
# - outputs dir: R-scripts/K37/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load aggregate K36 outputs + externalized K33/K32 datasets
# 03) Standardize vars + QC (sanity checks early)
# 04) Derive plotting datasets
# 05) Prepare aggregate figure layers
# 06) Render figures
# 07) Save captions
# 08) Save artifacts -> R-scripts/K37_CAPACITY_VIS/outputs/
# 09) Append manifest row per artifact
# 10) Save sessionInfo / renv diagnostics to manifest/
# 11) EOF marker
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(tidyr)
  library(tibble)
  library(here)
})

req_cols <- c("id", "time", "FOF_status", "age", "BMI", "locomotor_capacity", "locomotor_capacity_0", "z3_0")

script_label <- "K37"

source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
out_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

append_manifest_safe <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  append_manifest(
    manifest_row(
      script = script_label,
      label = label,
      path = get_relpath(path),
      kind = kind,
      n = n,
      notes = notes
    ),
    manifest_path
  )
}

resolve_data_root <- function() {
  dr <- Sys.getenv("DATA_ROOT", unset = "")
  if (dr == "") {
    stop(
      paste(
        "DATA_ROOT is required for K37.",
        "Set it in config/.env and run via proot command that sources config/.env in-call.",
        sep = "\n"
      ),
      call. = FALSE
    )
  }
  dr
}

read_external <- function(base_no_ext) {
  rds <- paste0(base_no_ext, ".rds")
  csv <- paste0(base_no_ext, ".csv")
  if (file.exists(rds)) return(readRDS(rds))
  if (file.exists(csv)) return(readr::read_csv(csv, show_col_types = FALSE))
  stop(sprintf("Missing external input: %s(.rds|.csv)", base_no_ext), call. = FALSE)
}

to_id_chr <- function(x) trimws(as.character(x))

get_beta <- function(df, term) {
  row <- df %>% filter(.data$effect == "fixed", .data$term == term)
  if (nrow(row) == 0) return(0)
  as.numeric(row$estimate[[1]])
}

data_root <- resolve_data_root()

k36_lmm_primary <- readr::read_csv(
  here::here("R-scripts", "K36", "outputs", "k36_locomotor_capacity_lmm_fixed_effects.csv"),
  show_col_types = FALSE
)
k36_lmm_fallback <- readr::read_csv(
  here::here("R-scripts", "K36", "outputs", "k36_z3_fallback_lmm_fixed_effects.csv"),
  show_col_types = FALSE
)
k36_overview <- readr::read_csv(
  here::here("R-scripts", "K36", "outputs", "k36_outcome_model_overview.csv"),
  show_col_types = FALSE
)

k50_long <- read_external(file.path(data_root, "paper_01", "analysis", "fof_analysis_k50_long"))
k50_wide <- read_external(file.path(data_root, "paper_01", "analysis", "fof_analysis_k50_wide"))

req_long <- c("id", "time", "FOF_status", "locomotor_capacity", "age", "BMI")
req_wide <- c("id", "locomotor_capacity_0", "z3_0")

miss_long <- setdiff(req_long, names(k50_long))
miss_wide <- setdiff(req_wide, names(k50_wide))
if (length(miss_long) > 0 || length(miss_wide) > 0) {
  stop(
    paste0(
      "Missing required columns.",
      " long:", paste(miss_long, collapse = ","),
      " wide:", paste(miss_wide, collapse = ",")
    ),
    call. = FALSE
  )
}

baseline_df <- k50_wide %>%
  transmute(
    id = to_id_chr(.data$id),
    locomotor_capacity_0 = as.numeric(.data$locomotor_capacity_0),
    z3_0 = as.numeric(.data$z3_0)
  ) %>%
  filter(!is.na(.data$locomotor_capacity_0), !is.na(.data$z3_0))

mean_age <- mean(k50_long$age, na.rm = TRUE)
mean_bmi <- mean(k50_long$BMI, na.rm = TRUE)
mean_balance <- mean(as.numeric(k50_long$tasapainovaikeus), na.rm = TRUE)

b0 <- get_beta(k36_lmm_primary, "(Intercept)")
b_time <- get_beta(k36_lmm_primary, "time_f12")
b_fof <- get_beta(k36_lmm_primary, "FOF_statusFOF")
b_time_fof <- get_beta(k36_lmm_primary, "time_f12:FOF_statusFOF")
b_age <- get_beta(k36_lmm_primary, "age")
b_bmi <- get_beta(k36_lmm_primary, "BMI")
b_balance <- get_beta(k36_lmm_primary, "tasapainovaikeus")

traj <- tidyr::expand_grid(
  fof_label = c("nonFOF", "FOF"),
  time = c(0, 12)
) %>%
  mutate(
    t12 = ifelse(.data$time == 12, 1, 0),
    fof_bin = ifelse(.data$fof_label == "FOF", 1, 0),
    pred = b0 +
      b_age * mean_age +
      b_bmi * mean_bmi +
      b_balance * mean_balance +
      b_time * .data$t12 +
      b_fof * .data$fof_bin +
      b_time_fof * .data$t12 * .data$fof_bin
  )

p_traj <- ggplot(traj, aes(x = factor(time), y = pred, color = fof_label, group = fof_label)) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.4) +
  scale_color_manual(values = c("#1b9e77", "#d95f02")) +
  labs(
    title = "Predicted locomotor_capacity Trajectories by FOF Status",
    subtitle = "K36 primary LMM fixed effects at mean covariates",
    x = "Time (months)",
    y = "Predicted locomotor_capacity",
    color = "FOF status"
  ) +
  theme_classic(base_size = 12)

ggsave(
  filename = file.path(out_dir, "k37_locomotor_capacity_predicted_trajectories.png"),
  plot = p_traj,
  width = 8.5,
  height = 5.3,
  dpi = 320
)

coef_compare <- bind_rows(
  k36_lmm_primary %>% filter(.data$term %in% c("time_f12", "FOF_statusFOF", "time_f12:FOF_statusFOF")) %>% mutate(outcome = "locomotor_capacity"),
  k36_lmm_fallback %>% filter(.data$term %in% c("time_f12", "FOF_statusFOF", "time_f12:FOF_statusFOF")) %>% mutate(outcome = "z3")
)

p_cmp <- ggplot(coef_compare, aes(x = term, y = estimate, color = outcome)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray40") +
  geom_point(position = position_dodge(width = 0.4), size = 2.3) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.12, position = position_dodge(width = 0.4)) +
  scale_color_manual(values = c("locomotor_capacity" = "#4c78a8", "z3" = "#f58518")) +
  labs(
    title = "Primary vs Fallback Outcome Estimates (K36 LMM)",
    subtitle = "Fixed-effect estimates with 95% CI for the key FOF terms",
    x = "LMM term",
    y = "Estimate",
    color = "Outcome"
  ) +
  theme_classic(base_size = 12)

ggsave(
  filename = file.path(out_dir, "k37_locomotor_capacity_vs_z3_model_comparison.png"),
  plot = p_cmp,
  width = 8.2,
  height = 5.2,
  dpi = 320
)

p_scatter <- ggplot(
  baseline_df,
  aes(x = .data$locomotor_capacity_0, y = .data$z3_0)
) +
  geom_point(alpha = 0.55, size = 1.8, color = "#1f77b4") +
  geom_smooth(method = "lm", se = TRUE, color = "#d62728", linewidth = 0.9) +
  labs(
    title = "Baseline Association: locomotor_capacity vs z3",
    subtitle = "Primary outcome and deterministic fallback at baseline",
    x = "locomotor_capacity_0",
    y = "z3_0"
  ) +
  theme_classic(base_size = 12)

ggsave(
  filename = file.path(out_dir, "k37_locomotor_capacity_vs_z3_baseline.png"),
  plot = p_scatter,
  width = 8.2,
  height = 5.2,
  dpi = 320
)

caption_lines <- c(
  "Figure 1 (k37_locomotor_capacity_predicted_trajectories.png): Predicted 0 to 12 month locomotor_capacity trajectories from the K36 primary LMM.",
  "Predictions are shown for nonFOF and FOF at mean covariates.",
  "",
  "Figure 2 (k37_locomotor_capacity_vs_z3_model_comparison.png): Key FOF-related LMM terms for locomotor_capacity primary versus z3 fallback.",
  "Points show estimates and vertical bars show 95% confidence intervals.",
  "",
  "Figure 3 (k37_locomotor_capacity_vs_z3_baseline.png): Baseline association between locomotor_capacity_0 and z3_0.",
  "A linear trend line with confidence band is provided for interpretation.",
  "",
  "All outputs are aggregate-only repository artifacts; patient-level data remain externalized under DATA_ROOT."
)
writeLines(caption_lines, con = file.path(out_dir, "k37_figure_caption.txt"))

sink(file.path(out_dir, "k37_sessioninfo.txt"))
cat("K37 session info\n")
print(sessionInfo())
sink()

append_manifest_safe("k37_locomotor_capacity_predicted_trajectories", "figure_png", file.path(out_dir, "k37_locomotor_capacity_predicted_trajectories.png"), notes = "Aggregate primary locomotor_capacity trajectories by FOF status")
append_manifest_safe("k37_locomotor_capacity_vs_z3_model_comparison", "figure_png", file.path(out_dir, "k37_locomotor_capacity_vs_z3_model_comparison.png"), notes = "Aggregate primary versus fallback coefficient comparison")
append_manifest_safe("k37_locomotor_capacity_vs_z3_baseline", "figure_png", file.path(out_dir, "k37_locomotor_capacity_vs_z3_baseline.png"), n = nrow(baseline_df), notes = "Aggregate baseline scatter of locomotor_capacity versus z3")
append_manifest_safe("k37_figure_caption", "text", file.path(out_dir, "k37_figure_caption.txt"), notes = "K37 figure captions")
append_manifest_safe("k37_sessioninfo", "sessioninfo", file.path(out_dir, "k37_sessioninfo.txt"), notes = "K37 session info")

message("K37 outputs written to: ", out_dir)
