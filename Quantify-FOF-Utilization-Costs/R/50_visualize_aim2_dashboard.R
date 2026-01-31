#!/usr/bin/env Rscript

# R/50_visualize_aim2_dashboard.R
# Purpose: Generate "Board-Ready" Dashboard for Aim 2 (Utilization & Costs)
# Security: Option B (Aggregates only in outputs/)

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(readr)
  library(ragg)
  library(stringr)
})

# --- Init Paths ---
RUN_ID <- format(Sys.time(), "%Y%m%dT%H%M%S")
BASE_OUT <- "outputs/figures"
FIG_DIR  <- file.path(BASE_OUT, RUN_ID)
dir.create(FIG_DIR, recursive = TRUE, showWarnings = FALSE)

# Inputs
MODELS_PATH <- "outputs/panel_models_summary.csv"
TRENDS_PATH <- "trends_aggregate.csv" # Check root first, then generate

# --- 1) Data Prep: Trends Aggregate ---
trends <- NULL

if (file.exists(TRENDS_PATH)) {
  message("Loading existing trends aggregate: ", TRENDS_PATH)
  trends <- read_csv(TRENDS_PATH, show_col_types = FALSE)
} else {
  message("Trends aggregate not found. Attempting to generate from secure panel data...")
  DATA_ROOT <- Sys.getenv("DATA_ROOT")
  PANEL_PATH <- file.path(DATA_ROOT, "derived", "aim2_panel.csv")
  
  if (DATA_ROOT != "" && file.exists(PANEL_PATH)) {
    message("Reading: ", PANEL_PATH)
    panel <- read_csv(PANEL_PATH, show_col_types = FALSE)
    
    # Aggregation Logic
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
        cost_py = total_cost / total_pt,
        fof_label = ifelse(FOF_status == 1, "FOF+", "FOF-")
      )
    
    # Save for future use (Aggregate is safe)
    write_csv(trends, TRENDS_PATH)
    message("Created and saved: ", TRENDS_PATH)
  } else {
    warning("Cannot generate trends: DATA_ROOT not set or panel missing.")
  }
}

# --- 2) Dashboard Plots ---

if (!is.null(trends)) {
  # Common Theme
  theme_dashboard <- theme_minimal() +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(color = "gray40", size = 10),
      legend.position = "bottom",
      panel.grid.minor = element_blank()
    )

  # A) Participants N by Year
  p_n <- ggplot(trends, aes(x = factor(period), y = n_obs, fill = fof_label)) +
    geom_col(position = "dodge", alpha = 0.8) +
    scale_fill_brewer(palette = "Set1") +
    labs(title = "Participants (N) by Year",
         subtitle = "Number of observations per period",
         x = "Year", y = "Count (N)", fill = "Group") +
    theme_dashboard
  
  agg_png(file.path(FIG_DIR, "aim2_participants_N_by_year.png"), width = 1000, height = 600, res = 120)
  print(p_n)
  dev.off()

  # B) Person-Time PY by Year
  p_py <- ggplot(trends, aes(x = factor(period), y = total_pt, fill = fof_label)) +
    geom_col(position = "dodge", alpha = 0.8) +
    scale_fill_brewer(palette = "Set2") +
    labs(title = "Person-Time (PY) by Year",
         subtitle = "Total exposure years",
         x = "Year", y = "Person-Years", fill = "Group") +
    theme_dashboard
  
  agg_png(file.path(FIG_DIR, "aim2_person_time_PY_by_year.png"), width = 1000, height = 600, res = 120)
  print(p_py)
  dev.off()

  # C) Heatmap/Tile N Year by FOF (Simplified as stacked bar or tile)
  p_heat <- ggplot(trends, aes(x = factor(period), y = fof_label, fill = n_obs)) +
    geom_tile(color = "white") +
    geom_text(aes(label = n_obs), color = "white", size = 3.5) +
    scale_fill_viridis_c() +
    labs(title = "Cohort Density Heatmap",
         x = "Year", y = "Group", fill = "N") +
    theme_dashboard
  
  agg_png(file.path(FIG_DIR, "aim2_heatmap_N_year_by_fof.png"), width = 1000, height = 500, res = 120)
  print(p_heat)
  dev.off()

  # D) Trend Visits/PY Sized by N
  p_trend <- ggplot(trends, aes(x = period, y = rate_py, color = fof_label, group = fof_label)) +
    geom_line(linewidth = 1) +
    geom_point(aes(size = n_obs), alpha = 0.7) +
    scale_color_brewer(palette = "Set1") +
    scale_size_continuous(range = c(2, 6)) +
    labs(title = "Visit Rate Trends (Scaled by N)",
         subtitle = "Visits per Person-Year (Point size indicates sample size)",
         x = "Year", y = "Visits / PY", color = "Group", size = "N") +
    theme_dashboard
  
  agg_png(file.path(FIG_DIR, "aim2_trend_visits_py_sized_by_N.png"), width = 1000, height = 600, res = 120)
  print(p_trend)
  dev.off()
}

# --- 3) Forest Plot (Model Ratios) ---
if (file.exists(MODELS_PATH)) {
  message("Generating Forest Plot from models...")
  models <- read_csv(MODELS_PATH, show_col_types = FALSE)
  
  # Clean labels
  models <- models %>%
    mutate(
      outcome_clean = str_to_title(gsub("_", " ", outcome)),
      model_type = ifelse(grepl("cost", type), "Cost Ratio (Gamma)", "Rate Ratio (NB)")
    )
  
  p_forest <- ggplot(models, aes(x = ratio, y = reorder(outcome_clean, ratio), color = model_type)) +
    geom_vline(xintercept = 1, linetype = "dashed", color = "gray50") +
    geom_errorbarh(aes(xmin = ratio_l, xmax = ratio_u), height = 0.3, linewidth = 0.8) +
    geom_point(size = 3.5) +
    scale_color_manual(values = c("Cost Ratio (Gamma)" = "#E7B800", "Rate Ratio (NB)" = "#2E9FDF")) +
    labs(title = "Aim 2: Model Effect Estimates",
         subtitle = "Comparison of FOF+ vs FOF- (Ratio > 1 indicates higher utilization/cost)",
         x = "Ratio (95% CI)", y = "", color = "Model Type") +
    theme_dashboard +
    theme(panel.grid.major.y = element_blank())
  
  agg_png(file.path(FIG_DIR, "aim2_forest_model_ratios.png"), width = 1000, height = 700, res = 120)
  print(p_forest)
  dev.off()
} else {
  message("Skipping Forest Plot: ", MODELS_PATH, " not found.")
}

message("Dashboard generation complete. Outputs in: ", FIG_DIR)
