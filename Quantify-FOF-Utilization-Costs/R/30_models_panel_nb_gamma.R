#!/usr/bin/env Rscript

# scripts/30_models_panel_nb_gamma.R
# Template-runner (Option B safe-by-default): packages -> prep -> NB + Gamma
# -> cluster-robust SE -> recycled predictions -> cluster bootstrap -> tables

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

# Robust project root discovery & security bootstrap
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)
script_path <- if (length(file_arg) > 0) sub("^--file=", "", file_arg[1]) else NA_character_
script_dir  <- if (!is.na(script_path)) dirname(normalizePath(script_path, mustWork = FALSE)) else getwd()
project_dir <- script_dir
while (basename(project_dir) %in% c("R", "scripts", "10_table1", "security", "outputs", "logs")) {
  project_dir <- dirname(project_dir)
}
source(file.path(project_dir, "R", "bootstrap.R"))

suppressPackageStartupMessages({
  library(stringr)
  library(MASS)       # glm.nb
  library(sandwich)   # vcovCL
  library(lmtest)     # coeftest
  library(broom)      # tidy
})

#-----------------------------
# 0) Inputs (Option B)
#-----------------------------
DATA_ROOT <- Sys.getenv("DATA_ROOT")  # secure location, not in repo

if (DATA_ROOT == "") {
  if (Sys.getenv("CI") == "true") {
    message("CI mode: DATA_ROOT missing, exiting gracefully.")
    quit(save="no", status=0)
  }
  stop("Set DATA_ROOT environment variable.")
}

PANEL_PATH <- safe_join_path(DATA_ROOT, "derived", "aim2_panel.csv")

if (!file.exists(PANEL_PATH)) {
  # Fallback for CI/Syntax check without data
  if (Sys.getenv("CI") == "true") {
    message("CI mode: DATA_ROOT missing, exiting gracefully.")
    quit(save="no", status=0)
  }
  stop("Set DATA_ROOT env var and ensure derived/aim2_panel.csv exists (run script 10).")
}

# Variable standardization (repo metadata)
std_path <- "data/VARIABLE_STANDARDIZATION.csv"
if (!file.exists(std_path)) stop("Missing data/VARIABLE_STANDARDIZATION.csv in repo.")
std_map <- read.csv(std_path, stringsAsFactors = FALSE)

# Load panel (must be person-period; no PII in outputs)
panel <- read.csv(PANEL_PATH, stringsAsFactors = FALSE)

#-----------------------------
# 1) Variable Config
#-----------------------------
# These must match VARIABLE_STANDARDIZATION.csv and Script 10 output
v_id      <- "id"
v_fof     <- "FOF_status"
v_age     <- "age"
v_sex     <- "sex"
v_period  <- "period"
v_pt      <- "person_time"
v_frailty <- "frailty_fried"

# Outcomes to model (adjust based on actual data presence)
count_outcomes <- c("util_visits_total", "util_visits_outpatient", "util_visits_inpatient")
cost_outcomes  <- c("cost_total_eur", "cost_outpatient_eur", "cost_inpatient_eur")

#-----------------------------
# 2) Model Helpers
#-----------------------------
# Ensure Robust is the reference level for frailty
prep_frailty_factor <- function(df) {
  if (v_frailty %in% names(df)) {
    df[[v_frailty]] <- factor(df[[v_frailty]], levels = c("robust", "pre-frail", "frail"))
  }
  df
}

vcov_cluster <- function(model, cluster_vec) {
  sandwich::vcovCL(model, cluster = cluster_vec, type = "HC0")
}

fit_nb <- function(df, y) {
  # Formula: y ~ FOF * frailty + period + age + sex + offset
  # Filter out unknown frailty for this analysis
  df_sub <- df %>% filter(.data[[v_frailty]] != "unknown")
  if(nrow(df_sub) == 0) return(NULL)
  df_sub <- prep_frailty_factor(df_sub)

  f_str <- paste0(
    y, " ~ ", v_fof, " * factor(", v_frailty, ") + factor(", v_period, ") + ", v_age, " + factor(", v_sex, ") + offset(log(", v_pt, "))"
  )
  MASS::glm.nb(as.formula(f_str), data = df_sub)
}

fit_gamma_pos <- function(df, y) {
  # Filter out unknown frailty
  df_sub <- df %>% filter(.data[[v_frailty]] != "unknown")
  df_pos <- df_sub %>% filter(.data[[y]] > 0)
  if(nrow(df_pos) < 10) return(NULL) # Too few positives
  df_pos <- prep_frailty_factor(df_pos)
  
  f_str <- paste0(
    y, " ~ ", v_fof, " * factor(", v_frailty, ") + factor(", v_period, ") + ", v_age, " + factor(", v_sex, ") + offset(log(", v_pt, "))"
  )
  glm(as.formula(f_str), data = df_pos, family = Gamma(link = "log"))
}

# Recycled prediction: set FOF=0/1 for all rows; return rate/PY
recycled_rate <- function(model, df) {
  if(is.null(model)) return(NULL)
  
  calc_for_subset <- function(sub_df, label) {
    if(nrow(sub_df) == 0) return(NULL)
    pred_for_fof <- function(val) {
      d2 <- sub_df
      d2[[v_fof]] <- val
      mu <- as.numeric(predict(model, newdata = d2, type = "response")) 
      sum(mu, na.rm = TRUE) / sum(d2[[v_pt]], na.rm = TRUE)
    }
    r0 <- pred_for_fof(0)
    r1 <- pred_for_fof(1)
    tibble(stratum = label, val_fof0 = r0, val_fof1 = r1, ratio = r1 / r0, diff = r1 - r0)
  }
  
  # Overall
  res_list <- list(calc_for_subset(df, "Overall"))
  
  # Stratified by frailty
  levels_f <- levels(df[[v_frailty]])
  for (lev in levels_f) {
    df_lev <- df %>% filter(.data[[v_frailty]] == lev)
    res_list[[lev]] <- calc_for_subset(df_lev, lev)
  }
  
  bind_rows(res_list)
}

#-----------------------------
# 3) Cluster Bootstrap
#-----------------------------
boot_cluster <- function(df, ids, B, fit_fun, pred_fun) {
  out <- vector("list", B)
  for (b in seq_len(B)) {
    tryCatch({
      samp_ids <- sample(ids, size = length(ids), replace = TRUE)
      map_df <- tibble(!!v_id := samp_ids, .boot_id = seq_along(samp_ids))
      df_b <- inner_join(df, map_df, by = v_id)
      
      m_b <- fit_fun(df_b)
      out[[b]] <- pred_fun(m_b, df_b)
    }, error = function(e) return(NULL))
  }
  bind_rows(out, .id = "b")
}

ci_percentile <- function(x, alpha = 0.05) {
  if(all(is.na(x))) return(c(NA, NA))
  quantile(x, probs = c(alpha/2, 1 - alpha/2), na.rm = TRUE, names = FALSE)
}

#-----------------------------
# 4) Main Execution Loop
#-----------------------------
B <- 500 # Production rigor
results <- list()

# Filter to those with known frailty for interaction analysis
panel_filtered <- panel %>% filter(.data[[v_frailty]] != "unknown")
panel_filtered <- prep_frailty_factor(panel_filtered)
ids <- unique(panel_filtered[[v_id]])

message("Persons with frailty data: ", length(ids))

summarize_boot <- function(est, boot, outcome_name, model_type) {
  boot_sum <- boot %>%
    group_by(stratum) %>%
    summarise(
      val_fof0_l = ci_percentile(val_fof0)[1],
      val_fof0_u = ci_percentile(val_fof0)[2],
      ratio_l = ci_percentile(ratio)[1],
      ratio_u = ci_percentile(ratio)[2],
      .groups = "drop"
    )
  
  est %>% 
    inner_join(boot_sum, by = "stratum") %>%
    mutate(outcome = outcome_name, type = model_type)
}

# --- Counts ---
for (y in count_outcomes) {
  if (!y %in% names(panel_filtered)) next
  message("Modeling Count: ", y)
  
  m <- fit_nb(panel_filtered, y)
  if(is.null(m)) next
  est <- recycled_rate(m, panel_filtered)
  
  boot <- boot_cluster(panel_filtered, ids, B, function(d) fit_nb(d, y), function(m, d) recycled_rate(m, d))
  
  results[[y]] <- summarize_boot(est, boot, y, "count_nb_interaction")
}

# --- Costs ---
for (y in cost_outcomes) {
  if (!y %in% names(panel_filtered)) next
  message("Modeling Cost: ", y)
  
  m <- fit_gamma_pos(panel_filtered, y)
  if(is.null(m)) next
  
  panel_pos <- panel_filtered %>% filter(.data[[y]] > 0)
  est <- recycled_rate(m, panel_pos)
  
  boot <- boot_cluster(panel_filtered, ids, B, 
                       function(d) fit_gamma_pos(d, y), 
                       function(m, d) recycled_rate(m, d %>% filter(.data[[y]] > 0)))
  
  results[[y]] <- summarize_boot(est, boot, y, "cost_gamma_pos_interaction")
}

#-----------------------------
# 5) Save Outputs
#-----------------------------
final_tbl <- bind_rows(results)
dir.create("outputs", showWarnings = FALSE)
write.csv(final_tbl, "outputs/panel_models_summary.csv", row.names = FALSE)
message("Done. Results saved to outputs/panel_models_summary.csv")
