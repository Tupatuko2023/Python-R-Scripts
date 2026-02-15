#!/usr/bin/env Rscript
# ==============================================================================
# 10_table1_patient_characteristics_by_fof.R
# Purpose: Produce publication-ready baseline Table 1 by Fear of Falling (FOF)
#
# SECURITY / PRIVACY (fail-closed):
# - Never print row-level data (no head(), View(), dput(), etc.)
# - Never print absolute paths; redact DATA_ROOT and getwd() in logs/console
# - Only export aggregated outputs when ALLOW_AGGREGATES == "1"
# - Apply N<5 suppression to all table cells (cells become "Suppressed"; p-values suppressed too)
#
# INPUT discovery (DATA_ROOT must be set):
#  1) DATA_ROOT/paper_02/KAAOS_data_sotullinen.xlsx (primary baseline runko)
#  2) DATA_ROOT/derived/kaatumisenpelko.csv         (alternative)
#  3) DATA_ROOT/data/kaatumisenpelko.csv            (alternative)
#
# TABLE 1 SOURCE OF TRUTH:
# - Baseline cohort from aim2_panel.csv (N≈486)
# - Frailty from frailty_cat_3 (precomputed baseline frailty)
# - See docs/TABLE_1_HANDOVER.md
#
# OUTPUTS (repo-relative):
#  - R/10_table1/outputs/table1_patient_characteristics_by_fof.csv
#  - (optional) R/10_table1/outputs/table1_patient_characteristics_by_fof.html
#  - (optional) R/10_table1/outputs/table1_patient_characteristics_by_fof.docx
#  - R/10_table1/logs/table1_run_metadata.txt
# ==============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(readxl)
  library(tidyr)
  library(stringr)
})

# ----------------------------
# A) Config & secure logging
# ----------------------------
DATA_ROOT <- Sys.getenv("DATA_ROOT", unset = "")
if (DATA_ROOT == "") stop("DATA_ROOT puuttuu (ympäristömuuttuja).")

ALLOW_AGGREGATES <- Sys.getenv("ALLOW_AGGREGATES", unset = "") == "1"

# Optional exports (only if ALLOW_AGGREGATES==1)
EXPORT_HTML <- Sys.getenv("EXPORT_HTML", unset = "0") == "1"
EXPORT_DOCX <- Sys.getenv("EXPORT_DOCX", unset = "0") == "1"
DISABLE_SUPPRESSION <- Sys.getenv("DISABLE_SUPPRESSION", unset = "1") == "1"

# Robust project root discovery & security bootstrap
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)
script_path <- if (length(file_arg) > 0) sub("^--file=", "", file_arg[1]) else NA_character_
script_dir <- if (!is.na(script_path)) dirname(normalizePath(script_path, mustWork = FALSE)) else getwd()
project_dir <- script_dir
while (basename(project_dir) %in% c("R", "scripts", "10_table1", "security", "outputs", "logs")) {
  project_dir <- dirname(project_dir)
}
source(file.path(project_dir, "R", "bootstrap.R"))

outputs_dir <- file.path(project_dir, "R", "10_table1", "outputs")
logs_dir    <- file.path(project_dir, "R", "10_table1", "logs")

dir.create(outputs_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(logs_dir,    showWarnings = FALSE, recursive = TRUE)
blocked_path <- file.path(outputs_dir, "table1_patient_characteristics_by_fof.BLOCKED.txt")

# Ensure stale BLOCKED marker never persists across runs
if (file.exists(blocked_path)) {
  invisible(file.remove(blocked_path))
}

abs_path_regex <- "(^|[[:space:]])(/[^[:space:]]+)"
redact_paths <- function(x) {
  if (length(x) == 0) return(x)
  x <- gsub(DATA_ROOT, "<DATA_ROOT>", x, fixed = TRUE)
  x <- gsub(getwd(), "<REPO_ROOT>", x, fixed = TRUE)
  x <- gsub(abs_path_regex, "\\1<ABS_PATH>", x, perl = TRUE)
  x
}

log_msg <- function(...) {
  msg <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " | ", paste0(..., collapse = ""))
  message(redact_paths(msg))
}

write_log <- function(path, lines) {
  writeLines(redact_paths(lines), con = path, useBytes = TRUE)
}

write_metadata <- function() {
  # Metadata-only log (no data, no abs paths)
  meta_path <- file.path(logs_dir, "table1_run_metadata.txt")
  meta_lines <- c(
    paste0("timestamp: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
    paste0("data_root_set: ", Sys.getenv("DATA_ROOT") != ""),
    paste0("allow_aggregates_env: ", ALLOW_AGGREGATES),
    paste0("export_html_requested: ", EXPORT_HTML),
    paste0("export_docx_requested: ", EXPORT_DOCX),
    paste0("R.version: ", R.version.string)
  )
  write_log(meta_path, meta_lines)
}

log_msg("Table 1 run started (secure).")
log_msg("ALLOW_AGGREGATES enabled: ", ALLOW_AGGREGATES)
log_msg("Suppression disabled: ", DISABLE_SUPPRESSION)

# ----------------------------
# B) Locate & read input data
# ----------------------------
bmi_candidates <- c("BMI","bmi","Painoindeksi (BMI)","painoindeksi","painoindeksi_bmi")

locate_input <- function(data_root) {
  candidates <- list(
    c("paper_02", "KAAOS_data_sotullinen.xlsx"),
    c("derived",  "kaatumisenpelko.csv"),
    c("data",     "kaatumisenpelko.csv")
  )
  first_existing <- NA_character_
  for (parts in candidates) {
    p <- tryCatch(do.call(safe_join_path, as.list(c(data_root, parts))), error = function(e) NA_character_)
    if (is.na(p)) next

    if (file.exists(p) && file.access(p, 4) == 0) {
      if (is.na(first_existing)) first_existing <- p
      if (grepl("\\.xlsx?$", p, ignore.case = TRUE)) return(p)
      hdr <- readr::read_csv(p, n_max = 0, show_col_types = FALSE, progress = FALSE)
      if (any(names(hdr) %in% bmi_candidates)) return(p)
    }
  }
  return(first_existing)
}

input_path <- locate_input(DATA_ROOT)
if (is.na(input_path)) {
  stop("Syötedataa ei löydy. Etsitty: derived/kaatumisenpelko.csv, derived/aim2_panel.csv, data/kaatumisenpelko.csv (DATA_ROOT:n alta).")
}

# IMPORTANT: do not print absolute input_path
log_msg("Input found (path redacted). Reading data...")
log_msg("Input selected: ", basename(input_path))

if (grepl("\\.xlsx?$", input_path, ignore.case = TRUE)) {
  df_raw <- readxl::read_excel(input_path, skip = 1, col_names = TRUE)
} else {
  df_raw <- readr::read_csv(input_path, show_col_types = FALSE, progress = FALSE)
}

# ----------------------------
# C) Column mapping (no guessing)
# ----------------------------
normalize_header <- function(x) {
  # normalize whitespace (incl. NBSP) and trim for safe header matching
  x <- gsub("\u00A0", " ", x, fixed = TRUE)
  x <- gsub("[[:space:]]+", " ", x)
  trimws(x)
}

normalize_id <- function(x) {
  x <- trimws(as.character(x))
  x <- gsub("\\D", "", x)
  x[x == ""] <- NA_character_
  x
}

normalize_nro <- function(x) {
  x <- trimws(as.character(x))
  x[x == ""] <- NA_character_
  num <- suppressWarnings(as.numeric(x))
  out <- ifelse(!is.na(num), as.character(num), NA_character_)
  out
}

pick_col_optional <- function(df_names, target, candidates) {
  hits <- intersect(df_names, candidates)
  if (length(hits) == 1) return(hits)
  if (length(hits) == 0) {
    norm_df <- normalize_header(df_names)
    norm_candidates <- normalize_header(candidates)
    norm_hits <- df_names[norm_df %in% norm_candidates]
    if (length(norm_hits) == 1) return(norm_hits)
    if (length(norm_hits) > 1) {
      stop(paste0(
        "Epäselvä mappaus (useita osumia) targetille ", target, " (normalized match): ",
        paste(norm_hits, collapse = ", "), "\n",
        "Anna yksiselitteinen mappaus: ", target, " = <dataset_column_name>"
      ))
    }
    return(NA_character_)
  }
  stop(paste0(
    "Epäselvä mappaus (useita osumia) targetille ", target, ": ",
    paste(hits, collapse = ", "), "\n",
    "Anna yksiselitteinen mappaus: ", target, " = <dataset_column_name>"
  ))
}

pick_col <- function(df_names, target, candidates) {
  hits <- intersect(df_names, candidates)
  if (length(hits) == 1) return(hits)
  if (length(hits) == 0) {
    norm_df <- normalize_header(df_names)
    norm_candidates <- normalize_header(candidates)
    norm_hits <- df_names[norm_df %in% norm_candidates]
    if (length(norm_hits) == 1) return(norm_hits)
    if (length(norm_hits) > 1) {
      stop(paste0(
        "Epäselvä mappaus (useita osumia) targetille ", target, " (normalized match): ",
        paste(norm_hits, collapse = ", "), "\n",
        "Anna yksiselitteinen mappaus: ", target, " = <dataset_column_name>"
      ))
    }
  }
  if (length(hits) == 0 && target == "BMI") {
    matches <- df_names[grepl("bmi|paino|indeksi", tolower(df_names))]
    message("BMI candidate columns: ", paste(matches, collapse = ", "))
  }
  if (length(hits) == 0) {
    stop(paste0(
      "Puuttuva sarake (tarvitaan mappaus): ", target, "\n",
      "Ehdotetut nimet eivät löytyneet. Anna mappaus muodossa: ", target, " = <dataset_column_name>"
    ))
  }
  stop(paste0(
    "Epäselvä mappaus (useita osumia) targetille ", target, ": ",
    paste(hits, collapse = ", "), "\n",
    "Anna yksiselitteinen mappaus: ", target, " = <dataset_column_name>"
  ))
}

# Candidate lists (prefer known project conventions; stop() if ambiguous/missing)
nm <- names(df_raw)

id_candidates <- c("id","ID","Id","henkilotunnus","Henkilotunnus","sotu","Sotu","SOTU")

pick_col_regex <- function(df_names, target, patterns) {
  df_norm <- normalize_header(df_names)
  hits <- integer()
  for (pat in patterns) {
    m <- grep(pat, df_norm, ignore.case = TRUE)
    if (length(m) > 0) hits <- unique(c(hits, m))
  }
  if (length(hits) == 1) return(df_names[hits[1]])
  if (length(hits) == 0) {
    stop(paste0(
      "Puuttuva sarake (tarvitaan mappaus): ", target, "\n",
      "Anna mappaus muodossa: ", target, " = <dataset_column_name>"
    ))
  }
  stop(paste0(
    "Epäselvä mappaus (useita osumia) targetille ", target, ": ",
    paste(df_names[hits], collapse = ", "), "\n",
    "Anna yksiselitteinen mappaus: ", target, " = <dataset_column_name>"
  ))
}

pick_col_regex_first <- function(df_names, target, patterns) {
  df_norm <- normalize_header(df_names)
  for (pat in patterns) {
    m <- grep(pat, df_norm, ignore.case = TRUE)
    if (length(m) == 1) return(df_names[m[1]])
    if (length(m) > 1) {
      stop(paste0(
        "Epäselvä mappaus (useita osumia) targetille ", target, ": ",
        paste(df_names[m], collapse = ", "), "\n",
        "Anna yksiselitteinen mappaus: ", target, " = <dataset_column_name>"
      ))
    }
  }
  stop(paste0(
    "Puuttuva sarake (tarvitaan mappaus): ", target, "\n",
    "Anna mappaus muodossa: ", target, " = <dataset_column_name>"
  ))
}

pick_col_regex_optional <- function(df_names, target, patterns) {
  df_norm <- normalize_header(df_names)
  for (pat in patterns) {
    m <- grep(pat, df_norm, ignore.case = TRUE)
    if (length(m) == 1) return(df_names[m[1]])
    if (length(m) > 1) {
      stop(paste0(
        "Epäselvä mappaus (useita osumia) targetille ", target, ": ",
        paste(df_names[m], collapse = ", "), "\n",
        "Anna yksiselitteinen mappaus: ", target, " = <dataset_column_name>"
      ))
    }
  }
  NA_character_
}

col_id      <- pick_col_regex_first(nm, "id", c("^nro$", "^potilas", "^sotu$", "^henkilotunnus"))
col_fof     <- pick_col_regex(nm, "FOF", c("^kaatumisen pelko\\s*\\(0="))
col_sex     <- pick_col_regex(nm, "sex", c("^sukupuoli", "^sex"))
col_age     <- pick_col_regex(nm, "age", c("^ikä", "^age"))
col_bmi     <- pick_col_regex(nm, "BMI", c("^BMI", "painoindeksi"))
col_smoker  <- pick_col_regex(nm, "smoker", c("^tupakointi", "^smoker", "^smoking"))
col_alcohol <- pick_col_regex(nm, "alcohol", c("^alkoholi", "^alcohol"))
col_dm      <- pick_col_regex(nm, "DM", c("^diabetes", "^dm$"))
col_ad      <- pick_col_regex(nm, "AD", c("^alzheimer", "^ad$"))
col_cva     <- pick_col_regex(nm, "CVA", c("^AVH", "^CVA", "stroke"))
col_srh     <- pick_col_regex(nm, "SRH", c("^koettu terveydentila", "^SRH"))
col_fallen  <- pick_col_regex(nm, "fallen", c("^kaatuminen\\s*\\("))
col_balance <- pick_col_regex(nm, "balance_difficulties", c("^tasapaino-? ?vaikeudet"))
col_fract   <- pick_col_regex(nm, "fractures", c("^murtumia"))
col_walk500 <- pick_col_regex(nm, "walk500", c("^500m vaikeus liikkua"))
col_ftsst   <- pick_col_regex(nm, "FTSST_seconds", c("^TK: Tuolilta nousu", "^FTSST"))
col_ability <- pick_col_regex(nm, "ability_out_of_home", c("^kodin ulkopuolella asiointi"))
col_frailty <- if ("frailty_cat_3" %in% nm) "frailty_cat_3" else NA_character_
col_visit_date <- pick_col_regex_optional(nm, "baseline_visit_date", c("kaao[s]?\\s*vastaan", "vastaan-otto", "käynti.*pvm", "pvm"))

# Deduplicate baseline to one row per NRO (prefer earliest visit date if available)
if (!is.na(col_id)) {
  is_nro <- grepl("^nro$", normalize_header(col_id), ignore.case = TRUE)
  df_raw <- df_raw %>%
    mutate(
      id_key = if (is_nro) normalize_nro(.data[[col_id]]) else normalize_id(.data[[col_id]]),
      visit_date = if (!is.na(col_visit_date)) suppressWarnings(as.Date(.data[[col_visit_date]], format = "%d.%m.%Y")) else as.Date(NA)
    ) %>%
    arrange(id_key, visit_date) %>%
    group_by(id_key) %>%
    slice(1) %>%
    ungroup() %>%
    select(-id_key, -visit_date)
}

# ----------------------------
# D) Robust recoding helpers
# ----------------------------
normalize_fof <- function(x) {
  # Accept: 0/1, 1/2, "No/Yes", "Ei/Kyllä", etc.
  if (is.numeric(x) || is.integer(x)) {
    ux <- sort(unique(x[!is.na(x)]))
    # Common: 0/1
    if (all(ux %in% c(0, 1))) return(factor(ifelse(x == 1, "Yes", ifelse(x == 0, "No", NA_character_)), levels = c("No","Yes")))
    # Common: 0/1/2 where 2=Unknown
    if (all(ux %in% c(0, 1, 2))) return(factor(ifelse(x == 1, "Yes", ifelse(x == 0, "No", NA_character_)), levels = c("No","Yes")))
    # Common: 1/2 where 1=No 2=Yes
    if (all(ux %in% c(1, 2))) return(factor(ifelse(x == 2, "Yes", ifelse(x == 1, "No", NA_character_)), levels = c("No","Yes")))
  }
  x_chr <- tolower(trimws(as.character(x)))
  no_set  <- c("0","no","n","ei","false","f","non","none")
  yes_set <- c("1","yes","y","kyllä","kylla","true","t","oui")
  out <- ifelse(x_chr %in% yes_set, "Yes",
                ifelse(x_chr %in% no_set, "No", NA_character_))
  factor(out, levels = c("No","Yes"))
}

normalize_binary01 <- function(x) {
  # Returns integer 0/1 with NA for missing/unknown
  if (is.numeric(x) || is.integer(x)) {
    ux <- sort(unique(x[!is.na(x)]))
    if (all(ux %in% c(0, 1))) return(as.integer(x))
    if (all(ux %in% c(1, 2))) return(as.integer(ifelse(x == 2, 1L, ifelse(x == 1, 0L, NA_integer_))))
  }
  x_chr <- tolower(trimws(as.character(x)))
  no_set  <- c("0","no","n","ei","false","f")
  yes_set <- c("1","yes","y","kyllä","kylla","true","t")
  as.integer(ifelse(x_chr %in% yes_set, 1L,
                    ifelse(x_chr %in% no_set, 0L, NA_integer_)))
}

normalize_binary012 <- function(x, label) {
  x_chr <- tolower(trimws(as.character(x)))
  x_chr[x_chr %in% c("", "e", "e1")] <- NA_character_
  x_chr <- ifelse(grepl("^\\s*[0-9]+\\s*=", x_chr), sub("^\\s*([0-9]+)\\s*=.*$", "\\1", x_chr), x_chr)
  x_chr <- ifelse(grepl("^\\s*[0-9]+\\s*$", x_chr), sub("^\\s*([0-9]+)\\s*$", "\\1", x_chr), x_chr)
  x_chr <- ifelse(x_chr %in% c("kyllä","kylla","yes","y","true","t","k"), "1", x_chr)
  x_chr <- ifelse(x_chr %in% c("ei","no","n","false","f"), "0", x_chr)
  x_chr <- ifelse(x_chr %in% c("ei tietoa","unknown","missing","na","n/a"), "2", x_chr)
  invalid <- !is.na(x_chr) & !x_chr %in% c("0","1","2")
  if (any(invalid)) {
    log_msg("Out-of-spec codes for ", label, ": ", sum(invalid), " coerced to NA.")
    x_chr[invalid] <- NA_character_
  }
  as.integer(ifelse(x_chr == "1", 1L, ifelse(x_chr == "0", 0L, NA_integer_)))
}

normalize_walk500 <- function(x) {
  x_chr <- tolower(trimws(as.character(x)))
  x_chr[x_chr %in% c("", "e", "e1")] <- NA_character_
  x_chr <- ifelse(grepl("^\\s*[0-9]+\\s*=", x_chr), sub("^\\s*([0-9]+)\\s*=.*$", "\\1", x_chr), x_chr)
  x_chr <- ifelse(grepl("^\\s*[0-9]+\\s*$", x_chr), sub("^\\s*([0-9]+)\\s*$", "\\1", x_chr), x_chr)
  invalid <- !is.na(x_chr) & !x_chr %in% c("0","1","2","3")
  if (any(invalid)) {
    log_msg("Out-of-spec codes for walk500: ", sum(invalid), " coerced to NA.")
    x_chr[invalid] <- NA_character_
  }
  as.integer(ifelse(x_chr %in% c("1","2"), 1L, ifelse(x_chr == "0", 0L, NA_integer_)))
}

normalize_alcohol <- function(x) {
  x_chr <- tolower(trimws(as.character(x)))
  x_chr[x_chr %in% c("", "e", "e1")] <- NA_character_
  x_chr <- ifelse(grepl("^\\s*[0-9]+\\s*=", x_chr), sub("^\\s*([0-9]+)\\s*=.*$", "\\1", x_chr), x_chr)
  x_chr <- ifelse(grepl("^\\s*[0-9]+\\s*$", x_chr), sub("^\\s*([0-9]+)\\s*$", "\\1", x_chr), x_chr)
  invalid <- !is.na(x_chr) & !x_chr %in% c("0","1","2","3")
  if (any(invalid)) {
    log_msg("Out-of-spec codes for alcohol: ", sum(invalid), " coerced to NA.")
    x_chr[invalid] <- NA_character_
  }
  as.integer(ifelse(x_chr %in% c("1","2"), 1L, ifelse(x_chr == "0", 0L, NA_integer_)))
}

women_from_sex <- function(x) {
  # Women indicator (1=female, 0=male), robust to common codings:
  # - 1=M 2=F (common in project)
  # - 0=F 1=M (also possible)
  # - strings "F"/"Female"/"Nainen"
  if (is.numeric(x) || is.integer(x)) {
    ux <- sort(unique(x[!is.na(x)]))
    if (all(ux %in% c(1, 2))) return(as.integer(ifelse(x == 2, 1L, ifelse(x == 1, 0L, NA_integer_))))
    if (all(ux %in% c(0, 1))) {
      # ambiguous: could be 0=F 1=M OR 0=M 1=F
      # Conservative rule: if values are 0/1, assume 0=F,1=M (as seen in aim2_analysis dictionary)
      return(as.integer(ifelse(x == 0, 1L, ifelse(x == 1, 0L, NA_integer_))))
    }
  }
  xc <- tolower(trimws(as.character(x)))
  female_set <- c("f","female","woman","women","nainen","nais","2")
  male_set   <- c("m","male","man","men","mies","1")
  as.integer(ifelse(xc %in% female_set, 1L,
                    ifelse(xc %in% male_set, 0L, NA_integer_)))
}

recode_srh_3 <- function(x) {
  # Target levels: Good/Excellent, Moderate, Bad
  xc <- tolower(trimws(as.character(x)))

  # Treat E1 as missing
  xc[xc == "e1"] <- NA_character_

  # Handle numeric-like string codes 0..5
  num <- suppressWarnings(as.integer(xc))
  is_code <- !is.na(num) & num %in% 0:5
  out <- rep(NA_character_, length(xc))
  out[is_code & num %in% c(0,1)] <- "Good/Excellent"
  out[is_code & num == 2]        <- "Moderate"
  out[is_code & num %in% c(3,4)] <- "Bad"
  # num==5 remains NA ("ei tietoa")

  # Fallback for text-based labels
  idx_other <- is.na(out) & !is.na(xc)
  if (any(idx_other)) {
    out[idx_other] <- dplyr::case_when(
      str_detect(xc[idx_other], "excellent|erinomain") ~ "Good/Excellent",
      str_detect(xc[idx_other], "good|hyv")           ~ "Good/Excellent",
      str_detect(xc[idx_other], "moderate|kohtal")    ~ "Moderate",
      str_detect(xc[idx_other], "bad|poor|huon|melko huono") ~ "Bad",
      TRUE ~ NA_character_
    )
  }

  factor(out, levels = c("Good/Excellent","Moderate","Bad"))
}

recode_ability_3 <- function(x) {
  # Target levels: Without difficulties, With difficulties, Unable independently
  if (is.numeric(x) || is.integer(x)) {
    ux <- sort(unique(x[!is.na(x)]))
    # Assumption: 1..3 increasing difficulty
    if (all(ux %in% 1:3)) {
      out <- dplyr::case_when(
        x == 1 ~ "Without difficulties",
        x == 2 ~ "With difficulties",
        x == 3 ~ "Unable independently",
        TRUE ~ NA_character_
      )
      return(factor(out, levels = c("Without difficulties","With difficulties","Unable independently")))
    }
    # Alternative: 0..2 increasing difficulty (0=no difficulties, 1=difficulties, 2=unable)
    if (all(ux %in% 0:2)) {
      out <- dplyr::case_when(
        x == 0 ~ "Without difficulties",
        x == 1 ~ "With difficulties",
        x == 2 ~ "Unable independently",
        TRUE ~ NA_character_
      )
      return(factor(out, levels = c("Without difficulties","With difficulties","Unable independently")))
    }
    # Alternative: 0..3 where 3=unknown
    if (all(ux %in% 0:3)) {
      out <- dplyr::case_when(
        x == 0 ~ "Without difficulties",
        x == 1 ~ "With difficulties",
        x == 2 ~ "Unable independently",
        x == 3 ~ NA_character_,
        TRUE ~ NA_character_
      )
      return(factor(out, levels = c("Without difficulties","With difficulties","Unable independently")))
    }
  }
  xc <- tolower(trimws(as.character(x)))
  out <- dplyr::case_when(
    str_detect(xc, "without|ei.*vaike|ilman") ~ "Without difficulties",
    str_detect(xc, "with|vaike")             ~ "With difficulties",
    str_detect(xc, "unable|independ|ei.*onnistu|kykenem") ~ "Unable independently",
    TRUE ~ NA_character_
  )
  factor(out, levels = c("Without difficulties","With difficulties","Unable independently"))
}

recode_frailty_3 <- function(x) {
  # Target levels: robust, pre-frail, frail
  if (is.numeric(x) || is.integer(x)) {
    ux <- sort(unique(x[!is.na(x)]))
    if (all(ux %in% c(0, 1, 2))) {
      out <- dplyr::case_when(
        x == 0 ~ "robust",
        x == 1 ~ "pre-frail",
        x == 2 ~ "frail",
        TRUE ~ NA_character_
      )
      return(factor(out, levels = c("robust","pre-frail","frail")))
    }
    if (all(ux %in% c(1, 2, 3))) {
      out <- dplyr::case_when(
        x == 1 ~ "robust",
        x == 2 ~ "pre-frail",
        x == 3 ~ "frail",
        TRUE ~ NA_character_
      )
      return(factor(out, levels = c("robust","pre-frail","frail")))
    }
  }

  xc <- tolower(trimws(as.character(x)))
  xc[xc %in% c("", "na", "n/a", "missing", "unknown", "ei tietoa", "e1")] <- NA_character_

  out <- dplyr::case_when(
    str_detect(xc, "non[- ]?frail|not[- ]?frail") ~ "robust",
    str_detect(xc, "^robust$|^rob$") ~ "robust",
    str_detect(xc, "pre[- ]?frail|prefrail|pre frail") ~ "pre-frail",
    str_detect(xc, "^frail$") ~ "frail",
    TRUE ~ NA_character_
  )
  factor(out, levels = c("robust","pre-frail","frail"))
}

# ----------------------------
# E) Prepare analysis dataset
# ----------------------------
df <- df_raw %>%
  transmute(
    id = if (!is.na(col_id)) {
      if (grepl("^nro$", normalize_header(col_id), ignore.case = TRUE)) normalize_nro(.data[[col_id]]) else normalize_id(.data[[col_id]])
    } else NA_character_,
    FOF = normalize_fof(.data[[col_fof]]),
    women = women_from_sex(.data[[col_sex]]),
    age = suppressWarnings(as.numeric(.data[[col_age]])),
    bmi = suppressWarnings(as.numeric(.data[[col_bmi]])),
    smoker = normalize_binary012(.data[[col_smoker]], "smoker"),
    alcohol = normalize_alcohol(.data[[col_alcohol]]),
    dm = normalize_binary01(.data[[col_dm]]),
    ad = normalize_binary01(.data[[col_ad]]),
    cva = normalize_binary01(.data[[col_cva]]),
    srh3 = recode_srh_3(.data[[col_srh]]),
    fallen = normalize_binary012(.data[[col_fallen]], "fallen"),
    balance = normalize_binary012(.data[[col_balance]], "balance"),
    fractures = normalize_binary012(.data[[col_fract]], "fractures"),
    walk500 = normalize_walk500(.data[[col_walk500]]),
    ftsst = suppressWarnings(as.numeric(.data[[col_ftsst]])),
    ability3 = recode_ability_3(.data[[col_ability]]),
    frailty3 = if (!is.na(col_frailty)) recode_frailty_3(.data[[col_frailty]]) else NA_character_
  )

load_frailty_lookup <- function(data_root) {
  panel_path <- safe_join_path(data_root, "derived", "aim2_panel.csv")
  if (!file.exists(panel_path)) {
    stop("Frailty lookup source missing: derived/aim2_panel.csv (DATA_ROOT).")
  }
  cw_path <- safe_join_path(data_root, "paper_02", "sotut.xlsx")
  if (!file.exists(cw_path)) {
    stop("Frailty crosswalk missing: paper_02/sotut.xlsx (DATA_ROOT).")
  }
  hdr <- readr::read_csv(panel_path, n_max = 0, show_col_types = FALSE, progress = FALSE)
  panel_names <- names(hdr)
  col_id_panel <- pick_col(panel_names, "id", id_candidates)
  col_frailty_panel <- if ("frailty_fried" %in% panel_names) {
    "frailty_fried"
  } else {
    stop("Frailty lookup source missing: expected frailty_fried in aim2_panel.csv.")
  }
  panel_df <- readr::read_csv(panel_path, show_col_types = FALSE, progress = FALSE)
  if ("period" %in% names(panel_df)) {
    panel_df <- panel_df %>%
      dplyr::select(dplyr::all_of(c(col_id_panel, col_frailty_panel, "period"))) %>%
      dplyr::arrange(.data[[col_id_panel]], .data$period) %>%
      dplyr::group_by(.data[[col_id_panel]]) %>%
      dplyr::slice(1) %>%
      dplyr::ungroup()
  } else {
    panel_df <- panel_df %>%
      dplyr::select(dplyr::all_of(c(col_id_panel, col_frailty_panel))) %>%
      dplyr::arrange(.data[[col_id_panel]]) %>%
      dplyr::group_by(.data[[col_id_panel]]) %>%
      dplyr::slice(1) %>%
      dplyr::ungroup()
  }
  if (nrow(panel_df) < 470) {
    stop(paste0(
      "CRITICAL ERROR: panel_dedup cohort too small. Found N=",
      nrow(panel_df),
      ", expected N≈477+. Check panel source/dedup."
    ))
  }
  cw <- readxl::read_excel(cw_path, col_names = TRUE)
  col_cw_nro <- pick_col_regex_first(names(cw), "crosswalk NRO", c("^NRO$"))
  col_cw_sotu <- pick_col_regex_first(names(cw), "crosswalk Sotu", c("^Sotu$"))
  cw_map <- cw %>%
    transmute(
      sotu_key = normalize_id(.data[[col_cw_sotu]]),
      nro_key = normalize_nro(.data[[col_cw_nro]])
    ) %>%
    filter(!is.na(sotu_key) & !is.na(nro_key))
  cw_map <- cw_map %>%
    mutate(nro_num = suppressWarnings(as.numeric(nro_key))) %>%
    filter(!is.na(nro_num)) %>%
    group_by(sotu_key) %>%
    summarise(nro_key = as.character(min(nro_num)), .groups = "drop")
  if (any(is.na(cw_map$nro_key))) stop("Frailty crosswalk has missing NRO after dedup; abort.")
  panel_df <- panel_df %>%
    transmute(
      panel_key = normalize_id(.data[[col_id_panel]]),
      frailty_raw = .data[[col_frailty_panel]],
      frailty_fried_num = suppressWarnings(as.numeric(as.character(.data[[col_frailty_panel]])))
    ) %>%
    mutate(
      frailty_fried_chr = tolower(trimws(as.character(.data$frailty_raw))),
      frailty3 = dplyr::case_when(
        frailty_fried_chr %in% c("robust", "rob") ~ "robust",
        frailty_fried_chr %in% c("pre-frail", "prefrail", "pre frail") ~ "pre-frail",
        frailty_fried_chr %in% c("frail") ~ "frail",
        frailty_fried_num == 0 ~ "robust",
        frailty_fried_num %in% c(1, 2) ~ "pre-frail",
        frailty_fried_num == 3 ~ "frail",
        is.na(frailty_fried_num) ~ "unknown",
        frailty_fried_num > 3 ~ "unknown",
        TRUE ~ "unknown"
      )
    )
  n_total <- nrow(panel_df)
  n_nonmiss_num <- sum(!is.na(panel_df$frailty_fried_num))
  n_unknown <- sum(panel_df$frailty3 == "unknown")
  if (n_total > 0 && n_unknown == n_total) {
    stop(paste0(
      "CRITICAL: frailty_cat_3 is 100% unknown at panel baseline. ",
      "n_total=", n_total, ", n_nonmiss_num=", n_nonmiss_num,
      "."
    ))
  }
  panel_df %>%
    left_join(cw_map, by = c("panel_key" = "sotu_key")) %>%
    transmute(id = normalize_nro(nro_key), frailty3 = frailty3)
}

if (is.na(col_frailty)) {
  if (is.na(col_id)) stop("Frailty join requires id column; id not found in baseline input.")
  frailty_lookup_raw <- load_frailty_lookup(DATA_ROOT)
  frailty_conf <- frailty_lookup_raw %>%
    filter(!is.na(id)) %>%
    group_by(id) %>%
    summarise(
      n_nonunk = dplyr::n_distinct(frailty3[frailty3 %in% c("robust", "pre-frail", "frail")]),
      .groups = "drop"
    )
  n_conflict <- sum(frailty_conf$n_nonunk > 1)
  if (n_conflict > 0) stop("Frailty lookup has conflicting non-unknown values per id; abort.")
  frailty_lookup <- frailty_lookup_raw %>%
    filter(!is.na(id)) %>%
    group_by(id) %>%
    summarise(
      frailty3 = dplyr::case_when(
        any(frailty3 %in% c("robust", "pre-frail", "frail")) ~
          dplyr::first(frailty3[frailty3 %in% c("robust", "pre-frail", "frail")]),
        TRUE ~ "unknown"
      ),
      .groups = "drop"
    )
  if (anyDuplicated(frailty_lookup$id) > 0) stop("Frailty lookup has duplicate ids; abort.")
  n_before <- nrow(df)
  df <- df %>% left_join(frailty_lookup, by = "id", suffix = c("", ".lk"))
  if (nrow(df) != n_before) stop("Join changed row count; abort.")
  df$frailty3 <- ifelse(is.na(df$frailty3) & !is.na(df$frailty3.lk), df$frailty3.lk, df$frailty3)
  df$frailty3.lk <- NULL
}

ok_frailty_levels <- c("robust", "pre-frail", "frail", "unknown")
frailty_nonmiss <- df$frailty3[!is.na(df$frailty3) & df$frailty3 != "unknown"]
frailty_levels_present <- sort(unique(as.character(frailty_nonmiss)))
if (length(frailty_nonmiss) == 0) {
  stop("Frailty3 recode produced all-NA: check col_frailty mapping (fail-closed).")
}
if (length(frailty_levels_present) < 2) {
  stop("Frailty3 has <2 levels after recode: check source coding (fail-closed).")
}
if (!all(unique(as.character(df$frailty3[!is.na(df$frailty3)])) %in% ok_frailty_levels)) {
  stop("Frailty3 has unexpected levels after recode: ", paste(unique(as.character(df$frailty3[!is.na(df$frailty3)])), collapse = ", "))
}

if (any(is.na(df$FOF))) {
  # missing allowed; but ensure we have both groups present among non-missing
  present <- sort(unique(df$FOF[!is.na(df$FOF)]))
  if (!all(c("No","Yes") %in% present)) stop("FOF-ryhmät eivät muodostu odotetusti (No/Yes). Tarkista FOF-koodaus tai anna mappaus.")
}

df <- df %>%
  filter(!is.na(FOF), !is.na(age) & age >= 65) %>%
  mutate(FOF = droplevels(FOF))

match_rate <- mean(!is.na(df$frailty3) & df$frailty3 != "unknown")
if (match_rate < 0.70) {
  stop(paste0("CRITICAL: frailty join match_rate too low: ", round(match_rate, 3)))
}
message("Table1 sample N: ", nrow(df))
message("Frailty match_rate: ", round(match_rate, 3))
frail_tab <- table(df$frailty3, useNA = "ifany")
message("Frailty distribution: ", paste(names(frail_tab), as.integer(frail_tab), sep = "=", collapse = ", "))
smoke_tab <- table(df$smoker, useNA = "ifany")
message("Smoking distribution: ", paste(names(smoke_tab), as.integer(smoke_tab), sep = "=", collapse = ", "))

N_no  <- sum(df$FOF == "No",  na.rm = TRUE)
N_yes <- sum(df$FOF == "Yes", na.rm = TRUE)
if (N_no == 0 || N_yes == 0) stop("Toinen FOF-ryhmä on tyhjä (No/Yes).")

# ----------------------------
# F) Formatting helpers
# ----------------------------
fmt_p <- function(p) {
  if (is.na(p)) return(NA_character_)
  if (p < 0.001) return("<0.001")
  sprintf("%.3f", p)
}

fmt_bin <- function(n, denom) {
  if (is.na(n) || is.na(denom) || denom == 0) return(NA_character_)
  pct <- round(100 * n / denom)
  paste0(n, "(", pct, ") [", denom, "]")
}

fmt_cont <- function(mean, sd, denom) {
  if (is.na(mean) || is.na(sd) || is.na(denom) || denom == 0) return(NA_character_)
  paste0(sprintf("%.1f", mean), "(", sprintf("%.1f", sd), ") [", denom, "]")
}

 # N<5 suppression: conservative -> if any contributing cell count < 5, blank the whole cell string
suppress_cell <- function(cell_string) {
  if (DISABLE_SUPPRESSION) cell_string else "Suppressed"
}

# ----------------------------
# G) Test helpers (chi-square / fisher; Welch t-test)
# ----------------------------
p_cat <- function(x, g) {
  # x: factor/character; g: factor with 2 levels
  ok <- !is.na(x) & !is.na(g)
  x <- droplevels(factor(x[ok]))
  g <- droplevels(factor(g[ok]))
  if (nlevels(g) != 2) return(NA_real_)
  tab <- table(x, g)
  if (any(dim(tab) == 0)) return(NA_real_)
  # expected counts
  cs <- suppressWarnings(chisq.test(tab, correct = FALSE))
  use_fisher <- any(cs$expected < 5)
  if (use_fisher) {
    suppressWarnings(fisher.test(tab)$p.value)
  } else {
    cs$p.value
  }
}

p_bin <- function(x01, g) {
  # x01: 0/1 integer
  ok <- !is.na(x01) & !is.na(g)
  x <- factor(ifelse(x01[ok] == 1, "Yes", "No"), levels = c("No","Yes"))
  g <- droplevels(factor(g[ok]))
  tab <- table(x, g)
  cs <- suppressWarnings(chisq.test(tab, correct = FALSE))
  use_fisher <- any(cs$expected < 5)
  if (use_fisher) {
    suppressWarnings(fisher.test(tab)$p.value)
  } else {
    cs$p.value
  }
}

p_t <- function(x, g) {
  ok <- !is.na(x) & !is.na(g)
  x <- x[ok]
  g <- droplevels(factor(g[ok]))
  if (nlevels(g) != 2) return(NA_real_)
  suppressWarnings(t.test(x ~ g)$p.value)  # Welch by default
}

# Determine if p-value must be suppressed due to small cells
small_cells_in_table <- function(tab) {
  any(tab < 5)
}

# ----------------------------
# H) Row builders
# ----------------------------
summ_bin_row <- function(label, x01, g) {
  denom <- tapply(!is.na(x01), g, sum)
  n_yes <- tapply(x01 == 1, g, sum, na.rm = TRUE)

  cell_no  <- fmt_bin(unname(n_yes["No"]),  unname(denom["No"]))
  cell_yes <- fmt_bin(unname(n_yes["Yes"]), unname(denom["Yes"]))

  # suppression rule: if any contributing cell <5 (yes or no) within each group OR denom <5 -> suppress that group's cell
  sup_no  <- is.na(denom["No"])  || denom["No"]  < 5 || n_yes["No"]  < 5 || (denom["No"]  - n_yes["No"])  < 5
  sup_yes <- is.na(denom["Yes"]) || denom["Yes"] < 5 || n_yes["Yes"] < 5 || (denom["Yes"] - n_yes["Yes"]) < 5

  # p-value suppression: if any cell in 2x2 is <5
  tab <- table(factor(ifelse(x01 == 1, "Yes", "No"), levels = c("No","Yes")), g, useNA = "no")
  sup_p <- small_cells_in_table(tab)

  p <- p_bin(x01, g)
  p_str <- fmt_p(p)

  if (!DISABLE_SUPPRESSION) {
    if (sup_no)  cell_no  <- suppress_cell(cell_no)
    if (sup_yes) cell_yes <- suppress_cell(cell_yes)
    if (sup_p)   p_str    <- suppress_cell(p_str)
  }

  tibble::tibble(
    Variable = label,
    No = cell_no,
    Yes = cell_yes,
    `P-value` = p_str
  )
}

summ_cont_row <- function(label, x, g) {
  denom <- tapply(!is.na(x), g, sum)
  mn <- tapply(x, g, function(v) mean(v, na.rm = TRUE))
  sdv <- tapply(x, g, function(v) sd(v, na.rm = TRUE))

  cell_no  <- fmt_cont(unname(mn["No"]),  unname(sdv["No"]),  unname(denom["No"]))
  cell_yes <- fmt_cont(unname(mn["Yes"]), unname(sdv["Yes"]), unname(denom["Yes"]))

  # suppression: denom <5 => suppress cell AND p-value
  sup_no  <- is.na(denom["No"])  || denom["No"]  < 5
  sup_yes <- is.na(denom["Yes"]) || denom["Yes"] < 5
  sup_p   <- sup_no || sup_yes

  p <- p_t(x, g)
  p_str <- fmt_p(p)

  if (!DISABLE_SUPPRESSION) {
    if (sup_no)  cell_no  <- suppress_cell(cell_no)
    if (sup_yes) cell_yes <- suppress_cell(cell_yes)
    if (sup_p)   p_str    <- suppress_cell(p_str)
  }

  tibble::tibble(
    Variable = label,
    No = cell_no,
    Yes = cell_yes,
    `P-value` = p_str
  )
}

summ_multicat <- function(header_label, x_factor, g, level_labels_in_order) {
  # Header row shows only denom: "[denom]" and p-value for distribution
  denom <- tapply(!is.na(x_factor), g, sum)
  denom_no  <- unname(denom["No"])
  denom_yes <- unname(denom["Yes"])

  # overall p-value
  p <- p_cat(x_factor, g)
  p_str <- fmt_p(p)

  # suppression: if ANY cell in contingency table <5 -> suppress p and all category cells,
  # and if denom <5 -> suppress denom display too.
  ok <- !is.na(x_factor) & !is.na(g)
  tab <- table(factor(x_factor[ok], levels = level_labels_in_order), g[ok], useNA = "no")
  sup_any <- small_cells_in_table(tab)
  sup_denom_no  <- is.na(denom_no)  || denom_no  < 5
  sup_denom_yes <- is.na(denom_yes) || denom_yes < 5

  header_no  <- paste0("[", denom_no, "]")
  header_yes <- paste0("[", denom_yes, "]")

  if (!DISABLE_SUPPRESSION) {
    if (sup_denom_no)  header_no  <- suppress_cell(header_no)
    if (sup_denom_yes) header_yes <- suppress_cell(header_yes)
    if (sup_any || sup_denom_no || sup_denom_yes) p_str <- suppress_cell(p_str)
  }

  header <- tibble::tibble(
    Variable = header_label,
    No = header_no,
    Yes = header_yes,
    `P-value` = p_str
  )

  # Level rows (no denom, no p-value)
  lev_rows <- lapply(level_labels_in_order, function(lev) {
    x_lev <- as.integer(x_factor == lev)
    denom2 <- tapply(!is.na(x_factor), g, sum)
    n_lev <- tapply(x_lev == 1, g, sum, na.rm = TRUE)

    cell_no  <- if (!is.na(denom2["No"])  && denom2["No"]  > 0) paste0(n_lev["No"],  "(", round(100*n_lev["No"]/denom2["No"]),  ")") else NA_character_
    cell_yes <- if (!is.na(denom2["Yes"]) && denom2["Yes"] > 0) paste0(n_lev["Yes"], "(", round(100*n_lev["Yes"]/denom2["Yes"]), ")") else NA_character_

    # per-cell suppression: if n<5 -> suppress; also if global small-cells -> suppress all
    if (!DISABLE_SUPPRESSION) {
      if (sup_any || (!is.na(n_lev["No"])  && n_lev["No"]  < 5)) cell_no  <- suppress_cell(cell_no)
      if (sup_any || (!is.na(n_lev["Yes"]) && n_lev["Yes"] < 5)) cell_yes <- suppress_cell(cell_yes)
    }

    tibble::tibble(
      Variable = paste0("  ", lev),
      No = cell_no,
      Yes = cell_yes,
      `P-value` = ""
    )
  }) %>% bind_rows()

  bind_rows(header, lev_rows)
}

# ----------------------------
# I) Build Table 1 in required order
# ----------------------------
# Ensure factor levels for multicat rows
df <- df %>%
  mutate(
    srh3 = factor(srh3, levels = c("Good/Excellent","Moderate","Bad")),
    ability3 = factor(ability3, levels = c("Without difficulties","With difficulties","Unable independently")),
    frailty3 = factor(frailty3, levels = c("robust","pre-frail","frail"))
  )

tab1 <- bind_rows(
  summ_bin_row("Women, n (%)", df$women, df$FOF),
  summ_cont_row("Age, mean (SD)", df$age, df$FOF),
  summ_cont_row("BMI, mean (SD)", df$bmi, df$FOF),
  summ_bin_row("Smoker, n (%)", df$smoker, df$FOF),
  summ_bin_row("Alcohol consumption, n (%)", df$alcohol, df$FOF),
  summ_bin_row("DM, n (%)", df$dm, df$FOF),
  summ_bin_row("AD, n (%)", df$ad, df$FOF),
  summ_bin_row("CVA, n (%)", df$cva, df$FOF),
  summ_multicat("Frailty (Fried), n (%)", df$frailty3, df$FOF, c("robust","pre-frail","frail")),
  summ_multicat("SRH, n (%)", df$srh3, df$FOF, c("Good/Excellent","Moderate","Bad")),
  summ_bin_row("Fallen, n (%)", df$fallen, df$FOF),
  summ_bin_row("Balance difficulties, n (%)", df$balance, df$FOF),
  summ_bin_row("Fractures, n (%)", df$fractures, df$FOF),
  summ_bin_row("Difficulties of walking 500 m, n (%)", df$walk500, df$FOF),
  summ_cont_row("FTSST, s, mean (SD)", df$ftsst, df$FOF),
  summ_multicat("Ability to transact out of home", df$ability3, df$FOF,
                c("Without difficulties","With difficulties","Unable independently"))
)

# Rename group columns to include N in header (CSV will contain newline)
colnames(tab1)[colnames(tab1) == "No"]  <- paste0("No\nN=", N_no)
colnames(tab1)[colnames(tab1) == "Yes"] <- paste0("Yes\nN=", N_yes)

# ----------------------------
# J) Export gating (ALLOW_AGGREGATES)
# ----------------------------
out_csv  <- file.path(outputs_dir, "table1_patient_characteristics_by_fof.csv")
out_html <- file.path(outputs_dir, "table1_patient_characteristics_by_fof.html")
out_docx <- file.path(outputs_dir, "table1_patient_characteristics_by_fof.docx")

if (!ALLOW_AGGREGATES) {
  # Fail-closed: do not write table, only safe metadata
  writeLines(
    c(
      "BLOCKED: Aggregated exports are disabled.",
      "Set ALLOW_AGGREGATES=1 to permit writing aggregated outputs."
    ),
    con = blocked_path,
    useBytes = TRUE
  )
  log_msg("ALLOW_AGGREGATES!=1 -> outputs blocked (no table written).")
  write_metadata()
  stop("Aggregaatit eivät ole sallittuja: aseta ALLOW_AGGREGATES=1 (ja aja uudelleen) kirjoittaaksesi Table 1 -tulokset.")
}

# Safe to write aggregated outputs
if (file.exists(blocked_path)) {
  invisible(file.remove(blocked_path))
}
readr::write_csv(tab1, out_csv)
log_msg(paste("Wrote", out_csv))

# Optional HTML via gt (if installed)
if (EXPORT_HTML) {
  if (requireNamespace("gt", quietly = TRUE)) {
    gt_tbl <- gt::gt(tab1) %>%
      gt::tab_header(title = "Table 1. Patient characteristics") %>%
      gt::opt_table_outline() %>%
      gt::opt_row_striping()
    gt::gtsave(gt_tbl, out_html)
    log_msg(paste("Wrote", out_html))
  } else {
    log_msg("EXPORT_HTML=1 but package 'gt' not available; skipping HTML.")
  }
}

# Optional DOCX via flextable/officer (if installed)
if (EXPORT_DOCX) {
  if (requireNamespace("flextable", quietly = TRUE) && requireNamespace("officer", quietly = TRUE)) {
    ft <- flextable::flextable(tab1)
    ft <- flextable::set_caption(ft, "Table 1. Patient characteristics")
    doc <- officer::read_docx()
    doc <- officer::body_add_flextable(doc, ft)
    print(doc, target = out_docx)
    log_msg(paste("Wrote", out_docx))
  } else {
    log_msg("EXPORT_DOCX=1 but packages 'flextable'/'officer' not available; skipping DOCX.")
  }
}

log_msg("Table 1 run completed (secure).")
write_metadata()
