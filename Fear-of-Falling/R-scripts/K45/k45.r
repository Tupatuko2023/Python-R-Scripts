#!/usr/bin/env Rscript
# ==============================================================================
# K45 - Sensitivity analysis: MICE for baseline covariates/exposures only
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(here)
  library(lme4)
  library(lmerTest)
  library(mice)
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

script_label <- "K45"
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

write_agg_png <- function(filename, expr, label = filename, notes = NA_character_) {
  out_path <- file.path(outputs_dir, filename)
  png(out_path, width = 1400, height = 900, res = 140)
  on.exit(dev.off(), add = TRUE)
  eval(expr)
  append_artifact(label = label, kind = "figure_png", path = out_path, n = NA_integer_, notes = notes)
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
    k40 = pick_first_existing(file.path(fv_dir, c("kaatumisenpelko_with_frailty_index_k40.rds", "kaatumisenpelko_with_frailty_index_k40.csv"))),
    k42_lmm_both = here::here("R-scripts", "K42", "outputs", "k42_lmm_both_coefficients.csv")
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

extract_fixef <- function(model_obj) {
  sm <- summary(model_obj)
  if (inherits(model_obj, "merMod")) {
    cf <- as.data.frame(sm$coefficients)
    tibble(
      term = rownames(cf),
      estimate = cf$Estimate,
      std.error = cf$`Std. Error`,
      statistic = cf$`t value`,
      p.value = cf$`Pr(>|t|)`
    )
  } else {
    cf <- as.data.frame(sm$coefficients)
    p_col <- grep("Pr\\(>", colnames(cf), value = TRUE)[1]
    stat_col <- grep("(t value|z value)", colnames(cf), value = TRUE)[1]
    tibble(
      term = rownames(cf),
      estimate = cf$Estimate,
      std.error = cf$`Std. Error`,
      statistic = if (!is.na(stat_col)) cf[[stat_col]] else NA_real_,
      p.value = if (!is.na(p_col)) cf[[p_col]] else NA_real_
    )
  }
}

pool_models_rubin <- function(model_list, model_name) {
  m <- length(model_list)
  get_coef <- function(mm) {
    if (inherits(mm, "merMod")) {
      return(fixef(mm))
    }
    coef(mm)
  }
  terms_all <- unique(unlist(lapply(model_list, function(mm) names(get_coef(mm)))))
  terms_all <- sort(terms_all)
  out <- lapply(terms_all, function(term) {
    betas <- sapply(model_list, function(mm) {
      b <- get_coef(mm)
      if (term %in% names(b)) as.numeric(b[[term]]) else NA_real_
    })
    variances <- sapply(model_list, function(mm) {
      vc <- as.matrix(vcov(mm))
      if (term %in% rownames(vc) && term %in% colnames(vc)) as.numeric(vc[term, term]) else NA_real_
    })
    ok <- is.finite(betas) & is.finite(variances) & variances >= 0
    if (sum(ok) < 2) {
      return(tibble(
        model = model_name,
        term = term,
        estimate = NA_real_,
        std.error = NA_real_,
        statistic = NA_real_,
        df = NA_real_,
        p.value = NA_real_,
        conf.low = NA_real_,
        conf.high = NA_real_,
        fmi = NA_real_,
        m_effective = sum(ok)
      ))
    }
    q <- betas[ok]
    u <- variances[ok]
    m_eff <- length(q)
    q_bar <- mean(q)
    u_bar <- mean(u)
    b_var <- stats::var(q)
    t_var <- u_bar + (1 + 1 / m_eff) * b_var
    se <- sqrt(t_var)
    r <- ifelse(u_bar <= 0, Inf, ((1 + 1 / m_eff) * b_var) / u_bar)
    df <- if (is.finite(r)) (m_eff - 1) * (1 + 1 / r)^2 else Inf
    t_stat <- q_bar / se
    p_val <- if (is.finite(df)) 2 * stats::pt(abs(t_stat), df = df, lower.tail = FALSE) else 2 * stats::pnorm(abs(t_stat), lower.tail = FALSE)
    tcrit <- if (is.finite(df)) stats::qt(0.975, df = df) else stats::qnorm(0.975)
    conf.low <- q_bar - tcrit * se
    conf.high <- q_bar + tcrit * se
    fmi <- ifelse(t_var > 0, ((1 + 1 / m_eff) * b_var) / t_var, NA_real_)
    tibble(
      model = model_name,
      term = term,
      estimate = q_bar,
      std.error = se,
      statistic = t_stat,
      df = df,
      p.value = p_val,
      conf.low = conf.low,
      conf.high = conf.high,
      fmi = fmi,
      m_effective = m_eff
    )
  })
  bind_rows(out)
}

data_root <- infer_data_root()
resolved <- resolve_inputs(data_root)

if (any(is.na(unlist(resolved)[c("k33_long", "k33_wide", "k32", "k40")]))) {
  stop(
    paste0(
      "K45 missing required inputs: ",
      paste(names(resolved)[is.na(unlist(resolved)[c("k33_long", "k33_wide", "k32", "k40")])], collapse = ", ")
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

long_model <- k33_long %>%
  left_join(cap_df, by = "id") %>%
  left_join(fi_df, by = "id") %>%
  mutate(
    composite_z = as.numeric(.data[[find_col(names(.), c("composite_z"))]]),
    time = normalize_time(.data[[find_col(names(.), c("time", "timepoint", "visit", "aika"))]]),
    fof_status = normalize_fof(.data[[find_col(names(.), c("fof_status", "kaatumisenpelko_on", "kaatumisenpelkoon"))]]),
    frailty_cat_3 = normalize_frailty_cat(.data[[find_col(names(.), c("frailty_cat_3"))]]),
    tasapainovaikeus = coerce_binary01(.data[[find_col(names(.), c("tasapainovaikeus"))]]),
    age = as.numeric(.data[[find_col(names(.), c("age", "ika"))]]),
    sex = normalize_sex(.data[[find_col(names(.), c("sex", "sukupuoli"))]]),
    bmi = as.numeric(.data[[find_col(names(.), c("bmi"))]])
  ) %>%
  select(id, composite_z, time, fof_status, frailty_cat_3, tasapainovaikeus, age, sex, bmi,
         capacity_score_latent_primary, frailty_index_fi_k40_z)

wide_model <- k33_wide %>%
  left_join(cap_df, by = "id") %>%
  left_join(fi_df, by = "id") %>%
  mutate(
    composite_z_baseline = as.numeric(.data[[find_col(names(.), c("composite_z_baseline", "composite_z0"))]]),
    composite_z_12m = as.numeric(.data[[find_col(names(.), c("composite_z_12m", "composite_z12"))]]),
    fof_status = normalize_fof(.data[[find_col(names(.), c("fof_status", "kaatumisenpelko_on", "kaatumisenpelkoon"))]]),
    frailty_cat_3 = normalize_frailty_cat(.data[[find_col(names(.), c("frailty_cat_3"))]]),
    tasapainovaikeus = coerce_binary01(.data[[find_col(names(.), c("tasapainovaikeus"))]]),
    age = as.numeric(.data[[find_col(names(.), c("age", "ika"))]]),
    sex = normalize_sex(.data[[find_col(names(.), c("sex", "sukupuoli"))]]),
    bmi = as.numeric(.data[[find_col(names(.), c("bmi"))]])
  ) %>%
  select(id, composite_z_baseline, composite_z_12m, fof_status, frailty_cat_3, tasapainovaikeus, age, sex, bmi,
         capacity_score_latent_primary, frailty_index_fi_k40_z)

wide_outcome_complete <- wide_model %>%
  filter(!is.na(composite_z_baseline), !is.na(composite_z_12m)) %>%
  mutate(
    fof_status = factor(fof_status, levels = c("nonFOF", "FOF")),
    frailty_cat_3 = factor(frailty_cat_3, levels = c("robust", "pre-frail", "frail")),
    sex = factor(sex, levels = c("female", "male")),
    tasapainovaikeus = factor(ifelse(tasapainovaikeus == 1, "yes", "no"), levels = c("no", "yes"))
  )

if (nrow(wide_outcome_complete) < 20) {
  stop("Too few outcome-complete participants for K45 sensitivity analysis", call. = FALSE)
}

impute_vars <- c(
  "age", "sex", "bmi", "fof_status", "frailty_cat_3", "tasapainovaikeus",
  "capacity_score_latent_primary", "frailty_index_fi_k40_z"
)
all_mice_vars <- c("id", "composite_z_baseline", "composite_z_12m", impute_vars)
missing_report_vars <- c("composite_z_baseline", "composite_z_12m", impute_vars)

missing_tbl <- tibble(
  variable = missing_report_vars,
  n_missing = sapply(wide_outcome_complete[, missing_report_vars, drop = FALSE], function(x) sum(is.na(x))),
  p_missing = sapply(wide_outcome_complete[, missing_report_vars, drop = FALSE], function(x) mean(is.na(x)))
)
write_agg_csv(missing_tbl, "k45_mice_missingness_summary.csv", notes = "Missingness summary before MICE (outcome-complete participants only)")

mice_data <- wide_outcome_complete %>% select(all_of(all_mice_vars))
ini <- mice::mice(mice_data, maxit = 0, printFlag = FALSE)
meth <- ini$method
pred <- ini$predictorMatrix

meth[] <- ""
meth[impute_vars] <- c(
  "pmm", "logreg", "pmm", "logreg", "polyreg", "logreg", "pmm", "pmm"
)
pred[,] <- 0
pred[impute_vars, c("composite_z_baseline", "composite_z_12m", impute_vars)] <- 1
pred[impute_vars, "id"] <- 0
diag(pred) <- 0

seed_k45 <- 20260303L
m_k45 <- 20L
imp <- mice::mice(
  mice_data,
  m = m_k45,
  maxit = 20,
  seed = seed_k45,
  method = meth,
  predictorMatrix = pred,
  printFlag = FALSE
)

methods_txt <- c(
  "K45 MICE setup",
  paste0("seed=", seed_k45),
  paste0("m=", m_k45),
  "scope=baseline covariates/exposures only; no follow-up outcome imputation",
  "imputation_methods:"
)
methods_txt <- c(
  methods_txt,
  paste0("  ", names(meth), "=", meth),
  "predictor_matrix:"
)
pred_lines <- capture.output(print(pred))
methods_txt <- c(methods_txt, pred_lines)
write_agg_txt(methods_txt, "k45_mice_methods_and_predictor_matrix.txt", notes = "Deterministic MICE method and predictor matrix")

write_agg_png(
  "k45_mice_diagnostics_traceplot.png",
  quote({
    plot(imp)
  }),
  notes = "MICE chain diagnostics"
)

numeric_candidates <- c("age", "bmi", "capacity_score_latent_primary", "frailty_index_fi_k40_z")
numeric_density_vars <- numeric_candidates[sapply(numeric_candidates, function(v) {
  if (!v %in% names(mice_data)) return(FALSE)
  x <- mice_data[[v]]
  sum(is.na(x)) > 0 && sum(!is.na(x)) >= 2 && length(unique(stats::na.omit(x))) >= 2
})]

write_agg_png(
  "k45_mice_diagnostics_density.png",
  quote({
    if (length(numeric_density_vars) == 0) {
      plot.new()
      text(0.5, 0.5, "No eligible numeric variables with missingness for density diagnostics.")
    } else {
      formula_text <- paste("~", paste(numeric_density_vars, collapse = " + "))
      mice::densityplot(imp, stats::as.formula(formula_text))
    }
  }),
  notes = "MICE density diagnostics for numeric imputed variables"
)

imputed_list <- mice::complete(imp, action = "all")

long_formula <- composite_z ~ time * fof_status + time * frailty_cat_3 + time * tasapainovaikeus +
  capacity_score_latent_primary + time:capacity_score_latent_primary +
  frailty_index_fi_k40_z + time:frailty_index_fi_k40_z + age + sex + bmi + (1 | id)

wide_formula <- composite_z_12m ~ composite_z_baseline + fof_status + frailty_cat_3 + tasapainovaikeus +
  capacity_score_latent_primary + frailty_index_fi_k40_z + age + sex + bmi

long_models_imp <- vector("list", length(imputed_list))
wide_models_imp <- vector("list", length(imputed_list))

for (i in seq_along(imputed_list)) {
  imp_df <- imputed_list[[i]] %>%
    mutate(
      fof_status = factor(fof_status, levels = c("nonFOF", "FOF")),
      frailty_cat_3 = factor(frailty_cat_3, levels = c("robust", "pre-frail", "frail")),
      sex = factor(sex, levels = c("female", "male")),
      tasapainovaikeus = factor(tasapainovaikeus, levels = c("no", "yes"))
    )

  wide_fit_i <- imp_df
  long_fit_i <- long_model %>%
    filter(id %in% imp_df$id) %>%
    select(id, composite_z, time) %>%
    left_join(
      imp_df %>%
        select(id, fof_status, frailty_cat_3, tasapainovaikeus, age, sex, bmi, capacity_score_latent_primary, frailty_index_fi_k40_z),
      by = "id"
    ) %>%
    filter(!is.na(composite_z), !is.na(time)) %>%
    mutate(time = as.numeric(time))

  long_models_imp[[i]] <- lmer(long_formula, data = long_fit_i, REML = FALSE)
  wide_models_imp[[i]] <- lm(wide_formula, data = wide_fit_i)
}

pooled_long <- pool_models_rubin(long_models_imp, model_name = "lmm_both_pooled")
pooled_wide <- pool_models_rubin(wide_models_imp, model_name = "ancova_both_pooled")
pooled_all <- bind_rows(pooled_long, pooled_wide)
write_agg_csv(pooled_all, "k45_pooled_coefficients_k42_both.csv", notes = "Rubin-pooled estimates for K42 BOTH-model analogs")

fmi_tbl <- pooled_all %>%
  select(model, term, fmi, m_effective) %>%
  arrange(model, desc(fmi))
write_agg_csv(fmi_tbl, "k45_fraction_missing_information.csv", notes = "Fraction of missing information by pooled coefficient")

# Complete-case comparison fitted locally on outcome-complete participants with full covariates
cc_wide <- wide_outcome_complete %>%
  filter(complete.cases(across(all_of(c("composite_z_baseline", "composite_z_12m", impute_vars)))))
cc_ids <- unique(cc_wide$id)
cc_long <- long_model %>%
  filter(id %in% cc_ids) %>%
  select(id, composite_z, time) %>%
  left_join(
    cc_wide %>%
      select(id, fof_status, frailty_cat_3, tasapainovaikeus, age, sex, bmi, capacity_score_latent_primary, frailty_index_fi_k40_z),
    by = "id"
  ) %>%
  filter(!is.na(composite_z), !is.na(time))

cc_lmm <- lmer(long_formula, data = cc_long, REML = FALSE)
cc_ancova <- lm(wide_formula, data = cc_wide)

cc_tbl <- bind_rows(
  extract_fixef(cc_lmm) %>% mutate(model = "lmm_both_complete_case"),
  extract_fixef(cc_ancova) %>% mutate(model = "ancova_both_complete_case")
) %>%
  select(model, term, estimate, std.error, statistic, p.value)

cmp_tbl <- pooled_all %>%
  select(model, term, estimate, std.error, p.value) %>%
  mutate(model = ifelse(model == "lmm_both_pooled", "lmm_both_complete_case", "ancova_both_complete_case")) %>%
  rename(
    estimate_pooled = estimate,
    std_error_pooled = std.error,
    p_value_pooled = p.value
  ) %>%
  left_join(
    cc_tbl %>%
      rename(
        estimate_complete_case = estimate,
        std_error_complete_case = std.error,
        p_value_complete_case = p.value
      ),
    by = c("model", "term")
  ) %>%
  mutate(
    delta_estimate = estimate_pooled - estimate_complete_case,
    direction_consistent = case_when(
      is.na(estimate_pooled) | is.na(estimate_complete_case) ~ NA,
      estimate_pooled == 0 | estimate_complete_case == 0 ~ NA,
      sign(estimate_pooled) == sign(estimate_complete_case) ~ TRUE,
      TRUE ~ FALSE
    )
  ) %>%
  arrange(model, term)

if (file.exists(resolved$k42_lmm_both)) {
  k42_ref <- readr::read_csv(resolved$k42_lmm_both, show_col_types = FALSE) %>%
    filter(effect == "fixed") %>%
    select(term, estimate) %>%
    rename(k42_reference_estimate = estimate)
  cmp_tbl <- cmp_tbl %>% left_join(k42_ref, by = "term")
}

write_agg_csv(cmp_tbl, "k45_complete_case_vs_pooled_comparison.csv", notes = "Local complete-case vs Rubin-pooled coefficient comparison")

n_outcome_complete <- nrow(wide_outcome_complete)
n_wide_cc <- nrow(cc_wide)
n_wide_pooled <- nrow(imputed_list[[1]])
n_long_outcome_rows <- nrow(long_model %>% filter(id %in% wide_outcome_complete$id, !is.na(composite_z), !is.na(time)))
n_long_cc <- nrow(cc_long)
n_long_pooled <- nrow(long_model %>% filter(id %in% imputed_list[[1]]$id, !is.na(composite_z), !is.na(time)))

key_terms <- c("time:capacity_score_latent_primary", "time:frailty_index_fi_k40_z")
key_cmp <- cmp_tbl %>%
  filter(model == "lmm_both_complete_case", term %in% key_terms) %>%
  transmute(
    term,
    estimate_complete_case,
    estimate_pooled,
    direction_consistent
  )

decision_lines <- c(
  paste0("timestamp=", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "k45_objective=sensitivity_mice_covariates_only",
  "primary_policy=K41/K42 complete-case analyses unchanged; K45 is sensitivity only.",
  "scope_lock=no_imputation_for_composite_z_12m_or_other_followup_outcomes",
  paste0("n_wide_outcome_complete=", n_outcome_complete),
  paste0("n_wide_complete_case=", n_wide_cc),
  paste0("n_wide_after_mice=", n_wide_pooled),
  paste0("n_long_outcome_rows=", n_long_outcome_rows),
  paste0("n_long_complete_case_rows=", n_long_cc),
  paste0("n_long_after_mice_rows=", n_long_pooled),
  "key_term_direction_consistency:"
)
if (nrow(key_cmp) > 0) {
  key_lines <- apply(key_cmp, 1, function(r) {
    paste0(
      "  ", r[["term"]], ": cc=", format(as.numeric(r[["estimate_complete_case"]]), digits = 6),
      ", pooled=", format(as.numeric(r[["estimate_pooled"]]), digits = 6),
      ", direction_consistent=", as.character(r[["direction_consistent"]])
    )
  })
  decision_lines <- c(decision_lines, key_lines)
}
decision_lines <- c(
  decision_lines,
  "governance=Aggregate-only outputs written to repo; no patient-level exports created by K45."
)
write_agg_txt(decision_lines, "k45_decision_log.txt", notes = "K45 deterministic decisions, Ns, and direction consistency")

session_path <- file.path(outputs_dir, "k45_sessioninfo.txt")
writeLines(c(capture.output(sessionInfo()), capture.output(tryCatch(renv::status(), error = function(e) e$message))), session_path)
append_artifact("k45_sessioninfo", "sessioninfo", session_path, notes = "K45 sessionInfo + renv status")

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
  paste0("input_k40_ncol=", ncol(k40)),
  paste0("reference_k42_lmm_both_path=", resolved$k42_lmm_both),
  paste0("reference_k42_lmm_both_exists=", file.exists(resolved$k42_lmm_both))
)
write_agg_txt(receipt_lines, "k45_external_input_receipt.txt", notes = "K45 external input receipt")

cat("K45 completed successfully. Outputs at:", outputs_dir, "\n")
