#!/usr/bin/env Rscript
# ==============================================================================
# K26_LMM_MOD - Long LMM time×FOF backbone + frailty moderation sensitivity
# File tag: K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R
# Purpose: Fit long-format mixed models for Composite_Z (time 0/12) with
#          backbone time×FOF and exploratory time×frailty×cComposite_Z0
#          moderation, running both frailty modes (cat + score) in one run.
#
# Outcome: Composite_Z (long; time_f in {0,12})
# Predictors: time_f, FOF_status (nonFOF/FOF), frailty_cat_3 or frailty_score_3
# Moderator/interaction: time_f×frailty×cComposite_Z0 (exploratory)
# Grouping variable: ID (random intercept)
# Covariates: age, sex, BMI (+ optional Balance_problem)
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# ID (or id/Jnro/NRO), age, sex, BMI,
# FOF_status or kaatumisenpelkoOn,
# Composite_Z0 or ToimintaKykySummary0,
# Composite_Z12 or ToimintaKykySummary2,
# frailty_cat_3 (for cat mode),
# frailty_score_3 (for score mode),
# tasapainovaikeus (optional)
#
# Mapping (raw -> analysis; explicit):
# ID <- ID | id | Jnro | NRO
# FOF_status <- FOF_status | kaatumisenpelkoOn (0/1 -> nonFOF/FOF)
# Composite_Z0 <- Composite_Z0 | ToimintaKykySummary0
# Composite_Z12 <- Composite_Z12 | ToimintaKykySummary2
# frailty_score_3 <- frailty_score_3 (canonical required)
# frailty_cat_3 <- robust/pre-frail/frail -> Robust/Pre-frail/Frail
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: not required (no stochastic methods)
#
# Outputs + manifest:
# - script_label: K26_LMM_MOD (canonical)
# - outputs dir root (init_paths): R-scripts/K26/outputs/
# - artifact subdir: R-scripts/K26/outputs/K26/K26_LMM_MOD/
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load raw data (immutable)
# 03) Standardize vars + QC checks
# 04) Build wide -> long (time_f 0/12)
# 05) Fit primary model per frailty mode (ML)
# 06) Fit moderation model per frailty mode (ML)
# 07) LRT primary vs moderation + fixed effects tables
# 08) Simple slopes (12-0 change) by frailty and cComposite_Z0 anchors
# 09) Results text (FI) generated from produced tables
# 10) Save artifacts + append manifest rows
# 11) Save sessionInfo
# 12) EOF marker
# ==============================================================================

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(readr)
  library(tidyr)
  library(tibble)
  library(stringr)
  library(lme4)
  library(lmerTest)
})

# --- Standard init (MANDATORY) -----------------------------------------------
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K26_LMM_MOD"
}

script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K26_LMM_MOD"

source(here::here("R", "functions", "io.R"))
source(here::here("R", "functions", "checks.R"))
source(here::here("R", "functions", "modeling.R"))
source(here::here("R", "functions", "reporting.R"))

paths <- init_paths("K26")
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path
out_subdir <- file.path(outputs_dir, "K26", "K26_LMM_MOD")
dir.create(out_subdir, recursive = TRUE, showWarnings = FALSE)
options(fof.outputs_dir = out_subdir, fof.manifest_path = manifest_path, fof.script = script_label)

parse_cli <- function(args) {
  out <- list(
    input = "",
    include_balance = TRUE,
    run_cat = TRUE,
    run_score = TRUE,
    balance_var = "tasapainovaikeus"
  )
  for (arg in args) {
    if (startsWith(arg, "--input=")) out$input <- sub("^--input=", "", arg)
    if (startsWith(arg, "--include_balance=")) out$include_balance <- tolower(sub("^--include_balance=", "", arg)) %in% c("true", "1", "yes", "y")
    if (startsWith(arg, "--run_cat=")) out$run_cat <- tolower(sub("^--run_cat=", "", arg)) %in% c("true", "1", "yes", "y")
    if (startsWith(arg, "--run_score=")) out$run_score <- tolower(sub("^--run_score=", "", arg)) %in% c("true", "1", "yes", "y")
    if (startsWith(arg, "--balance_var=")) out$balance_var <- sub("^--balance_var=", "", arg)
  }
  out
}

load_rdata_input <- function(path) {
  e <- new.env(parent = emptyenv())
  objs <- load(path, envir = e)

  if ("analysis_data" %in% objs) {
    d <- get("analysis_data", envir = e)
    if (inherits(d, c("data.frame", "tbl_df", "tbl"))) {
      return(d)
    }
  }

  candidates <- objs[vapply(objs, function(nm) {
    inherits(get(nm, envir = e), c("data.frame", "tbl_df", "tbl"))
  }, logical(1))]

  has_required <- function(df) {
    id_ok <- any(c("ID", "id", "Jnro", "NRO") %in% names(df))
    fof_ok <- any(c("FOF_status", "kaatumisenpelkoOn") %in% names(df))
    z0_ok <- any(c("Composite_Z0", "ToimintaKykySummary0") %in% names(df))
    z12_ok <- any(c("Composite_Z12", "ToimintaKykySummary2") %in% names(df))
    common_ok <- all(c("age", "sex", "BMI", "frailty_cat_3", "frailty_score_3") %in% names(df))
    id_ok && fof_ok && z0_ok && z12_ok && common_ok
  }

  matching <- candidates[vapply(candidates, function(nm) has_required(get(nm, envir = e)), logical(1))]
  if (length(matching) == 0) {
    stop(
      paste0(
        "No suitable data.frame/tibble found in RData. Objects: ",
        paste(objs, collapse = ", "),
        ". Data-frame candidates: ",
        ifelse(length(candidates) == 0, "<none>", paste(candidates, collapse = ", ")),
        ". Required columns include ID/id/Jnro/NRO, FOF_status/kaatumisenpelkoOn, ",
        "Composite_Z0/ToimintaKykySummary0, Composite_Z12/ToimintaKykySummary2, ",
        "age, sex, BMI, frailty_cat_3, frailty_score_3."
      )
    )
  }

  get(matching[1], envir = e)
}

load_input_as_df <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext %in% c("rdata", "rda")) {
    return(load_rdata_input(path))
  }
  if (ext == "rds") {
    x <- readRDS(path)
    if (!inherits(x, c("data.frame", "tbl_df", "tbl"))) {
      stop("Resolved input is not a data.frame/tibble: ", path)
    }
    return(as_tibble(x))
  }
  if (ext == "csv") {
    return(readr::read_csv(path, show_col_types = FALSE))
  }
  stop("Unsupported input extension for K26 resolver: ", ext, " (path: ", path, ")")
}

first_existing <- function(df, candidates) {
  hit <- candidates[candidates %in% names(df)]
  if (length(hit) == 0) return(NA_character_)
  hit[1]
}

normalize_id_key <- function(x) {
  trimws(as.character(x))
}

attach_k15_frailty_to_k33 <- function(k33, k15) {
  k33_id <- first_existing(k33, c("id", "ID", "Jnro", "NRO"))
  k15_id <- first_existing(k15, c("id", "ID", "Jnro", "NRO"))
  if (is.na(k33_id) || is.na(k15_id)) return(k33)

  k15_score_col <- first_existing(k15, c("frailty_score_3", "frailty_score"))
  k15_cat_col <- first_existing(k15, c("frailty_cat_3", "frailty_cat"))
  if (is.na(k15_score_col) && is.na(k15_cat_col)) return(k33)

  k15_join <- k15 %>%
    transmute(
      .id_key = normalize_id_key(.data[[k15_id]]),
      frailty_score_3_k15 = if (!is.na(k15_score_col)) suppressWarnings(as.numeric(.data[[k15_score_col]])) else NA_real_,
      frailty_cat_3_k15 = if (!is.na(k15_cat_col)) normalize_frailty_cat(.data[[k15_cat_col]]) else factor(NA)
    ) %>%
    arrange(.id_key) %>%
    distinct(.id_key, .keep_all = TRUE)

  out <- k33 %>%
    mutate(.id_key = normalize_id_key(.data[[k33_id]])) %>%
    left_join(k15_join, by = ".id_key")

  if ("frailty_score_3" %in% names(out)) {
    out <- out %>%
      mutate(
        frailty_score_3 = dplyr::coalesce(
          suppressWarnings(as.numeric(.data$frailty_score_3)),
          .data$frailty_score_3_k15
        )
      )
  } else {
    out <- out %>% mutate(frailty_score_3 = .data$frailty_score_3_k15)
  }

  if ("frailty_cat_3" %in% names(out)) {
    out <- out %>%
      mutate(
        frailty_cat_3 = dplyr::coalesce(
          normalize_frailty_cat(.data$frailty_cat_3),
          .data$frailty_cat_3_k15
        )
      )
  } else {
    out <- out %>% mutate(frailty_cat_3 = .data$frailty_cat_3_k15)
  }

  out %>% select(-any_of(c(".id_key", "frailty_score_3_k15", "frailty_cat_3_k15")))
}

resolve_input_data <- function(cli_input) {
  attempts <- character()
  note_attempt <- function(label, path) {
    attempts <<- c(attempts, paste0(label, ": ", path))
  }
  fail_unresolved <- function() {
    stop(
      paste0(
        "K26 input resolution failed.\n",
        "Tried paths:\n- ",
        paste(attempts, collapse = "\n- "),
        "\nRequired columns include canonical frailty_score_3 (+ K26 required vars).\n",
        "Use one of:\n",
        "1) --input=/path/to/input.(RData|rds|csv)\n",
        "2) DATA_PATH=/path/to/input.(RData|rds|csv)\n",
        "3) DATA_ROOT with K33/K15 externalized datasets under paper_01."
      )
    )
  }

  if (nzchar(cli_input)) {
    note_attempt("--input", cli_input)
    if (!file.exists(cli_input)) fail_unresolved()
    return(list(
      data = load_input_as_df(cli_input),
      source_path = normalizePath(cli_input, winslash = "/", mustWork = TRUE),
      source_note = "--input",
      attempts = attempts
    ))
  }

  data_path <- Sys.getenv("DATA_PATH", unset = "")
  if (nzchar(data_path)) {
    note_attempt("DATA_PATH", data_path)
    if (file.exists(data_path)) {
      return(list(
        data = load_input_as_df(data_path),
        source_path = normalizePath(data_path, winslash = "/", mustWork = TRUE),
        source_note = "DATA_PATH",
        attempts = attempts
      ))
    }
  }

  data_root <- Sys.getenv("DATA_ROOT", unset = "")
  if (nzchar(data_root)) {
    k33_candidates <- c(
      file.path(data_root, "paper_01", "analysis", "fof_analysis_k33_wide.rds"),
      file.path(data_root, "paper_01", "analysis", "fof_analysis_k33_wide.csv")
    )
    k15_candidates <- c(
      file.path(data_root, "paper_01", "frailty", "kaatumisenpelko_with_frailty_k15.rds"),
      file.path(data_root, "paper_01", "frailty", "kaatumisenpelko_with_frailty_scores.rds"),
      file.path(data_root, "paper_01", "frailty", "kaatumisenpelko_with_frailty_k15.csv"),
      file.path(data_root, "paper_01", "frailty", "kaatumisenpelko_with_frailty_scores.csv")
    )

    for (kp in k33_candidates) note_attempt("DATA_ROOT:k33", kp)
    for (kp in k15_candidates) note_attempt("DATA_ROOT:k15", kp)

    k33_path <- k33_candidates[file.exists(k33_candidates)][1]
    k15_path <- k15_candidates[file.exists(k15_candidates)][1]

    if (!is.na(k33_path) && nzchar(k33_path)) {
      k33_df <- load_input_as_df(k33_path)
      if (any(c("frailty_score_3", "frailty_score") %in% names(k33_df))) {
        return(list(
          data = k33_df,
          source_path = normalizePath(k33_path, winslash = "/", mustWork = TRUE),
          source_note = "DATA_ROOT:k33",
          attempts = attempts
        ))
      }
      if (!is.na(k15_path) && nzchar(k15_path)) {
        k15_df <- load_input_as_df(k15_path)
        merged <- attach_k15_frailty_to_k33(k33_df, k15_df)
        return(list(
          data = merged,
          source_path = paste0(
            normalizePath(k33_path, winslash = "/", mustWork = TRUE),
            " + ",
            normalizePath(k15_path, winslash = "/", mustWork = TRUE)
          ),
          source_note = "DATA_ROOT:k33_plus_k15",
          attempts = attempts
        ))
      }
    }

    if (!is.na(k15_path) && nzchar(k15_path)) {
      return(list(
        data = load_input_as_df(k15_path),
        source_path = normalizePath(k15_path, winslash = "/", mustWork = TRUE),
        source_note = "DATA_ROOT:k15",
        attempts = attempts
      ))
    }
  }

  fail_unresolved()
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

normalize_sex <- function(x) {
  xc <- tolower(trimws(as.character(x)))
  female_set <- c("0", "2", "f", "female", "woman", "nainen")
  male_set <- c("1", "m", "male", "man", "mies")
  out <- rep(NA_character_, length(xc))
  out[xc %in% female_set] <- "female"
  out[xc %in% male_set] <- "male"
  factor(out, levels = c("female", "male"))
}

normalize_frailty_cat <- function(x) {
  xc <- tolower(trimws(as.character(x)))
  out <- dplyr::case_when(
    xc %in% c("robust", "0") ~ "Robust",
    xc %in% c("pre-frail", "prefrail", "1") ~ "Pre-frail",
    xc %in% c("frail", "2", "3") ~ "Frail",
    TRUE ~ NA_character_
  )
  factor(out, levels = c("Robust", "Pre-frail", "Frail"))
}

fmt_p <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.001) return("<0.001")
  sprintf("%.3f", p)
}

append_artifact <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  append_manifest(
    manifest_row(script = script_label, label = label, path = get_relpath(path), kind = kind, n = n, notes = notes),
    manifest_path
  )
}

tidy_fixed <- function(model) {
  if (requireNamespace("broom.mixed", quietly = TRUE)) {
    return(broom.mixed::tidy(model, effects = "fixed", conf.int = TRUE))
  }
  sm <- summary(model)$coefficients
  out <- tibble(
    term = rownames(sm),
    estimate = sm[, "Estimate"],
    std.error = sm[, "Std. Error"],
    statistic = sm[, grep("(t value|z value)", colnames(sm), value = TRUE)[1]],
    p.value = sm[, grep("Pr\\(>", colnames(sm), value = TRUE)[1]]
  )
  ci <- tryCatch(confint(model, parm = "beta_", method = "Wald"), error = function(e) NULL)
  if (!is.null(ci)) {
    ci_df <- tibble(term = rownames(ci), conf.low = ci[, 1], conf.high = ci[, 2])
    out <- out %>% left_join(ci_df, by = "term")
  } else {
    out <- out %>% mutate(conf.low = NA_real_, conf.high = NA_real_)
  }
  out
}

make_lrt_table <- function(a) {
  p_col <- grep("Pr\\(>Chisq\\)", names(a), value = TRUE)
  tibble(
    model = rownames(a),
    npar = a$npar,
    AIC = a$AIC,
    BIC = a$BIC,
    logLik = a$logLik,
    deviance = a$deviance,
    Chisq = if ("Chisq" %in% names(a)) a$Chisq else NA_real_,
    Df = if ("Df" %in% names(a)) a$Df else NA_real_,
    p.value = if (length(p_col) == 1) a[[p_col]] else NA_real_
  )
}

safe_simple_slopes <- function(model, mode, data_mode) {
  if (!requireNamespace("emmeans", quietly = TRUE)) {
    return(tibble(note = "emmeans package missing; simple slopes not computed"))
  }

  c0_mean <- mean(data_mode$cComposite_Z0, na.rm = TRUE)
  c0_sd <- stats::sd(data_mode$cComposite_Z0, na.rm = TRUE)
  c0_vals <- c(c0_mean - c0_sd, c0_mean, c0_mean + c0_sd)

  if (mode == "cat") {
    frailty_levels <- levels(droplevels(data_mode$frailty_cat_3))
    at_list <- list(cComposite_Z0 = c0_vals, frailty_cat_3 = frailty_levels)
    emm <- emmeans::emmeans(model, ~ time_f | frailty_cat_3 + cComposite_Z0, at = at_list)
    sl <- emmeans::contrast(emm, method = list(change_12_minus_0 = c(-1, 1)), by = c("frailty_cat_3", "cComposite_Z0"))
    as.data.frame(sl) %>% as_tibble() %>% mutate(mode = mode)
  } else {
    observed_int <- sort(unique(as.integer(round(data_mode$frailty_score_3))))
    frailty_vals <- intersect(0:3, observed_int)
    if (length(frailty_vals) == 0) {
      return(tibble(note = "No observed integer frailty_score_3 values in 0:3", mode = mode))
    }
    at_list <- list(cComposite_Z0 = c0_vals, frailty_score_3 = frailty_vals)
    emm <- emmeans::emmeans(model, ~ time_f | frailty_score_3 + cComposite_Z0, at = at_list)
    sl <- emmeans::contrast(emm, method = list(change_12_minus_0 = c(-1, 1)), by = c("frailty_score_3", "cComposite_Z0"))
    as.data.frame(sl) %>% as_tibble() %>% mutate(mode = mode)
  }
}

build_results_text <- function(mode, lrt_tbl, fixed_mod, slopes_tbl, out_path) {
  lrt_p <- lrt_tbl %>% pull(p.value)
  lrt_p <- lrt_p[!is.na(lrt_p)]
  if (length(lrt_p) == 0) {
    lrt_p <- NA_real_
  } else {
    lrt_p <- tail(lrt_p, 1)
  }

  key_terms <- fixed_mod$term[grepl("time_f12", fixed_mod$term) & grepl("cComposite_Z0", fixed_mod$term)]
  three_way <- fixed_mod %>% filter(term %in% key_terms)

  lines <- c(
    paste0("K26 (", mode, ") tulosyhteenveto"),
    paste0("- LRT primary vs moderation p-arvo: ", fmt_p(as.numeric(lrt_p[1]))),
    "- 3-way termit (time_f12:*:cComposite_Z0) fixed effects -taulukosta:"
  )

  if (nrow(three_way) == 0) {
    lines <- c(lines, "  - Ei 3-way termejä löydetty (termimatch tyhjä).")
  } else {
    tw_lines <- apply(three_way, 1, function(r) {
      paste0("  - ", r[["term"]], ": beta=", sprintf("%.4f", as.numeric(r[["estimate"]])),
             ", p=", fmt_p(as.numeric(r[["p.value"]])))
    })
    lines <- c(lines, tw_lines)
  }

  lines <- c(lines, "- Yksinkertaiset slope-muutokset (12-0) taulukosta:")
  if ("note" %in% names(slopes_tbl)) {
    lines <- c(lines, paste0("  - ", slopes_tbl$note[1]))
  } else if (nrow(slopes_tbl) > 0) {
    nshow <- min(6, nrow(slopes_tbl))
    sl_show <- slopes_tbl[seq_len(nshow), , drop = FALSE]
    term_col <- if ("frailty_cat_3" %in% names(sl_show)) "frailty_cat_3" else if ("frailty_score_3" %in% names(sl_show)) "frailty_score_3" else NA_character_
    for (i in seq_len(nrow(sl_show))) {
      rr <- sl_show[i, ]
      grp <- if (!is.na(term_col)) as.character(rr[[term_col]]) else "NA"
      c0 <- if ("cComposite_Z0" %in% names(rr)) sprintf("%.3f", as.numeric(rr$cComposite_Z0)) else "NA"
      est <- if ("estimate" %in% names(rr)) sprintf("%.4f", as.numeric(rr$estimate)) else "NA"
      pvv <- if ("p.value" %in% names(rr)) fmt_p(as.numeric(rr$p.value)) else ""
      lines <- c(lines, paste0("  - group=", grp, ", cComposite_Z0=", c0, ", change12-0=", est, ", p=", pvv))
    }
  } else {
    lines <- c(lines, "  - Ei slope-rivejä tuotettu.")
  }

  lines <- c(lines,
             "- Tulkinta: 3-way-moderointi on eksploratiivinen; tulkinta varovaisesti.",
             "- Backbone-termi time_f:FOF_status sisältyi molempiin malleihin.")

  writeLines(lines, con = out_path)

  # Table-to-text crosscheck (deterministic)
  placeholder_used <- any(grepl("Ei 3-way termejä", lines, fixed = TRUE))
  terms_present <- if (length(key_terms) == 0) {
    FALSE
  } else {
    all(vapply(key_terms, function(tt) any(grepl(tt, lines, fixed = TRUE)), logical(1)))
  }
  crosscheck_ok <- isTRUE(terms_present) && !placeholder_used

  list(
    lines = lines,
    crosscheck_ok = crosscheck_ok,
    key_terms_n = length(key_terms),
    placeholder_used = placeholder_used
  )
}

run_mode <- function(mode, long_df, include_balance) {
  stopifnot(mode %in% c("cat", "score"))

  frailty_var <- if (mode == "cat") "frailty_cat_3" else "frailty_score_3"
  data_mode <- long_df

  if (mode == "cat") {
    data_mode <- data_mode %>% filter(!is.na(frailty_cat_3)) %>% mutate(frailty_cat_3 = droplevels(frailty_cat_3))
    if (nlevels(data_mode$frailty_cat_3) < 2) stop("Cat mode: frailty_cat_3 has <2 levels after filtering.")
  } else {
    data_mode <- data_mode %>% filter(!is.na(frailty_score_3))
    if (all(is.na(data_mode$frailty_score_3))) stop("Score mode: frailty_score_3 unavailable.")
  }

  covars <- c("age", "sex", "BMI")
  if (include_balance && "Balance_problem" %in% names(data_mode) && !all(is.na(data_mode$Balance_problem))) {
    covars <- c(covars, "Balance_problem")
  }

  req_mode <- unique(c("ID", "Composite_Z", "time_f", "FOF_status", "cComposite_Z0", frailty_var, covars))
  data_mode <- data_mode %>% select(all_of(req_mode)) %>% tidyr::drop_na()

  if (nrow(data_mode) < 20) stop("Mode ", mode, ": too few complete rows after filtering (n<20).")

  rhs_primary <- paste(c("time_f*FOF_status", paste0("time_f*", frailty_var), covars), collapse = " + ")
  rhs_mod <- paste(c("time_f*FOF_status", paste0("time_f*", frailty_var, "*cComposite_Z0"), covars), collapse = " + ")

  f_primary <- as.formula(paste("Composite_Z ~", rhs_primary, "+ (1|ID)"))
  f_mod <- as.formula(paste("Composite_Z ~", rhs_mod, "+ (1|ID)"))

  m_primary <- lmerTest::lmer(f_primary, data = data_mode, REML = FALSE)
  m_mod <- lmerTest::lmer(f_mod, data = data_mode, REML = FALSE)

  lrt <- anova(m_primary, m_mod)
  lrt_tbl <- make_lrt_table(lrt)

  fixed_primary <- tidy_fixed(m_primary)
  fixed_mod <- tidy_fixed(m_mod)
  slopes_tbl <- safe_simple_slopes(m_mod, mode, data_mode)

  p_lrt <- file.path(out_subdir, paste0("K26_LRT_primary_vs_mod_", mode, ".csv"))
  p_fix_p <- file.path(out_subdir, paste0("K26_fixed_effects_primary_", mode, ".csv"))
  p_fix_m <- file.path(out_subdir, paste0("K26_fixed_effects_moderation_", mode, ".csv"))
  p_sl <- file.path(out_subdir, paste0("K26_simple_slopes_change_", mode, ".csv"))
  p_txt <- file.path(out_subdir, paste0("K26_results_text_fi_", mode, ".txt"))
  p_rds_p <- file.path(out_subdir, paste0("K26_model_primary_", mode, ".rds"))
  p_rds_m <- file.path(out_subdir, paste0("K26_model_moderation_", mode, ".rds"))

  readr::write_csv(lrt_tbl, p_lrt)
  readr::write_csv(fixed_primary, p_fix_p)
  readr::write_csv(fixed_mod, p_fix_m)
  readr::write_csv(slopes_tbl, p_sl)
  saveRDS(m_primary, p_rds_p)
  saveRDS(m_mod, p_rds_m)

  txt_meta <- build_results_text(mode, lrt_tbl, fixed_mod, slopes_tbl, p_txt)

  append_artifact(paste0("K26_LRT_primary_vs_mod_", mode), "table_csv", p_lrt, n = nrow(lrt_tbl), notes = "K26 LRT: primary vs moderation")
  append_artifact(paste0("K26_fixed_effects_primary_", mode), "table_csv", p_fix_p, n = nrow(fixed_primary), notes = "K26 fixed effects primary")
  append_artifact(paste0("K26_fixed_effects_moderation_", mode), "table_csv", p_fix_m, n = nrow(fixed_mod), notes = "K26 fixed effects moderation")
  append_artifact(paste0("K26_simple_slopes_change_", mode), "table_csv", p_sl, n = nrow(slopes_tbl), notes = "K26 simple slopes change 12-0")
  append_artifact(paste0("K26_results_text_fi_", mode), "txt", p_txt, notes = "K26 Finnish results text generated from model tables")
  append_artifact(paste0("K26_model_primary_", mode), "rds", p_rds_p, notes = "K26 lmer primary model object")
  append_artifact(paste0("K26_model_moderation_", mode), "rds", p_rds_m, notes = "K26 lmer moderation model object")

  list(
    mode = mode,
    lrt = p_lrt,
    fixed_primary = p_fix_p,
    fixed_mod = p_fix_m,
    slopes = p_sl,
    txt = p_txt,
    n_complete = nrow(data_mode),
    crosscheck_ok = isTRUE(txt_meta$crosscheck_ok),
    key_terms_n = txt_meta$key_terms_n,
    placeholder_used = txt_meta$placeholder_used
  )
}

cli <- parse_cli(commandArgs(trailingOnly = TRUE))
resolved <- resolve_input_data(cli$input)
input_path <- resolved$source_path
raw <- resolved$data

col_id <- first_existing(raw, c("ID", "id", "Jnro", "NRO"))
col_age <- first_existing(raw, c("age"))
col_sex <- first_existing(raw, c("sex"))
col_bmi <- first_existing(raw, c("BMI"))
col_fof <- first_existing(raw, c("FOF_status", "kaatumisenpelkoOn"))
col_balance <- first_existing(raw, c(cli$balance_var, "tasapainovaikeus"))
col_cz0 <- first_existing(raw, c("Composite_Z0", "ToimintaKykySummary0", "Composite_Z_baseline"))
col_cz12 <- first_existing(raw, c("Composite_Z12", "ToimintaKykySummary2", "Composite_Z_12m"))
col_fcat <- first_existing(raw, c("frailty_cat_3", "frailty_cat"))
col_fscore <- first_existing(raw, c("frailty_score_3", "frailty_score"))

frailty_score_source <- "K15_RData"
frailty_cat_source <- "K15_RData"
derived_rule <- NA_character_
fallback_notes <- "none"

req_common <- c(col_id, col_age, col_sex, col_bmi, col_fof, col_cz0, col_cz12)
if (any(is.na(req_common))) {
  stop("Missing required columns after mapping. Required mapped vars: ID/age/sex/BMI/FOF/Composite_Z0/Composite_Z12")
}
if (isTRUE(cli$run_cat) && is.na(col_fcat)) {
  stop("Missing required canonical frailty column(s): frailty_cat_3")
}
if (isTRUE(cli$run_score) && is.na(col_fscore)) {
  stop("Missing required canonical frailty column(s): frailty_score_3")
}
fallback_used <- FALSE

wide <- raw %>%
  transmute(
    ID = as.character(.data[[col_id]]),
    age = suppressWarnings(as.numeric(.data[[col_age]])),
    sex = normalize_sex(.data[[col_sex]]),
    BMI = suppressWarnings(as.numeric(.data[[col_bmi]])),
    FOF_status = normalize_fof(.data[[col_fof]]),
    Balance_problem = if (!is.na(col_balance)) suppressWarnings(as.numeric(.data[[col_balance]])) else NA_real_,
    Composite_Z0 = suppressWarnings(as.numeric(.data[[col_cz0]])),
    Composite_Z12 = suppressWarnings(as.numeric(.data[[col_cz12]])),
    frailty_cat_3 = if (!is.na(col_fcat)) normalize_frailty_cat(.data[[col_fcat]]) else factor(NA),
    frailty_score_3 = if (!is.na(col_fscore)) suppressWarnings(as.numeric(.data[[col_fscore]])) else NA_real_
  )

if (all(is.na(wide$FOF_status))) stop("FOF mapping produced all NA.")
if (all(is.na(wide$Composite_Z0)) || all(is.na(wide$Composite_Z12))) stop("Composite_Z0/12 is all NA after mapping.")
if (isTRUE(cli$run_cat) && all(is.na(wide$frailty_cat_3))) {
  stop("Missing required canonical frailty column(s): frailty_cat_3 is all NA after mapping.")
}
if (isTRUE(cli$run_score) && all(is.na(wide$frailty_score_3))) {
  stop("Missing required canonical frailty column(s): frailty_score_3 is all NA after mapping.")
}

wide <- wide %>% mutate(cComposite_Z0 = Composite_Z0 - mean(Composite_Z0, na.rm = TRUE))

long_df <- wide %>%
  select(ID, age, sex, BMI, FOF_status, Balance_problem, frailty_cat_3, frailty_score_3, cComposite_Z0, Composite_Z0, Composite_Z12) %>%
  pivot_longer(cols = c("Composite_Z0", "Composite_Z12"), names_to = "time_raw", values_to = "Composite_Z") %>%
  mutate(
    time_f = ifelse(time_raw == "Composite_Z0", "0", "12"),
    time_f = factor(time_f, levels = c("0", "12"))
  ) %>%
  select(-time_raw)

# Ensure unique ID x time rows
key_dups <- long_df %>% count(ID, time_f) %>% filter(n > 1)
if (nrow(key_dups) > 0) stop("Duplicate ID×time_f rows detected after long transform.")

results <- list()
if (isTRUE(cli$run_cat)) results[["cat"]] <- run_mode("cat", long_df, cli$include_balance)
if (isTRUE(cli$run_score)) results[["score"]] <- run_mode("score", long_df, cli$include_balance)

# Provenance/QC trace artifact
prov_path <- file.path(out_subdir, "K26_frailty_provenance.txt")
n_wide <- dplyr::n_distinct(wide$ID)
n_long <- nrow(long_df)
mode_lines <- unlist(lapply(names(results), function(mm) {
  rr <- results[[mm]]
  c(
    paste0("[mode=", mm, "] n_complete=", rr$n_complete),
    paste0("[mode=", mm, "] key_terms_n=", rr$key_terms_n),
    paste0("[mode=", mm, "] placeholder_used=", rr$placeholder_used),
    paste0("[mode=", mm, "] crosscheck_ok=", rr$crosscheck_ok)
  )
}), use.names = FALSE)

prov_lines <- c(
  "K26 frailty provenance",
  paste0("input_path=", input_path),
  paste0("frailty_score_source=", frailty_score_source),
  paste0("frailty_cat_source=", frailty_cat_source),
  paste0("derived_rule=", ifelse(is.na(derived_rule), "none", derived_rule)),
  paste0("fallback_used=", fallback_used),
  paste0("fallback_notes=", fallback_notes),
  paste0("n_wide_unique_id=", n_wide),
  paste0("n_long_rows=", n_long),
  mode_lines
)
writeLines(prov_lines, con = prov_path)
append_artifact("K26_frailty_provenance_txt", "txt", prov_path, notes = "K26 frailty source/fallback/crosscheck trace")

session_path <- file.path(out_subdir, "sessionInfo.txt")
session_lines <- capture.output(sessionInfo())
if (requireNamespace("renv", quietly = TRUE)) {
  session_lines <- c(session_lines, "", "---- renv diagnostics ----", capture.output(renv::diagnostics()))
}
writeLines(session_lines, con = session_path)
append_artifact("K26_sessionInfo", "sessioninfo", session_path, notes = "K26 sessionInfo + renv diagnostics")

cat("Saved K26 artifacts to: ", out_subdir, "\n", sep = "")
for (nm in names(results)) {
  cat(" - mode=", nm, ": ", results[[nm]]$txt, "\n", sep = "")
}
cat(" - session: ", session_path, "\n", sep = "")
