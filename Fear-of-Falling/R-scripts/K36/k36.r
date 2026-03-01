#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(here)
  library(lme4)
  library(lmerTest)
})

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

first_existing <- function(nms, candidates) {
  hits <- candidates[candidates %in% nms]
  if (length(hits) == 0) return(NA_character_)
  hits[1]
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

normalize_frailty <- function(x) {
  s <- tolower(trimws(as.character(x)))
  out <- rep(NA_character_, length(s))
  out[s %in% c("robust", "0")] <- "robust"
  out[s %in% c("pre-frail", "prefrail", "pre frail", "1")] <- "pre-frail"
  out[s %in% c("frail", "2", "3", "4")] <- "frail"
  factor(out, levels = c("robust", "pre-frail", "frail"))
}

tidy_fixed <- function(model) {
  if (requireNamespace("broom.mixed", quietly = TRUE)) {
    return(broom.mixed::tidy(model, effects = "fixed", conf.int = TRUE))
  }
  sm <- summary(model)$coefficients
  p_col <- grep("Pr\\(>", colnames(sm), value = TRUE)
  stat_col <- grep("(t value|z value)", colnames(sm), value = TRUE)
  out <- tibble(
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

# ---- resolve inputs ----------------------------------------------------------
data_root <- resolve_data_root()

k33_long_path <- resolve_existing(c(
  file.path(data_root, "paper_01", "analysis", "fof_analysis_k33_long.rds"),
  file.path(data_root, "paper_01", "analysis", "fof_analysis_k33_long.csv")
))
k33_wide_path <- resolve_existing(c(
  file.path(data_root, "paper_01", "analysis", "fof_analysis_k33_wide.rds"),
  file.path(data_root, "paper_01", "analysis", "fof_analysis_k33_wide.csv")
))
k32_path <- resolve_existing(c(
  file.path(data_root, "paper_01", "capacity_scores", "kaatumisenpelko_with_capacity_scores_k32.rds"),
  file.path(data_root, "paper_01", "capacity_scores", "kaatumisenpelko_with_capacity_scores_k32.csv")
))

if (any(is.na(c(k33_long_path, k33_wide_path, k32_path)))) {
  stop(
    paste0(
      "K36 could not resolve required external inputs.\n",
      "k33_long=", k33_long_path, "\n",
      "k33_wide=", k33_wide_path, "\n",
      "k32=", k32_path
    ),
    call. = FALSE
  )
}

long_raw <- read_dataset(k33_long_path)
wide_raw <- read_dataset(k33_wide_path)
k32_raw <- read_dataset(k32_path)

id_col_k32 <- first_existing(names(k32_raw), c("id", "ID", "Jnro", "NRO"))
cap_col_k32 <- first_existing(names(k32_raw), c("capacity_score_latent_primary", "capacity_score_cfa_primary"))
if (is.na(id_col_k32) || is.na(cap_col_k32)) {
  stop("K36 missing id/capacity column in K32 dataset.", call. = FALSE)
}

k32_key <- k32_raw %>%
  transmute(
    id = trimws(as.character(.data[[id_col_k32]])),
    capacity_score_latent_primary = suppressWarnings(as.numeric(.data[[cap_col_k32]]))
  ) %>%
  filter(!is.na(id), id != "") %>%
  distinct(id, .keep_all = TRUE)

# ---- prepare long ------------------------------------------------------------
long <- long_raw %>%
  mutate(id = trimws(as.character(.data[[first_existing(names(long_raw), c("id", "ID", "Jnro", "NRO"))]]))) %>%
  left_join(k32_key, by = "id") %>%
  transmute(
    id = id,
    time_f = factor(as.integer(.data[[first_existing(names(long_raw), c("time"))]]), levels = c(0, 12), labels = c("0", "12")),
    Composite_Z = as.numeric(.data[[first_existing(names(long_raw), c("Composite_Z"))]]),
    FOF_status = normalize_fof(.data[[first_existing(names(long_raw), c("FOF_status"))]]),
    frailty_cat_3 = normalize_frailty(.data[[first_existing(names(long_raw), c("frailty_cat_3"))]]),
    tasapainovaikeus = normalize_binary(.data[[first_existing(names(long_raw), c("tasapainovaikeus"))]]),
    age = suppressWarnings(as.numeric(.data[[first_existing(names(long_raw), c("age"))]])),
    sex = factor(as.character(.data[[first_existing(names(long_raw), c("sex"))]])),
    BMI = suppressWarnings(as.numeric(.data[[first_existing(names(long_raw), c("BMI"))]])),
    capacity_score_latent_primary = capacity_score_latent_primary
  )

long_primary <- long %>% tidyr::drop_na(Composite_Z, time_f, FOF_status, frailty_cat_3, tasapainovaikeus, age, sex, BMI)
long_extended <- long %>% tidyr::drop_na(Composite_Z, time_f, FOF_status, frailty_cat_3, tasapainovaikeus, age, sex, BMI, capacity_score_latent_primary)

long_common <- long_extended

f_lmm_primary <- as.formula("Composite_Z ~ time_f * FOF_status + time_f * frailty_cat_3 + time_f * tasapainovaikeus + age + sex + BMI + (1 | id)")
f_lmm_extended <- as.formula("Composite_Z ~ time_f * FOF_status + time_f * frailty_cat_3 + time_f * tasapainovaikeus + age + sex + BMI + capacity_score_latent_primary + time_f:capacity_score_latent_primary + (1 | id)")

m_lmm_primary <- lmerTest::lmer(f_lmm_primary, data = long_primary, REML = FALSE)
m_lmm_extended <- lmerTest::lmer(f_lmm_extended, data = long_extended, REML = FALSE)
m_lmm_primary_common <- lmerTest::lmer(f_lmm_primary, data = long_common, REML = FALSE)
m_lmm_extended_common <- lmerTest::lmer(f_lmm_extended, data = long_common, REML = FALSE)

lmm_primary_tbl <- tidy_fixed(m_lmm_primary)
lmm_extended_tbl <- tidy_fixed(m_lmm_extended)

lrt <- anova(m_lmm_primary_common, m_lmm_extended_common)
lmm_cmp <- tibble(
  model = rownames(lrt),
  npar = lrt$npar,
  AIC = lrt$AIC,
  BIC = lrt$BIC,
  logLik = lrt$logLik,
  deviance = lrt$deviance,
  Chisq = if ("Chisq" %in% names(lrt)) lrt$Chisq else NA_real_,
  Df = if ("Df" %in% names(lrt)) lrt$Df else NA_real_,
  p.value = if ("Pr(>Chisq)" %in% names(lrt)) lrt[["Pr(>Chisq)"]] else NA_real_,
  n_primary = nrow(long_primary),
  n_extended = nrow(long_extended),
  n_common = nrow(long_common)
)

# ---- prepare wide ------------------------------------------------------------
wide <- wide_raw %>%
  mutate(id = trimws(as.character(.data[[first_existing(names(wide_raw), c("id", "ID", "Jnro", "NRO"))]]))) %>%
  left_join(k32_key, by = "id") %>%
  transmute(
    id = id,
    Composite_Z_baseline = as.numeric(.data[[first_existing(names(wide_raw), c("Composite_Z_baseline"))]]),
    Composite_Z_12m = as.numeric(.data[[first_existing(names(wide_raw), c("Composite_Z_12m"))]]),
    FOF_status = normalize_fof(.data[[first_existing(names(wide_raw), c("FOF_status"))]]),
    frailty_cat_3 = normalize_frailty(.data[[first_existing(names(wide_raw), c("frailty_cat_3"))]]),
    tasapainovaikeus = normalize_binary(.data[[first_existing(names(wide_raw), c("tasapainovaikeus"))]]),
    age = suppressWarnings(as.numeric(.data[[first_existing(names(wide_raw), c("age"))]])),
    sex = factor(as.character(.data[[first_existing(names(wide_raw), c("sex"))]])),
    BMI = suppressWarnings(as.numeric(.data[[first_existing(names(wide_raw), c("BMI"))]])),
    capacity_score_latent_primary = capacity_score_latent_primary
  )

wide_primary <- wide %>% tidyr::drop_na(Composite_Z_12m, Composite_Z_baseline, FOF_status, frailty_cat_3, tasapainovaikeus, age, sex, BMI)
wide_extended <- wide %>% tidyr::drop_na(Composite_Z_12m, Composite_Z_baseline, FOF_status, frailty_cat_3, tasapainovaikeus, age, sex, BMI, capacity_score_latent_primary)

f_ancova_primary <- as.formula("Composite_Z_12m ~ Composite_Z_baseline + FOF_status + frailty_cat_3 + tasapainovaikeus + age + sex + BMI")
f_ancova_extended <- as.formula("Composite_Z_12m ~ Composite_Z_baseline + FOF_status + frailty_cat_3 + tasapainovaikeus + age + sex + BMI + capacity_score_latent_primary")

m_ancova_primary <- stats::lm(f_ancova_primary, data = wide_primary)
m_ancova_extended <- stats::lm(f_ancova_extended, data = wide_extended)

coef_tbl <- function(model) {
  sm <- summary(model)$coefficients
  ci <- suppressWarnings(confint(model))
  tibble(
    term = rownames(sm),
    estimate = sm[, 1],
    std.error = sm[, 2],
    statistic = sm[, 3],
    p.value = sm[, 4],
    conf.low = ci[rownames(sm), 1],
    conf.high = ci[rownames(sm), 2]
  )
}

ancova_primary_tbl <- coef_tbl(m_ancova_primary)
ancova_extended_tbl <- coef_tbl(m_ancova_extended)
ancova_cmp <- tibble(
  model = c("primary", "extended"),
  n = c(nobs(m_ancova_primary), nobs(m_ancova_extended)),
  AIC = c(AIC(m_ancova_primary), AIC(m_ancova_extended)),
  BIC = c(BIC(m_ancova_primary), BIC(m_ancova_extended)),
  adj_r2 = c(summary(m_ancova_primary)$adj.r.squared, summary(m_ancova_extended)$adj.r.squared)
)

# ---- write outputs -----------------------------------------------------------
out_lmm_p <- file.path(outputs_dir, "k36_lmm_primary_fixed_effects.csv")
out_lmm_e <- file.path(outputs_dir, "k36_lmm_extended_fixed_effects.csv")
out_lmm_c <- file.path(outputs_dir, "k36_lmm_model_comparison.csv")
out_a_p <- file.path(outputs_dir, "k36_ancova_primary_coefficients.csv")
out_a_e <- file.path(outputs_dir, "k36_ancova_extended_coefficients.csv")
out_a_c <- file.path(outputs_dir, "k36_ancova_model_comparison.csv")
out_notes <- file.path(outputs_dir, "k36_decision_log.txt")
out_receipt <- file.path(outputs_dir, "k36_external_input_receipt.txt")
out_session <- file.path(outputs_dir, "k36_sessioninfo.txt")

readr::write_csv(lmm_primary_tbl, out_lmm_p, na = "")
readr::write_csv(lmm_extended_tbl, out_lmm_e, na = "")
readr::write_csv(lmm_cmp, out_lmm_c, na = "")
readr::write_csv(ancova_primary_tbl, out_a_p, na = "")
readr::write_csv(ancova_extended_tbl, out_a_e, na = "")
readr::write_csv(ancova_cmp, out_a_c, na = "")

notes <- c(
  "K36 extended canonical models (K26-path)",
  "Primary models are preserved; extended models add capacity terms.",
  "Long LMM extended terms: + capacity_score_latent_primary + time_f:capacity_score_latent_primary",
  "Wide ANCOVA extended term: + capacity_score_latent_primary",
  paste0("n_long_primary=", nrow(long_primary), "; n_long_extended=", nrow(long_extended), "; n_long_common=", nrow(long_common)),
  paste0("n_wide_primary=", nrow(wide_primary), "; n_wide_extended=", nrow(wide_extended))
)
writeLines(notes, out_notes)

receipt <- c(
  "script=K36",
  paste0("timestamp_utc=", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste0("data_root=", data_root),
  paste0("k33_long_path=", k33_long_path),
  paste0("k33_long_md5=", unname(tools::md5sum(k33_long_path))),
  paste0("k33_wide_path=", k33_wide_path),
  paste0("k33_wide_md5=", unname(tools::md5sum(k33_wide_path))),
  paste0("k32_path=", k32_path),
  paste0("k32_md5=", unname(tools::md5sum(k32_path))),
  paste0("k33_long_nrow=", nrow(long_raw), "; k33_long_ncol=", ncol(long_raw)),
  paste0("k33_wide_nrow=", nrow(wide_raw), "; k33_wide_ncol=", ncol(wide_raw)),
  paste0("k32_nrow=", nrow(k32_raw), "; k32_ncol=", ncol(k32_raw)),
  "governance=aggregate-only outputs in repo; patient-level data externalized in DATA_ROOT"
)
writeLines(receipt, out_receipt)

writeLines(capture.output(sessionInfo()), out_session)

append_manifest_safe("k36_lmm_primary_fixed_effects", "table_csv", out_lmm_p, n = nrow(lmm_primary_tbl), notes = "K36 baseline (primary) long LMM fixed effects")
append_manifest_safe("k36_lmm_extended_fixed_effects", "table_csv", out_lmm_e, n = nrow(lmm_extended_tbl), notes = "K36 extended long LMM fixed effects with capacity terms")
append_manifest_safe("k36_lmm_model_comparison", "table_csv", out_lmm_c, n = nrow(lmm_cmp), notes = "K36 long-model comparison primary vs extended")
append_manifest_safe("k36_ancova_primary_coefficients", "table_csv", out_a_p, n = nrow(ancova_primary_tbl), notes = "K36 baseline wide ANCOVA coefficients")
append_manifest_safe("k36_ancova_extended_coefficients", "table_csv", out_a_e, n = nrow(ancova_extended_tbl), notes = "K36 extended wide ANCOVA coefficients with capacity covariate")
append_manifest_safe("k36_ancova_model_comparison", "table_csv", out_a_c, n = nrow(ancova_cmp), notes = "K36 wide-model comparison primary vs extended")
append_manifest_safe("k36_decision_log", "text", out_notes, notes = "K36 modeling decisions and sample sizes")
append_manifest_safe("k36_external_input_receipt", "text", out_receipt, notes = "K36 external input provenance receipt")
append_manifest_safe("k36_sessioninfo", "sessioninfo", out_session, notes = "K36 session info")

cat("K36 outputs written to:", outputs_dir, "\n")
