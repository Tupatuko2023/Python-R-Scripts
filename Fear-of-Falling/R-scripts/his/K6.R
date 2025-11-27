
# K6: Secondary exploratory ANCOVA analyses
# Aim: Does baseline pain / SRH / SRM modify FOF-group differences
# in 12-month change in Composite_Z?


# Load required packages -----------------------------------------------
library(dplyr)
library(tidyr)
library(ggplot2)
library(forcats)
library(broom)
library(car)        # for Type III tests later
library(emmeans)    # for marginal means later
library(rlang)
library(tibble)



# Load the dataset ------------------------------------------------------

# Optional: keep a working copy so the original stays untouched
analysis_data_raw <- analysis_data

# Basic structure and missingness overview -----------------------------
glimpse(analysis_data_raw)

summary(select(
  analysis_data_raw,
  NRO, Age, Sex,
  PainVAS0, SRH, oma_arvio_liikuntakyky,
  kaatumisenpelkoOn
))

# Inspect kaatumisenpelkoOn coding ------------------------------------
table(analysis_data$kaatumisenpelkoOn, useNA = "ifany")

# Define FOF_status factor (0 = non-FOF, 1 = FOF) ----------------------
analysis_data <- analysis_data %>%
  mutate(
    FOF_status = case_when(
      kaatumisenpelkoOn == 0 ~ "non_FOF",
      kaatumisenpelkoOn == 1 ~ "FOF",
      TRUE                   ~ NA_character_
    ),
    FOF_status = factor(
      FOF_status,
      levels = c("non_FOF", "FOF")
    )
  )

# Inspect PainVAS0 distribution ---------------------------------------
analysis_data_raw %>%
  summarise(
    n_nonmiss   = sum(!is.na(PainVAS0)),
    mean        = mean(PainVAS0, na.rm = TRUE),
    sd          = sd(PainVAS0, na.rm = TRUE),
    min         = min(PainVAS0, na.rm = TRUE),
    p25         = quantile(PainVAS0, 0.25, na.rm = TRUE),
    p50         = quantile(PainVAS0, 0.50, na.rm = TRUE),
    p75         = quantile(PainVAS0, 0.75, na.rm = TRUE),
    max         = max(PainVAS0, na.rm = TRUE)
  )

# Quick visual check
ggplot(analysis_data_raw, aes(x = PainVAS0)) +
  geom_histogram(bins = 30) +
  labs(
    title = "Distribution of baseline pain VAS",
    x = "PainVAS0 (0–100)",
    y = "Count"
  )
# The distribution looks roughly symmetric, so we can use it as a continuous predictor without transformations.

# Compute tertile cutpoints (based on nonmissing PainVAS0) ------------
pain_tertiles <- quantile(
  analysis_data_raw$PainVAS0,
  probs = c(1/3, 2/3),
  na.rm = TRUE
)

pain_tertiles

# Recode into tertiles (keeping original PainVAS0) ---------------------
analysis_data <- analysis_data_raw %>%
  mutate(
    PainVAS0_tertile = case_when(
      is.na(PainVAS0) ~ NA_character_,
      PainVAS0 <= pain_tertiles[1] ~ "T1",
      PainVAS0 <= pain_tertiles[2] ~ "T2",
      TRUE                         ~ "T3"
    ),
    PainVAS0_tertile = factor(
      PainVAS0_tertile,
      levels = c("T1", "T2", "T3")
    )
  )

# Check distribution of new tertile variable ---------------------------
analysis_data %>%
  count(PainVAS0_tertile) %>%
  mutate(prop = n / sum(n))

# Inspect SRH coding ---------------------------------------------------
table(analysis_data$SRH, useNA = "ifany")
summary(analysis_data$SRH)

# Recode SRH: 0 = good, 1 = intermediate, 2 = poor ---------------------
analysis_data <- analysis_data %>%
  mutate(
    SRH_3class = case_when(
      is.na(SRH)   ~ NA_character_,
      SRH == 0     ~ "good",
      SRH == 1     ~ "intermediate",
      SRH == 2     ~ "poor",
      TRUE         ~ NA_character_
    ),
    SRH_3class = factor(
      SRH_3class,
      levels = c("good", "intermediate", "poor")
    )
  )

# Jakauma
analysis_data %>%
  count(SRH_3class) %>%
  mutate(prop = n / sum(n))

# SRH_3class FOF-ryhmittäin
srh_tab <- analysis_data %>%
  filter(!is.na(FOF_status), !is.na(SRH_3class)) %>%
  count(FOF_status, SRH_3class) %>%
  group_by(FOF_status) %>%
  mutate(row_prop = n / sum(n)) %>%
  ungroup()

srh_tab


# Check SRH_3class distribution ----------------------------------------
analysis_data %>%
  count(SRH_3class) %>%
  mutate(prop = n / sum(n))
# Looks reasonable.

# Inspect SRM proxy (oma_arvio_liikuntakyky) ---------------------------
table(analysis_data$oma_arvio_liikuntakyky, useNA = "ifany")
summary(analysis_data$oma_arvio_liikuntakyky)

# Uudelleenluokitus SRM: 0 = good, 1 = intermediate, 2 = poor ----------
analysis_data <- analysis_data %>%
  mutate(
    SRM_3class = case_when(
      is.na(oma_arvio_liikuntakyky) ~ NA_character_,
      oma_arvio_liikuntakyky == 0   ~ "good",
      oma_arvio_liikuntakyky == 1   ~ "intermediate",
      oma_arvio_liikuntakyky == 2   ~ "poor",
      TRUE                          ~ NA_character_
    ),
    SRM_3class = factor(
      SRM_3class,
      levels = c("good", "intermediate", "poor")
    )
  )

# Jakauma
analysis_data %>%
  count(SRM_3class) %>%
  mutate(prop = n / sum(n))

# SRM_3class FOF ryhmittäin
srm_tab <- analysis_data %>%
  filter(!is.na(FOF_status), !is.na(SRM_3class)) %>%
  count(FOF_status, SRM_3class) %>%
  group_by(FOF_status) %>%
  mutate(row_prop = n / sum(n)) %>%
  ungroup()

srm_tab

# Check FOF_status distribution ----------------------------------------
analysis_data %>%
  count(FOF_status) %>%
  mutate(prop = n / sum(n))


# Mean pain VAS by FOF_status -----------------------------------------
pain_by_fof <- analysis_data %>%
  group_by(FOF_status) %>%
  summarise(
    n           = sum(!is.na(PainVAS0)),
    mean_pain   = mean(PainVAS0, na.rm = TRUE),
    sd_pain     = sd(PainVAS0, na.rm = TRUE),
    median_pain = median(PainVAS0, na.rm = TRUE),
    .groups = "drop"
  )

pain_by_fof

# Pain tertiles by FOF_status (counts and row proportions) -------------
pain_tertile_tab <- analysis_data %>%
  filter(!is.na(FOF_status), !is.na(PainVAS0_tertile)) %>%
  count(FOF_status, PainVAS0_tertile) %>%
  group_by(FOF_status) %>%
  mutate(row_prop = n / sum(n)) %>%
  ungroup()

pain_tertile_tab


ggplot(
  analysis_data,
  aes(x = FOF_status, y = PainVAS0)
) +
  geom_boxplot() +
  labs(
    title = "Baseline pain VAS by FOF status",
    x = "FOF status",
    y = "PainVAS0 (0–100)"
  )


# SRH_3class by FOF_status ---------------------------------------------
srh_tab <- analysis_data %>%
  filter(!is.na(FOF_status), !is.na(SRH_3class)) %>%
  count(FOF_status, SRH_3class) %>%
  group_by(FOF_status) %>%
  mutate(row_prop = n / sum(n)) %>%
  ungroup()

srh_tab

# SRM_3class by FOF_status ---------------------------------------------
srm_tab <- analysis_data %>%
  filter(!is.na(FOF_status), !is.na(SRM_3class)) %>%
  count(FOF_status, SRM_3class) %>%
  group_by(FOF_status) %>%
  mutate(row_prop = n / sum(n)) %>%
  ungroup()

srm_tab


# SRH stacked bar ------------------------------------------------------
ggplot(
  analysis_data %>%
    filter(!is.na(FOF_status), !is.na(SRH_3class)),
  aes(x = FOF_status, fill = SRH_3class)
) +
  geom_bar(position = "fill") +
  scale_y_continuous(labels = scales::percent_format()) +
  labs(
    title = "Self-rated health by FOF status",
    x = "FOF status",
    y = "Proportion"
  )

# SRM stacked bar ------------------------------------------------------
ggplot(
  analysis_data %>%
    filter(!is.na(FOF_status), !is.na(SRM_3class)),
  aes(x = FOF_status, fill = SRM_3class)
) +
  geom_bar(position = "fill") +
  scale_y_continuous(labels = scales::percent_format()) +
  labs(
    title = "Self-rated mobility by FOF status",
    x = "FOF status",
    y = "Proportion"
  )


check_cell_sizes <- function(data, g_var) {
  data %>%
    filter(!is.na(FOF_status), !is.na({{ g_var }})) %>%
    count(FOF_status, {{ g_var }}) %>%
    mutate(ok_30 = n >= 30)
}

# Kovariaattien tarkistus: ikä ja sukupuoli ---------------------------
summary(analysis_data$Age)
summary(analysis_data$Sex)
table(analysis_data$Sex, useNA = "ifany")

# Sukupuolen uudelleenkooditus: 0 = female, 1 = male ------------------
analysis_data <- analysis_data %>%
  mutate(
    Sex_factor = fct_recode(
      Sex,
      "female" = "0",
      "male"   = "1"
    )
  )

# Tarkistetaan uusi kooditus
table(analysis_data$Sex_factor, useNA = "ifany")



# Check for all three grouping variables -------------------------------
# Funktio solukokojen tarkistukseen kaikille G-muuttujille
check_cell_sizes <- function(data, g_var) {
  data %>%
    filter(!is.na(FOF_status), !is.na({{ g_var }})) %>%
    count(FOF_status, {{ g_var }}) %>%
    mutate(ok_30 = n >= 30)
}

cell_pain <- check_cell_sizes(analysis_data, PainVAS0_tertile)
cell_srh  <- check_cell_sizes(analysis_data, SRH_3class)
cell_srm  <- check_cell_sizes(analysis_data, SRM_3class)

cell_pain
cell_srh
cell_srm
 
# 2-luokkainen kipumuuttuja, jotta kaikki FOF × kipu -solut ≥ 30 -------
analysis_data <- analysis_data %>%
  mutate(
    PainVAS0_G2 = case_when(
      is.na(PainVAS0_tertile)              ~ NA_character_,
      PainVAS0_tertile == "T1"             ~ "low",
      PainVAS0_tertile %in% c("T2", "T3")  ~ "high"
    ),
    PainVAS0_G2 = factor(
      PainVAS0_G2,
      levels = c("low", "high")
    )
  )

# Uudet solukoot FOF × PainVAS0_G2
cell_pain2 <- check_cell_sizes(analysis_data, PainVAS0_G2)
cell_pain2

# ---------- ANCOVA-apufunktio: FOF_status × G, kovariaatteina ikä ja sukupuoli ----------

# Kontrastit Type III -testeihin
options(contrasts = c("contr.sum", "contr.poly"))

run_ancova_FOF_G <- function(data, outcome, baseline, G_var) {
  outcome  <- rlang::ensym(outcome)
  baseline <- rlang::ensym(baseline)
  G_var    <- rlang::ensym(G_var)
  
  # Complete case -data
  dat_cc <- data %>%
    filter(
      !is.na(FOF_status),
      !is.na(!!G_var),
      !is.na(!!outcome),
      !is.na(!!baseline),
      !is.na(Age),
      !is.na(Sex_factor)
    )
  
  cat("N ennen complete case -rajausta:", nrow(data), "\n")
  cat("N complete case -aineistossa:", nrow(dat_cc), "\n\n")
  
  # Rakennetaan formula stringistä
  form <- as.formula(
    paste0(
      rlang::as_string(outcome),
      " ~ FOF_status * ", rlang::as_string(G_var),
      " + ", rlang::as_string(baseline),
      " + Age + Sex_factor"
    )
  )
  
  # Sovitus
  fit <- lm(form, data = dat_cc)
  
  # Type III -testit
  anova_tab <- car::Anova(fit, type = 3)
  print(anova_tab)
  
  cat("\nEstimated marginal means (FOF ×", rlang::as_string(G_var), "):\n")
  emm <- emmeans::emmeans(fit, specs = c("FOF_status", rlang::as_string(G_var)))
  print(emm)
  
  list(
    data_cc = dat_cc,
    fit     = fit,
    anova   = anova_tab,
    emm     = emm
  )
}

# Lisäanalyysi: FOF × jatkuva kipu (PainVAS0), ilman kategorisointia
run_ancova_FOF_pain_cont <- function(data) {
  
  dat_cc <- data %>%
    filter(
      !is.na(FOF_status),
      !is.na(PainVAS0),
      !is.na(Delta_Composite_Z),
      !is.na(Composite_Z0),
      !is.na(Age),
      !is.na(Sex_factor)
    )
  
  cat("Jatkuva kipu, N ennen complete case -rajausta:", nrow(data), "\n")
  cat("Jatkuva kipu, N complete case -aineistossa:", nrow(dat_cc), "\n\n")
  
  fit <- lm(
    Delta_Composite_Z ~ FOF_status * scale(PainVAS0) +
      Composite_Z0 + Age + Sex_factor,
    data = dat_cc
  )
  
  anova_tab <- car::Anova(fit, type = 3)
  print(anova_tab)
  
  list(
    data_cc = dat_cc,
    fit     = fit,
    anova   = anova_tab
  )
}



# Esimerkki 1: FOF × kipu (2-luokkainen PainVAS0_G2)
res_pain <- run_ancova_FOF_G(
  data     = analysis_data,
  outcome  = Delta_Composite_Z,
  baseline = Composite_Z0,
  G_var    = PainVAS0_G2
)

# Esimerkki: diagnostiikka erikseen kutsuttavaksi
check_lm_assumptions <- function(fit) {
  par(mfrow = c(2, 2))
  plot(fit)  # jäännökset vs. sovitteet, QQ-plotti jne.
  par(mfrow = c(1, 1))
}
# Käyttö:
check_lm_assumptions(res_pain$fit)

# Lisäanalyysi: FOF × jatkuva kipu (PainVAS0 skaalattuna)
res_pain_cont <- run_ancova_FOF_pain_cont(analysis_data)

# Esimerkki 2: FOF × SRH
res_srh <- run_ancova_FOF_G(
  data     = analysis_data,
  outcome  = Delta_Composite_Z,
  baseline = Composite_Z0,
  G_var    = SRH_3class
)

# Esimerkki 3: FOF × SRM
res_srm <- run_ancova_FOF_G(
  data     = analysis_data,
  outcome  = Delta_Composite_Z,
  baseline = Composite_Z0,
  G_var    = SRM_3class
)

# Type III -testien taulukot
anova_pain <- res_pain$anova %>%
  as.data.frame() %>%
  rownames_to_column("term")

anova_srh <- res_srh$anova %>%
  as.data.frame() %>%
  rownames_to_column("term")

anova_srm <- res_srm$anova %>%
  as.data.frame() %>%
  rownames_to_column("term")

# Siistit ANOVA-taulukot raportointia varten
anova_pain_tidy <- anova_pain %>%
  select(term, `Sum Sq`, Df, `F value`, `Pr(>F)`)

anova_srh_tidy <- anova_srh %>%
  select(term, `Sum Sq`, Df, `F value`, `Pr(>F)`)

anova_srm_tidy <- anova_srm %>%
  select(term, `Sum Sq`, Df, `F value`, `Pr(>F)`)


anova_pain
anova_srh
anova_srm

emm_pain <- as.data.frame(res_pain$emm)
emm_srh  <- as.data.frame(res_srh$emm)
emm_srm  <- as.data.frame(res_srm$emm)

emm_pain
emm_srh
emm_srm

# Mallin kertoimet
summary(res_pain_cont$fit)
summary(res_pain$fit)