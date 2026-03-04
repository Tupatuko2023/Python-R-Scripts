#!/usr/bin/env Rscript
# ==============================================================================
# K32_EXTENDED_CAPACITY_PRIMARY - Deterministic 4-5 Indicator Capacity Model
# File: k32.r
#
# Purpose
# - Implement a controlled extended latent capacity model with a deterministic
#   indicator set and admissibility gate.
# - Keep K30/K31 unchanged; K32 is a new parallel script.
# - Always compute z-composite fallback scores.
# ==============================================================================
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tidyr)
  library(tibble)
  library(purrr)
  library(janitor)
  library(here)
  library(lavaan)
})

# --- Standard init -------------------------------------------------------------
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.[Rr]$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K32"
}
script_label_raw <- sub("\\..*$", "", sub("\\.V.*$", "", script_base))
script_label <- toupper(script_label_raw)
if (is.na(script_label) || script_label == "") script_label <- "K32"

source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

# --- Deterministic indicator defaults -----------------------------------------
manual_map <- c(
  grip = NA_character_,
  gait = NA_character_,
  chair = "tuoli0",
  balance = "seisominen0",
  self_report = "vaikeus_liikkua_500m"
)

candidates <- list(
  grip = c("puristus0_clean", "puristus0", "puristusvoima_kg_oik_0", "puristusvoima_kg_vas_0"),
  gait = c("kavelynopeus_m_sek0", "kavelynopeus0"),
  chair = c("tuoli0", "tuoliltanousu0"),
  balance = c("seisominen0"),
  self_report = c("vaikeus_liikkua_500m", "vaikeus500m", "vaikeus_liikkua_2km")
)

GRIP_VERY_HIGH_KG <- 80
SCORE_NA_SHARE_MAX <- 0.20

# --- Helpers ------------------------------------------------------------------
dir_create <- function(path) {
  if (!dir.exists(path)) dir.create(path, recursive = TRUE, showWarnings = FALSE)
  invisible(path)
}

write_lines_safely <- function(lines, path) {
  dir_create(dirname(path))
  writeLines(lines, con = path, useBytes = TRUE)
  path
}

write_csv_safely <- function(df, path) {
  dir_create(dirname(path))
  readr::write_csv(df, file = path, na = "")
  path
}

write_rds_safely <- function(obj, path) {
  dir_create(dirname(path))
  saveRDS(obj, file = path)
  path
}

resolve_data_root <- function() {
  data_root <- Sys.getenv("DATA_ROOT", unset = "")
  if (!nzchar(data_root)) {
    stop(
      paste0(
        "DATA_ROOT is not set. Refusing to write patient-level outputs into repo.\n",
        "Set config/.env with: export DATA_ROOT=/absolute/path/to/local_data\n",
        "Run via runner/pattern that sources config/.env."
      ),
      call. = FALSE
    )
  }
  normalizePath(data_root, winslash = "/", mustWork = FALSE)
}

append_manifest_safe <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  n_chr <- if (is.na(n)) NA_character_ else as.character(n)
  append_manifest(
    manifest_row(
      script = script_label,
      label = label,
      path = get_relpath(path),
      kind = kind,
      n = n_chr,
      notes = notes
    ),
    manifest_path
  )
  invisible(TRUE)
}

safe_num <- function(x) suppressWarnings(as.numeric(x))

safe_cor <- function(x, y, method = "spearman") {
  ok <- complete.cases(x, y)
  if (sum(ok) < 3) return(NA_real_)
  suppressWarnings(cor(x[ok], y[ok], method = method))
}

na_row_mean <- function(mat) {
  nonmiss <- rowSums(!is.na(mat))
  out <- rowMeans(mat, na.rm = TRUE)
  out[nonmiss == 0] <- NA_real_
  out
}

audit_cont <- function(x) {
  tibble(
    n = length(x),
    n_miss = sum(is.na(x)),
    p_miss = mean(is.na(x)),
    mean = mean(x, na.rm = TRUE),
    sd = sd(x, na.rm = TRUE),
    median = median(x, na.rm = TRUE),
    p01 = as.numeric(quantile(x, 0.01, na.rm = TRUE, names = FALSE)),
    p99 = as.numeric(quantile(x, 0.99, na.rm = TRUE, names = FALSE)),
    min = suppressWarnings(min(x, na.rm = TRUE)),
    max = suppressWarnings(max(x, na.rm = TRUE))
  )
}

audit_cat <- function(x) {
  tab <- table(x, useNA = "ifany")
  prop <- prop.table(tab)
  tibble(
    level = names(tab),
    n = as.integer(tab),
    p = as.numeric(prop)
  ) %>%
    arrange(desc(n)) %>%
    mutate(flag_rare = p < 0.05)
}

closest_match <- function(target, choices) {
  if (length(choices) == 0) return(character(0))
  d <- adist(target, choices, ignore.case = TRUE)
  choices[order(d)][1:min(5, length(choices))]
}

resolve_one <- function(df_names, key) {
  manual <- manual_map[[key]]
  if (!is.na(manual) && nzchar(manual) && manual %in% df_names) return(manual)

  cand <- candidates[[key]]
  hit <- cand[cand %in% df_names]
  if (length(hit) > 0) return(hit[1])

  fuzzy <- df_names[str_detect(df_names, fixed(key, ignore_case = TRUE))]
  if (length(fuzzy) == 1) return(fuzzy[1])
  NA_character_
}

build_mapping <- function(df_names) {
  keys <- names(manual_map)
  mapped <- setNames(rep(NA_character_, length(keys)), keys)
  for (k in keys) mapped[[k]] <- resolve_one(df_names, k)

  required <- c("grip", "gait", "chair", "balance")
  unresolved_required <- required[is.na(mapped[required])]

  list(
    mapped = mapped,
    unresolved_required = unresolved_required
  )
}

find_input_dataset <- function() {
  tried <- character(0)

  env_path <- Sys.getenv("DATA_PATH", unset = "")
  if (nzchar(env_path)) {
    tried <- c(tried, env_path)
    if (!file.exists(env_path)) {
      stop("DATA_PATH is set but file does not exist: ", env_path, call. = FALSE)
    }
    ext <- tolower(tools::file_ext(env_path))
    kind <- if (ext == "rds") "rds" else "csv"
    return(list(kind = kind, path = normalizePath(env_path), tried = tried))
  }

  data_root <- Sys.getenv("DATA_ROOT", unset = "")
  if (nzchar(data_root)) {
    root_candidates <- c(
      file.path(data_root, "paper_01", "capacity_scores", "kaatumisenpelko_with_capacity_scores_k31.rds"),
      file.path(data_root, "paper_01", "capacity_scores", "kaatumisenpelko_with_capacity_scores_k31.csv"),
      file.path(data_root, "paper_01", "capacity_scores", "kaatumisenpelko_with_capacity_scores.rds"),
      file.path(data_root, "paper_01", "capacity_scores", "kaatumisenpelko_with_capacity_scores.csv")
    )
    tried <- c(tried, root_candidates)
    hit <- root_candidates[file.exists(root_candidates)][1]
    if (!is.na(hit) && nzchar(hit)) {
      ext <- tolower(tools::file_ext(hit))
      kind <- if (ext == "rds") "rds" else "csv"
      return(list(kind = kind, path = normalizePath(hit), tried = tried))
    }
  }

  repo_candidates <- c(
    here::here("R-scripts", "K31", "outputs", "kaatumisenpelko_with_capacity_scores_k31.rds"),
    here::here("R-scripts", "K31", "outputs", "kaatumisenpelko_with_capacity_scores_k31.csv"),
    here::here("R-scripts", "K30", "outputs", "kaatumisenpelko_with_capacity_scores.rds"),
    here::here("R-scripts", "K30", "outputs", "kaatumisenpelko_with_capacity_scores.csv"),
    here::here("data", "raw", "KaatumisenPelko.csv"),
    here::here("data", "external", "KaatumisenPelko.csv"),
    here::here("data", "KaatumisenPelko.csv"),
    here::here("dataset", "KaatumisenPelko.csv"),
    here::here("KaatumisenPelko.csv")
  )
  tried <- c(tried, repo_candidates)
  hit <- repo_candidates[file.exists(repo_candidates)][1]
  if (!is.na(hit) && nzchar(hit)) {
    ext <- tolower(tools::file_ext(hit))
    kind <- if (ext == "rds") "rds" else "csv"
    return(list(kind = kind, path = normalizePath(hit), tried = tried))
  }

  stop(
    paste0(
      "Could not locate K32 input dataset.\n",
      "Tried paths:\n- ", paste(unique(tried), collapse = "\n- "), "\n\n",
      "Set one of:\n",
      "1) --DATA_PATH=/absolute/path/to/input.(rds|csv)\n",
      "2) DATA_ROOT with paper_01/capacity_scores outputs available."
    ),
    call. = FALSE
  )
}

recode_self_report_capacity <- function(x) {
  x_num <- safe_num(x)
  vals <- sort(unique(x_num[!is.na(x_num)]))
  if (length(vals) == 0) return(rep(NA_real_, length(x_num)))

  if (all(vals %in% c(0, 1, 2))) {
    return(case_when(
      is.na(x_num) ~ NA_real_,
      x_num == 0 ~ 2,
      x_num == 1 ~ 1,
      x_num == 2 ~ 0,
      TRUE ~ NA_real_
    ))
  }

  if (all(vals %in% c(1, 2, 3))) {
    return(case_when(
      is.na(x_num) ~ NA_real_,
      x_num == 1 ~ 2,
      x_num == 2 ~ 1,
      x_num == 3 ~ 0,
      TRUE ~ NA_real_
    ))
  }

  rep(NA_real_, length(x_num))
}

fit_capacity_cfa <- function(df_model, use_self_report) {
  rhs <- c("grip", "gait", "chair", "balance")
  if (isTRUE(use_self_report)) rhs <- c(rhs, "self_report")

  model_cfa <- paste0("Capacity =~ ", paste(rhs, collapse = " + "))
  ordered_vars <- if (isTRUE(use_self_report)) "self_report" else character(0)
  estimator <- if (length(ordered_vars) > 0) "WLSMV" else "MLR"

  cfa_warn <- character(0)
  fit <- withCallingHandlers(
    tryCatch(
      lavaan::cfa(
        model = model_cfa,
        data = df_model,
        estimator = estimator,
        ordered = ordered_vars,
        missing = "pairwise"
      ),
      error = function(e) e
    ),
    warning = function(w) {
      cfa_warn <<- c(cfa_warn, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  if (inherits(fit, "error")) {
    return(list(
      fit = NULL,
      score = rep(NA_real_, nrow(df_model)),
      diagnostics = tibble(
        converged_ok = FALSE,
        has_neg_resid_var = NA,
        has_std_loading_gt1 = NA,
        score_na_share = 1,
        loading_signs_ok = NA,
        admissible = FALSE,
        reason = paste0("cfa_error: ", conditionMessage(fit)),
        warning_count = length(cfa_warn),
        warnings = paste(unique(cfa_warn), collapse = " | ")
      )
    ))
  }

  pe <- parameterEstimates(fit, standardized = TRUE) %>% as_tibble()
  loadings <- pe %>% filter(op == "=~")
  resid_vars <- pe %>%
    filter(op == "~~", lhs == rhs, lhs %in% c("grip", "gait", "chair", "balance", "self_report"))

  fs <- tryCatch(lavaan::lavPredict(fit, method = "EBM"), error = function(e) NULL)
  score <- if (is.null(fs)) rep(NA_real_, nrow(df_model)) else as.numeric(fs[, 1])

  converged_ok <- isTRUE(lavInspect(fit, "converged"))
  has_neg_resid_var <- any(resid_vars$est < 0, na.rm = TRUE)
  has_std_loading_gt1 <- any(abs(loadings$std.all) > 1, na.rm = TRUE)
  score_na_share <- mean(is.na(score))

  expected_sign_map <- c(
    grip = 1,
    gait = 1,
    chair = -1,
    balance = 1,
    self_report = 1
  )

  load_sign_tbl <- loadings %>%
    transmute(
      indicator = rhs,
      std.all = std.all,
      actual_sign = sign(std.all),
      expected_sign = expected_sign_map[indicator]
    )

  gait_loading <- load_sign_tbl %>% filter(indicator == "gait") %>% pull(std.all)
  gait_loading <- if (length(gait_loading) > 0) gait_loading[1] else NA_real_

  pos_expected <- load_sign_tbl %>% filter(expected_sign == 1, !is.na(std.all))
  pos_negative_count <- sum(pos_expected$std.all < 0, na.rm = TRUE)
  pos_total <- nrow(pos_expected)
  majority_expected_positive_negative <- (pos_total > 0) && (pos_negative_count > (pos_total / 2))

  orientation_flip_applied <- (!is.na(gait_loading) && gait_loading < 0) || majority_expected_positive_negative
  if (isTRUE(orientation_flip_applied)) score <- -1 * score

  load_sign_tbl <- load_sign_tbl %>%
    mutate(oriented_sign = if (isTRUE(orientation_flip_applied)) -1 * actual_sign else actual_sign)

  comparable <- load_sign_tbl %>%
    filter(!is.na(expected_sign), !is.na(oriented_sign), oriented_sign != 0)
  loading_signs_ok <- if (nrow(comparable) == 0) FALSE else all(comparable$oriented_sign == comparable$expected_sign)

  admissible <- isTRUE(converged_ok) && !has_neg_resid_var && !has_std_loading_gt1 &&
    isTRUE(loading_signs_ok) && (score_na_share <= SCORE_NA_SHARE_MAX)

  reason <- c()
  if (!converged_ok) reason <- c(reason, "not_converged")
  if (has_neg_resid_var) reason <- c(reason, "neg_resid_var")
  if (has_std_loading_gt1) reason <- c(reason, "std_loading_gt1")
  if (!isTRUE(loading_signs_ok)) reason <- c(reason, "loading_sign_mismatch")
  if (score_na_share > SCORE_NA_SHARE_MAX) reason <- c(reason, "score_na_share_high")
  if (length(reason) == 0) reason <- "admissible"

  if (!admissible) score[] <- NA_real_

  list(
    fit = fit,
    score = score,
    diagnostics = tibble(
      converged_ok = converged_ok,
      has_neg_resid_var = has_neg_resid_var,
      has_std_loading_gt1 = has_std_loading_gt1,
      score_na_share = score_na_share,
      loading_signs_ok = loading_signs_ok,
      orientation_flip_applied = orientation_flip_applied,
      gait_loading_std_all = gait_loading,
      expected_sign_map = "grip:+;gait:+;chair:-;balance:+;self_report:+",
      admissible = admissible,
      reason = paste(reason, collapse = ";"),
      warning_count = length(cfa_warn),
      warnings = paste(unique(cfa_warn), collapse = " | ")
    )
  )
}

save_lavaan_outputs <- function(fit, prefix) {
  sum_path <- file.path(outputs_dir, paste0(prefix, "_summary.txt"))
  load_path <- file.path(outputs_dir, paste0(prefix, "_loadings.csv"))

  if (is.null(fit)) {
    write_lines_safely(c(paste0(prefix, " - cfa failed (no fit object)")), sum_path)
    write_csv_safely(tibble(), load_path)
    append_manifest_safe(label = paste0(prefix, "_summary"), kind = "text", path = sum_path)
    append_manifest_safe(label = paste0(prefix, "_loadings"), kind = "table_csv", path = load_path)
    return(invisible(list(summary = sum_path, loadings = load_path)))
  }

  lines <- c(
    paste0(prefix, " - lavaan CFA"),
    capture.output(summary(fit, standardized = TRUE, fit.measures = TRUE))
  )
  write_lines_safely(lines, sum_path)
  append_manifest_safe(label = paste0(prefix, "_summary"), kind = "text", path = sum_path)

  pe <- parameterEstimates(fit, standardized = TRUE) %>%
    as_tibble() %>%
    filter(op == "=~") %>%
    select(lhs, op, rhs, est, se, z, pvalue, std.all)
  write_csv_safely(pe, load_path)
  append_manifest_safe(label = paste0(prefix, "_loadings"), kind = "table_csv", path = load_path)

  invisible(list(summary = sum_path, loadings = load_path))
}

# --- 1) Load input -------------------------------------------------------------
dir_create(outputs_dir)
input_info <- find_input_dataset()

if (input_info$kind == "rds") {
  df_raw <- readRDS(input_info$path)
} else {
  df_raw <- readr::read_csv(input_info$path, show_col_types = FALSE)
}

df <- janitor::clean_names(as_tibble(df_raw))

colnames_path <- file.path(outputs_dir, "k32_columns_after_clean_names.txt")
write_lines_safely(sort(names(df)), colnames_path)
append_manifest_safe(label = "k32_columns_after_clean_names", kind = "text", path = colnames_path)

message("Loaded input: ", basename(input_info$path), " (rows=", nrow(df), ", cols=", ncol(df), ")")

# --- 2) Resolve indicator mapping ---------------------------------------------
map_res <- build_mapping(names(df))
map <- map_res$mapped

if (length(map_res$unresolved_required) > 0) {
  lines <- c(
    "K32 mapping unresolved.",
    paste0("Missing required: ", paste(map_res$unresolved_required, collapse = ", "))
  )
  for (k in names(map)) {
    if (is.na(map[[k]]) && k %in% names(candidates)) {
      lines <- c(lines, paste0("- target: ", k), paste0("  closest: ", paste(closest_match(k, names(df)), collapse = ", ")))
    }
  }
  suggest_path <- file.path(outputs_dir, "k32_mapping_suggestions.txt")
  write_lines_safely(lines, suggest_path)
  append_manifest_safe(label = "k32_mapping_suggestions", kind = "text", path = suggest_path)
  stop("K32 mapping failed. See: ", suggest_path, call. = FALSE)
}

# --- 3) Build scoring indicators ----------------------------------------------
self_raw <- if (!is.na(map[["self_report"]])) df[[map[["self_report"]]]] else rep(NA_real_, nrow(df))
self_capacity <- recode_self_report_capacity(self_raw)
self_capacity_ord <- factor(self_capacity, levels = c(0, 1, 2), ordered = TRUE)
self_present <- any(!is.na(self_capacity))

df_scored <- df %>%
  mutate(
    indicator_grip = safe_num(.data[[map[["grip"]]]]),
    indicator_gait_raw = safe_num(.data[[map[["gait"]]]]),
    indicator_chair_raw = safe_num(.data[[map[["chair"]]]]),
    indicator_balance_raw = safe_num(.data[[map[["balance"]]]]),
    indicator_self_report_raw = safe_num(self_raw),
    indicator_gait_primary = if_else(indicator_gait_raw == 0, NA_real_, indicator_gait_raw),
    indicator_gait_sensitivity = indicator_gait_raw,
    indicator_chair_capacity = if_else(is.na(indicator_chair_raw), NA_real_, -1 * indicator_chair_raw),
    indicator_balance_capacity = indicator_balance_raw,
    indicator_self_report_capacity = self_capacity,
    indicator_self_report_ordered = self_capacity_ord
  )

if ("puristus0_clean" != map[["grip"]] && "puristus0" == map[["grip"]]) {
  df_scored <- df_scored %>% mutate(indicator_grip = if_else(indicator_grip <= 0, NA_real_, indicator_grip))
}

# --- 4) Audits ----------------------------------------------------------------
cont_audit <- bind_rows(
  audit_cont(df_scored$indicator_grip) %>% mutate(var = "indicator_grip"),
  audit_cont(df_scored$indicator_gait_primary) %>% mutate(var = "indicator_gait_primary"),
  audit_cont(df_scored$indicator_gait_sensitivity) %>% mutate(var = "indicator_gait_sensitivity"),
  audit_cont(df_scored$indicator_chair_capacity) %>% mutate(var = "indicator_chair_capacity"),
  audit_cont(df_scored$indicator_balance_capacity) %>% mutate(var = "indicator_balance_capacity")
) %>% select(var, everything())
cont_path <- file.path(outputs_dir, "k32_audit_continuous.csv")
write_csv_safely(cont_audit, cont_path)
append_manifest_safe(label = "k32_audit_continuous", kind = "table_csv", path = cont_path, n = nrow(df_scored))

self_tbl <- audit_cat(df_scored$indicator_self_report_raw)
self_path <- file.path(outputs_dir, "k32_audit_self_report_freq.csv")
write_csv_safely(self_tbl, self_path)
append_manifest_safe(label = "k32_audit_self_report_freq", kind = "table_csv", path = self_path, n = nrow(df_scored))

corr_vars <- df_scored %>% transmute(
  grip = indicator_grip,
  gait_primary = indicator_gait_primary,
  chair = indicator_chair_capacity,
  balance = indicator_balance_capacity,
  self = indicator_self_report_capacity
)
cor_mat <- suppressWarnings(cor(corr_vars, use = "pairwise.complete.obs"))
cor_tbl <- as.data.frame(as.table(cor_mat)) %>%
  as_tibble() %>%
  rename(var1 = Var1, var2 = Var2, r = Freq)
cor_path <- file.path(outputs_dir, "k32_audit_correlations.csv")
write_csv_safely(cor_tbl, cor_path)
append_manifest_safe(label = "k32_audit_correlations", kind = "table_csv", path = cor_path, n = nrow(df_scored))

flags <- tibble(
  flag_walkspeed_zero = mean(df_scored$indicator_gait_raw == 0, na.rm = TRUE),
  flag_grip_very_high = mean(df_scored$indicator_grip > GRIP_VERY_HIGH_KG, na.rm = TRUE),
  flag_chair_nonpositive_raw = mean(df_scored$indicator_chair_raw <= 0, na.rm = TRUE),
  grip_very_high_threshold = GRIP_VERY_HIGH_KG
)
flags_path <- file.path(outputs_dir, "k32_red_flags.csv")
write_csv_safely(flags, flags_path)
append_manifest_safe(label = "k32_red_flags", kind = "table_csv", path = flags_path, n = nrow(df_scored))

decision_lines <- c(
  "K32 decisions (extended deterministic capacity model)",
  paste0("Input source: ", input_info$path),
  "Indicator defaults:",
  paste0("- grip: ", map[["grip"]]),
  paste0("- gait: ", map[["gait"]], " (primary 0->NA; sensitivity retains 0)"),
  paste0("- chair: ", map[["chair"]], " transformed to capacity as -chair_time"),
  paste0("- balance: ", map[["balance"]]),
  paste0("- self-report: ", ifelse(!is.na(map[["self_report"]]), map[["self_report"]], "not available")),
  "Self-report recode is deterministic (0/1/2 or 1/2/3 to high-is-better capacity scale).",
  "Expected loading sign map: grip(+), gait(+), chair(-), balance(+), self_report(+ high-is-better coding).",
  "Factor score orientation rule: if gait loading is negative OR majority expected-positive indicators load negative, multiply latent score by -1.",
  "CFA admissibility gate: converged, no Heywood, no Std.all>1, signs coherent vs expected map (after deterministic orientation), low score NA share.",
  paste0("Admissibility threshold score_na_share <= ", SCORE_NA_SHARE_MAX)
)
dec_path <- file.path(outputs_dir, "k32_decision_log.txt")
write_lines_safely(decision_lines, dec_path)
append_manifest_safe(label = "k32_decision_log", kind = "text", path = dec_path, n = nrow(df_scored))

# --- 5) CFA (primary + sensitivity) -------------------------------------------
build_model_df <- function(gait_col, include_self) {
  out <- df_scored %>% transmute(
    grip = indicator_grip,
    gait = .data[[gait_col]],
    chair = indicator_chair_capacity,
    balance = indicator_balance_capacity,
    self_report = indicator_self_report_ordered
  )
  if (!include_self) out <- out %>% select(-self_report)
  out
}

cfa_primary_in <- build_model_df("indicator_gait_primary", self_present)
cfa_sens_in <- build_model_df("indicator_gait_sensitivity", self_present)

cfa_primary <- fit_capacity_cfa(cfa_primary_in, use_self_report = self_present)
cfa_sens <- fit_capacity_cfa(cfa_sens_in, use_self_report = self_present)

df_scored <- df_scored %>% mutate(
  capacity_score_latent_primary = cfa_primary$score,
  capacity_score_latent_sensitivity = cfa_sens$score
)

save_lavaan_outputs(cfa_primary$fit, "k32_cfa_primary")
save_lavaan_outputs(cfa_sens$fit, "k32_cfa_sensitivity")

cfa_diag <- bind_rows(
  cfa_primary$diagnostics %>% mutate(model = "primary_zero_to_na", ordered_self_report = self_present),
  cfa_sens$diagnostics %>% mutate(model = "sensitivity_zero_retained", ordered_self_report = self_present)
) %>% select(model, ordered_self_report, everything())
cfa_diag_path <- file.path(outputs_dir, "k32_cfa_diagnostics.csv")
write_csv_safely(cfa_diag, cfa_diag_path)
append_manifest_safe(label = "k32_cfa_diagnostics", kind = "table_csv", path = cfa_diag_path, n = nrow(df_scored))

# --- 6) Always-available z-composites -----------------------------------------
z4_primary <- df_scored %>% transmute(
  z_grip = as.numeric(scale(indicator_grip)),
  z_gait = as.numeric(scale(indicator_gait_primary)),
  z_chair = as.numeric(scale(indicator_chair_capacity)),
  z_balance = as.numeric(scale(indicator_balance_capacity))
)
z4_sens <- df_scored %>% transmute(
  z_grip = as.numeric(scale(indicator_grip)),
  z_gait = as.numeric(scale(indicator_gait_sensitivity)),
  z_chair = as.numeric(scale(indicator_chair_capacity)),
  z_balance = as.numeric(scale(indicator_balance_capacity))
)

if (self_present) {
  z_self <- as.numeric(scale(df_scored$indicator_self_report_capacity))
  z5_primary <- cbind(as.matrix(z4_primary), z_self = z_self)
  z5_sens <- cbind(as.matrix(z4_sens), z_self = z_self)
} else {
  z5_primary <- NULL
  z5_sens <- NULL
}

df_scored <- df_scored %>% mutate(
  capacity_score_z4_primary = na_row_mean(as.matrix(z4_primary)),
  capacity_score_z4_sensitivity = na_row_mean(as.matrix(z4_sens)),
  capacity_score_z5_primary = if (self_present) na_row_mean(z5_primary) else NA_real_,
  capacity_score_z5_sensitivity = if (self_present) na_row_mean(z5_sens) else NA_real_
)

score_summ <- tibble(
  score = c(
    "capacity_score_latent_primary",
    "capacity_score_latent_sensitivity",
    "capacity_score_z4_primary",
    "capacity_score_z4_sensitivity",
    "capacity_score_z5_primary",
    "capacity_score_z5_sensitivity"
  ),
  n = c(
    sum(!is.na(df_scored$capacity_score_latent_primary)),
    sum(!is.na(df_scored$capacity_score_latent_sensitivity)),
    sum(!is.na(df_scored$capacity_score_z4_primary)),
    sum(!is.na(df_scored$capacity_score_z4_sensitivity)),
    sum(!is.na(df_scored$capacity_score_z5_primary)),
    sum(!is.na(df_scored$capacity_score_z5_sensitivity))
  ),
  mean = c(
    mean(df_scored$capacity_score_latent_primary, na.rm = TRUE),
    mean(df_scored$capacity_score_latent_sensitivity, na.rm = TRUE),
    mean(df_scored$capacity_score_z4_primary, na.rm = TRUE),
    mean(df_scored$capacity_score_z4_sensitivity, na.rm = TRUE),
    mean(df_scored$capacity_score_z5_primary, na.rm = TRUE),
    mean(df_scored$capacity_score_z5_sensitivity, na.rm = TRUE)
  ),
  sd = c(
    sd(df_scored$capacity_score_latent_primary, na.rm = TRUE),
    sd(df_scored$capacity_score_latent_sensitivity, na.rm = TRUE),
    sd(df_scored$capacity_score_z4_primary, na.rm = TRUE),
    sd(df_scored$capacity_score_z4_sensitivity, na.rm = TRUE),
    sd(df_scored$capacity_score_z5_primary, na.rm = TRUE),
    sd(df_scored$capacity_score_z5_sensitivity, na.rm = TRUE)
  )
)
scores_path <- file.path(outputs_dir, "k32_scores_summary.csv")
write_csv_safely(score_summ, scores_path)
append_manifest_safe(label = "k32_scores_summary", kind = "table_csv", path = scores_path, n = nrow(df_scored))

# --- 7) Save dataset + reproducibility ----------------------------------------
data_root <- resolve_data_root()
external_dir <- file.path(data_root, "paper_01", "capacity_scores")
dir_create(external_dir)

out_csv <- file.path(external_dir, "kaatumisenpelko_with_capacity_scores_k32.csv")
out_rds <- file.path(external_dir, "kaatumisenpelko_with_capacity_scores_k32.rds")
write_csv_safely(df_scored, out_csv)
write_rds_safely(df_scored, out_rds)

csv_md5 <- unname(tools::md5sum(out_csv)[1])
rds_md5 <- unname(tools::md5sum(out_rds)[1])
receipt_path <- file.path(outputs_dir, "k32_patient_level_output_receipt.txt")
receipt_lines <- c(
  paste0("script=", script_label),
  paste0("timestamp_utc=", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste0("data_root=", data_root),
  paste0("external_dir=", external_dir),
  paste0("csv_path=", out_csv),
  paste0("csv_md5=", csv_md5),
  paste0("rds_path=", out_rds),
  paste0("rds_md5=", rds_md5),
  paste0("nrow=", nrow(df_scored)),
  paste0("ncol=", ncol(df_scored))
)
write_lines_safely(receipt_lines, receipt_path)
append_manifest_safe(
  label = "k32_patient_level_output_receipt",
  kind = "text",
  path = receipt_path,
  n = nrow(df_scored),
  notes = "Patient-level CSV/RDS written to DATA_ROOT external path."
)

sess_path <- file.path(outputs_dir, "k32_sessioninfo.txt")
write_lines_safely(capture.output(sessionInfo()), sess_path)
append_manifest_safe(label = "k32_sessioninfo", kind = "text", path = sess_path)

message("K32 complete. Outputs written to: ", outputs_dir)
