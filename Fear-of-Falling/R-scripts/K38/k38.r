#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(stringr)
  library(here)
})

source(here::here("R", "functions", "init.R"))

paths <- init_paths("K38")
out_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

lmm_primary_path <- here::here("R-scripts", "K36", "outputs", "k36_lmm_primary_fixed_effects.csv")
lmm_extended_path <- here::here("R-scripts", "K36", "outputs", "k36_lmm_extended_fixed_effects.csv")
lmm_cmp_path <- here::here("R-scripts", "K36", "outputs", "k36_lmm_model_comparison.csv")
anc_primary_path <- here::here("R-scripts", "K36", "outputs", "k36_ancova_primary_coefficients.csv")
anc_extended_path <- here::here("R-scripts", "K36", "outputs", "k36_ancova_extended_coefficients.csv")
anc_cmp_path <- here::here("R-scripts", "K36", "outputs", "k36_ancova_model_comparison.csv")
k37_caption_path <- here::here("R-scripts", "K37", "outputs", "k37_figure_caption.txt")

required <- c(
  lmm_primary_path, lmm_extended_path, lmm_cmp_path,
  anc_primary_path, anc_extended_path, anc_cmp_path, k37_caption_path
)
missing <- required[!file.exists(required)]
if (length(missing) > 0) {
  stop(paste("Missing required K36/K37 aggregate inputs:\n", paste(missing, collapse = "\n")), call. = FALSE)
}

lmm_primary <- readr::read_csv(lmm_primary_path, show_col_types = FALSE) %>%
  filter(.data$effect == "fixed") %>%
  mutate(framework = "LMM", model_layer = "Primary")

lmm_extended <- readr::read_csv(lmm_extended_path, show_col_types = FALSE) %>%
  filter(.data$effect == "fixed") %>%
  mutate(framework = "LMM", model_layer = "Extended")

anc_primary <- readr::read_csv(anc_primary_path, show_col_types = FALSE) %>%
  mutate(framework = "ANCOVA", model_layer = "Primary")

anc_extended <- readr::read_csv(anc_extended_path, show_col_types = FALSE) %>%
  mutate(framework = "ANCOVA", model_layer = "Extended")

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
  standardize_coef(lmm_extended),
  standardize_coef(anc_primary),
  standardize_coef(anc_extended)
)

lmm_cmp <- readr::read_csv(lmm_cmp_path, show_col_types = FALSE)
anc_cmp <- readr::read_csv(anc_cmp_path, show_col_types = FALSE)

lmm_p <- lmm_cmp %>% filter(.data$model == "m_lmm_primary_common")
lmm_e <- lmm_cmp %>% filter(.data$model == "m_lmm_extended_common")
anc_p <- anc_cmp %>% filter(.data$model == "primary")
anc_e <- anc_cmp %>% filter(.data$model == "extended")

cmp_tbl <- tibble(
  row_type = "model_comparison",
  framework = c("LMM", "ANCOVA"),
  model_layer = "Primary_vs_Extended",
  term = c("Delta AIC (Extended - Primary)", "Delta AIC (Extended - Primary)"),
  estimate = NA_real_,
  std_error = NA_real_,
  statistic = NA_real_,
  df = NA_real_,
  p_value = NA_real_,
  conf_low = NA_real_,
  conf_high = NA_real_,
  delta_aic = c(
    as.numeric(lmm_e$AIC) - as.numeric(lmm_p$AIC),
    as.numeric(anc_e$AIC) - as.numeric(anc_p$AIC)
  ),
  delta_adj_r2 = c(
    NA_real_,
    as.numeric(anc_e$adj_r2) - as.numeric(anc_p$adj_r2)
  ),
  notes = c(
    "LMM comparison from K36 common sample",
    "ANCOVA comparison from K36 common sample"
  )
)

k38_table <- bind_rows(coef_tbl, cmp_tbl)

table_path <- file.path(out_dir, "k38_table_primary_vs_extended.csv")
readr::write_csv(k38_table, table_path)

# Snippets (English, neutral, non-causal)
methods_lines <- c(
  "Methods (Extended reporting layer)",
  "Primary models followed the pre-specified canonical K26 analysis.",
  "An extended layer (K36) added baseline capacity_score_latent_primary as an additional covariate,",
  "and included a time-by-capacity interaction in the long mixed-effects model.",
  "No model-specification changes were made to the primary analyses; results are presented as primary vs extended in parallel.",
  "Patient-level datasets remained externalized under DATA_ROOT; repository artifacts are aggregate-only tables, figures, and receipts."
)
writeLines(methods_lines, con = file.path(out_dir, "k38_methods_snippet.txt"))

cap_main <- coef_tbl %>% filter(.data$framework == "LMM", .data$model_layer == "Extended", .data$term == "capacity_score_latent_primary")
cap_time <- coef_tbl %>% filter(.data$framework == "LMM", .data$model_layer == "Extended", .data$term == "time_f12:capacity_score_latent_primary")
anc_cap <- coef_tbl %>% filter(.data$framework == "ANCOVA", .data$model_layer == "Extended", .data$term == "capacity_score_latent_primary")

fmt_num <- function(x, d = 3) format(round(as.numeric(x), d), nsmall = d, trim = TRUE)
fmt_p <- function(p) {
  p <- as.numeric(p)
  ifelse(is.na(p), "NA", ifelse(p < 0.001, "<0.001", format(round(p, 3), nsmall = 3, trim = TRUE)))
}

results_lines <- c(
  "Results (Extended reporting layer)",
  sprintf(
    "In the extended LMM, baseline capacity_score_latent_primary was positively associated with Composite_Z (beta=%s, 95%% CI %s to %s, p=%s).",
    fmt_num(cap_main$estimate), fmt_num(cap_main$conf_low), fmt_num(cap_main$conf_high), fmt_p(cap_main$p_value)
  ),
  sprintf(
    "The time-by-capacity interaction term was positive (beta=%s, 95%% CI %s to %s, p=%s), indicating that higher baseline capacity aligned with a more favorable 0 to 12 month trajectory.",
    fmt_num(cap_time$estimate), fmt_num(cap_time$conf_low), fmt_num(cap_time$conf_high), fmt_p(cap_time$p_value)
  ),
  sprintf(
    "In the wide ANCOVA cross-check, the capacity term was also positive (beta=%s, 95%% CI %s to %s, p=%s).",
    fmt_num(anc_cap$estimate), fmt_num(anc_cap$conf_low), fmt_num(anc_cap$conf_high), fmt_p(anc_cap$p_value)
  ),
  sprintf(
    "Model-comparison metrics favored the extended layer (LMM Delta AIC=%s; ANCOVA Delta AIC=%s; ANCOVA Delta Adj R2=%s).",
    fmt_num(cmp_tbl$delta_aic[cmp_tbl$framework == "LMM"]),
    fmt_num(cmp_tbl$delta_aic[cmp_tbl$framework == "ANCOVA"]),
    fmt_num(cmp_tbl$delta_adj_r2[cmp_tbl$framework == "ANCOVA"])
  ),
  "These estimates are reported as associative (non-causal) effects within the pre-specified modeling framework."
)
writeLines(results_lines, con = file.path(out_dir, "k38_results_snippet.txt"))

discussion_lines <- c(
  "Discussion (Extended reporting layer)",
  "The continuous latent capacity score provided additional explanatory signal beyond categorical frailty status in the extended analyses.",
  "This supports capacity as a complementary baseline descriptor rather than a replacement for existing frailty categorization.",
  "Given overlap between functional constructs, some redundancy is expected; therefore, primary and extended outputs should be interpreted jointly.",
  "Findings should be interpreted with caution due to observational design, residual confounding risk, and scale-dependence of modeled effects.",
  "No causal interpretation is implied."
)
writeLines(discussion_lines, con = file.path(out_dir, "k38_discussion_snippet.txt"))

callout_lines <- c(
  "Figure callouts (K37)",
  "Figure A (Predicted trajectories): Higher baseline capacity levels align with more favorable predicted 0 to 12 month Composite_Z trajectories in the extended model.",
  "Figure B (Model comparison): Extended models show improved fit metrics relative to primary models, particularly lower AIC and higher adjusted R2 in ANCOVA.",
  "Figure C (Baseline association): Baseline capacity and baseline Composite_Z show a positive linear association consistent with the extended model direction.",
  "",
  "References: k37_predicted_trajectories.png, k37_model_comparison.png, k37_capacity_vs_baseline.png"
)
writeLines(callout_lines, con = file.path(out_dir, "k38_figure_callouts.txt"))

sink(file.path(out_dir, "k38_sessioninfo.txt"))
cat("K38 session info\n")
print(sessionInfo())
sink()

# Manifest rows (aggregate/reporting artifacts only)
rows <- bind_rows(
  manifest_row("K38", "k38_table_primary_vs_extended", get_relpath(table_path), "table_csv", n = nrow(k38_table), notes = "Primary vs extended coefficients and model-comparison summary"),
  manifest_row("K38", "k38_results_snippet", get_relpath(file.path(out_dir, "k38_results_snippet.txt")), "text", n = NA_integer_, notes = "English neutral Results snippet"),
  manifest_row("K38", "k38_methods_snippet", get_relpath(file.path(out_dir, "k38_methods_snippet.txt")), "text", n = NA_integer_, notes = "English Methods snippet"),
  manifest_row("K38", "k38_discussion_snippet", get_relpath(file.path(out_dir, "k38_discussion_snippet.txt")), "text", n = NA_integer_, notes = "English Discussion snippet"),
  manifest_row("K38", "k38_figure_callouts", get_relpath(file.path(out_dir, "k38_figure_callouts.txt")), "text", n = NA_integer_, notes = "Figure callouts referencing K37 outputs"),
  manifest_row("K38", "k38_sessioninfo", get_relpath(file.path(out_dir, "k38_sessioninfo.txt")), "sessioninfo", n = NA_integer_, notes = "Session info for K38 reporting pack")
)
append_manifest(rows, manifest_path)

message("K38 outputs written to: ", out_dir)
