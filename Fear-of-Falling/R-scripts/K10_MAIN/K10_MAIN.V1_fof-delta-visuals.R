#!/usr/bin/env Rscript
# ==============================================================================
# K10_MAIN - Visualizations for FOF and change in composite function
# File tag: K10_MAIN.V1_fof-delta-visuals.R
# Purpose: Plot adjusted and raw mean changes in composite function by FOF status
#
# Outcome: Delta_Composite_Z (12-month change in composite function)
# Predictors: FOF_status_f
# Moderator/interaction: Baseline composite (centered) via cComposite_Z0
# Grouping variable: FOF_status_f (No FOF vs FOF)
# Covariates: Composite_Z0 (centered), age, sex, BMI
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# age, sex, BMI, kaatumisenpelkoOn, ToimintaKykySummary0, ToimintaKykySummary2
#
# Mapping example (raw -> analysis; keep minimal + explicit):
# kaatumisenpelkoOn -> FOF_status_f (No FOF / FOF)
# ToimintaKykySummary0 -> Composite_Z0
# ToimintaKykySummary2 -> Composite_Z12
# Delta_Composite_Z = Composite_Z12 - Composite_Z0
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: N/A (no randomness)
#
# Outputs + manifest:
# - script_label: K10_MAIN (canonical)
# - outputs dir: R-scripts/K10_MAIN/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load raw data (immutable; no edits)
# 03) Standardize vars + QC (sanity checks early)
# 04) Derive/rename vars (document mapping)
# 05) Prepare analysis dataset (complete-case)
# 06) Fit ANCOVA model for adjusted means
# 07) Compute emmeans, Hedges g, raw means + CI
# 08) Save artifacts -> R-scripts/K10_MAIN/outputs/
# 09) Append manifest row per artifact
# 10) Save sessionInfo / renv diagnostics to manifest/
# 11) EOF marker
# ==============================================================================
#
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
  library(ggplot2)
  library(emmeans)
  library(effectsize)
  library(here)
})

# --- Standard init (MANDATORY) -----------------------------------------------
# Derive script_label from --file, supporting file tags like: K10_MAIN.V1_name.R
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K10_MAIN"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K10_MAIN"

source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

cat("================================================================================\n")
cat("K10 FOF Delta Composite Visualizations\n")
cat("Script label:", script_label, "\n")
cat("Outputs dir:", outputs_dir, "\n")
cat("Manifest:", manifest_path, "\n")
cat("Project root:", here::here(), "\n")
cat("================================================================================\n\n")

# --- Load raw data (immutable) -----------------------------------------------
raw_path <- here::here("data", "external", "KaatumisenPelko.csv")
if (!file.exists(raw_path)) stop("Raw data not found: ", raw_path)

raw_data <- readr::read_csv(raw_path, show_col_types = FALSE)

# --- Required columns gate (DO NOT INVENT) ----------------------------------
req_cols <- c(
  "age",
  "sex",
  "BMI",
  "kaatumisenpelkoOn",
  "ToimintaKykySummary0",
  "ToimintaKykySummary2"
)

missing_cols <- setdiff(req_cols, names(raw_data))
if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}

if ("id" %in% names(raw_data) && anyDuplicated(raw_data$id)) {
  stop("Duplicate id rows detected; expected wide format.")
}

fof_vals <- unique(na.omit(raw_data$kaatumisenpelkoOn))
bad_fof <- setdiff(fof_vals, c(0, 1))
if (length(bad_fof) > 0) {
  stop("Unexpected kaatumisenpelkoOn values (expected 0/1): ", paste(bad_fof, collapse = ", "))
}

# --- Minimal QC --------------------------------------------------------------
qc_missingness <- raw_data %>%
  mutate(FOF_status = kaatumisenpelkoOn) %>%
  group_by(FOF_status) %>%
  summarise(
    n = dplyr::n(),
    miss_age = sum(is.na(age)),
    miss_sex = sum(is.na(sex)),
    miss_BMI = sum(is.na(BMI)),
    miss_z0 = sum(is.na(ToimintaKykySummary0)),
    miss_z12 = sum(is.na(ToimintaKykySummary2)),
    .groups = "drop"
  )

qc_path <- file.path(outputs_dir, paste0(script_label, "_qc_missingness_by_fof.csv"))
save_table_csv(qc_missingness, qc_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "qc_missingness_by_fof",
    path = get_relpath(qc_path),
    kind = "table_csv",
    n = nrow(qc_missingness)
  ),
  manifest_path
)

# --- Map variables for analysis ---------------------------------------------
analysis_data <- raw_data %>%
  transmute(
    age = age,
    sex = sex,
    BMI = BMI,
    FOF_status = kaatumisenpelkoOn,
    FOF_status_f = factor(kaatumisenpelkoOn, levels = c(0, 1), labels = c("No FOF", "FOF")),
    Composite_Z0 = ToimintaKykySummary0,
    Composite_Z12 = ToimintaKykySummary2,
    Delta_Composite_Z = ToimintaKykySummary2 - ToimintaKykySummary0
  )

analysis_data_cc <- analysis_data %>%
  select(Delta_Composite_Z, Composite_Z0, FOF_status, FOF_status_f, age, sex, BMI) %>%
  drop_na() %>%
  mutate(
    sex = factor(sex),
    cComposite_Z0 = as.numeric(scale(Composite_Z0, center = TRUE, scale = FALSE))
  )

if (!nrow(analysis_data_cc)) {
  stop("No complete-case data available for K10 model.")
}

# --- Model ------------------------------------------------------------------
model_jn_c <- lm(
  Delta_Composite_Z ~ FOF_status_f * cComposite_Z0 + age + sex + BMI,
  data = analysis_data_cc
)

# --- Adjusted means (emmeans) ------------------------------------------------
emm_fof <- emmeans::emmeans(
  model_jn_c,
  specs = "FOF_status_f",
  at = list(cComposite_Z0 = 0)
) %>%
  as.data.frame() %>%
  mutate(
    FOF_label = dplyr::recode_factor(
      as.character(FOF_status_f),
      `No FOF` = "Ei kaatumisen pelkoa",
      `FOF` = "Kaatumisen pelko"
    )
  )

emm_path <- file.path(outputs_dir, paste0(script_label, "_emmeans_adjusted_means.csv"))
save_table_csv(emm_fof, emm_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "emmeans_adjusted_means",
    path = get_relpath(emm_path),
    kind = "table_csv",
    n = nrow(emm_fof)
  ),
  manifest_path
)

y_range <- range(c(emm_fof$lower.CL, emm_fof$upper.CL, 0), na.rm = TRUE)
y_pad <- 0.1 * diff(y_range)
y_limits <- c(y_range[1] - y_pad, y_range[2] + y_pad)

p_adj <- ggplot(emm_fof, aes(x = FOF_label, y = emmean)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_point(size = 3) +
  geom_errorbar(
    aes(ymin = lower.CL, ymax = upper.CL),
    width = 0.15
  ) +
  coord_cartesian(ylim = y_limits) +
  theme_minimal(base_size = 13) +
  labs(
    x = "FOF-ryhmä",
    y = "Ennustettu muutos fyysisessä toimintakyvyssä (Δ Composite Z)",
    title = "Vakioidut keskiarvot Δ Composite Z -muutokselle",
    subtitle = "FOF 0 vs 1, vakioitu iän, sukupuolen, BMI:n ja lähtötason mukaan"
  )

plot_adj_path <- file.path(outputs_dir, paste0(script_label, "_fof_delta_composite_adj_means.png"))
ggsave(filename = plot_adj_path, plot = p_adj, width = 6, height = 4, dpi = 300)
append_manifest(
  manifest_row(
    script = script_label,
    label = "plot_adj_means",
    path = get_relpath(plot_adj_path),
    kind = "figure_png",
    n = NA_integer_
  ),
  manifest_path
)

# --- Raw means + Hedges g ----------------------------------------------------
raw_summary <- analysis_data_cc %>%
  mutate(
    FOF_label = dplyr::recode_factor(
      as.character(FOF_status),
      `0` = "Ei kaatumisen pelkoa",
      `1` = "Kaatumisen pelko"
    )
  ) %>%
  group_by(FOF_label) %>%
  summarise(
    mean_delta = mean(Delta_Composite_Z, na.rm = TRUE),
    sd_delta = sd(Delta_Composite_Z, na.rm = TRUE),
    n = sum(!is.na(Delta_Composite_Z)),
    se_delta = sd_delta / sqrt(n),
    lower = mean_delta - qt(0.975, df = n - 1) * se_delta,
    upper = mean_delta + qt(0.975, df = n - 1) * se_delta,
    .groups = "drop"
  )

raw_summary_path <- file.path(outputs_dir, paste0(script_label, "_raw_means_ci.csv"))
save_table_csv(raw_summary, raw_summary_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "raw_means_ci",
    path = get_relpath(raw_summary_path),
    kind = "table_csv",
    n = nrow(raw_summary)
  ),
  manifest_path
)

g_obj <- effectsize::hedges_g(
  Delta_Composite_Z ~ FOF_status,
  data = analysis_data_cc,
  ci = 0.95
)
g_df <- as.data.frame(g_obj)
g_path <- file.path(outputs_dir, paste0(script_label, "_hedges_g.csv"))
save_table_csv(g_df, g_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "hedges_g",
    path = get_relpath(g_path),
    kind = "table_csv",
    n = nrow(g_df)
  ),
  manifest_path
)

g_col <- c("Hedges_g", "SMD", "g")[
  c("Hedges_g", "SMD", "g") %in% names(g_df)
][1]
g_hat <- if (!is.na(g_col)) g_df[[g_col]][1] else NA_real_

y_range2 <- range(c(raw_summary$lower, raw_summary$upper, 0), na.rm = TRUE)
y_pad2 <- 0.1 * diff(y_range2)
y_limits2 <- c(y_range2[1] - y_pad2, y_range2[2] + y_pad2)

p_raw <- ggplot(raw_summary, aes(x = FOF_label, y = mean_delta)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_point(size = 3) +
  geom_errorbar(
    aes(ymin = lower, ymax = upper),
    width = 0.15
  ) +
  coord_cartesian(ylim = y_limits2) +
  theme_minimal(base_size = 13) +
  labs(
    x = "FOF-ryhmä",
    y = "Keskimääräinen muutos fyysisessä toimintakyvyssä (Δ Composite Z)",
    title = "Raakakeskiarvot Δ Composite Z -muutokselle FOF-ryhmittäin",
    subtitle = if (is.na(g_hat)) {
      "Hedges g: NA"
    } else {
      paste0("Hedges g (FOF 1 vs 0) ≈ ", round(g_hat, 2))
    }
  )

plot_raw_path <- file.path(outputs_dir, paste0(script_label, "_fof_delta_composite_raw_means.png"))
ggsave(filename = plot_raw_path, plot = p_raw, width = 6, height = 4, dpi = 300)
append_manifest(
  manifest_row(
    script = script_label,
    label = "plot_raw_means",
    path = get_relpath(plot_raw_path),
    kind = "figure_png",
    n = NA_integer_
  ),
  manifest_path
)

# --- Summary text ------------------------------------------------------------
txt_path <- file.path(outputs_dir, paste0(script_label, "_summary.txt"))
writeLines(
  c(
    "K10_MAIN FOF delta composite visualizations",
    paste0("N complete-case: ", nrow(analysis_data_cc)),
    "Model: Delta_Composite_Z ~ FOF_status * cComposite_Z0 + age + sex + BMI",
    "See CSV outputs for emmeans, raw means, and Hedges g."
  ),
  con = txt_path
)
append_manifest(
  manifest_row(
    script = script_label,
    label = "summary_txt",
    path = get_relpath(txt_path),
    kind = "text",
    n = NA_integer_
  ),
  manifest_path
)

# --- Session info -----------------------------------------------------------
save_sessioninfo_manifest()
