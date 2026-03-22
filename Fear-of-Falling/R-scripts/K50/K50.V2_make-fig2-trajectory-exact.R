#!/usr/bin/env Rscript
# ==============================================================================
# K50 - Exact Figure 2 Trajectory From Saved Primary LONG Model
# File tag: K50.V2_make-fig2-trajectory-exact.R
# Purpose: Build Figure 2 from the saved K50 primary LONG mixed model object
#          using exact model-based adjusted means and covariance-correct 95% CIs.
#
# Outcome: locomotor_capacity
# Predictors: FOF_status, time
# Moderator/interaction: time * FOF_status
# Grouping variable: id
# Covariates: age, sex, BMI
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# time, FOF_status, age, sex, BMI
#
# Mapping example (optional; raw -> analysis; keep minimal + explicit):
# saved merMod model.frame -> exact Figure 2 prediction grid
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: 20251124 (not used; no randomness)
#
# Outputs + manifest:
# - script_label: K50 (canonical)
# - outputs dir: R-scripts/K50/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load saved exact primary LONG model object
# 03) Validate model class and model-frame variables
# 04) Compute exact adjusted means with emmeans
# 05) Build canonical four-row prediction table
# 06) Save prediction CSV to R-scripts/K50/outputs/
# 07) Save PNG and PDF figure artifacts
# 08) Append manifest row per artifact
# 09) Save sessionInfo artifact
# 10) EOF marker
# ==============================================================================
#
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(emmeans)
  library(here)
})

# --- Standard init (MANDATORY) -----------------------------------------------
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.[Rr]$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K50"
}
script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K50"

source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path
artifact_dir <- file.path(outputs_dir, "FIG2_trajectory_exact")
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

req_cols <- c("time", "FOF_status", "age", "sex", "BMI")

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

model_path <- Sys.getenv(
  "K50_PRIMARY_MODEL_RDS",
  unset = file.path(outputs_dir, "k50_long_locomotor_capacity_model_primary.rds")
)

if (!file.exists(model_path)) {
  stop(
    paste0(
      "Exact K50 primary model object is missing. Expected: ",
      model_path,
      ". Run R-scripts/K50/K50.r with --shape LONG --outcome locomotor_capacity first."
    ),
    call. = FALSE
  )
}

fit <- readRDS(model_path)
if (!inherits(fit, "merMod")) {
  stop("Loaded K50 primary model object is not a merMod fit.", call. = FALSE)
}

model_df <- stats::model.frame(fit)
missing_cols <- setdiff(req_cols, names(model_df))
if (length(missing_cols) > 0) {
  stop(
    "Saved K50 model frame is missing required variables: ",
    paste(missing_cols, collapse = ", "),
    call. = FALSE
  )
}

fof_levels <- sort(unique(as.character(stats::na.omit(model_df$FOF_status))))
if (!identical(fof_levels, c("0", "1"))) {
  stop("Saved K50 model frame must use FOF_status levels 0 and 1.", call. = FALSE)
}

time_values <- sort(unique(stats::na.omit(as.numeric(as.character(model_df$time)))))
if (!identical(time_values, c(0, 12))) {
  stop("Saved K50 model frame must use numeric time values 0 and 12.", call. = FALSE)
}

age_mean <- mean(model_df$age, na.rm = TRUE)
bmi_mean <- mean(model_df$BMI, na.rm = TRUE)

emm <- emmeans::emmeans(
  fit,
  specs = ~ FOF_status * time,
  at = list(
    time = c(0, 12),
    age = age_mean,
    BMI = bmi_mean
  ),
  weights = "proportional"
)

pred <- as.data.frame(summary(emm, infer = c(TRUE, TRUE))) %>%
  rename(
    estimate = emmean,
    std.error = SE,
    conf.low = lower.CL,
    conf.high = upper.CL
  ) %>%
  mutate(
    time = as.numeric(as.character(time)),
    FOF_status = as.character(FOF_status),
    time_label = if_else(time == 0, "Baseline", "12 months"),
    FOF_label = if_else(FOF_status == "0", "No FOF", "FOF")
  ) %>%
  select(FOF_status, FOF_label, time, time_label, estimate, std.error, df, conf.low, conf.high) %>%
  arrange(match(FOF_label, c("No FOF", "FOF")), time)

if (nrow(pred) != 4) {
  stop("Exact Figure 2 prediction table must contain exactly four rows.", call. = FALSE)
}
if (!identical(pred$time, c(0, 12, 0, 12))) {
  stop("Exact Figure 2 prediction table must be ordered as baseline/12m within FOF groups.", call. = FALSE)
}

pred_path <- file.path(artifact_dir, "k50_long_locomotor_capacity_fig2_predictions.csv")
readr::write_csv(pred, pred_path, na = "")
append_manifest_safe(
  label = "k50_long_locomotor_capacity_fig2_predictions",
  kind = "table_csv",
  path = pred_path,
  n = nrow(pred),
  notes = "Exact Figure 2 adjusted means and 95% CIs from the saved K50 primary LONG model"
)

plot_tbl <- pred %>% mutate(time_label = factor(time_label, levels = c("Baseline", "12 months")))
fig <- ggplot(plot_tbl, aes(x = time_label, y = estimate, color = FOF_label, group = FOF_label)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.2) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.08, linewidth = 0.6) +
  scale_color_manual(values = c("No FOF" = "#2C7FB8", "FOF" = "#D95F0E")) +
  labs(
    title = "Figure 2. Adjusted locomotor-capacity trajectories by baseline fear of falling",
    x = "Time",
    y = "Adjusted locomotor capacity",
    color = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top")

png_path <- file.path(artifact_dir, "k50_fig2_trajectory_exact.png")
pdf_path <- file.path(artifact_dir, "k50_fig2_trajectory_exact.pdf")
ggsave(filename = png_path, plot = fig, width = 10, height = 6, dpi = 300)
ggsave(filename = pdf_path, plot = fig, width = 10, height = 6)
append_manifest_safe(
  label = "k50_fig2_trajectory_exact_png",
  kind = "figure_png",
  path = png_path,
  n = nrow(pred),
  notes = "Exact Figure 2 PNG from saved K50 primary LONG model"
)
append_manifest_safe(
  label = "k50_fig2_trajectory_exact_pdf",
  kind = "figure_pdf",
  path = pdf_path,
  n = nrow(pred),
  notes = "Exact Figure 2 PDF from saved K50 primary LONG model"
)

session_path <- file.path(artifact_dir, "k50_fig2_trajectory_exact_sessioninfo.txt")
writeLines(capture.output(sessionInfo()), con = session_path)
append_manifest_safe(
  label = "k50_fig2_trajectory_exact_sessioninfo",
  kind = "sessioninfo",
  path = session_path,
  notes = "Session info for exact K50 Figure 2 generation"
)

message("Exact Figure 2 artifacts written to: ", artifact_dir)
