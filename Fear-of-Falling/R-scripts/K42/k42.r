#!/usr/bin/env Rscript
# ==============================================================================
# K42 - Capacity vs FI head-to-head (common-sample deterministic comparisons)
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

script_label <- "K42"
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
  capacity_dir <- file.path(data_root, "paper_01", "capacity_scores")
  fv_dir <- file.path(data_root, "paper_01", "frailty_vulnerability")

  list(
    k33_long = pick_first_existing(file.path(analysis_dir, c("fof_analysis_k33_long.rds", "fof_analysis_k33_long.csv"))),
    k33_wide = pick_first_existing(file.path(analysis_dir, c("fof_analysis_k33_wide.rds", "fof_analysis_k33_wide.csv"))),
    k32 = pick_first_existing(file.path(capacity_dir, c("kaatumisenpelko_with_capacity_scores_k32.rds", "kaatumisenpelko_with_capacity_scores_k32.csv"))),
    k40 = pick_first_existing(file.path(fv_dir, c("kaatumisenpelko_with_frailty_index_k40.rds", "kaatumisenpelko_with_frailty_index_k40.csv")))
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

safe_cor <- function(x, y) {
  ok <- !is.na(x) & !is.na(y)
  if (sum(ok) < 10) return(NA_real_)
  suppressWarnings(cor(x[ok], y[ok]))
}

is_singular_fit <- function(model) {
  if (!inherits(model, "merMod")) return(NA)
  tryCatch(lme4::isSingular(model, tol = 1e-4), error = function(e) NA)
}

calc_vif_manual <- function(lm_model) {
  x <- model.matrix(lm_model)
  if (ncol(x) <= 2) return(tibble(term = character(0), vif = numeric(0)))
  x <- x[, colnames(x) != "(Intercept)", drop = FALSE]
  out <- lapply(colnames(x), function(nm) {
    y <- x[, nm]
    others <- x[, colnames(x) != nm, drop = FALSE]
    if (ncol(others) == 0) return(tibble(term = nm, vif = NA_real_))
    tmp <- tryCatch(summary(lm(y ~ others))$r.squared, error = function(e) NA_real_)
    vif <- ifelse(is.na(tmp) || tmp >= 0.999999, NA_real_, 1 / (1 - tmp))
    tibble(term = nm, vif = vif)
  })
  bind_rows(out)
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
# Inputs
# -----------------------------------------------------------------------------
data_root <- infer_data_root()
resolved <- resolve_inputs(data_root)
if (any(is.na(unlist(resolved)))) {
  stop(
    paste0(
      "K42 missing required inputs: ",
      paste(names(resolved)[is.na(unlist(resolved))], collapse = ", ")
    ),
    call. = FALSE
  )
}

k33_long <- load_tabular(resolved$k33_long)
k33_wide <- load_tabular(resolved$k33_wide)
k32 <- load_tabular(resolved$k32)
k40 <- load_tabular(resolved$k40)

names(k33_long) <- clean_names_simple(names(k33_long))
names(k33_wide) <- clean_names_simple(names(k33_wide))
names(k32) <- clean_names_simple(names(k32))
names(k40) <- clean_names_simple(names(k40))

# Harmonize IDs
id_long <- find_col(names(k33_long), c("id", "participant_id", "subject_id", "study_id"))
id_wide <- find_col(names(k33_wide), c("id", "participant_id", "subject_id", "study_id"))
id_k32 <- find_col(names(k32), c("id", "participant_id", "subject_id", "study_id", "nro", "jnro"))
id_k40 <- find_col(names(k40), c("id", "participant_id", "subject_id", "study_id"))
if (any(is.na(c(id_long, id_wide, id_k32, id_k40)))) stop("Could not resolve ID columns", call. = FALSE)

names(k33_long)[names(k33_long) == id_long] <- "id"
names(k33_wide)[names(k33_wide) == id_wide] <- "id"
names(k32)[names(k32) == id_k32] <- "id"
names(k40)[names(k40) == id_k40] <- "id"

cap_col <- find_col(names(k32), c("capacity_score_latent_primary", "capacity_score"))
fi_col <- find_col(names(k40), c("frailty_index_fi_k40_z", "frailty_index_fi_z"))
if (is.na(cap_col) || is.na(fi_col)) stop("Required capacity/FI columns missing in K32/K40 input", call. = FALSE)

cap_df <- k32 %>%
  group_by(id) %>%
  slice(1L) %>%
  ungroup() %>%
  transmute(id, capacity_score_latent_primary = as.numeric(.data[[cap_col]]))

fi_df <- k40 %>%
  group_by(id) %>%
  slice(1L) %>%
  ungroup() %>%
  transmute(id, frailty_index_fi_k40_z = as.numeric(.data[[fi_col]]))

long_joined <- k33_long %>% left_join(cap_df, by = "id") %>% left_join(fi_df, by = "id")
wide_joined <- k33_wide %>% left_join(cap_df, by = "id") %>% left_join(fi_df, by = "id")

# Canonical model datasets
long_model <- long_joined %>%
  mutate(
    composite_z = as.numeric(.data[[find_col(names(.), c("composite_z"))]]),
    time = normalize_time(.data[[find_col(names(.), c("time", "timepoint", "visit", "aika"))]]),
    fof_status = normalize_fof(.data[[find_col(names(.), c("fof_status", "kaatumisenpelko_on", "kaatumisenpelkoon"))]]),
    frailty_cat_3 = normalize_frailty_cat(.data[[find_col(names(.), c("frailty_cat_3"))]]),
    tasapainovaikeus = coerce_binary01(.data[[find_col(names(.), c("tasapainovaikeus"))]]),
    age = as.numeric(.data[[find_col(names(.), c("age", "ika"))]]),
    sex = normalize_sex(.data[[find_col(names(.), c("sex", "sukupuoli"))]]),
    bmi = as.numeric(.data[[find_col(names(.), c("bmi"))]]),
    capacity_score_latent_primary = as.numeric(capacity_score_latent_primary),
    frailty_index_fi_k40_z = as.numeric(frailty_index_fi_k40_z)
  ) %>%
  select(id, composite_z, time, fof_status, frailty_cat_3, tasapainovaikeus, age, sex, bmi,
         capacity_score_latent_primary, frailty_index_fi_k40_z)

wide_model <- wide_joined %>%
  mutate(
    composite_z_baseline = as.numeric(.data[[find_col(names(.), c("composite_z_baseline", "composite_z0"))]]),
    composite_z_12m = as.numeric(.data[[find_col(names(.), c("composite_z_12m", "composite_z12"))]]),
    fof_status = normalize_fof(.data[[find_col(names(.), c("fof_status", "kaatumisenpelko_on", "kaatumisenpelkoon"))]]),
    frailty_cat_3 = normalize_frailty_cat(.data[[find_col(names(.), c("frailty_cat_3"))]]),
    tasapainovaikeus = coerce_binary01(.data[[find_col(names(.), c("tasapainovaikeus"))]]),
    age = as.numeric(.data[[find_col(names(.), c("age", "ika"))]]),
    sex = normalize_sex(.data[[find_col(names(.), c("sex", "sukupuoli"))]]),
    bmi = as.numeric(.data[[find_col(names(.), c("bmi"))]]),
    capacity_score_latent_primary = as.numeric(capacity_score_latent_primary),
    frailty_index_fi_k40_z = as.numeric(frailty_index_fi_k40_z)
  ) %>%
  select(id, composite_z_baseline, composite_z_12m, fof_status, frailty_cat_3, tasapainovaikeus, age, sex, bmi,
         capacity_score_latent_primary, frailty_index_fi_k40_z)

# -----------------------------------------------------------------------------
# Common-sample gate (all 4 models each family)
# -----------------------------------------------------------------------------
long_primary_vars <- c("id", "composite_z", "time", "fof_status", "frailty_cat_3", "tasapainovaikeus", "age", "sex", "bmi")
long_capacity_vars <- c(long_primary_vars, "capacity_score_latent_primary")
long_fi_vars <- c(long_primary_vars, "frailty_index_fi_k40_z")
long_both_vars <- c(long_primary_vars, "capacity_score_latent_primary", "frailty_index_fi_k40_z")

wide_primary_vars <- c("id", "composite_z_12m", "composite_z_baseline", "fof_status", "frailty_cat_3", "tasapainovaikeus", "age", "sex", "bmi")
wide_capacity_vars <- c(wide_primary_vars, "capacity_score_latent_primary")
wide_fi_vars <- c(wide_primary_vars, "frailty_index_fi_k40_z")
wide_both_vars <- c(wide_primary_vars, "capacity_score_latent_primary", "frailty_index_fi_k40_z")

cc_long_primary <- complete.cases(long_model[, long_primary_vars, drop = FALSE])
cc_long_capacity <- complete.cases(long_model[, long_capacity_vars, drop = FALSE])
cc_long_fi <- complete.cases(long_model[, long_fi_vars, drop = FALSE])
cc_long_both <- complete.cases(long_model[, long_both_vars, drop = FALSE])
cc_long_common <- cc_long_primary & cc_long_capacity & cc_long_fi & cc_long_both

cc_wide_primary <- complete.cases(wide_model[, wide_primary_vars, drop = FALSE])
cc_wide_capacity <- complete.cases(wide_model[, wide_capacity_vars, drop = FALSE])
cc_wide_fi <- complete.cases(wide_model[, wide_fi_vars, drop = FALSE])
cc_wide_both <- complete.cases(wide_model[, wide_both_vars, drop = FALSE])
cc_wide_common <- cc_wide_primary & cc_wide_capacity & cc_wide_fi & cc_wide_both

n_long_common <- sum(cc_long_common)
n_wide_common <- sum(cc_wide_common)
if (n_long_common < 20 || n_wide_common < 20) {
  stop(paste0("Common sample too small. n_long_common=", n_long_common, ", n_wide_common=", n_wide_common), call. = FALSE)
}

counts_df <- tibble(
  metric = c(
    "n_long_primary", "n_long_capacity", "n_long_fi", "n_long_both", "n_long_common",
    "n_wide_primary", "n_wide_capacity", "n_wide_fi", "n_wide_both", "n_wide_common",
    "n_long_primary_ids", "n_long_capacity_ids", "n_long_fi_ids", "n_long_both_ids", "n_long_common_ids",
    "n_wide_primary_ids", "n_wide_capacity_ids", "n_wide_fi_ids", "n_wide_both_ids", "n_wide_common_ids"
  ),
  value = c(
    sum(cc_long_primary), sum(cc_long_capacity), sum(cc_long_fi), sum(cc_long_both), sum(cc_long_common),
    sum(cc_wide_primary), sum(cc_wide_capacity), sum(cc_wide_fi), sum(cc_wide_both), sum(cc_wide_common),
    n_distinct(long_model$id[cc_long_primary]), n_distinct(long_model$id[cc_long_capacity]),
    n_distinct(long_model$id[cc_long_fi]), n_distinct(long_model$id[cc_long_both]), n_distinct(long_model$id[cc_long_common]),
    n_distinct(wide_model$id[cc_wide_primary]), n_distinct(wide_model$id[cc_wide_capacity]),
    n_distinct(wide_model$id[cc_wide_fi]), n_distinct(wide_model$id[cc_wide_both]), n_distinct(wide_model$id[cc_wide_common])
  )
)
write_agg_csv(counts_df, "k42_common_sample_counts.csv", notes = "Common-sample counts for all four model sets")

# Data for fitting
long_fit <- long_model[cc_long_common, , drop = FALSE] %>%
  mutate(
    fof_status = droplevels(fof_status),
    frailty_cat_3 = droplevels(frailty_cat_3),
    sex = droplevels(sex)
  )
wide_fit <- wide_model[cc_wide_common, , drop = FALSE] %>%
  mutate(
    fof_status = droplevels(fof_status),
    frailty_cat_3 = droplevels(frailty_cat_3),
    sex = droplevels(sex)
  )

if (nlevels(long_fit$fof_status) < 2 || nlevels(long_fit$frailty_cat_3) < 2 || nlevels(long_fit$sex) < 2) {
  stop("Insufficient factor levels in long common sample", call. = FALSE)
}
if (nlevels(wide_fit$fof_status) < 2 || nlevels(wide_fit$frailty_cat_3) < 2 || nlevels(wide_fit$sex) < 2) {
  stop("Insufficient factor levels in wide common sample", call. = FALSE)
}

# -----------------------------------------------------------------------------
# Models
# -----------------------------------------------------------------------------
lmm_primary_formula <- composite_z ~ time * fof_status + time * frailty_cat_3 + time * tasapainovaikeus + age + sex + bmi + (1 | id)
lmm_capacity_formula <- composite_z ~ time * fof_status + time * frailty_cat_3 + time * tasapainovaikeus + capacity_score_latent_primary + time:capacity_score_latent_primary + age + sex + bmi + (1 | id)
lmm_fi_formula <- composite_z ~ time * fof_status + time * frailty_cat_3 + time * tasapainovaikeus + frailty_index_fi_k40_z + time:frailty_index_fi_k40_z + age + sex + bmi + (1 | id)
lmm_both_formula <- composite_z ~ time * fof_status + time * frailty_cat_3 + time * tasapainovaikeus + capacity_score_latent_primary + time:capacity_score_latent_primary + frailty_index_fi_k40_z + time:frailty_index_fi_k40_z + age + sex + bmi + (1 | id)

ancova_primary_formula <- composite_z_12m ~ composite_z_baseline + fof_status + frailty_cat_3 + tasapainovaikeus + age + sex + bmi
ancova_capacity_formula <- composite_z_12m ~ composite_z_baseline + fof_status + frailty_cat_3 + tasapainovaikeus + capacity_score_latent_primary + age + sex + bmi
ancova_fi_formula <- composite_z_12m ~ composite_z_baseline + fof_status + frailty_cat_3 + tasapainovaikeus + frailty_index_fi_k40_z + age + sex + bmi
ancova_both_formula <- composite_z_12m ~ composite_z_baseline + fof_status + frailty_cat_3 + tasapainovaikeus + capacity_score_latent_primary + frailty_index_fi_k40_z + age + sex + bmi

lmm_primary <- lmer(lmm_primary_formula, data = long_fit, REML = FALSE)
lmm_capacity <- lmer(lmm_capacity_formula, data = long_fit, REML = FALSE)
lmm_fi <- lmer(lmm_fi_formula, data = long_fit, REML = FALSE)
lmm_both <- lmer(lmm_both_formula, data = long_fit, REML = FALSE)

ancova_primary <- lm(ancova_primary_formula, data = wide_fit)
ancova_capacity <- lm(ancova_capacity_formula, data = wide_fit)
ancova_fi <- lm(ancova_fi_formula, data = wide_fit)
ancova_both <- lm(ancova_both_formula, data = wide_fit)

write_agg_csv(tidy_model(lmm_primary), "k42_lmm_primary_coefficients.csv", notes = "Long model primary")
write_agg_csv(tidy_model(lmm_capacity), "k42_lmm_capacity_coefficients.csv", notes = "Long model + capacity")
write_agg_csv(tidy_model(lmm_fi), "k42_lmm_fi_coefficients.csv", notes = "Long model + FI")
write_agg_csv(tidy_model(lmm_both), "k42_lmm_both_coefficients.csv", notes = "Long model + both")

write_agg_csv(tidy_model(ancova_primary), "k42_ancova_primary_coefficients.csv", notes = "Wide ANCOVA primary")
write_agg_csv(tidy_model(ancova_capacity), "k42_ancova_capacity_coefficients.csv", notes = "Wide ANCOVA + capacity")
write_agg_csv(tidy_model(ancova_fi), "k42_ancova_fi_coefficients.csv", notes = "Wide ANCOVA + FI")
write_agg_csv(tidy_model(ancova_both), "k42_ancova_both_coefficients.csv", notes = "Wide ANCOVA + both")

# LMM comparisons
lmm_models <- list(primary = lmm_primary, capacity = lmm_capacity, fi = lmm_fi, both = lmm_both)
lmm_comp <- bind_rows(lapply(names(lmm_models), function(nm) {
  m <- lmm_models[[nm]]
  tibble(model = nm, nobs = nobs(m), npar = attr(logLik(m), "df"), AIC = AIC(m), BIC = BIC(m), logLik = as.numeric(logLik(m)))
}))

add_lrt <- function(base, mod) {
  a <- anova(base, mod)
  p_col <- grep("Pr\\(>Chisq\\)", names(a), value = TRUE)
  tibble(
    lrt_vs = deparse(formula(mod))[1],
    chisq = if ("Chisq" %in% names(a)) as.numeric(a$Chisq[2]) else NA_real_,
    df = if ("Df" %in% names(a)) as.numeric(a$Df[2]) else NA_real_,
    p_value = if (length(p_col) == 1) as.numeric(a[[p_col]][2]) else NA_real_
  )
}

lmm_lrt_tbl <- bind_rows(
  add_lrt(lmm_primary, lmm_capacity) %>% mutate(model = "capacity"),
  add_lrt(lmm_primary, lmm_fi) %>% mutate(model = "fi"),
  add_lrt(lmm_primary, lmm_both) %>% mutate(model = "both"),
  add_lrt(lmm_capacity, lmm_both) %>% mutate(model = "both_vs_capacity"),
  add_lrt(lmm_fi, lmm_both) %>% mutate(model = "both_vs_fi")
)

lmm_compare <- lmm_comp %>% left_join(lmm_lrt_tbl %>% select(model, chisq, df, p_value), by = "model")
write_agg_csv(lmm_compare, "k42_lmm_model_comparison.csv", notes = "LMM model comparison and nested LRT summaries")

# ANCOVA comparisons
ancova_models <- list(primary = ancova_primary, capacity = ancova_capacity, fi = ancova_fi, both = ancova_both)
ancova_comp <- bind_rows(lapply(names(ancova_models), function(nm) {
  m <- ancova_models[[nm]]
  tibble(model = nm, nobs = nobs(m), AIC = AIC(m), BIC = BIC(m), adj_r_squared = summary(m)$adj.r.squared, sigma = summary(m)$sigma)
}))

add_f <- function(base, mod, label) {
  a <- anova(base, mod)
  tibble(model = label, F_stat = as.numeric(a$F[2]), df = as.numeric(a$Df[2]), p_value = as.numeric(a$`Pr(>F)`[2]))
}
ancova_lrt <- bind_rows(
  add_f(ancova_primary, ancova_capacity, "capacity"),
  add_f(ancova_primary, ancova_fi, "fi"),
  add_f(ancova_primary, ancova_both, "both"),
  add_f(ancova_capacity, ancova_both, "both_vs_capacity"),
  add_f(ancova_fi, ancova_both, "both_vs_fi")
)

ancova_compare <- ancova_comp %>% left_join(ancova_lrt %>% select(model, F_stat, df, p_value), by = "model")
write_agg_csv(ancova_compare, "k42_ancova_model_comparison.csv", notes = "ANCOVA model comparison and nested F-test summaries")

# Collinearity
corr_long <- safe_cor(long_fit$capacity_score_latent_primary, long_fit$frailty_index_fi_k40_z)
corr_wide <- safe_cor(wide_fit$capacity_score_latent_primary, wide_fit$frailty_index_fi_k40_z)
high_corr_flag <- any(abs(c(corr_long, corr_wide)) >= 0.80, na.rm = TRUE)

vif_tbl <- calc_vif_manual(ancova_both)
if (nrow(vif_tbl) == 0) {
  vif_tbl <- tibble(term = "vif_unavailable", vif = NA_real_)
}

col_tbl <- bind_rows(
  tibble(metric = "corr_capacity_fi_long", value = corr_long),
  tibble(metric = "corr_capacity_fi_wide", value = corr_wide),
  tibble(metric = "high_collinearity_flag_abs_corr_ge_0_80", value = as.numeric(high_corr_flag)),
  vif_tbl %>% transmute(metric = paste0("vif_", term), value = vif)
)
write_agg_csv(col_tbl, "k42_capacity_fi_collinearity.csv", notes = "Capacity-FI correlation and VIF diagnostics")

# Predicted trajectories for fallback interpretation (aggregate grid only)
traj_grid <- expand.grid(
  time = sort(unique(long_fit$time)),
  capacity_score_latent_primary = c(-1, 0, 1),
  frailty_index_fi_k40_z = c(-1, 0, 1),
  fof_status = levels(long_fit$fof_status)[1],
  frailty_cat_3 = levels(long_fit$frailty_cat_3)[1],
  tasapainovaikeus = 0,
  age = mean(long_fit$age, na.rm = TRUE),
  sex = levels(long_fit$sex)[1],
  bmi = mean(long_fit$bmi, na.rm = TRUE)
)
traj_grid$pred_both <- predict(lmm_both, newdata = traj_grid, re.form = NA)
write_agg_csv(as_tibble(traj_grid), "k42_lmm_both_predicted_trajectories.csv", notes = "Aggregate prediction grid for collinearity fallback interpretation")

# Red flags and logs
red_flags <- tibble(
  flag = c(
    "long_common_sample_lt_20",
    "wide_common_sample_lt_20",
    "lmm_primary_singular",
    "lmm_capacity_singular",
    "lmm_fi_singular",
    "lmm_both_singular",
    "high_collinearity_abs_corr_ge_0_80"
  ),
  value = c(
    as.numeric(n_long_common < 20),
    as.numeric(n_wide_common < 20),
    as.numeric(is_singular_fit(lmm_primary)),
    as.numeric(is_singular_fit(lmm_capacity)),
    as.numeric(is_singular_fit(lmm_fi)),
    as.numeric(is_singular_fit(lmm_both)),
    as.numeric(high_corr_flag)
  )
)
write_agg_csv(red_flags, "k42_red_flags.csv", notes = "Deterministic red flags and collinearity gate")

decision_lines <- c(
  paste0("timestamp=", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "k42_objective=capacity_vs_fi_head_to_head",
  "canonical_policy=Primary formulas preserved; capacity/FI added only in extended models.",
  paste0("n_long_common=", n_long_common),
  paste0("n_wide_common=", n_wide_common),
  paste0("corr_capacity_fi_long=", corr_long),
  paste0("corr_capacity_fi_wide=", corr_wide),
  paste0("high_collinearity=", high_corr_flag),
  "interpretation_priority=LMM: time:capacity and time:FI. ANCOVA: main effects capacity/FI with baseline adjustment.",
  if (isTRUE(high_corr_flag)) {
    "collinearity_fallback=High collinearity detected; prioritize model comparison and predicted trajectories, avoid over-interpreting single-coefficient p-values in +both models."
  } else {
    "collinearity_fallback=Not triggered."
  },
  "governance=Aggregate-only outputs written to repo. No patient-level exports created by K42."
)
write_agg_txt(decision_lines, "k42_decision_log.txt", notes = "K42 decision trace and collinearity fallback status")

session_path <- file.path(outputs_dir, "k42_sessioninfo.txt")
writeLines(c(capture.output(sessionInfo()), capture.output(tryCatch(renv::status(), error = function(e) e$message))), session_path)
append_artifact("k42_sessioninfo", "sessioninfo", session_path, notes = "K42 sessionInfo + renv status")

receipt_lines <- c(
  paste0("timestamp=", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  paste0("data_root=", data_root),
  paste0("input_k33_long_path=", resolved$k33_long),
  paste0("input_k33_long_md5=", md5_file(resolved$k33_long)),
  paste0("input_k33_long_nrow=", nrow(k33_long)),
  paste0("input_k33_long_ncol=", ncol(k33_long)),
  paste0("input_k33_wide_path=", resolved$k33_wide),
  paste0("input_k33_wide_md5=", md5_file(resolved$k33_wide)),
  paste0("input_k33_wide_nrow=", nrow(k33_wide)),
  paste0("input_k33_wide_ncol=", ncol(k33_wide)),
  paste0("input_k32_path=", resolved$k32),
  paste0("input_k32_md5=", md5_file(resolved$k32)),
  paste0("input_k32_nrow=", nrow(k32)),
  paste0("input_k32_ncol=", ncol(k32)),
  paste0("input_k40_path=", resolved$k40),
  paste0("input_k40_md5=", md5_file(resolved$k40)),
  paste0("input_k40_nrow=", nrow(k40)),
  paste0("input_k40_ncol=", ncol(k40))
)
write_agg_txt(receipt_lines, "k42_external_input_receipt.txt", notes = "K42 external input receipt")

cat("K42 completed successfully. Outputs at:", outputs_dir, "\n")
