#!/usr/bin/env Rscript
# ==============================================================================
# K31_CAPACITY_SECONDARY - Extended Latent Capacity Model (Secondary)
# File: k31.r
#
# Purpose
# - Build a secondary 4-5 indicator capacity model (over-identified CFA target)
#   while keeping K30 composite pipeline as primary unchanged.
# - Required objective indicators: grip + gait + chair + balance (baseline).
# - Optional (max 1) self-report indicator: walking-difficulty item.
# - Fit CFA for primary/sensitivity gait handling and release latent scores only
#   if deterministic admissibility criteria pass.
# - Always compute transparent z-composite fallback scores from the same indicators.
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
  "K31"
}
script_label_raw <- sub("\\..*$", "", sub("\\.V.*$", "", script_base))
script_label <- toupper(script_label_raw)
if (is.na(script_label) || script_label == "") script_label <- "K31"

source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

# --- Mapping defaults ----------------------------------------------------------
manual_map <- c(
  grip = NA_character_,
  gait = NA_character_,
  chair = NA_character_,
  balance = NA_character_,
  balance_right = NA_character_,
  balance_left = NA_character_,
  self_report = NA_character_
)

candidates <- list(
  grip = c("puristus0_clean", "puristus0", "puristusvoima_kg_oik_0", "puristusvoima_kg_vas_0"),
  gait = c("kavelynopeus_m_sek0", "kavelynopeus0"),
  chair = c("tuoli0", "tuoliltanousu0"),
  balance = c("seisominen0"),
  balance_right = c("yhdella_jalalla_seisominen_oik_0"),
  balance_left = c("yhdella_jalalla_seisominen_vas_0"),
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
        "Run via runner that sources config/.env, e.g.:\n",
        "  bash scripts/termux/run_k31_proot.sh"
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

  required <- c("grip", "gait", "chair")
  unresolved_required <- required[is.na(mapped[required])]

  # balance can be direct, or fallback from right+left
  balance_ok <- !is.na(mapped[["balance"]]) || (!is.na(mapped[["balance_right"]]) && !is.na(mapped[["balance_left"]]))

  list(
    mapped = mapped,
    unresolved_required = unresolved_required,
    balance_ok = balance_ok
  )
}

find_input_dataset <- function() {
  # Preferred: K30 analysis-ready dataset
  k30_rds <- here::here("R-scripts", "K30", "outputs", "kaatumisenpelko_with_capacity_scores.rds")
  if (file.exists(k30_rds)) {
    return(list(kind = "rds", path = normalizePath(k30_rds)))
  }

  env_path <- Sys.getenv("DATA_PATH", unset = "")
  if (nzchar(env_path)) {
    if (!file.exists(env_path)) {
      stop("DATA_PATH is set but file does not exist: ", env_path)
    }
    ext <- tolower(tools::file_ext(env_path))
    kind <- if (ext == "rds") "rds" else "csv"
    return(list(kind = kind, path = normalizePath(env_path)))
  }

  filename <- "KaatumisenPelko.csv"
  candidates_csv <- c(
    here::here("data", "raw", filename),
    here::here("data", "external", filename),
    here::here("data", filename),
    here::here("dataset", filename),
    here::here(filename)
  )
  hit <- candidates_csv[file.exists(candidates_csv)][1]
  if (!is.na(hit) && nzchar(hit)) return(list(kind = "csv", path = normalizePath(hit)))

  msg <- paste0(
    "Could not locate K31 input dataset. Tried:\n",
    "- ", k30_rds, "\n",
    "- ", paste(candidates_csv, collapse = "\n- "), "\n\n",
    "Set DATA_PATH to .rds or .csv."
  )
  stop(msg, call. = FALSE)
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

  obj_ld <- loadings %>% filter(rhs %in% c("grip", "gait", "chair", "balance")) %>% pull(std.all)
  obj_sign <- sign(obj_ld[!is.na(obj_ld) & obj_ld != 0])
  loading_signs_ok <- if (length(obj_sign) <= 1) TRUE else length(unique(obj_sign)) == 1

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

colnames_path <- file.path(outputs_dir, "k31_columns_after_clean_names.txt")
write_lines_safely(sort(names(df)), colnames_path)
append_manifest_safe(label = "k31_columns_after_clean_names", kind = "text", path = colnames_path)

message("Loaded input: ", basename(input_info$path), " (rows=", nrow(df), ", cols=", ncol(df), ")")

# --- 2) Resolve indicator mapping ---------------------------------------------
map_res <- build_mapping(names(df))
map <- map_res$mapped

if (length(map_res$unresolved_required) > 0 || !map_res$balance_ok) {
  lines <- c("K31 mapping unresolved.")
  if (length(map_res$unresolved_required) > 0) {
    lines <- c(lines, paste0("Missing required: ", paste(map_res$unresolved_required, collapse = ", ")))
  }
  if (!map_res$balance_ok) {
    lines <- c(lines, "Missing required: balance (direct or right+left fallback)")
  }

  for (k in names(map)) {
    if (is.na(map[[k]])) {
      lines <- c(lines, paste0("- target: ", k), paste0("  closest: ", paste(closest_match(k, names(df)), collapse = ", ")))
    }
  }
  suggest_path <- file.path(outputs_dir, "k31_mapping_suggestions.txt")
  write_lines_safely(lines, suggest_path)
  append_manifest_safe(label = "k31_mapping_suggestions", kind = "text", path = suggest_path)
  stop("K31 mapping failed. See: ", suggest_path, call. = FALSE)
}

# --- 3) Build scoring indicators ----------------------------------------------
balance_raw <- if (!is.na(map[["balance"]])) {
  df[[map[["balance"]]]]
} else {
  br <- safe_num(df[[map[["balance_right"]]]])
  bl <- safe_num(df[[map[["balance_left"]]]])
  rowMeans(cbind(br, bl), na.rm = TRUE)
}

self_raw <- if (!is.na(map[["self_report"]])) df[[map[["self_report"]]]] else rep(NA_real_, nrow(df))
self_raw_num <- safe_num(self_raw)

self_capacity <- case_when(
  is.na(self_raw_num) ~ NA_real_,
  self_raw_num == 0 ~ 2,
  self_raw_num == 1 ~ 1,
  self_raw_num == 2 ~ 0,
  TRUE ~ NA_real_
)
self_capacity_ord <- factor(self_capacity, levels = c(0, 1, 2), ordered = TRUE)
self_present <- any(!is.na(self_capacity))

df_scored <- df %>%
  mutate(
    indicator_grip = safe_num(.data[[map[["grip"]]]]),
    indicator_gait_raw = safe_num(.data[[map[["gait"]]]]),
    indicator_chair_raw = safe_num(.data[[map[["chair"]]]]),
    indicator_balance_raw = safe_num(balance_raw),
    indicator_self_report_raw = self_raw_num,
    indicator_gait_primary = if_else(indicator_gait_raw == 0, NA_real_, indicator_gait_raw),
    indicator_gait_sensitivity = indicator_gait_raw,
    indicator_chair_capacity = if_else(is.na(indicator_chair_raw), NA_real_, -1 * indicator_chair_raw),
    indicator_balance_capacity = indicator_balance_raw,
    indicator_self_report_capacity = self_capacity,
    indicator_self_report_ordered = self_capacity_ord
  )

# --- 4) Audits ----------------------------------------------------------------
cont_audit <- bind_rows(
  audit_cont(df_scored$indicator_grip) %>% mutate(var = "indicator_grip"),
  audit_cont(df_scored$indicator_gait_primary) %>% mutate(var = "indicator_gait_primary"),
  audit_cont(df_scored$indicator_gait_sensitivity) %>% mutate(var = "indicator_gait_sensitivity"),
  audit_cont(df_scored$indicator_chair_capacity) %>% mutate(var = "indicator_chair_capacity"),
  audit_cont(df_scored$indicator_balance_capacity) %>% mutate(var = "indicator_balance_capacity")
) %>% select(var, everything())
cont_path <- file.path(outputs_dir, "k31_audit_continuous.csv")
write_csv_safely(cont_audit, cont_path)
append_manifest_safe(label = "k31_audit_continuous", kind = "table_csv", path = cont_path, n = nrow(df_scored))

self_tbl <- audit_cat(df_scored$indicator_self_report_raw)
self_path <- file.path(outputs_dir, "k31_audit_self_report_freq.csv")
write_csv_safely(self_tbl, self_path)
append_manifest_safe(label = "k31_audit_self_report_freq", kind = "table_csv", path = self_path, n = nrow(df_scored))

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
cor_path <- file.path(outputs_dir, "k31_audit_correlations.csv")
write_csv_safely(cor_tbl, cor_path)
append_manifest_safe(label = "k31_audit_correlations", kind = "table_csv", path = cor_path, n = nrow(df_scored))

flags <- tibble(
  flag_walkspeed_zero = mean(df_scored$indicator_gait_raw == 0, na.rm = TRUE),
  flag_grip_very_high = mean(df_scored$indicator_grip > GRIP_VERY_HIGH_KG, na.rm = TRUE),
  flag_chair_nonpositive_raw = mean(df_scored$indicator_chair_raw <= 0, na.rm = TRUE),
  grip_very_high_threshold = GRIP_VERY_HIGH_KG
)
flags_path <- file.path(outputs_dir, "k31_red_flags.csv")
write_csv_safely(flags, flags_path)
append_manifest_safe(label = "k31_red_flags", kind = "table_csv", path = flags_path, n = nrow(df_scored))

decision_lines <- c(
  "K31 decisions (secondary latent model)",
  paste0("Input source: ", input_info$path),
  "Indicator defaults:",
  paste0("- grip: ", map[["grip"]]),
  paste0("- gait: ", map[["gait"]], " (primary 0->NA; sensitivity retains 0)"),
  paste0("- chair: ", map[["chair"]], " transformed to capacity as -chair_time"),
  paste0("- balance: ", ifelse(!is.na(map[["balance"]]), map[["balance"]], paste0(map[["balance_right"]], "+", map[["balance_left"]], " mean"))),
  paste0("- self-report (optional max 1): ", ifelse(!is.na(map[["self_report"]]), map[["self_report"]], "not available")),
  "Self-report recode (deterministic): 0=no difficulty -> best (2), 1=difficulty -> 1, 2=cannot -> worst (0).",
  paste0("Admissibility threshold score_na_share <= ", SCORE_NA_SHARE_MAX)
)
dec_path <- file.path(outputs_dir, "k31_decision_log.txt")
write_lines_safely(decision_lines, dec_path)
append_manifest_safe(label = "k31_decision_log", kind = "text", path = dec_path, n = nrow(df_scored))

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

save_lavaan_outputs(cfa_primary$fit, "k31_cfa_primary")
save_lavaan_outputs(cfa_sens$fit, "k31_cfa_sensitivity")

cfa_diag <- bind_rows(
  cfa_primary$diagnostics %>% mutate(model = "primary_zero_to_na", ordered_self_report = self_present),
  cfa_sens$diagnostics %>% mutate(model = "sensitivity_zero_retained", ordered_self_report = self_present)
) %>% select(model, ordered_self_report, everything())
cfa_diag_path <- file.path(outputs_dir, "k31_cfa_diagnostics.csv")
write_csv_safely(cfa_diag, cfa_diag_path)
append_manifest_safe(label = "k31_cfa_diagnostics", kind = "table_csv", path = cfa_diag_path, n = nrow(df_scored))

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
  ),
  p01 = c(
    as.numeric(quantile(df_scored$capacity_score_latent_primary, 0.01, na.rm = TRUE)),
    as.numeric(quantile(df_scored$capacity_score_latent_sensitivity, 0.01, na.rm = TRUE)),
    as.numeric(quantile(df_scored$capacity_score_z4_primary, 0.01, na.rm = TRUE)),
    as.numeric(quantile(df_scored$capacity_score_z4_sensitivity, 0.01, na.rm = TRUE)),
    as.numeric(quantile(df_scored$capacity_score_z5_primary, 0.01, na.rm = TRUE)),
    as.numeric(quantile(df_scored$capacity_score_z5_sensitivity, 0.01, na.rm = TRUE))
  ),
  p99 = c(
    as.numeric(quantile(df_scored$capacity_score_latent_primary, 0.99, na.rm = TRUE)),
    as.numeric(quantile(df_scored$capacity_score_latent_sensitivity, 0.99, na.rm = TRUE)),
    as.numeric(quantile(df_scored$capacity_score_z4_primary, 0.99, na.rm = TRUE)),
    as.numeric(quantile(df_scored$capacity_score_z4_sensitivity, 0.99, na.rm = TRUE)),
    as.numeric(quantile(df_scored$capacity_score_z5_primary, 0.99, na.rm = TRUE)),
    as.numeric(quantile(df_scored$capacity_score_z5_sensitivity, 0.99, na.rm = TRUE))
  )
)

scores_path <- file.path(outputs_dir, "k31_scores_summary.csv")
write_csv_safely(score_summ, scores_path)
append_manifest_safe(label = "k31_scores_summary", kind = "table_csv", path = scores_path, n = nrow(df_scored))

# --- 7) Save dataset + reproducibility ----------------------------------------
data_root <- resolve_data_root()
external_dir <- file.path(data_root, "paper_01", "capacity_scores")
dir_create(external_dir)

out_csv <- file.path(external_dir, "kaatumisenpelko_with_capacity_scores_k31.csv")
out_rds <- file.path(external_dir, "kaatumisenpelko_with_capacity_scores_k31.rds")

write_csv_safely(df_scored, out_csv)
write_rds_safely(df_scored, out_rds)

csv_md5 <- unname(tools::md5sum(out_csv)[1])
rds_md5 <- unname(tools::md5sum(out_rds)[1])
receipt_path <- file.path(outputs_dir, "k31_patient_level_output_receipt.txt")
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
  label = "k31_patient_level_output_receipt",
  kind = "text",
  path = receipt_path,
  n = nrow(df_scored),
  notes = "Patient-level CSV/RDS written to DATA_ROOT external path."
)

sess_path <- file.path(outputs_dir, "k31_sessioninfo.txt")
write_lines_safely(capture.output(sessionInfo()), sess_path)
append_manifest_safe(label = "k31_sessioninfo", kind = "text", path = sess_path)

message("K31 complete. Outputs written to: ", outputs_dir)
