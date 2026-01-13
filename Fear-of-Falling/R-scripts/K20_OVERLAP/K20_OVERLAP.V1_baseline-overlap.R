#!/usr/bin/env Rscript
# ==============================================================================
# K20_OVERLAP - Baseline overlap: FOF_status x frailty_cat_3 (2x3)
# File tag: K20_OVERLAP.V1_baseline-overlap.R
# Purpose: Visualize baseline overlap between FOF_status and frailty_cat_3.
#
# Outcome: None (descriptive overlap)
# Predictors: FOF_status, frailty_cat_3
# Grouping variable: id (distinct baseline row)
# Covariates: None
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# id, FOF_status, frailty_cat_3
#
# Mapping example (optional; raw -> analysis; keep minimal + explicit):
# K15_frailty_analysis_data.RData -> analysis_data (id, FOF_status, frailty_cat_3)
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: N/A (no randomness)
#
# Outputs + manifest:
# - script_label: K20_OVERLAP (canonical)
# - outputs dir: R-scripts/K20_OVERLAP/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load frailty-augmented dataset (K15 artifact; fallback run K15)
# 03) Required vars + baseline distinct(id) + ID uniqueness check
# 04) Missingness summary (audit trail)
# 05) Cross-tab (n + row%) + small cell flags
# 06) Heatmap plot (row% with n labels)
# 07) Spine-style proportion plot (row% by frailty within FOF_status)
# 08) Save artifacts -> R-scripts/K20_OVERLAP/outputs/
# 09) Append manifest row per artifact
# 10) Save sessionInfo to manifest/
# 11) EOF marker
# ==============================================================================
#
suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(readr)
  library(tidyr)
  library(ggplot2)
  library(tibble)
})

# --- Standard init (MANDATORY) -----------------------------------------------
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K20_OVERLAP"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K20_OVERLAP"

source(here::here("R", "functions", "init.R"))
source(here::here("R", "functions", "reporting.R"))

paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

cat("================================================================================\n")
cat("K20 baseline overlap: FOF_status x frailty_cat_3\n")
cat("Script label:", script_label, "\n")
cat("Outputs dir:", outputs_dir, "\n")
cat("Manifest:", manifest_path, "\n")
cat("Project root:", here::here(), "\n")
cat("================================================================================\n\n")

# --- Load K15 frailty artifact (preferred; fallback run K15) -------------------
find_k15_artifacts <- function() {
  k15_dirs <- c(
    here::here("R-scripts", "K15", "outputs"),
    here::here("R-scripts", "K15_MAIN", "outputs")
  )
  k15_dirs <- k15_dirs[file.exists(k15_dirs)]
  patterns <- c("frailty.*\\.(RData|rds)$", "K15.*\\.(RData|rds)$")

  candidates <- unlist(lapply(k15_dirs, function(dir_path) {
    unlist(lapply(patterns, function(pat) {
      list.files(dir_path, pattern = pat, full.names = TRUE, ignore.case = TRUE)
    }))
  }))
  unique(candidates)
}

load_k15_rdata <- function(path) {
  env <- new.env(parent = emptyenv())
  loaded <- load(path, envir = env)
  preferred <- intersect(c("analysis_data", "data_final", "df"), loaded)
  if (length(preferred) > 0) {
    return(get(preferred[1], envir = env))
  }
  for (obj_name in loaded) {
    obj <- get(obj_name, envir = env)
    if (is.data.frame(obj)) return(obj)
  }
  stop("K20_OVERLAP: No data.frame object found in: ", basename(path))
}

df <- NULL
k15_candidates <- find_k15_artifacts()

if (length(k15_candidates) > 0) {
  k15_path <- k15_candidates[1]
  message("K20_OVERLAP: Loading K15 artifact: ", k15_path)
  if (grepl("\\.rds$", k15_path, ignore.case = TRUE)) {
    df <- readRDS(k15_path)
  } else {
    df <- load_k15_rdata(k15_path)
  }
} else {
  message("K20_OVERLAP: No K15 artifact found. Running K15 to generate frailty data.")
  run_status <- system("Rscript R-scripts/K15/K15.R")
  if (!is.null(run_status) && run_status != 0) {
    stop("K20_OVERLAP: K15 run failed with status: ", run_status)
  }
  k15_candidates <- find_k15_artifacts()
  if (length(k15_candidates) == 0) {
    stop("K20_OVERLAP: K15 did not produce a loadable artifact under R-scripts/K15*/outputs/.")
  }
  k15_path <- k15_candidates[1]
  message("K20_OVERLAP: Loading K15 artifact: ", k15_path)
  if (grepl("\\.rds$", k15_path, ignore.case = TRUE)) {
    df <- readRDS(k15_path)
  } else {
    df <- load_k15_rdata(k15_path)
  }
}

if (!is.data.frame(df)) stop("K20_OVERLAP: Loaded object is not a data.frame/tibble.")

# --- Required vars + baseline distinct(id) ------------------------------------
req_cols <- c("id", "FOF_status", "frailty_cat_3")
missing_cols <- setdiff(req_cols, names(df))
if (length(missing_cols) > 0) {
  stop("K20_OVERLAP: Missing required columns: ", paste(missing_cols, collapse = ", "))
}

standardize_fof <- function(x) {
  x0 <- tolower(trimws(as.character(x)))
  out <- dplyr::case_when(
    x0 %in% c("0", "false", "no", "nofof", "nonfof", "ei fof") ~ "nonFOF",
    x0 %in% c("1", "true", "fof") ~ "FOF",
    TRUE ~ NA_character_
  )
  factor(out, levels = c("nonFOF", "FOF"))
}

standardize_frailty <- function(x) {
  x0 <- tolower(trimws(as.character(x)))
  out <- dplyr::case_when(
    x0 %in% c("robust") ~ "robust",
    grepl("^pre", x0) ~ "pre-frail",
    x0 %in% c("frail") ~ "frail",
    TRUE ~ NA_character_
  )
  factor(out, levels = c("robust", "pre-frail", "frail"))
}

df_base <- df %>%
  distinct(id, .keep_all = TRUE) %>%
  mutate(
    FOF_status = standardize_fof(FOF_status),
    frailty_cat_3 = standardize_frailty(frailty_cat_3)
  )

if (dplyr::n_distinct(df_base$id) != nrow(df_base)) {
  stop("K20_OVERLAP: id is not unique after distinct().")
}

# --- Missingness summary (audit trail) ---------------------------------------
missingness <- tibble::tibble(
  n_total = nrow(df_base),
  n_missing_FOF = sum(is.na(df_base$FOF_status)),
  n_missing_frailty = sum(is.na(df_base$frailty_cat_3)),
  n_missing_any = sum(is.na(df_base$FOF_status) | is.na(df_base$frailty_cat_3))
)

miss_path <- file.path(outputs_dir, "K20_baseline_overlap_missingness.csv")
readr::write_csv(missingness, miss_path)

missing_note <- if (missingness$n_missing_any > 0) {
  "missingness present (n_missing_any > 0)"
} else {
  NA_character_
}

append_manifest(
  manifest_row(
    script = script_label,
    label = "K20_baseline_overlap_missingness",
    path = get_relpath(miss_path),
    kind = "table_csv",
    n = nrow(df_base),
    notes = missing_note
  ),
  manifest_path
)

if (!is.na(missing_note)) {
  message("K20_OVERLAP: Missingness present (see K20_baseline_overlap_missingness.csv).")
}

# --- Cross-tab (n + row%) + small cell flags ---------------------------------
tab <- df_base %>%
  filter(!is.na(FOF_status), !is.na(frailty_cat_3)) %>%
  count(FOF_status, frailty_cat_3, name = "n") %>%
  tidyr::complete(
    FOF_status = factor(c("nonFOF", "FOF"), levels = c("nonFOF", "FOF")),
    frailty_cat_3 = factor(c("robust", "pre-frail", "frail"), levels = c("robust", "pre-frail", "frail")),
    fill = list(n = 0)
  ) %>%
  group_by(FOF_status) %>%
  mutate(
    row_total = sum(n),
    row_pct = if_else(row_total > 0, n / row_total, NA_real_),
    small_cell = n < 5L
  ) %>%
  ungroup() %>%
  select(FOF_status, frailty_cat_3, n, row_pct, small_cell)

tab_path <- file.path(outputs_dir, "K20_baseline_overlap_table.csv")
readr::write_csv(tab, tab_path)

small_cell_note <- if (any(tab$small_cell, na.rm = TRUE)) {
  "small cells present (n < 5)"
} else {
  NA_character_
}

append_manifest(
  manifest_row(
    script = script_label,
    label = "K20_baseline_overlap_table",
    path = get_relpath(tab_path),
    kind = "table_csv",
    n = nrow(df_base),
    notes = small_cell_note
  ),
  manifest_path
)

if (!is.na(small_cell_note)) {
  message("K20_OVERLAP: Small cells present (n < 5).")
}

# --- Plot 1: Heatmap (row% with n labels) ------------------------------------
p_heat <- ggplot(tab, aes(x = frailty_cat_3, y = FOF_status, fill = row_pct)) +
  geom_tile(color = "white") +
  geom_text(
    aes(label = ifelse(is.na(row_pct), "NA", paste0(n, " (", sprintf("%.1f", 100 * row_pct), "%)"))),
    size = 3
  ) +
  scale_fill_gradient(low = "#f0f0f0", high = "#2c7fb8", na.value = "#f7f7f7") +
  labs(
    title = "Baseline overlap: FOF_status x frailty_cat_3",
    subtitle = "Cells show n and row% within FOF_status (descriptive)",
    x = "Frailty category (3 levels)",
    y = "FOF status",
    fill = "Row %"
  ) +
  theme_minimal()

heat_path <- file.path(outputs_dir, "K20_baseline_overlap_heatmap.png")
ggsave(filename = heat_path, plot = p_heat, width = 6, height = 4, dpi = 300)

append_manifest(
  manifest_row(
    script = script_label,
    label = "K20_baseline_overlap_heatmap",
    path = get_relpath(heat_path),
    kind = "figure_png",
    n = nrow(df_base)
  ),
  manifest_path
)

# --- Plot 2: Spine-style proportion plot -------------------------------------
p_spine <- ggplot(tab, aes(x = frailty_cat_3, y = row_pct)) +
  geom_col(fill = "#3b8bc2") +
  facet_wrap(~ FOF_status, nrow = 1) +
  geom_text(
    aes(label = ifelse(is.na(row_pct), "NA", paste0("n=", n))),
    vjust = -0.2,
    size = 3
  ) +
  scale_y_continuous(
    labels = function(x) paste0(sprintf("%.0f", 100 * x), "%"),
    limits = c(0, 1)
  ) +
  labs(
    title = "Baseline overlap (row proportions)",
    subtitle = "Frailty distribution within each FOF_status group",
    x = "Frailty category (3 levels)",
    y = "Row proportion"
  ) +
  theme_minimal()

spine_path <- file.path(outputs_dir, "K20_baseline_overlap_spine.png")
ggsave(filename = spine_path, plot = p_spine, width = 7, height = 3.8, dpi = 300)

append_manifest(
  manifest_row(
    script = script_label,
    label = "K20_baseline_overlap_spine",
    path = get_relpath(spine_path),
    kind = "figure_png",
    n = nrow(df_base)
  ),
  manifest_path
)

# --- Session info -------------------------------------------------------------
save_sessioninfo_manifest()

message("K20_OVERLAP: DONE")
message("  - Outputs dir: ", outputs_dir)
message("  - Heatmap: ", heat_path)
message("  - Spine: ", spine_path)
