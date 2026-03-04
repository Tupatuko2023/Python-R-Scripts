#!/usr/bin/env Rscript
# ==============================================================================
# K39 - Frailty/Vulnerability latent builder (non-performance indicators only)
# File tag: k39.r
# Purpose: Build one continuous frailty/vulnerability score using deterministic
#          Phase A -> Phase B selection (deficit latent vs phenotype latent vs
#          z-composite fallback), with governance-safe externalized row-level
#          outputs under DATA_ROOT.
#
# Required vars (external input, resolved from DATA_ROOT):
# id
# Optional but expected for overlap diagnostics: Composite_Z_baseline or equivalent
# Optional but expected for richer indicator set: K15 frailty external dataset
#
# Outputs + manifest:
# - Repo outputs (aggregate only):
#   k39_column_inventory.csv
#   k39_candidate_inventory.csv
#   k39_excluded_vars.csv
#   k39_candidate_vs_compositez_cor.csv
#   k39_red_flags.csv
#   k39_selected_indicators.csv
#   k39_cfa_admissibility.csv
#   k39_decision_log.txt
#   k39_external_output_receipt.txt
#   sessioninfo_K39.txt
# - External patient-level outputs ONLY:
#   ${DATA_ROOT}/paper_01/frailty_vulnerability/frailty_vulnerability_scores.csv
#   ${DATA_ROOT}/paper_01/frailty_vulnerability/frailty_vulnerability_scores.rds
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(here)
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

script_label <- "K39"
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

md5_file <- function(path) {
  unname(tools::md5sum(path))
}

clean_names_simple <- function(x) {
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", "_", x)
  x <- gsub("_+", "_", x)
  x <- gsub("^_|_$", "", x)
  x
}

load_tabular <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "rds") {
    obj <- readRDS(path)
    if (!is.data.frame(obj)) stop("RDS is not a data.frame: ", path, call. = FALSE)
    return(as_tibble(obj))
  }
  if (ext == "csv") {
    return(readr::read_csv(path, show_col_types = FALSE))
  }
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

  stop(
    "DATA_ROOT is required but missing. Set environment variable DATA_ROOT ",
    "or config/.env entry DATA_ROOT=/abs/path before running K39.",
    call. = FALSE
  )
}

pick_first_existing <- function(paths_vec) {
  hits <- paths_vec[file.exists(paths_vec)]
  if (length(hits) == 0) return(NA_character_)
  hits[[1]]
}

resolve_inputs <- function(data_root) {
  analysis_dir <- file.path(data_root, "paper_01", "analysis")
  frailty_dir <- file.path(data_root, "paper_01", "frailty")

  wide_candidates <- file.path(analysis_dir, c(
    "fof_analysis_k33_wide.rds",
    "fof_analysis_k33_wide.csv"
  ))
  long_candidates <- file.path(analysis_dir, c(
    "fof_analysis_k33_long.rds",
    "fof_analysis_k33_long.csv"
  ))
  k15_candidates <- file.path(frailty_dir, c(
    "kaatumisenpelko_with_frailty_k15.rds",
    "kaatumisenpelko_with_frailty_k15.csv",
    "kaatumisenpelko_with_frailty_scores.rds",
    "kaatumisenpelko_with_frailty_scores.csv"
  ))

  list(
    analysis_wide = pick_first_existing(wide_candidates),
    analysis_long = pick_first_existing(long_candidates),
    k15 = pick_first_existing(k15_candidates),
    analysis_dir = analysis_dir,
    frailty_dir = frailty_dir
  )
}

find_col <- function(nms, candidates) {
  hit <- intersect(candidates, nms)
  if (length(hit) == 0) return(NA_character_)
  hit[[1]]
}

mode_top_levels <- function(x, k = 3) {
  x <- x[!is.na(x)]
  if (length(x) == 0) return(NA_character_)
  tb <- sort(table(as.character(x)), decreasing = TRUE)
  top <- head(tb, k)
  paste(paste0(names(top), ":", as.integer(top)), collapse = " | ")
}

coerce_numeric <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  if (is.logical(x)) return(as.numeric(x))
  if (inherits(x, "Date") || inherits(x, "POSIXt")) return(as.numeric(x))
  if (is.factor(x)) return(as.numeric(x))
  if (is.character(x)) {
    out <- suppressWarnings(as.numeric(x))
    if (all(is.na(out) == is.na(x))) return(out)
    return(as.numeric(factor(x)))
  }
  suppressWarnings(as.numeric(x))
}

infer_type <- function(x) {
  nn <- x[!is.na(x)]
  nlev <- length(unique(nn))
  if (nlev <= 1) return("constant")
  if (nlev == 2) return("binary")
  if (is.factor(x) || is.character(x)) {
    if (nlev <= 7) return("ordinal")
    return("categorical")
  }
  if (is.numeric(x)) {
    if (all(abs(nn - round(nn)) < 1e-9) && nlev <= 7) return("ordinal")
    return("continuous")
  }
  "other"
}

expected_direction <- function(var_name) {
  better_when_higher <- c(
    "energy_score", "self_rated_health", "toimintakyky", "activity_score",
    "physical_activity_score", "adl_score", "iadl_score", "quality_of_life"
  )
  if (any(grepl(paste(better_when_higher, collapse = "|"), var_name, ignore.case = TRUE))) {
    return(-1)
  }
  1
}

to_worse_numeric <- function(x, var_name, var_type) {
  direction <- expected_direction(var_name)
  xnum <- coerce_numeric(x)

  if (var_type == "binary") {
    vals <- sort(unique(xnum[!is.na(xnum)]))
    if (length(vals) != 2) return(rep(NA_real_, length(x)))
    out <- ifelse(is.na(xnum), NA_real_, ifelse(xnum == max(vals), 1, 0))
    if (direction < 0) out <- ifelse(is.na(out), NA_real_, 1 - out)
    return(out)
  }

  if (var_type %in% c("ordinal", "continuous")) {
    rng <- range(xnum, na.rm = TRUE)
    if (!all(is.finite(rng)) || diff(rng) == 0) return(rep(NA_real_, length(x)))
    scaled <- (xnum - rng[[1]]) / diff(rng)
    if (direction < 0) scaled <- 1 - scaled
    return(scaled)
  }

  rep(NA_real_, length(x))
}

safe_cor <- function(x, y) {
  ok <- !is.na(x) & !is.na(y)
  if (sum(ok) < 10) return(NA_real_)
  suppressWarnings(cor(x[ok], y[ok]))
}

closest_suggestions <- function(targets, names_pool, max_n = 3) {
  out <- lapply(targets, function(tgt) {
    d <- utils::adist(tgt, names_pool, ignore.case = TRUE)
    ord <- order(d)
    paste(head(names_pool[ord], max_n), collapse = ", ")
  })
  tibble(expected_target = targets, closest_columns = unlist(out, use.names = FALSE))
}

# 0) Resolve inputs from DATA_ROOT ------------------------------------------------
data_root <- infer_data_root()
resolved <- resolve_inputs(data_root)

if (is.na(resolved$analysis_wide) && is.na(resolved$analysis_long)) {
  stop(
    "K39 requires K33 analysis dataset under DATA_ROOT/paper_01/analysis. ",
    "Missing both wide and long canonical files.",
    call. = FALSE
  )
}

base_path <- if (!is.na(resolved$analysis_wide)) resolved$analysis_wide else resolved$analysis_long
base_df <- load_tabular(base_path)
names(base_df) <- clean_names_simple(names(base_df))

id_col <- find_col(names(base_df), c("id", "participant_id", "subject_id", "study_id"))
if (is.na(id_col)) {
  stop("Could not resolve ID column from K33 dataset.", call. = FALSE)
}

# If long-like dataset, keep baseline rows deterministically when possible.
time_col <- find_col(names(base_df), c("time", "timepoint", "visit", "aika"))
if (!is.na(time_col)) {
  tvals <- tolower(as.character(base_df[[time_col]]))
  baseline_levels <- c("baseline", "bl", "0", "0m", "m0", "t0")
  has_baseline <- tvals %in% baseline_levels
  if (any(has_baseline, na.rm = TRUE)) {
    base_df <- base_df[has_baseline %in% TRUE, , drop = FALSE]
  }
}

base_df <- base_df %>%
  arrange(.data[[id_col]]) %>%
  group_by(.data[[id_col]]) %>%
  slice(1L) %>%
  ungroup()

# Optional K15 merge for deficit indicators
if (!is.na(resolved$k15)) {
  k15_df <- load_tabular(resolved$k15)
  names(k15_df) <- clean_names_simple(names(k15_df))
  k15_id <- find_col(names(k15_df), c("id", "participant_id", "subject_id", "study_id"))

  if (!is.na(k15_id)) {
    k15_keep <- setdiff(names(k15_df), id_col)
    if (!(id_col %in% names(k15_df))) {
      names(k15_df)[names(k15_df) == k15_id] <- id_col
    }
    base_df <- base_df %>% left_join(k15_df[, c(id_col, setdiff(names(k15_df), id_col)), drop = FALSE], by = id_col)
  }
}

# 1) Phase A: clean_names + column inventory + exclusion + audits ----------------
perf_regex <- "puristus|grip|kavely|gait|tuoli|chair|seisom|single_leg|balance"
admin_regex <- "^id$|^time$|composite_z|capacity|fof|frailty_vulnerability_score|delta_"

composite_col <- find_col(
  names(base_df),
  c("composite_z_baseline", "composite_z0", "composite_z", "toimintakykysummary0")
)

col_inventory <- tibble(
  var_name = names(base_df),
  class = vapply(base_df, function(x) class(x)[1], character(1)),
  n = nrow(base_df),
  n_miss = vapply(base_df, function(x) sum(is.na(x)), integer(1)),
  p_miss = n_miss / pmax(n, 1),
  n_levels = vapply(base_df, function(x) length(unique(x[!is.na(x)])), integer(1))
)
write_agg_csv(col_inventory, "k39_column_inventory.csv", notes = "Phase A clean_names column inventory")

excluded_perf <- tibble(
  var_name = names(base_df)[grepl(perf_regex, names(base_df), ignore.case = TRUE)],
  reason = "performance_test_pattern"
)

excluded_admin <- tibble(
  var_name = names(base_df)[grepl(admin_regex, names(base_df), ignore.case = TRUE)],
  reason = "administrative_or_structural"
)

excluded_vars <- bind_rows(excluded_perf, excluded_admin) %>% distinct(var_name, .keep_all = TRUE)
write_agg_csv(excluded_vars, "k39_excluded_vars.csv", notes = "Hard exclusions by governance and overlap guard")

candidate_names <- setdiff(names(base_df), excluded_vars$var_name)

candidate_inventory <- lapply(candidate_names, function(vn) {
  x <- base_df[[vn]]
  vtype <- infer_type(x)
  worse <- to_worse_numeric(x, vn, vtype)
  prev <- if (vtype == "binary") mean(worse == 1, na.rm = TRUE) else NA_real_
  corz <- if (!is.na(composite_col)) safe_cor(worse, coerce_numeric(base_df[[composite_col]])) else NA_real_

  tibble(
    var_name = vn,
    type = vtype,
    n = length(x),
    n_miss = sum(is.na(x)),
    p_miss = mean(is.na(x)),
    prevalence = prev,
    n_levels = length(unique(x[!is.na(x)])),
    top_levels = mode_top_levels(x),
    cor_with_composite_z_baseline = corz
  )
}) %>% bind_rows()

write_agg_csv(candidate_inventory, "k39_candidate_inventory.csv", notes = "Phase A non-performance candidate inventory")

candidate_vs_comp <- candidate_inventory %>%
  transmute(var_name, cor_with_composite_z_baseline)
write_agg_csv(candidate_vs_comp, "k39_candidate_vs_compositez_cor.csv", notes = "Phase A overlap diagnostics vs Composite_Z_baseline")

# Red flags: rare prevalence, extreme imbalance, near duplicates
rf1 <- candidate_inventory %>%
  filter(type == "binary", !is.na(prevalence), prevalence < 0.05) %>%
  transmute(flag = "ultra_rare_prevalence", var_name, detail = paste0("prevalence=", round(prevalence, 4)))

rf2 <- candidate_inventory %>%
  filter(type == "binary", !is.na(prevalence), prevalence > 0.95) %>%
  transmute(flag = "extreme_imbalance", var_name, detail = paste0("prevalence=", round(prevalence, 4)))

ord_bin <- candidate_inventory %>% filter(type %in% c("binary", "ordinal"))
rf3 <- tibble(flag = character(), var_name = character(), detail = character())
if (nrow(ord_bin) >= 2) {
  nm <- ord_bin$var_name
  mat <- sapply(nm, function(vn) to_worse_numeric(base_df[[vn]], vn, ord_bin$type[ord_bin$var_name == vn]))
  if (is.vector(mat)) mat <- matrix(mat, ncol = 1, dimnames = list(NULL, nm))
  cmat <- suppressWarnings(cor(mat, use = "pairwise.complete.obs"))
  if (!is.null(dim(cmat)) && ncol(cmat) > 1) {
    idx <- which(abs(cmat) > 0.90 & upper.tri(cmat), arr.ind = TRUE)
    if (nrow(idx) > 0) {
      rf3 <- tibble(
        flag = "near_duplicate_pair",
        var_name = paste0(colnames(cmat)[idx[, 1]], " ~ ", colnames(cmat)[idx[, 2]]),
        detail = paste0("abs_cor=", round(abs(cmat[idx]), 4))
      )
    }
  }
}

red_flags <- bind_rows(rf1, rf2, rf3)
if (nrow(red_flags) == 0) red_flags <- tibble(flag = "none", var_name = NA_character_, detail = "No configured red flags")
write_agg_csv(red_flags, "k39_red_flags.csv", notes = "Phase A red flags")

# Mapping helper artifact (closest suggestions + manual mapping placeholder)
mapping_targets <- c("fatigue", "weight_loss", "low_activity", "adl", "iadl", "comorbidity")
mapping_help <- closest_suggestions(mapping_targets, candidate_names, max_n = 3)
mapping_help$manual_mapping_selected_column <- NA_character_
write_agg_csv(mapping_help, "k39_mapping_suggestions.csv", notes = "Closest-match suggestions + manual mapping block")

# 2) Phase B: deterministic model selection -------------------------------------
usable <- candidate_inventory %>%
  mutate(
    usable_missing = p_miss <= 0.20,
    usable_prev = ifelse(type == "binary", !is.na(prevalence) & prevalence >= 0.05 & prevalence <= 0.95, TRUE),
    usable_for_cfa = type %in% c("binary", "ordinal") & usable_missing & usable_prev
  )

phenotype_regex <- "fatigue|exhaust|weight|appetite|activity|adl|iadl|self_rated_health|energy"
usable <- usable %>%
  mutate(
    phenotype_like = grepl(phenotype_regex, var_name, ignore.case = TRUE),
    deficit_like = type %in% c("binary", "ordinal")
  )

deficit_pool <- usable %>% filter(deficit_like, usable_for_cfa)
phenotype_pool <- usable %>% filter(phenotype_like, usable_for_cfa)

rank_key <- function(df) {
  df %>%
    mutate(priority = case_when(
      grepl("adl|iadl", var_name, ignore.case = TRUE) ~ 1,
      grepl("fatigue|exhaust|weight|appetite|activity", var_name, ignore.case = TRUE) ~ 2,
      grepl("comorb|disease|diag|med", var_name, ignore.case = TRUE) ~ 3,
      TRUE ~ 4
    )) %>%
    arrange(priority, p_miss, desc(abs(cor_with_composite_z_baseline)))
}

decision <- "fallback_z_only"
selected <- character(0)

if (nrow(deficit_pool) >= 8) {
  decision <- "deficit_accumulation_latent"
  selected <- rank_key(deficit_pool) %>% slice_head(n = 6) %>% pull(var_name)
} else if (nrow(phenotype_pool) >= 4) {
  decision <- "phenotype_style_latent"
  selected <- rank_key(phenotype_pool) %>% slice_head(n = 5) %>% pull(var_name)
} else {
  fallback_pool <- usable %>%
    filter(type %in% c("binary", "ordinal", "continuous"), p_miss <= 0.35) %>%
    arrange(p_miss)
  if (nrow(fallback_pool) >= 3) {
    selected <- fallback_pool %>% slice_head(n = min(6, n())) %>% pull(var_name)
  }
}

selected_tbl <- tibble(
  var_name = selected,
  selected_for = decision,
  expected_direction = vapply(selected, expected_direction, numeric(1))
)
write_agg_csv(selected_tbl, "k39_selected_indicators.csv", notes = "Selected indicators after deterministic Phase B rule")

# Build numeric scores (always) and CFA inputs (conditional)
if (length(selected) == 0) {
  stop("K39: insufficient non-performance indicators (<3 usable) for even z-composite fallback.", call. = FALSE)
}

score_df <- base_df[, c(id_col), drop = FALSE]
names(score_df) <- c("id")

for (vn in selected) {
  vtype <- usable$type[match(vn, usable$var_name)]
  score_df[[paste0("worse_", vn)]] <- to_worse_numeric(base_df[[vn]], vn, vtype)
}

z_cols <- grep("^worse_", names(score_df), value = TRUE)
z_mat <- as.matrix(scale(score_df[, z_cols, drop = FALSE]))
if (is.null(dim(z_mat))) z_mat <- matrix(z_mat, ncol = 1)
score_df$frailty_vulnerability_score_z <- rowMeans(z_mat, na.rm = TRUE)
score_df$frailty_vulnerability_score_z[!is.finite(score_df$frailty_vulnerability_score_z)] <- NA_real_

# CFA path
score_df$frailty_vulnerability_score_latent_primary <- NA_real_
admissibility <- tibble(
  decision = decision,
  attempted_cfa = FALSE,
  converged = NA,
  no_negative_residual_variances = NA,
  no_std_all_gt_1 = NA,
  latent_na_share_le_0_2 = NA,
  admissible = FALSE,
  notes = "CFA not attempted"
)
cfa_loadings <- tibble(
  lhs = character(),
  op = character(),
  rhs = character(),
  est = numeric(),
  std_all = numeric()
)
cfa_summary_lines <- c("CFA not attempted")

if (decision %in% c("deficit_accumulation_latent", "phenotype_style_latent") && length(selected) >= 4) {
  if (!requireNamespace("lavaan", quietly = TRUE)) {
    admissibility$notes <- "lavaan package missing; latent scores set NA"
  } else {
    cfa_df <- score_df[, c("id", z_cols), drop = FALSE]
    cfa_names <- sub("^worse_", "", z_cols)
    names(cfa_df)[match(z_cols, names(cfa_df))] <- cfa_names

    ordered_names <- character(0)
    for (vn in cfa_names) {
      raw_v <- cfa_df[[vn]]
      if (all(is.na(raw_v))) next
      uq <- sort(unique(raw_v[!is.na(raw_v)]))
      if (length(uq) <= 7) {
        levs <- sort(unique(raw_v[!is.na(raw_v)]))
        cfa_df[[vn]] <- factor(raw_v, levels = levs, ordered = TRUE)
        ordered_names <- c(ordered_names, vn)
      }
    }

    if (length(ordered_names) >= 4) {
      model_syntax <- paste0("Frailty =~ ", paste(ordered_names, collapse = " + "))
      fit <- try(
        lavaan::cfa(
          model = model_syntax,
          data = cfa_df,
          ordered = ordered_names,
          estimator = "WLSMV",
          std.lv = TRUE,
          missing = "pairwise"
        ),
        silent = TRUE
      )

      if (!inherits(fit, "try-error")) {
        conv <- isTRUE(lavaan::lavInspect(fit, "converged"))
        theta <- try(lavaan::lavInspect(fit, "theta"), silent = TRUE)
        neg_resid <- FALSE
        if (!inherits(theta, "try-error") && !is.null(theta) && all(dim(theta) > 0)) {
          neg_resid <- any(diag(theta) < 0, na.rm = TRUE)
        }

        stdsol <- try(lavaan::standardizedSolution(fit), silent = TRUE)
        std_bad <- FALSE
        if (!inherits(stdsol, "try-error") && nrow(stdsol) > 0) {
          std_bad <- any(abs(stdsol$est.std) > 1, na.rm = TRUE)
          std_tbl <- stdsol %>% as_tibble()
          if ("est" %in% names(std_tbl)) {
            est_raw <- std_tbl$est
          } else if ("est.unstd" %in% names(std_tbl)) {
            est_raw <- std_tbl$est.unstd
          } else {
            est_raw <- rep(NA_real_, nrow(std_tbl))
          }
          std_tbl$est_raw <- est_raw
          cfa_loadings <- std_tbl %>%
            filter(op == "=~") %>%
            transmute(lhs, op, rhs, est = est_raw, std_all = est.std)
        }

        scores <- try(lavaan::lavPredict(fit), silent = TRUE)
        latent_vec <- rep(NA_real_, nrow(score_df))
        na_share <- 1
        if (!inherits(scores, "try-error")) {
          sv <- as.numeric(scores[, 1])
          latent_vec <- sv
          na_share <- mean(is.na(sv))
        }

        is_admissible <- conv && !neg_resid && !std_bad && is.finite(na_share) && na_share <= 0.20
        if (is_admissible) {
          score_df$frailty_vulnerability_score_latent_primary <- latent_vec
        }

        admissibility <- tibble(
          decision = decision,
          attempted_cfa = TRUE,
          converged = conv,
          no_negative_residual_variances = !neg_resid,
          no_std_all_gt_1 = !std_bad,
          latent_na_share_le_0_2 = na_share <= 0.20,
          admissible = is_admissible,
          notes = ifelse(is_admissible, "CFA admissible", "CFA inadmissible; latent set NA")
        )
        cfa_summary_lines <- c(
          sprintf("decision=%s", decision),
          sprintf("converged=%s", as.character(conv)),
          sprintf("no_negative_residual_variances=%s", as.character(!neg_resid)),
          sprintf("no_std_all_gt_1=%s", as.character(!std_bad)),
          sprintf("latent_na_share=%.4f", na_share),
          sprintf("admissible=%s", as.character(is_admissible))
        )
      } else {
        admissibility <- tibble(
          decision = decision,
          attempted_cfa = TRUE,
          converged = FALSE,
          no_negative_residual_variances = FALSE,
          no_std_all_gt_1 = FALSE,
          latent_na_share_le_0_2 = FALSE,
          admissible = FALSE,
          notes = "CFA fit failed; latent set NA"
        )
        cfa_summary_lines <- c(
          sprintf("decision=%s", decision),
          "fit_error=TRUE",
          "admissible=FALSE"
        )
      }
    } else {
      admissibility$attempted_cfa <- TRUE
      admissibility$notes <- "Insufficient ordered indicators for CFA; latent set NA"
      cfa_summary_lines <- c(
        sprintf("decision=%s", decision),
        sprintf("ordered_indicator_count=%d", length(ordered_names)),
        "admissible=FALSE",
        "reason=insufficient_ordered_indicators"
      )
    }
  }
}

write_agg_csv(admissibility, "k39_cfa_admissibility.csv", notes = "CFA admissibility gate")
write_agg_csv(admissibility, "k39_cfa_diagnostics.csv", notes = "CFA diagnostics alias")
write_agg_csv(cfa_loadings, "k39_cfa_primary_loadings.csv", notes = "CFA standardized loadings")
write_agg_txt(cfa_summary_lines, "k39_cfa_primary_summary.txt", notes = "CFA primary summary")

# 3) Externalize patient-level outputs ------------------------------------------
external_dir <- file.path(data_root, "paper_01", "frailty_vulnerability")
dir.create(external_dir, recursive = TRUE, showWarnings = FALSE)

external_csv <- file.path(external_dir, "kaatumisenpelko_with_frailty_vulnerability_k39.csv")
external_rds <- file.path(external_dir, "kaatumisenpelko_with_frailty_vulnerability_k39.rds")

out_patient <- score_df %>%
  select(id, frailty_vulnerability_score_latent_primary, frailty_vulnerability_score_z)

readr::write_csv(out_patient, external_csv)
saveRDS(out_patient, external_rds)

# 4) Decision log + receipt + sessioninfo ---------------------------------------
decision_lines <- c(
  sprintf("timestamp=%s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  sprintf("data_root=%s", data_root),
  sprintf("input_base_path=%s", base_path),
  sprintf("input_k15_path=%s", ifelse(is.na(resolved$k15), "NA", resolved$k15)),
  sprintf("decision=%s", decision),
  sprintf("n_candidates=%d", nrow(candidate_inventory)),
  sprintf("n_deficit_usable=%d", nrow(deficit_pool)),
  sprintf("n_phenotype_usable=%d", nrow(phenotype_pool)),
  sprintf("selected_indicators=%s", paste(selected, collapse = ",")),
  sprintf("cfa_admissible=%s", as.character(admissibility$admissible[[1]])),
  sprintf("governance=repo_aggregate_only;patient_level_externalized")
)
write_agg_txt(decision_lines, "k39_decision_log.txt", notes = "Deterministic Phase A->B rule and outcome")

receipt_lines <- c(
  sprintf("timestamp=%s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  sprintf("external_dir=%s", external_dir),
  sprintf("external_csv=%s", external_csv),
  sprintf("external_rds=%s", external_rds),
  sprintf("rows_exported=%d", nrow(out_patient)),
  sprintf("cols_exported=%d", ncol(out_patient)),
  sprintf("md5_csv=%s", md5_file(external_csv)),
  sprintf("md5_rds=%s", md5_file(external_rds)),
  "columns_exported=id,frailty_vulnerability_score_latent_primary,frailty_vulnerability_score_z",
  "governance=patient-level outputs written only under DATA_ROOT"
)
write_agg_txt(receipt_lines, "k39_patient_level_output_receipt.txt", notes = "External patient-level output receipt")
write_agg_txt(receipt_lines, "k39_external_output_receipt.txt", notes = "External patient-level output receipt (legacy alias)")

session_path <- save_sessioninfo_manifest(outputs_dir = outputs_dir, manifest_path = manifest_path, script = script_label)
session_alias <- file.path(outputs_dir, "k39_sessioninfo.txt")
file.copy(session_path, session_alias, overwrite = TRUE)
append_artifact("k39_sessioninfo.txt", "sessioninfo", session_alias, notes = "K39 session info alias")

message("K39 completed.")
