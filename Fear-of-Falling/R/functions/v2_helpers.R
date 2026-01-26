# R/functions/v2_helpers.R
# Minimal shared helpers for K15/K16 V2 scripts

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
})

detect_is_long <- function(df, id_col = "ID", time_cols = c("time", "time_f")) {
  has_time <- any(time_cols %in% names(df))
  if (!has_time && id_col %in% names(df) && anyDuplicated(df[[id_col]]) > 0) {
    warning("Duplicate IDs detected without time/time_f; treating as wide data.")
  }
  has_time
}

v2_qc_missing_by_group <- function(df, group_col = "FOF_status", metrics) {
  if (!(group_col %in% names(df))) {
    stop("Group column not found: ", group_col)
  }
  if (!all(metrics %in% names(df))) {
    missing <- setdiff(metrics, names(df))
    stop("Missing metrics for QC: ", paste(missing, collapse = ", "))
  }
  df %>%
    mutate(
      FOF_group = factor(.data[[group_col]],
                         levels = c(0, 1),
                         labels = c("nonFOF", "FOF"))
    ) %>%
    group_by(FOF_group) %>%
    summarise(
      n = n(),
      across(all_of(metrics), ~ sum(is.na(.)), .names = "missing_{.col}"),
      .groups = "drop"
    )
}
