#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(ggplot2)
})

root_dir <- here::here()
output_dir <- file.path(root_dir, "R-scripts", "K22", "outputs", "sls_predicts_change_and_level")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
manifest_path <- file.path(root_dir, "manifest", "manifest.csv")

# Prefer K15-derived analysis_data (contains canonical frailty + SLS derivations)
rdata_path <- file.path(root_dir, "R-scripts", "K15", "outputs", "K15.3._frailty_analysis_data.RData")
source_used <- NA_character_

if (file.exists(rdata_path)) {
  load(rdata_path)
  if (!exists("analysis_data")) stop("K15 RData exists but analysis_data object missing.")
  df <- analysis_data
  source_used <- "K15.3._frailty_analysis_data.RData"
} else {
  csv_path <- file.path(root_dir, "data", "external", "KaatumisenPelko.csv")
  if (!file.exists(csv_path)) stop("Missing data/external/KaatumisenPelko.csv")
  df <- readr::read_csv(csv_path, show_col_types = FALSE)
  source_used <- "data/external/KaatumisenPelko.csv"
}

# Canonical construction helpers
if (!("FOF_status" %in% names(df)) && ("kaatumisenpelkoOn" %in% names(df))) {
  df <- df %>% mutate(FOF_status = if_else(kaatumisenpelkoOn == 1, 1L, 0L))
}

if (!("Composite_Z0" %in% names(df)) && ("ToimintaKykySummary0" %in% names(df))) {
  df <- df %>% mutate(Composite_Z0 = as.numeric(ToimintaKykySummary0))
}
if (!("Composite_Z3" %in% names(df)) && ("ToimintaKykySummary2" %in% names(df))) {
  df <- df %>% mutate(Composite_Z3 = as.numeric(ToimintaKykySummary2))
}
if (!("Composite_Z3" %in% names(df)) && ("Composite_Z2" %in% names(df))) {
  df <- df %>% mutate(Composite_Z3 = as.numeric(Composite_Z2))
}

# SLS alias logic copied from K15.3 principle
balance_aliases <- c(
  "single_leg_stance", "single leg stance", "one_leg_stance", "one-leg stance",
  "one_leg_balance", "one leg balance", "SLS", "sls",
  "z_Seisominen0", "Seisominen0", "z_Seisominen2", "Seisominen2"
)

pick_alias <- function(nms, aliases) {
  for (a in aliases) {
    hit <- nms[tolower(nms) == tolower(a)]
    if (length(hit) > 0) return(hit[[1]])
  }
  NA_character_
}

selected_sls_col <- NA_character_
if ("single_leg_stance" %in% names(df)) {
  selected_sls_col <- "single_leg_stance"
} else {
  selected_sls_col <- pick_alias(names(df), balance_aliases)
  if (!is.na(selected_sls_col)) {
    df <- df %>% mutate(single_leg_stance = as.numeric(.data[[selected_sls_col]]))
  }
}

if (!("single_leg_stance" %in% names(df))) {
  stop("MISSING COLUMN: single_leg_stance not found and no alias matched.")
}

if (!("single_leg_stance_clean" %in% names(df))) {
  df <- df %>% mutate(
    single_leg_stance_clean = dplyr::case_when(
      is.na(single_leg_stance) ~ NA_real_,
      single_leg_stance < 0 ~ NA_real_,
      TRUE ~ as.numeric(single_leg_stance)
    )
  )
}

if (!("delta_composite_z" %in% names(df))) {
  if (!("Composite_Z0" %in% names(df)) || !("Composite_Z3" %in% names(df))) {
    stop("MISSING COLUMN: cannot build delta_composite_z (need Composite_Z0 and Composite_Z3)")
  }
  df <- df %>% mutate(delta_composite_z = as.numeric(Composite_Z3) - as.numeric(Composite_Z0))
}

if (!("sex" %in% names(df))) stop("MISSING COLUMN: sex")
if (!("age" %in% names(df))) stop("MISSING COLUMN: age")
if (!("BMI" %in% names(df))) stop("MISSING COLUMN: BMI")
if (!("FOF_status" %in% names(df))) stop("MISSING COLUMN: FOF_status")

# Harmonize types
as_factor01 <- function(x) {
  if (is.factor(x)) return(x)
  vals <- suppressWarnings(as.numeric(x))
  if (all(is.na(vals))) return(as.factor(x))
  factor(vals)
}

df <- df %>% mutate(
  FOF_status = as_factor01(FOF_status),
  sex = as_factor01(sex),
  age = as.numeric(age),
  BMI = as.numeric(BMI),
  single_leg_stance_clean = as.numeric(single_leg_stance_clean),
  SLS10 = single_leg_stance_clean / 10
)

# Utility
extract_coef_table <- function(model, model_id) {
  sm <- summary(model)$coefficients
  if (is.null(dim(sm))) return(tibble())
  ci <- tryCatch(confint(model), error = function(e) NULL)
  terms <- rownames(sm)
  tib <- tibble(
    model_id = model_id,
    term = terms,
    estimate = as.numeric(sm[, 1]),
    std_error = as.numeric(sm[, 2]),
    statistic = as.numeric(sm[, 3]),
    p_value = as.numeric(sm[, 4])
  )
  if (!is.null(ci)) {
    ci_df <- tibble(term = rownames(ci), conf_low = as.numeric(ci[, 1]), conf_high = as.numeric(ci[, 2]))
    tib <- tib %>% left_join(ci_df, by = "term")
  } else {
    tib <- tib %>% mutate(conf_low = NA_real_, conf_high = NA_real_)
  }
  tib
}

metric_row <- function(model, model_id, n, note = NA_character_) {
  s <- summary(model)
  tibble(
    model_id = model_id,
    n_complete = n,
    aic = AIC(model),
    r_squared = unname(s$r.squared),
    adj_r_squared = unname(s$adj.r.squared),
    note = note
  )
}

# Build model datasets (complete-case per model)
base_vars <- c("delta_composite_z", "Composite_Z3", "Composite_Z0", "single_leg_stance_clean", "SLS10", "FOF_status", "age", "sex", "BMI")

cc_delta <- df %>% dplyr::select(all_of(base_vars)) %>% filter(complete.cases(.))
cc_ancova <- cc_delta
cc_delta_n <- nrow(cc_delta)
cc_ancova_n <- nrow(cc_ancova)

if (cc_delta_n < 30) stop("Too few complete cases for primary delta model.")

# Models
m_delta_linear <- lm(delta_composite_z ~ single_leg_stance_clean + FOF_status + age + sex + BMI, data = cc_delta)
m_delta_linear_sls10 <- lm(delta_composite_z ~ SLS10 + FOF_status + age + sex + BMI, data = cc_delta)
m_ancova <- lm(Composite_Z3 ~ Composite_Z0 + single_leg_stance_clean + FOF_status + age + sex + BMI, data = cc_ancova)
m_delta_spline <- lm(delta_composite_z ~ splines::ns(single_leg_stance_clean, df = 3) + FOF_status + age + sex + BMI, data = cc_delta)
m_delta_interaction <- lm(delta_composite_z ~ single_leg_stance_clean * FOF_status + age + sex + BMI, data = cc_delta)

spline_cmp <- anova(m_delta_linear, m_delta_spline)
spline_p <- tryCatch(as.numeric(spline_cmp$`Pr(>F)`[2]), error = function(e) NA_real_)

# Overadjustment diagnostics (frailty balance proxy)
overadjust_note <- "frailty_cat_3_balance unavailable"
corr_sls_frail <- NA_real_
se_sls_m_sls <- NA_real_
se_sls_m_both <- NA_real_
cond_num_m_both <- NA_real_

models_over <- list()
if ("frailty_cat_3_balance" %in% names(df)) {
  cc_over <- df %>%
    dplyr::select(delta_composite_z, single_leg_stance_clean, FOF_status, age, sex, BMI, frailty_cat_3_balance, frailty_count_3_balance) %>%
    filter(complete.cases(delta_composite_z, single_leg_stance_clean, FOF_status, age, sex, BMI, frailty_cat_3_balance))

  if (nrow(cc_over) >= 30) {
    cc_over <- cc_over %>% mutate(frailty_cat_3_balance = factor(frailty_cat_3_balance))
    m_sls <- lm(delta_composite_z ~ single_leg_stance_clean + FOF_status + age + sex + BMI, data = cc_over)
    m_frailB <- lm(delta_composite_z ~ frailty_cat_3_balance + FOF_status + age + sex + BMI, data = cc_over)
    m_both <- lm(delta_composite_z ~ single_leg_stance_clean + frailty_cat_3_balance + FOF_status + age + sex + BMI, data = cc_over)

    models_over <- list(m_sls = m_sls, m_frailB = m_frailB, m_both = m_both, n = nrow(cc_over))

    corr_sls_frail <- if ("frailty_count_3_balance" %in% names(cc_over)) {
      suppressWarnings(cor(cc_over$single_leg_stance_clean, cc_over$frailty_count_3_balance, use = "complete.obs"))
    } else NA_real_

    se_sls_m_sls <- summary(m_sls)$coefficients["single_leg_stance_clean", "Std. Error"]
    se_sls_m_both <- summary(m_both)$coefficients["single_leg_stance_clean", "Std. Error"]
    cond_num_m_both <- kappa(model.matrix(m_both), exact = FALSE)
    overadjust_note <- "diagnostic models fit"
  } else {
    overadjust_note <- "frailty_cat_3_balance present but insufficient complete cases"
  }
}

# Missingness and floor/ceiling
sls_missing_pct <- mean(is.na(df$single_leg_stance_clean)) * 100
delta_missing_pct <- mean(is.na(df$delta_composite_z)) * 100
sls_non_na <- df$single_leg_stance_clean[!is.na(df$single_leg_stance_clean)]
prop_zero <- if (length(sls_non_na) > 0) mean(sls_non_na == 0) * 100 else NA_real_
prop_max <- if (length(sls_non_na) > 0) mean(sls_non_na == max(sls_non_na, na.rm = TRUE)) * 100 else NA_real_

# Collect outputs
coef_tabs <- bind_rows(
  extract_coef_table(m_delta_linear, "delta_linear_sls"),
  extract_coef_table(m_delta_linear_sls10, "delta_linear_sls10"),
  extract_coef_table(m_ancova, "ancova_level_sls"),
  extract_coef_table(m_delta_spline, "delta_spline_df3"),
  extract_coef_table(m_delta_interaction, "delta_interaction_sls_x_fof")
)

if (length(models_over) > 0) {
  coef_tabs <- bind_rows(
    coef_tabs,
    extract_coef_table(models_over$m_sls, "overadj_sls_only"),
    extract_coef_table(models_over$m_frailB, "overadj_frailty_balance_only"),
    extract_coef_table(models_over$m_both, "overadj_both_sls_plus_frailty_balance")
  )
}

metrics <- bind_rows(
  metric_row(m_delta_linear, "delta_linear_sls", cc_delta_n),
  metric_row(m_delta_linear_sls10, "delta_linear_sls10", cc_delta_n),
  metric_row(m_ancova, "ancova_level_sls", cc_ancova_n),
  metric_row(m_delta_spline, "delta_spline_df3", cc_delta_n, note = paste0("anova_vs_linear_p=", round(spline_p, 6))),
  metric_row(m_delta_interaction, "delta_interaction_sls_x_fof", cc_delta_n)
)

if (length(models_over) > 0) {
  metrics <- bind_rows(
    metrics,
    metric_row(models_over$m_sls, "overadj_sls_only", models_over$n),
    metric_row(models_over$m_frailB, "overadj_frailty_balance_only", models_over$n),
    metric_row(models_over$m_both, "overadj_both_sls_plus_frailty_balance", models_over$n,
               note = paste0("corr_sls_frailty_count3_balance=", round(corr_sls_frail, 4),
                             "; se_sls_only=", round(se_sls_m_sls, 6),
                             "; se_sls_both=", round(se_sls_m_both, 6),
                             "; cond_number=", round(cond_num_m_both, 2)))
  )
}

fixed_path <- file.path(output_dir, "K22_sls_models_fixed_effects.csv")
metrics_path <- file.path(output_dir, "K22_sls_model_metrics.csv")
md_path <- file.path(output_dir, "K22_sls_evidence_note.md")
fig_path <- file.path(output_dir, "K22_sls_delta_vs_sls.png")

readr::write_csv(coef_tabs, fixed_path)
readr::write_csv(metrics, metrics_path)

# Figure (single panel, no manual colors)
p <- ggplot(cc_delta, aes(x = single_leg_stance_clean, y = delta_composite_z)) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", se = TRUE) +
  geom_smooth(method = "loess", se = FALSE, linetype = 2) +
  theme_minimal() +
  labs(
    title = "delta_composite_z vs baseline single_leg_stance",
    subtitle = "Linear fit (solid) and loess trend (dashed)",
    x = "single_leg_stance (baseline)",
    y = "delta_composite_z (12-month change)"
  )

ggsave(filename = fig_path, plot = p, width = 7, height = 5, dpi = 160)

# Pull key coefficient rows for textual summary
key_row <- function(tab, model_id, term) {
  out <- tab %>% filter(model_id == !!model_id, term == !!term) %>% slice(1)
  if (nrow(out) == 0) return(NULL)
  out
}

term_sls_delta <- key_row(coef_tabs, "delta_linear_sls", "single_leg_stance_clean")
term_sls_ancova <- key_row(coef_tabs, "ancova_level_sls", "single_leg_stance_clean")
term_sls10_delta <- key_row(coef_tabs, "delta_linear_sls10", "SLS10")
term_int <- key_row(coef_tabs, "delta_interaction_sls_x_fof", "single_leg_stance_clean:FOF_status1")

fmt_term <- function(row) {
  if (is.null(row)) return("not estimable")
  sprintf("est=%.4f, 95%% CI [%.4f, %.4f], p=%.4g", row$estimate, row$conf_low, row$conf_high, row$p_value)
}

mi_note <- if (requireNamespace("mice", quietly = TRUE)) {
  "MI package (mice) available in environment; MI sensitivity was not run in this targeted K22 pass."
} else {
  "MI not run: package mice not available in current renv/session (TODO if MI is required)."
}

selected_msg <- ifelse(is.na(selected_sls_col), "single_leg_stance (existing column)", selected_sls_col)

md_lines <- c(
  "# K22 Evidence Note: Does baseline SLS predict 12-month change or level?",
  "",
  "## Data and variable mapping",
  paste0("- Source used: `", source_used, "`"),
  paste0("- Selected SLS column/alias: `", selected_msg, "` -> `single_leg_stance_clean`"),
  "- Outcomes: `delta_composite_z = Composite_Z3 - Composite_Z0` and ANCOVA level `Composite_Z3` with baseline adjustment (`Composite_Z0`).",
  "",
  "## Core model results",
  paste0("- Delta linear model (`delta ~ SLS + FOF + age + sex + BMI`), N=", cc_delta_n, ": ", fmt_term(term_sls_delta)),
  paste0("- ANCOVA model (`Composite_Z3 ~ Composite_Z0 + SLS + FOF + age + sex + BMI`), N=", cc_ancova_n, ": ", fmt_term(term_sls_ancova)),
  paste0("- SLS per 10s (`SLS10`) in delta model, N=", cc_delta_n, ": ", fmt_term(term_sls10_delta)),
  paste0("- Non-linearity check (spline df=3 vs linear, same N): anova p=", sprintf("%.4g", spline_p)),
  paste0("- Interaction check (`SLS x FOF_status`) in delta model, N=", cc_delta_n, ": ", fmt_term(term_int)),
  "",
  "## Overadjustment / collinearity diagnostic",
  paste0("- Status: ", overadjust_note),
  if (!is.na(corr_sls_frail)) paste0("- Correlation(`single_leg_stance_clean`, `frailty_count_3_balance`) = ", round(corr_sls_frail, 4)) else "- Correlation with frailty_count_3_balance: unavailable",
  if (!is.na(se_sls_m_sls) && !is.na(se_sls_m_both)) paste0("- SLS SE change (sls-only -> both): ", round(se_sls_m_sls, 6), " -> ", round(se_sls_m_both, 6)) else "- SLS SE change: unavailable",
  if (!is.na(cond_num_m_both)) paste0("- Condition number (both model): ", round(cond_num_m_both, 2)) else "- Condition number: unavailable",
  "",
  "## Missingness and distribution",
  paste0("- Missing single_leg_stance_clean: ", sprintf("%.2f%%", sls_missing_pct)),
  paste0("- Missing delta_composite_z: ", sprintf("%.2f%%", delta_missing_pct)),
  paste0("- Floor share (SLS == 0): ", sprintf("%.2f%%", prop_zero)),
  paste0("- Ceiling share (SLS == max): ", sprintf("%.2f%%", prop_max)),
  "",
  "## Interpretation (construct-level)",
  "This K22 pass evaluates whether baseline SLS adds predictive information for 12-month change and follow-up level under the specified covariate set. Conclusions should be interpreted at model-construct level for this dataset and not generalized beyond this context.",
  "",
  "## MI sensitivity",
  paste0("- ", mi_note),
  "",
  "## ROPE/equivalence placeholder",
  "- TODO: define clinically meaningful +/-Delta threshold to interpret SLS10 CI in equivalence terms.",
  "",
  "## Table-to-text crosscheck",
  "All reported N, coefficients, CIs, p-values, and fit metrics are read from the generated CSV artifacts in this folder."
)

writeLines(md_lines, md_path)

# Manifest append (1 row per artifact)
append_manifest <- function(label, kind, path, n = NA, notes = NA_character_) {
  row <- data.frame(
    timestamp = as.character(Sys.time()),
    script = "K22",
    label = label,
    kind = kind,
    path = path,
    n = ifelse(is.na(n), NA, n),
    notes = ifelse(is.na(notes), NA, notes),
    stringsAsFactors = FALSE
  )
  if (!file.exists(manifest_path)) {
    readr::write_csv(row, manifest_path)
  } else {
    readr::write_csv(row, manifest_path, append = TRUE)
  }
}

append_manifest("K22_sls_models_fixed_effects", "table_csv", "R-scripts/K22/outputs/sls_predicts_change_and_level/K22_sls_models_fixed_effects.csv", nrow(coef_tabs), "K22 targeted SLS models: coefficients + CI + p")
append_manifest("K22_sls_model_metrics", "table_csv", "R-scripts/K22/outputs/sls_predicts_change_and_level/K22_sls_model_metrics.csv", nrow(metrics), "K22 targeted SLS models: N, AIC, R2 and spline-vs-linear p")
append_manifest("K22_sls_evidence_note", "doc_md", "R-scripts/K22/outputs/sls_predicts_change_and_level/K22_sls_evidence_note.md", NA, "Manuscript-ready interpretation for K22 SLS checks")
append_manifest("K22_sls_delta_vs_sls", "plot_png", "R-scripts/K22/outputs/sls_predicts_change_and_level/K22_sls_delta_vs_sls.png", cc_delta_n, "Single-panel scatter with linear and loess fits")

message("K22 complete: outputs and manifest rows written.")
