#!/usr/bin/env Rscript
# ==============================================================================
# K36 - Primary locomotor_capacity and z3 fallback models
# File tag: K36.V2_locomotor-capacity-primary-z3-fallback.R
# Purpose: Fit the current primary locomotor_capacity models and parallel z3 fallback models.
#
# Outcome: locomotor_capacity (primary), z3 (fallback/sensitivity)
# Predictors: FOF_status
# Moderator/interaction: time x FOF_status
# Grouping variable: id
# Covariates: age, sex, BMI, tasapainovaikeus
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# id
# time
# FOF_status
# age
# sex
# BMI
# tasapainovaikeus
# locomotor_capacity
# z3
# locomotor_capacity_0
# locomotor_capacity_12m
# z3_0
# z3_12m
#
# Mapping example (optional; raw -> analysis; keep minimal + explicit):
# fof_analysis_k50_long$locomotor_capacity -> primary long outcome
# fof_analysis_k50_long$z3 -> fallback long outcome
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: NA (set only when randomness is used: MI/bootstrap/resampling)
#
# Outputs + manifest:
# - script_label: K36 (canonical)
# - outputs dir: R-scripts/K36/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load canonical K50 long/wide datasets
# 03) Standardize vars + QC (sanity checks early)
# 04) Prepare primary and fallback analysis datasets
# 05) Fit long primary/fallback models
# 06) Fit wide primary/fallback ANCOVA checks
# 07) Save aggregate artifacts -> R-scripts/K36/outputs/
# 08) Append manifest row per artifact
# 09) Save sessionInfo / renv diagnostics to manifest/
# 10) EOF marker
# ==============================================================================
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(tidyr)
  library(here)
  library(lme4)
  library(lmerTest)
})

req_cols <- c(
  "id", "time", "FOF_status", "age", "sex", "BMI", "tasapainovaikeus",
  "locomotor_capacity", "z3", "locomotor_capacity_0", "locomotor_capacity_12m", "z3_0", "z3_12m"
)

script_label <- "K36"
source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

append_manifest_safe <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  append_manifest(
    manifest_row(script = script_label, label = label, path = get_relpath(path), kind = kind, n = n, notes = notes),
    manifest_path
  )
}

resolve_data_root <- function() {
  dr <- Sys.getenv("DATA_ROOT", unset = "")
  if (!nzchar(dr)) {
    stop("K36 requires DATA_ROOT. Set config/.env and run via proot runner pattern.", call. = FALSE)
  }
  dr
}

resolve_existing <- function(candidates) {
  hit <- candidates[file.exists(candidates)][1]
  if (is.na(hit) || !nzchar(hit)) return(NA_character_)
  normalizePath(hit, winslash = "/", mustWork = TRUE)
}

read_dataset <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "rds") return(as_tibble(readRDS(path)))
  if (ext == "csv") return(as_tibble(readr::read_csv(path, show_col_types = FALSE)))
  stop("Unsupported dataset extension: ", ext, call. = FALSE)
}

normalize_fof <- function(x) {
  s <- tolower(trimws(as.character(x)))
  out <- rep(NA_character_, length(s))
  out[s %in% c("0", "nonfof", "ei fof", "without fof", "false")] <- "nonFOF"
  out[s %in% c("1", "fof", "with fof", "true")] <- "FOF"
  suppressWarnings(num <- as.integer(s))
  out[is.na(out) & !is.na(num) & num == 0L] <- "nonFOF"
  out[is.na(out) & !is.na(num) & num == 1L] <- "FOF"
  factor(out, levels = c("nonFOF", "FOF"))
}

normalize_binary <- function(x) {
  s <- tolower(trimws(as.character(x)))
  out <- rep(NA_integer_, length(s))
  out[s %in% c("0", "no", "ei", "false")] <- 0L
  out[s %in% c("1", "yes", "kylla", "kylä", "true")] <- 1L
  suppressWarnings(num <- as.integer(s))
  out[is.na(out) & !is.na(num) & num %in% c(0L, 1L)] <- num[is.na(out) & !is.na(num) & num %in% c(0L, 1L)]
  out
}

tidy_fixed <- function(model) {
  sm <- summary(model)$coefficients
  p_col <- grep("Pr\\(>", colnames(sm), value = TRUE)
  stat_col <- grep("(t value|z value)", colnames(sm), value = TRUE)
  out <- tibble(
    effect = "fixed",
    term = rownames(sm),
    estimate = sm[, "Estimate"],
    std.error = sm[, "Std. Error"],
    statistic = if (length(stat_col) > 0) sm[, stat_col[1]] else NA_real_,
    p.value = if (length(p_col) > 0) sm[, p_col[1]] else NA_real_
  )
  ci <- tryCatch(confint(model, parm = "beta_", method = "Wald"), error = function(e) NULL)
  if (!is.null(ci)) {
    out <- out %>% left_join(tibble(term = rownames(ci), conf.low = ci[, 1], conf.high = ci[, 2]), by = "term")
  } else {
    out <- out %>% mutate(conf.low = NA_real_, conf.high = NA_real_)
  }
  out
}

coef_tbl <- function(model) {
  sm <- summary(model)$coefficients
  ci <- suppressWarnings(confint(model))
  tibble(
    effect = "fixed",
    term = rownames(sm),
    estimate = sm[, 1],
    std.error = sm[, 2],
    statistic = sm[, 3],
    p.value = sm[, 4],
    conf.low = ci[rownames(sm), 1],
    conf.high = ci[rownames(sm), 2]
  )
}

data_root <- resolve_data_root()
k50_long_path <- resolve_existing(c(
  file.path(data_root, "paper_01", "analysis", "fof_analysis_k50_long.rds"),
  file.path(data_root, "paper_01", "analysis", "fof_analysis_k50_long.csv")
))
k50_wide_path <- resolve_existing(c(
  file.path(data_root, "paper_01", "analysis", "fof_analysis_k50_wide.rds"),
  file.path(data_root, "paper_01", "analysis", "fof_analysis_k50_wide.csv")
))

if (any(is.na(c(k50_long_path, k50_wide_path)))) {
  stop(
    paste0(
      "K36 could not resolve canonical K50 inputs.\n",
      "k50_long=", k50_long_path, "\n",
      "k50_wide=", k50_wide_path
    ),
    call. = FALSE
  )
}

long_raw <- read_dataset(k50_long_path)
wide_raw <- read_dataset(k50_wide_path)

long_required <- c("id", "time", "FOF_status", "age", "sex", "BMI", "tasapainovaikeus", "locomotor_capacity", "z3")
wide_required <- c("id", "FOF_status", "age", "sex", "BMI", "tasapainovaikeus", "locomotor_capacity_0", "locomotor_capacity_12m", "z3_0", "z3_12m")
miss_long <- setdiff(long_required, names(long_raw))
miss_wide <- setdiff(wide_required, names(wide_raw))
if (length(miss_long) > 0 || length(miss_wide) > 0) {
  stop(
    paste0(
      "K36 canonical K50 inputs are missing required columns.\n",
      "long: ", paste(miss_long, collapse = ", "), "\n",
      "wide: ", paste(miss_wide, collapse = ", ")
    ),
    call. = FALSE
  )
}

long <- long_raw %>%
  transmute(
    id = trimws(as.character(.data$id)),
    time_f = factor(as.integer(.data$time), levels = c(0, 12), labels = c("0", "12")),
    FOF_status = normalize_fof(.data$FOF_status),
    age = suppressWarnings(as.numeric(.data$age)),
    sex = factor(as.character(.data$sex)),
    BMI = suppressWarnings(as.numeric(.data$BMI)),
    tasapainovaikeus = normalize_binary(.data$tasapainovaikeus),
    locomotor_capacity = suppressWarnings(as.numeric(.data$locomotor_capacity)),
    z3 = suppressWarnings(as.numeric(.data$z3))
  )

wide <- wide_raw %>%
  transmute(
    id = trimws(as.character(.data$id)),
    FOF_status = normalize_fof(.data$FOF_status),
    age = suppressWarnings(as.numeric(.data$age)),
    sex = factor(as.character(.data$sex)),
    BMI = suppressWarnings(as.numeric(.data$BMI)),
    tasapainovaikeus = normalize_binary(.data$tasapainovaikeus),
    locomotor_capacity_0 = suppressWarnings(as.numeric(.data$locomotor_capacity_0)),
    locomotor_capacity_12m = suppressWarnings(as.numeric(.data$locomotor_capacity_12m)),
    z3_0 = suppressWarnings(as.numeric(.data$z3_0)),
    z3_12m = suppressWarnings(as.numeric(.data$z3_12m))
  )

long_primary <- long %>% drop_na(locomotor_capacity, time_f, FOF_status, age, sex, BMI, tasapainovaikeus)
long_fallback <- long %>% drop_na(z3, time_f, FOF_status, age, sex, BMI, tasapainovaikeus)

wide_primary <- wide %>% drop_na(locomotor_capacity_0, locomotor_capacity_12m, FOF_status, age, sex, BMI, tasapainovaikeus)
wide_fallback <- wide %>% drop_na(z3_0, z3_12m, FOF_status, age, sex, BMI, tasapainovaikeus)

f_lmm_primary <- locomotor_capacity ~ time_f * FOF_status + age + sex + BMI + tasapainovaikeus + (1 | id)
f_lmm_fallback <- z3 ~ time_f * FOF_status + age + sex + BMI + tasapainovaikeus + (1 | id)
f_ancova_primary <- locomotor_capacity_12m ~ locomotor_capacity_0 + FOF_status + age + sex + BMI + tasapainovaikeus
f_ancova_fallback <- z3_12m ~ z3_0 + FOF_status + age + sex + BMI + tasapainovaikeus

m_lmm_primary <- lmerTest::lmer(f_lmm_primary, data = long_primary, REML = FALSE)
m_lmm_fallback <- lmerTest::lmer(f_lmm_fallback, data = long_fallback, REML = FALSE)
m_ancova_primary <- stats::lm(f_ancova_primary, data = wide_primary)
m_ancova_fallback <- stats::lm(f_ancova_fallback, data = wide_fallback)

lmm_primary_tbl <- tidy_fixed(m_lmm_primary) %>% mutate(outcome = "locomotor_capacity", role = "primary", framework = "LMM")
lmm_fallback_tbl <- tidy_fixed(m_lmm_fallback) %>% mutate(outcome = "z3", role = "fallback", framework = "LMM")
ancova_primary_tbl <- coef_tbl(m_ancova_primary) %>% mutate(outcome = "locomotor_capacity", role = "primary", framework = "ANCOVA")
ancova_fallback_tbl <- coef_tbl(m_ancova_fallback) %>% mutate(outcome = "z3", role = "fallback", framework = "ANCOVA")

overview_tbl <- bind_rows(
  tibble(
    framework = "LMM",
    outcome = c("locomotor_capacity", "z3"),
    role = c("primary", "fallback"),
    n = c(nrow(long_primary), nrow(long_fallback)),
    AIC = c(AIC(m_lmm_primary), AIC(m_lmm_fallback)),
    BIC = c(BIC(m_lmm_primary), BIC(m_lmm_fallback)),
    adj_r2 = NA_real_
  ),
  tibble(
    framework = "ANCOVA",
    outcome = c("locomotor_capacity", "z3"),
    role = c("primary", "fallback"),
    n = c(nobs(m_ancova_primary), nobs(m_ancova_fallback)),
    AIC = c(AIC(m_ancova_primary), AIC(m_ancova_fallback)),
    BIC = c(BIC(m_ancova_primary), BIC(m_ancova_fallback)),
    adj_r2 = c(summary(m_ancova_primary)$adj.r.squared, summary(m_ancova_fallback)$adj.r.squared)
  )
)

out_lmm_primary <- file.path(outputs_dir, "k36_locomotor_capacity_lmm_fixed_effects.csv")
out_lmm_fallback <- file.path(outputs_dir, "k36_z3_fallback_lmm_fixed_effects.csv")
out_ancova_primary <- file.path(outputs_dir, "k36_locomotor_capacity_ancova_coefficients.csv")
out_ancova_fallback <- file.path(outputs_dir, "k36_z3_fallback_ancova_coefficients.csv")
out_overview <- file.path(outputs_dir, "k36_outcome_model_overview.csv")
out_notes <- file.path(outputs_dir, "k36_decision_log.txt")
out_receipt <- file.path(outputs_dir, "k36_external_input_receipt.txt")
out_session <- file.path(outputs_dir, "k36_sessioninfo.txt")

readr::write_csv(lmm_primary_tbl, out_lmm_primary, na = "")
readr::write_csv(lmm_fallback_tbl, out_lmm_fallback, na = "")
readr::write_csv(ancova_primary_tbl, out_ancova_primary, na = "")
readr::write_csv(ancova_fallback_tbl, out_ancova_fallback, na = "")
readr::write_csv(overview_tbl, out_overview, na = "")

notes <- c(
  "K36 outcome architecture aligned to ANALYSIS_PLAN.md",
  "Primary outcome line: locomotor_capacity",
  "Fallback/sensitivity outcome line: z3",
  "Composite_Z is not modeled here; legacy bridge work remains outside the active primary branch.",
  paste0("n_long_primary=", nrow(long_primary), "; n_long_fallback=", nrow(long_fallback)),
  paste0("n_wide_primary=", nrow(wide_primary), "; n_wide_fallback=", nrow(wide_fallback))
)
writeLines(notes, out_notes)

receipt <- c(
  "script=K36",
  paste0("timestamp_utc=", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste0("data_root=", data_root),
  paste0("k50_long_path=", k50_long_path),
  paste0("k50_long_md5=", unname(tools::md5sum(k50_long_path))),
  paste0("k50_wide_path=", k50_wide_path),
  paste0("k50_wide_md5=", unname(tools::md5sum(k50_wide_path))),
  "primary_outcome=locomotor_capacity",
  "fallback_outcome=z3",
  paste0("k50_long_nrow=", nrow(long_raw), "; k50_long_ncol=", ncol(long_raw)),
  paste0("k50_wide_nrow=", nrow(wide_raw), "; k50_wide_ncol=", ncol(wide_raw)),
  "governance=aggregate-only outputs in repo; patient-level data externalized in DATA_ROOT"
)
writeLines(receipt, out_receipt)
writeLines(capture.output(sessionInfo()), out_session)

append_manifest_safe("k36_locomotor_capacity_lmm_fixed_effects", "table_csv", out_lmm_primary, n = nrow(lmm_primary_tbl), notes = "K36 primary locomotor_capacity LMM fixed effects")
append_manifest_safe("k36_z3_fallback_lmm_fixed_effects", "table_csv", out_lmm_fallback, n = nrow(lmm_fallback_tbl), notes = "K36 fallback z3 LMM fixed effects")
append_manifest_safe("k36_locomotor_capacity_ancova_coefficients", "table_csv", out_ancova_primary, n = nrow(ancova_primary_tbl), notes = "K36 primary locomotor_capacity ANCOVA coefficients")
append_manifest_safe("k36_z3_fallback_ancova_coefficients", "table_csv", out_ancova_fallback, n = nrow(ancova_fallback_tbl), notes = "K36 fallback z3 ANCOVA coefficients")
append_manifest_safe("k36_outcome_model_overview", "table_csv", out_overview, n = nrow(overview_tbl), notes = "K36 primary vs fallback outcome overview")
append_manifest_safe("k36_decision_log", "text", out_notes, notes = "K36 outcome architecture decisions")
append_manifest_safe("k36_external_input_receipt", "text", out_receipt, notes = "K36 canonical K50 input provenance receipt")
append_manifest_safe("k36_sessioninfo", "sessioninfo", out_session, notes = "K36 session info")

cat("K36 outputs written to:", outputs_dir, "\n")
