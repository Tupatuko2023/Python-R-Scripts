#!/usr/bin/env Rscript
# scripts/debug_hospital_reconciliation.R
# Purpose: Safe Schema Discovery & Prototyping for Hospital Outcome (Option B compliant)
# Security: No paths printed, no ID values printed. Aggregated rates only.

suppressPackageStartupMessages({
  library(dplyr)
  library(readxl)
  library(stringr)
  library(fs)
  library(readr)
})

log_msg <- function(...) {
  msg <- paste0(...)
  cat(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "|", msg, "\n")
}

# Load common.R if present
if (file.exists("R/common.R")) {
  source("R/common.R")
}

DATA_ROOT <- Sys.getenv("DATA_ROOT", "")
if (!nzchar(DATA_ROOT)) {
    if (file.exists("R/common.R")) {
        DATA_ROOT <- tryCatch(ensure_data_root(), error = function(e) "") 
    }
}
if (!nzchar(DATA_ROOT)) stop("Missing DATA_ROOT", call. = FALSE)

safe_list_files <- function(root) {
  files <- tryCatch(fs::dir_ls(root, recurse = TRUE, type = "file"), error = function(e) character(0))
  tibble::tibble(file = fs::path_file(files), full_path = as.character(files)) %>% dplyr::arrange(file)
}

safe_read_xlsx <- function(path, sheet = 1) {
  bn <- fs::path_file(path)
  df <- readxl::read_xlsx(path, sheet = sheet)
  log_msg("Loaded: ", bn, " | nrow=", nrow(df), " | ncol=", ncol(df))
  df
}

log_msg("DEBUG START: Hospital Rate Prototyping (Safe Merge)")

inv <- safe_list_files(DATA_ROOT)

# Locate files
ep_path <- inv$full_path[str_detect(inv$file, "KAAOS")][1]
dx_path <- inv$full_path[str_detect(inv$file, "sotut")][1] # In synthetic, dx is in sotut for now

if (is.na(ep_path) || is.na(dx_path)) stop("Missing input files in DATA_ROOT", call. = FALSE)

ep_df <- safe_read_xlsx(ep_path)
dx_df <- safe_read_xlsx(dx_path)

# Normalize column names for merge prototyping
# In synthetic: both have potilas_id
# KAAOS (episodes) has: potilas_id, osastojakso_id, vastaan-otto pvm, BMI, etc.
# sotut (dx) has: potilas_id, Sotu, pdgo (added in generator)

# SAFE MERGE: Check for unique episode ID first
has_episode_id <- "osastojakso_id" %in% names(ep_df) && "osastojakso_id" %in% names(dx_df)

if (has_episode_id) {
    log_msg("Joining by osastojakso_id (Preferred)")
    joined <- ep_df %>% left_join(dx_df, by = "osastojakso_id")
} else {
    log_msg("Joining by potilas_id (Date-bounded join prototype)")
    # Since synthetic dx_df might not have dates, we'll assume a 1:1 or 1:N mapping for now
    # In real data, we would use: filter(diag_date >= start & diag_date <= end)
    joined <- ep_df %>% left_join(dx_df, by = "potilas_id")
}

# Identify Injury Episodes
# Protocol: pdgo starts with S or T (ICD-10)
if (!"pdgo" %in% names(joined)) {
    # Fallback if col name different
    diag_col <- names(joined)[str_detect(tolower(names(joined)), "pdgo|diag|dg")][1]
    if (!is.na(diag_col)) joined$pdgo <- joined[[diag_col]]
}

joined <- joined %>%
  mutate(is_injury = str_detect(pdgo, "^[ST]"))

# Aggregate by episode
# Synthetic has one row per episode usually, but real data has multiple dx per episode
episode_summary <- joined %>%
  group_by(potilas_id, osastojakso_id) %>%
  summarise(
    is_injury_episode = any(is_injury, na.rm = TRUE),
    episode_count = 1,
    .groups = "drop"
  )

# Calculate Rates
n_injury_episodes <- sum(episode_summary$is_injury_episode, na.rm = TRUE)
total_persons <- n_distinct(episode_summary$potilas_id)

# Assumption: Person-Years for synthetic 100 persons ~ 100 PY for simplicity of prototype
py_estimate <- total_persons * 1.0 

rate_per_1000py <- (n_injury_episodes / py_estimate) * 1000

log_msg("PROTOTYPE RESULTS:")
log_msg("Total episodes processed: ", nrow(episode_summary))
log_msg("Injury episodes identified: ", n_injury_episodes)
log_msg("Calculated Rate per 1000 PY (Prototype): ", round(rate_per_1000py, 1))

log_msg("Target comparison: ~378.2 (Manuscript)")

log_msg("DEBUG END")
