## KAAOS 8: R Script for ANCOVA Models of Change in Physical Performance by Fear of Falling Status
## [K8.R]

## ANCOVA models of change in physical performance by FOF status,
## with moderation by baseline balance problems and walking ability.

# Muuttuuko fyysinen toimintakyky eri tavalla FOF-ryhmissä? Ja riippuuko tämä
# tasapaino-ongelmista tai kävelyvaikeuksista?
#
# Vastaus lyhyesti:
#
# ➡️ Ei näyttöä ryhmäeroista. 
# ➡️ Ei näyttöä moderoinnista. 
# ➡️ Trendi: molemmat ryhmät paranevat hieman.
#
# Johtopäätös:
#
# FOF-status ei näytä vaikuttavan fyysisen suorituskyvyn muutoksiin seurannassa,
# eikä tämä vaikutus riipu lähtötason tasapainosta tai 500 m kävelykyvystä.


########################################################################################################

#  Sequence list
########################################################################################################

# 1: Load required packages

library(dplyr)
library(tidyr)
library(ggplot2)
library(broom)
library(car)
library(emmeans)
library(sandwich)
library(lmtest)
library(purrr)
library(stringr)
library(here)

set.seed(1234)  # for any later random procedures (e.g. bootstraps if added)

########################################################################################################
########################################################################################################

# 2: Output-kansio K8:n alle -------------------------------------------

## .../Fear-of-Falling/R-scripts/K8/outputs
outputs_dir <- here::here("R-scripts", "K8", "outputs")
if (!dir.exists(outputs_dir)) {
  dir.create(outputs_dir, recursive = TRUE)
}

## 2.1: --- Skriptin tunniste ---
script_label <- "K8_ANCOVA"   # tai esim. "K8" – voit muuttaa halutuksi

## 2.2 --- Erillinen manifest-kansio projektissa: ./manifest -------------------
# Projektin juurikansio oletetaan olevan .../Fear-of-Falling
manifest_dir <- here::here("manifest")
if (!dir.exists(manifest_dir)) {
  dir.create(manifest_dir, recursive = TRUE)
}
manifest_path <- file.path(manifest_dir, "manifest.csv")



# 3: Data Preparation

## 3.1: Basic existence check
exists("analysis_data")
str(analysis_data, max.level = 1)


## 3.2: Identify age, sex, BMI variable names flexibly
var_age <- dplyr::case_when(
  "Age" %in% names(analysis_data) ~ "Age",
  "age" %in% names(analysis_data) ~ "age",
  TRUE ~ NA_character_
)

var_sex <- dplyr::case_when(
  "Sex" %in% names(analysis_data) ~ "Sex",
  "sex" %in% names(analysis_data) ~ "sex",
  TRUE ~ NA_character_
)

var_BMI <- dplyr::case_when(
  "BMI" %in% names(analysis_data) ~ "BMI",
  TRUE ~ NA_character_
)

if (any(is.na(c(var_age, var_sex, var_BMI)))) {
  stop("Could not find age, sex or BMI variable in analysis_data. Please check variable names.")
}

## 3.3: Create recoded factors without overwriting originals
analysis_data <- analysis_data %>%
  mutate(
    ## FOF_status from kaatumisenpelkoOn: 0 = nonFOF, 1 = FOF
    FOF_status = case_when(
      kaatumisenpelkoOn == 0 ~ "nonFOF",
      kaatumisenpelkoOn == 1 ~ "FOF",
      TRUE ~ NA_character_
    ) %>% factor(levels = c("nonFOF", "FOF")),
    
    ## Balance_problem from tasapainovaikeus: 0 = no, 1 = yes
    Balance_problem = case_when(
      tasapainovaikeus == 0 ~ "no_balance_problem",
      tasapainovaikeus == 1 ~ "balance_problem",
      TRUE ~ NA_character_
    ) %>% factor(levels = c("no_balance_problem", "balance_problem")),
    
    ## Walk500m_3class from Vaikeus500m: 0,1,2 → 3 classes
    Walk500m_3class = case_when(
      Vaikeus500m == 0 ~ "no_difficulty",
      Vaikeus500m == 1 ~ "some_difficulty",
      Vaikeus500m == 2 ~ "unable",
      TRUE ~ NA_character_
    ) %>% factor(levels = c("no_difficulty", "some_difficulty", "unable")),
    
    ## Make covariates clearly typed
    Age = .data[[var_age]],
    Sex = as.factor(.data[[var_sex]]),
    BMI_c = .data[[var_BMI]],  # keep original BMI but also a clearly named numeric
    PainVAS0_c = if ("PainVAS0" %in% names(.)) PainVAS0 else NA_real_
  )

# 4: Quick recoding tables
table(analysis_data$kaatumisenpelkoOn, analysis_data$FOF_status, useNA = "ifany")
table(analysis_data$tasapainovaikeus, analysis_data$Balance_problem, useNA = "ifany")
table(analysis_data$Vaikeus500m, analysis_data$Walk500m_3class, useNA = "ifany")


## Decide how to define DeltaComposite
has_ready_delta <- "Delta_Composite_Z" %in% names(analysis_data)

## Try to determine baseline composite
comp0_candidates <- c("Composite_Z0", "ToimintaKykySummary0")
comp2_candidates <- c("Composite_Z2", "ToimintaKykySummary2")

Composite_Z0_var <- comp0_candidates[comp0_candidates %in% names(analysis_data)][1]
Composite_Z2_var <- comp2_candidates[comp2_candidates %in% names(analysis_data)][1]

if (!has_ready_delta && (is.na(Composite_Z0_var) || is.na(Composite_Z2_var))) {
  stop("Could not find either Delta_Composite_Z or a pair of baseline/follow-up composite variables.")
}

analysis_data <- analysis_data %>%
  mutate(
    Composite0 = if (!is.na(Composite_Z0_var)) .data[[Composite_Z0_var]] else NA_real_,
    Composite2 = if (!is.na(Composite_Z2_var)) .data[[Composite_Z2_var]] else NA_real_,
    DeltaComposite = dplyr::case_when(
      has_ready_delta ~ Delta_Composite_Z,
      TRUE ~ Composite2 - Composite0
    )
  )
summary(analysis_data$DeltaComposite)

## Helper to check variable existence
has_var <- function(v) v %in% names(analysis_data)

analysis_data <- analysis_data %>%
  mutate(
    ## Handgrip strength (HGS): higher = better
    HGS0 = dplyr::case_when(
      has_var("Puristus0") ~ Puristus0,
      TRUE ~ NA_real_
    ),
    HGS2 = dplyr::case_when(
      has_var("Puristus2") ~ Puristus2,
      TRUE ~ NA_real_
    ),
    Delta_HGS = dplyr::case_when(
      has_var("PuristusMuutos") ~ PuristusMuutos,
      !is.na(HGS0) & !is.na(HGS2) ~ HGS2 - HGS0,
      TRUE ~ NA_real_
    ),
    
    ## Maximum walking speed (MWS): higher = better
    MWS0 = dplyr::case_when(
      has_var("kavelynopeus_m_sek0") ~ kavelynopeus_m_sek0,
      TRUE ~ NA_real_
    ),
    MWS2 = dplyr::case_when(
      has_var("kavelynopeus_m_sek2") ~ kavelynopeus_m_sek2,
      TRUE ~ NA_real_
    ),
    Delta_MWS = dplyr::case_when(
      has_var("Kävelymuutos") ~ Kävelymuutos,
      !is.na(MWS0) & !is.na(MWS2) ~ MWS2 - MWS0,
      TRUE ~ NA_real_
    ),
    
    ## Five Times Sit-to-Stand (FTSST): lower time = better; reverse so higher = better
    FTSST0 = dplyr::case_when(
      has_var("Tuoli0") ~ Tuoli0,
      TRUE ~ NA_real_
    ),
    FTSST2 = dplyr::case_when(
      has_var("Tuoli2") ~ Tuoli2,
      TRUE ~ NA_real_
    ),
    Delta_FTSST = dplyr::case_when(
      has_var("Tuolimuutos") ~ -Tuolimuutos,            # if recorded as time change, reverse sign
      !is.na(FTSST0) & !is.na(FTSST2) ~ (FTSST0 - FTSST2),  # improvement = shorter time
      TRUE ~ NA_real_
    ),
    
    ## Single-leg stance (SLS): higher = better
    SLS0 = dplyr::case_when(
      has_var("Seisominen0") ~ Seisominen0,
      TRUE ~ NA_real_
    ),
    SLS2 = dplyr::case_when(
      has_var("Seisominen2") ~ Seisominen2,
      TRUE ~ NA_real_
    ),
    Delta_SLS = dplyr::case_when(
      has_var("TasapainoMuutos") ~ TasapainoMuutos,
      !is.na(SLS0) & !is.na(SLS2) ~ SLS2 - SLS0,
      TRUE ~ NA_real_
    )
  )

## Quick summaries of change scores
analysis_data %>%
  summarise(
    across(
      c(DeltaComposite, Delta_HGS, Delta_MWS, Delta_FTSST, Delta_SLS),
      list(mean = ~mean(., na.rm = TRUE), sd = ~sd(., na.rm = TRUE)),
      .names = "{.col}_{.fn}"
    )
  )


## Baseline descriptives by FOF_status
baseline_vars <- c("Composite0", "HGS0", "MWS0", "FTSST0", "SLS0",
                   "Age", "Sex", "BMI_c", "PainVAS0_c")

## Continuous vars
analysis_data %>%
  group_by(FOF_status) %>%
  summarise(
    n = n(),
    across(
      c(Composite0, HGS0, MWS0, FTSST0, SLS0, Age, BMI_c, PainVAS0_c),
      list(mean = ~mean(., na.rm = TRUE), sd = ~sd(., na.rm = TRUE)),
      .names = "{.col}_{.fn}"
    ),
    .groups = "drop"
  )

## Categorical baseline balance and walking ability
table(analysis_data$FOF_status, analysis_data$Balance_problem, useNA = "ifany")
table(analysis_data$FOF_status, analysis_data$Walk500m_3class, useNA = "ifany")

## Outcome changes by FOF_status
analysis_data %>%
  group_by(FOF_status) %>%
  summarise(
    n = n(),
    across(
      c(DeltaComposite, Delta_HGS, Delta_MWS, Delta_FTSST, Delta_SLS),
      list(mean = ~mean(., na.rm = TRUE), sd = ~sd(., na.rm = TRUE)),
      .names = "{.col}_{.fn}"
    ),
    .groups = "drop"
  )

ggplot(analysis_data, aes(x = FOF_status, y = DeltaComposite)) +
  geom_boxplot() +
  labs(
    title = "Change in composite performance (DeltaComposite) by FOF status",
    x = "FOF status",
    y = "DeltaComposite (positive = improvement)"
  )

## Cell counts for FOF_status x Balance_problem
cell_counts_balance <- table(analysis_data$FOF_status, analysis_data$Balance_problem)
cell_counts_balance

if (any(cell_counts_balance < 30, na.rm = TRUE)) {
  warning("Some FOF_status x Balance_problem cells have n < 30. Interpret subgroup results with caution.")
}

## Initial 3-class cell counts
cell_counts_walk3 <- table(analysis_data$FOF_status, analysis_data$Walk500m_3class)
cell_counts_walk3

## Default merging rule:
## - Merge some_difficulty + unable -> difficulty_or_unable
analysis_data <- analysis_data %>%
  mutate(
    Walk500m_G_final = case_when(
      Walk500m_3class %in% c("some_difficulty", "unable") ~ "difficulty_or_unable",
      Walk500m_3class == "no_difficulty" ~ "no_difficulty",
      TRUE ~ NA_character_
    ) %>% factor(levels = c("no_difficulty", "difficulty_or_unable"))
  )

cell_counts_walk_final <- table(analysis_data$FOF_status, analysis_data$Walk500m_G_final)
cell_counts_walk_final

if (any(cell_counts_walk_final < 30, na.rm = TRUE)) {
  warning("Some FOF_status x Walk500m_G_final cells still have n < 30. Consider alternative merges or cautious interpretation.")
}


walk_cell_tables <- list(
  initial_3_class = as.data.frame(cell_counts_walk3),
  final_2_class   = as.data.frame(cell_counts_walk_final)
)

fit_ancova_moderation <- function(data, outcome, baseline, G_var) {
  ## data: data.frame
  ## outcome: name of Delta outcome (character)
  ## baseline: name of baseline measure for same test
  ## G_var: moderator variable name ("Balance_problem" or "Walk500m_G_final")
  
  needed <- c("FOF_status", G_var, baseline, outcome, "Age", "Sex", "BMI_c")
  dat_model <- data %>%
    dplyr::select(dplyr::all_of(needed)) %>%
    tidyr::drop_na()
  
  if (nrow(dat_model) == 0) {
    stop(paste("No complete cases for outcome", outcome, "and moderator", G_var))
  }
  
  formula_str <- paste0(
    outcome, " ~ FOF_status * ", G_var, " + ", baseline,
    " + Age + Sex + BMI_c"
  )
  model_formula <- as.formula(formula_str)
  
  m <- lm(model_formula, data = dat_model)
  
  ## Type III tests
  anova_tab <- car::Anova(m, type = "III") %>% broom::tidy()
  
  ## EMMs: FOF_status within each level of G_var
  emm <- emmeans::emmeans(m, specs = "FOF_status", by = G_var)
  
  ## NonFOF minus FOF within each G
  contrast_list <- list(nonFOF_minus_FOF = c(1, -1))
  emm_contr <- emmeans::contrast(emm, method = contrast_list) %>%
    broom::tidy(conf.int = TRUE)  ## (LV:t myös kontrasteihin, jos haluat)
  
  ## LS-meanit + 95 % CI:t
  emm_tab <- broom::tidy(emm, conf.int = TRUE)  # HUOM: conf.int = TRUE lisätty
  
  ## Robust SEs (HC3)
  vcov_hc3 <- sandwich::vcovHC(m, type = "HC3")
  coef_robust <- lmtest::coeftest(m, vcov. = vcov_hc3)
  robust_tab <- broom::tidy(coef_robust)
  
  list(
    model = m,
    anova_type3 = anova_tab,
    emm = emm_tab,
    contrasts_within_G = emm_contr,
    robustHC3 = robust_tab,
    data_used = dat_model
  )
}



## Map each Delta outcome to its baseline variable
baseline_map <- list(
  DeltaComposite = "Composite0",
  Delta_HGS      = "HGS0",
  Delta_MWS      = "MWS0",
  Delta_FTSST    = "FTSST0",
  Delta_SLS      = "SLS0"
)

## Restrict to outcomes that actually exist with some non-missing data
available_outcomes <- names(baseline_map)[
  names(baseline_map) %in% names(analysis_data) &
    sapply(names(baseline_map), function(o) sum(!is.na(analysis_data[[o]])) > 0)
]

available_outcomes

## Moderators G
G_vars <- c("Balance_problem", "Walk500m_G_final")

ancova_results <- list()

for (G in G_vars) {
  for (out in available_outcomes) {
    bl <- baseline_map[[out]]
    res_name <- paste(out, G, sep = "__")
    ancova_results[[res_name]] <- fit_ancova_moderation(
      data = analysis_data,
      outcome = out,
      baseline = bl,
      G_var = G
    )
  }
}


## Interaction terms table (FOF_status x G for each model)
interaction_summary <- purrr::imap_dfr(
  ancova_results,
  ~ .x$anova_type3 %>%
    filter(str_detect(term, "FOF_status:")) %>%
    mutate(model_id = .y),
  .id = "model_id"
)

interaction_summary


## Within-G contrasts: nonFOF - FOF for each level of G
contrast_summary <- purrr::imap_dfr(
  ancova_results,
  ~ .x$contrasts_within_G %>%
    mutate(model_id = .y),
  .id = "model_id"
)

contrast_summary

make_emm_plot <- function(res_list, outcome_label, G_label) {
  emm_df <- res_list$emm
  
  ## 1) Etsi keskiarvosarake (emmean / estimate)
  mean_col <- dplyr::case_when(
    "emmean"   %in% names(emm_df) ~ "emmean",
    "estimate" %in% names(emm_df) ~ "estimate",
    TRUE ~ NA_character_
  )
  if (is.na(mean_col)) {
    stop("En löytänyt emmean/estimate-saraketta emmeans-taulukosta.")
  }
  
  ## 2) Etsi luottamusväli-sarakkeet (conf.low/conf.high tai lower.CL/upper.CL)
  lower_col <- dplyr::case_when(
    "conf.low"  %in% names(emm_df) ~ "conf.low",
    "lower.CL"  %in% names(emm_df) ~ "lower.CL",
    TRUE ~ NA_character_
  )
  upper_col <- dplyr::case_when(
    "conf.high" %in% names(emm_df) ~ "conf.high",
    "upper.CL"  %in% names(emm_df) ~ "upper.CL",
    TRUE ~ NA_character_
  )
  
  if (is.na(lower_col) || is.na(upper_col)) {
    stop("En löytänyt luottamusväli-sarakkeita (conf.low/conf.high tai lower.CL/upper.CL).")
  }
  
  ## 3) Tunnista moderaattorimuuttuja (G) = ainoa ei-FOF-status selittäjä
  mod_col_candidates <- setdiff(
    names(emm_df),
    c("FOF_status", mean_col, lower_col, upper_col,
      "std.error", "SE", "df", "t.ratio", "p.value")
  )
  
  if (length(mod_col_candidates) == 0) {
    stop("En löytänyt moderaattorimuuttujaa (G) emmeans-taulukosta.")
  }
  ## Jos jostain syystä löytyy useampi, otetaan ensimmäinen
  mod_col <- mod_col_candidates[1]
  
  ## 4) Piirretään kuva
  ggplot(emm_df,
         aes_string(x = mod_col,
                    y = mean_col,
                    color = "FOF_status",
                    group = "FOF_status")) +
    geom_point(position = position_dodge(width = 0.2)) +
    geom_errorbar(
      aes_string(ymin = lower_col, ymax = upper_col),
      width = 0.1,
      position = position_dodge(width = 0.2)
    ) +
    labs(
      title = paste0("Adjusted change in ", outcome_label,
                     " by FOF_status and ", G_label),
      x = G_label,
      y = paste0("Adjusted ", outcome_label,
                 " (Delta; positive = improvement)"),
      color = "FOF status"
    ) +
    theme_minimal()
}


## Example: Composite outcome for Balance_problem
plot_DeltaComposite_Balance <- make_emm_plot(
  ancova_results[["DeltaComposite__Balance_problem"]],
  outcome_label = "composite performance",
  G_label = "balance problems"
)

## Example: Composite outcome for Walk500m_G_final
plot_DeltaComposite_Walk500 <- make_emm_plot(
  ancova_results[["DeltaComposite__Walk500m_G_final"]],
  outcome_label = "composite performance",
  G_label = "500 m walking ability"
)

## print and save:
print(plot_DeltaComposite_Balance)
print(plot_DeltaComposite_Walk500)

ggsave(
  filename = file.path(outputs_dir, "plot_DeltaComposite_Balance.png"),
  plot     = plot_DeltaComposite_Balance,
  width = 7, height = 5, dpi = 300
)


ggsave(
  filename = file.path(outputs_dir, "plot_DeltaComposite_Walk500.png"),
  plot     = plot_DeltaComposite_Walk500,
  width = 7, height = 5, dpi = 300
)

## Residual diagnostics: DeltaComposite ~ FOF_status * Balance_problem
m_comp_balance <- ancova_results[["DeltaComposite__Balance_problem"]]$model
par(mfrow = c(2, 2))
plot(m_comp_balance)

## Residual diagnostics: DeltaComposite ~ FOF_status * Walk500m_G_final
m_comp_walk <- ancova_results[["DeltaComposite__Walk500m_G_final"]]$model
par(mfrow = c(2, 2))
plot(m_comp_walk)
par(mfrow = c(1, 1))

## Interaction and contrast tables for export
write.csv(
  interaction_summary,
  file.path(outputs_dir, "interaction_summary_FOFxG_ANCOVA.csv"),
  row.names = FALSE
)

write.csv(
  contrast_summary,
  file.path(outputs_dir, "contrast_summary_withinG_nonFOF_minus_FOF.csv"),
  row.names = FALSE
)

## Cell count tables
write.csv(
  walk_cell_tables$initial_3_class,
  file.path(outputs_dir, "cell_counts_FOF_by_Walk500m_3class.csv"),
  row.names = FALSE
)

write.csv(
  walk_cell_tables$final_2_class,
  file.path(outputs_dir, "cell_counts_FOF_by_Walk500m_G_final.csv"),
  row.names = FALSE
)

## Save example plots

ggsave(
  filename = file.path(outputs_dir, "plot_DeltaComposite_Balance.png"),
  plot     = plot_DeltaComposite_Balance,
  width = 7, height = 5, dpi = 300
)

ggsave(
  filename = file.path(outputs_dir, "plot_DeltaComposite_Walk500.png"),
  plot     = plot_DeltaComposite_Walk500,
  width = 7, height = 5, dpi = 300
)
################################################################################
################################################################################

################################################################################
## 13. Manifestin päivitys: keskeiset taulukot ja kuvat
################################################################################

# --- K8-skriptin tuottamat päätiedostot --------------------------------------

manifest_rows <- dplyr::tibble(
  script = script_label,
  
  type = c(
    "table",  # interaction_summary_FOFxG_ANCOVA.csv
    "table",  # contrast_summary_withinG_nonFOF_minus_FOF.csv
    "table",  # cell_counts_FOF_by_Walk500m_3class.csv
    "table",  # cell_counts_FOF_by_Walk500m_G_final.csv
    "plot",   # plot_DeltaComposite_Balance.png
    "plot"    # plot_DeltaComposite_Walk500.png
  ),
  
  filename = c(
    file.path(script_label, "interaction_summary_FOFxG_ANCOVA.csv"),
    file.path(script_label, "contrast_summary_withinG_nonFOF_minus_FOF.csv"),
    file.path(script_label, "cell_counts_FOF_by_Walk500m_3class.csv"),
    file.path(script_label, "cell_counts_FOF_by_Walk500m_G_final.csv"),
    file.path(script_label, "plot_DeltaComposite_Balance.png"),
    file.path(script_label, "plot_DeltaComposite_Walk500.png")
  ),
  
  description = c(
    "FOF × moderaattori (Balance_problem / Walk500m_G_final) — interaktiotermit, Type III ANOVA",
    "NonFOF – FOF LS-mean -kontrastit kunkin moderaattoritason sisällä (emmeans)",
    "FOF × Walk500m alkuperäinen 3-luokkainen ristiintaulukko",
    "FOF × Walk500m yhdistetty 2-luokkainen ristiintaulukko",
    "Adjusted ΔComposite – EMM-kuva moderaattorina balance problems",
    "Adjusted ΔComposite – EMM-kuva moderaattorina walking 500 m ability"
  )
)

# --- Kirjoitetaan tai appendataan manifest.csv --------------------------------

if (!file.exists(manifest_path)) {
  # Luodaan uusi manifest tiedosto
  write.csv(manifest_rows, manifest_path, row.names = FALSE)
  message("Manifest created: ", manifest_path)
} else {
  # Lisätään perään ilman otsikkoriviä
  write.table(
    manifest_rows,
    manifest_path,
    append = TRUE,
    sep = ",",
    col.names = FALSE,
    row.names = FALSE
  )
  message("Manifest updated: appended ", nrow(manifest_rows),
          " rows to ", manifest_path)
}


# End of K8.R