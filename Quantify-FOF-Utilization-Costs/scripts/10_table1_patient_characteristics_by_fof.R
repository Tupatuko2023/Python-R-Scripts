suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
})

DATA_ROOT <- Sys.getenv("DATA_ROOT", unset = "")
if (DATA_ROOT == "") stop("DATA_ROOT puuttuu.")

ALLOW_AGGREGATES <- Sys.getenv("ALLOW_AGGREGATES", unset = "") == "1"
outputs_dir <- file.path("outputs")
if (!dir.exists(outputs_dir)) dir.create(outputs_dir, recursive = TRUE)
logs_dir <- file.path("logs")
if (!dir.exists(logs_dir)) dir.create(logs_dir, recursive = TRUE)

# Redaction helper
redact_paths <- function(x) {
  if (length(x) == 0) return(x)
  x <- gsub(DATA_ROOT, "<DATA_ROOT>", x, fixed = TRUE)
  x
}

log_msg <- function(...) {
  msg <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " | ", paste0(..., collapse = ""))
  message(redact_paths(msg))
}

# Metadata log
writeLines(c(
  paste0("timestamp: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  paste0("allow_aggregates: ", ALLOW_AGGREGATES)
), file.path(logs_dir, "table1_run_metadata.txt"))

log_msg("Table 1 run started.")

# Locate Input
input_path <- file.path(DATA_ROOT, "derived", "aim2_panel.csv")
if (!file.exists(input_path)) input_path <- file.path(DATA_ROOT, "derived", "kaatumisenpelko.csv")
if (!file.exists(input_path)) stop("Input not found.")

log_msg("Reading input...")
df_raw <- read_csv(input_path, show_col_types = FALSE)

# Recoding Helpers
pick_col <- function(df_names, target, candidates) {
  hits <- intersect(df_names, candidates)
  if (length(hits) >= 1) return(hits[1])
  stop(paste("Column not found:", target))
}

nm <- names(df_raw)
col_fof <- pick_col(nm, "FOF", c("FOF_status","fof_fear_binary","kaatumisenpelkoOn","FOF"))
col_sex <- pick_col(nm, "sex", c("sex","Sukupuoli","gender"))
col_age <- pick_col(nm, "age", c("age","Ik?","Age"))
col_bmi <- pick_col(nm, "BMI", c("BMI","bmi","Painoindeksi (BMI)"))

normalize_fof <- function(x) {
  x_chr <- tolower(as.character(x))
  ifelse(x_chr %in% c("1","yes","kylla"), "Yes",
  ifelse(x_chr %in% c("0","no","ei"), "No", NA_character_))
}

df <- df_raw %>%
  transmute(
    FOF = factor(normalize_fof(.data[[col_fof]]), levels=c("No","Yes")),
    age = as.numeric(.data[[col_age]]),
    bmi = as.numeric(.data[[col_bmi]]),
    women = if_else(as.character(.data[[col_sex]]) %in% c("2","F","Female","Nainen"), 1L, 0L)
  ) %>%
  filter(!is.na(FOF))

N_no <- sum(df$FOF == "No")
N_yes <- sum(df$FOF == "Yes")
if (N_no == 0 || N_yes == 0) stop("Group empty.")

# Formatting
fmt_cont <- function(m, s, n) {
  if (n < 5) return("Suppressed")
  sprintf("%.1f (%.1f)", m, s)
}
fmt_bin <- function(n_cases, n_total) {
  if (n_cases < 5 || (n_total-n_cases) < 5) return("Suppressed")
  pct <- round(100*n_cases/n_total, 0)
  sprintf("%d (%d%%)", n_cases, pct)
}

calc_row_cont <- function(var_name, vals, grp) {
  m <- tapply(vals, grp, mean, na.rm=TRUE)
  s <- tapply(vals, grp, sd, na.rm=TRUE)
  n <- tapply(vals, grp, function(x) sum(!is.na(x)))
  p_val <- tryCatch(t.test(vals ~ grp)$p.value, error=function(e) NA)
  p_str <- if(is.na(p_val)) "NA" else sprintf("%.3f", p_val)
  if (any(n < 5)) p_str <- "Suppressed"
  tibble(Variable = var_name, No = fmt_cont(m["No"], s["No"], n["No"]), Yes = fmt_cont(m["Yes"], s["Yes"], n["Yes"]), P = p_str)
}

calc_row_bin <- function(var_name, vals, grp) {
  n_tot <- tapply(!is.na(vals), grp, sum)
  n_yes <- tapply(vals==1, grp, sum, na.rm=TRUE)
  p_val <- tryCatch(chisq.test(table(vals, grp))$p.value, error=function(e) NA)
  p_str <- if(is.na(p_val)) "NA" else sprintf("%.3f", p_val)
  if (any(n_tot < 5) || any(n_yes < 5)) p_str <- "Suppressed"
  tibble(Variable = var_name, No = fmt_bin(n_yes["No"], n_tot["No"]), Yes = fmt_bin(n_yes["Yes"], n_tot["Yes"]), P = p_str)
}

tab1 <- bind_rows(
  calc_row_cont("Age, mean (SD)", df$age, df$FOF),
  calc_row_cont("BMI, mean (SD)", df$bmi, df$FOF),
  calc_row_bin("Women, n (%)", df$women, df$FOF)
)

colnames(tab1) <- c("Variable", paste0("No (N=",N_no,")"), paste0("Yes (N=",N_yes,")"), "P-value")

out_csv <- file.path(outputs_dir, "table1_patient_characteristics_by_fof.csv")
if (ALLOW_AGGREGATES) {
  write_csv(tab1, out_csv)
  log_msg("SUCCESS: Wrote ", out_csv)
} else {
  log_msg("BLOCKED")
}
