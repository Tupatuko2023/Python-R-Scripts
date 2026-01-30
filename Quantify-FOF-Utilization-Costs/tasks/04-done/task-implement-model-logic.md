# Task: Implement Full Model Logic (Script 30)

## Status

* **Source:** docs/analysis_plan.md (Section 6/Runbook code block)
* **Target:** scripts/30_models_panel_nb_gamma.R

## Instructions

Replace the current "skeleton" content of `scripts/30_models_panel_nb_gamma.R` with the functional code below. This code implements the Negative Binomial and Gamma models, recycled predictions, and cluster bootstrapping as specified in the Analysis Plan.

### Code to Write

```r
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
  stop("Set DATA_ROOT env var and ensure derived/aim2_panel.csv exists (run script 10).")
}

# Variable standardization (repo metadata)
std_path <- file.path("data", "VARIABLE_STANDARDIZATION.csv")
if (!file.exists(std_path)) stop("Missing data/VARIABLE_STANDARDIZATION.csv in repo.")
std_map <- read_csv(std_path, show_col_types = FALSE)

# Load panel (must be person-period; no PII in outputs)
panel <- read_csv(PANEL_PATH, show_col_types = FALSE)

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

# Outcomes to model
count_outcomes <- c("util_visits_total", "util_visits_outpatient", "util_visits_inpatient") # Adjust based on actual data
cost_outcomes  <- c("cost_total_eur", "cost_outpatient_eur", "cost_inpatient_eur") # Adjust based on actual data

#-----------------------------
# 2) Model Helpers
#-----------------------------
vcov_cluster <- function(model, cluster_vec) {
  sandwich::vcovCL(model, cluster = cluster_vec, type = "HC0")
}

fit_nb <- function(df, y) {
  # Formula: y ~ FOF + period + age + sex + frailty + offset
  f <- as.formula(paste0(
    y, " ~ ", v_fof, " + factor(", v_period, ") + ", v_age, " + factor(", v_sex, ") + ",
    v_frailty, " + offset(log(", v_pt, "))"
  ))
  MASS::glm.nb(f, data = df)
}

fit_gamma_pos <- function(df, y) {
  df_pos <- df %>% filter(.data[[y]] > 0)
  f <- as.formula(paste0(
    y, " ~ ", v_fof, " + factor(", v_period, ") + ", v_age, " + factor(", v_sex, ") + ",
    v_frailty, " + offset(log(", v_pt, "))"
  ))
  glm(f, data = df_pos, family = Gamma(link = "log"))
}

# Recycled prediction: set FOF=0/1 for all rows; return rate/PY
recycled_rate <- function(model, df) {
  pred_for_fof <- function(val) {
    d2 <- df
    d2[[v_fof]] <- val
    # Predict expected count/cost per period
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
      df_b <- inner_join(df, tibble(!!v_id := samp_ids), by = v_id, relationship = "many-to-many")
      
      m_b <- fit_fun(df_b)
      out[[b]] <- pred_fun(m_b, df_b)
    }, error = function(e) return(NULL))
  }
  bind_rows(out, .id = "b")
}

ci_percentile <- function(x, alpha = 0.05) {
  quantile(x, probs = c(alpha/2, 1 - alpha/2), na.rm = TRUE, names = FALSE)
}

#-----------------------------
# 4) Main Execution Loop
#-----------------------------
B <- 50 # Debug level; use 500+ for final
results <- list()
ids <- unique(panel[[v_id]])

# --- Counts ---
for (y in count_outcomes) {
  if (!y %in% names(panel)) next
  message("Modeling Count: ", y)
  
  m <- fit_nb(panel, y)
  est <- recycled_rate(m, panel)
  
  boot <- boot_cluster(panel, ids, B, function(d) fit_nb(d, y), function(m, d) recycled_rate(m, d))
  
  # Summarize
  res <- est %>% mutate(
    outcome = y,
    type = "count_nb",
    val_fof0_l = ci_percentile(boot$val_fof0)[1], val_fof0_u = ci_percentile(boot$val_fof0)[2],
    ratio_l = ci_percentile(boot$ratio)[1], ratio_u = ci_percentile(boot$ratio)[2]
  )
  results[[y]] <- res
}

# --- Costs ---
for (y in cost_outcomes) {
  if (!y %in% names(panel)) next
  message("Modeling Cost: ", y)
  
  # Gamma on positives
  m <- fit_gamma_pos(panel, y)
  est <- recycled_rate(m, panel %>% filter(.data[[y]] > 0)) # Note: recycled on positives only for conditional
  
  boot <- boot_cluster(panel, ids, B, function(d) fit_gamma_pos(d, y), function(m, d) recycled_rate(m, d %>% filter(.data[[y]] > 0)))
  
  res <- est %>% mutate(
    outcome = y,
    type = "cost_gamma_pos",
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
write_csv(final_tbl, "outputs/panel_models_summary.csv")
message("Done. Results saved to outputs/panel_models_summary.csv")
```

## Action

1. Write this content to `scripts/30_models_panel_nb_gamma.R`.
2. Ensure the script is functional.
