#!/usr/bin/env Rscript

# Table 3 — Injury-related Health Care Usage vs control per 1000 PY
# Outputs:
#   (1) outputs/tables/table3.csv
#   (2) outputs/tables/table3.md
#   (3) optional outputs/tables/table3.docx
#
# IMPORTANT: Do not guess variable names. Uses data/VARIABLE_STANDARDIZATION.csv verified mappings.
# TODO/REPLACE: plug in Table 2's exact model + SE/CI logic once confirmed.

suppressPackageStartupMessages({
  library(optparse)
  library(readr)
  library(dplyr)
  library(stringr)
  library(tidyr)
  library(purrr)
  library(broom)
  library(readxl)
  library(MASS)     # glm.nb
})

# -----------------------------
# 1) CLI / Config
# -----------------------------
option_list <- list(
  make_option(c("--data_root"), type = "character", default = Sys.getenv("DATA_ROOT", ""),
              help = "Path to DATA_ROOT (required unless input files are absolute)."),
  make_option(c("--output_dir"), type = "character", default = Sys.getenv("OUTPUT_DIR", "outputs/tables"),
              help = "Output directory."),
  make_option(c("--visits_file"), type = "character", default = "",
              help = "Clinical visits input file (xlsx/csv)."),
  make_option(c("--treat_file"), type = "character", default = "",
              help = "Treatment periods input file (xlsx/csv)."),
  make_option(c("--varmap_file"), type = "character", default = "data/VARIABLE_STANDARDIZATION.csv",
              help = "Variable standardization mapping file."),
  make_option(c("--engine"), type = "character", default = "negbin",
              help = "Model engine: negbin or poisson (must match Table 2)."),
  make_option(c("--seed"), type = "integer", default = 12345,
              help = "Random seed (for deterministic behavior if resampling added later)."),
  make_option(c("--make_docx"), action = "store_true", default = FALSE,
              help = "Also write DOCX (requires flextable+officer)."),
  make_option(c("--round_rate"), type = "integer", default = 1,
              help = "Decimals for rate and SE in Mean(SE)."),
  make_option(c("--round_irr"), type = "integer", default = 2,
              help = "Decimals for IRR and CI.")
)
opt <- parse_args(OptionParser(option_list = option_list))
set.seed(opt$seed)

dir.create(opt$output_dir, recursive = TRUE, showWarnings = FALSE)

stopifnot(nzchar(opt$varmap_file), file.exists(opt$varmap_file))
stopifnot(opt$engine %in% c("negbin", "poisson"))

# helper: join DATA_ROOT + filename unless absolute
resolve_path <- function(path, data_root) {
  if (nzchar(path) && file.exists(path)) return(path)
  if (!nzchar(data_root)) return(path)
  p <- file.path(data_root, path)
  p
}

visits_path <- resolve_path(opt$visits_file, opt$data_root)
treat_path  <- resolve_path(opt$treat_file,  opt$data_root)

# -----------------------------
# 2) Variable mapping (verified-only)
# -----------------------------
# Expected columns (STANDARD NAMES) — DO NOT GUESS.
# TODO/REPLACE after checking VARIABLE_STANDARDIZATION.csv for exact names + verified status.
REQ_STD <- c(
  "person_id",     # unique id
  "fof_status",    # 0/1
  "case_status",   # control/case (0/1)
  "sex",           # 0/1 or F/M
  "age",           # baseline age
  "py",            # person-years
  "icd10_code",    # diagnosis code for clinical visits
  "event_count"    # count of visits (or 1 per row)
)

read_varmap_verified <- function(varmap_file) {
  vm <- suppressMessages(readr::read_csv(varmap_file, show_col_types = FALSE))
  # TODO/REPLACE: adjust column names to actual schema of VARIABLE_STANDARDIZATION.csv
  # expected: raw_name, std_name, verified (TRUE/FALSE)
  stopifnot(all(c("raw_name", "std_name", "verified") %in% names(vm)))
  vm %>% filter(.data$verified %in% TRUE)
}

apply_varmap <- function(df, varmap_verified) {
  # rename raw columns -> std columns where mapping exists
  rename_pairs <- varmap_verified %>% select(raw_name, std_name)
  rename_map <- setNames(rename_pairs$std_name, rename_pairs$raw_name)
  df %>% rename(any_of(rename_map))
}

assert_required_cols <- function(df, req) {
  missing <- setdiff(req, names(df))
  if (length(missing) > 0) {
    stop(
      "Missing required STANDARD columns: ",
      paste(missing, collapse = ", "),
      "\nKB missing → check data/VARIABLE_STANDARDIZATION.csv verified mappings."
    )
  }
}

# -----------------------------
# 3) Robust ICD-10 bucket
# -----------------------------
icd10_bucket <- function(x) {
  # normalize
  x2 <- x %>%
    str_to_upper() %>%
    str_trim() %>%
    str_replace_all("\\.", "") %>%
    str_replace_all("\\s+", "")

  # capture letter + 2 digits (e.g., S72, T14)
  core <- str_match(x2, "^([A-Z])(\\d{2})")[,2:3, drop = FALSE]
  letter <- core[,1]
  num2   <- suppressWarnings(as.integer(core[,2]))

  out <- rep(NA_character_, length(x2))

  # S00–S99 in 10-blocks
  isS <- !is.na(letter) & letter == "S" & !is.na(num2) & num2 >= 0 & num2 <= 99
  out[isS] <- sprintf("S%02d-%02d", floor(num2[isS]/10)*10, floor(num2[isS]/10)*10 + 9)

  # T00–T14 (inclusive)
  isT <- !is.na(letter) & letter == "T" & !is.na(num2) & num2 >= 0 & num2 <= 14
  out[isT] <- "T00-14"

  out
}

# quick self-test (does not fail run; prints warning if unexpected)
test_icd_bucket <- function() {
  ex <- c("S00.1", "s09", "S10", "S72.0", "S99", "T14", "T15", "X59")
  got <- icd10_bucket(ex)
  exp <- c("S00-09", "S00-09", "S10-19", "S70-79", "S90-99", "T00-14", NA, NA)
  if (!identical(got, exp)) {
    warning("ICD-10 bucket test mismatch.\nGot: ", paste(got, collapse=" | "),
            "\nExp: ", paste(exp, collapse=" | "))
  }
}
test_icd_bucket()

BUCKET_LEVELS <- c(
  "S00-09","S10-19","S20-29","S30-39","S40-49","S50-59","S60-69","S70-79","S80-89","S90-99","T00-14",
  "Total"
)

# -----------------------------
# 4) Readers (xlsx/csv)
# -----------------------------
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

# -----------------------------
# 5) Rate + SE (Poisson approx)
# -----------------------------
rate_per_1000 <- function(events, py) 1000 * events / py
se_rate_per_1000_poisson <- function(events, py) 1000 * sqrt(events) / py

fmt_mean_se <- function(rate, se, d = 1) {
  sprintf(paste0("%.", d, "f(%.", d, "f)"), rate, se)
}

fmt_irr_ci <- function(irr, lcl, ucl, d = 2) {
  sprintf(paste0("%.", d, "f(%.", d, "f to %.", d, "f)"), irr, lcl, ucl)
}

fmt_p <- function(p) {
  if (is.na(p)) return(NA_character_)
  if (p < 0.001) return("p<0.001")
  sprintf("p=%.3f", p)
}

# -----------------------------
# 6) Modeling (placeholder to be replaced by Table 2 logic)
# -----------------------------
fit_irr_model <- function(df, engine = "negbin") {
  # df must contain: event_count, case_status, age, sex, py
  # case_status: 0=control, 1=case (or factor with control reference)
  # TODO/REPLACE: exactly mirror Table 2 model, SE/CI type, clustering, etc.

  df <- df %>%
    mutate(
      case_status = as.factor(case_status),
      # enforce reference level = control if present
      case_status = forcats::fct_relevel(case_status, "0", "control", "Control")
    )

  fml <- as.formula("event_count ~ case_status + age + sex + offset(log(py))")

  fit <- if (engine == "negbin") {
    MASS::glm.nb(fml, data = df, link = log)
  } else {
    glm(fml, data = df, family = poisson(link = "log"))
  }

  co <- broom::tidy(fit)
  # find case coefficient (non-reference)
  case_row <- co %>% filter(str_detect(term, "^case_status")) %>% slice(1)

  beta <- case_row$estimate
  se   <- case_row$std.error
  z    <- beta / se
  p    <- 2 * pnorm(abs(z), lower.tail = FALSE)

  irr <- exp(beta)
  lcl <- exp(beta - 1.96 * se)
  ucl <- exp(beta + 1.96 * se)

  list(irr = irr, lcl = lcl, ucl = ucl, p = p, fit = fit)
}

# -----------------------------
# 7) Build Table 3 blocks
# -----------------------------
# Expected strata labels:
#   Without FOF: fof_status==0
#   FOF:         fof_status==1
FOF_LABEL <- function(x) ifelse(as.integer(x) == 1, "FOF", "Without FOF")

summarise_rate_block <- function(df, bucket_value) {
  # df already filtered to one FOF stratum, one case_status group
  # bucket_value: one of BUCKET_LEVELS (including Total)
  if (bucket_value != "Total") {
    df2 <- df %>% filter(bucket == bucket_value)
  } else {
    df2 <- df
  }

  events <- sum(df2$event_count, na.rm = TRUE)
  py     <- sum(df2$py, na.rm = TRUE)

  rate <- rate_per_1000(events, py)
  se   <- se_rate_per_1000_poisson(events, py)

  tibble(
    events = events,
    py = py,
    rate_1000 = rate,
    se_1000 = se
  )
}

build_block_for_bucket <- function(df_stratum, bucket_value, engine) {
  # df_stratum contains both control+case within one FOF stratum and one outcome family (visits OR treatment)
  # returns one row with formatted columns + irr
  # rate columns are crude per group; IRR is age+sex adjusted (per manuscript text).
  # TODO/REPLACE: if Table 2 standardizes differently, swap here.

  # rates
  ctrl <- df_stratum %>% filter(case_status == 0)
  case <- df_stratum %>% filter(case_status == 1)

  r_ctrl <- summarise_rate_block(ctrl, bucket_value)
  r_case <- summarise_rate_block(case, bucket_value)

  # model for IRR
  df_model <- if (bucket_value == "Total") {
    df_stratum
  } else {
    df_stratum %>% filter(bucket == bucket_value)
  }

  mod <- fit_irr_model(df_model, engine = engine)

  tibble(
    row = bucket_value,
    ctrl_mean_se = fmt_mean_se(r_ctrl$rate_1000, r_ctrl$se_1000, d = opt$round_rate),
    case_mean_se = fmt_mean_se(r_case$rate_1000, r_case$se_1000, d = opt$round_rate),
    irr_ci = fmt_irr_ci(mod$irr, mod$lcl, mod$ucl, d = opt$round_irr),
    p = mod$p
  )
}

# -----------------------------
# 8) MAIN — Load, map, validate, compute
# -----------------------------
varmap_verified <- read_varmap_verified(opt$varmap_file)

# --- Clinical visits (ICD-bucketed)
stopifnot(nzchar(visits_path), file.exists(visits_path))
visits_raw <- read_any(visits_path)
visits <- visits_raw %>%
  apply_varmap(varmap_verified)

# NOTE: REQ_STD includes columns not relevant to treatment periods; validate minimally here
REQ_VISITS <- c("fof_status","case_status","sex","age","py","icd10_code","event_count")
assert_required_cols(visits, REQ_VISITS)

visits <- visits %>%
  mutate(
    bucket = icd10_bucket(icd10_code),
    # keep only buckets of interest
    bucket = ifelse(bucket %in% BUCKET_LEVELS, bucket, NA_character_),
    fof_status = as.integer(fof_status),
    case_status = as.integer(case_status)
  ) %>%
  filter(!is.na(bucket)) %>%
  mutate(bucket = factor(bucket, levels = BUCKET_LEVELS))

# --- Treatment periods (no ICD buckets)
stopifnot(nzchar(treat_path), file.exists(treat_path))
treat_raw <- read_any(treat_path)
treat <- treat_raw %>%
  apply_varmap(varmap_verified)

# TODO/REPLACE: standard names for treatment outcome count (e.g., treatment_periods_count)
REQ_TREAT <- c("fof_status","case_status","sex","age","py","event_count")
assert_required_cols(treat, REQ_TREAT)

treat <- treat %>%
  mutate(
    bucket = "Treatment periods",
    fof_status = as.integer(fof_status),
    case_status = as.integer(case_status)
  )

# -----------------------------
# 9) Build the final Table 3
# -----------------------------
build_table3_panel <- function(df, fof_value, engine) {
  df_stratum <- df %>% filter(fof_status == fof_value)

  map_dfr(BUCKET_LEVELS, ~ build_block_for_bucket(df_stratum, .x, engine = engine)) %>%
    mutate(panel = FOF_LABEL(fof_value))
}

# visits panel (ICD rows + Total)
tab_visits_0 <- build_table3_panel(visits, fof_value = 0, engine = opt$engine)
tab_visits_1 <- build_table3_panel(visits, fof_value = 1, engine = opt$engine)

# treatment periods panel (single row)
tab_treat_0 <- build_block_for_bucket(treat %>% filter(fof_status == 0), "Treatment periods", engine = opt$engine) %>%
  mutate(panel = "Without FOF")
tab_treat_1 <- build_block_for_bucket(treat %>% filter(fof_status == 1), "Treatment periods", engine = opt$engine) %>%
  mutate(panel = "FOF")

# combine into a spec-ordered table
table3_long <- bind_rows(tab_visits_0, tab_visits_1, tab_treat_0, tab_treat_1) %>%
  mutate(
    row = factor(row, levels = c(BUCKET_LEVELS, "Treatment periods"))
  ) %>%
  arrange(panel, row)

# pivot to manuscript columns:
# Without FOF: Control/Case/IRR; FOF: Control/Case/IRR
table3_wide <- table3_long %>%
  select(panel, row, ctrl_mean_se, case_mean_se, irr_ci) %>%
  pivot_wider(
    names_from = panel,
    values_from = c(ctrl_mean_se, case_mean_se, irr_ci),
    names_glue = "{panel}__{.value}"
  ) %>%
  arrange(row)

# write machine-readable CSV
out_csv <- file.path(opt$output_dir, "table3.csv")
readr::write_csv(table3_wide, out_csv)

# -----------------------------
# 10) Write markdown (manuscript-ready)
# -----------------------------
# Header N's (preferably computed from data; QC against manuscript)
# Manuscript example N's: Without FOF Control 441, Case 147; FOF Control 990, Case 330
# TODO/REPLACE: compute unique persons by case_status within fof strata, and assert equals if desired.

md_lines <- c(
  "### Table 3. Injury-related Health Care Usage compared with the control group per 1000 patient years",
  "",
  "| Diagnosis (ICD-10) | Without FOF: Control Mean(SE) | Without FOF: Case Mean(SE) | Without FOF: IRR (95% CI) | FOF: Control Mean(SE) | FOF: Case Mean(SE) | FOF: IRR (95% CI) |",
  "|---|---:|---:|---:|---:|---:|---:|"
)

md_body <- table3_wide %>%
  mutate(
    Diagnosis = as.character(row),
    `Without FOF: Control Mean(SE)` = `Without FOF__ctrl_mean_se`,
    `Without FOF: Case Mean(SE)`    = `Without FOF__case_mean_se`,
    `Without FOF: IRR (95% CI)`     = `Without FOF__irr_ci`,
    `FOF: Control Mean(SE)`         = `FOF__ctrl_mean_se`,
    `FOF: Case Mean(SE)`            = `FOF__case_mean_se`,
    `FOF: IRR (95% CI)`             = `FOF__irr_ci`
  ) %>%
  select(
    Diagnosis,
    `Without FOF: Control Mean(SE)`,
    `Without FOF: Case Mean(SE)`,
    `Without FOF: IRR (95% CI)`,
    `FOF: Control Mean(SE)`,
    `FOF: Case Mean(SE)`,
    `FOF: IRR (95% CI)`
  )

md_rows <- md_body %>%
  mutate(across(everything(), ~ ifelse(is.na(.x), "", .x))) %>%
  pmap_chr(~ paste0("| ", paste(c(...), collapse = " | "), " |"))

# text lines (Total rows)
get_panel_total <- function(panel_name, outcome_df, row_name = "Total") {
  one <- outcome_df %>% filter(panel == panel_name, row == row_name) %>% slice(1)
  if (nrow(one) == 0) return(list(irr_ci = NA_character_, p = NA_real_))
  list(irr_ci = one$irr_ci, p = one$p)
}
tot_wo <- table3_long %>% filter(panel == "Without FOF")
tot_fo <- table3_long %>% filter(panel == "FOF")

tot_vis_wo <- get_panel_total("Without FOF", table3_long %>% filter(row == "Total"), "Total")
tot_vis_fo <- get_panel_total("FOF",         table3_long %>% filter(row == "Total"), "Total")

tp_wo <- table3_long %>% filter(panel == "Without FOF", row == "Treatment periods") %>% slice(1)
tp_fo <- table3_long %>% filter(panel == "FOF", row == "Treatment periods") %>% slice(1)

txt1 <- paste0(
  "Total Clinical visits age-sex stand. IRR ",
  tot_vis_wo$irr_ci, " vrs ", tot_vis_fo$irr_ci, " ", fmt_p(min(tot_wo$p, tot_fo$p, na.rm = TRUE))
)
txt2 <- paste0(
  "Total Treatment periods age sex adjusted. IRR ",
  tp_wo$irr_ci, " vrs ", tp_fo$irr_ci, " ", fmt_p(min(tp_wo$p, tp_fo$p, na.rm = TRUE))
)

md_out <- c(md_lines, md_rows, "", txt1, txt2, "")
out_md <- file.path(opt$output_dir, "table3.md")
writeLines(md_out, out_md)

# -----------------------------
# 11) Optional DOCX
# -----------------------------
if (isTRUE(opt$make_docx)) {
  if (!requireNamespace("flextable", quietly = TRUE) || !requireNamespace("officer", quietly = TRUE)) {
    warning("make_docx requested but flextable/officer not installed. Skipping DOCX.")
  } else {
    library(flextable)
    library(officer)

    ft <- flextable::flextable(md_body)
    ft <- flextable::autofit(ft)

    doc <- officer::read_docx()
    doc <- officer::body_add_par(doc, "Table 3. Injury-related Health Care Usage compared with the control group per 1000 patient years", style = "heading 2")
    doc <- officer::body_add_flextable(doc, ft)
    doc <- officer::body_add_par(doc, txt1, style = "Normal")
    doc <- officer::body_add_par(doc, txt2, style = "Normal")

    out_docx <- file.path(opt$output_dir, "table3.docx")
    print(doc, target = out_docx)
  }
}

message("Wrote: ", out_csv)
message("Wrote: ", out_md)
if (isTRUE(opt$make_docx)) message("DOCX (if available): ", file.path(opt$output_dir, "table3.docx"))
