#!/usr/bin/env Rscript
# ==============================================================================
# Table 2: Usage of Injury Related Health Services
# - Produces aggregated Table 2 CSV only when double-gated (Option B).
# - No row-level outputs; no absolute paths in stdout/logs.
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(readxl)
  library(tidyr)
  library(stringr)
  library(MASS)
})

# ========================
# A) Config & gating
# ========================

SEED <- as.integer(Sys.getenv("SEED", unset = "20260207"))
B_BOOT <- as.integer(Sys.getenv("BOOTSTRAP_B", unset = "500"))
if (is.na(B_BOOT) || B_BOOT < 20) B_BOOT <- 500

ALLOW_AGGREGATES <- Sys.getenv("ALLOW_AGGREGATES", unset = "") == "1"
INTEND_AGGREGATES <- tolower(Sys.getenv("INTEND_AGGREGATES", unset = "false")) %in% c("1", "true", "yes")

PATH_AIM2_ANALYSIS <- Sys.getenv("PATH_AIM2_ANALYSIS", unset = "")
PATH_PKL_VISITS_XLSX <- Sys.getenv("PATH_PKL_VISITS_XLSX", unset = "")
PATH_WARD_DIAGNOSIS_XLSX <- Sys.getenv("PATH_WARD_DIAGNOSIS_XLSX", unset = "")
PATH_HOSP_EPISODES_XLSX <- Sys.getenv("PATH_HOSP_EPISODES_XLSX", unset = "")
PATH_LINK_TABLE <- Sys.getenv("PATH_LINK_TABLE", unset = "")
DATA_ROOT <- Sys.getenv("DATA_ROOT", unset = "")

PKL_ID_COL <- Sys.getenv("PKL_ID_COL", unset = "")
WARD_ID_COL <- Sys.getenv("WARD_ID_COL", unset = "")
LINK_ID_COL <- Sys.getenv("LINK_ID_COL", unset = "id")
LINK_REGISTER_COL <- Sys.getenv("LINK_REGISTER_COL", unset = "register_id")
WARD_EPISODE_ID_COL <- Sys.getenv("WARD_EPISODE_ID_COL", unset = "")

HOSP_EP_ID_COL <- Sys.getenv("HOSP_EP_ID_COL", unset = "")
HOSP_EP_START_COL <- Sys.getenv("HOSP_EP_START_COL", unset = "")
HOSP_EP_END_COL <- Sys.getenv("HOSP_EP_END_COL", unset = "")
DX_ID_COL <- Sys.getenv("DX_ID_COL", unset = "")
if (!nzchar(DX_ID_COL)) DX_ID_COL <- Sys.getenv("WARD_ID_COL", unset = "")
if (!nzchar(DX_ID_COL)) DX_ID_COL <- Sys.getenv("HOSP_EP_ID_COL", unset = "")
if (!nzchar(DX_ID_COL)) {
  stop("DX_ID_COL missing (and no WARD_ID_COL/HOSP_EP_ID_COL fallback).", call. = FALSE)
}

DX_PDGO_COL <- Sys.getenv("DX_PDGO_COL", unset = "Pdgo")
DX_DATE_COL <- Sys.getenv("DX_DATE_COL", unset = "")
DX_START_COL <- Sys.getenv("DX_START_COL", unset = "")
DX_END_COL <- Sys.getenv("DX_END_COL", unset = "")

required_paths <- c(PATH_AIM2_ANALYSIS, PATH_PKL_VISITS_XLSX, PATH_WARD_DIAGNOSIS_XLSX, PATH_HOSP_EPISODES_XLSX)
if (any(required_paths == "")) {
  stop("Missing required PATH_* env vars (PATH_AIM2_ANALYSIS, PATH_PKL_VISITS_XLSX, PATH_WARD_DIAGNOSIS_XLSX, PATH_HOSP_EPISODES_XLSX).")
}
if (PKL_ID_COL == "") stop("PKL_ID_COL is required (registry ID column in outpatient file).")
if (WARD_ID_COL == "") stop("WARD_ID_COL is required (registry ID column in inpatient file).")
if (HOSP_EP_ID_COL == "" || HOSP_EP_START_COL == "" || HOSP_EP_END_COL == "") {
  stop("HOSP_EP_ID_COL, HOSP_EP_START_COL, HOSP_EP_END_COL are required.")
}
if (!nzchar(DX_ID_COL)) DX_ID_COL <- WARD_ID_COL
if (DX_ID_COL == "" || DX_PDGO_COL == "") {
  stop("DX_ID_COL and DX_PDGO_COL are required.")
}
if (DX_DATE_COL == "" && (DX_START_COL == "" || DX_END_COL == "")) {
  stop("DX_DATE_COL or DX_START_COL/DX_END_COL are required.")
}
if (DATA_ROOT == "") stop("DATA_ROOT is not set.")
if (!dir.exists(DATA_ROOT)) stop("DATA_ROOT is not accessible.")

path_under_root <- function(p, root) {
  if (p == "") return(TRUE)
  p_norm <- normalizePath(p, winslash = "/", mustWork = FALSE)
  r_norm <- normalizePath(root, winslash = "/", mustWork = FALSE)
  startsWith(p_norm, r_norm)
}

if (!all(
  path_under_root(PATH_AIM2_ANALYSIS, DATA_ROOT),
  path_under_root(PATH_PKL_VISITS_XLSX, DATA_ROOT),
  path_under_root(PATH_WARD_DIAGNOSIS_XLSX, DATA_ROOT),
  path_under_root(PATH_HOSP_EPISODES_XLSX, DATA_ROOT),
  path_under_root(PATH_LINK_TABLE, DATA_ROOT)
)) {
  stop("PATH_* inputs must be located under DATA_ROOT.")
}

# ========================
# B) Secure logging helpers
# ========================

abs_path_regex <- "(^|[[:space:]])(/[^[:space:]]+)"
redact_paths <- function(x) {
  if (length(x) == 0) return(x)
  x <- gsub(getwd(), "<REPO_ROOT>", x, fixed = TRUE)
  x <- gsub(DATA_ROOT, "<DATA_ROOT>", x, fixed = TRUE)
  x <- gsub(abs_path_regex, "\\1<ABS_PATH>", x, perl = TRUE)
  x
}

log_msg <- function(...) {
  msg <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " | ", paste0(..., collapse = ""))
  message(redact_paths(msg))
}

file_basename <- function(x) ifelse(is.na(x) || x == "", "", basename(x))

as_date_yyyymmdd <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXct") || inherits(x, "POSIXt")) return(as.Date(x))
  x_chr <- as.character(x)
  x_chr <- gsub("\\.0$", "", x_chr)
  suppressWarnings(as.Date(x_chr, format = "%Y%m%d"))
}

is_injury_code <- function(x) {
  x <- toupper(trimws(as.character(x)))
  x <- gsub("[^A-Z0-9]", "", x)
  letter <- substr(x, 1, 1)
  num2 <- suppressWarnings(as.integer(substr(x, 2, 3)))
  (letter == "S" & !is.na(num2) & num2 >= 0 & num2 <= 99) |
    (letter == "T" & !is.na(num2) & num2 >= 0 & num2 <= 14)
}

collapse_days_union <- function(df) {
  if (nrow(df) == 0) return(0)
  df <- df[order(df$start_date, df$end_date), , drop = FALSE]
  df$start_date <- as.Date(df$start_date)
  df$end_date <- as.Date(df$end_date)
  df <- df[!is.na(df$start_date) & !is.na(df$end_date), , drop = FALSE]
  if (nrow(df) == 0) return(0)
  df <- df[df$end_date >= df$start_date, , drop = FALSE]
  if (nrow(df) == 0) return(0)
  cur_s <- df$start_date[1]
  cur_e <- df$end_date[1]
  total <- 0
  if (nrow(df) > 1) {
    for (i in 2:nrow(df)) {
      s <- df$start_date[i]; e <- df$end_date[i]
      if (is.na(s) || is.na(e)) next
      if (s <= (cur_e + 1)) {
        if (e > cur_e) cur_e <- e
      } else {
        total <- total + as.integer(cur_e - cur_s) + 1
        cur_s <- s; cur_e <- e
      }
    }
  }
  total <- total + as.integer(cur_e - cur_s) + 1
  total
}

# ========================
# C) Safe readers
# ========================

read_csv_safe <- function(path) {
  if (!file.exists(path)) stop("Missing file: ", file_basename(path))
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
}

read_xlsx_safe <- function(path) {
  if (!file.exists(path)) stop("Missing file: ", file_basename(path))
  readxl::read_excel(path, col_names = TRUE)
}

# ========================
# D) Load inputs
# ========================

log_msg("Loading inputs (paths redacted).")

aim2 <- read_csv_safe(PATH_AIM2_ANALYSIS)

req_aim2 <- c("id", "FOF_status", "age", "sex", "followup_days")
missing_aim2 <- setdiff(req_aim2, names(aim2))
if (length(missing_aim2) > 0) {
  stop("aim2_analysis missing columns: ", paste(missing_aim2, collapse = ", "))
}

aim2 <- aim2 %>%
  transmute(
    id = .data$id,
    FOF_status = suppressWarnings(as.integer(.data$FOF_status)),
    age = suppressWarnings(as.numeric(.data$age)),
    sex = as.factor(.data$sex),
    followup_days = suppressWarnings(as.numeric(.data$followup_days))
  )

if (any(is.na(aim2$FOF_status)) || any(!aim2$FOF_status %in% c(0, 1))) {
  stop("FOF_status must be coded as 0/1 (No/Yes).")
}
if (any(is.na(aim2$followup_days)) || any(aim2$followup_days <= 0)) {
  stop("followup_days must be numeric and > 0.")
}

aim2 <- aim2 %>% mutate(person_years = followup_days / 365.25)

pkl <- read_xlsx_safe(PATH_PKL_VISITS_XLSX)
ward <- read_xlsx_safe(PATH_WARD_DIAGNOSIS_XLSX)
hosp <- read_xlsx_safe(PATH_HOSP_EPISODES_XLSX)

if (!(PKL_ID_COL %in% names(pkl))) stop("PKL_ID_COL not found in outpatient file.")
if (!(WARD_ID_COL %in% names(ward))) stop("WARD_ID_COL not found in inpatient file.")
if (!("Pdgo" %in% names(pkl))) stop("Outpatient file missing Pdgo.")
if (!(DX_ID_COL %in% names(ward))) stop("DX_ID_COL not found in ward diagnosis file.")
if (!(DX_PDGO_COL %in% names(ward))) stop("DX_PDGO_COL not found in ward diagnosis file.")
if (!(HOSP_EP_ID_COL %in% names(hosp))) stop("HOSP_EP_ID_COL not found in hospital episodes file.")
if (!all(c(HOSP_EP_START_COL, HOSP_EP_END_COL) %in% names(hosp))) stop("Hospital episodes start/end cols not found.")

# ========================
# E) Link table handling
# ========================

use_link <- PATH_LINK_TABLE != ""

if (use_link) {
  link <- read_csv_safe(PATH_LINK_TABLE)
  if (!(LINK_ID_COL %in% names(link)) || !(LINK_REGISTER_COL %in% names(link))) {
    stop("Link table missing required columns (", LINK_ID_COL, ", ", LINK_REGISTER_COL, ").")
  }
  link <- link %>%
    transmute(id = .data[[LINK_ID_COL]], register_id = .data[[LINK_REGISTER_COL]]) %>%
    distinct()

  dup_id <- link %>% count(id) %>% filter(n > 1)
  dup_reg <- link %>% count(register_id) %>% filter(n > 1)
  if (nrow(dup_id) > 0 || nrow(dup_reg) > 0) {
    stop("Link table must be 1:1 (duplicates detected).")
  }
} else {
  # Fail-closed if IDs do not match directly
  direct_match_pkl <- all(aim2$id %in% pkl[[PKL_ID_COL]])
  direct_match_ward <- all(aim2$id %in% ward[[WARD_ID_COL]])
  if (!(direct_match_pkl && direct_match_ward)) {
    stop("Link table missing and IDs do not match. Provide PATH_LINK_TABLE.")
  }
  link <- aim2 %>% transmute(id = .data$id, register_id = .data$id)
}

# ========================
# F) ICD-10 block mapping
# ========================

blocks <- c(
  "S00-09", "S10-19", "S20-29", "S30-39", "S40-49",
  "S50-59", "S60-69", "S70-79", "S80-89", "S90-99",
  "T00-14"
)

icd_block <- function(code) {
  if (is.na(code)) return(NA_character_)
  c2 <- toupper(gsub("[^A-Z0-9]", "", as.character(code)))
  m <- regmatches(c2, regexec("^([A-Z])(\\d{2})", c2))[[1]]
  if (length(m) < 3) return(NA_character_)
  letter <- m[2]
  num <- suppressWarnings(as.integer(m[3]))
  if (is.na(num)) return(NA_character_)
  if (letter == "S" && num >= 0 && num <= 9) return("S00-09")
  if (letter == "S" && num >= 10 && num <= 19) return("S10-19")
  if (letter == "S" && num >= 20 && num <= 29) return("S20-29")
  if (letter == "S" && num >= 30 && num <= 39) return("S30-39")
  if (letter == "S" && num >= 40 && num <= 49) return("S40-49")
  if (letter == "S" && num >= 50 && num <= 59) return("S50-59")
  if (letter == "S" && num >= 60 && num <= 69) return("S60-69")
  if (letter == "S" && num >= 70 && num <= 79) return("S70-79")
  if (letter == "S" && num >= 80 && num <= 89) return("S80-89")
  if (letter == "S" && num >= 90 && num <= 99) return("S90-99")
  if (letter == "T" && num >= 0 && num <= 14) return("T00-14")
  NA_character_
}

# ========================
# G) Outpatient counts
# ========================

pkl_slim <- pkl %>%
  transmute(register_id = .data[[PKL_ID_COL]], pdgo = .data$Pdgo) %>%
  mutate(block = vapply(pdgo, icd_block, character(1))) %>%
  filter(!is.na(block))

pkl_linked <- pkl_slim %>%
  inner_join(link, by = "register_id")

pkl_counts <- pkl_linked %>%
  count(id, block, name = "count")

pkl_wide <- pkl_counts %>%
  tidyr::pivot_wider(names_from = block, values_from = count, values_fill = 0)

# Ensure all block columns exist
for (b in blocks) {
  if (!(b %in% names(pkl_wide))) pkl_wide[[b]] <- 0
}

pkl_wide <- pkl_wide %>%
  mutate(Total = rowSums(dplyr::select(., all_of(blocks)), na.rm = TRUE))

# ========================
# H) Inpatient (treatment periods) counts
# ========================

ward_ep <- hosp %>%
  transmute(
    register_id = .data[[HOSP_EP_ID_COL]],
    start_date = as_date_yyyymmdd(.data[[HOSP_EP_START_COL]]),
    end_date   = as_date_yyyymmdd(.data[[HOSP_EP_END_COL]])
  ) %>%
  filter(!is.na(start_date), !is.na(end_date))

dx_tbl <- ward %>%
  transmute(
    register_id = .data[[DX_ID_COL]],
    dx_start = if (DX_DATE_COL != "") as_date_yyyymmdd(.data[[DX_DATE_COL]]) else as_date_yyyymmdd(.data[[DX_START_COL]]),
    dx_end   = if (DX_DATE_COL != "") as_date_yyyymmdd(.data[[DX_DATE_COL]]) else as_date_yyyymmdd(.data[[DX_END_COL]])
  ) %>%
  filter(!is.na(dx_start), !is.na(dx_end))

dx_names <- names(ward)
is_dateish <- function(nm) grepl("pvm|date|alku|loppu|start|end", tolower(nm))
is_idish <- function(nm) grepl("id|tunnus|henk|potilas|register", tolower(nm))
diag_like <- dx_names[grepl("^Sdg[0-9]+", dx_names) | grepl("diag|dg", tolower(dx_names))]
diag_like <- diag_like[!vapply(diag_like, is_dateish, logical(1))]
diag_like <- diag_like[!vapply(diag_like, is_idish, logical(1))]
dx_diag_cols <- unique(c(if (DX_PDGO_COL %in% dx_names) DX_PDGO_COL else character(0), diag_like))
if (length(dx_diag_cols) == 0) stop("No diagnosis columns found in dxfile. Set DX_PDGO_COL explicitly or update patterns.")

dx_date_cols <- if (DX_DATE_COL != "") DX_DATE_COL else c(DX_START_COL, DX_END_COL)
dx_any <- ward %>%
  dplyr::select(all_of(c(DX_ID_COL, dx_date_cols, dx_diag_cols))) %>%
  dplyr::mutate(any_injury_dx = if_any(all_of(dx_diag_cols), ~ is_injury_code(.x)))

if (DX_DATE_COL != "") {
  dx_any <- dx_any %>% mutate(diag_date = as_date_yyyymmdd(.data[[DX_DATE_COL]]))
  merged <- ward_ep %>%
    inner_join(dx_any, by = c("register_id" = DX_ID_COL)) %>%
    filter(!is.na(diag_date), diag_date >= start_date, diag_date <= end_date)
} else {
  dx_any <- dx_any %>%
    mutate(dx_start = as_date_yyyymmdd(.data[[DX_START_COL]]),
           dx_end   = as_date_yyyymmdd(.data[[DX_END_COL]]))
  merged <- ward_ep %>%
    inner_join(dx_any, by = c("register_id" = DX_ID_COL)) %>%
    filter(!is.na(dx_start), !is.na(dx_end), dx_start <= end_date, dx_end >= start_date)
}

dx_episode_injury <- merged %>%
  group_by(register_id, start_date, end_date) %>%
  summarise(any_injury = any(any_injury_dx, na.rm = TRUE), .groups = "drop") %>%
  filter(any_injury)

injury_episode_counts <- dx_episode_injury %>%
  distinct(register_id, start_date, end_date) %>%
  count(register_id, name = "hospital_periods")

dx_injury_intervals <- dx_any %>%
  filter(any_injury_dx) %>%
  transmute(
    register_id = .data[[DX_ID_COL]],
    start_date = if (DX_DATE_COL != "") as_date_yyyymmdd(.data[[DX_DATE_COL]]) else as_date_yyyymmdd(.data[[DX_START_COL]]),
    end_date   = if (DX_DATE_COL != "") as_date_yyyymmdd(.data[[DX_DATE_COL]]) else as_date_yyyymmdd(.data[[DX_END_COL]])
  ) %>%
  filter(!is.na(start_date), !is.na(end_date), end_date >= start_date)

collapsed_days <- dx_injury_intervals %>%
  group_by(register_id) %>%
  summarise(hospital_days = collapse_days_union(pick(start_date, end_date)), .groups = "drop")

ward_linked <- injury_episode_counts %>%
  inner_join(link, by = "register_id")

ward_counts <- ward_linked %>%
  count(id, name = "hospital_periods")

ward_days_linked <- collapsed_days %>%
  inner_join(link, by = "register_id") %>%
  group_by(id) %>%
  summarise(hospital_days = sum(hospital_days, na.rm = TRUE), .groups = "drop")

# ========================
# I) Combine person-level data
# ========================

df <- aim2 %>%
  left_join(pkl_wide, by = "id") %>%
  left_join(ward_counts, by = "id") %>%
  left_join(ward_days_linked, by = "id")

# Replace NA counts with 0
for (b in c(blocks, "Total")) {
  if (!(b %in% names(df))) df[[b]] <- 0
  df[[b]] <- suppressWarnings(as.integer(ifelse(is.na(df[[b]]), 0, df[[b]])))
}
if (!("hospital_periods" %in% names(df))) df$hospital_periods <- 0
if (any(is.na(df$hospital_periods))) df$hospital_periods[is.na(df$hospital_periods)] <- 0
if (!("hospital_days" %in% names(df))) df$hospital_days <- 0
if (any(is.na(df$hospital_days))) df$hospital_days[is.na(df$hospital_days)] <- 0

log_msg("Outcome counts:")
for (b in c(blocks, "Total", "hospital_days")) {
  log_msg("  ", b, ": ", sum(df[[b]], na.rm = TRUE))
}

# ========================
# J) Modeling helpers
# ========================

fit_model <- function(data, count_col) {
  form <- as.formula(paste0("`", count_col, "` ~ FOF_status + age + sex + offset(log(person_years))"))
  
  fit_pois <- tryCatch({
    suppressWarnings(glm(form, data = data, family = poisson(link = "log")))
  }, error = function(e) NULL)
  
  if (is.null(fit_pois)) return(NULL)
  
  disp <- suppressWarnings(sum(residuals(fit_pois, type = "pearson")^2) / fit_pois$df.residual)
  if (is.finite(disp) && disp > 1.5) {
    fit_nb <- tryCatch({
      suppressWarnings(MASS::glm.nb(form, data = data))
    }, error = function(e) NULL)
    
    if (!is.null(fit_nb)) {
      return(list(fit = fit_nb, model = "nb"))
    }
  }
  list(fit = fit_pois, model = "poisson")
}

irr_from_fit <- function(fit) {
  if (is.null(fit)) return(c(irr = NA, low = NA, high = NA))
  coef_name <- "FOF_status"
  if (!(coef_name %in% names(coef(fit)))) {
    return(c(irr = NA, low = NA, high = NA))
  }
  beta <- coef(fit)[[coef_name]]
  se <- sqrt(diag(vcov(fit)))[[coef_name]]
  irr <- exp(beta)
  low <- exp(beta - 1.96 * se)
  high <- exp(beta + 1.96 * se)
  c(irr = irr, low = low, high = high)
}

rate_from_fit <- function(fit, data, fof_value) {
  if (is.null(fit)) return(NA_real_)
  d <- data
  d$FOF_status <- fof_value
  mu <- tryCatch({
    suppressWarnings(predict(fit, newdata = d, type = "response"))
  }, error = function(e) NA_real_)
  if (all(is.na(mu))) return(NA_real_)
  sum(mu, na.rm = TRUE) / sum(d$person_years, na.rm = TRUE) * 1000
}

bootstrap_rates <- function(data, count_col, B, seed) {
  if (B < 1) return(c(no = NA_real_, yes = NA_real_))
  set.seed(seed)
  n <- nrow(data)
  rates_no <- numeric(B)
  rates_yes <- numeric(B)
  for (b in seq_len(B)) {
    idx <- sample.int(n, size = n, replace = TRUE)
    d <- data[idx, , drop = FALSE]
    fit_info <- fit_model(d, count_col)
    rates_no[b] <- if (is.null(fit_info)) NA_real_ else rate_from_fit(fit_info$fit, d, 0)
    rates_yes[b] <- if (is.null(fit_info)) NA_real_ else rate_from_fit(fit_info$fit, d, 1)
  }
  c(no = sd(rates_no, na.rm = TRUE), yes = sd(rates_yes, na.rm = TRUE))
}

fmt_num <- function(x, digits = 2) {
  ifelse(is.na(x), NA_character_, formatC(x, format = "f", digits = digits))
}

# ========================
# K) Build Table 2
# ========================

rows <- c(blocks, "Total", "hospital_days")
row_labels <- c(
  paste0("Outpatient visits ", blocks),
  "Outpatient visits Total",
  "Hospital treatment days"
)

results <- vector("list", length(rows))

for (i in seq_along(rows)) {
  outcome <- rows[[i]]
  label <- row_labels[[i]]
  log_msg("Processing outcome: ", outcome)

  fit_info <- fit_model(df, outcome)
  fit <- if (!is.null(fit_info)) fit_info$fit else NULL

  irr_vals <- irr_from_fit(fit)
  rate_no <- rate_from_fit(fit, df, 0)
  rate_yes <- rate_from_fit(fit, df, 1)
  se_vals <- bootstrap_rates(df, outcome, B_BOOT, SEED + i)

  results[[i]] <- tibble(
    row = label,
    fof_no_mean = rate_no,
    fof_no_se = se_vals[["no"]],
    fof_yes_mean = rate_yes,
    fof_yes_se = se_vals[["yes"]],
    irr = irr_vals[["irr"]],
    irr_low = irr_vals[["low"]],
    irr_high = irr_vals[["high"]]
  )
}

out <- bind_rows(results) %>%
  mutate(
    fof_no_mean_se = paste0(fmt_num(fof_no_mean), " (", fmt_num(fof_no_se), ")"),
    fof_yes_mean_se = paste0(fmt_num(fof_yes_mean), " (", fmt_num(fof_yes_se), ")"),
    irr_95ci = paste0(fmt_num(irr), " (", fmt_num(irr_low), ", ", fmt_num(irr_high), ")")
  )

# ========================
# L) Output gating
# ========================

if (!(ALLOW_AGGREGATES && INTEND_AGGREGATES)) {
  stop("Aggregates not allowed: set ALLOW_AGGREGATES=1 and INTEND_AGGREGATES=true to write Table 2 output.")
}

dir.create(file.path("R", "15_table2", "outputs"), showWarnings = FALSE, recursive = TRUE)

out_path <- file.path("R", "15_table2", "outputs", "table2_generated.csv")
readr::write_csv(out, out_path, na = "")

log_msg("Table 2 written to R/15_table2/outputs/table2_generated.csv (no paths printed).")
