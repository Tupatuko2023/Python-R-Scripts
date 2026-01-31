#!/usr/bin/env Rscript

# scripts/45_visualize_aim2_outputs.R
# Purpose: Generate visual artifacts (Forest plots, Trends, QC) from Aim 2 outputs.
# Adheres to Option B: Aggregate-only outputs.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(readr)
  library(ragg)
})

# --- Init Paths ---
# Use a fixed run ID or timestamp
RUN_ID <- format(Sys.time(), "%Y%m%dT%H%M%S")
BASE_OUT <- "outputs/figures"
FIG_DIR  <- file.path(BASE_OUT, RUN_ID)
AGG_DIR  <- file.path(FIG_DIR, "aggregates")
dir.create(AGG_DIR, recursive = TRUE, showWarnings = FALSE)

# Inputs
MODELS_PATH <- "outputs/panel_models_summary.csv"
QC_MISS_PATH <- "outputs/qc/qc_missingness.csv"

# --- 1) Forest Plot for Model Estimates ---
if (file.exists(MODELS_PATH)) {
  message("Generating Forest Plot...")
  df_models <- read_csv(MODELS_PATH, show_col_types = FALSE)
  
  # Clean outcome names for plotting
  df_models <- df_models %>%
    mutate(outcome_label = gsub("_", " ", outcome))
  
  p_forest <- ggplot(df_models, aes(x = ratio, y = reorder(outcome_label, ratio), color = type)) +
    geom_vline(xintercept = 1, linetype = "dashed", alpha = 0.5) +
    geom_point(size = 3) +
    geom_errorbarh(aes(xmin = ratio_l, xmax = ratio_u), height = 0.2) +
    theme_minimal() +
    labs(title = "Aim 2: Model Ratios (FOF 1 vs 0)",
         subtitle = "Rate Ratios (NB) and Cost Ratios (Gamma)",
         x = "Ratio (95% CI)", y = "Outcome") +
    theme(legend.position = "bottom")

  agg_png(file.path(FIG_DIR, "forest_plot_ratios.png"), width = 1000, height = 700, res = 120)
  print(p_forest)
  dev.off()
} else {
  message("Warning: ", MODELS_PATH, " not found.")
}

# --- 2) QC Missingness Summary ---
if (file.exists(QC_MISS_PATH)) {
  message("Generating QC Missingness Plot...")
  df_miss <- read_csv(QC_MISS_PATH, show_col_types = FALSE)
  
  # Top variables with missingness
  df_miss_top <- df_miss %>% 
    group_by(variable) %>% 
    summarise(missing_count = sum(missing_count), .groups = "drop") %>%
    arrange(desc(missing_count)) %>% 
    head(15)
  
  if (nrow(df_miss_top) > 0) {
    p_miss <- ggplot(df_miss_top, aes(x = reorder(variable, missing_count), y = missing_count)) +
      geom_col(fill = "steelblue") +
      coord_flip() +
      theme_minimal() +
      labs(title = "QC: Top 15 Missing Variables",
           x = "Variable", y = "Missing Count")

    agg_png(file.path(FIG_DIR, "qc_missingness_top15.png"), width = 1000, height = 700, res = 120)
    print(p_miss)
    dev.off()
  }
}

# --- 3) Trend Plots (if panel data available) ---
DATA_ROOT <- Sys.getenv("DATA_ROOT")
PANEL_PATH <- file.path(DATA_ROOT, "derived", "aim2_panel.csv")

if (DATA_ROOT != "" && file.exists(PANEL_PATH)) {
  message("Generating Outcome Trends from: ", PANEL_PATH)
  # Read only necessary columns to save memory
  panel <- read_csv(PANEL_PATH, show_col_types = FALSE)
  
  # Aggregate by period and FOF status (Safe aggregate)
  trends <- panel %>%
    group_by(period, FOF_status) %>%
    summarise(
      n_obs = n(),
      total_visits = sum(util_visits_total, na.rm = TRUE),
      total_cost = sum(cost_total_eur, na.rm = TRUE),
      total_pt = sum(person_time, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      rate_py = total_visits / total_pt,
      cost_py = total_cost / total_pt
    )
  
  # Save trend aggregate
  write_csv(trends, file.path(AGG_DIR, "trends_aggregate.csv"))
  
  # Plot Visits Trend
  p_trend_v <- ggplot(trends, aes(x = period, y = rate_py, color = factor(FOF_status), group = FOF_status)) +
    geom_line(size = 1.2) + 
    geom_point(size = 3) +
    theme_minimal() +
    scale_color_brewer(palette = "Set1") +
    labs(title = "Visit Trends by FOF Status",
         subtitle = "Visits per Person-Year",
         x = "Follow-up Period (Years)", y = "Visits / PY",
         color = "FOF Status")
  
  agg_png(file.path(FIG_DIR, "trend_visits_py.png"), width = 1000, height = 700, res = 120)
  print(p_trend_v)
  dev.off()

  # Plot Cost Trend
  p_trend_c <- ggplot(trends, aes(x = period, y = cost_py, color = factor(FOF_status), group = FOF_status)) +
    geom_line(size = 1.2) + 
    geom_point(size = 3) +
    theme_minimal() +
    scale_color_brewer(palette = "Set2") +
    labs(title = "Cost Trends by FOF Status",
         subtitle = "EUR per Person-Year",
         x = "Follow-up Period (Years)", y = "EUR / PY",
         color = "FOF Status")
  
  agg_png(file.path(FIG_DIR, "trend_costs_py.png"), width = 1000, height = 700, res = 120)
  print(p_trend_c)
  dev.off()
  
  # --- 4) Frailty Trends (Updated) ---
  if ("frailty_binary" %in% names(panel)) {
    message("Generating Frailty Trends (Binary)...")
    trends_frail <- panel %>%
      filter(frailty_binary != "unknown") %>%
      group_by(period, frailty_binary) %>%
      summarise(
        n_obs = n(),
        total_visits = sum(util_visits_total, na.rm = TRUE),
        total_pt = sum(person_time, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      mutate(rate_py = total_visits / total_pt)
      
    if (nrow(trends_frail) > 0) {
      p_frail <- ggplot(trends_frail, aes(x = period, y = rate_py, color = frailty_binary, group = frailty_binary)) +
        geom_line(size = 1.2) + 
        geom_point(size = 3) +
        theme_minimal() +
        scale_color_viridis_d(option = "plasma", end = 0.8) +
        labs(title = "Visit Trends by Frailty Status (Binary)",
             subtitle = "Visits per Person-Year",
             x = "Follow-up Period (Years)", y = "Visits / PY",
             color = "Frailty")
      
      agg_png(file.path(FIG_DIR, "trend_visits_by_frailty_binary.png"), width = 1000, height = 700, res = 120)
      print(p_frail)
      dev.off()
    }
  }

} else {
  message("Skipping Trend Plots: DATA_ROOT or aim2_panel.csv missing.")
}

message("Visualization complete. Artifacts in ", FIG_DIR)
