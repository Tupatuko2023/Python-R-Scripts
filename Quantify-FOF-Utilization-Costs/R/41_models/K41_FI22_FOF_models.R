#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(readxl)
})

clean_names_simple <- function(x) {
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", "_", x)
  x <- gsub("_+", "_", x)
  x <- gsub("^_|_$", "", x)
  make.unique(x, sep = "_")
}

find_col <- function(nms, candidates) {
  hit <- intersect(candidates, nms)
  if (length(hit) == 0) return(NA_character_)
  hit[[1]]
}

resolve_data_root <- function() {
  dr <- Sys.getenv("DATA_ROOT", "")
  if (nzchar(dr)) return(dr)
  stop("DATA_ROOT is required.", call. = FALSE)
}

resolve_id_column <- function(df) {
  id_override_raw <- Sys.getenv("ID_COL", "")
  if (nzchar(id_override_raw)) {
    id_override_clean <- clean_names_simple(id_override_raw)
    if (id_override_clean %in% names(df)) return(id_override_clean)
    stop(sprintf("ID_COL '%s' not found after name cleaning.", id_override_raw), call. = FALSE)
  }

  id_named <- find_col(names(df), c("id", "participant_id", "subject_id", "study_id", "nro", "jnro", "1"))
  if (!is.na(id_named)) return(id_named)

  n <- nrow(df)
  prof <- lapply(names(df), function(vn) {
    x <- df[[vn]]
    type_ok <- is.character(x) || is.integer(x) || is.numeric(x)
    miss_rate <- mean(is.na(x))
    uniq_ratio <- dplyr::n_distinct(x[!is.na(x)]) / n
    tibble::tibble(var_name = vn, type_ok = type_ok, miss_rate = miss_rate, uniq_ratio = uniq_ratio)
  }) %>% bind_rows() %>%
    filter(type_ok, miss_rate <= 0.05, uniq_ratio >= 0.90) %>%
    arrange(desc(uniq_ratio), miss_rate, var_name)

  if (nrow(prof) == 0) stop("Could not resolve id column.", call. = FALSE)
  prof$var_name[[1]]
}

detect_label_row <- function(df, id_col) {
  if (nrow(df) == 0 || !(id_col %in% names(df))) return(FALSE)
  first_row <- df[1, , drop = FALSE]
  id_token <- tolower(trimws(as.character(first_row[[id_col]][1])))
  id_ok <- id_token %in% c("nro", "id", "participant", "subject")
  other_vals <- trimws(as.character(first_row[1, setdiff(names(df), id_col), drop = TRUE]))
  labelish_hits <- sum(!is.na(other_vals) & (nchar(other_vals) >= 20 | grepl("0\\s*=|1\\s*=|2\\s*=", other_vals, perl = TRUE)))
  isTRUE(id_ok && labelish_hits >= 2)
}

to_numeric <- function(x) suppressWarnings(as.numeric(trimws(as.character(x))))

run_id <- format(Sys.time(), "%Y%m%d_%H%M%S")
outputs_dir <- file.path("R", "41_models", "outputs", run_id)
dir.create(outputs_dir, recursive = TRUE, showWarnings = FALSE)

data_root <- resolve_data_root()
xlsx_path <- file.path(data_root, "paper_02", "KAAOS_data.xlsx")
fi_path <- file.path(data_root, "paper_02", "frailty_vulnerability", "kaaos_with_frailty_index_k40.csv")

if (!file.exists(xlsx_path)) stop("Missing KAAOS_data.xlsx under DATA_ROOT.", call. = FALSE)
if (!file.exists(fi_path)) stop("Missing K40 FI patient-level csv under DATA_ROOT.", call. = FALSE)

sheets <- readxl::excel_sheets(xlsx_path)
sheet_use <- sheets[[1]]
raw_df <- readxl::read_excel(xlsx_path, sheet = sheet_use, guess_max = 5000)
raw_df <- tibble::as_tibble(raw_df)
names(raw_df) <- clean_names_simple(names(raw_df))

id_col <- resolve_id_column(raw_df)
if (detect_label_row(raw_df, id_col)) raw_df <- raw_df[-1, , drop = FALSE]

age_col <- find_col(names(raw_df), c("2_1", "age", "ika"))
sex_col <- find_col(names(raw_df), c("3", "sex", "sukupuoli"))
fof_col <- find_col(names(raw_df), c("32", "fof", "kaatumisen_pelko"))
if (any(is.na(c(age_col, sex_col, fof_col)))) {
  stop("Could not resolve one or more required columns (age, sex, fof).", call. = FALSE)
}

base_df <- raw_df %>%
  mutate(id = as.character(.data[[id_col]])) %>%
  arrange(id) %>%
  group_by(id) %>%
  slice(1L) %>%
  ungroup() %>%
  transmute(
    id = as.character(id),
    age = to_numeric(.data[[age_col]]),
    sex_num = to_numeric(.data[[sex_col]]),
    fof_num = to_numeric(.data[[fof_col]])
  ) %>%
  mutate(
    fof_yes = ifelse(fof_num %in% c(0, 1), fof_num, NA_real_),
    sex = case_when(
      sex_num == 0 ~ "female",
      sex_num == 1 ~ "male",
      TRUE ~ NA_character_
    )
  )

fi_df <- readr::read_csv(fi_path, show_col_types = FALSE) %>%
  transmute(
    id = as.character(id),
    fi = as.numeric(frailty_index_fi)
  )

model_df <- base_df %>%
  inner_join(fi_df, by = "id") %>%
  filter(!is.na(fi), !is.na(fof_yes), !is.na(age), !is.na(sex)) %>%
  mutate(sex = factor(sex, levels = c("female", "male")))

summary_tbl <- tibble::tibble(
  metric = c("run_id", "n_rows_model", "fof_yes_rate", "fi_mean", "fi_sd", "age_mean", "age_sd"),
  value = c(
    run_id,
    as.character(nrow(model_df)),
    as.character(mean(model_df$fof_yes, na.rm = TRUE)),
    as.character(mean(model_df$fi, na.rm = TRUE)),
    as.character(sd(model_df$fi, na.rm = TRUE)),
    as.character(mean(model_df$age, na.rm = TRUE)),
    as.character(sd(model_df$age, na.rm = TRUE))
  )
)
readr::write_csv(summary_tbl, file.path(outputs_dir, "k41_fi22_dataset_summary.csv"))

open_plot_device <- function(path_stub, width = 1200, height = 800, res = 120) {
  png_path <- paste0(path_stub, ".png")
  pdf_path <- paste0(path_stub, ".pdf")

  ok <- tryCatch({
    if (capabilities("cairo")) {
      png(png_path, width = width, height = height, res = res, type = "cairo")
    } else {
      png(png_path, width = width, height = height, res = res)
    }
    TRUE
  }, error = function(e) FALSE)

  if (ok) return(png_path)

  pdf(pdf_path, width = 10, height = 6.67)
  pdf_path
}

# Figure 1: FI histogram
fig_hist_path <- open_plot_device(file.path(outputs_dir, "k41_fi22_histogram"))
hist(model_df$fi,
  breaks = 20,
  col = "#4C78A8",
  border = "white",
  main = "FI22_nonperformance_KAAOS Distribution",
  xlab = "Frailty Index (FI)"
)
dev.off()

# Figure 2: FI vs age with linear trend
fi_age_fit <- lm(fi ~ age, data = model_df)
fi_age_coef <- coef(summary(fi_age_fit))

fig_age_path <- open_plot_device(file.path(outputs_dir, "k41_fi22_vs_age"))
plot(model_df$age, model_df$fi,
  pch = 16,
  col = rgb(0.30, 0.47, 0.66, 0.35),
  xlab = "Age (years)",
  ylab = "Frailty Index (FI)",
  main = "FI22 vs Age"
)
abline(fi_age_fit, col = "#D62728", lwd = 2)
dev.off()

fit <- glm(fof_yes ~ fi + age + sex, data = model_df, family = binomial())
co <- coef(summary(fit))

or_tbl <- tibble::tibble(
  term = rownames(co),
  estimate = co[, "Estimate"],
  std_error = co[, "Std. Error"],
  z_value = co[, "z value"],
  p_value = co[, "Pr(>|z|)"],
  odds_ratio = exp(estimate),
  conf_low = exp(estimate - 1.96 * std_error),
  conf_high = exp(estimate + 1.96 * std_error)
)
readr::write_csv(or_tbl, file.path(outputs_dir, "k41_fi22_fof_model_or.csv"))

fi_age_tbl <- tibble::tibble(
  metric = c("corr_fi_age", "beta_age_lm_fi_on_age", "p_age_lm_fi_on_age"),
  value = c(
    suppressWarnings(cor(model_df$fi, model_df$age, use = "complete.obs")),
    fi_age_coef["age", "Estimate"],
    fi_age_coef["age", "Pr(>|t|)"]
  )
)
readr::write_csv(fi_age_tbl, file.path(outputs_dir, "k41_fi22_age_trend_summary.csv"))

log_lines <- c(
  sprintf("run_id=%s", run_id),
  sprintf("sheet_selected=%s", sheet_use),
  sprintf("id_col=%s", id_col),
  sprintf("age_col=%s", age_col),
  sprintf("sex_col=%s", sex_col),
  sprintf("fof_col=%s", fof_col),
  sprintf("n_rows_model=%d", nrow(model_df)),
  sprintf("fig_hist=%s", basename(fig_hist_path)),
  sprintf("fig_fi_vs_age=%s", basename(fig_age_path)),
  "model=glm_binomial(fof_yes ~ fi + age + sex)",
  "fi_variant=FI22_nonperformance_KAAOS"
)
writeLines(log_lines, con = file.path(outputs_dir, "k41_fi22_run_log.txt"))

message("K41_FI22_FOF_models completed.")
message(sprintf("Outputs: %s", outputs_dir))
