#!/usr/bin/env Rscript
# ==============================================================================
# 32_CFA_3ITEM - Core 3-item locomotor capacity CFA from KAAOS raw Excel
# File tag: 32_cfa_3item.r
# Purpose:
#   Build a deterministic gait + chair + balance locomotor capacity model from
#   DATA_ROOT/paper_02/KAAOS_data_sotullinen.xlsx, with z3 fallback and explicit
#   fail-closed mapping audit.
#
# Required vars (resolved from raw Excel headers; fail closed on ambiguity):
# - gait: TK 10 metrin kayvelynopeus (sek) -> converted to m/s as 10 / seconds
# - chair: TK Tuolilta nousu 5 krt (sek) -> capacity direction via -time
# - balance: direct Seisominen0 OR fallback mean(right, left) single-leg stance
#
# Outputs (repo-local aggregate/QC):
# - R/32_cfa/outputs/<run_id>/*
# - manifest/manifest.csv (one row per artifact)
#
# Patient-level outputs (local-only; never in repo):
# - DATA_ROOT/paper_02/capacity_scores/kaaos_with_capacity_scores_32_cfa_3item.(csv|rds)
# ==============================================================================

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(tibble)
})

args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)
script_path <- if (length(file_arg) > 0) sub("^--file=", "", file_arg[[1]]) else ""

subproject_root <- if (nzchar(script_path)) {
  normalizePath(file.path(dirname(script_path), "..", ".."), winslash = "/", mustWork = FALSE)
} else {
  wd <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  if (file.exists(file.path(wd, "R", "32_cfa", "32_cfa_3item.r"))) {
    wd
  } else if (file.exists(file.path(wd, "Quantify-FOF-Utilization-Costs", "R", "32_cfa", "32_cfa_3item.r"))) {
    file.path(wd, "Quantify-FOF-Utilization-Costs")
  } else {
    wd
  }
}
setwd(subproject_root)

script_label <- "32_CFA_3ITEM"
run_id <- format(Sys.time(), "%Y%m%d_%H%M%S")
outputs_dir <- file.path(subproject_root, "R", "32_cfa", "outputs", run_id)
manifest_path <- file.path(subproject_root, "manifest", "manifest.csv")
dir.create(outputs_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(manifest_path), recursive = TRUE, showWarnings = FALSE)

BALANCE_MAX_SECONDS <- 300

clean_names_simple <- function(x) {
  x <- iconv(x, from = "UTF-8", to = "ASCII//TRANSLIT")
  x[is.na(x)] <- ""
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", "_", x)
  x <- gsub("_+", "_", x)
  x <- gsub("^_|_$", "", x)
  make.unique(x, sep = "_")
}

append_manifest_row <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  row <- data.frame(
    artifact = NA_character_,
    description = NA_character_,
    creator = NA_character_,
    date = NA_character_,
    hash = NA_character_,
    timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    script = script_label,
    label = label,
    kind = kind,
    path = sub(paste0("^", normalizePath(subproject_root, winslash = "/", mustWork = FALSE), "/"), "", normalizePath(path, winslash = "/", mustWork = FALSE)),
    n = if (is.na(n)) NA_character_ else as.character(n),
    notes = if (is.na(notes)) "" else notes,
    stringsAsFactors = FALSE
  )
  utils::write.table(
    row,
    file = manifest_path,
    append = file.exists(manifest_path),
    sep = ",",
    row.names = FALSE,
    col.names = !file.exists(manifest_path),
    quote = TRUE,
    na = ""
  )
  invisible(TRUE)
}

write_csv_safely <- function(df, path, label, notes = NA_character_) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(df, path, row.names = FALSE, na = "")
  append_manifest_row(label = label, kind = "table_csv", path = path, n = nrow(df), notes = notes)
  invisible(path)
}

write_txt_safely <- function(lines, path, label, notes = NA_character_) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, con = path, useBytes = TRUE)
  append_manifest_row(label = label, kind = "text", path = path, n = length(lines), notes = notes)
  invisible(path)
}

write_rds_local <- function(obj, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  saveRDS(obj, path)
  invisible(path)
}

resolve_data_root <- function(root) {
  from_env <- Sys.getenv("DATA_ROOT", "")
  if (nzchar(from_env)) return(from_env)

  env_path <- file.path(root, "config", ".env")
  if (file.exists(env_path)) {
    env_lines <- readLines(env_path, warn = FALSE)
    hit <- grep("^export DATA_ROOT=|^DATA_ROOT=", env_lines, value = TRUE)
    if (length(hit) > 0) {
      value <- sub("^export DATA_ROOT=", "", hit[[1]])
      value <- sub("^DATA_ROOT=", "", value)
      value <- gsub('^"|"$', "", value)
      value <- gsub("^'|'$", "", value)
      if (nzchar(value)) return(value)
    }
  }

  stop("DATA_ROOT is required but missing.", call. = FALSE)
}

safe_num <- function(x) suppressWarnings(as.numeric(as.character(x)))

safe_cor <- function(x, y, method = "pearson") {
  ok <- complete.cases(x, y)
  if (sum(ok) < 3) return(NA_real_)
  suppressWarnings(cor(x[ok], y[ok], method = method))
}

na_row_mean <- function(mat) {
  out <- rowMeans(mat, na.rm = TRUE)
  out[rowSums(!is.na(mat)) == 0] <- NA_real_
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
    min = suppressWarnings(min(x, na.rm = TRUE)),
    max = suppressWarnings(max(x, na.rm = TRUE))
  )
}

pick_one_pattern <- function(df_names, target, patterns, required = TRUE) {
  hits <- integer(0)
  for (pat in patterns) {
    m <- grep(pat, df_names, ignore.case = TRUE)
    if (length(m) > 0) hits <- unique(c(hits, m))
  }
  if (length(hits) == 1) return(df_names[hits[[1]]])
  if (length(hits) == 0 && !required) return(NA_character_)
  if (length(hits) == 0) {
    stop(paste0("Missing required raw mapping for ", target, "."), call. = FALSE)
  }
  stop(paste0("Ambiguous raw mapping for ", target, ": ", paste(df_names[hits], collapse = ", ")), call. = FALSE)
}

build_mapping <- function(df_names) {
  mapped <- c(
    id = pick_one_pattern(df_names, "id", c("^nro$"), required = FALSE),
    fof = pick_one_pattern(df_names, "fof", c("^kaatumisen_pelko_0_"), required = FALSE),
    gait_time = pick_one_pattern(df_names, "gait_time", c("^tk_10.*k.*velynopeus.*sek"), required = TRUE),
    chair_time = pick_one_pattern(df_names, "chair_time", c("^tk_tuolilta_nousu_5_krt_sek"), required = TRUE),
    balance_direct = pick_one_pattern(df_names, "balance_direct", c("^seisominen0$"), required = FALSE),
    balance_right = pick_one_pattern(df_names, "balance_right", c("^tk_yhdell.*jalalla_seisominen_oikea.*sek"), required = FALSE),
    balance_left = pick_one_pattern(df_names, "balance_left", c("^tk_yhdell.*jalalla_seisominen_vasen.*sek"), required = FALSE)
  )

  balance_ok <- !is.na(mapped[["balance_direct"]]) || (!is.na(mapped[["balance_right"]]) && !is.na(mapped[["balance_left"]]))

  list(
    mapped = mapped,
    required_ok = !is.na(mapped[["gait_time"]]) && !is.na(mapped[["chair_time"]]) && balance_ok,
    balance_source = if (!is.na(mapped[["balance_direct"]])) "direct" else if (balance_ok) "mean_right_left" else "missing"
  )
}

inspect_excel_layouts <- function(path) {
  sheets <- readxl::excel_sheets(path)
  out <- list()
  idx <- 1L
  for (sheet_name in sheets) {
    for (skip_n in c(0, 1)) {
      probe <- tryCatch(
        readxl::read_excel(path, sheet = sheet_name, skip = skip_n, n_max = 0, .name_repair = "minimal"),
        error = function(e) e
      )
      if (inherits(probe, "error")) {
        out[[idx]] <- data.frame(
          sheet = sheet_name,
          skip = skip_n,
          matched_required = NA_integer_,
          balance_source = "read_error",
          required_ok = FALSE,
          error = conditionMessage(probe),
          stringsAsFactors = FALSE
        )
      } else {
        clean_names <- clean_names_simple(names(probe))
        map_res <- tryCatch(build_mapping(clean_names), error = function(e) e)
        if (inherits(map_res, "error")) {
          out[[idx]] <- data.frame(
            sheet = sheet_name,
            skip = skip_n,
            matched_required = NA_integer_,
            balance_source = "mapping_error",
            required_ok = FALSE,
            error = conditionMessage(map_res),
            stringsAsFactors = FALSE
          )
        } else {
          matched_required <- sum(!is.na(map_res$mapped[c("gait_time", "chair_time")])) + ifelse(map_res$required_ok, 1L, 0L)
          out[[idx]] <- data.frame(
            sheet = sheet_name,
            skip = skip_n,
            matched_required = matched_required,
            balance_source = map_res$balance_source,
            required_ok = map_res$required_ok,
            error = "",
            stringsAsFactors = FALSE
          )
        }
      }
      idx <- idx + 1L
    }
  }
  dplyr::bind_rows(out)
}

fit_capacity_cfa <- function(df_model) {
  if (!requireNamespace("lavaan", quietly = TRUE)) {
    return(list(
      fit = NULL,
      score = rep(NA_real_, nrow(df_model)),
      diagnostics = tibble(
        converged_ok = FALSE,
        has_neg_resid_var = NA,
        has_std_loading_gt1 = NA,
        score_na_share = 1,
        loading_signs_ok = NA,
        orientation_flip_applied = NA,
        gait_loading_std_all = NA_real_,
        factor_determinacy = NA_real_,
        cfi = NA_real_,
        tli = NA_real_,
        rmsea = NA_real_,
        srmr = NA_real_,
        chisq = NA_real_,
        df = NA_real_,
        pvalue = NA_real_,
        expected_sign_map = "gait:+;chair:+;balance:+",
        admissible = FALSE,
        reason = "lavaan_missing",
        warning_count = NA_integer_,
        warnings = "Package 'lavaan' not installed"
      )
    ))
  }

  keep <- complete.cases(df_model)
  df_fit <- df_model[keep, , drop = FALSE]
  score_full <- rep(NA_real_, nrow(df_model))

  if (nrow(df_fit) < 10) {
    return(list(
      fit = NULL,
      score = score_full,
      diagnostics = tibble(
        converged_ok = FALSE,
        has_neg_resid_var = NA,
        has_std_loading_gt1 = NA,
        score_na_share = 1,
        loading_signs_ok = NA,
        orientation_flip_applied = NA,
        gait_loading_std_all = NA_real_,
        factor_determinacy = NA_real_,
        cfi = NA_real_,
        tli = NA_real_,
        rmsea = NA_real_,
        srmr = NA_real_,
        chisq = NA_real_,
        df = NA_real_,
        pvalue = NA_real_,
        expected_sign_map = "gait:+;chair:+;balance:+",
        admissible = FALSE,
        reason = "insufficient_complete_cases",
        warning_count = NA_integer_,
        warnings = "Fewer than 10 complete cases for 3-item CFA"
      )
    ))
  }

  model_cfa <- "Capacity =~ gait + chair + balance"
  cfa_warn <- character(0)
  fit <- withCallingHandlers(
    tryCatch(
      lavaan::cfa(
        model = model_cfa,
        data = df_fit,
        estimator = "MLR",
        missing = "listwise"
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
      score = score_full,
      diagnostics = tibble(
        converged_ok = FALSE,
        has_neg_resid_var = NA,
        has_std_loading_gt1 = NA,
        score_na_share = 1,
        loading_signs_ok = NA,
        orientation_flip_applied = NA,
        gait_loading_std_all = NA_real_,
        factor_determinacy = NA_real_,
        cfi = NA_real_,
        tli = NA_real_,
        rmsea = NA_real_,
        srmr = NA_real_,
        chisq = NA_real_,
        df = NA_real_,
        pvalue = NA_real_,
        expected_sign_map = "gait:+;chair:+;balance:+",
        admissible = FALSE,
        reason = paste0("cfa_error: ", conditionMessage(fit)),
        warning_count = length(unique(cfa_warn)),
        warnings = paste(unique(cfa_warn), collapse = " | ")
      )
    ))
  }

  pe <- lavaan::parameterEstimates(fit, standardized = TRUE)
  loadings <- pe[pe$op == "=~", , drop = FALSE]
  resid_vars <- pe[pe$op == "~~" & pe$lhs %in% c("gait", "chair", "balance") & pe$lhs == pe$rhs, , drop = FALSE]
  score_fit <- tryCatch(as.numeric(lavaan::lavPredict(fit, method = "EBM")[, 1]), error = function(e) rep(NA_real_, nrow(df_fit)))

  expected <- c(gait = 1, chair = 1, balance = 1)
  signs <- setNames(sign(loadings$std.all), loadings$rhs)
  gait_loading <- if ("gait" %in% names(signs)) loadings$std.all[loadings$rhs == "gait"][1] else NA_real_
  positive_expected <- names(expected)[expected == 1]
  majority_positive_negative <- sum(loadings$std.all[loadings$rhs %in% positive_expected] < 0, na.rm = TRUE) >
    (sum(loadings$rhs %in% positive_expected) / 2)
  orientation_flip_applied <- (!is.na(gait_loading) && gait_loading < 0) || majority_positive_negative
  if (isTRUE(orientation_flip_applied)) score_fit <- -1 * score_fit

  score_full[keep] <- score_fit

  oriented_signs <- if (isTRUE(orientation_flip_applied)) -1 * signs else signs
  comparable <- names(expected)[names(expected) %in% names(oriented_signs)]
  loading_signs_ok <- length(comparable) > 0 && all(oriented_signs[comparable] == expected[comparable], na.rm = TRUE)
  has_neg_resid_var <- any(resid_vars$est < 0, na.rm = TRUE)
  has_std_loading_gt1 <- any(abs(loadings$std.all) > 1, na.rm = TRUE)
  score_na_share <- mean(is.na(score_full))
  converged_ok <- isTRUE(lavaan::lavInspect(fit, "converged"))
  factor_determinacy <- tryCatch({
    det <- lavaan::lavInspect(fit, "fs.determinacy")
    as.numeric(det[[1]])
  }, error = function(e) {
    tryCatch({
      rel <- lavaan::lavInspect(fit, "fs.reliability")
      as.numeric(rel[[1]])
    }, error = function(e2) NA_real_)
  })
  fit_measures <- tryCatch(
    lavaan::fitMeasures(fit, c("cfi", "tli", "rmsea", "srmr", "chisq", "df", "pvalue")),
    error = function(e) c(cfi = NA_real_, tli = NA_real_, rmsea = NA_real_, srmr = NA_real_, chisq = NA_real_, df = NA_real_, pvalue = NA_real_)
  )
  admissible <- converged_ok && !has_neg_resid_var && !has_std_loading_gt1 && isTRUE(loading_signs_ok)
  if (!admissible) score_full[] <- NA_real_

  reasons <- character(0)
  if (!converged_ok) reasons <- c(reasons, "not_converged")
  if (has_neg_resid_var) reasons <- c(reasons, "neg_resid_var")
  if (has_std_loading_gt1) reasons <- c(reasons, "std_loading_gt1")
  if (!isTRUE(loading_signs_ok)) reasons <- c(reasons, "loading_sign_mismatch")
  if (length(reasons) == 0) reasons <- "admissible"

  list(
    fit = fit,
    score = score_full,
    diagnostics = tibble(
      converged_ok = converged_ok,
      has_neg_resid_var = has_neg_resid_var,
      has_std_loading_gt1 = has_std_loading_gt1,
      score_na_share = score_na_share,
      loading_signs_ok = loading_signs_ok,
      orientation_flip_applied = orientation_flip_applied,
      gait_loading_std_all = gait_loading,
      factor_determinacy = factor_determinacy,
      cfi = unname(fit_measures["cfi"]),
      tli = unname(fit_measures["tli"]),
      rmsea = unname(fit_measures["rmsea"]),
      srmr = unname(fit_measures["srmr"]),
      chisq = unname(fit_measures["chisq"]),
      df = unname(fit_measures["df"]),
      pvalue = unname(fit_measures["pvalue"]),
      expected_sign_map = "gait:+;chair:+;balance:+",
      admissible = admissible,
      reason = paste(reasons, collapse = ";"),
      warning_count = length(unique(cfa_warn)),
      warnings = paste(unique(cfa_warn), collapse = " | ")
    )
  )
}

save_lavaan_outputs <- function(fit, prefix) {
  sum_path <- file.path(outputs_dir, paste0(prefix, "_summary.txt"))
  load_path <- file.path(outputs_dir, paste0(prefix, "_loadings.csv"))
  if (is.null(fit)) {
    write_txt_safely(c(paste0(prefix, ": no lavaan fit object")), sum_path, label = paste0(prefix, "_summary"))
    write_csv_safely(data.frame(), load_path, label = paste0(prefix, "_loadings"))
    return(invisible(NULL))
  }

  write_txt_safely(c(capture.output(summary(fit, standardized = TRUE, fit.measures = TRUE))), sum_path, label = paste0(prefix, "_summary"))
  pe <- lavaan::parameterEstimates(fit, standardized = TRUE)
  pe <- pe[pe$op == "=~", c("lhs", "op", "rhs", "est", "se", "z", "pvalue", "std.all"), drop = FALSE]
  write_csv_safely(pe, load_path, label = paste0(prefix, "_loadings"))
  invisible(NULL)
}

data_root <- resolve_data_root(subproject_root)
raw_path <- file.path(data_root, "paper_02", "KAAOS_data_sotullinen.xlsx")
if (!file.exists(raw_path)) {
  stop("Raw Excel missing: DATA_ROOT/paper_02/KAAOS_data_sotullinen.xlsx", call. = FALSE)
}

layout_tbl <- inspect_excel_layouts(raw_path)
layout_path <- file.path(outputs_dir, "32_cfa_3item_excel_layout_candidates.csv")
write_csv_safely(layout_tbl, layout_path, label = "32_cfa_3item_excel_layout_candidates", notes = "Sheet/skip audit for raw workbook")

valid_layouts <- layout_tbl %>% filter(required_ok)
if (nrow(valid_layouts) != 1) {
  stop(
    paste0(
      "Raw Excel sheet/skip resolution failed. Expected exactly one valid gait/chair/balance layout, found ",
      nrow(valid_layouts), ". See outputs audit."
    ),
    call. = FALSE
  )
}

selected_sheet <- valid_layouts$sheet[[1]]
selected_skip <- valid_layouts$skip[[1]]
df_raw <- readxl::read_excel(raw_path, sheet = selected_sheet, skip = selected_skip, .name_repair = "minimal")
raw_names <- names(df_raw)
clean_names <- clean_names_simple(raw_names)
names(df_raw) <- clean_names

map_res <- build_mapping(clean_names)
map <- map_res$mapped
mapping_tbl <- tibble(
  target = names(map),
  source_clean = unname(map),
  source_raw = vapply(unname(map), function(x) if (is.na(x)) NA_character_ else raw_names[match(x, clean_names)], character(1))
)
mapping_path <- file.path(outputs_dir, "32_cfa_3item_mapping.csv")
write_csv_safely(mapping_tbl, mapping_path, label = "32_cfa_3item_mapping", notes = "Deterministic raw-to-analysis mapping")

if (!isTRUE(map_res$required_ok)) {
  stop("3-item raw mapping is incomplete. See mapping audit.", call. = FALSE)
}

balance_raw <- if (!is.na(map[["balance_direct"]])) {
  safe_num(df_raw[[map[["balance_direct"]]]])
} else {
  br <- safe_num(df_raw[[map[["balance_right"]]]])
  bl <- safe_num(df_raw[[map[["balance_left"]]]])
  br[br > BALANCE_MAX_SECONDS] <- NA_real_
  bl[bl > BALANCE_MAX_SECONDS] <- NA_real_
  bal <- rowMeans(cbind(br, bl), na.rm = TRUE)
  bal[!is.finite(bal)] <- NA_real_
  bal
}

gait_time_sec <- safe_num(df_raw[[map[["gait_time"]]]])
gait_speed_mps <- ifelse(is.na(gait_time_sec), NA_real_, ifelse(gait_time_sec > 0, 10 / gait_time_sec, 0))
chair_time_sec <- safe_num(df_raw[[map[["chair_time"]]]])

df_scored <- tibble(
  id = if (!is.na(map[["id"]])) as.character(df_raw[[map[["id"]]]]) else as.character(seq_len(nrow(df_raw))),
  fof_raw = if (!is.na(map[["fof"]])) safe_num(df_raw[[map[["fof"]]]]) else NA_real_,
  indicator_gait_time_sec = gait_time_sec,
  indicator_gait_primary = ifelse(gait_speed_mps == 0, NA_real_, gait_speed_mps),
  indicator_gait_sensitivity = gait_speed_mps,
  indicator_chair_raw = chair_time_sec,
  indicator_chair_capacity = ifelse(is.na(chair_time_sec), NA_real_, -1 * chair_time_sec),
  indicator_balance_capacity = balance_raw
)

cont_tbl <- bind_rows(
  audit_cont(df_scored$indicator_gait_primary) %>% mutate(var = "indicator_gait_primary"),
  audit_cont(df_scored$indicator_gait_sensitivity) %>% mutate(var = "indicator_gait_sensitivity"),
  audit_cont(df_scored$indicator_chair_capacity) %>% mutate(var = "indicator_chair_capacity"),
  audit_cont(df_scored$indicator_balance_capacity) %>% mutate(var = "indicator_balance_capacity")
) %>% select(var, everything())
write_csv_safely(cont_tbl, file.path(outputs_dir, "32_cfa_3item_audit_continuous.csv"), label = "32_cfa_3item_audit_continuous")

cor_tbl <- data.frame(
  metric = c("gait_vs_chair", "gait_vs_balance", "chair_vs_balance"),
  r = c(
    safe_cor(df_scored$indicator_gait_primary, df_scored$indicator_chair_capacity),
    safe_cor(df_scored$indicator_gait_primary, df_scored$indicator_balance_capacity),
    safe_cor(df_scored$indicator_chair_capacity, df_scored$indicator_balance_capacity)
  ),
  stringsAsFactors = FALSE
)
write_csv_safely(cor_tbl, file.path(outputs_dir, "32_cfa_3item_audit_correlations.csv"), label = "32_cfa_3item_audit_correlations")

flags_tbl <- tibble(
  flag_walkspeed_zero = mean(df_scored$indicator_gait_sensitivity == 0, na.rm = TRUE),
  flag_chair_nonpositive_raw = mean(df_scored$indicator_chair_raw <= 0, na.rm = TRUE),
  flag_balance_implausibly_high_raw = if (map_res$balance_source == "direct") {
    mean(safe_num(df_raw[[map[["balance_direct"]]]]) > BALANCE_MAX_SECONDS, na.rm = TRUE)
  } else {
    mean(
      safe_num(df_raw[[map[["balance_right"]]]]) > BALANCE_MAX_SECONDS |
        safe_num(df_raw[[map[["balance_left"]]]]) > BALANCE_MAX_SECONDS,
      na.rm = TRUE
    )
  }
)
write_csv_safely(flags_tbl, file.path(outputs_dir, "32_cfa_3item_red_flags.csv"), label = "32_cfa_3item_red_flags")

primary_complete <- complete.cases(df_scored$indicator_gait_primary, df_scored$indicator_chair_capacity, df_scored$indicator_balance_capacity)
sensitivity_complete <- complete.cases(df_scored$indicator_gait_sensitivity, df_scored$indicator_chair_capacity, df_scored$indicator_balance_capacity)

decision_lines <- c(
  "32_cfa_3item decisions",
  paste0("raw_source=DATA_ROOT/paper_02/KAAOS_data_sotullinen.xlsx"),
  paste0("selected_sheet=", selected_sheet),
  paste0("selected_skip=", selected_skip),
  paste0("rows_loaded=", nrow(df_scored)),
  paste0("rows_primary_complete=", sum(primary_complete)),
  paste0("rows_sensitivity_complete=", sum(sensitivity_complete)),
  paste0("mapping_gait_raw=", mapping_tbl$source_raw[mapping_tbl$target == "gait_time"]),
  "gait_derivation=10 / timed_seconds (inference from raw 10m test header and legacy kavelynopeus_m_sek0 naming)",
  paste0("mapping_chair_raw=", mapping_tbl$source_raw[mapping_tbl$target == "chair_time"]),
  paste0("mapping_balance_mode=", map_res$balance_source),
  paste0(
    "mapping_balance_raw=",
    if (map_res$balance_source == "direct") {
      mapping_tbl$source_raw[mapping_tbl$target == "balance_direct"]
    } else {
      paste(
        mapping_tbl$source_raw[mapping_tbl$target == "balance_right"],
        mapping_tbl$source_raw[mapping_tbl$target == "balance_left"],
        sep = " + "
      )
    }
  ),
  "balance_derivation=mean(right,left) when direct Seisominen0 is unavailable (aligned with legacy K31 fallback)",
  paste0("balance_implausible_high_rule=values>", BALANCE_MAX_SECONDS, " sec -> NA before balance aggregation"),
  "primary_factor=gait + chair + balance",
  "expected_loading_signs=gait:+;chair_capacity:+;balance:+"
)
write_txt_safely(decision_lines, file.path(outputs_dir, "32_cfa_3item_decision_log.txt"), label = "32_cfa_3item_decision_log")

z3_primary <- cbind(
  z_gait = as.numeric(scale(df_scored$indicator_gait_primary)),
  z_chair = as.numeric(scale(df_scored$indicator_chair_capacity)),
  z_balance = as.numeric(scale(df_scored$indicator_balance_capacity))
)
z3_sens <- cbind(
  z_gait = as.numeric(scale(df_scored$indicator_gait_sensitivity)),
  z_chair = as.numeric(scale(df_scored$indicator_chair_capacity)),
  z_balance = as.numeric(scale(df_scored$indicator_balance_capacity))
)

df_scored$capacity_score_z3_primary <- na_row_mean(z3_primary)
df_scored$capacity_score_z3_sensitivity <- na_row_mean(z3_sens)

cfa_primary <- fit_capacity_cfa(
  tibble(
    gait = df_scored$indicator_gait_primary,
    chair = df_scored$indicator_chair_capacity,
    balance = df_scored$indicator_balance_capacity
  )
)
cfa_sens <- fit_capacity_cfa(
  tibble(
    gait = df_scored$indicator_gait_sensitivity,
    chair = df_scored$indicator_chair_capacity,
    balance = df_scored$indicator_balance_capacity
  )
)

df_scored$capacity_score_latent_primary <- cfa_primary$score
df_scored$capacity_score_latent_sensitivity <- cfa_sens$score

cfa_diag <- bind_rows(
  cfa_primary$diagnostics %>% mutate(model = "primary_zero_to_na"),
  cfa_sens$diagnostics %>% mutate(model = "sensitivity_zero_retained")
) %>% select(model, everything())
write_csv_safely(cfa_diag, file.path(outputs_dir, "32_cfa_3item_cfa_diagnostics.csv"), label = "32_cfa_3item_cfa_diagnostics")

score_summary <- tibble(
  score = c("capacity_score_latent_primary", "capacity_score_latent_sensitivity", "capacity_score_z3_primary", "capacity_score_z3_sensitivity"),
  n = c(
    sum(!is.na(df_scored$capacity_score_latent_primary)),
    sum(!is.na(df_scored$capacity_score_latent_sensitivity)),
    sum(!is.na(df_scored$capacity_score_z3_primary)),
    sum(!is.na(df_scored$capacity_score_z3_sensitivity))
  ),
  mean = c(
    mean(df_scored$capacity_score_latent_primary, na.rm = TRUE),
    mean(df_scored$capacity_score_latent_sensitivity, na.rm = TRUE),
    mean(df_scored$capacity_score_z3_primary, na.rm = TRUE),
    mean(df_scored$capacity_score_z3_sensitivity, na.rm = TRUE)
  ),
  sd = c(
    sd(df_scored$capacity_score_latent_primary, na.rm = TRUE),
    sd(df_scored$capacity_score_latent_sensitivity, na.rm = TRUE),
    sd(df_scored$capacity_score_z3_primary, na.rm = TRUE),
    sd(df_scored$capacity_score_z3_sensitivity, na.rm = TRUE)
  )
)
write_csv_safely(score_summary, file.path(outputs_dir, "32_cfa_3item_scores_summary.csv"), label = "32_cfa_3item_scores_summary")

save_lavaan_outputs(cfa_primary$fit, "32_cfa_3item_cfa_primary")
save_lavaan_outputs(cfa_sens$fit, "32_cfa_3item_cfa_sensitivity")

if (!requireNamespace("lavaan", quietly = TRUE)) {
  write_txt_safely(
    c(
      "32_cfa_3item stopped after read/audit/z3 stage.",
      "Reason: package 'lavaan' is not installed in this project environment."
    ),
    file.path(outputs_dir, "32_cfa_3item_blocked.txt"),
    label = "32_cfa_3item_blocked"
  )
  stop("Package 'lavaan' missing. Read/audit stage completed; CFA stage blocked.", call. = FALSE)
}

external_dir <- file.path(data_root, "paper_02", "capacity_scores")
dir.create(external_dir, recursive = TRUE, showWarnings = FALSE)
out_csv <- file.path(external_dir, "kaaos_with_capacity_scores_32_cfa_3item.csv")
out_rds <- file.path(external_dir, "kaaos_with_capacity_scores_32_cfa_3item.rds")
utils::write.csv(df_scored, out_csv, row.names = FALSE, na = "")
write_rds_local(df_scored, out_rds)

receipt_lines <- c(
  paste0("script=", script_label),
  paste0("timestamp_utc=", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste0("raw_source_rel=paper_02/KAAOS_data_sotullinen.xlsx"),
  paste0("selected_sheet=", selected_sheet),
  paste0("selected_skip=", selected_skip),
  paste0("rows_loaded=", nrow(df_scored)),
  paste0("rows_primary_complete=", sum(primary_complete)),
  paste0("rows_sensitivity_complete=", sum(sensitivity_complete)),
  paste0("external_csv=", out_csv),
  paste0("external_rds=", out_rds)
)
write_txt_safely(receipt_lines, file.path(outputs_dir, "32_cfa_3item_patient_level_output_receipt.txt"), label = "32_cfa_3item_patient_level_output_receipt")

write_txt_safely(capture.output(sessionInfo()), file.path(outputs_dir, "32_cfa_3item_sessioninfo.txt"), label = "32_cfa_3item_sessioninfo")

message("32_cfa_3item complete. Outputs written to: ", outputs_dir)
