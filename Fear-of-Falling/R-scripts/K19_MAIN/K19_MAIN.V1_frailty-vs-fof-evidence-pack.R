#!/usr/bin/env Rscript
# ==============================================================================
# K19_MAIN - Frailty vs FOF evidence pack (collinearity, partial R2, nested A/B/C)
# File tag: K19_MAIN.V1_frailty-vs-fof-evidence-pack.R
# Purpose: Extend K18/K16 evidence with collinearity checks, partial R2 (or
#          term-level effect sizes), and nested A/B/C model comparisons.
#
# Outcome: Composite_Z (long; 0 vs 12 months)
# Predictors: FOF_status, frailty_cat_3, frailty_score_3
# Moderator/interaction: time_f * FOF_status; time_f * frailty_(cat/score)
# Grouping variable: ID (random intercept)
# Covariates: age, sex, BMI
#
# Required vars (DO NOT INVENT; must match req_cols_cat/req_cols_cont checks):
# Categorical set: Composite_Z, time_f, FOF_status, frailty_cat_3, age, sex, BMI, ID
# Continuous set:  Composite_Z, time_f, FOF_status, frailty_score_3, age, sex, BMI, ID
#
# Mapping example (K18 RData -> models):
# K18_all_models.RData -> all_models$models$M1 (categorical), all_models$models$M_cont (continuous)
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: N/A (no randomness)
#
# Outputs + manifest:
# - script_label: K19_MAIN (canonical)
# - outputs dir: R-scripts/K19_MAIN/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load K18 model objects (K18_all_models.RData)
# 03) Extract model frames for consistent A/B/C fitting
# 04) Fit nested A/B/C models (categorical + continuous; ML for LRT)
# 05) Collinearity checks (performance::check_collinearity, fallback)
# 06) Partial R2 / term-level effect sizes (partR2/effectsize, fallback)
# 07) Save outputs -> R-scripts/K19_MAIN/outputs/
# 08) Append manifest row per artifact
# 09) Save sessionInfo to manifest/
# 10) EOF marker
# ==============================================================================
#

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(readr)
  library(tibble)
  library(lme4)
  library(lmerTest)
  library(broom.mixed)
})

# --- Standard init (MANDATORY) -----------------------------------------------
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K19_MAIN"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K19_MAIN"

source(here::here("R", "functions", "init.R"))
source(here::here("R", "functions", "reporting.R"))

paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

cat("================================================================================\n")
cat("K19 Frailty vs FOF evidence pack\n")
cat("Script label:", script_label, "\n")
cat("Outputs dir:", outputs_dir, "\n")
cat("Manifest:", manifest_path, "\n")
cat("Project root:", here::here(), "\n")
cat("================================================================================\n\n")

# --- Load K18 model objects --------------------------------------------------
k18_rdata <- here::here("R-scripts", "K18_MAIN", "outputs", "K18_all_models.RData")
if (!file.exists(k18_rdata)) {
  stop("K18 models not found: ", k18_rdata,
       "\nRun K18_MAIN first to generate K18_all_models.RData.")
}

loaded <- load(k18_rdata)
if (!("all_models" %in% loaded) || !exists("all_models")) {
  stop("Expected object 'all_models' not found in K18_all_models.RData. Loaded: ",
       paste(loaded, collapse = ", "))
}

if (!is.list(all_models) || is.null(all_models$models)) {
  stop("K18 all_models object missing 'models' list. Please re-run K18_MAIN.")
}

mod_M1 <- all_models$models$M1
mod_M_cont <- all_models$models$M_cont

if (is.null(mod_M1) || is.null(mod_M_cont)) {
  stop("K19 requires mod_M1 and mod_M_cont from K18_all_models.RData. ",
       "Please re-run K18_MAIN and ensure these models are saved.")
}

# --- Extract model frames -----------------------------------------------------
data_m1 <- tryCatch(model.frame(mod_M1), error = function(e) NULL)
if (is.null(data_m1)) stop("Failed to extract model.frame from mod_M1.")

data_mcont <- tryCatch(model.frame(mod_M_cont), error = function(e) NULL)
if (is.null(data_mcont)) stop("Failed to extract model.frame from mod_M_cont.")

req_cols_cat <- c("Composite_Z", "time_f", "FOF_status", "frailty_cat_3", "age", "sex", "BMI", "ID")
req_cols_cont <- c("Composite_Z", "time_f", "FOF_status", "frailty_score_3", "age", "sex", "BMI", "ID")

check_required <- function(df, req_cols, label) {
  missing <- setdiff(req_cols, names(df))
  if (length(missing) > 0) {
    stop("Missing required columns in ", label, ": ", paste(missing, collapse = ", "))
  }
}

check_required(data_m1, req_cols_cat, "categorical set (M1 data)")
check_required(data_mcont, req_cols_cont, "continuous set (M_cont data)")

# --- Nested A/B/C models (ML) ------------------------------------------------
form_A_cat <- "Composite_Z ~ time_f * FOF_status + age + sex + BMI + (1 | ID)"
form_B_cat <- "Composite_Z ~ time_f * frailty_cat_3 + age + sex + BMI + (1 | ID)"
form_C_cat <- "Composite_Z ~ time_f * FOF_status + time_f * frailty_cat_3 + age + sex + BMI + (1 | ID)"

form_A_cont <- "Composite_Z ~ time_f * FOF_status + age + sex + BMI + (1 | ID)"
form_B_cont <- "Composite_Z ~ time_f * frailty_score_3 + age + sex + BMI + (1 | ID)"
form_C_cont <- "Composite_Z ~ time_f * FOF_status + time_f * frailty_score_3 + age + sex + BMI + (1 | ID)"

fit_lmer_ml <- function(formula_str, data) {
  lmerTest::lmer(stats::as.formula(formula_str), data = data, REML = FALSE)
}

cat("\nFitting nested models (categorical set)...\n")
mod_A_cat <- fit_lmer_ml(form_A_cat, data_m1)
mod_B_cat <- fit_lmer_ml(form_B_cat, data_m1)
mod_C_cat <- fit_lmer_ml(form_C_cat, data_m1)

cat("\nFitting nested models (continuous set)...\n")
mod_A_cont <- fit_lmer_ml(form_A_cont, data_mcont)
mod_B_cont <- fit_lmer_ml(form_B_cont, data_mcont)
mod_C_cont <- fit_lmer_ml(form_C_cont, data_mcont)

# --- Model comparison table --------------------------------------------------
model_stats <- function(mod) {
  tibble::tibble(
    AIC = AIC(mod),
    BIC = BIC(mod),
    logLik = as.numeric(logLik(mod)),
    n = nobs(mod)
  )
}

lrt_vs_c <- function(mod_small, mod_large) {
  comp <- anova(mod_small, mod_large)
  tibble::tibble(
    LRT_chisq = as.numeric(comp$Chisq[2]),
    LRT_df = as.numeric(comp$Df[2]),
    LRT_p = as.numeric(comp$`Pr(>Chisq)`[2])
  )
}

cat_lrt_A <- lrt_vs_c(mod_A_cat, mod_C_cat)
cat_lrt_B <- lrt_vs_c(mod_B_cat, mod_C_cat)
cont_lrt_A <- lrt_vs_c(mod_A_cont, mod_C_cont)
cont_lrt_B <- lrt_vs_c(mod_B_cont, mod_C_cont)

comparison_tbl <- dplyr::bind_rows(
  tibble::tibble(
    model_set = "categorical",
    model = "A",
    formula = form_A_cat
  ) %>% dplyr::bind_cols(model_stats(mod_A_cat), cat_lrt_A),
  tibble::tibble(
    model_set = "categorical",
    model = "B",
    formula = form_B_cat
  ) %>% dplyr::bind_cols(model_stats(mod_B_cat), cat_lrt_B),
  tibble::tibble(
    model_set = "categorical",
    model = "C",
    formula = form_C_cat
  ) %>% dplyr::bind_cols(model_stats(mod_C_cat),
                         tibble::tibble(LRT_chisq = NA_real_, LRT_df = NA_real_, LRT_p = NA_real_)),
  tibble::tibble(
    model_set = "continuous",
    model = "A",
    formula = form_A_cont
  ) %>% dplyr::bind_cols(model_stats(mod_A_cont), cont_lrt_A),
  tibble::tibble(
    model_set = "continuous",
    model = "B",
    formula = form_B_cont
  ) %>% dplyr::bind_cols(model_stats(mod_B_cont), cont_lrt_B),
  tibble::tibble(
    model_set = "continuous",
    model = "C",
    formula = form_C_cont
  ) %>% dplyr::bind_cols(model_stats(mod_C_cont),
                         tibble::tibble(LRT_chisq = NA_real_, LRT_df = NA_real_, LRT_p = NA_real_))
)

comparison_path <- file.path(outputs_dir, "K19_model_comparisons_ABCs.csv")
save_table_csv(comparison_tbl, comparison_path)
append_manifest(
  manifest_row(script = script_label, label = "K19_model_comparisons_ABCs",
               path = get_relpath(comparison_path), kind = "table_csv", n = nrow(comparison_tbl)),
  manifest_path
)

# --- Collinearity checks -----------------------------------------------------
collinearity_tbl <- function(mod, model_set, note_override = NA_character_) {
  if (requireNamespace("performance", quietly = TRUE)) {
    tbl <- tryCatch(performance::check_collinearity(mod), error = function(e) NULL)
    if (is.null(tbl)) {
      tbl <- NULL
    } else {
      tbl <- as.data.frame(tbl)
    }
  } else {
    tbl <- NULL
  }

  if (!is.null(tbl)) {
    term <- if ("Parameter" %in% names(tbl)) tbl$Parameter else rownames(tbl)
    vif_val <- if ("VIF" %in% names(tbl)) tbl$VIF else tbl$vif
    tol_val <- if ("Tolerance" %in% names(tbl)) tbl$Tolerance else tbl$tolerance
    note_val <- note_override

    needs_term <- is.null(term) || length(term) == 0 || all(is.na(term)) || all(grepl("^[0-9]+$", term))
    if (needs_term) {
      fx <- colnames(lme4::getME(mod, "X"))
      fx <- fx[fx != "(Intercept)"]
      if (length(fx) >= length(vif_val)) {
        term <- fx[seq_len(length(vif_val))]
      } else {
        term <- c(fx, rep(NA_character_, length(vif_val) - length(fx)))
      }
      note_val <- ifelse(is.na(note_val), "term names inferred from model matrix order", note_val)
      if (length(fx) != length(vif_val)) {
        note_val <- ifelse(is.na(note_val),
                           "term names truncated/padded from model matrix order",
                           note_val)
      }
    }

    tibble::tibble(
      model_set = model_set,
      method = "performance::check_collinearity",
      term = term,
      vif = as.numeric(vif_val),
      tolerance = as.numeric(tol_val),
      note = note_val
    )
  } else if (requireNamespace("car", quietly = TRUE)) {
    v <- car::vif(mod)
    if (is.matrix(v)) {
      v <- v[, 1]
    }
    tibble::tibble(
      model_set = model_set,
      method = "car::vif",
      term = names(v),
      vif = as.numeric(v),
      tolerance = 1 / as.numeric(v),
      note = note_override
    )
  } else {
    tibble::tibble(
      model_set = model_set,
      method = "unavailable",
      term = NA_character_,
      vif = NA_real_,
      tolerance = NA_real_,
      note = ifelse(is.na(note_override),
                    "performance::check_collinearity and car::vif not available",
                    note_override)
    )
  }
}

col_tbl <- dplyr::bind_rows(
  collinearity_tbl(mod_C_cat, "M1_categorical",
                   note_override = "ML refit using M1 formula (time_f*FOF_status + time_f*frailty_cat_3 + covars)"),
  collinearity_tbl(mod_C_cont, "M_cont_continuous",
                   note_override = "ML refit using M_cont formula (time_f*FOF_status + time_f*frailty_score_3 + covars)")
)

col_path <- file.path(outputs_dir, "K19_collinearity_M1_Mcont.csv")
save_table_csv(col_tbl, col_path)
append_manifest(
  manifest_row(script = script_label, label = "K19_collinearity_M1_Mcont",
               path = get_relpath(col_path), kind = "table_csv", n = nrow(col_tbl)),
  manifest_path
)

# --- Partial R2 / term-level effect sizes -----------------------------------
partial_r2_tbl <- function(mod, model_set, partvars) {
  if (requireNamespace("partR2", quietly = TRUE)) {
    res <- tryCatch(
      partR2::partR2(mod, partvars = partvars, data = model.frame(mod), nboot = 0),
      error = function(e) e
    )
    if (inherits(res, "error")) {
      return(tibble::tibble(
        model_set = model_set,
        term = NA_character_,
        metric = "partial_R2",
        value = NA_real_,
        note = paste0("partR2 failed: ", res$message)
      ))
    }
    if (is.data.frame(res$R2)) {
      return(tibble::tibble(
        model_set = model_set,
        term = res$R2$Predictor,
        metric = "partial_R2",
        value = res$R2$R2,
        note = NA_character_
      ))
    }
    return(tibble::tibble(
      model_set = model_set,
      term = NA_character_,
      metric = "partial_R2",
      value = NA_real_,
      note = "partR2 returned unexpected structure"
    ))
  }

  if (requireNamespace("effectsize", quietly = TRUE)) {
    an <- tryCatch(anova(mod), error = function(e) e)
    if (inherits(an, "error")) {
      return(tibble::tibble(
        model_set = model_set,
        term = NA_character_,
        metric = "partial_eta_sq",
        value = NA_real_,
        note = paste0("anova failed: ", an$message)
      ))
    }
    es <- tryCatch(effectsize::eta_squared(an, partial = TRUE), error = function(e) e)
    if (inherits(es, "error")) {
      return(tibble::tibble(
        model_set = model_set,
        term = NA_character_,
        metric = "partial_eta_sq",
        value = NA_real_,
        note = paste0("effectsize failed: ", es$message)
      ))
    }
    return(tibble::tibble(
      model_set = model_set,
      term = es$Parameter,
      metric = "partial_eta_sq",
      value = es$Eta2_partial,
      note = NA_character_
    ))
  }

  tibble::tibble(
    model_set = model_set,
    term = NA_character_,
    metric = "unavailable",
    value = NA_real_,
    note = "partR2 and effectsize not available"
  )
}

part_tbl <- dplyr::bind_rows(
  partial_r2_tbl(mod_C_cat, "M1_categorical",
                 partvars = c("FOF_status", "frailty_cat_3", "time_f:FOF_status", "time_f:frailty_cat_3")),
  partial_r2_tbl(mod_C_cont, "M_cont_continuous",
                 partvars = c("FOF_status", "frailty_score_3", "time_f:FOF_status", "time_f:frailty_score_3"))
)

part_path <- file.path(outputs_dir, "K19_partial_r2_M1_Mcont.csv")
save_table_csv(part_tbl, part_path)
append_manifest(
  manifest_row(script = script_label, label = "K19_partial_r2_M1_Mcont",
               path = get_relpath(part_path), kind = "table_csv", n = nrow(part_tbl)),
  manifest_path
)

# --- Fixed effects tables (A/B/C) --------------------------------------------
fixed_effects_tbl <- function(mod, model_set, model_id) {
  if (requireNamespace("broom.mixed", quietly = TRUE)) {
    tbl <- broom.mixed::tidy(mod, effects = "fixed", conf.int = TRUE)
    if (!("df" %in% names(tbl))) tbl$df <- NA_real_
    if (!("p.value" %in% names(tbl))) tbl$p.value <- NA_real_
    if (!("conf.low" %in% names(tbl))) tbl$conf.low <- NA_real_
    if (!("conf.high" %in% names(tbl))) tbl$conf.high <- NA_real_
    return(tbl %>%
      mutate(model_set = model_set, model = model_id) %>%
      select(model_set, model, term, estimate, std.error, statistic, df, p.value, conf.low, conf.high))
  }

  sm <- summary(mod)
  coefs <- as.data.frame(sm$coefficients)
  coefs$term <- rownames(coefs)
  out <- tibble::tibble(
    model_set = model_set,
    model = model_id,
    term = coefs$term,
    estimate = coefs[, 1],
    std.error = coefs[, 2],
    statistic = coefs[, 3],
    df = if (ncol(coefs) >= 4) coefs[, 4] else NA_real_,
    p.value = if (ncol(coefs) >= 5) coefs[, 5] else NA_real_,
    conf.low = NA_real_,
    conf.high = NA_real_
  )
  out
}

fixed_tbl <- dplyr::bind_rows(
  fixed_effects_tbl(mod_A_cat, "categorical", "A"),
  fixed_effects_tbl(mod_B_cat, "categorical", "B"),
  fixed_effects_tbl(mod_C_cat, "categorical", "C"),
  fixed_effects_tbl(mod_A_cont, "continuous", "A"),
  fixed_effects_tbl(mod_B_cont, "continuous", "B"),
  fixed_effects_tbl(mod_C_cont, "continuous", "C")
)

fixed_path <- file.path(outputs_dir, "K19_fixed_effects_tables.csv")
save_table_csv(fixed_tbl, fixed_path)
append_manifest(
  manifest_row(script = script_label, label = "K19_fixed_effects_tables",
               path = get_relpath(fixed_path), kind = "table_csv", n = nrow(fixed_tbl)),
  manifest_path
)

# --- Results text (FI) --------------------------------------------------------
get_lrt_p <- function(df, model_set, model) {
  val <- df %>% filter(.data$model_set == .env$model_set, .data$model == .env$model) %>% pull(LRT_p)
  if (length(val) == 0 || is.na(val[1])) stop("Missing LRT p for ", model_set, " model ", model)
  val[1]
}

lrt_cat_A <- get_lrt_p(comparison_tbl, "categorical", "A")
lrt_cat_B <- get_lrt_p(comparison_tbl, "categorical", "B")
lrt_cont_A <- get_lrt_p(comparison_tbl, "continuous", "A")
lrt_cont_B <- get_lrt_p(comparison_tbl, "continuous", "B")

col_note <- if (all(is.na(col_tbl$vif))) {
  "Kollineaarisuustarkistus ei ollut saatavilla (performance/car puuttuu)."
} else {
  "Kollineaarisuustarkistus tehty (ks. K19_collinearity_M1_Mcont.csv)."
}

r2_note <- if (all(is.na(part_tbl$value))) {
  "Partial R2 / termikohtaiset efektit eivät olleet saatavilla (partR2/effectsize puuttuu)."
} else {
  "Partial R2 / termikohtaiset efektit tuotettu (ks. K19_partial_r2_M1_Mcont.csv)."
}

results_lines <- c(
  "TULOKSET: K19 frailty vs FOF evidence pack",
  "========================================",
  "",
  "Nested A/B/C -mallivertailu (ML, LRT vs C):",
  sprintf("  Categorical: A vs C p = %.4g, B vs C p = %.4g", lrt_cat_A, lrt_cat_B),
  sprintf("  Continuous:  A vs C p = %.4g, B vs C p = %.4g", lrt_cont_A, lrt_cont_B),
  "Huom: kollineaarisuus/partial R2 laskettiin ML-refit -malleista (sama kaava kuin M1/M_cont).",
  "",
  col_note,
  r2_note,
  "",
  "Output-polut:",
  paste0("  - ", get_relpath(comparison_path)),
  paste0("  - ", get_relpath(col_path)),
  paste0("  - ", get_relpath(part_path)),
  paste0("  - ", get_relpath(fixed_path))
)

results_path <- file.path(outputs_dir, "K19_Results_FI.txt")
writeLines(results_lines, con = results_path)
append_manifest(
  manifest_row(script = script_label, label = "K19_Results_FI",
               path = get_relpath(results_path), kind = "text", n = NA_integer_),
  manifest_path
)

# --- Session info -------------------------------------------------------------
save_sessioninfo_manifest()

message("K19 complete. Outputs saved to: ", outputs_dir)
