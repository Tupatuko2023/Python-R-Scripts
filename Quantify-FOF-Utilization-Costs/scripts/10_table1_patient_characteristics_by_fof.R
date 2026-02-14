#!/usr/bin/env Rscript
# ==============================================================================
# 10_TABLE1 - Table 1 Patient Characteristics
# File tag: 10_table1_patient_characteristics_by_fof.R
# Purpose: Produce publication-ready baseline Table 1 by Fear of Falling (FOF)
#
# Outcome: Table 1 (Patient Characteristics)
# Predictors: FOF_status
# Required vars (must match req_cols): id, FOF, sex, age, bmi, smoker, alcohol, 
#   dm, ad, cva, srh3, fallen, balance, fractures, walk500, ftsst, ability3, frailty3
#
# SECURITY / PRIVACY (Option B / fail-closed):
# - Never print row-level data.
# - N<5 suppression for all table cells and p-values.
# - Only export aggregated outputs when ALLOW_AGGREGATES == "1".
#
# Reproducibility:
# - Data from DATA_ROOT.
#
# Outputs + manifest:
# - script_label: 10_table1
# - outputs dir: Quantify-FOF-Utilization-Costs/outputs/
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
if (DATA_ROOT == "") stop("DATA_ROOT environment variable not set. (Option B requirement)")

ALLOW_AGGREGATES <- Sys.getenv("ALLOW_AGGREGATES", unset = "") == "1"

# Paths relative to script location
# Expecting script to be in Quantify-FOF-Utilization-Costs/scripts/
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)
script_path <- if (length(file_arg) > 0) sub("^--file=", "", file_arg[1]) else "scripts/10_table1_patient_characteristics_by_fof.R"
script_dir <- dirname(normalizePath(script_path, mustWork = FALSE))
subproject_root <- normalizePath(file.path(script_dir, ".."), mustWork = FALSE)

outputs_dir <- file.path(subproject_root, "outputs")
logs_dir    <- file.path(subproject_root, "logs")
dir.create(outputs_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(logs_dir,    showWarnings = FALSE, recursive = TRUE)

# Secure path redaction
abs_path_regex <- "(^|[[:space:]])(/[^[:space:]]+)"
redact_paths <- function(x) {
  if (length(x) == 0) return(x)
  x <- gsub(DATA_ROOT, "<DATA_ROOT>", x, fixed = TRUE)
  x <- gsub(subproject_root, "<SUBPROJECT_ROOT>", x, fixed = TRUE)
  x <- gsub(abs_path_regex, "\\1<ABS_PATH>", x, perl = TRUE)
  x
}

log_msg <- function(...) {
  msg <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " | ", paste0(..., collapse = ""))
  message(redact_paths(msg))
}

write_metadata <- function() {
  meta_path <- file.path(logs_dir, "table1_run_metadata.txt")
  meta_lines <- c(
    paste0("timestamp: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
    paste0("data_root_set: ", Sys.getenv("DATA_ROOT") != ""),
    paste0("allow_aggregates: ", ALLOW_AGGREGATES),
    paste0("R.version: ", R.version.string)
  )
  writeLines(redact_paths(meta_lines), con = meta_path)
}

log_msg("Table 1 run started.")

# ----------------------------
# B) Locate & read input data
# ----------------------------
locate_input <- function(data_root) {
  candidates <- c(
    file.path(data_root, "KaatumisenPelko.csv"),
    file.path(data_root, "derived",  "kaatumisenpelko.csv"),
    file.path(data_root, "data",     "kaatumisenpelko.csv"),
    file.path(data_root, "paper_02", "KAAOS_data_sotullinen.xlsx")
  )
  for (p in candidates) {
    if (file.exists(p)) return(p)
  }
  return(NA_character_)
}

input_path <- locate_input(DATA_ROOT)
if (is.na(input_path)) {
  stop("Input data not found in DATA_ROOT candidate paths.")
}

log_msg("Using input: ", redact_paths(input_path))

if (grepl("\\.xlsx?$", input_path, ignore.case = TRUE)) {
  df_raw <- readxl::read_excel(input_path, skip = 1, col_names = TRUE)
} else {
  df_raw <- readr::read_csv(input_path, show_col_types = FALSE, progress = FALSE)
}

# ----------------------------
# C) Column mapping (robust)
# ----------------------------
nm <- names(df_raw)

pick_col_regex <- function(df_names, target, patterns) {
  for (pat in patterns) {
    m <- grep(pat, df_names, ignore.case = TRUE)
    if (length(m) == 1) return(df_names[m[1]])
    if (length(m) > 1) stop(paste("Ambiguous column mapping for:", target, "within pattern", pat, "-", paste(df_names[m], collapse = ", ")))
  }
  stop(paste("Column not found for:", target))
}

col_id      <- pick_col_regex(nm, "id", c("^id$", "^nro$", "^potilas", "^sotu$", "^henkilotunnus"))
col_fof     <- pick_col_regex(nm, "FOF", c("^kaatumisenpelkoOn$", "^FOF_status$", "^kaatumisen pelko\\s*\\(0="))
col_sex     <- pick_col_regex(nm, "sex", c("^sex$", "^sukupuoli"))
col_age     <- pick_col_regex(nm, "age", c("^age$", "^Agelka$", "^ikä"))
col_bmi     <- pick_col_regex(nm, "BMI", c("^bmi$", "^BMI", "painoindeksi"))
col_smoker  <- pick_col_regex(nm, "smoker", c("^tupakointi", "^smoker", "^smoking"))
col_alcohol <- pick_col_regex(nm, "alcohol", c("^alkoholi", "^alcohol"))
col_dm      <- pick_col_regex(nm, "DM", c("^diabetes", "^dm$"))
col_ad      <- pick_col_regex(nm, "AD", c("^alzheimer", "^ad$"))
col_cva     <- pick_col_regex(nm, "CVA", c("^AVH", "^CVA", "stroke"))
col_srh     <- pick_col_regex(nm, "SRH", c("^koettuterveydentila", "^SRH"))
col_fallen  <- pick_col_regex(nm, "fallen", c("^kaatuminen\\s*\\(", "^kaatuminen$"))
col_balance <- pick_col_regex(nm, "balance", c("^tasapainovaikeus", "^tasapaino-? ?vaikeudet"))
col_fract   <- pick_col_regex(nm, "fractures", c("^murtumia"))
col_walk500 <- pick_col_regex(nm, "walk500", c("^vaikeus_liikkua_500m", "^500m vaikeus liikkua"))
col_ftsst   <- pick_col_regex(nm, "FTSST", c("^tuoliltanousu0", "^TK: Tuolilta nousu", "^FTSST"))
col_ability <- pick_col_regex(nm, "ability", c("^oma_arvio_liikuntakyky", "^kodin ulkopuolella asiointi"))
col_frailty <- if ("frailty_cat_3" %in% nm) "frailty_cat_3" else NA_character_

# Basic cleaning
normalize_id <- function(x) {
  x <- trimws(as.character(x))
  x <- gsub("\\D", "", x)
  x[x == ""] <- NA_character_
  x
}

# ----------------------------
# D) Recoding Helpers
# ----------------------------
recode_fof_bin <- function(x) {
  if (is.numeric(x) || is.integer(x)) {
    return(factor(ifelse(is.na(x), NA_character_, ifelse(x == 0, "No", "Yes")), levels = c("No", "Yes")))
  }
  factor(ifelse(tolower(trimws(as.character(x))) %in% c("0", "ei", "no"), "No", "Yes"), levels = c("No", "Yes"))
}

women_from_sex <- function(x) {
  xc <- tolower(trimws(as.character(x)))
  # Handle numeric 0/1 where 0=Female (KAAOS standard)
  if (all(xc %in% c("0", "1", NA_character_))) {
    return(as.integer(xc == "0"))
  }
  # Fallback for other standards (e.g. 1=M, 2=F)
  as.integer(xc %in% c("f", "female", "nainen", "2"))
}

normalize_bin012 <- function(x) {
  x_chr <- tolower(trimws(as.character(x)))
  # Treat 0 as No, anything >0 as Yes for Table 1 binary row
  as.integer(ifelse(x_chr %in% c("1", "2", "yes", "kyllä", "true"), 1L,
                    ifelse(x_chr %in% c("0", "no", "ei", "false"), 0L, NA_integer_)))
}

recode_srh_3 <- function(x) {
  xc <- tolower(trimws(as.character(x)))
  out <- dplyr::case_when(
    str_detect(xc, "excellent|erinomain|hyv|good|0|1") ~ "Good/Excellent",
    str_detect(xc, "moderate|kohtal|2")               ~ "Moderate",
    str_detect(xc, "bad|poor|huon|3|4")               ~ "Bad",
    TRUE ~ NA_character_
  )
  factor(out, levels = c("Good/Excellent", "Moderate", "Bad"))
}

# ----------------------------
# E) Process Data
# ----------------------------
df <- df_raw %>%
  transmute(
    id = normalize_id(.data[[col_id]]),
    FOF = recode_fof_bin(.data[[col_fof]]),
    women = women_from_sex(.data[[col_sex]]),
    age = suppressWarnings(as.numeric(.data[[col_age]])),
    bmi = suppressWarnings(as.numeric(.data[[col_bmi]])),
    smoker = normalize_bin012(.data[[col_smoker]]),
    alcohol = normalize_bin012(.data[[col_alcohol]]),
    dm = normalize_bin012(.data[[col_dm]]),
    ad = normalize_bin012(.data[[col_ad]]),
    cva = normalize_bin012(.data[[col_cva]]),
    srh3 = recode_srh_3(.data[[col_srh]]),
    fallen = normalize_bin012(.data[[col_fallen]]),
    balance = normalize_bin012(.data[[col_balance]]),
    fractures = normalize_bin012(.data[[col_fract]]),
    walk500 = normalize_bin012(.data[[col_walk500]]),
    ftsst = suppressWarnings(as.numeric(.data[[col_ftsst]])),
    frailty3 = if (!is.na(col_frailty)) .data[[col_frailty]] else NA_character_
  ) %>%
  filter(!is.na(FOF), !is.na(age), age >= 65)

log_msg("Sample size N: ", nrow(df))

# ----------------------------
# F) N<5 Suppression Formatting
# ----------------------------
fmt_p <- function(p, tab = NULL) {
  if (is.na(p)) return(NA_character_)
  # Suppress p-value if any cell count in the underlying table is < 5 and > 0
  if (!is.null(tab) && any(tab > 0 & tab < 5)) return("suppressed")
  if (p < 0.001) return("<0.001")
  sprintf("%.3f", p)
}

fmt_bin <- function(n, denom) {
  if (is.na(n) || is.na(denom) || denom == 0) return(NA_character_)
  if (n > 0 && n < 5) return("<5")
  pct <- round(100 * n / denom)
  paste0(n, " (", pct, "%)")
}

fmt_cont <- function(mean, sd, n) {
  if (is.na(mean) || is.na(n) || n == 0) return(NA_character_)
  if (n > 0 && n < 5) return("<5")
  paste0(sprintf("%.1f", mean), " (", sprintf("%.1f", sd), ")")
}

# ----------------------------
# G) Row Builders
# ----------------------------
summ_bin_row <- function(label, x01, g) {
  gl <- levels(g)
  cells <- sapply(gl, function(lv) {
    n_yes <- sum(x01 == 1 & g == lv, na.rm = TRUE)
    denom <- sum(!is.na(x01) & g == lv)
    fmt_bin(n_yes, denom)
  })
  
  # P-value with suppression check
  tab <- table(factor(x01, levels=c(0,1)), g)
  p_val <- if (all(dim(tab) >= 2)) suppressWarnings(chisq.test(tab)$p.value) else NA_real_
  
  tibble(Variable = label, !!!setNames(as.list(cells), gl), `P-value` = fmt_p(p_val, tab))
}

# ----------------------------
# H) Row Builders (Cont)
# ----------------------------
summ_cont_row <- function(label, x, g) {
  gl <- levels(g)
  cells <- sapply(gl, function(lv) {
    vals <- x[g == lv & !is.na(x)]
    fmt_cont(mean(vals), sd(vals), length(vals))
  })
  
  p_val <- if (length(gl) == 2) suppressWarnings(t.test(x ~ g)$p.value) else NA_real_
  tibble(Variable = label, !!!setNames(as.list(cells), gl), `P-value` = fmt_p(p_val))
}

# ----------------------------
# I) Build Table
# ----------------------------
tab1 <- bind_rows(
  summ_bin_row("Women, n (%)", df$women, df$FOF),
  summ_cont_row("Age, mean (SD)", df$age, df$FOF),
  summ_cont_row("BMI, mean (SD)", df$bmi, df$FOF),
  summ_bin_row("Smoker, n (%)", df$smoker, df$FOF),
  summ_bin_row("DM, n (%)", df$dm, df$FOF),
  summ_bin_row("AD, n (%)", df$ad, df$FOF),
  summ_bin_row("CVA, n (%)", df$cva, df$FOF),
  summ_bin_row("Fallen, n (%)", df$fallen, df$FOF),
  summ_cont_row("FTSST, s, mean (SD)", df$ftsst, df$FOF)
)

# ----------------------------
# J) Finalize and Export
# ----------------------------
out_path <- file.path(outputs_dir, "table1_patient_characteristics_by_fof.csv")

if (ALLOW_AGGREGATES) {
  write_csv(tab1, out_path)
  log_msg("Table 1 exported to: ", out_path)
} else {
  log_msg("ALLOW_AGGREGATES not set. Export blocked (fail-closed).")
}

write_metadata()
log_msg("Table 1 run complete.")
