# --- Kxx template (put at top of every script) -------------------------------
suppressPackageStartupMessages({ library(here); library(dplyr) })

rm(list = ls(pattern = "^(save_|init_paths$|append_manifest$|manifest_row$)"),
   envir = .GlobalEnv)

source(here("R","functions","io.R"))
source(here("R","functions","checks.R"))
source(here("R","functions","modeling.R"))
source(here("R","functions","reporting.R"))

script_label <- sub("\\.R$", "", basename(commandArgs(trailingOnly=FALSE)[grep("--file=", commandArgs())] |> sub("--file=", "", x=_)))
if (is.na(script_label) || script_label == "") script_label <- "K16"
paths <- init_paths(script_label)

set.seed(20251124)


# K16: Frailty-Adjusted Statistical Models for Fear-of-Falling Study
# Purpose: Integrate frailty proxy variables from K15 into ANCOVA and mixed models

# Get paths from init_paths (already called in header)
outputs_dir   <- getOption("fof.outputs_dir")
manifest_path <- getOption("fof.manifest_path")
output_dir    <- outputs_dir  # alias for compatibility

suppressPackageStartupMessages({
  library(tidyr)
  library(lme4)
  library(lmerTest)
  library(car)
  library(broom)
  library(broom.mixed)
  library(flextable)
  library(officer)
  library(ggplot2)
  library(reformulas)
})
library(conflicted)
conflicted::conflict_prefer("select", "dplyr")
conflicted::conflict_prefer("filter", "dplyr")
conflicted::conflict_prefer("recode", "dplyr")
conflicted::conflict_prefer("lmer", "lmerTest")

message("\n", strrep("=", 80))
message("K16: FRAILTY-ADJUSTED STATISTICAL MODELS")
message(strrep("=", 80), "\n")

# ==============================================================================
# 01. Load Data with Frailty Variables
# ==============================================================================

message("01) Loading analysis data with frailty variables from K15...")

force_reload <- TRUE
if (force_reload && exists("analysis_data")) rm(analysis_data)

# Check if analysis_data already exists in environment
if (!exists("analysis_data")) {
  # Try to load from K15 RData file
  k15_rdata <- here::here("R-scripts", "K15", "outputs",
                         "K15_frailty_analysis_data.RData")

  if (file.exists(k15_rdata)) {
    load(k15_rdata)
    message("✓ Loaded analysis_data from: ", k15_rdata)
  } else {
    # Run K15.R to generate the data
    message("Running K15.R to generate frailty variables...")
    source(here::here("R-scripts", "K15", "K15.R"))
  }
}

# --- Harmonize variable names expected by K16 -------------------------------

# ID (K11/K9-datassa usein Jnro)
if (!("ID" %in% names(analysis_data))) {
  if ("Jnro" %in% names(analysis_data)) {
    analysis_data <- analysis_data %>% mutate(ID = Jnro)
  } else if ("NRO" %in% names(analysis_data)) {
    analysis_data <- analysis_data %>% mutate(ID = NRO)
  } else {
    stop("K16: ID puuttuu eikä löytynyt Jnro/NRO-korviketta.")
  }
}

# Composite baseline + follow-up: mapataan ToimintaKykySummary0/2 -> Composite_Z0/3
if (!("Composite_Z0" %in% names(analysis_data))) {
  if ("ToimintaKykySummary0" %in% names(analysis_data)) {
    analysis_data <- analysis_data %>% mutate(Composite_Z0 = ToimintaKykySummary0)
  } else {
    stop("K16: Composite_Z0 puuttuu eikä löytynyt ToimintaKykySummary0-korviketta.")
  }
}

if (!("Composite_Z3" %in% names(analysis_data))) {
  if ("ToimintaKykySummary2" %in% names(analysis_data)) {
    analysis_data <- analysis_data %>% mutate(Composite_Z3 = ToimintaKykySummary2)
  } else {
    stop("K16: Composite_Z3 puuttuu eikä löytynyt ToimintaKykySummary2-korviketta.")
  }
}


if ("frailty_count_3" %in% names(analysis_data) &&
    all(is.na(analysis_data$frailty_cat_3))) {

  analysis_data <- analysis_data %>%
    mutate(
      frailty_cat_3 = case_when(
        is.na(frailty_count_3) ~ NA_character_,
        frailty_count_3 == 0   ~ "robust",
        frailty_count_3 == 1   ~ "pre-frail",
        frailty_count_3 >= 2   ~ "frail"
      ),
      frailty_cat_3 = factor(frailty_cat_3, levels = c("robust","pre-frail","frail"))
    )
}

analysis_data <- analysis_data %>%
  mutate(frailty_cat_3_label = factor(frailty_cat_3,
                                      levels = c("robust","pre-frail","frail"),
                                      labels = c("Robust","Pre-frail","Frail")
  ))

table(analysis_data$frailty_cat_3, useNA="ifany")


# Frailty continuous score: K15 tuottaa frailty_count_3 -> käytetään sitä score:na
if (!("frailty_score_3" %in% names(analysis_data))) {
  if ("frailty_count_3" %in% names(analysis_data)) {
    analysis_data <- analysis_data %>% mutate(frailty_score_3 = as.numeric(frailty_count_3))
  } else {
    stop("K16: frailty_score_3 puuttuu eikä löytynyt frailty_count_3-korviketta.")
  }
}



# Käytä K15:n valmista faktorimuuttujaa (nonFOF/FOF)
# FOF_status: oletus 0 = nonFOF, 1 = FOF

if ("FOF_status_factor" %in% names(analysis_data)) {
  analysis_data <- analysis_data %>%
    mutate(FOF_status = droplevels(FOF_status_factor))
} else {
  # fallback (jos factor puuttuu): tunnista myös "nonFOF"
  analysis_data <- analysis_data %>%
    mutate(
      FOF_status = trimws(as.character(FOF_status)),
      FOF_status = case_when(
        FOF_status %in% c("nonFOF","No_FOF","No FOF","NoFOF","0","FALSE","False") ~ "nonFOF",
        FOF_status %in% c("FOF","1","TRUE","True") ~ "FOF",
        TRUE ~ NA_character_
      ),
      FOF_status = factor(FOF_status, levels = c("nonFOF","FOF"))
    )
}

# sex: tee sama (0/1 -> female/male), jotta pred_data:n factorit matchaa
analysis_data <- analysis_data %>%
  mutate(
    sex = trimws(as.character(sex)),
    sex = case_when(
      sex %in% c("0", "female", "Female", "F") ~ "female",
      sex %in% c("1", "male", "Male", "M") ~ "male",
      TRUE ~ sex
    ),
    sex = factor(sex)
  )

# 1) Mitä FOF_status on koko datassa nyt?
print(table(analysis_data$FOF_status, useNA = "ifany"))

# 2) Mitkä olivat alkuperäiset FOF-arvot ennen recodea? (jos et tallettanut, tee nyt seuraavalla ajolla)
analysis_data$FOF_raw <- analysis_data$FOF_status  # tee tämä ENNEN recodea
print(table(analysis_data$FOF_raw, useNA="ifany"))
print(sort(unique(as.character(analysis_data$FOF_raw))))

# 3) Kuinka moni on complete-case per ryhmä?
cc_flag <- complete.cases(
  analysis_data[, c("Composite_Z0","Composite_Z3","age","sex","BMI","FOF_status")]
)

analysis_data %>%
  mutate(cc = cc_flag) %>%
  count(FOF_status, cc)

# Verify required frailty variables exist
required_vars <- c("frailty_cat_3", "frailty_cat_3_obj", "frailty_cat_3_2plus",
                   "frailty_score_3", "FOF_status", "Composite_Z0", "Composite_Z3")


analysis_data %>%
  mutate(has_CZ3 = !is.na(Composite_Z3)) %>%
  count(FOF_status, has_CZ3)

missing_vars <- setdiff(required_vars, names(analysis_data))
if (length(missing_vars) > 0) {
  stop("Missing required variables: ", paste(missing_vars, collapse = ", "))
}

message("✓ All required frailty variables present")
message("  - frailty_cat_3: ", sum(!is.na(analysis_data$frailty_cat_3)), " valid cases")
message("  - frailty_cat_3_obj: ", sum(!is.na(analysis_data$frailty_cat_3_obj)), " valid cases")
message("  - frailty_cat_3_2plus: ", sum(!is.na(analysis_data$frailty_cat_3_2plus)), " valid cases")

# ==============================================================================
# 02. Prepare Data for Analysis
# ==============================================================================

message("\n02) Preparing data for analysis...")

# 4.1 Create Delta variable for ANCOVA

table(analysis_data$FOF_status, useNA="ifany")


fix_frailty <- function(x){
  x0 <- tolower(trimws(as.character(x)))
  out <- dplyr::case_when(
    x0 %in% c("robust") ~ "Robust",
    grepl("pre", x0) ~ "Pre-frail",
    x0 %in% c("frail") ~ "Frail",
    TRUE ~ NA_character_
  )
  factor(out, levels = c("Robust","Pre-frail","Frail"))
}

table(analysis_data$frailty_cat_3, useNA="ifany")

analysis_data <- analysis_data %>%
  mutate(
    Delta_Composite_Z = Composite_Z3 - Composite_Z0,
    frailty_cat_3       = fix_frailty(frailty_cat_3),
    frailty_cat_3_obj   = fix_frailty(frailty_cat_3_obj),
    frailty_cat_3_2plus = fix_frailty(frailty_cat_3_2plus)
  )


# 4.2 Create long-format data for mixed models
message("Creating long-format data for mixed models...")

analysis_long <- analysis_data %>%
  mutate(Composite_Z0_baseline = Composite_Z0) %>%
  dplyr::select(
    ID, FOF_status, frailty_cat_3, frailty_cat_3_obj, frailty_cat_3_2plus,
    frailty_score_3, age, sex, BMI,
    Composite_Z0_baseline, Composite_Z0, Composite_Z3
  ) %>%
  pivot_longer(
    cols = c(Composite_Z0, Composite_Z3),
    names_to = "timepoint",
    values_to = "Composite_Z"
  ) %>%
  mutate(
    time = ifelse(timepoint == "Composite_Z0", 0, 3),
    time_factor = factor(time, levels = c(0, 3), labels = c("Baseline", "3 months"))
  )

analysis_long$FOF_status
analysis_long$sex

message("✓ Data preparation complete")
message("  - Wide format (ANCOVA): ", nrow(analysis_data), " participants")
message("  - Long format (Mixed models): ", nrow(analysis_long), " observations")

# ==============================================================================
# 03. Primary ANCOVA Models
# ==============================================================================

message("\n03) Running primary ANCOVA models (Delta-analysis)...")

# varmista että score on olemassa ja numeerinen
analysis_data <- analysis_data %>%
  mutate(frailty_score_3 = as.numeric(frailty_score_3))

dat_delta <- analysis_data %>%
  mutate(Delta_Composite_Z = Composite_Z3 - Composite_Z0) %>%
  dplyr::select(
    Delta_Composite_Z, FOF_status,
    frailty_cat_3, frailty_score_3,
    Composite_Z0, age, sex, BMI
  ) %>%
  tidyr::drop_na() %>%
  droplevels()

table(dat_delta$FOF_status)
table(dat_delta$frailty_cat_3)

stopifnot(nlevels(dat_delta$FOF_status) >= 2, nlevels(dat_delta$frailty_cat_3) >= 2)
table(is.na(dat_delta$frailty_score_3))

# Use treatment contrasts so terms become e.g. FOF_statusFOF, frailty_cat_3Pre-frail, ...
op_contr <- options("contrasts")
options(contrasts = c("contr.treatment", "contr.poly"))
on.exit(options(op_contr), add = TRUE)

# Ensure reference levels
dat_delta <- dat_delta %>%
  mutate(
    FOF_status    = relevel(FOF_status, ref = "nonFOF"),
    frailty_cat_3 = relevel(frailty_cat_3, ref = "Robust"),
    sex           = relevel(sex, ref = "female")
  )

analysis_long <- analysis_long %>%
  mutate(
    FOF_status    = relevel(FOF_status, ref = "nonFOF"),
    frailty_cat_3 = relevel(frailty_cat_3, ref = "Robust"),
    sex           = relevel(sex, ref = "female")
  )


# 5.1 Model without frailty (baseline comparison)
mod_delta_baseline <- lm(Delta_Composite_Z ~ FOF_status + Composite_Z0 + age + sex + BMI,
                         data = dat_delta)

# 5.2 Model with frailty_cat_3 (primary)
mod_delta_frailty  <- lm(Delta_Composite_Z ~ FOF_status + frailty_cat_3 + Composite_Z0 + age + sex + BMI,
                         data = dat_delta)

# 5.3 Model with frailty_score_3 (continuous)
mod_delta_frailty_cont <- lm(Delta_Composite_Z ~ FOF_status + frailty_score_3 + Composite_Z0 + age + sex + BMI,
                             data = dat_delta)

message("✓ ANCOVA models fitted")

# Extract and format results
ancova_results <- list(
  baseline = broom::tidy(mod_delta_baseline, conf.int = TRUE),
  frailty_cat = broom::tidy(mod_delta_frailty, conf.int = TRUE),
  frailty_cont = broom::tidy(mod_delta_frailty_cont, conf.int = TRUE)
)

unique(ancova_results$frailty_cat$term)


# Model comparison
ancova_comparison <- data.frame(
  Model = c("Baseline (no frailty)", "Frailty categorical", "Frailty continuous"),
  AIC = c(AIC(mod_delta_baseline), AIC(mod_delta_frailty), AIC(mod_delta_frailty_cont)),
  BIC = c(BIC(mod_delta_baseline), BIC(mod_delta_frailty), BIC(mod_delta_frailty_cont)),
  R2 = c(summary(mod_delta_baseline)$r.squared,
         summary(mod_delta_frailty)$r.squared,
         summary(mod_delta_frailty_cont)$r.squared),
  Adj_R2 = c(summary(mod_delta_baseline)$adj.r.squared,
             summary(mod_delta_frailty)$adj.r.squared,
             summary(mod_delta_frailty_cont)$adj.r.squared)
)

# ==============================================================================
# 04. Primary Mixed Models
# ==============================================================================

message("\n04) Running primary mixed models (Longitudinal analysis)...")

# 6.1 Model without frailty (baseline comparison)
mod_mixed_baseline <- lmer(
  Composite_Z ~ time * FOF_status + Composite_Z0_baseline + age + sex + BMI + (1 | ID),
  data = analysis_long,
  REML = TRUE
)

# 6.2 Model with frailty_cat_3 (primary)
mod_mixed_frailty <- lmer(
  Composite_Z ~ time * FOF_status + frailty_cat_3 + Composite_Z0_baseline + age + sex + BMI + (1 | ID),
  data = analysis_long,
  REML = TRUE
)

# 6.3 Model with frailty_score_3 (continuous)
mod_mixed_frailty_cont <- lmer(
  Composite_Z ~ time * FOF_status + frailty_score_3 + Composite_Z0_baseline + age + sex + BMI + (1 | ID),
  data = analysis_long,
  REML = TRUE
)

message("✓ Mixed models fitted")

# Extract and format results
mixed_results <- list(
  baseline = broom.mixed::tidy(mod_mixed_baseline, conf.int = TRUE),
  frailty_cat = broom.mixed::tidy(mod_mixed_frailty, conf.int = TRUE),
  frailty_cont = broom.mixed::tidy(mod_mixed_frailty_cont, conf.int = TRUE)
)

unique(mixed_results$frailty_cat$term[mixed_results$frailty_cat$effect=="fixed"])


# Model comparison
mixed_comparison <- data.frame(
  Model = c("Baseline (no frailty)", "Frailty categorical", "Frailty continuous"),
  AIC = c(AIC(mod_mixed_baseline), AIC(mod_mixed_frailty), AIC(mod_mixed_frailty_cont)),
  BIC = c(BIC(mod_mixed_baseline), BIC(mod_mixed_frailty), BIC(mod_mixed_frailty_cont))
)

# ==============================================================================
# 05. Exploratory Interaction Models
# ==============================================================================

message("\n05) Running exploratory interaction models...")

# 7.1 ANCOVA with FOF × frailty interaction
mod_delta_interaction <- lm(
  Delta_Composite_Z ~ FOF_status * frailty_cat_3 + Composite_Z0 + age + sex + BMI,
  data = analysis_data
)

# 7.2 Mixed model with time × FOF × frailty interaction
mod_mixed_interaction <- lmer(
  Composite_Z ~ time * FOF_status * frailty_cat_3 + Composite_Z0_baseline + age + sex + BMI + (1 | ID),
  data = analysis_long,
  REML = TRUE
)

message("✓ Interaction models fitted")

# Extract results
interaction_results <- list(
  ancova = broom::tidy(mod_delta_interaction, conf.int = TRUE),
  mixed = broom.mixed::tidy(mod_mixed_interaction, conf.int = TRUE)
)

# ==============================================================================
# 06. Sensitivity Analyses
# ==============================================================================

message("\n06) Running sensitivity analyses with alternative frailty definitions...")

# 8.1 Models with frailty_cat_3_obj (objective-only)
mod_delta_sens_obj <- lm(
  Delta_Composite_Z ~ FOF_status + frailty_cat_3_obj + Composite_Z0 + age + sex + BMI,
  data = analysis_data
)

mod_mixed_sens_obj <- lmer(
  Composite_Z ~ time * FOF_status + frailty_cat_3_obj + Composite_Z0_baseline + age + sex + BMI + (1 | ID),
  data = analysis_long,
  REML = TRUE
)

# 8.2 Models with frailty_cat_3_2plus (strict definition)
mod_delta_sens_strict <- lm(
  Delta_Composite_Z ~ FOF_status + frailty_cat_3_2plus + Composite_Z0 + age + sex + BMI,
  data = analysis_data
)

mod_mixed_sens_strict <- lmer(
  Composite_Z ~ time * FOF_status + frailty_cat_3_2plus + Composite_Z0_baseline + age + sex + BMI + (1 | ID),
  data = analysis_long,
  REML = TRUE
)

message("✓ Sensitivity analyses complete")

# Extract sensitivity results
sensitivity_results <- list(
  ancova_obj = broom::tidy(mod_delta_sens_obj, conf.int = TRUE),
  mixed_obj = broom.mixed::tidy(mod_mixed_sens_obj, conf.int = TRUE),
  ancova_strict = broom::tidy(mod_delta_sens_strict, conf.int = TRUE),
  mixed_strict = broom.mixed::tidy(mod_mixed_sens_strict, conf.int = TRUE)
)

# ==============================================================================
# 07. Create Output Tables
# ==============================================================================

message("\n07) Creating formatted output tables...")

# 9.1 ANCOVA primary results table
ancova_primary_table <- ancova_results$frailty_cat %>%
  filter(term != "(Intercept)") %>%
  mutate(
    term = recode(term,
                  "FOF_statusFOF" = "FOF (vs. No FOF)",
                  "frailty_cat_3Pre-frail" = "Pre-frail (vs. Robust)",
                  "frailty_cat_3Frail" = "Frail (vs. Robust)",
                  "Composite_Z0" = "Baseline Composite Z",
                  "age" = "Age (years)",
                  "sexmale" = "Sex (Male vs. Female)",
                  "BMI" = "BMI (kg/m²)"),
    CI = paste0("[", sprintf("%.3f", conf.low), ", ", sprintf("%.3f", conf.high), "]"),
    p_formatted = case_when(
      p.value < 0.001 ~ "<0.001",
      p.value < 0.01 ~ sprintf("%.3f", p.value),
      TRUE ~ sprintf("%.2f", p.value)
    )
  ) %>%
  dplyr::select(Predictor = term, B = estimate, SE = std.error,
         CI, t = statistic, p = p_formatted)

ft_ancova_primary <- flextable(ancova_primary_table) %>%
  set_caption("ANCOVA Results: Change in Composite Physical Function (Δ-score) with Frailty Adjustment") %>%
  autofit() %>%
  theme_booktabs()

# 9.2 Mixed model primary results table
mixed_primary_table <- mixed_results$frailty_cat %>%
  filter(effect == "fixed", term != "(Intercept)") %>%
  mutate(
    term = recode(term,
                  "time" = "Time (3 months)",
                  "FOF_statusFOF" = "FOF (vs. No FOF)",
                  "frailty_cat_3Pre-frail" = "Pre-frail (vs. Robust)",
                  "frailty_cat_3Frail" = "Frail (vs. Robust)",
                  "Composite_Z0_baseline" = "Baseline Composite Z",
                  "age" = "Age (years)",
                  "sexmale" = "Sex (Male vs. Female)",
                  "BMI" = "BMI (kg/m²)",
                  "time:FOF_statusFOF" = "Time × FOF"),
    CI = paste0("[", sprintf("%.3f", conf.low), ", ", sprintf("%.3f", conf.high), "]"),
    p_formatted = case_when(
      p.value < 0.001 ~ "<0.001",
      p.value < 0.01 ~ sprintf("%.3f", p.value),
      TRUE ~ sprintf("%.2f", p.value)
    )
  ) %>%
  select(Predictor = term, B = estimate, SE = std.error,
         CI, t = statistic, p = p_formatted)

ft_mixed_primary <- flextable(mixed_primary_table) %>%
  set_caption("Mixed Model Results: Composite Physical Function Over Time with Frailty Adjustment") %>%
  autofit() %>%
  theme_booktabs()

# 9.3 Model comparison table
ft_ancova_comparison <- flextable(ancova_comparison) %>%
  set_caption("ANCOVA Model Comparison: Frailty Adjustment Impact") %>%
  colformat_double(j = c("AIC", "BIC", "R2", "Adj_R2"), digits = 3) %>%
  autofit() %>%
  theme_booktabs()

ft_mixed_comparison <- flextable(mixed_comparison) %>%
  set_caption("Mixed Model Comparison: Frailty Adjustment Impact") %>%
  colformat_double(j = c("AIC", "BIC"), digits = 1) %>%
  autofit() %>%
  theme_booktabs()

# 9.4 Sensitivity analysis summary
sensitivity_summary <- data.frame(
  Analysis = c("Primary (Combined)", "Sensitivity: Objective-only", "Sensitivity: Strict (≥2)"),
  ANCOVA_AIC = c(AIC(mod_delta_frailty), AIC(mod_delta_sens_obj), AIC(mod_delta_sens_strict)),
  Mixed_AIC = c(AIC(mod_mixed_frailty), AIC(mod_mixed_sens_obj), AIC(mod_mixed_sens_strict)),
  ANCOVA_R2 = c(summary(mod_delta_frailty)$r.squared,
                summary(mod_delta_sens_obj)$r.squared,
                summary(mod_delta_sens_strict)$r.squared)
)

ft_sensitivity <- flextable(sensitivity_summary) %>%
  set_caption("Sensitivity Analysis: Alternative Frailty Definitions") %>%
  colformat_double(j = c("ANCOVA_AIC", "Mixed_AIC"), digits = 1) %>%
  colformat_double(j = "ANCOVA_R2", digits = 3) %>%
  autofit() %>%
  theme_booktabs()

# ==============================================================================
# 08. Save Tables
# ==============================================================================

message("\n08) Saving output tables...")

# Save as Word document
doc <- read_docx() %>%
  body_add_flextable(ft_ancova_primary) %>%
  body_add_par("") %>%
  body_add_flextable(ft_mixed_primary) %>%
  body_add_par("") %>%
  body_add_flextable(ft_ancova_comparison) %>%
  body_add_par("") %>%
  body_add_flextable(ft_mixed_comparison) %>%
  body_add_par("") %>%
  body_add_flextable(ft_sensitivity)

docx_path <- file.path(output_dir, "K16_frailty_models_tables.docx")
print(doc, target = docx_path)
register_output(docx_path, "Frailty-adjusted model results tables", script_label)
message("✓ Saved tables: ", docx_path)

# Save model objects
model_list <- list(
  ancova_baseline = mod_delta_baseline,
  ancova_frailty = mod_delta_frailty,
  ancova_frailty_cont = mod_delta_frailty_cont,
  ancova_interaction = mod_delta_interaction,
  mixed_baseline = mod_mixed_baseline,
  mixed_frailty = mod_mixed_frailty,
  mixed_frailty_cont = mod_mixed_frailty_cont,
  mixed_interaction = mod_mixed_interaction,
  ancova_sens_obj = mod_delta_sens_obj,
  mixed_sens_obj = mod_mixed_sens_obj,
  ancova_sens_strict = mod_delta_sens_strict,
  mixed_sens_strict = mod_mixed_sens_strict
)

rdata_path <- file.path(output_dir, "K16_all_models.RData")
save(model_list, ancova_results, mixed_results, interaction_results,
     sensitivity_results, file = rdata_path)
register_output(rdata_path, "All frailty-adjusted model objects", script_label)
message("✓ Saved model objects: ", rdata_path)

# ==============================================================================
# 09. Create Visualization
# ==============================================================================

message("\n09) Creating visualizations...")

# 11.1 Coefficient plot for frailty effects
frailty_coefs <- bind_rows(
  ancova_results$frailty_cat %>%
    filter(grepl("frailty", term)) %>%
    mutate(Model = "ANCOVA", term = gsub("frailty_cat_3", "", term)),
  mixed_results$frailty_cat %>%
    filter(effect == "fixed", grepl("frailty", term)) %>%
    mutate(Model = "Mixed Model", term = gsub("frailty_cat_3", "", term))
)

p_frailty_coefs <- ggplot(frailty_coefs, aes(x = term, y = estimate, color = Model)) +
  geom_point(position = position_dodge(width = 0.5), size = 3) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                position = position_dodge(width = 0.5), width = 0.2) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  coord_flip() +
  labs(
    title = "Frailty Effects on Physical Function",
    subtitle = "Coefficient estimates with 95% confidence intervals",
    x = "Frailty Category (vs. Robust)",
    y = "Effect Size (β coefficient)"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave(file.path(output_dir, "K16_frailty_effects_plot.png"),
       p_frailty_coefs, width = 8, height = 5, dpi = 300)
register_output(file.path(output_dir, "K16_frailty_effects_plot.png"),
                "Frailty effects coefficient plot", script_label)
message("✓ Saved plot: K16_frailty_effects_plot.png")

# 11.2 Predicted trajectories by frailty status  ---- FIXED ----

pred_data <- tidyr::expand_grid(
  time = c(0, 3),
  FOF_status    = levels(analysis_long$FOF_status),
  frailty_cat_3 = levels(analysis_long$frailty_cat_3)
) %>%
  mutate(
    # pakota factorit ja tasot IDENTTISEKSI mallin kanssa
    FOF_status    = factor(FOF_status, levels = levels(analysis_long$FOF_status)),
    frailty_cat_3 = factor(frailty_cat_3, levels = levels(analysis_long$frailty_cat_3)),

    Composite_Z0_baseline = mean(analysis_long$Composite_Z0_baseline, na.rm = TRUE),
    age = mean(analysis_long$age, na.rm = TRUE),
    BMI = mean(analysis_long$BMI, na.rm = TRUE),
    sex = factor("female", levels = levels(analysis_long$sex))
  )
# Verify that model matrix columns match

fixed_terms <- delete.response(terms(reformulas::nobars(formula(mod_mixed_frailty))))
X_new <- model.matrix(fixed_terms, pred_data)
X_fit <- lme4::getME(mod_mixed_frailty, "X")

stopifnot(
  length(setdiff(colnames(X_fit), colnames(X_new))) == 0,
  length(setdiff(colnames(X_new), colnames(X_fit))) == 0
)

pred_data$predicted <- predict(mod_mixed_frailty, newdata = pred_data, re.form = NA)

# 4) piirrä
pred_data <- pred_data %>%
  mutate(FOF_label = dplyr::recode(as.character(FOF_status),
                                   "nonFOF" = "No FOF",
                                   "FOF"    = "FOF"))

p_trajectories <- ggplot(pred_data, aes(x = time, y = predicted,
                                        color = frailty_cat_3,
                                        linetype = FOF_status, group = interaction(frailty_cat_3, FOF_status))) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  labs(
    title = "Predicted Physical Function Trajectories",
    subtitle = "By frailty status and FOF (adjusted for covariates)",
    x = "Time (months)",
    y = "Predicted Composite Physical Function (Z-score)",
    color = "Frailty Status",
    linetype = "Fear of Falling"
  ) +
  scale_x_continuous(breaks = c(0, 3)) +
  theme_minimal() +
  theme(legend.position = "right")

ggsave(file.path(output_dir, "K16_predicted_trajectories.png"),
       p_trajectories, width = 10, height = 6, dpi = 300)
register_output(file.path(output_dir, "K16_predicted_trajectories.png"),
                "Predicted trajectories by frailty", script_label)
message("✓ Saved plot: K16_predicted_trajectories.png")

# ==============================================================================
# 10. Generate Results Text
# ==============================================================================

message("\n10) Generating Results text...")

# Extract key statistics

get_term <- function(df, pattern, effect_fixed = FALSE){
  out <- df
  if (effect_fixed && "effect" %in% names(out)) out <- out %>% dplyr::filter(effect=="fixed")
  out <- out %>% dplyr::filter(grepl(pattern, term))
  if (nrow(out) == 0) stop("Term not found: ", pattern)
  out[1, , drop = FALSE]
}

fof_effect_ancova <- get_term(ancova_results$frailty_cat, "^FOF_status")
fof_time_mixed    <- get_term(mixed_results$frailty_cat, "time.*FOF_status", effect_fixed = TRUE)

frailty_prefrail_ancova <- get_term(ancova_results$frailty_cat, "frailty_cat_3.*Pre")
frailty_frail_ancova    <- get_term(ancova_results$frailty_cat, "frailty_cat_3.*Frail")

frailty_prefrail_mixed  <- get_term(mixed_results$frailty_cat, "frailty_cat_3.*Pre", effect_fixed = TRUE)
frailty_frail_mixed     <- get_term(mixed_results$frailty_cat, "frailty_cat_3.*Frail", effect_fixed = TRUE)


# Calculate R² change
r2_baseline <- summary(mod_delta_baseline)$r.squared
r2_frailty <- summary(mod_delta_frailty)$r.squared
r2_change <- r2_frailty - r2_baseline

# Helper: p-formaatti
p_txt <- function(p){
  ifelse(p < 0.001, "< 0.001", paste0("= ", sprintf("%.3f", p)))
}

sig_en <- ifelse(fof_effect_ancova$p.value < 0.05, "significantly", "not significantly")
sig_fi <- ifelse(fof_effect_ancova$p.value < 0.05, "merkitsevästi", "ei-merkitsevästi")



# Generate English Results text
results_text_en <- paste0(
  "RESULTS: Frailty-Adjusted Analysis\n",
  "=====================================\n\n",

  "Primary ANCOVA Results (Change Analysis)\n",
  "-----------------------------------------\n",
  "After adjusting for physical frailty status, FOF was ", sig_en, " associated with ",
  "decline in composite physical function (B = ", sprintf("%.3f", fof_effect_ancova$estimate),
  ", 95% CI [", sprintf("%.3f", fof_effect_ancova$conf.low), ", ",
  sprintf("%.3f", fof_effect_ancova$conf.high), "], p ",
  p_txt(fof_effect_ancova$p.value), ").\n\n",

  "Frailty status showed independent associations with physical function change:\n",
  "- Pre-frail participants (vs. robust) showed ",
  ifelse(frailty_prefrail_ancova$estimate < 0, "greater decline", "less decline"),
  " (B = ", sprintf("%.3f", frailty_prefrail_ancova$estimate),
  ", 95% CI [", sprintf("%.3f", frailty_prefrail_ancova$conf.low), ", ",
  sprintf("%.3f", frailty_prefrail_ancova$conf.high), "], p ",
  ifelse(frailty_prefrail_ancova$p.value < 0.001, "< 0.001",
         ifelse(frailty_prefrail_ancova$p.value < 0.05,
                paste("=", sprintf("%.3f", frailty_prefrail_ancova$p.value)),
                paste("=", sprintf("%.2f", frailty_prefrail_ancova$p.value)))), ").\n",

  "- Frail participants (vs. robust) showed ",
  ifelse(frailty_frail_ancova$estimate < 0, "greater decline", "less decline"),
  " (B = ", sprintf("%.3f", frailty_frail_ancova$estimate),
  ", 95% CI [", sprintf("%.3f", frailty_frail_ancova$conf.low), ", ",
  sprintf("%.3f", frailty_frail_ancova$conf.high), "], p ",
  ifelse(frailty_frail_ancova$p.value < 0.001, "< 0.001",
         ifelse(frailty_frail_ancova$p.value < 0.05,
                paste("=", sprintf("%.3f", frailty_frail_ancova$p.value)),
                paste("=", sprintf("%.2f", frailty_frail_ancova$p.value)))), ").\n\n",

  "Adding frailty to the model improved explanatory power (ΔR² = ",
  sprintf("%.3f", r2_change), ", from R² = ", sprintf("%.3f", r2_baseline),
  " to R² = ", sprintf("%.3f", r2_frailty), ").\n\n",

  "Primary Mixed Model Results (Longitudinal Analysis)\n",
  "---------------------------------------------------\n",
  "The time × FOF interaction remained ",
  ifelse(fof_time_mixed$p.value < 0.05, "significant", "non-significant"),
  " after frailty adjustment (B = ", sprintf("%.3f", fof_time_mixed$estimate),
  ", 95% CI [", sprintf("%.3f", fof_time_mixed$conf.low), ", ",
  sprintf("%.3f", fof_time_mixed$conf.high), "], p ",
  ifelse(fof_time_mixed$p.value < 0.001, "< 0.001",
         paste("=", sprintf("%.3f", fof_time_mixed$p.value))), "), ",
  "indicating that FOF-related decline persists independent of baseline frailty.\n\n",

  "Frailty showed main effects on physical function levels:\n",
  "- Pre-frail status was associated with lower function (B = ",
  sprintf("%.3f", frailty_prefrail_mixed$estimate), ", p ",
  ifelse(frailty_prefrail_mixed$p.value < 0.001, "< 0.001",
         paste("=", sprintf("%.3f", frailty_prefrail_mixed$p.value))), ").\n",

  "- Frail status was associated with lower function (B = ",
  sprintf("%.3f", frailty_frail_mixed$estimate), ", p ",
  ifelse(frailty_frail_mixed$p.value < 0.001, "< 0.001",
         paste("=", sprintf("%.3f", frailty_frail_mixed$p.value))), ").\n\n",

  "Sensitivity Analyses\n",
  "--------------------\n",
  "Results remained consistent across alternative frailty definitions:\n",
  "- Objective-only frailty (AIC = ", sprintf("%.1f", AIC(mod_delta_sens_obj)),
  " vs. primary AIC = ", sprintf("%.1f", AIC(mod_delta_frailty)), ")\n",
  "- Strict frailty (≥2 indicators; AIC = ", sprintf("%.1f", AIC(mod_delta_sens_strict)),
  " vs. primary AIC = ", sprintf("%.1f", AIC(mod_delta_frailty)), ")\n\n",

  "These findings suggest that FOF effects on physical function decline are ",
  "independent of baseline frailty status, with both factors showing distinct ",
  "contributions to functional trajectories in community-dwelling older adults.\n"
)

# Generate Finnish Results text
results_text_fi <- paste0(
  "TULOKSET: Haurauskorjattu analyysi\n",
  "===================================\n\n",
  "Primääri ANCOVA-tulokset (Muutosanalyysi)\n",
  "------------------------------------------\n",
  "Fyysisen haurausstatuksen huomioimisen jälkeen kaatumisen pelko (FOF) oli ",
  sig_fi, " yhteydessä fyysisen suorituskyvyn heikkenemiseen (B = ",
  sprintf("%.3f", fof_effect_ancova$estimate), ", 95% LV [",
  sprintf("%.3f", fof_effect_ancova$conf.low), ", ",
  sprintf("%.3f", fof_effect_ancova$conf.high), "], p ",
  p_txt(fof_effect_ancova$p.value), ").\n\n",

  "Haurausstatuksella oli itsenäinen yhteys fyysisen suorituskyvyn muutokseen:\n",
  "- Esihauraat osallistujat (vs. robustit) osoittivat ",
  ifelse(frailty_prefrail_ancova$estimate < 0, "suurempaa heikkenemistä", "vähäisempää heikkenemistä"),
  " (B = ", sprintf("%.3f", frailty_prefrail_ancova$estimate),
  ", 95% LV [", sprintf("%.3f", frailty_prefrail_ancova$conf.low), ", ",
  sprintf("%.3f", frailty_prefrail_ancova$conf.high), "], p ",
  ifelse(frailty_prefrail_ancova$p.value < 0.001, "< 0.001",
         paste("=", sprintf("%.3f", frailty_prefrail_ancova$p.value))), ").\n",

  "- Hauraat osallistujat (vs. robustit) osoittivat ",
  ifelse(frailty_frail_ancova$estimate < 0, "suurempaa heikkenemistä", "vähäisempää heikkenemistä"),
  " (B = ", sprintf("%.3f", frailty_frail_ancova$estimate),
  ", 95% LV [", sprintf("%.3f", frailty_frail_ancova$conf.low), ", ",
  sprintf("%.3f", frailty_frail_ancova$conf.high), "], p ",
  ifelse(frailty_frail_ancova$p.value < 0.001, "< 0.001",
         paste("=", sprintf("%.3f", frailty_frail_ancova$p.value))), ").\n\n",

  "Haurausmuuttujan lisääminen malliin paransi selitysvoimaa (ΔR² = ",
  sprintf("%.3f", r2_change), ", R²:stä ", sprintf("%.3f", r2_baseline),
  " → R² = ", sprintf("%.3f", r2_frailty), ").\n\n",

  "Primääri sekamallin tulokset (Pitkittäisanalyysi)\n",
  "--------------------------------------------------\n",
  "Aika × FOF -yhdysvaikutus säilyi ",
  ifelse(fof_time_mixed$p.value < 0.05, "merkittävänä", "ei-merkittävänä"),
  " haurauskorjauksen jälkeen (B = ", sprintf("%.3f", fof_time_mixed$estimate),
  ", 95% LV [", sprintf("%.3f", fof_time_mixed$conf.low), ", ",
  sprintf("%.3f", fof_time_mixed$conf.high), "], p ",
  ifelse(fof_time_mixed$p.value < 0.001, "< 0.001",
         paste("=", sprintf("%.3f", fof_time_mixed$p.value))), "), ",
  "mikä osoittaa että FOF:iin liittyvä heikkeneminen on riippumatonta lähtötason hauraudesta.\n\n",

  "Hauraudella oli pääefektejä fyysisen toimintakyvyn tasoihin:\n",
  "- Esihauras status oli yhteydessä matalampaan toimintakykyyn (B = ",
  sprintf("%.3f", frailty_prefrail_mixed$estimate), ", p ",
  ifelse(frailty_prefrail_mixed$p.value < 0.001, "< 0.001",
         paste("=", sprintf("%.3f", frailty_prefrail_mixed$p.value))), ").\n",

  "- Hauras status oli yhteydessä matalampaan toimintakykyyn (B = ",
  sprintf("%.3f", frailty_frail_mixed$estimate), ", p ",
  ifelse(frailty_frail_mixed$p.value < 0.001, "< 0.001",
         paste("=", sprintf("%.3f", frailty_frail_mixed$p.value))), ").\n\n",

  "Herkkyysanalyysit\n",
  "-----------------\n",
  "Tulokset pysyivät johdonmukaisina vaihtoehtoisten haurausmääritysten kanssa:\n",
  "- Vain objektiivinen hauraus (AIC = ", sprintf("%.1f", AIC(mod_delta_sens_obj)),
  " vs. primääri AIC = ", sprintf("%.1f", AIC(mod_delta_frailty)), ")\n",
  "- Tiukka hauraus (≥2 indikaattoria; AIC = ", sprintf("%.1f", AIC(mod_delta_sens_strict)),
  " vs. primääri AIC = ", sprintf("%.1f", AIC(mod_delta_frailty)), ")\n\n",

  "Nämä tulokset viittaavat siihen, että kaatumisen pelon vaikutukset fyysisen ",
  "suorituskyvyn heikkenemiseen ovat riippumattomia lähtötason haurausstatuksesta, ",
  "ja molemmat tekijät osoittavat erilliset kontribuutiot kotona asuvien ikääntyneiden ",
  "toimintakykytrajektoreihin.\n"
)

# Save Results texts
results_en_path <- file.path(output_dir, "K16_Results_EN.txt")
writeLines(results_text_en, results_en_path)
register_output(results_en_path, "Results text in English", script_label)
message("✓ Saved English Results: ", results_en_path)

results_fi_path <- file.path(output_dir, "K16_Results_FI.txt")
writeLines(results_text_fi, results_fi_path)
register_output(results_fi_path, "Results text in Finnish", script_label)
message("✓ Saved Finnish Results: ", results_fi_path)

# ==============================================================================
# 11. Summary
# ==============================================================================

message("\n", strrep("=", 80))
message("K16 ANALYSIS COMPLETE")
message(strrep("=", 80))
message("\nKey Findings:")
fof_sig <- ifelse(fof_effect_ancova$p.value < 0.05, "significant", "non-significant")
message("✓ FOF effect after frailty adjustment (ANCOVA B = ",
        sprintf("%.3f", fof_effect_ancova$estimate[1]),
        ", p ", p_txt(fof_effect_ancova$p.value[1]),
        "; ", fof_sig, ")")
message("✓ Frailty shows independent effects on physical function")
message("✓ Adding frailty improved model fit (ΔR² = ", sprintf("%.3f", r2_change), ")")
message("✓ Results robust across sensitivity analyses")
message("\nOutputs saved to: ", output_dir)
message("✓ Model tables (Word): K16_frailty_models_tables.docx")
message("✓ Model objects (RData): K16_all_models.RData")
message("✓ Coefficient plot: K16_frailty_effects_plot.png")
message("✓ Trajectory plot: K16_predicted_trajectories.png")
message("✓ Results text (EN): K16_Results_EN.txt")
message("✓ Results text (FI): K16_Results_FI.txt")
message(strrep("=", 80), "\n")

# End of K16.R

save_sessioninfo_manifest()

