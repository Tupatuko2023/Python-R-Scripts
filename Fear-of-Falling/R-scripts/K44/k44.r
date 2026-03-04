#!/usr/bin/env Rscript
# ==============================================================================
# K44 - Visualize K42 BOTH-model gradients (deterministic, no refit)
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(tidyr)
  library(here)
})

args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)
script_path <- if (length(file_arg) > 0) sub("^--file=", "", file_arg[[1]]) else ""
project_root <- if (nzchar(script_path)) {
  dirname(dirname(dirname(normalizePath(script_path, winslash = "/", mustWork = FALSE))))
} else {
  getwd()
}
setwd(project_root)

source(here::here("R", "functions", "init.R"))
source(here::here("R", "functions", "reporting.R"))

script_label <- "K44"
paths <- init_paths(script_label)
outputs_dir <- getOption("fof.outputs_dir")
manifest_path <- getOption("fof.manifest_path")

append_artifact <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  append_manifest(
    manifest_row(script = script_label, label = label, path = get_relpath(path), kind = kind, n = n, notes = notes),
    manifest_path
  )
}

write_agg_txt <- function(lines, filename, label = filename, notes = NA_character_) {
  out_path <- file.path(outputs_dir, filename)
  writeLines(lines, out_path)
  append_artifact(label = label, kind = "text", path = out_path, n = length(lines), notes = notes)
  out_path
}

write_agg_png <- function(plot_obj, filename, width = 10, height = 5, dpi = 320, label = filename, notes = NA_character_) {
  out_path <- file.path(outputs_dir, filename)
  ggsave(out_path, plot = plot_obj, width = width, height = height, dpi = dpi)
  append_artifact(label = label, kind = "figure_png", path = out_path, n = NA_integer_, notes = notes)
  out_path
}

input_paths <- list(
  coeff = here::here("R-scripts", "K42", "outputs", "k42_lmm_both_coefficients.csv"),
  collin = here::here("R-scripts", "K42", "outputs", "k42_capacity_fi_collinearity.csv"),
  counts = here::here("R-scripts", "K42", "outputs", "k42_common_sample_counts.csv"),
  model_comp = here::here("R-scripts", "K42", "outputs", "k42_lmm_model_comparison.csv"),
  pred_ref = here::here("R-scripts", "K42", "outputs", "k42_lmm_both_predicted_trajectories.csv")
)

missing_required <- names(input_paths)[!file.exists(unlist(input_paths)[names(input_paths) %in% c("coeff", "collin", "counts")])]
if (length(missing_required) > 0) {
  stop("Missing required K42 input files: ", paste(missing_required, collapse = ", "), call. = FALSE)
}

coeff <- readr::read_csv(input_paths$coeff, show_col_types = FALSE)
collin <- readr::read_csv(input_paths$collin, show_col_types = FALSE)
counts <- readr::read_csv(input_paths$counts, show_col_types = FALSE)

if (!all(c("effect", "term", "estimate") %in% names(coeff))) {
  stop("K42 coefficients file is missing required columns (effect, term, estimate)", call. = FALSE)
}

fixed <- coeff %>%
  filter(effect == "fixed") %>%
  select(term, estimate)

need_terms <- c(
  "(Intercept)",
  "time",
  "capacity_score_latent_primary",
  "frailty_index_fi_k40_z",
  "time:capacity_score_latent_primary",
  "time:frailty_index_fi_k40_z"
)
missing_terms <- setdiff(need_terms, fixed$term)
if (length(missing_terms) > 0) {
  stop(
    paste0("Missing required K42 BOTH fixed-effect terms: ", paste(missing_terms, collapse = ", ")),
    call. = FALSE
  )
}

coef_or0 <- function(term) {
  hit <- fixed$estimate[fixed$term == term]
  if (length(hit) == 0) return(0)
  hit[[1]]
}

ref <- list(age = 0, bmi = 0, tasapainovaikeus = 0, fof = 0, fra_pre = 0, fra_frail = 0, male = 0)
if (file.exists(input_paths$pred_ref)) {
  pred_ref <- readr::read_csv(input_paths$pred_ref, show_col_types = FALSE)
  if (nrow(pred_ref) > 0) {
    ref$age <- suppressWarnings(as.numeric(pred_ref$age[[1]]))
    ref$bmi <- suppressWarnings(as.numeric(pred_ref$bmi[[1]]))
    ref$tasapainovaikeus <- suppressWarnings(as.numeric(pred_ref$tasapainovaikeus[[1]]))
    ref$fof <- ifelse(as.character(pred_ref$fof_status[[1]]) == "FOF", 1, 0)
    fra_ref <- as.character(pred_ref$frailty_cat_3[[1]])
    ref$fra_pre <- ifelse(fra_ref == "pre-frail", 1, 0)
    ref$fra_frail <- ifelse(fra_ref == "frail", 1, 0)
    ref$male <- ifelse(as.character(pred_ref$sex[[1]]) == "male", 1, 0)
  }
}

predict_eta <- function(time, cap, fi,
                        fof = ref$fof,
                        fra_pre = ref$fra_pre,
                        fra_frail = ref$fra_frail,
                        tas = ref$tasapainovaikeus,
                        age = ref$age,
                        male = ref$male,
                        bmi = ref$bmi) {
  coef_or0("(Intercept)") +
    coef_or0("time") * time +
    coef_or0("fof_statusFOF") * fof +
    coef_or0("frailty_cat_3pre-frail") * fra_pre +
    coef_or0("frailty_cat_3frail") * fra_frail +
    coef_or0("tasapainovaikeus") * tas +
    coef_or0("capacity_score_latent_primary") * cap +
    coef_or0("frailty_index_fi_k40_z") * fi +
    coef_or0("age") * age +
    coef_or0("sexmale") * male +
    coef_or0("bmi") * bmi +
    coef_or0("time:fof_statusFOF") * time * fof +
    coef_or0("time:frailty_cat_3pre-frail") * time * fra_pre +
    coef_or0("time:frailty_cat_3frail") * time * fra_frail +
    coef_or0("time:tasapainovaikeus") * time * tas +
    coef_or0("time:capacity_score_latent_primary") * time * cap +
    coef_or0("time:frailty_index_fi_k40_z") * time * fi
}

time_points <- c(0, 12)
cap_levels <- c(-1, 0, 1)
fi_levels <- c(-1, 0, 1)

panel_a <- expand_grid(
  panel = "A. Capacity Gradient (FI fixed at mean)",
  time = time_points,
  capacity_score_latent_primary = cap_levels,
  frailty_index_fi_k40_z = 0
) %>%
  mutate(
    profile = factor(
      capacity_score_latent_primary,
      levels = c(-1, 0, 1),
      labels = c("Capacity -1 SD", "Capacity mean", "Capacity +1 SD")
    )
  )

panel_b <- expand_grid(
  panel = "B. FI Gradient (Capacity fixed at mean)",
  time = time_points,
  capacity_score_latent_primary = 0,
  frailty_index_fi_k40_z = fi_levels
) %>%
  mutate(
    profile = factor(
      frailty_index_fi_k40_z,
      levels = c(-1, 0, 1),
      labels = c("FI -1 SD", "FI mean", "FI +1 SD")
    )
  )

gradient_df <- bind_rows(panel_a, panel_b) %>%
  mutate(
    pred_composite_z = predict_eta(
      time = time,
      cap = capacity_score_latent_primary,
      fi = frailty_index_fi_k40_z
    ),
    time_label = factor(time, levels = c(0, 12), labels = c("Baseline", "12 months"))
  )

ylims <- range(gradient_df$pred_composite_z, na.rm = TRUE)
p_grad <- ggplot(gradient_df, aes(x = time_label, y = pred_composite_z, color = profile, group = profile)) +
  geom_line(linewidth = 1.0) +
  geom_point(size = 2.1) +
  facet_wrap(~panel, nrow = 1, scales = "fixed") +
  scale_y_continuous(limits = ylims) +
  labs(
    title = "K42 BOTH Model Predicted Trajectories",
    subtitle = "Model-based gradients with one construct varied and the other held at mean",
    x = NULL,
    y = "Predicted Composite_Z",
    color = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

write_agg_png(
  p_grad,
  "k44_both_gradients.png",
  width = 12,
  height = 5,
  label = "k44_both_gradients.png",
  notes = "K42 BOTH model deterministic gradient panels"
)

extreme_df <- expand_grid(
  time = time_points,
  capacity_score_latent_primary = c(-1, 1),
  frailty_index_fi_k40_z = c(-1, 1)
) %>%
  mutate(
    profile = case_when(
      capacity_score_latent_primary == -1 & frailty_index_fi_k40_z == -1 ~ "Cap -1 SD, FI -1 SD",
      capacity_score_latent_primary == -1 & frailty_index_fi_k40_z == 1 ~ "Cap -1 SD, FI +1 SD",
      capacity_score_latent_primary == 1 & frailty_index_fi_k40_z == -1 ~ "Cap +1 SD, FI -1 SD",
      capacity_score_latent_primary == 1 & frailty_index_fi_k40_z == 1 ~ "Cap +1 SD, FI +1 SD",
      TRUE ~ ""
    ),
    pred_composite_z = predict_eta(
      time = time,
      cap = capacity_score_latent_primary,
      fi = frailty_index_fi_k40_z
    ),
    time_label = factor(time, levels = c(0, 12), labels = c("Baseline", "12 months"))
  )

p_extreme <- ggplot(extreme_df, aes(x = time_label, y = pred_composite_z, color = profile, group = profile)) +
  geom_line(linewidth = 1.0) +
  geom_point(size = 2.1) +
  labs(
    title = "K42 BOTH Model Reference Extreme Profiles",
    subtitle = "Model-based reference profiles (not prevalence-weighted groups)",
    x = NULL,
    y = "Predicted Composite_Z",
    color = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

write_agg_png(
  p_extreme,
  "k44_extreme_profiles.png",
  width = 9,
  height = 5,
  label = "k44_extreme_profiles.png",
  notes = "K42 BOTH model extreme reference profiles"
)

if (file.exists(input_paths$model_comp)) {
  model_comp <- readr::read_csv(input_paths$model_comp, show_col_types = FALSE)
  if (all(c("model", "aic") %in% names(model_comp))) {
    p_cmp <- ggplot(model_comp, aes(x = reorder(model, aic), y = aic)) +
      geom_col(fill = "#4C78A8") +
      coord_flip() +
      labs(
        title = "K42 LMM Model Comparison",
        x = NULL,
        y = "AIC"
      ) +
      theme_minimal(base_size = 12)

    write_agg_png(
      p_cmp,
      "k44_model_comparison.png",
      width = 8,
      height = 4.5,
      label = "k44_model_comparison.png",
      notes = "K42 LMM AIC comparison"
    )
  }
}

corr_val <- collin %>%
  filter(metric == "corr_capacity_fi_long") %>%
  pull(value)
if (length(corr_val) == 0) corr_val <- NA_real_

caption_lines <- c(
  "K44 figure notes:",
  "- Predictions are deterministic from K42 BOTH-model fixed effects; no model refit.",
  "- Main figure Panel A varies capacity at -1 SD / mean / +1 SD with FI fixed at mean.",
  "- Main figure Panel B varies FI at -1 SD / mean / +1 SD with capacity fixed at mean.",
  "- Supplement figure uses four model-based reference profiles (cap/FI extreme combinations).",
  sprintf("- Capacity-FI correlation from K42: r = %.3f.", as.numeric(corr_val)),
  "- Reference profiles are model-based and not prevalence-weighted groups.",
  "- Associations are descriptive and non-causal."
)
write_agg_txt(caption_lines, "k44_figure_caption.txt", label = "k44_figure_caption.txt", notes = "K44 figure caption and interpretation constraints")

counts_lines <- apply(counts, 1, function(r) paste0(r[["metric"]], " = ", r[["value"]]))

decision_log <- c(
  "K44 decision log",
  "- Source coefficients: K42 BOTH fixed effects.",
  "- Random intercept contribution fixed at 0 for visualization.",
  "- Time points fixed at {0,12}.",
  "- Capacity/FI gradients use standardized levels {-1,0,+1}.",
  sprintf("- corr_capacity_fi_long = %s", ifelse(is.na(corr_val), "NA", format(round(as.numeric(corr_val), 6), nsmall = 6))),
  "- No DATA_ROOT patient-level reads were required.",
  "- Common sample summary from K42:",
  counts_lines
)
write_agg_txt(decision_log, "k44_decision_log.txt", label = "k44_decision_log.txt", notes = "K44 deterministic decisions and K42 references")

receipt_lines <- c(
  "K44 external input receipt",
  "- external_data_root_reads = FALSE",
  "- note: all required inputs loaded from repository K42 aggregate outputs"
)
write_agg_txt(receipt_lines, "k44_external_input_receipt.txt", label = "k44_external_input_receipt.txt", notes = "K44 external input receipt")

session_lines <- c(
  capture.output(sessionInfo())
)
session_path <- file.path(outputs_dir, "k44_sessioninfo.txt")
writeLines(session_lines, session_path)
append_artifact(
  label = "k44_sessioninfo",
  kind = "sessioninfo",
  path = session_path,
  n = NA_integer_,
  notes = "K44 sessionInfo"
)

message("K44 completed: deterministic K42 BOTH-model visualizations written to ", outputs_dir)
