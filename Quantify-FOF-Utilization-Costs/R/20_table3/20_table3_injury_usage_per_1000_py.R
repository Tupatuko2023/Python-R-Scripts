#!/usr/bin/env Rscript
# Table 3 generation (case vs control, per 1000 patient-years)
# Based on a user-provided local draft (untracked file):
# R/20_Table_3_Injury_related_Health_Care_Usage_vs_control_per_1000_PY.R
# Adapted to project conventions and Snakemake-compatible IO.

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(stringr)
  library(tidyr)
  library(purrr)
  library(broom)
  library(readxl)
  library(MASS)
})

parse_cli_args <- function(defaults) {
  args <- commandArgs(trailingOnly = TRUE)
  out <- defaults
  i <- 1
  while (i <= length(args)) {
    a <- args[[i]]
    if (a == "--make_docx") {
      out$make_docx <- TRUE
      i <- i + 1
      next
    }
    if (!startsWith(a, "--")) {
      stop("Unexpected argument: ", a)
    }
    key <- sub("^--", "", a)
    if ((i + 1) > length(args)) {
      stop("Missing value for argument: ", a)
    }
    val <- args[[i + 1]]
    if (!nzchar(key) || !key %in% names(out)) {
      stop("Unknown argument: ", a)
    }
    out[[key]] <- val
    i <- i + 2
  }
  out
}

opt <- parse_cli_args(list(
  data_root = Sys.getenv("DATA_ROOT", ""),
  output_dir = Sys.getenv("OUTPUT_DIR", "outputs/tables"),
  visits_file = "",
  treat_file = "",
  varmap_file = "data/VARIABLE_STANDARDIZATION.csv",
  visits_source_dataset = "",
  treat_source_dataset = "",
  engine = "negbin",
  seed = "20250130",
  make_docx = FALSE,
  round_rate = "1",
  round_irr = "2"
))

opt$seed <- as.integer(opt$seed)
opt$round_rate <- as.integer(opt$round_rate)
opt$round_irr <- as.integer(opt$round_irr)
set.seed(opt$seed)

stopifnot(opt$engine %in% c("negbin", "poisson"))
stopifnot(nzchar(opt$varmap_file), file.exists(opt$varmap_file))
dir.create(opt$output_dir, recursive = TRUE, showWarnings = FALSE)

resolve_path <- function(path, data_root) {
  if (!nzchar(path)) return(path)
  if (file.exists(path)) return(path)
  if (!nzchar(data_root)) return(path)
  file.path(data_root, path)
}

read_any <- function(path) {
  stopifnot(nzchar(path), file.exists(path))
  if (str_detect(tolower(path), "\\.csv$")) {
    readr::read_csv(path, show_col_types = FALSE)
  } else if (str_detect(tolower(path), "\\.(xlsx|xls)$")) {
    readxl::read_excel(path)
  } else {
    stop("Unsupported input format: ", path)
  }
}

read_varmap_gate <- function(varmap_file, source_dataset = "") {
  vm <- suppressMessages(readr::read_csv(varmap_file, show_col_types = FALSE))
  stopifnot(all(c("source_dataset", "original_variable", "standard_variable") %in% names(vm)))

  vm2 <- vm %>%
    mutate(
      original_variable = as.character(.data$original_variable),
      standard_variable = as.character(.data$standard_variable)
    ) %>%
    filter(!is.na(.data$standard_variable), nzchar(.data$standard_variable)) %>%
    filter(!is.na(.data$original_variable), nzchar(.data$original_variable)) %>%
    filter(!str_detect(.data$original_variable, "FIXME"))

  if (nzchar(source_dataset)) {
    vm2 <- vm2 %>% filter(.data$source_dataset == source_dataset)
  }
  vm2
}

apply_varmap <- function(df, vm) {
  vm_uni <- vm %>%
    group_by(.data$standard_variable) %>%
    slice(1) %>%
    ungroup()

  rename_map <- setNames(vm_uni$standard_variable, vm_uni$original_variable)
  df %>% rename(any_of(rename_map))
}

assert_required_cols <- function(df, req, context = "") {
  missing <- setdiff(req, names(df))
  if (length(missing) > 0) {
    stop(
      "Missing required STANDARD columns",
      if (nzchar(context)) paste0(" (", context, ")") else "",
      ": ", paste(missing, collapse = ", "),
      "\nKB gate: fix data/VARIABLE_STANDARDIZATION.csv mappings (no guessing)."
    )
  }
}

rate_per_1000 <- function(events, py) 1000 * events / py
se_rate_per_1000_poisson <- function(events, py) 1000 * sqrt(events) / py

fmt_mean_se <- function(rate, se, d = 1) sprintf(paste0("%.", d, "f(%.", d, "f)"), rate, se)
fmt_irr_ci <- function(irr, lcl, ucl, d = 2) sprintf(paste0("%.", d, "f(%.", d, "f to %.", d, "f)"), irr, lcl, ucl)
fmt_p <- function(p) {
  if (is.na(p)) return(NA_character_)
  if (p < 0.001) return("p<0.001")
  sprintf("p=%.3f", p)
}

icd10_bucket <- function(x) {
  x2 <- x %>%
    str_to_upper() %>%
    str_trim() %>%
    str_replace_all("\\.", "") %>%
    str_replace_all("\\s+", "")

  core <- str_match(x2, "^([A-Z])(\\d{2})")[, 2:3, drop = FALSE]
  letter <- core[, 1]
  num2 <- suppressWarnings(as.integer(core[, 2]))

  out <- rep(NA_character_, length(x2))
  is_s <- !is.na(letter) & letter == "S" & !is.na(num2) & num2 >= 0 & num2 <= 99
  out[is_s] <- sprintf("S%02d-%02d", floor(num2[is_s] / 10) * 10, floor(num2[is_s] / 10) * 10 + 9)

  is_t <- !is.na(letter) & letter == "T" & !is.na(num2) & num2 >= 0 & num2 <= 14
  out[is_t] <- "T00-14"
  out
}

fit_irr_model <- function(df, engine = "negbin") {
  df <- df %>% mutate(case_status = as.factor(.data$case_status), sex = as.factor(.data$sex))
  if ("control" %in% levels(df$case_status)) {
    df$case_status <- relevel(df$case_status, ref = "control")
  }

  f <- as.formula("event_count ~ case_status + age + sex + offset(log(py))")
  mod <- if (engine == "negbin") {
    MASS::glm.nb(f, data = df)
  } else {
    glm(f, data = df, family = poisson())
  }

  td <- broom::tidy(mod)
  one <- td %>% filter(.data$term == "case_statuscase" | .data$term == "case_status1") %>% slice(1)
  if (nrow(one) == 0) return(list(irr = NA_real_, lcl = NA_real_, ucl = NA_real_, p = NA_real_))

  b <- one$estimate
  se <- one$std.error
  z <- b / se

  list(
    irr = exp(b),
    lcl = exp(b - 1.96 * se),
    ucl = exp(b + 1.96 * se),
    p = 2 * pnorm(-abs(z))
  )
}

REQ_VISITS <- c("fof_status", "case_status", "sex", "age", "py", "icd10_code", "event_count")
REQ_TREAT <- c("fof_status", "case_status", "sex", "age", "py", "event_count")
BUCKET_LEVELS <- c(
  "S00-09", "S10-19", "S20-29", "S30-39", "S40-49", "S50-59", "S60-69", "S70-79", "S80-89", "S90-99", "T00-14",
  "Total", "Treatment periods"
)

visits_path <- resolve_path(opt$visits_file, opt$data_root)
treat_path <- resolve_path(opt$treat_file, opt$data_root)
if (!file.exists(visits_path)) stop("Visits input not found (check DATA_ROOT + visits_file).")
if (!file.exists(treat_path)) stop("Treatment input not found (check DATA_ROOT + treat_file).")

visits_raw <- read_any(visits_path)
treat_raw <- read_any(treat_path)

vm_vis <- read_varmap_gate(opt$varmap_file, opt$visits_source_dataset)
vm_trt <- read_varmap_gate(opt$varmap_file, opt$treat_source_dataset)

# If inputs are already standardized (derived table3_* inputs), do not rename.
visits <- if (all(REQ_VISITS %in% names(visits_raw))) visits_raw else apply_varmap(visits_raw, vm_vis)
treat <- if (all(REQ_TREAT %in% names(treat_raw))) treat_raw else apply_varmap(treat_raw, vm_trt)

assert_required_cols(visits, REQ_VISITS, "visits")
assert_required_cols(treat, REQ_TREAT, "treat")

visits <- visits %>%
  mutate(
    fof_status = as.integer(.data$fof_status),
    py = as.numeric(.data$py),
    event_count = as.numeric(.data$event_count),
    bucket = icd10_bucket(.data$icd10_code)
  )

treat <- treat %>%
  mutate(
    fof_status = as.integer(.data$fof_status),
    py = as.numeric(.data$py),
    event_count = as.numeric(.data$event_count)
  )

agg_panel <- function(df, row_var = "bucket") {
  df %>%
    filter(!is.na(.data[[row_var]])) %>%
    group_by(
      panel = if_else(.data$fof_status == 1, "FOF", "Without FOF"),
      row = .data[[row_var]],
      case_status = .data$case_status
    ) %>%
    summarise(events = sum(.data$event_count, na.rm = TRUE), py = sum(.data$py, na.rm = TRUE), .groups = "drop") %>%
    mutate(
      rate = if_else(.data$py > 0, rate_per_1000(.data$events, .data$py), NA_real_),
      se = if_else(.data$py > 0, se_rate_per_1000_poisson(.data$events, .data$py), NA_real_)
    )
}

vis_agg <- agg_panel(visits, "bucket")

vis_total <- visits %>%
  group_by(panel = if_else(.data$fof_status == 1, "FOF", "Without FOF"), case_status = .data$case_status) %>%
  summarise(events = sum(.data$event_count, na.rm = TRUE), py = sum(.data$py, na.rm = TRUE), .groups = "drop") %>%
  mutate(
    row = "Total",
    rate = if_else(.data$py > 0, rate_per_1000(.data$events, .data$py), NA_real_),
    se = if_else(.data$py > 0, se_rate_per_1000_poisson(.data$events, .data$py), NA_real_)
  )

trt_agg <- treat %>%
  group_by(panel = if_else(.data$fof_status == 1, "FOF", "Without FOF"), case_status = .data$case_status) %>%
  summarise(events = sum(.data$event_count, na.rm = TRUE), py = sum(.data$py, na.rm = TRUE), .groups = "drop") %>%
  mutate(
    row = "Treatment periods",
    rate = if_else(.data$py > 0, rate_per_1000(.data$events, .data$py), NA_real_),
    se = if_else(.data$py > 0, se_rate_per_1000_poisson(.data$events, .data$py), NA_real_)
  )

table3_base <- bind_rows(vis_agg, vis_total, trt_agg) %>%
  mutate(row = factor(.data$row, levels = BUCKET_LEVELS, ordered = TRUE)) %>%
  arrange(.data$panel, .data$row)

compute_irr_by_row <- function(source_df, row_name, panel_name, engine, kind = "visits") {
  df_model <- if (kind == "treat") {
    source_df
  } else if (row_name == "Total") {
    source_df
  } else {
    source_df %>% filter(.data$bucket == as.character(row_name))
  }

  df_model <- df_model %>% filter(if_else(.data$fof_status == 1, "FOF", "Without FOF") == panel_name)
  if (nrow(df_model) == 0 || length(unique(df_model$case_status)) < 2) {
    return(tibble(irr = NA_real_, lcl = NA_real_, ucl = NA_real_, p = NA_real_))
  }

  res <- fit_irr_model(df_model, engine = engine)
  tibble(irr = res$irr, lcl = res$lcl, ucl = res$ucl, p = res$p)
}

irr_rows <- expand_grid(panel = c("Without FOF", "FOF"), row = factor(BUCKET_LEVELS, levels = BUCKET_LEVELS, ordered = TRUE)) %>%
  mutate(
    out = pmap(list(panel, row), function(panel_name, row_name) {
      if (as.character(row_name) == "Treatment periods") {
        compute_irr_by_row(treat, as.character(row_name), panel_name, opt$engine, kind = "treat")
      } else {
        compute_irr_by_row(visits, as.character(row_name), panel_name, opt$engine, kind = "visits")
      }
    })
  ) %>%
  unnest(.data$out) %>%
  mutate(irr_ci = if_else(!is.na(.data$irr), fmt_irr_ci(.data$irr, .data$lcl, .data$ucl, opt$round_irr), NA_character_))

table3_long <- table3_base %>%
  left_join(irr_rows, by = c("panel", "row")) %>%
  mutate(mean_se = if_else(!is.na(.data$rate), fmt_mean_se(.data$rate, .data$se, opt$round_rate), NA_character_))

wide_one_panel <- function(df_panel) {
  ctrl <- df_panel %>% filter(.data$case_status %in% c("control", 0, "0")) %>% dplyr::select(row, ctrl_mean_se = mean_se)
  cas <- df_panel %>% filter(.data$case_status %in% c("case", 1, "1")) %>% dplyr::select(row, case_mean_se = mean_se)
  irr <- df_panel %>% dplyr::select(row, irr_ci)
  full_join(full_join(ctrl, cas, by = "row"), irr, by = "row")
}

wo_w <- table3_long %>%
  filter(.data$panel == "Without FOF") %>%
  wide_one_panel() %>%
  rename(WO_ctrl_mean_se = ctrl_mean_se, WO_case_mean_se = case_mean_se, WO_irr_ci = irr_ci)

fo_w <- table3_long %>%
  filter(.data$panel == "FOF") %>%
  wide_one_panel() %>%
  rename(FO_ctrl_mean_se = ctrl_mean_se, FO_case_mean_se = case_mean_se, FO_irr_ci = irr_ci)

out_tbl <- full_join(wo_w, fo_w, by = "row") %>%
  mutate(Diagnosis = as.character(.data$row)) %>%
  dplyr::select(
    Diagnosis,
    WO_ctrl_mean_se, WO_case_mean_se, WO_irr_ci,
    FO_ctrl_mean_se, FO_case_mean_se, FO_irr_ci
  ) %>%
  mutate(across(everything(), ~ ifelse(is.na(.x), "", .x)))

out_csv <- file.path(opt$output_dir, "table3.csv")
write_csv(out_tbl, out_csv)

md_lines <- c(
  "Table 3. Injury-related Health Care Usage compared with the control group per 1000 patient years",
  "",
  "| Diagnosis | Without FOF: Control Mean(SE) | Without FOF: Case Mean(SE) | Without FOF: IRR (95% CI) | FOF: Control Mean(SE) | FOF: Case Mean(SE) | FOF: IRR (95% CI) |",
  "|---|---:|---:|---:|---:|---:|---:|"
)

md_rows <- out_tbl %>%
  transmute(
    Diagnosis,
    `Without FOF: Control Mean(SE)` = .data$WO_ctrl_mean_se,
    `Without FOF: Case Mean(SE)` = .data$WO_case_mean_se,
    `Without FOF: IRR (95% CI)` = .data$WO_irr_ci,
    `FOF: Control Mean(SE)` = .data$FO_ctrl_mean_se,
    `FOF: Case Mean(SE)` = .data$FO_case_mean_se,
    `FOF: IRR (95% CI)` = .data$FO_irr_ci
  ) %>%
  pmap_chr(~ paste0("| ", paste(c(...), collapse = " | "), " |"))

get_panel_total <- function(panel_name, df, row_name) {
  one <- df %>% filter(.data$panel == panel_name, .data$row == row_name) %>% slice(1)
  if (nrow(one) == 0) return(list(irr_ci = NA_character_, p = NA_real_))
  list(irr_ci = one$irr_ci, p = one$p)
}

min_p <- function(...) {
  vals <- c(...)
  vals <- vals[!is.na(vals)]
  if (length(vals) == 0) return(NA_real_)
  min(vals)
}

tot_vis_wo <- get_panel_total("Without FOF", table3_long, "Total")
tot_vis_fo <- get_panel_total("FOF", table3_long, "Total")
tp_wo <- get_panel_total("Without FOF", table3_long, "Treatment periods")
tp_fo <- get_panel_total("FOF", table3_long, "Treatment periods")

p_vis <- min_p(tot_vis_wo$p, tot_vis_fo$p)
p_tp <- min_p(tp_wo$p, tp_fo$p)

txt1 <- paste0("Total Clinical visits age-sex stand. IRR ", tot_vis_wo$irr_ci, " vrs ", tot_vis_fo$irr_ci, " ", ifelse(is.na(p_vis), "", fmt_p(p_vis)))
txt2 <- paste0("Total Treatment periods age sex adjusted. IRR ", tp_wo$irr_ci, " vrs ", tp_fo$irr_ci, " ", ifelse(is.na(p_tp), "", fmt_p(p_tp)))

out_md <- file.path(opt$output_dir, "table3.md")
writeLines(c(md_lines, md_rows, "", txt1, txt2, ""), out_md)

if (isTRUE(opt$make_docx)) {
  if (!requireNamespace("flextable", quietly = TRUE) || !requireNamespace("officer", quietly = TRUE)) {
    warning("make_docx requested but flextable/officer not installed. Skipping DOCX.")
  } else {
    library(flextable)
    library(officer)
    ft <- flextable::autofit(flextable::flextable(out_tbl))
    doc <- officer::read_docx()
    doc <- officer::body_add_par(doc, "Table 3. Injury-related Health Care Usage compared with the control group per 1000 patient years", style = "heading 2")
    doc <- officer::body_add_flextable(doc, ft)
    doc <- officer::body_add_par(doc, txt1, style = "Normal")
    doc <- officer::body_add_par(doc, txt2, style = "Normal")
    print(doc, target = file.path(opt$output_dir, "table3.docx"))
  }
}

message("Wrote: table3.csv")
message("Wrote: table3.md")
if (isTRUE(opt$make_docx)) message("DOCX (if available): table3.docx")
