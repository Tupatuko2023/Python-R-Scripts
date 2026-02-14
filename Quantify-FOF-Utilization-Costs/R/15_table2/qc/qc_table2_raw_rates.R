#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(readr)
  library(readxl)
})

log_msg <- function(msg) {
  cat(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "|", msg, "\n")
}

# ---- Gates ----
allow_agg <- Sys.getenv("ALLOW_AGGREGATES", "") == "1"
intend_agg <- tolower(Sys.getenv("INTEND_AGGREGATES", "")) %in% c("true", "1", "yes")
if (!allow_agg || !intend_agg) {
  stop("Aggregates gate closed. Set ALLOW_AGGREGATES=1 and INTEND_AGGREGATES=true.", call. = FALSE)
}

# ---- Env inputs (no printing of values) ----
need_env <- function(name) {
  v <- Sys.getenv(name, "")
  if (!nzchar(v)) stop(sprintf("Missing required env var: %s", name), call. = FALSE)
  v
}

DATA_ROOT <- need_env("DATA_ROOT")
PATH_AIM2_ANALYSIS <- need_env("PATH_AIM2_ANALYSIS")
PATH_PKL_VISITS_XLSX <- need_env("PATH_PKL_VISITS_XLSX")
PATH_WARD_DIAGNOSIS_XLSX <- need_env("PATH_WARD_DIAGNOSIS_XLSX")
PATH_LINK_TABLE <- need_env("PATH_LINK_TABLE")
PATH_HOSP_EPISODES_XLSX <- need_env("PATH_HOSP_EPISODES_XLSX")

PKL_ID_COL <- need_env("PKL_ID_COL")
WARD_ID_COL <- need_env("WARD_ID_COL")

# Hospital episodes table columns
HOSP_EP_ID_COL <- need_env("HOSP_EP_ID_COL")
HOSP_EP_START_COL <- need_env("HOSP_EP_START_COL")
HOSP_EP_END_COL <- need_env("HOSP_EP_END_COL")

# Diagnosis (dx) table columns for date-bounded merge
DX_ID_COL <- Sys.getenv("DX_ID_COL", "")
if (!nzchar(DX_ID_COL)) DX_ID_COL <- Sys.getenv("WARD_ID_COL", "")
if (!nzchar(DX_ID_COL)) DX_ID_COL <- Sys.getenv("HOSP_EP_ID_COL", "")
if (!nzchar(DX_ID_COL)) stop("Missing DX_ID_COL (and no WARD_ID_COL/HOSP_EP_ID_COL fallback).", call. = FALSE)

DX_PDGO_COL <- Sys.getenv("DX_PDGO_COL", "")
if (!nzchar(DX_PDGO_COL)) DX_PDGO_COL <- "Pdgo"
DX_DATE_COL <- Sys.getenv("DX_DATE_COL", "")
DX_START_COL <- Sys.getenv("DX_START_COL", "")
DX_END_COL <- Sys.getenv("DX_END_COL", "")
if (!nzchar(DX_DATE_COL) && (!nzchar(DX_START_COL) || !nzchar(DX_END_COL))) {
  stop("Missing DX_DATE_COL or DX_START_COL/DX_END_COL.", call. = FALSE)
}

# Guardrail: require all input paths under DATA_ROOT (string prefix check)
require_under_dataroot <- function(p, name) {
  if (!startsWith(normalizePath(p, winslash = "/", mustWork = FALSE),
                  normalizePath(DATA_ROOT, winslash = "/", mustWork = FALSE))) {
    stop(sprintf("%s is not under DATA_ROOT.", name), call. = FALSE)
  }
}
require_under_dataroot(PATH_AIM2_ANALYSIS, "PATH_AIM2_ANALYSIS")
require_under_dataroot(PATH_PKL_VISITS_XLSX, "PATH_PKL_VISITS_XLSX")
require_under_dataroot(PATH_WARD_DIAGNOSIS_XLSX, "PATH_WARD_DIAGNOSIS_XLSX")
require_under_dataroot(PATH_LINK_TABLE, "PATH_LINK_TABLE")
require_under_dataroot(PATH_HOSP_EPISODES_XLSX, "PATH_HOSP_EPISODES_XLSX")

# ---- Helpers ----
as_date_yyyymmdd <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXct") || inherits(x, "POSIXt")) return(as.Date(x))
  x_chr <- as.character(x)
  x_chr <- str_replace_all(x_chr, "\\.0$", "")
  suppressWarnings(as.Date(x_chr, format = "%Y%m%d"))
}

icd_block_injury <- function(icd_code) {
  x <- toupper(trimws(as.character(icd_code)))
  x <- str_replace_all(x, "[^A-Z0-9]", "")
  letter <- str_sub(x, 1, 1)
  num2 <- suppressWarnings(as.integer(str_sub(x, 2, 3)))
  out <- rep(NA_character_, length(x))

  is_S <- letter == "S" & !is.na(num2) & num2 >= 0 & num2 <= 99
  is_T <- letter == "T" & !is.na(num2) & num2 >= 0 & num2 <= 14

  out[is_S] <- sprintf("S%02d-%02d",
                       floor(num2[is_S] / 10) * 10,
                       floor(num2[is_S] / 10) * 10 + 9)
  out[is_T] <- "T00-14"
  out
}

rate_per_1000 <- function(events, py) {
  ifelse(py > 0, (events / py) * 1000, NA_real_)
}

collapse_days_union <- function(df) {
  if (nrow(df) == 0) return(0)
  df <- df[order(df$start_date, df$end_date), , drop = FALSE]
  df <- df[!is.na(df$start_date) & !is.na(df$end_date), , drop = FALSE]
  if (nrow(df) == 0) return(0)
  df$start_date <- as.Date(df$start_date)
  df$end_date <- as.Date(df$end_date)
  df <- df[!is.na(df$start_date) & !is.na(df$end_date), , drop = FALSE]
  if (nrow(df) == 0) return(0)
  df <- df[df$end_date >= df$start_date, , drop = FALSE]
  if (nrow(df) == 0) return(0)
  idx <- which(!is.na(df$start_date) & !is.na(df$end_date))
  if (length(idx) == 0) return(0)
  cur_s <- df$start_date[idx[1]]
  cur_e <- df$end_date[idx[1]]
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

is_injury_code <- function(x) {
  x <- toupper(trimws(as.character(x)))
  x <- str_replace_all(x, "[^A-Z0-9]", "")
  letter <- str_sub(x, 1, 1)
  num2 <- suppressWarnings(as.integer(str_sub(x, 2, 3)))
  (letter == "S" & !is.na(num2) & num2 >= 0 & num2 <= 99) |
    (letter == "T" & !is.na(num2) & num2 >= 0 & num2 <= 14)
}

is_injury_code_t98 <- function(x) {
  x <- toupper(trimws(as.character(x)))
  x <- str_replace_all(x, "[^A-Z0-9]", "")
  letter <- str_sub(x, 1, 1)
  num2 <- suppressWarnings(as.integer(str_sub(x, 2, 3)))
  (letter == "S" & !is.na(num2) & num2 >= 0 & num2 <= 99) |
    (letter == "T" & !is.na(num2) & num2 >= 0 & num2 <= 98)
}

# ---- Load person-level ----
log_msg("Loading aim2_analysis (paths redacted).")
aim2 <- readr::read_csv(PATH_AIM2_ANALYSIS, show_col_types = FALSE) %>%
  transmute(
    id = .data[["id"]],
    FOF_status = as.integer(.data[["FOF_status"]]),
    followup_days = as.numeric(.data[["followup_days"]]),
    age = suppressWarnings(as.numeric(.data[["age"]])),
    sex = .data[["sex"]]
  ) %>%
  mutate(
    person_years = followup_days / 365.25
  )

# ---- Load linkage ----
link_tbl <- readr::read_csv(PATH_LINK_TABLE, show_col_types = FALSE)
if (!all(c("id", "register_id") %in% names(link_tbl))) {
  stop("Link table must contain columns: id, register_id", call. = FALSE)
}

cohort <- aim2 %>%
  inner_join(link_tbl, by = "id") %>%
  filter(FOF_status %in% c(0, 1)) %>%
  group_by(FOF_status) %>%
  summarise(n = n(), py = sum(person_years, na.rm = TRUE), .groups = "drop")

# Cohort counts before/after linkage (no IDs)
pre_counts <- aim2 %>%
  summarise(
    pre_n_total = n(),
    pre_n_fof0 = sum(FOF_status == 0, na.rm = TRUE),
    pre_n_fof1 = sum(FOF_status == 1, na.rm = TRUE),
    pre_n_invalid_fof = sum(!(FOF_status %in% c(0, 1)), na.rm = TRUE)
  )

drop_counts <- aim2 %>%
  filter(FOF_status %in% c(0, 1)) %>%
  summarise(
    drop_missing_sex = sum(is.na(sex) | sex == "", na.rm = TRUE),
    drop_missing_age = sum(is.na(age), na.rm = TRUE),
    drop_missing_followup = sum(is.na(followup_days) | followup_days <= 0, na.rm = TRUE),
    drop_nonpositive_py = sum(is.na(person_years) | person_years <= 0, na.rm = TRUE)
  )

drop_counts_by_fof <- aim2 %>%
  filter(FOF_status %in% c(0, 1)) %>%
  group_by(FOF_status) %>%
  summarise(
    drop_missing_sex = sum(is.na(sex) | sex == "", na.rm = TRUE),
    drop_missing_age = sum(is.na(age), na.rm = TRUE),
    drop_missing_followup = sum(is.na(followup_days) | followup_days <= 0, na.rm = TRUE),
    drop_nonpositive_py = sum(is.na(person_years) | person_years <= 0, na.rm = TRUE),
    .groups = "drop"
  )

# ---- Outpatient: Pdgo-only vs Any-dx ----
log_msg("Loading outpatient visits (paths redacted).")
pkl <- readxl::read_xlsx(PATH_PKL_VISITS_XLSX)

if (!PKL_ID_COL %in% names(pkl)) stop("PKL_ID_COL not found in outpatient file.", call. = FALSE)
if (!"Pdgo" %in% names(pkl)) stop("Missing Pdgo in outpatient file.", call. = FALSE)

sdg_cols <- names(pkl)[str_detect(names(pkl), "^Sdg[1-9]o$")]
dx_cols_any <- c("Pdgo", sdg_cols)

pkl_with_row <- pkl %>% mutate(.row_id = row_number())
pkl_long_any <- pkl_with_row %>%
  transmute(.row_id, register_id = .data[[PKL_ID_COL]]) %>%
  bind_cols(pkl_with_row %>% select(all_of(dx_cols_any))) %>%
  pivot_longer(cols = all_of(dx_cols_any), names_to = "dx_field", values_to = "dx") %>%
  mutate(block = icd_block_injury(dx)) %>%
  filter(!is.na(block))

injury_visit_any <- pkl_long_any %>%
  distinct(.row_id, register_id) %>%
  count(register_id, name = "outpatient_injury_visits_anydx")

injury_visit_pdgo <- pkl_with_row %>%
  transmute(.row_id, register_id = .data[[PKL_ID_COL]], dx = .data[["Pdgo"]]) %>%
  mutate(block = icd_block_injury(dx)) %>%
  filter(!is.na(block)) %>%
  distinct(.row_id, register_id) %>%
  count(register_id, name = "outpatient_injury_visits_pdgo")

# ---- Hospital: episodes vs days (two sources) ----
log_msg("Loading hospital diagnosis file (paths redacted).")
ward_dx <- readxl::read_xlsx(PATH_WARD_DIAGNOSIS_XLSX)
if (!WARD_ID_COL %in% names(ward_dx)) stop("WARD_ID_COL not found in ward diagnosis file.", call. = FALSE)
if (!DX_ID_COL %in% names(ward_dx)) stop("DX_ID_COL not found in ward diagnosis file.", call. = FALSE)
if (!DX_PDGO_COL %in% names(ward_dx)) stop("DX_PDGO_COL not found in ward diagnosis file.", call. = FALSE)
if (!all(c("OsastojaksoAlkuPvm", "OsastojaksoLoppuPvm") %in% names(ward_dx))) {
  stop("Missing OsastojaksoAlkuPvm/OsastojaksoLoppuPvm in ward diagnosis file.", call. = FALSE)
}

ward_stays <- ward_dx %>%
  transmute(
    register_id = .data[[WARD_ID_COL]],
    start_date = as_date_yyyymmdd(.data[["OsastojaksoAlkuPvm"]]),
    end_date   = as_date_yyyymmdd(.data[["OsastojaksoLoppuPvm"]]),
    pdgo = .data[[DX_PDGO_COL]]
  ) %>%
  filter(!is.na(start_date), !is.na(end_date))

ward_episode_counts <- ward_stays %>%
  distinct(register_id, start_date, end_date) %>%
  count(register_id, name = "hospital_episodes_from_dxfile")

ward_days_sum <- ward_stays %>%
  mutate(days = as.numeric(end_date - start_date) + 1) %>%
  group_by(register_id) %>%
  summarise(hospital_days_from_dxfile = sum(days, na.rm = TRUE), .groups = "drop")

# Injury-only hospital stays (dxfile)
ward_stays_injury <- ward_stays %>%
  mutate(block = icd_block_injury(pdgo)) %>%
  filter(!is.na(block))

ward_episode_counts_injury <- ward_stays_injury %>%
  distinct(register_id, start_date, end_date) %>%
  count(register_id, name = "injury_hosp_ep_dxfile")

ward_days_sum_injury <- ward_stays_injury %>%
  mutate(days = as.numeric(end_date - start_date) + 1) %>%
  group_by(register_id) %>%
  summarise(injury_hosp_days_dxfile = sum(days, na.rm = TRUE), .groups = "drop")

# ---- Hospital episodes table + safe date-bounded merge ----
log_msg("Loading hospital episodes file (paths redacted).")
hosp <- readxl::read_xlsx(PATH_HOSP_EPISODES_XLSX)
if (!HOSP_EP_ID_COL %in% names(hosp)) stop("HOSP_EP_ID_COL not found in hospital episodes file.", call. = FALSE)
if (!all(c(HOSP_EP_START_COL, HOSP_EP_END_COL) %in% names(hosp))) stop("Hospital episodes start/end cols not found.", call. = FALSE)

hosp2 <- hosp %>%
  transmute(
    register_id = .data[[HOSP_EP_ID_COL]],
    start_date = as_date_yyyymmdd(.data[[HOSP_EP_START_COL]]),
    end_date   = as_date_yyyymmdd(.data[[HOSP_EP_END_COL]])
  ) %>%
  filter(!is.na(start_date), !is.na(end_date))

hosp_episode_counts2 <- hosp2 %>%
  distinct(register_id, start_date, end_date) %>%
  count(register_id, name = "hospital_episodes_from_episodefile")

hosp_days_sum2 <- hosp2 %>%
  mutate(days = as.numeric(end_date - start_date) + 1) %>%
  group_by(register_id) %>%
  summarise(hospital_days_from_episodefile = sum(days, na.rm = TRUE), .groups = "drop")

# Dx table for date-bounded merge
# --- DX columns: any-dx discovery (names only, no values) ---
dx_names <- names(ward_dx)
is_dateish <- function(nm) str_detect(tolower(nm), "pvm|date|alku|loppu|start|end")
is_idish   <- function(nm) str_detect(tolower(nm), "id|tunnus|henk|potilas|register")

diag_like <- dx_names[
  str_detect(dx_names, "^Sdg[0-9]+") |
  str_detect(tolower(dx_names), "diag|dg")
]
diag_like <- diag_like[!vapply(diag_like, is_dateish, logical(1))]
diag_like <- diag_like[!vapply(diag_like, is_idish, logical(1))]

dx_diag_cols <- unique(c(if (DX_PDGO_COL %in% dx_names) DX_PDGO_COL else character(0), diag_like))
if (length(dx_diag_cols) == 0) {
  stop("No diagnosis columns found in dxfile. Set DX_PDGO_COL explicitly or update patterns.", call. = FALSE)
}

dx_date_cols <- if (nzchar(DX_DATE_COL)) DX_DATE_COL else c(DX_START_COL, DX_END_COL)

dx_any <- ward_dx %>%
  select(all_of(c(DX_ID_COL, dx_date_cols, dx_diag_cols))) %>%
  mutate(
    any_injury_dx = if_any(all_of(dx_diag_cols), ~ is_injury_code(.x)),
    any_injury_dx_t98 = if_any(all_of(dx_diag_cols), ~ is_injury_code_t98(.x))
  )

# JOIN + bounded filter
if (nzchar(DX_DATE_COL)) {
  dx_any <- dx_any %>% mutate(diag_date = as_date_yyyymmdd(.data[[DX_DATE_COL]]))
  merged <- hosp2 %>%
    inner_join(dx_any, by = c("register_id" = DX_ID_COL)) %>%
    filter(!is.na(diag_date), diag_date >= start_date, diag_date <= end_date)
} else {
  dx_any <- dx_any %>%
    mutate(dx_start = as_date_yyyymmdd(.data[[DX_START_COL]]),
           dx_end   = as_date_yyyymmdd(.data[[DX_END_COL]]))
  merged <- hosp2 %>%
    inner_join(dx_any, by = c("register_id" = DX_ID_COL)) %>%
    filter(!is.na(dx_start), !is.na(dx_end), dx_start <= end_date, dx_end >= start_date)
}

dx_episode_injury <- merged %>%
  group_by(register_id, start_date, end_date) %>%
  summarise(any_injury = any(any_injury_dx, na.rm = TRUE), .groups = "drop") %>%
  filter(any_injury)

# Collapsed injury days from dxfile (union of intervals per person)
dx_injury_intervals <- dx_any %>%
  filter(any_injury_dx) %>%
  transmute(
    register_id = .data[[DX_ID_COL]],
    start_date = if (nzchar(DX_DATE_COL)) as_date_yyyymmdd(.data[[DX_DATE_COL]]) else as_date_yyyymmdd(.data[[DX_START_COL]]),
    end_date   = if (nzchar(DX_DATE_COL)) as_date_yyyymmdd(.data[[DX_DATE_COL]]) else as_date_yyyymmdd(.data[[DX_END_COL]])
  ) %>%
  filter(!is.na(start_date), !is.na(end_date), end_date >= start_date)

collapsed_days <- dx_injury_intervals %>%
  mutate(start_date = as.Date(start_date), end_date = as.Date(end_date)) %>%
  group_by(register_id) %>%
  summarise(injury_hosp_days_collapsed_dx = collapse_days_union(pick(start_date, end_date)), .groups = "drop")

dx_injury_intervals_t98 <- dx_any %>%
  filter(any_injury_dx_t98) %>%
  transmute(
    register_id = .data[[DX_ID_COL]],
    start_date = if (nzchar(DX_DATE_COL)) as_date_yyyymmdd(.data[[DX_DATE_COL]]) else as_date_yyyymmdd(.data[[DX_START_COL]]),
    end_date   = if (nzchar(DX_DATE_COL)) as_date_yyyymmdd(.data[[DX_DATE_COL]]) else as_date_yyyymmdd(.data[[DX_END_COL]])
  ) %>%
  filter(!is.na(start_date), !is.na(end_date), end_date >= start_date)

collapsed_days_t98 <- dx_injury_intervals_t98 %>%
  mutate(start_date = as.Date(start_date), end_date = as.Date(end_date)) %>%
  group_by(register_id) %>%
  summarise(injury_hosp_days_collapsed_dx_t98 = collapse_days_union(pick(start_date, end_date)), .groups = "drop")

hosp_episode_counts2_injury <- dx_episode_injury %>%
  distinct(register_id, start_date, end_date) %>%
  count(register_id, name = "injury_hosp_ep_episodefile")

hosp_days_sum2_injury <- dx_episode_injury %>%
  distinct(register_id, start_date, end_date) %>%
  mutate(days = as.numeric(end_date - start_date) + 1) %>%
  group_by(register_id) %>%
  summarise(injury_hosp_days_episodefile = sum(days, na.rm = TRUE), .groups = "drop")

# ---- Join to cohort and aggregate ----
analytic <- aim2 %>%
  inner_join(link_tbl, by = "id") %>%
  left_join(injury_visit_pdgo, by = "register_id") %>%
  left_join(injury_visit_any,  by = "register_id") %>%
  left_join(ward_episode_counts, by = "register_id") %>%
  left_join(ward_days_sum, by = "register_id") %>%
  left_join(ward_episode_counts_injury, by = "register_id") %>%
  left_join(ward_days_sum_injury, by = "register_id")

analytic <- analytic %>%
  left_join(hosp_episode_counts2, by = "register_id") %>%
  left_join(hosp_days_sum2, by = "register_id") %>%
  left_join(hosp_episode_counts2_injury, by = "register_id") %>%
  left_join(hosp_days_sum2_injury, by = "register_id") %>%
  left_join(collapsed_days, by = "register_id") %>%
  left_join(collapsed_days_t98, by = "register_id")

analytic <- analytic %>%
  mutate(
    outpatient_injury_visits_pdgo = replace_na(outpatient_injury_visits_pdgo, 0L),
    outpatient_injury_visits_anydx = replace_na(outpatient_injury_visits_anydx, 0L),
    hospital_episodes_from_dxfile = replace_na(hospital_episodes_from_dxfile, 0L),
    hospital_days_from_dxfile = replace_na(hospital_days_from_dxfile, 0),
    injury_hosp_ep_dxfile = replace_na(injury_hosp_ep_dxfile, 0L),
    injury_hosp_days_dxfile = replace_na(injury_hosp_days_dxfile, 0),
    injury_hosp_days_collapsed_dx = replace_na(injury_hosp_days_collapsed_dx, 0),
    injury_hosp_days_collapsed_dx_t98 = replace_na(injury_hosp_days_collapsed_dx_t98, 0)
  ) %>%
  mutate(person_years = as.numeric(followup_days) / 365.25)

post_counts <- analytic %>%
  filter(FOF_status %in% c(0, 1)) %>%
  summarise(
    post_n_fof0 = sum(FOF_status == 0, na.rm = TRUE),
    post_n_fof1 = sum(FOF_status == 1, na.rm = TRUE)
  )

summarise_block <- function(df) {
  df %>%
    summarise(
      n = n(),
      py = sum(person_years, na.rm = TRUE),
      outpatient_pdgo_events = sum(outpatient_injury_visits_pdgo, na.rm = TRUE),
      outpatient_anydx_events = sum(outpatient_injury_visits_anydx, na.rm = TRUE),
      hosp_ep_dxfile = sum(hospital_episodes_from_dxfile, na.rm = TRUE),
      hosp_days_dxfile = sum(hospital_days_from_dxfile, na.rm = TRUE),
      injury_hosp_ep_dxfile = sum(injury_hosp_ep_dxfile, na.rm = TRUE),
      injury_hosp_days_dxfile = sum(injury_hosp_days_dxfile, na.rm = TRUE),
      injury_hosp_days_collapsed_dx = sum(injury_hosp_days_collapsed_dx, na.rm = TRUE),
      injury_hosp_days_collapsed_dx_t98 = sum(injury_hosp_days_collapsed_dx_t98, na.rm = TRUE),
      hosp_ep_episodefile = if ("hospital_episodes_from_episodefile" %in% names(.)) sum(hospital_episodes_from_episodefile, na.rm = TRUE) else NA_real_,
      hosp_days_episodefile = if ("hospital_days_from_episodefile" %in% names(.)) sum(hospital_days_from_episodefile, na.rm = TRUE) else NA_real_,
      injury_hosp_ep_episodefile = if ("injury_hosp_ep_episodefile" %in% names(.)) sum(injury_hosp_ep_episodefile, na.rm = TRUE) else NA_real_,
      injury_hosp_days_episodefile = if ("injury_hosp_days_episodefile" %in% names(.)) sum(injury_hosp_days_episodefile, na.rm = TRUE) else NA_real_,
      .groups = "drop"
    ) %>%
    mutate(
      outpatient_pdgo_rate_1000py = rate_per_1000(outpatient_pdgo_events, py),
      outpatient_anydx_rate_1000py = rate_per_1000(outpatient_anydx_events, py),
      hosp_ep_dxfile_rate_1000py = rate_per_1000(hosp_ep_dxfile, py),
      hosp_days_dxfile_rate_1000py = rate_per_1000(hosp_days_dxfile, py),
      injury_hosp_ep_dxfile_rate_1000py = rate_per_1000(injury_hosp_ep_dxfile, py),
      injury_hosp_days_dxfile_rate_1000py = rate_per_1000(injury_hosp_days_dxfile, py),
      injury_hosp_days_collapsed_dx_rate_1000py = rate_per_1000(injury_hosp_days_collapsed_dx, py),
      injury_hosp_days_collapsed_dx_t98_rate_1000py = rate_per_1000(injury_hosp_days_collapsed_dx_t98, py),
      hosp_ep_episodefile_rate_1000py = rate_per_1000(hosp_ep_episodefile, py),
      hosp_days_episodefile_rate_1000py = rate_per_1000(hosp_days_episodefile, py),
      injury_hosp_ep_episodefile_rate_1000py = rate_per_1000(injury_hosp_ep_episodefile, py),
      injury_hosp_days_episodefile_rate_1000py = rate_per_1000(injury_hosp_days_episodefile, py)
    ) %>%
    mutate(
      pre_n_total = pre_counts$pre_n_total,
      pre_n_fof0 = pre_counts$pre_n_fof0,
      pre_n_fof1 = pre_counts$pre_n_fof1,
      pre_n_invalid_fof = pre_counts$pre_n_invalid_fof,
      post_n_fof0 = post_counts$post_n_fof0,
      post_n_fof1 = post_counts$post_n_fof1
    )
}

sum_by_fof <- analytic %>%
  filter(FOF_status %in% c(0, 1)) %>%
  group_by(FOF_status) %>%
  summarise_block() %>%
  left_join(drop_counts_by_fof, by = "FOF_status")

sum_overall <- analytic %>%
  filter(FOF_status %in% c(0, 1)) %>%
  summarise_block() %>%
  mutate(
    FOF_status = -1L,
    drop_missing_sex = drop_counts$drop_missing_sex,
    drop_missing_age = drop_counts$drop_missing_age,
    drop_missing_followup = drop_counts$drop_missing_followup,
    drop_nonpositive_py = drop_counts$drop_nonpositive_py
  )

out <- bind_rows(sum_by_fof, sum_overall) %>%
  mutate(FOF_group = case_when(
    FOF_status == 0 ~ "FOF_No",
    FOF_status == 1 ~ "FOF_Yes",
    TRUE ~ "Overall"
  )) %>%
  select(
    FOF_group, n, py,
    outpatient_pdgo_events, outpatient_pdgo_rate_1000py,
    outpatient_anydx_events, outpatient_anydx_rate_1000py,
    hosp_ep_dxfile, hosp_ep_dxfile_rate_1000py,
    hosp_days_dxfile, hosp_days_dxfile_rate_1000py,
    injury_hosp_ep_dxfile, injury_hosp_ep_dxfile_rate_1000py,
    injury_hosp_days_dxfile, injury_hosp_days_dxfile_rate_1000py,
    injury_hosp_days_collapsed_dx, injury_hosp_days_collapsed_dx_rate_1000py,
    injury_hosp_days_collapsed_dx_t98, injury_hosp_days_collapsed_dx_t98_rate_1000py,
    hosp_ep_episodefile, hosp_ep_episodefile_rate_1000py,
    hosp_days_episodefile, hosp_days_episodefile_rate_1000py,
    injury_hosp_ep_episodefile, injury_hosp_ep_episodefile_rate_1000py,
    injury_hosp_days_episodefile, injury_hosp_days_episodefile_rate_1000py,
    pre_n_total, pre_n_fof0, pre_n_fof1, pre_n_invalid_fof,
    post_n_fof0, post_n_fof1,
    drop_missing_sex, drop_missing_age, drop_missing_followup, drop_nonpositive_py
  )

out_path <- file.path("R", "15_table2", "outputs", "table2_qc_summary.csv")
readr::write_csv(out, out_path, na = "")

log_msg("QC summary written (path redacted).")
