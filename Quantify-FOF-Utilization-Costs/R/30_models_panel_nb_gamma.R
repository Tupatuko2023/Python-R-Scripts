#!/usr/bin/env Rscript

# scripts/30_models_panel_nb_gamma.R
# Template-runner (Option B safe-by-default): packages -> prep -> NB + Gamma
# -> cluster-robust SE -> recycled predictions -> cluster bootstrap -> tables

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
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
PANEL_PATH <- file.path(DATA_ROOT, "derived", "aim2_panel.csv")

if (DATA_ROOT == "" || !file.exists(PANEL_PATH)) {
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
vcov_cluster <- function(model, cluster_vec) {
  sandwich::vcovCL(model, cluster = cluster_vec, type = "HC0")
}

fit_nb <- function(df, y) {
  # Formula: y ~ FOF * frailty + period + age + sex + offset
  # Filter out unknown frailty for this analysis
  df_sub <- df %>% filter(.data[[v_frailty]] != "unknown")
  if(nrow(df_sub) == 0) return(NULL)

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
  
  f_str <- paste0(
    y, " ~ ", v_fof, " * factor(", v_frailty, ") + factor(", v_period, ") + ", v_age, " + factor(", v_sex, ") + offset(log(", v_pt, "))"
  )
  glm(as.formula(f_str), data = df_pos, family = Gamma(link = "log"))
}

# Recycled prediction: set FOF=0/1 for all rows; return rate/PY
recycled_rate <- function(model, df) {
  if(is.null(model)) return(tibble(val_fof0=NA, val_fof1=NA, ratio=NA, diff=NA))
  
  pred_for_fof <- function(val) {
    d2 <- df
    d2[[v_fof]] <- val
    # Predict expected count/cost per period
    # type='response' gives mu (counts) or cost (euros) per period
    mu <- as.numeric(predict(model, newdata = d2, type = "response")) 
    # Convert to per PY (aggregated)
    sum(mu, na.rm = TRUE) / sum(d2[[v_pt]], na.rm = TRUE)
  }
  r0 <- pred_for_fof(0)
  r1 <- pred_for_fof(1)
  tibble(val_fof0 = r0, val_fof1 = r1, ratio = r1 / r0, diff = r1 - r0)
}

#-----------------------------
# 3) Cluster Bootstrap
#-----------------------------
boot_cluster <- function(df, ids, B, fit_fun, pred_fun) {
  # Simplified for template; increase B in production
  out <- vector("list", B)
  for (b in seq_len(B)) {
    tryCatch({
      samp_ids <- sample(ids, size = length(ids), replace = TRUE)
      # Efficient join to replicate rows
      # Note: 'relationship' arg requires newer dplyr, using standard join logic for safety
      # Create mapping table
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
B <- 50 # Debug level
results <- list()

# Filter to those with known frailty for interaction analysis
panel_filtered <- panel %>% filter(.data[[v_frailty]] != "unknown")
ids <- unique(panel_filtered[[v_id]])

message("Persons with frailty data: ", length(ids))

# --- Counts ---
for (y in count_outcomes) {
  if (!y %in% names(panel_filtered)) next
  message("Modeling Count: ", y)
  
  m <- fit_nb(panel_filtered, y)
  if(is.null(m)) next
  est <- recycled_rate(m, panel_filtered)
  
  boot <- boot_cluster(panel_filtered, ids, B, function(d) fit_nb(d, y), function(m, d) recycled_rate(m, d))
  
  # Summarize
  res <- est %>% mutate(
    outcome = y,
    type = "count_nb_interaction",
    val_fof0_l = ci_percentile(boot$val_fof0)[1], val_fof0_u = ci_percentile(boot$val_fof0)[2],
    ratio_l = ci_percentile(boot$ratio)[1], ratio_u = ci_percentile(boot$ratio)[2]
  )
  results[[y]] <- res
}

# --- Costs ---
for (y in cost_outcomes) {
  if (!y %in% names(panel_filtered)) next
  message("Modeling Cost: ", y)
  
  # Gamma on positives
  m <- fit_gamma_pos(panel_filtered, y)
  if(is.null(m)) next
  
  # Recycled on positives only for conditional mean
  panel_pos <- panel_filtered %>% filter(.data[[y]] > 0)
  est <- recycled_rate(m, panel_pos)
  
  boot <- boot_cluster(panel_filtered, ids, B, 
                       function(d) fit_gamma_pos(d, y), 
                       function(m, d) recycled_rate(m, d %>% filter(.data[[y]] > 0)))
  
  res <- est %>% mutate(
    outcome = y,
    type = "cost_gamma_pos_interaction",
    val_fof0_l = ci_percentile(boot$val_fof0)[1], val_fof0_u = ci_percentile(boot$val_fof0)[2],
    ratio_l = ci_percentile(boot$ratio)[1], ratio_u = ci_percentile(boot$ratio)[2]
  )
  results[[y]] <- res
}

#-----------------------------
# 5) Save Outputs
#-----------------------------
final_tbl <- bind_rows(results)
dir.create("outputs", showWarnings = FALSE)
write.csv(final_tbl, "outputs/panel_models_summary.csv", row.names = FALSE)
message("Done. Results saved to outputs/panel_models_summary.csv")
