#!/usr/bin/env Rscript

# Quantify-FOF-Utilization-Costs/R/60_board_ready_dashboard.R
# Purpose: Final "Board-Ready" Dashboard with Stratified Forest Plots
# Security: Aggregate-only data (Option B).

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(readr)
  library(ragg)
  library(stringr)
})

# --- Configuration ---
# Use a fixed run ID or timestamp
RUN_ID <- format(Sys.time(), "%Y%m%dT%H%M%S")
BASE_OUT <- "outputs/figures"
FIG_DIR  <- file.path(BASE_OUT, RUN_ID)
dir.create(FIG_DIR, recursive = TRUE, showWarnings = FALSE)

MODELS_PATH <- "outputs/panel_models_summary.csv"
TRENDS_PATH <- "outputs/trends_aggregate.csv"

# Common Theme
theme_board <- theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(color = "gray30", size = 11),
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold", size = 12)
  )

# --- 1) Load Data ---
if (!file.exists(MODELS_PATH)) stop("Models summary missing: ", MODELS_PATH)
models <- read_csv(MODELS_PATH, show_col_types = FALSE)

# --- 2) Stratified Forest Plot ---
message("Generating Stratified Forest Plot...")

# Prepare data for plotting
plot_df <- models %>%
  mutate(
    stratum_label = case_when(
      stratum == "Overall" ~ "Overall (N=486)",
      stratum == "robust" ~ "Robust",
      stratum == "pre-frail" ~ "Pre-frail",
      stratum == "frail" ~ "Frail",
      TRUE ~ stratum
    ),
    stratum_label = factor(stratum_label, levels = rev(c("Overall (N=486)", "Robust", "Pre-frail", "Frail"))),
    outcome_label = ifelse(outcome == "cost_total_eur", "Healthcare Costs (EUR)", "Service Utilization (Visits)"),
    type_label = ifelse(grepl("cost", type), "Cost Ratio (Gamma)", "Rate Ratio (NB)")
  )

p_strata <- ggplot(plot_df, aes(x = ratio, y = stratum_label, color = stratum_label)) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "gray50") +
  geom_errorbarh(aes(xmin = ratio_l, xmax = ratio_u), height = 0.3, linewidth = 1.2) +
  geom_point(size = 5) +
  facet_wrap(~outcome_label, scales = "free_x") +
  scale_color_manual(values = c("Overall (N=486)" = "black", "Robust" = "#2ecc71", "Pre-frail" = "#f39c12", "Frail" = "#e74c3c")) +
  labs(
    title = "Fear of Falling Impact by Physical Frailty",
    subtitle = "Adjusted Ratios (FOF+ vs FOF-) with 95% Bootstrap CIs (B=500)",
    x = "Ratio (95% CI)",
    y = "",
    caption = "Note: Ratio > 1.0 indicates higher utilization/costs in the FOF group.\nOverall cost ratio: 1.16 [0.98, 1.39]."
  ) +
  theme_board +
  theme(legend.position = "none", axis.text.y = element_text(face = "bold", size = 11))

agg_png(file.path(FIG_DIR, "forest_plot_strata.png"), width = 1200, height = 600, res = 120)
print(p_strata)
dev.off()

# --- 3) Trends Comparison (Visits) ---
if (file.exists(TRENDS_PATH)) {
  message("Generating Trend Plots...")
  trends <- read_csv(TRENDS_PATH, show_col_types = FALSE) %>%
    mutate(fof_label = ifelse(FOF_status == 1, "FOF+", "FOF-"))

  p_trend_v <- ggplot(trends, aes(x = period, y = rate_py, color = fof_label, group = fof_label)) +
    geom_line(linewidth = 1.5) +
    geom_point(size = 4) +
    scale_color_brewer(palette = "Set1") +
    labs(title = "Healthcare Utilization Trends",
         subtitle = "Visits per Person-Year by FOF status",
         x = "Follow-up Year", y = "Visits / PY", color = "Group") +
    theme_board

  agg_png(file.path(FIG_DIR, "trend_visits_final.png"), width = 1000, height = 600, res = 120)
  print(p_trend_v)
  dev.off()
  
  p_trend_c <- ggplot(trends, aes(x = period, y = cost_py, color = fof_label, group = fof_label)) +
    geom_line(linewidth = 1.5) +
    geom_point(size = 4) +
    scale_color_brewer(palette = "Set2") +
    labs(title = "Healthcare Cost Trends",
         subtitle = "Annual Costs (EUR) per Person-Year by FOF status",
         x = "Follow-up Year", y = "EUR / PY", color = "Group") +
    theme_board

  agg_png(file.path(FIG_DIR, "trend_costs_final.png"), width = 1000, height = 600, res = 120)
  print(p_trend_c)
  dev.off()
}

message("Dashboard generation complete.")
message("Artifacts saved to: ", FIG_DIR)
