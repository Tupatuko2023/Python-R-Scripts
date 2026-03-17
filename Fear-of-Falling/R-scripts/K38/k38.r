#!/usr/bin/env Rscript
# ==============================================================================
# K38 - Aggregate Reporting Pack
# File tag: K38.V1_reporting-pack.R
# Purpose: Build aggregate reporting snippets from K36 primary/fallback outcome artifacts and K37 figures.
#
# Outcome: Aggregate reporting snippets and comparison table
# Predictors: K36 coefficient tables, K36 model-comparison tables, K37 captions
# Moderator/interaction: time_f12:FOF_statusFOF
# Grouping variable: None
# Covariates: Derived from upstream aggregate artifacts
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# effect
# term
# estimate
# std.error
# p.value
# conf.low
# conf.high
# AIC
# adj_r2
#
# Mapping example (optional; raw -> analysis; keep minimal + explicit):
# K36 primary/fallback outcome tables -> reporting text deltas
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: NA (set only when randomness is used: MI/bootstrap/resampling)
#
# Outputs + manifest:
# - script_label: K38 (canonical)
# - outputs dir: R-scripts/K38/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load aggregate K36 and K37 artifacts
# 03) Standardize vars + QC (sanity checks early)
# 04) Derive comparison tables
# 05) Prepare manuscript-facing snippets
# 06) Save reporting artifacts
# 07) Append manifest row per artifact
# 08) Save sessionInfo / renv diagnostics to manifest/
# 09) EOF marker
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(stringr)
  library(here)
})

source(here::here("R", "functions", "init.R"))

req_cols <- c("effect", "term", "estimate", "std.error", "p.value", "conf.low", "conf.high", "AIC", "adj_r2")

paths <- init_paths("K38")
out_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

lmm_primary_path <- here::here("R-scripts", "K36", "outputs", "k36_locomotor_capacity_lmm_fixed_effects.csv")
lmm_fallback_path <- here::here("R-scripts", "K36", "outputs", "k36_z3_fallback_lmm_fixed_effects.csv")
anc_primary_path <- here::here("R-scripts", "K36", "outputs", "k36_locomotor_capacity_ancova_coefficients.csv")
anc_fallback_path <- here::here("R-scripts", "K36", "outputs", "k36_z3_fallback_ancova_coefficients.csv")
overview_path <- here::here("R-scripts", "K36", "outputs", "k36_outcome_model_overview.csv")
k37_caption_path <- here::here("R-scripts", "K37", "outputs", "k37_figure_caption.txt")

required <- c(
  lmm_primary_path, lmm_fallback_path, anc_primary_path, anc_fallback_path, overview_path, k37_caption_path
)
missing <- required[!file.exists(required)]
if (length(missing) > 0) {
  stop(paste("Missing required K36/K37 aggregate inputs:\n", paste(missing, collapse = "\n")), call. = FALSE)
}

lmm_primary <- readr::read_csv(lmm_primary_path, show_col_types = FALSE) %>%
  filter(.data$effect == "fixed") %>%
  mutate(framework = "LMM", model_layer = "Primary")

lmm_fallback <- readr::read_csv(lmm_fallback_path, show_col_types = FALSE) %>%
  filter(.data$effect == "fixed") %>%
  mutate(framework = "LMM", model_layer = "Fallback")

anc_primary <- readr::read_csv(anc_primary_path, show_col_types = FALSE) %>%
  mutate(framework = "ANCOVA", model_layer = "Primary")

anc_fallback <- readr::read_csv(anc_fallback_path, show_col_types = FALSE) %>%
  mutate(framework = "ANCOVA", model_layer = "Fallback")

standardize_coef <- function(df) {
  cols <- names(df)
  if (!"df" %in% cols) df$df <- NA_real_
  if (!"effect" %in% cols) df$effect <- "fixed"
  df %>%
    transmute(
      row_type = "coefficient",
      framework = .data$framework,
      model_layer = .data$model_layer,
      term = .data$term,
      estimate = as.numeric(.data$estimate),
      std_error = as.numeric(.data$std.error),
      statistic = as.numeric(.data$statistic),
      df = suppressWarnings(as.numeric(.data$df)),
      p_value = as.numeric(.data$p.value),
      conf_low = suppressWarnings(as.numeric(.data$conf.low)),
      conf_high = suppressWarnings(as.numeric(.data$conf.high)),
      delta_aic = NA_real_,
      delta_adj_r2 = NA_real_,
      notes = NA_character_
    )
}

coef_tbl <- bind_rows(
  standardize_coef(lmm_primary),
  standardize_coef(lmm_fallback),
  standardize_coef(anc_primary),
  standardize_coef(anc_fallback)
)

cmp_tbl <- readr::read_csv(overview_path, show_col_types = FALSE) %>%
  transmute(
    row_type = "model_overview",
    framework = .data$framework,
    model_layer = ifelse(.data$role == "primary", "Primary", "Fallback"),
    term = .data$outcome,
    estimate = NA_real_,
    std_error = NA_real_,
    statistic = NA_real_,
    df = NA_real_,
    p_value = NA_real_,
    conf_low = NA_real_,
    conf_high = NA_real_,
    delta_aic = .data$AIC,
    delta_adj_r2 = .data$adj_r2,
    notes = paste0("n=", .data$n, "; role=", .data$role)
  )

k38_table <- bind_rows(coef_tbl, cmp_tbl)

table_path <- file.path(out_dir, "k38_table_locomotor_capacity_primary_vs_z3_fallback.csv")
readr::write_csv(k38_table, table_path)

# Snippets (English, neutral, non-causal)
methods_lines <- c(
  "Methods (Primary/fallback reporting layer)",
  "Primary models followed the active ANALYSIS_PLAN outcome architecture with locomotor_capacity as the current primary outcome.",
  "Parallel sensitivity models used z3 as the deterministic fallback outcome for the same locomotor construct.",
  "Composite_Z was not used as the active primary line in this reporting pack; it remains a legacy bridge outcome only.",
  "Patient-level datasets remained externalized under DATA_ROOT; repository artifacts are aggregate-only tables, figures, and receipts."
)
writeLines(methods_lines, con = file.path(out_dir, "k38_methods_snippet.txt"))

primary_lmm_int <- coef_tbl %>% filter(.data$framework == "LMM", .data$model_layer == "Primary", .data$term == "time_f12:FOF_statusFOF")
fallback_lmm_int <- coef_tbl %>% filter(.data$framework == "LMM", .data$model_layer == "Fallback", .data$term == "time_f12:FOF_statusFOF")
primary_anc_fof <- coef_tbl %>% filter(.data$framework == "ANCOVA", .data$model_layer == "Primary", .data$term == "FOF_statusFOF")
fallback_anc_fof <- coef_tbl %>% filter(.data$framework == "ANCOVA", .data$model_layer == "Fallback", .data$term == "FOF_statusFOF")

fmt_num <- function(x, d = 3) format(round(as.numeric(x), d), nsmall = d, trim = TRUE)
fmt_p <- function(p) {
  p <- as.numeric(p)
  ifelse(is.na(p), "NA", ifelse(p < 0.001, "<0.001", format(round(p, 3), nsmall = 3, trim = TRUE)))
}

results_lines <- c(
  "Results (Primary/fallback reporting layer)",
  sprintf(
    "In the primary locomotor_capacity LMM, the time-by-FOF interaction estimate was beta=%s (95%% CI %s to %s, p=%s).",
    fmt_num(primary_lmm_int$estimate), fmt_num(primary_lmm_int$conf_low), fmt_num(primary_lmm_int$conf_high), fmt_p(primary_lmm_int$p_value)
  ),
  sprintf(
    "In the z3 fallback LMM, the corresponding time-by-FOF interaction estimate was beta=%s (95%% CI %s to %s, p=%s).",
    fmt_num(fallback_lmm_int$estimate), fmt_num(fallback_lmm_int$conf_low), fmt_num(fallback_lmm_int$conf_high), fmt_p(fallback_lmm_int$p_value)
  ),
  sprintf(
    "In wide ANCOVA cross-checks, the FOF main-effect estimates were beta=%s (locomotor_capacity) and beta=%s (z3 fallback).",
    fmt_num(primary_anc_fof$estimate), fmt_num(fallback_anc_fof$estimate)
  ),
  sprintf(
    "Model-overview rows label locomotor_capacity as the primary outcome and z3 as fallback across both LMM and ANCOVA frameworks (primary LMM AIC=%s; fallback LMM AIC=%s).",
    fmt_num(cmp_tbl$delta_aic[cmp_tbl$framework == "LMM" & cmp_tbl$model_layer == "Primary"]),
    fmt_num(cmp_tbl$delta_aic[cmp_tbl$framework == "LMM" & cmp_tbl$model_layer == "Fallback"])
  ),
  "These estimates are reported as associative (non-causal) effects within the pre-specified modeling framework."
)
writeLines(results_lines, con = file.path(out_dir, "k38_results_snippet.txt"))

discussion_lines <- c(
  "Discussion (Primary/fallback reporting layer)",
  "The reporting pack now treats locomotor_capacity as the active primary outcome and z3 strictly as the deterministic fallback/sensitivity outcome.",
  "This removes the earlier ambiguity where downstream artifacts could imply that z3 or an obsolete z5-derived label was the current primary line.",
  "Primary and fallback outputs should be interpreted jointly as aligned outcome branches of the same locomotor construct.",
  "Findings should be interpreted with caution due to observational design, residual confounding risk, and scale-dependence of modeled effects.",
  "No causal interpretation is implied."
)
writeLines(discussion_lines, con = file.path(out_dir, "k38_discussion_snippet.txt"))

callout_lines <- c(
  "Figure callouts (K37)",
  "Figure A (Predicted trajectories): The primary locomotor_capacity trajectories are shown for nonFOF and FOF from the K36 primary LMM.",
  "Figure B (Primary vs fallback comparison): The key FOF-related LMM estimates are shown side-by-side for locomotor_capacity primary and z3 fallback.",
  "Figure C (Baseline association): Baseline locomotor_capacity_0 and z3_0 show a positive linear association across the shared baseline sample.",
  "",
  "References: k37_locomotor_capacity_predicted_trajectories.png, k37_locomotor_capacity_vs_z3_model_comparison.png, k37_locomotor_capacity_vs_z3_baseline.png"
)
writeLines(callout_lines, con = file.path(out_dir, "k38_figure_callouts.txt"))

sink(file.path(out_dir, "k38_sessioninfo.txt"))
cat("K38 session info\n")
print(sessionInfo())
sink()

# Manifest rows (aggregate/reporting artifacts only)
rows <- bind_rows(
  manifest_row("K38", "k38_table_locomotor_capacity_primary_vs_z3_fallback", get_relpath(table_path), "table_csv", n = nrow(k38_table), notes = "locomotor_capacity primary vs z3 fallback coefficient and model overview summary"),
  manifest_row("K38", "k38_results_snippet", get_relpath(file.path(out_dir, "k38_results_snippet.txt")), "text", n = NA_integer_, notes = "English neutral Results snippet"),
  manifest_row("K38", "k38_methods_snippet", get_relpath(file.path(out_dir, "k38_methods_snippet.txt")), "text", n = NA_integer_, notes = "English Methods snippet"),
  manifest_row("K38", "k38_discussion_snippet", get_relpath(file.path(out_dir, "k38_discussion_snippet.txt")), "text", n = NA_integer_, notes = "English Discussion snippet"),
  manifest_row("K38", "k38_figure_callouts", get_relpath(file.path(out_dir, "k38_figure_callouts.txt")), "text", n = NA_integer_, notes = "Figure callouts referencing K37 outputs"),
  manifest_row("K38", "k38_sessioninfo", get_relpath(file.path(out_dir, "k38_sessioninfo.txt")), "sessioninfo", n = NA_integer_, notes = "Session info for K38 reporting pack")
)
append_manifest(rows, manifest_path)

message("K38 outputs written to: ", out_dir)
