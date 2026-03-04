#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(tidyr)
  library(tibble)
})

resolve_data_root <- function() {
  dr <- Sys.getenv("DATA_ROOT", unset = "")
  if (dr == "") {
    stop(
      paste(
        "DATA_ROOT is required for K37.",
        "Set it in config/.env and run via proot command that sources config/.env in-call.",
        sep = "\n"
      ),
      call. = FALSE
    )
  }
  dr
}

read_external <- function(base_no_ext) {
  rds <- paste0(base_no_ext, ".rds")
  csv <- paste0(base_no_ext, ".csv")
  if (file.exists(rds)) return(readRDS(rds))
  if (file.exists(csv)) return(readr::read_csv(csv, show_col_types = FALSE))
  stop(sprintf("Missing external input: %s(.rds|.csv)", base_no_ext), call. = FALSE)
}

get_beta <- function(df, term) {
  row <- df %>% filter(.data$effect == "fixed", .data$term == term)
  if (nrow(row) == 0) return(0)
  as.numeric(row$estimate[[1]])
}

fof_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
out_dir <- file.path(fof_root, "R-scripts", "K37", "outputs")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

data_root <- resolve_data_root()

k36_lmm_ext <- readr::read_csv(
  file.path(fof_root, "R-scripts", "K36", "outputs", "k36_lmm_extended_fixed_effects.csv"),
  show_col_types = FALSE
)
k36_lmm_cmp <- readr::read_csv(
  file.path(fof_root, "R-scripts", "K36", "outputs", "k36_lmm_model_comparison.csv"),
  show_col_types = FALSE
)
k36_ancova_cmp <- readr::read_csv(
  file.path(fof_root, "R-scripts", "K36", "outputs", "k36_ancova_model_comparison.csv"),
  show_col_types = FALSE
)

k33_long <- read_external(file.path(data_root, "paper_01", "analysis", "fof_analysis_k33_long"))
k33_wide <- read_external(file.path(data_root, "paper_01", "analysis", "fof_analysis_k33_wide"))
k32 <- read_external(file.path(data_root, "paper_01", "capacity_scores", "kaatumisenpelko_with_capacity_scores_k32"))

req_long <- c("id", "time", "Composite_Z", "age", "BMI")
req_wide <- c("id", "Composite_Z_baseline")
req_k32 <- c("id", "capacity_score_latent_primary")

miss_long <- setdiff(req_long, names(k33_long))
miss_wide <- setdiff(req_wide, names(k33_wide))
miss_k32 <- setdiff(req_k32, names(k32))
if (length(miss_long) > 0 || length(miss_wide) > 0 || length(miss_k32) > 0) {
  stop(
    paste0(
      "Missing required columns.",
      " long:", paste(miss_long, collapse = ","),
      " wide:", paste(miss_wide, collapse = ","),
      " k32:", paste(miss_k32, collapse = ",")
    ),
    call. = FALSE
  )
}

baseline_df <- k33_wide %>%
  select(all_of(c("id", "Composite_Z_baseline"))) %>%
  left_join(k32 %>% select(all_of(c("id", "capacity_score_latent_primary"))), by = "id") %>%
  filter(!is.na(.data$Composite_Z_baseline), !is.na(.data$capacity_score_latent_primary))

cap_mean <- mean(baseline_df$capacity_score_latent_primary)
cap_sd <- sd(baseline_df$capacity_score_latent_primary)

cap_levels <- tibble(
  cap_label = c("Capacity -1 SD", "Capacity mean", "Capacity +1 SD"),
  capacity_score_latent_primary = c(cap_mean - cap_sd, cap_mean, cap_mean + cap_sd)
)

b0 <- get_beta(k36_lmm_ext, "(Intercept)")
b_time <- get_beta(k36_lmm_ext, "time_f12")
b_cap <- get_beta(k36_lmm_ext, "capacity_score_latent_primary")
b_time_cap <- get_beta(k36_lmm_ext, "time_f12:capacity_score_latent_primary")
b_age <- get_beta(k36_lmm_ext, "age")
b_bmi <- get_beta(k36_lmm_ext, "BMI")

mean_age <- mean(k33_long$age, na.rm = TRUE)
mean_bmi <- mean(k33_long$BMI, na.rm = TRUE)

traj <- tidyr::expand_grid(
  cap_levels,
  time = c(0, 12)
) %>%
  mutate(
    t12 = ifelse(.data$time == 12, 1, 0),
    pred = b0 +
      b_age * mean_age +
      b_bmi * mean_bmi +
      b_time * .data$t12 +
      b_cap * .data$capacity_score_latent_primary +
      b_time_cap * .data$t12 * .data$capacity_score_latent_primary
  )

p_traj <- ggplot(traj, aes(x = factor(time), y = pred, color = cap_label, group = cap_label)) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.4) +
  scale_color_manual(values = c("#1b9e77", "#7570b3", "#d95f02")) +
  labs(
    title = "Predicted Composite_Z Trajectories by Baseline Capacity",
    subtitle = "K36 extended LMM fixed effects (capacity at -1 SD / mean / +1 SD)",
    x = "Time (months)",
    y = "Predicted Composite_Z",
    color = "Baseline capacity"
  ) +
  theme_classic(base_size = 12)

ggsave(
  filename = file.path(out_dir, "k37_predicted_trajectories.png"),
  plot = p_traj,
  width = 8.5,
  height = 5.3,
  dpi = 320
)

lmm_primary <- k36_lmm_cmp %>% filter(.data$model == "m_lmm_primary_common")
lmm_extended <- k36_lmm_cmp %>% filter(.data$model == "m_lmm_extended_common")

anc_primary <- k36_ancova_cmp %>% filter(.data$model == "primary")
anc_extended <- k36_ancova_cmp %>% filter(.data$model == "extended")

model_cmp <- tibble(
  model_family = c("LMM", "ANCOVA"),
  delta_aic = c(
    as.numeric(lmm_extended$AIC) - as.numeric(lmm_primary$AIC),
    as.numeric(anc_extended$AIC) - as.numeric(anc_primary$AIC)
  ),
  delta_r2 = c(
    NA_real_,
    as.numeric(anc_extended$adj_r2) - as.numeric(anc_primary$adj_r2)
  )
)

cmp_long <- model_cmp %>%
  tidyr::pivot_longer(cols = c("delta_aic", "delta_r2"), names_to = "metric", values_to = "value") %>%
  filter(!is.na(.data$value)) %>%
  mutate(
    metric = recode(.data$metric, delta_aic = "Delta AIC (Extended - Primary)", delta_r2 = "Delta Adj R2 (Extended - Primary)")
  )

p_cmp <- ggplot(cmp_long, aes(x = model_family, y = value, fill = metric)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.62) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray40") +
  scale_fill_manual(values = c("Delta AIC (Extended - Primary)" = "#4c78a8", "Delta Adj R2 (Extended - Primary)" = "#f58518")) +
  labs(
    title = "Primary vs Extended Model Improvement (K36)",
    subtitle = "Lower Delta AIC and higher Delta Adj R2 indicate improved fit",
    x = "Model family",
    y = "Change from primary model",
    fill = "Metric"
  ) +
  theme_classic(base_size = 12)

ggsave(
  filename = file.path(out_dir, "k37_model_comparison.png"),
  plot = p_cmp,
  width = 8.2,
  height = 5.2,
  dpi = 320
)

p_scatter <- ggplot(
  baseline_df,
  aes(x = .data$capacity_score_latent_primary, y = .data$Composite_Z_baseline)
) +
  geom_point(alpha = 0.55, size = 1.8, color = "#1f77b4") +
  geom_smooth(method = "lm", se = TRUE, color = "#d62728", linewidth = 0.9) +
  labs(
    title = "Baseline Association: Capacity Latent Score vs Composite_Z",
    subtitle = "Participant-level baseline values (aggregate visualization only)",
    x = "capacity_score_latent_primary",
    y = "Composite_Z_baseline"
  ) +
  theme_classic(base_size = 12)

ggsave(
  filename = file.path(out_dir, "k37_capacity_vs_baseline.png"),
  plot = p_scatter,
  width = 8.2,
  height = 5.2,
  dpi = 320
)

caption_lines <- c(
  "Figure 1 (k37_predicted_trajectories.png): Predicted 0 to 12 month Composite_Z trajectories from K36 extended LMM fixed effects.",
  "Capacity is shown at -1 SD, mean, and +1 SD of baseline capacity_score_latent_primary.",
  "Predictions hold categorical terms at reference and continuous covariates at sample means.",
  "",
  "Figure 2 (k37_model_comparison.png): Primary vs extended model changes.",
  "Delta AIC is shown for LMM and ANCOVA; Delta Adj R2 is shown where available from aggregate K36 outputs (ANCOVA).",
  "",
  "Figure 3 (k37_capacity_vs_baseline.png): Baseline association between capacity_score_latent_primary and Composite_Z_baseline.",
  "A linear trend line with confidence band is provided for interpretation.",
  "",
  "All outputs are aggregate-only repository artifacts; patient-level data remain externalized under DATA_ROOT."
)
writeLines(caption_lines, con = file.path(out_dir, "k37_figure_caption.txt"))

sink(file.path(out_dir, "k37_sessioninfo.txt"))
cat("K37 session info\n")
print(sessionInfo())
sink()

message("K37 outputs written to: ", out_dir)
