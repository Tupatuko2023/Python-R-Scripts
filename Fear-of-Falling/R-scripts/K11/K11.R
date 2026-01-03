#!/usr/bin/env Rscript
# ==============================================================================
# K11 - FOF as independent predictor of 12-month functional change
# File tag: K11.R
# Purpose: Analyzes fear of falling (FOF) as independent predictor of 12-month
#          change in composite physical function, with comprehensive covariate
#          adjustment, missing data analysis (MICE), and distributional sensitivity
#
# Outcome: Delta_Composite_Z (12-month change in composite physical function)
# Predictors: FOF_status (0 = Ei FOF, 1 = FOF)
# Moderator/interaction: None (main effects + subgroup analyses by age quartiles)
# Grouping variable: None (wide format ANCOVA)
# Covariates: Age, Sex, BMI, MOI_score, diabetes, alzheimer, parkinson, AVH,
#             previous_falls, psych_score
#
# Required vars (raw_data - DO NOT INVENT; must match req_raw_cols check):
# id, age, sex, BMI, kaatumisenpelkoOn, ToimintaKykySummary0, ToimintaKykySummary2,
# MOIindeksiindeksi, diabetes, alzheimer, parkinson, AVH, kaatuminen, mieliala
#
# Required vars (analysis df - after standardize_analysis_vars):
# id, Age, Sex, BMI, FOF_status, Composite_Z0, Composite_Z2, Delta_Composite_Z,
# MOIindeksiindeksi, diabetes, alzheimer, parkinson, AVH, kaatuminen, mieliala
#
# Mapping (raw -> analysis; keep minimal + explicit):
# kaatumisenpelkoOn (0/1) -> FOF_status -> FOF_status_f (factor: "Ei FOF"/"FOF")
# age -> Age
# sex (0/1) -> Sex -> Sex_f (factor: "female"/"male")
# ToimintaKykySummary0 -> Composite_Z0
# ToimintaKykySummary2 -> Composite_Z2
# Composite_Z2 - Composite_Z0 -> Delta_Composite_Z
# MOIindeksiindeksi -> MOI_score (in dat_fof)
# kaatuminen -> previous_falls (in dat_fof)
# mieliala -> psych_score (in dat_fof)
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: 20251124 (set immediately before MICE; also passed to mice::mice())
#
# Outputs + manifest:
# - script_label: K11 (canonical)
# - outputs dir: R-scripts/K11/outputs/K11/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load raw data (immutable; no edits)
# 03) Check required raw columns (req_raw_cols)
# 04) Standardize vars + QC (standardize_analysis_vars + sanity_checks)
# 05) Check required analysis columns (req_analysis_cols)
# 06) Prepare analysis dataset (dat_fof with complete-case filtering)
# 07) Fit primary ANCOVA models (base + extended with clinical covariates)
# 08) Sensitivity: MICE imputation (20 datasets, pooled results)
# 09) Sensitivity: responder analysis (logistic regression, ordinal models)
# 10) Subgroup analysis by age quartiles (responder proportions, emmeans)
# 11) Distributional analysis (GLS heteroscedasticity, quantile regression)
# 12) Save artifacts -> outputs/K11/
# 13) Append manifest row per artifact
# 14) Save sessionInfo to manifest/
# 15) EOF marker
# ==============================================================================
#
suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(broom)
  library(mice)
  library(MASS)
  library(nlme)
  library(quantreg)
  library(emmeans)
  library(car)
  library(scales)
  library(tibble)
  library(lmtest)
  library(effectsize)
})

# --- Standard init (MANDATORY) -----------------------------------------------
# Derive script_label from --file, supporting file tags like: K11.V1_name.R
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K11"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)  # canonical SCRIPT_ID
if (is.na(script_label) || script_label == "") script_label <- "K11"

# Source helper functions (io, checks, modeling, reporting)
rm(list = ls(pattern = "^(save_|init_paths$|append_manifest$|manifest_row$)"),
   envir = .GlobalEnv)

source(here("R","functions","io.R"))
source(here("R","functions","checks.R"))
source(here("R","functions","modeling.R"))
source(here("R","functions","reporting.R"))

if (!exists("save_table_csv_html", envir = .GlobalEnv)) {
  stop("save_table_csv_html NOT loaded. Check: R/functions/reporting.R contains the function and source() points to correct file.")
}

# init_paths() must set outputs_dir + manifest_path (+ options fof.*)
paths <- init_paths(script_label)
outputs_dir   <- paths$outputs_dir
manifest_path <- paths$manifest_path

# seed (set ONLY immediately before MICE, not here - see section 06)

# ==============================================================================
# 02. Load Dataset & Data Checking
# ==============================================================================

file_path <- here::here("data", "external", "KaatumisenPelko.csv")
raw_data <- readr::read_csv(file_path, show_col_types = FALSE)

## Working copy so the original stays untouched
if (!exists("raw_data")) {
  stop("Object 'raw_data' not found. Please load your data as raw_data first.")
}

# --- Required raw columns check (DO NOT INVENT) ------------------------------
req_raw_cols <- c(
  "id", "age", "sex", "BMI", "kaatumisenpelkoOn",
  "ToimintaKykySummary0", "ToimintaKykySummary2",
  "MOIindeksiindeksi", "diabetes", "alzheimer", "parkinson",
  "AVH", "kaatuminen", "mieliala"
)
missing_raw_cols <- setdiff(req_raw_cols, names(raw_data))
if (length(missing_raw_cols) > 0) {
  stop("Missing required raw columns: ", paste(missing_raw_cols, collapse = ", "))
}

# --- Standardize variable names and run sanity checks -----------------------
df <- standardize_analysis_vars(raw_data)
qc <- sanity_checks(df)
print(qc)

# --- Required analysis columns check -----------------------------------------
req_analysis_cols <- c(
  "id", "Age", "Sex", "BMI", "FOF_status",
  "Composite_Z0", "Composite_Z2", "Delta_Composite_Z",
  "MOIindeksiindeksi", "diabetes", "alzheimer", "parkinson",
  "AVH", "kaatuminen", "mieliala"
)
missing_analysis_cols <- setdiff(req_analysis_cols, names(df))
if (length(missing_analysis_cols) > 0) {
  stop("Missing required analysis columns: ", paste(missing_analysis_cols, collapse = ", "))
}

# DATA CHECKING (kevyt)
print(qc)
glimpse(df)


DEBUG <- FALSE
if (DEBUG) {
  glimpse(raw_data)
  raw_data %>% dplyr::select(
    Age, sex, BMI, MOIindeksiindeksi, diabetes,
    kaatumisenpelkoOn,
    alzheimer, parkinson, AVH,
    ToimintaKykySummary0, ToimintaKykySummary2
  ) %>% glimpse()
}

# --- Analysis dataset for modeling (one place, one truth) ----

# Poimi lis??kovariaatit raakadatan nimill?? ja liit?? df:????n id:n mukaan

dat_fof <- df %>%
  mutate(
    MOI_score      = as.numeric(MOIindeksiindeksi),
    psych_score    = as.numeric(mieliala),
    previous_falls = as.numeric(kaatuminen),
    
    Sex_f = factor(Sex, levels = c(0, 1), labels = c("Level 0", "Level 1")),
    
    AgeClass = case_when(
      Age < 75 ~ "65_74",
      Age >= 75 & Age <= 84 ~ "75_84",
      Age >= 85 ~ "85plus",
      TRUE ~ NA_character_
    ),
    AgeClass = factor(AgeClass, levels = c("65_74","75_84","85plus"), ordered = TRUE),
    
    Neuro_any_num = if_else((alzheimer == 1 | parkinson == 1 | AVH == 1),
                            1L, 0L, missing = 0L),
    Neuro_any = factor(Neuro_any_num, levels = c(0,1), labels = c("no_neuro","neuro"))
  ) %>%
  filter(
    !is.na(Composite_Z0), !is.na(Composite_Z2), !is.na(Delta_Composite_Z),
    !is.na(FOF_status), !is.na(Age), !is.na(Sex), !is.na(BMI)
  )

dat_fof <- dat_fof %>%
  mutate(
    Sex_f = factor(Sex, levels = c(0,1), labels = c("Level 0", "Level 1")),
    FOF_status_f = factor(FOF_status, levels = c(0,1), labels = c("Ei FOF","FOF"))
  )

glimpse(dat_fof)


# ==============================================================================
# 03. Prepare Analysis Dataset
# ==============================================================================

# 3.1 Outcome variables: Composite change

# Tarkistetaan ensin, mit?? sarakkeita on
has_DeltaComposite    <- "DeltaComposite" %in% names(dat_fof)
has_DeltaComposite_Z  <- "Delta_Composite_Z" %in% names(dat_fof)

if (has_DeltaComposite) {
  # K??yt?? valmista saraketta sellaisenaan
  message("Using existing DeltaComposite column.")
  
} else if (has_DeltaComposite_Z) {
  # Luo DeltaComposite t??st??
  dat_fof <- dat_fof %>%
    mutate(DeltaComposite = Delta_Composite_Z)
  message("Created DeltaComposite from Delta_Composite_Z.")
  
} else {
  # Laske muutos suoraan
  dat_fof <- dat_fof %>%
    mutate(DeltaComposite = ToimintaKykySummary2 - ToimintaKykySummary0)
  message("Created DeltaComposite as ToimintaKykySummary2 - ToimintaKykySummary0.")
}


# 3.2 PBT changes (HGS, MWS, FTSST, SLS)

dat_fof <- dat_fof %>%
  mutate(
    # HGS: positiivinen = parannus
    Delta_HGS = if_else(
      !is.na(Puristus0) & !is.na(Puristus2),
      Puristus2 - Puristus0,
      NA_real_
    ),

    # MWS: positiivinen = parannus
    Delta_MWS = if_else(
      !is.na(kavelynopeus_m_sek0) & !is.na(kavelynopeus_m_sek2),
      kavelynopeus_m_sek2 - kavelynopeus_m_sek0,
      NA_real_
    ),

    # FTSST (Tuoli): pienempi aika = parempi -> muutoksen merkki k????nnet????n
    Delta_FTSST = if_else(
      !is.na(Tuoli0) & !is.na(Tuoli2),
      Tuoli0 - Tuoli2,  # positiivinen = nopeampi testi
      NA_real_
    ),

    # SLS (Seisominen): suurempi aika = parempi
    Delta_SLS = if_else(
      !is.na(Seisominen0) & !is.na(Seisominen2),
      Seisominen2 - Seisominen0,
      NA_real_
    )
  )


# 3.3 Complete-case analysis dataset

dat_fof <- df %>%
  dplyr::transmute(
    id,
    Composite_Z0,
    Composite_Z2,
    Delta_Composite_Z,
    Age,
    BMI,
    Sex_f = factor(Sex, levels = c(0,1), labels = c("Level 0", "Level 1")),
    FOF_status_f = factor(FOF_status, levels = c(0,1), labels = c("Ei FOF","FOF")),
    diabetes = diabetes,
    alzheimer = alzheimer,
    parkinson = parkinson,
    AVH = AVH,
    previous_falls = kaatuminen,
    psych_score = mieliala,
    MOI_score = MOIindeksiindeksi
  ) %>%
  dplyr::filter(
    !is.na(Composite_Z0),
    !is.na(Composite_Z2),
    !is.na(Age),
    !is.na(BMI),
    !is.na(Sex_f),
    !is.na(FOF_status_f)
  )

dat_fof <- dat_fof %>%
  mutate(
    AgeClass = case_when(
      Age < 75 ~ "65_74",
      Age >= 75 & Age <= 84 ~ "75_84",
      Age >= 85 ~ "85plus",
      TRUE ~ NA_character_
    ),
    AgeClass = factor(AgeClass, levels = c("65_74","75_84","85plus"), ordered = TRUE)
  )

str(dat_fof)


# ==============================================================================
# 04. Primary ANCOVA Models
# ==============================================================================

# 4.1 Base model: FOF + baseline composite + age + BMI + sex

m1 <- fit_primary_ancova(dat_fof)

tab_m1 <- tidy_lm_ci(m1)
tab_m1_p <- tidy_lm_p(m1)

print(tab_m1)

# --- save outputs (NOW tab_m1 exists) ---
csv_path  <- file.path(outputs_dir, "fit_primary_ancova.csv")
csv_p_path <- file.path(outputs_dir, "fit_primary_ancova_pvalues.csv")

save_table_csv(tab_m1,   csv_path)
save_table_csv(tab_m1_p, csv_p_path)

append_manifest(
  manifest_row(script = "K11", label = "fit_primary_ancova",
               path = csv_path, kind = "table_csv", n = nrow(dat_fof)),
  manifest_path
)
append_manifest(
  manifest_row(script = "K11", label = "fit_primary_ancova_pvalues",
               path = csv_p_path, kind = "table_csv", n = nrow(dat_fof)),
  manifest_path
)


# FOF-efekti talteen

mod_base <- lm(
  Delta_Composite_Z ~ FOF_status_f + Composite_Z0 + Age + Sex_f + BMI,
  data = dat_fof
)

summary(mod_base)

tab_base <- broom::tidy(mod_base, conf.int = TRUE)
fof_base <- tab_base %>% 
  dplyr::filter(grepl("^FOF_status", term))


# 4.2 Extended model: adding clinical covariates

mod_ext <- lm(
  Delta_Composite_Z ~ FOF_status_f + Composite_Z0 + Age + Sex_f + BMI +
    MOI_score + diabetes + alzheimer + parkinson + AVH + previous_falls + psych_score,
  data = dat_fof
)


summary(mod_ext)
tab_ext <- broom::tidy(mod_ext, conf.int = TRUE)
fof_ext <- tab_ext %>% 
  dplyr::filter(grepl("^FOF_status", term))


fof_comp <- fof_base %>%
  mutate(model = "base") %>%
  bind_rows(fof_ext %>% mutate(model = "extended")) %>%
  dplyr::select(model, term, estimate, conf.low, conf.high, p.value)

fof_comp

# ==============================================================================
# 05. Model Comparison
# ==============================================================================


tab_base <- tidy(mod_base, conf.int = TRUE)
tab_ext  <- tidy(mod_ext,  conf.int = TRUE)

# FOF-kertoimet ja LV:t rinnakkain
fof_base <- dplyr::filter(tab_base, term == "FOF_status_fFOF")
fof_ext  <- dplyr::filter(tab_ext,  term == "FOF_status_fFOF")

fof_base
fof_ext


standardize_parameters(mod_ext)


# ==============================================================================
# 06. Missing Data Analysis (MICE)
# ==============================================================================

# Set seed for reproducibility (MICE uses random imputation)
set.seed(20251124)

dat_fof <- dat_fof %>%
  mutate(
    FOF_status = as.integer(FOF_status_f == "FOF"),
    sex        = as.integer(Sex_f == "Level 1")
  )

# Valitse MICE-imputointiin mukaan otettavat muuttujat
required_columns <- c(
  "Delta_Composite_Z",
  "FOF_status",
  "Composite_Z0",
  "Age",
  "BMI",
  "sex",
  "MOI_score",
  "diabetes",
  "alzheimer",
  "parkinson",
  "AVH",
  "previous_falls",
  "psych_score"
)

missing_cols <- setdiff(required_columns, names(dat_fof))
if (length(missing_cols) > 0) {
  stop("dat_fof missing columns: ", paste(missing_cols, collapse = ", "))
}

mice_data <- dat_fof %>% dplyr::select(all_of(required_columns))


# Puuttuvuuskuvio
md_pattern <- mice::md.pattern(mice_data, plot = FALSE)

md_pattern_df <- as.data.frame(md_pattern)
save_table_csv_html(md_pattern_df, "missing_data_pattern",
                    outputs_dir = outputs_dir,
                    manifest_path = manifest_path,
                    script = "K11",
                    n = nrow(dat_fof))


# Alkuasetukset: predictorMatrix
ini  <- mice::mice(mice_data, m = 1, maxit = 0, printFlag = FALSE)
pred <- ini$predictorMatrix

# Ei imputoida lopputulosta (Delta_Composite_Z)
pred["Delta_Composite_Z", ] <- 0

# Varsinainen imputointi, esim. 20 imputoitua datasetti??
imp <- mice::mice(
  mice_data,
  m = 20,
  predictorMatrix = pred,
  seed = 20251124,
  printFlag = FALSE
)

# Perusmalli imputoidussa datassa
fit_base <- with(imp, lm(Delta_Composite_Z ~ FOF_status + Composite_Z0 + Age + BMI + sex))
pool(fit_base)

# Laajennettu malli imputoidussa datassa
fit_ext <- with(imp, lm(
  Delta_Composite_Z ~ FOF_status + Composite_Z0 + Age + BMI + sex +
    MOI_score + diabetes + alzheimer + parkinson + AVH +
    previous_falls + psych_score
))
pool(fit_ext)


# Poolatut mallit talteen olioihin
pool_base_imp <- pool(fit_base)
pool_ext_imp  <- pool(fit_ext)


# Muutetaan summary-data.frameiksi
tab_base_imp <- as.data.frame(summary(pool_base_imp, conf.int = TRUE))
tab_ext_imp  <- as.data.frame(summary(pool_ext_imp,  conf.int = TRUE))

find("save_table_csv_html")
args(save_table_csv_html)
getAnywhere("save_table_csv_html")
environmentName(environment(save_table_csv_html))

# Tallennus CSV + HTML
save_table_csv_html(tab_base_imp, "mice_pooled_model_base")
save_table_csv_html(tab_ext_imp,  "mice_pooled_model_extended")

# FOF-kertoimet ja LV:t rinnakkain
tab_base_imp %>% dplyr::filter(term == "FOF_status_fFOF")
tab_ext_imp  %>% dplyr::filter(term == "FOF_status_fFOF")

# ==============================================================================
# 07. Responder & Ordinal Analysis
# ==============================================================================

# 7.1 Responder analysis (logistic regression)

## Muodostetaan responder-muuttuja (kynnys valittavissa, esim. 0.3 SD):
delta_cut <- 0.3  # valitse kliinisesti perusteltu raja
dat_fof$responder <- ifelse(dat_fof$Delta_Composite_Z >= delta_cut, 1, 0)
dat_fof$responder <- factor(dat_fof$responder, levels = c(0, 1))  # 0 = ei-responder, 1 = responder

# Logistinen regressio:
mod_resp <- glm(
  responder ~ FOF_status + Composite_Z0 + Age + BMI + sex,
  data   = dat_fof,
  family = binomial(link = "logit")
)

summary(mod_resp)

tab_resp <- tidy(mod_resp, conf.int = TRUE, exponentiate = TRUE)
tab_resp  # nyt kertoimet ovat OR-arvoja

# 7.2 Ordinal analysis (declined - stable - improved)

## A) Muodosta kolmeportainen muutosluokka:

dat_fof$change_cat <- cut(
  dat_fof$Delta_Composite_Z,
  breaks = c(-Inf, -0.2, 0.2, Inf),
  labels = c("heikentynyt", "stabiili", "parantunut")
)

dat_fof$change_cat <- relevel(dat_fof$change_cat, ref = "stabiili")
table(dat_fof$change_cat, dat_fof$FOF_status)

## B) Ordinaalinen logistinen malli (esim. MASS::polr):

mod_ord <- polr(
  change_cat ~ FOF_status + Composite_Z0 + Age + BMI + sex,
  data = dat_fof,
  Hess = TRUE
)

summary(mod_ord)

# Kertoimet ja luottamusv??lit OR-muodossa
(ctab <- coef(summary(mod_ord)))

ci <- confint(mod_ord)  # luottamusv??lit log-asteikolla
OR  <- exp(cbind(Estimate = coef(mod_ord), ci))
OR  # hae t??st?? FOF-rivi

# ==============================================================================
# 08. Subgroup Analysis by Age Quartiles
# ==============================================================================

# 8.1 Create age quartiles
dat_fof <- dat_fof %>%
  mutate(
    Age_quartile = dplyr::ntile(Age, 4),           # arvot 1,2,3,4
    Age_quartile = factor(
      Age_quartile,
      levels = 1:4,
      labels = c("Q1 (nuorimmat)", 
                 "Q2", 
                 "Q3", 
                 "Q4 (vanhimmat)")
    )
  )

dat_fof %>% 
  group_by(Age_quartile) %>% 
  summarise(
    n   = n(),
    min_age = min(Age),
    median_age = median(Age),
    max_age = max(Age)
  )

# 8.2 Responder proportions by age quartile and FOF status

responder_by_Age_fof <- dat_fof %>%
  group_by(Age_quartile, FOF_status) %>%
  summarise(
    n_total     = n(),
    n_resp      = sum(as.numeric(as.character(responder)) == 1, na.rm = TRUE),
    prop_resp   = n_resp / n_total
  ) %>%
  ungroup()

responder_by_Age_fof

# 8.3 P-values by quartile (FOF vs nonFOF)

p_by_quartile <- dat_fof %>%
  group_by(Age_quartile) %>%
  group_modify(~{
    tab <- table(.x$responder, .x$FOF_status)
    
    test <- if (any(tab < 5)) fisher.test(tab) else chisq.test(tab, correct = FALSE)
    
    tibble(
      test_type = if (any(tab < 5)) "Fisher" else "Chi-square",
      p_value   = test$p.value
    )
  }) %>%
  ungroup()

p_by_quartile


# 8.4 Model with FOF ?? Age quartile interaction

mod_resp_Age_int <- glm(
  responder ~ FOF_status * Age_quartile + Composite_Z0 + Age + BMI + sex,
  data   = dat_fof,
  family = binomial(link = "logit")
)

# A) Globaalit p-arvot (mm. interaktio: muuttuuko FOF-efekti i??n mukaan?)
Anova(mod_resp_Age_int, type = "III")

# B) FOF vs nonFOF -vertailu kussakin ik??kvartiilissa (OR + p-arvo)
emm_fof_by_age <- emmeans(
  mod_resp_Age_int,
  ~ FOF_status | Age_quartile,
  type = "response"     # antaa my??s todenn??k??isyyksi??
)

contr_fof_by_age <- contrast(
  emm_fof_by_age,
  method = "revpairwise",   # FOF vs nonFOF per kvartiili
  by     = "Age_quartile",
  adjust = "none"           # halutessasi esim. "bonferroni"
)

summary(contr_fof_by_age, infer = TRUE, type = "response")


# 8.5 P-values for plotting

# Oleta, ett?? p_by_quartile on laskettu t??m??n tyyppisen??:
# Age_quartile, test_type, p_value

sig_df <- responder_by_Age_fof %>%
  left_join(p_by_quartile, by = "Age_quartile") %>%
  group_by(Age_quartile) %>%
  summarise(
    # korkein responder-osuus kvartiilissa
    y_max   = max(prop_resp, na.rm = TRUE),
    p_value = first(p_value)
  ) %>%
  ungroup() %>%
  mutate(
    # lis??t????n pieni marginaali tekstille
    y_label = y_max + 0.05,
    # mit?? n??ytet????n: t??hdet tai p-arvo
    label = dplyr::case_when(
      p_value < 0.001 ~ "***",
      p_value < 0.01  ~ "**",
      p_value < 0.05  ~ "*",
      p_value < 0.10  ~ paste0("p = ", round(p_value, 2)),  # esim. p = 0.08
      TRUE            ~ ""                                 # ei n??ytet?? mit????n
    )
  )

sig_df_plot <- sig_df %>% filter(label != "")

# 8.6 Plot: responder proportion by age quartile and FOF status

plot_responder_osuus <- ggplot(responder_by_Age_fof,
       aes(x = Age_quartile,
           y = prop_resp,
           fill = FOF_status)) +
  geom_col(position = position_dodge(width = 0.8)) +
  scale_y_continuous(
    name = "Responder-osuus",
    limits = c(0, 1)
  ) +
  labs(
    x    = "Ik??kvartiili",
    fill = "FOF-status",
    title = "Responder-osuus i??n kvartiileittain FOF/nonFOF mukaan"
  ) +
  theme_minimal()

ggsave(
  filename = file.path(outputs_dir, "Responder_osuus.png"),
  plot     = plot_responder_osuus,
  width = 7, height = 5, dpi = 300
)

plot_responderosuus_per <- ggplot(responder_by_Age_fof,
                                  aes(x = Age_quartile,
                                      y = prop_resp,
                                      fill = FOF_status)) +
  geom_col(position = position_dodge(width = 0.8)) +
  scale_y_continuous(
    name = "Responder-osuus (%)",
    limits = c(0, 1),
    labels = scales::percent_format(accuracy = 1)
  ) +
  labs(
    x    = "Ik??kvartiili",
    fill = "FOF-status",
    title = "Responder-osuus i??n kvartiileittain FOF/nonFOF mukaan"
  ) +
  theme_minimal()

# Sama kuva + p-arvo-/t??htitekstit ik??kvartiilin p????lle
plot_responderosuus_per_annot <- plot_responderosuus_per +
  geom_text(
    data = sig_df %>% filter(label != ""),
    aes(x = Age_quartile, y = y_label, label = label),
    inherit.aes = FALSE,
    vjust = 0   # teksti hieman pisteen yl??puolelle
  ) +
  # pieni lis??varaa y-akselille, jos tarvitsee
  coord_cartesian(ylim = c(0, 1.05))

# Tallenna
ggsave(
  filename = file.path(outputs_dir, "Responder_osuus_percent_annot.png"),
  plot     = plot_responderosuus_per_annot,
  width = 7, height = 5, dpi = 300
)

# ==============================================================================
# 09. Distributional Analysis
# ==============================================================================

# 9.1 Heteroscedasticity analysis (GLS)

mod_lm <- lm(
  Delta_Composite_Z ~ FOF_status + Composite_Z0 + Age + BMI + sex,
  data = dat_fof
)

# Esim. Breusch???Pagan heteroskedastisuustesti
library(lmtest)
bptest(mod_lm, ~ FOF_status, data = dat_fof)

# GLS models: homoscedastic vs FOF-specific variance
mod_gls_hom <- gls(
  Delta_Composite_Z ~ FOF_status+ Composite_Z0 + Age + BMI + sex,
  data = dat_fof
)

# Eri varianssit FOF-ryhmille
mod_gls_het <- gls(
  Delta_Composite_Z ~ FOF_status+ Composite_Z0 + Age + BMI + sex,
  data = dat_fof,
  weights = varIdent(form = ~ 1 | FOF_status)
)

anova(mod_gls_hom, mod_gls_het)  # testaa, parantaako heteroskedastisuus sovitusta

# Arvioidut residuaalivarianssit ryhmitt??in
summary(mod_gls_het)$modelStruct$varStruct

# 9.2 Quantile regression

taus <- c(0.25, 0.5, 0.75)

mod_rq_25 <- rq(
  Delta_Composite_Z ~ FOF_status + Composite_Z0 + Age + BMI + sex,
  tau  = 0.25,
  data = dat_fof
)

mod_rq_50 <- rq(
  Delta_Composite_Z ~ FOF_status + Composite_Z0 + Age + BMI + sex,
  tau  = 0.50,
  data = dat_fof
)

mod_rq_75 <- rq(
  Delta_Composite_Z ~ FOF_status + Composite_Z0 + Age + BMI + sex,
  tau  = 0.75,
  data = dat_fof
)

summary(mod_rq_25)
summary(mod_rq_50)
summary(mod_rq_75)

# Esim. ker???? FOF_status-kertoimet taulukkoon

get_fof <- function(fit) {
  cf <- summary(fit)$coefficients
  
  # etsi rivi, joka alkaa "FOF_status"
  rn <- rownames(cf)
  idx <- grep("^FOF_status", rn)
  if (length(idx) == 0) stop("FOF-termi?? ei l??ytynyt. Rownames: ", paste(rn, collapse=", "))
  
  term <- rn[idx[1]]
  
  est <- cf[term, "coefficients"]
  lo  <- cf[term, "lower bd"]
  hi  <- cf[term, "upper bd"]
  se  <- (hi - lo) / (2 * 1.96)
  
  data.frame(tau = fit$tau, term = term, beta_FOF = est, se_FOF = se, ci_low = lo, ci_high = hi)
}

fof_rq <- do.call(rbind, lapply(list(mod_rq_25, mod_rq_50, mod_rq_75), get_fof))


# ==============================================================================
# 10. Save Tables & Outputs
# ==============================================================================

# 10.1 Descriptive frequencies and age quartiles

freq_FOF_status <- dat_fof %>% 
  count(FOF_status)

freq_AgeClass <- dat_fof %>% 
  count(AgeClass)

cross_FOF_AgeClass <- dat_fof %>% 
  count(FOF_status, AgeClass)

Age_quartile_summary <- dat_fof %>% 
  group_by(Age_quartile) %>% 
  summarise(
    n          = n(),
    min_age    = min(Age),
    median_age = median(Age),
    max_age    = max(Age),
    .groups    = "drop"
  )

# Ik??jakaumat kvartaaleittain: montako kutakin ik???? per kvartiili
Age_quartile_Age_counts <- dat_fof %>%
  group_by(Age_quartile, Age) %>%
  summarise(
    n = n(),
    .groups = "drop"
  ) %>%
  arrange(Age_quartile, Age)

Age_quartile_Age_counts

# Tallennus CSV + HTML (outputs-kansioon kuten muutkin)
save_table_csv_html(Age_quartile_Age_counts, "Age_quartile_Age_counts")
save_table_csv_html(freq_FOF_status,      "freq_FOF_status")
save_table_csv_html(freq_AgeClass,        "freq_AgeClass")
save_table_csv_html(cross_FOF_AgeClass,   "cross_FOF_AgeClass")
save_table_csv_html(Age_quartile_summary, "Age_quartile_summary")


# 10.2 Linear models: base & extended

# tab_base ja tab_ext on jo luotu aiemmin, varmistetaan:
tab_base <- broom::tidy(mod_base, conf.int = TRUE)
tab_ext  <- broom::tidy(mod_ext,  conf.int = TRUE)

save_table_csv_html(tab_base, "lm_base_model_full")
save_table_csv_html(tab_ext,  "lm_extended_model_full")

# FOF-kertoimen kooste base vs extended
fof_base <- subset(tab_base, term == "FOF_status_fFOF")
fof_ext  <- subset(tab_ext,  term == "FOF_status_fFOF")

fof_comp <- fof_base %>% 
  mutate(model = "base") %>% 
  bind_rows(fof_ext %>% mutate(model = "extended")) %>% 
  dplyr::select(model, term, estimate, conf.low, conf.high, p.value)

save_table_csv_html(fof_comp, "FOF_effect_base_vs_extended")

# Standardoidut kertoimet extended-mallille
tab_std_ext <- standardize_parameters(mod_ext) %>% 
  as.data.frame()

save_table_csv_html(tab_std_ext, "lm_extended_standardized")


# 10.3 MICE imputed models

# Huom: seuraavat oli jo tehty aiemmin skriptiss??:
# md_pattern_df
# tab_base_imp
# tab_ext_imp
# save_table_csv_html(..., "missing_data_pattern")
# save_table_csv_html(..., "mice_pooled_model_base")
# save_table_csv_html(..., "mice_pooled_model_extended")

# Kooste FOF-kertoimista imputoiduissa malleissa
fof_base_imp <- tab_base_imp %>% dplyr::filter(term == "FOF_status_fFOF")
fof_ext_imp  <- tab_ext_imp  %>% dplyr::filter(term == "FOF_status_fFOF")

fof_imp_comp <- bind_rows(
  fof_base_imp %>% mutate(model = "base_imputed"),
  fof_ext_imp  %>% mutate(model = "extended_imputed")
)

save_table_csv_html(fof_imp_comp, "FOF_effect_MICE_base_vs_extended")


# 10.4 Responder and ordinal models

# Logistinen responder-malli (OR:t)
tab_resp <- tidy(mod_resp, conf.int = TRUE, exponentiate = TRUE)
save_table_csv_html(tab_resp, "logit_responder_model")

# Ordinaalimalli: OR + 95 % CI
ctab <- coef(summary(mod_ord))
ctab_df <- as.data.frame(ctab) %>%
  tibble::rownames_to_column("term")

OR_df <- as.data.frame(OR) %>%
  tibble::rownames_to_column("term")

save_table_csv_html(ctab_df, "ordinal_polr_coefficients")
save_table_csv_html(OR_df,   "ordinal_polr_OR")

# Responder-osuudet ik??kvartiileittain ja FOF-statuksen mukaan
save_table_csv_html(responder_by_Age_fof, "responder_by_Age_and_FOF")

# Kvartiilikohtaiset p-arvot (Chi-square/Fisher)
save_table_csv_html(p_by_quartile, "responder_pvalues_by_Age_quartile")

# emmeans: FOF vs nonFOF per ik??kvartiili (OR + CI)
contr_fof_by_Age_df <- as.data.frame(
  summary(contr_fof_by_age, infer = TRUE, type = "response")
)

save_table_csv_html(contr_fof_by_Age_df, "emmeans_FOF_vs_nonFOF_by_agequartile")


# 10.5 Distributional and quantile regression results

# Breusch???Pagan heteroskedastisuustesti
bp <- bptest(mod_lm, ~ FOF_status, data = dat_fof)

bp_df <- data.frame(
  statistic = unname(bp$statistic),
  df        = unname(bp$parameter),
  p_value   = bp$p.value
)

save_table_csv_html(bp_df, "BP_test_FOF_status")

# GLS-mallien vertailu: homoskedastinen vs FOF-spesifinen var
gls_comp <- as.data.frame(anova(mod_gls_hom, mod_gls_het))
save_table_csv_html(gls_comp, "gls_hom_vs_het_comparison")

# Residuaalivarianssien suhteet FOF-ryhmitt??in
var_struct <- summary(mod_gls_het)$modelStruct$varStruct

# Poimitaan varIdent-kertoimet (ei sis??ll?? baseline-ryhm????, jonka kerroin = 1)
var_coefs <- coef(var_struct, unconstrained = FALSE)

# FOF-status -faktorin tasot datasta
var_levels <- levels(dat_fof$FOF_status)

# Baseline-ryhm?? on se taso, jota ei ole var_coefs-nimiss??
baseline_level <- setdiff(var_levels, names(var_coefs))

# Jos jostain syyst?? baselinea ei l??ydy, oletetaan ensimm??inen taso
if (length(baseline_level) == 0) {
  baseline_level <- var_levels[1]
}

# Kootaan t??ysi suhteiden vektori: baseline = 1, muut = coef(var_struct)
ratios_full <- c(1, as.numeric(var_coefs))
names(ratios_full) <- c(baseline_level, names(var_coefs))

var_struct_df <- data.frame(
  group = names(ratios_full),
  ratio = as.numeric(ratios_full)
)

save_table_csv_html(var_struct_df, "gls_residual_variance_by_FOF")

# Kvanttilinjaregressio: FOF-kerroin eri kvantiileissa
save_table_csv_html(fof_rq, "quantile_reg_FOF_effect")


# ==============================================================================
# 11. Save Session Info
# ==============================================================================

save_sessioninfo_manifest()

# End of K11.R