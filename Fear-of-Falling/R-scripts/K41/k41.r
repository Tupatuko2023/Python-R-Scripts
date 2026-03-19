#!/usr/bin/env Rscript
# ============================================================================== 
# K41 - FI extended models (canonical primary + FI extended, common-sample rule)
# ============================================================================== 

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(here)
  library(lme4)
  library(lmerTest)
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

script_label <- "K41"
paths <- init_paths(script_label)
outputs_dir <- getOption("fof.outputs_dir")
manifest_path <- getOption("fof.manifest_path")

append_artifact <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  append_manifest(
    manifest_row(script = script_label, label = label, path = get_relpath(path), kind = kind, n = n, notes = notes),
    manifest_path
  )
}

write_agg_csv <- function(df, filename, label = filename, notes = NA_character_) {
  out_path <- file.path(outputs_dir, filename)
  readr::write_csv(df, out_path)
  append_artifact(label = label, kind = "table_csv", path = out_path, n = nrow(df), notes = notes)
  out_path
}

write_agg_txt <- function(lines, filename, label = filename, notes = NA_character_) {
  out_path <- file.path(outputs_dir, filename)
  writeLines(lines, out_path)
  append_artifact(label = label, kind = "text", path = out_path, n = length(lines), notes = notes)
  out_path
}

md5_file <- function(path) unname(tools::md5sum(path))

clean_names_simple <- function(x) {
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", "_", x)
  x <- gsub("_+", "_", x)
  x <- gsub("^_|_$", "", x)
  x
}

pick_first_existing <- function(paths_vec) {
  hits <- paths_vec[file.exists(paths_vec)]
  if (length(hits) == 0) return(NA_character_)
  hits[[1]]
}

load_tabular <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "rds") {
    obj <- readRDS(path)
    if (!is.data.frame(obj)) stop("RDS is not a data.frame: ", path, call. = FALSE)
    return(as_tibble(obj))
  }
  if (ext == "csv") return(readr::read_csv(path, show_col_types = FALSE))
  stop("Unsupported input extension: ", path, call. = FALSE)
}

infer_data_root <- function() {
  from_env <- Sys.getenv("DATA_ROOT", "")
  if (nzchar(from_env)) return(from_env)

  env_path <- file.path(project_root, "config", ".env")
  if (file.exists(env_path)) {
    env_lines <- readLines(env_path, warn = FALSE)
    hit <- grep("^DATA_ROOT\\s*=", env_lines, value = TRUE)
    if (length(hit) > 0) {
      value <- sub("^DATA_ROOT\\s*=\\s*", "", hit[[1]])
      value <- gsub('^"|"$', "", value)
      value <- gsub("^'|'$", "", value)
      if (nzchar(value)) return(value)
    }
  }

  stop("DATA_ROOT is required but missing. Set DATA_ROOT env var or config/.env DATA_ROOT=...", call. = FALSE)
}

resolve_inputs <- function(data_root) {
  analysis_dir <- file.path(data_root, "paper_01", "analysis")
  fv_dir <- file.path(data_root, "paper_02", "frailty_vulnerability")

  list(
    k33_long = pick_first_existing(file.path(analysis_dir, c("fof_analysis_k33_long.rds", "fof_analysis_k33_long.csv"))),
    k33_wide = pick_first_existing(file.path(analysis_dir, c("fof_analysis_k33_wide.rds", "fof_analysis_k33_wide.csv"))),
    k40 = pick_first_existing(file.path(fv_dir, c("kaaos_with_frailty_index_k40.rds", "kaaos_with_frailty_index_k40.csv"))),
    analysis_dir = analysis_dir,
    fv_dir = fv_dir
  )
}

find_col <- function(nms, candidates) {
  hit <- intersect(candidates, nms)
  if (length(hit) == 0) return(NA_character_)
  hit[[1]]
}

normalize_fof <- function(x) {
  if (is.factor(x)) x <- as.character(x)
  if (is.numeric(x) || is.integer(x)) {
    return(factor(ifelse(x == 1, "FOF", "nonFOF"), levels = c("nonFOF", "FOF")))
  }
  xc <- tolower(trimws(as.character(x)))
  out <- ifelse(xc %in% c("1", "fof", "with fof"), "FOF",
                ifelse(xc %in% c("0", "nonfof", "ei fof", "without fof"), "nonFOF", NA_character_))
  factor(out, levels = c("nonFOF", "FOF"))
}

normalize_frailty_cat <- function(x) {
  xc <- tolower(trimws(as.character(x)))
  out <- dplyr::case_when(
    xc %in% c("robust", "0") ~ "robust",
    xc %in% c("pre-frail", "prefrail", "1") ~ "pre-frail",
    xc %in% c("frail", "2", "3") ~ "frail",
    TRUE ~ NA_character_
  )
  factor(out, levels = c("robust", "pre-frail", "frail"))
}

normalize_sex <- function(x) {
  xc <- tolower(trimws(as.character(x)))
  female_set <- c("0", "2", "f", "female", "woman", "nainen")
  male_set <- c("1", "m", "male", "man", "mies")
  out <- rep(NA_character_, length(xc))
  out[xc %in% female_set] <- "female"
  out[xc %in% male_set] <- "male"
  factor(out, levels = c("female", "male"))
}

normalize_time <- function(x) {
  if (is.numeric(x) || is.integer(x)) return(as.numeric(x))
  xc <- tolower(trimws(as.character(x)))
  out <- rep(NA_real_, length(xc))
  out[xc %in% c("0", "baseline", "bl", "m0", "0m", "t0")] <- 0
  out[xc %in% c("12", "12m", "m12", "t12", "followup", "follow_up", "12_month", "12months")] <- 12
  suppressWarnings({
    numeric_guess <- as.numeric(xc)
  })
  out[is.na(out)] <- numeric_guess[is.na(out)]
  out
}

coerce_binary01 <- function(x) {
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x) || is.integer(x)) return(as.numeric(x))
  xc <- tolower(trimws(as.character(x)))
  out <- rep(NA_real_, length(xc))
  out[xc %in% c("1", "yes", "true", "kylla", "k", "y")] <- 1
  out[xc %in% c("0", "no", "false", "ei", "n")] <- 0
  out
}

tidy_model <- function(model) {
  if (requireNamespace("broom.mixed", quietly = TRUE) && inherits(model, "merMod")) {
    return(broom.mixed::tidy(model, effects = "fixed", conf.int = TRUE))
  }
  if (requireNamespace("broom", quietly = TRUE) && inherits(model, "lm")) {
    return(broom::tidy(model, conf.int = TRUE))
  }

  sm <- summary(model)$coefficients
  p_col <- grep("Pr\\(>", colnames(sm), value = TRUE)[1]
  stat_col <- grep("(t value|z value)", colnames(sm), value = TRUE)[1]
  out <- tibble(
    term = rownames(sm),
    estimate = sm[, "Estimate"],
    std.error = sm[, "Std. Error"],
    statistic = if (!is.na(stat_col)) sm[, stat_col] else NA_real_,
    p.value = if (!is.na(p_col)) sm[, p_col] else NA_real_
  )

  ci <- tryCatch(confint(model), error = function(e) NULL)
  if (!is.null(ci) && nrow(ci) > 0) {
    ci_df <- tibble(term = rownames(ci), conf.low = ci[, 1], conf.high = ci[, 2])
    out <- out %>% left_join(ci_df, by = "term")
  } else {
    out <- out %>% mutate(conf.low = NA_real_, conf.high = NA_real_)
  }
  out
}

# -----------------------------------------------------------------------------
# 1) Resolve and load inputs
# -----------------------------------------------------------------------------
data_root <- infer_data_root()
resolved <- resolve_inputs(data_root)

if (is.na(resolved$k33_long) || is.na(resolved$k33_wide) || is.na(resolved$k40)) {
  stop(
    paste0(
      "K41 missing required inputs. k33_long=", resolved$k33_long,
      ", k33_wide=", resolved$k33_wide,
      ", k40=", resolved$k40
    ),
    call. = FALSE
  )
}

long_df <- load_tabular(resolved$k33_long)
wide_df <- load_tabular(resolved$k33_wide)
k40_df <- load_tabular(resolved$k40)

names(long_df) <- clean_names_simple(names(long_df))
names(wide_df) <- clean_names_simple(names(wide_df))
names(k40_df) <- clean_names_simple(names(k40_df))

long_id <- find_col(names(long_df), c("id", "participant_id", "subject_id", "study_id"))
wide_id <- find_col(names(wide_df), c("id", "participant_id", "subject_id", "study_id"))
k40_id <- find_col(names(k40_df), c("id", "participant_id", "subject_id", "study_id"))
if (any(is.na(c(long_id, wide_id, k40_id)))) stop("Could not resolve id column in one or more inputs", call. = FALSE)

if (long_id != "id") names(long_df)[names(long_df) == long_id] <- "id"
if (wide_id != "id") names(wide_df)[names(wide_df) == wide_id] <- "id"
if (k40_id != "id") names(k40_df)[names(k40_df) == k40_id] <- "id"

fi_z_col <- find_col(names(k40_df), c("frailty_index_fi_k40_z", "frailty_index_fi_z"))
fi_col <- find_col(names(k40_df), c("frailty_index_fi_k40", "frailty_index_fi"))
if (is.na(fi_z_col) && is.na(fi_col)) {
  stop("K40 input must include frailty_index_fi_k40_z or frailty_index_fi_k40", call. = FALSE)
}

k40_keep <- k40_df %>%
  group_by(id) %>%
  slice(1L) %>%
  ungroup() %>%
  mutate(
    frailty_index_fi_k40 = if (!is.na(fi_col)) as.numeric(.data[[fi_col]]) else NA_real_,
    frailty_index_fi_k40_z = if (!is.na(fi_z_col)) as.numeric(.data[[fi_z_col]]) else as.numeric(scale(frailty_index_fi_k40))
  ) %>%
  select(id, frailty_index_fi_k40, frailty_index_fi_k40_z)

long_joined <- long_df %>% left_join(k40_keep, by = "id")
wide_joined <- wide_df %>% left_join(k40_keep, by = "id")

# -----------------------------------------------------------------------------
# 2) Harmonize variables for canonical formulas
# -----------------------------------------------------------------------------
long_model <- long_joined %>%
  mutate(
    composite_z = as.numeric(.data[[find_col(names(.), c("composite_z"))]]),
    time = normalize_time(.data[[find_col(names(.), c("time", "timepoint", "visit", "aika"))]]),
    fof_status = normalize_fof(.data[[find_col(names(.), c("fof_status", "kaatumisenpelkoon"))]]),
    frailty_cat_3 = normalize_frailty_cat(.data[[find_col(names(.), c("frailty_cat_3"))]]),
    tasapainovaikeus = coerce_binary01(.data[[find_col(names(.), c("tasapainovaikeus"))]]),
    age = as.numeric(.data[[find_col(names(.), c("age", "ika"))]]),
    sex = normalize_sex(.data[[find_col(names(.), c("sex", "sukupuoli"))]]),
    bmi = as.numeric(.data[[find_col(names(.), c("bmi"))]]),
    frailty_index_fi_k40_z = as.numeric(frailty_index_fi_k40_z)
  ) %>%
  select(id, composite_z, time, fof_status, frailty_cat_3, tasapainovaikeus, age, sex, bmi, frailty_index_fi_k40_z)

wide_model <- wide_joined %>%
  mutate(
    composite_z_baseline = as.numeric(.data[[find_col(names(.), c("composite_z_baseline", "composite_z0"))]]),
    composite_z_12m = as.numeric(.data[[find_col(names(.), c("composite_z_12m", "composite_z12"))]]),
    fof_status = normalize_fof(.data[[find_col(names(.), c("fof_status", "kaatumisenpelkoon"))]]),
    frailty_cat_3 = normalize_frailty_cat(.data[[find_col(names(.), c("frailty_cat_3"))]]),
    tasapainovaikeus = coerce_binary01(.data[[find_col(names(.), c("tasapainovaikeus"))]]),
    age = as.numeric(.data[[find_col(names(.), c("age", "ika"))]]),
    sex = normalize_sex(.data[[find_col(names(.), c("sex", "sukupuoli"))]]),
    bmi = as.numeric(.data[[find_col(names(.), c("bmi"))]]),
    frailty_index_fi_k40_z = as.numeric(frailty_index_fi_k40_z)
  ) %>%
  select(id, composite_z_baseline, composite_z_12m, fof_status, frailty_cat_3, tasapainovaikeus, age, sex, bmi, frailty_index_fi_k40_z)

# -----------------------------------------------------------------------------
# 3) Common-sample accounting
# -----------------------------------------------------------------------------
long_primary_vars <- c("id", "composite_z", "time", "fof_status", "frailty_cat_3", "tasapainovaikeus", "age", "sex", "bmi")
long_extended_vars <- c(long_primary_vars, "frailty_index_fi_k40_z")

wide_primary_vars <- c("id", "composite_z_12m", "composite_z_baseline", "fof_status", "frailty_cat_3", "tasapainovaikeus", "age", "sex", "bmi")
wide_extended_vars <- c(wide_primary_vars, "frailty_index_fi_k40_z")

long_cc_primary <- complete.cases(long_model[, long_primary_vars, drop = FALSE])
long_cc_extended <- complete.cases(long_model[, long_extended_vars, drop = FALSE])
long_cc_common <- long_cc_primary & long_cc_extended

wide_cc_primary <- complete.cases(wide_model[, wide_primary_vars, drop = FALSE])
wide_cc_extended <- complete.cases(wide_model[, wide_extended_vars, drop = FALSE])
wide_cc_common <- wide_cc_primary & wide_cc_extended

long_primary_n <- sum(long_cc_primary)
long_extended_n <- sum(long_cc_extended)
long_common_n <- sum(long_cc_common)

wide_primary_n <- sum(wide_cc_primary)
wide_extended_n <- sum(wide_cc_extended)
wide_common_n <- sum(wide_cc_common)

if (long_common_n < 20 || wide_common_n < 20) {
  stop(
    paste0(
      "Common sample too small for stable model fitting. long_common=", long_common_n,
      ", wide_common=", wide_common_n
    ),
    call. = FALSE
  )
}

common_counts <- tibble(
  metric = c(
    "n_long_primary", "n_long_extended", "n_long_common",
    "n_wide_primary", "n_wide_extended", "n_wide_common",
    "n_long_primary_ids", "n_long_extended_ids", "n_long_common_ids",
    "n_wide_primary_ids", "n_wide_extended_ids", "n_wide_common_ids"
  ),
  value = c(
    long_primary_n, long_extended_n, long_common_n,
    wide_primary_n, wide_extended_n, wide_common_n,
    dplyr::n_distinct(long_model$id[long_cc_primary]),
    dplyr::n_distinct(long_model$id[long_cc_extended]),
    dplyr::n_distinct(long_model$id[long_cc_common]),
    dplyr::n_distinct(wide_model$id[wide_cc_primary]),
    dplyr::n_distinct(wide_model$id[wide_cc_extended]),
    dplyr::n_distinct(wide_model$id[wide_cc_common])
  )
)
write_agg_csv(common_counts, "k41_common_sample_counts.csv", notes = "Primary/extended/common counts for long and wide")

# -----------------------------------------------------------------------------
# 4) Fit models on mandatory common samples
# -----------------------------------------------------------------------------
long_fit <- long_model[long_cc_common, , drop = FALSE]
wide_fit <- wide_model[wide_cc_common, , drop = FALSE]

long_fit <- long_fit %>%
  mutate(
    fof_status = droplevels(fof_status),
    frailty_cat_3 = droplevels(frailty_cat_3),
    sex = droplevels(sex)
  )

wide_fit <- wide_fit %>%
  mutate(
    fof_status = droplevels(fof_status),
    frailty_cat_3 = droplevels(frailty_cat_3),
    sex = droplevels(sex)
  )

if (nlevels(long_fit$fof_status) < 2 || nlevels(long_fit$frailty_cat_3) < 2 || nlevels(long_fit$sex) < 2) {
  stop("Long common sample dropped below required factor levels for canonical model", call. = FALSE)
}
if (nlevels(wide_fit$fof_status) < 2 || nlevels(wide_fit$frailty_cat_3) < 2 || nlevels(wide_fit$sex) < 2) {
  stop("Wide common sample dropped below required factor levels for canonical model", call. = FALSE)
}

lmm_primary_formula <- as.formula(
  "composite_z ~ time * fof_status + time * frailty_cat_3 + time * tasapainovaikeus + age + sex + bmi + (1 | id)"
)
lmm_extended_formula <- as.formula(
  "composite_z ~ time * fof_status + time * frailty_cat_3 + time * tasapainovaikeus + frailty_index_fi_k40_z + time:frailty_index_fi_k40_z + age + sex + bmi + (1 | id)"
)

ancova_primary_formula <- as.formula(
  "composite_z_12m ~ composite_z_baseline + fof_status + frailty_cat_3 + tasapainovaikeus + age + sex + bmi"
)
ancova_extended_formula <- as.formula(
  "composite_z_12m ~ composite_z_baseline + fof_status + frailty_cat_3 + tasapainovaikeus + frailty_index_fi_k40_z + age + sex + bmi"
)

lmm_primary <- lmer(lmm_primary_formula, data = long_fit, REML = FALSE)
lmm_extended <- lmer(lmm_extended_formula, data = long_fit, REML = FALSE)
ancova_primary <- lm(ancova_primary_formula, data = wide_fit)
ancova_extended <- lm(ancova_extended_formula, data = wide_fit)

lmm_primary_coef <- tidy_model(lmm_primary)
lmm_extended_coef <- tidy_model(lmm_extended)
ancova_primary_coef <- tidy_model(ancova_primary)
ancova_extended_coef <- tidy_model(ancova_extended)

lmm_compare_raw <- anova(lmm_primary, lmm_extended)
lmm_compare <- tibble(
  model = rownames(lmm_compare_raw),
  npar = lmm_compare_raw$npar,
  AIC = lmm_compare_raw$AIC,
  BIC = lmm_compare_raw$BIC,
  logLik = lmm_compare_raw$logLik,
  deviance = lmm_compare_raw$deviance,
  Chisq = if ("Chisq" %in% names(lmm_compare_raw)) lmm_compare_raw$Chisq else NA_real_,
  Df = if ("Df" %in% names(lmm_compare_raw)) lmm_compare_raw$Df else NA_real_,
  p_value = {
    p_col <- grep("Pr\\(>Chisq\\)", names(lmm_compare_raw), value = TRUE)
    if (length(p_col) == 1) lmm_compare_raw[[p_col]] else NA_real_
  }
)

anova_lm <- anova(ancova_primary, ancova_extended)
ancova_compare <- tibble(
  model = c("primary", "extended"),
  nobs = c(stats::nobs(ancova_primary), stats::nobs(ancova_extended)),
  AIC = c(AIC(ancova_primary), AIC(ancova_extended)),
  BIC = c(BIC(ancova_primary), BIC(ancova_extended)),
  adj_r_squared = c(summary(ancova_primary)$adj.r.squared, summary(ancova_extended)$adj.r.squared),
  residual_se = c(summary(ancova_primary)$sigma, summary(ancova_extended)$sigma),
  lrt_chisq = c(NA_real_, as.numeric(anova_lm$F[2])),
  lrt_df = c(NA_real_, as.numeric(anova_lm$Df[2])),
  lrt_p_value = c(NA_real_, as.numeric(anova_lm$`Pr(>F)`[2]))
)

write_agg_csv(lmm_primary_coef, "k41_lmm_primary_coefficients.csv", notes = "Canonical K26-equivalent long LMM on common sample")
write_agg_csv(lmm_extended_coef, "k41_lmm_extended_coefficients.csv", notes = "Long LMM with FI extension on same common sample")
write_agg_csv(lmm_compare, "k41_lmm_model_comparison.csv", notes = "Primary vs FI-extended long LMM comparison (common sample)")

write_agg_csv(ancova_primary_coef, "k41_ancova_primary_coefficients.csv", notes = "Canonical ANCOVA on common sample")
write_agg_csv(ancova_extended_coef, "k41_ancova_extended_coefficients.csv", notes = "ANCOVA with FI extension on same common sample")
write_agg_csv(ancova_compare, "k41_ancova_model_comparison.csv", notes = "Primary vs FI-extended ANCOVA comparison (common sample)")

# -----------------------------------------------------------------------------
# 5) Decision log, session info, and external input receipt
# -----------------------------------------------------------------------------
decision_lines <- c(
  paste0("timestamp=", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "k41_objective=canonical_primary_preserved_fi_extended_added",
  "canonical_policy=Primary formulas unchanged from ANALYSIS_PLAN; FI appears only in extended models.",
  paste0("lmm_primary_formula=", deparse(lmm_primary_formula)),
  paste0("lmm_extended_formula=", deparse(lmm_extended_formula)),
  paste0("ancova_primary_formula=", deparse(ancova_primary_formula)),
  paste0("ancova_extended_formula=", deparse(ancova_extended_formula)),
  paste0("n_long_primary=", long_primary_n),
  paste0("n_long_extended=", long_extended_n),
  paste0("n_long_common=", long_common_n),
  paste0("n_wide_primary=", wide_primary_n),
  paste0("n_wide_extended=", wide_extended_n),
  paste0("n_wide_common=", wide_common_n),
  "governance=Repo outputs are aggregate-only. No patient-level exports written by K41."
)
write_agg_txt(decision_lines, "k41_decision_log.txt", notes = "K41 canonical-vs-extended decision trace")

session_path <- file.path(outputs_dir, "k41_sessioninfo.txt")
writeLines(c(capture.output(sessionInfo()), capture.output(tryCatch(renv::status(), error = function(e) e$message))), session_path)
append_artifact("k41_sessioninfo", "sessioninfo", session_path, notes = "K41 sessionInfo + renv status")

receipt_lines <- c(
  paste0("timestamp=", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  paste0("data_root=", data_root),
  paste0("input_k33_long_path=", resolved$k33_long),
  paste0("input_k33_long_md5=", md5_file(resolved$k33_long)),
  paste0("input_k33_long_nrow=", nrow(long_df)),
  paste0("input_k33_long_ncol=", ncol(long_df)),
  paste0("input_k33_wide_path=", resolved$k33_wide),
  paste0("input_k33_wide_md5=", md5_file(resolved$k33_wide)),
  paste0("input_k33_wide_nrow=", nrow(wide_df)),
  paste0("input_k33_wide_ncol=", ncol(wide_df)),
  paste0("input_k40_path=", resolved$k40),
  paste0("input_k40_md5=", md5_file(resolved$k40)),
  paste0("input_k40_nrow=", nrow(k40_df)),
  paste0("input_k40_ncol=", ncol(k40_df))
)
write_agg_txt(receipt_lines, "k41_external_input_receipt.txt", notes = "K41 external input receipt with path/md5/nrow/ncol")

cat("K41 completed successfully. Outputs at:", outputs_dir, "\n")
