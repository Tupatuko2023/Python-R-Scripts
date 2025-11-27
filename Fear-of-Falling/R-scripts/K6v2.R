
# K6: Secondary exploratory ANCOVA analyses
# Aim: Does baseline pain / SRH / SRM modify FOF-group differences
# in 12-month change in Composite_Z?


# Ei havaittu tilastollisesti merkitsevää näyttöä siitä, että 
# lähtötason kipu, koettu yleisterveys tai koettu liikuntakyky muuttaisivat 
# FOF-ryhmien välisiä eroja 12 kuukauden muutoksessa fyysisessä toimintakyvyssä 
# (kaikki interaktiot p > 0.27).

# 1: Set Working Directory
setwd("C:/GitWork/Python-R-Scripts/Fear-of-Falling/R-scripts/K6")


# 2: Data Import and Preliminary Processing
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
library(knitr)



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

# emmeans-objektit (emmGrid) + data.frame-versiot
emm_pain_obj <- res_pain$emm
emm_srh_obj  <- res_srh$emm
emm_srm_obj  <- res_srm$emm

emm_pain <- as.data.frame(emm_pain_obj)
emm_srh  <- as.data.frame(emm_srh_obj)
emm_srm  <- as.data.frame(emm_srm_obj)

# Kontrastit: FOF-ero jokaisessa kipuluokassa (PainVAS0_G2)
emm_pain_contrasts <- emm_pain_obj %>%
  contrast(method = "pairwise", by = "PainVAS0_G2") %>%
  summary(infer = TRUE)

# Kontrastit: FOF-ero jokaisessa SRH-luokassa
emm_srh_contrasts <- emm_srh_obj %>%
  contrast(method = "pairwise", by = "SRH_3class") %>%
  summary(infer = TRUE)

# Kontrastit: FOF-ero jokaisessa SRM-luokassa
emm_srm_contrasts <- emm_srm_obj %>%
  contrast(method = "pairwise", by = "SRM_3class") %>%
  summary(infer = TRUE)


emm_pain_contrasts_df <- as.data.frame(emm_pain_contrasts)
emm_srh_contrasts_df  <- as.data.frame(emm_srh_contrasts)
emm_srm_contrasts_df  <- as.data.frame(emm_srm_contrasts)

kable(emm_pain_contrasts_df,
      digits = 3,
      caption = "FOF vs non-FOF -erot Delta_Composite_Z:ssa kipuluokittain")

# Mallin kertoimet
summary(res_pain_cont$fit)
summary(res_pain$fit)

# -------------------------------------------------------------------
# Kuvio 1: FOF × PainVAS0_G2 -emmeans (interaction plot)
# -------------------------------------------------------------------
library(dplyr)
library(ggplot2)
library(forcats)

# Summaroidaan emmeans-objekti ja tehdään siisti data.frame
emm_pain_plot_data <- summary(emm_pain_obj, infer = TRUE) %>%
  as.data.frame() %>%
  mutate(
    # FOF_status-tasot ovat tässä vaiheessa "0" ja "1"
    FOF_status  = fct_recode(
      FOF_status,
      "non_FOF" = "0",
      "FOF"     = "1"
    ),
    FOF_status  = fct_relevel(FOF_status, "non_FOF", "FOF"),
    PainVAS0_G2 = fct_relevel(PainVAS0_G2, "low", "high")
  )


p_pain <- ggplot(
  emm_pain_plot_data,
  aes(
    x     = PainVAS0_G2,
    y     = emmean,
    group = FOF_status,
    color = FOF_status
  )
) +
  geom_line(position = position_dodge(width = 0.1)) +
  geom_point(position = position_dodge(width = 0.1), size = 2) +
  geom_errorbar(
    aes(ymin = lower.CL, ymax = upper.CL),
    width     = 0.05,
    position  = position_dodge(width = 0.1)
  ) +
  labs(
    title  = "Säädetty Delta_Composite_Z FOF-tilan ja kipuluokan mukaan",
    x      = "Lähtötason kipu (PainVAS0_G2)",
    y      = "Säädetty keskiarvo Delta_Composite_Z",
    color  = "FOF-tila"
  ) +
  theme_minimal()

# Varmistetaan outputs-kansio ja tallennetaan kuva
if (!dir.exists("outputs")) dir.create("outputs", recursive = TRUE)

ggsave(
  filename = file.path("outputs", "K6_FOF_PainVAS0_G2_emmeans.png"),
  plot     = p_pain,
  width    = 7,
  height   = 5,
  dpi      = 300
)


# -------------------------------------------------------------------
# Kuvio 2: FOF × SRH_3class -emmeans (interaction plot)
# -------------------------------------------------------------------

emm_srh_plot_data <- summary(emm_srh_obj, infer = TRUE) %>%
  as.data.frame() %>%
  mutate(
    FOF_status  = fct_recode(
      FOF_status,
      "non_FOF" = "0",
      "FOF"     = "1"
    ),
    FOF_status  = fct_relevel(FOF_status, "non_FOF", "FOF"),
    SRH_3class  = fct_relevel(SRH_3class, "good", "intermediate", "poor")
  )

p_srh <- ggplot(
  emm_srh_plot_data,
  aes(
    x     = SRH_3class,
    y     = emmean,
    group = FOF_status,
    color = FOF_status
  )
) +
  geom_line(position = position_dodge(width = 0.1)) +
  geom_point(position = position_dodge(width = 0.1), size = 2) +
  geom_errorbar(
    aes(ymin = lower.CL, ymax = upper.CL),
    width     = 0.05,
    position  = position_dodge(width = 0.1)
  ) +
  labs(
    title  = "Säädetty Delta_Composite_Z FOF-tilan ja SRH-luokan mukaan",
    x      = "Self-rated health (SRH_3class)",
    y      = "Säädetty keskiarvo Delta_Composite_Z",
    color  = "FOF-tila"
  ) +
  theme_minimal()

ggsave(
  filename = file.path("outputs", "K6_FOF_SRH3_emmeans.png"),
  plot     = p_srh,
  width    = 7,
  height   = 5,
  dpi      = 300
)


# -------------------------------------------------------------------
# Kuvio 3: FOF × SRM_3class -emmeans (interaction plot)
# -------------------------------------------------------------------

emm_srm_plot_data <- summary(emm_srm_obj, infer = TRUE) %>%
  as.data.frame() %>%
  mutate(
    FOF_status  = fct_recode(
      FOF_status,
      "non_FOF" = "0",
      "FOF"     = "1"
    ),
    FOF_status  = fct_relevel(FOF_status, "non_FOF", "FOF"),
    SRM_3class  = fct_relevel(SRM_3class, "good", "intermediate", "poor")
  )


p_srm <- ggplot(
  emm_srm_plot_data,
  aes(
    x     = SRM_3class,
    y     = emmean,
    group = FOF_status,
    color = FOF_status
  )
) +
  geom_line(position = position_dodge(width = 0.1)) +
  geom_point(position = position_dodge(width = 0.1), size = 2) +
  geom_errorbar(
    aes(ymin = lower.CL, ymax = upper.CL),
    width     = 0.05,
    position  = position_dodge(width = 0.1)
  ) +
  labs(
    title  = "Säädetty Delta_Composite_Z FOF-tilan ja SRM-luokan mukaan",
    x      = "Self-rated mobility (SRM_3class)",
    y      = "Säädetty keskiarvo Delta_Composite_Z",
    color  = "FOF-tila"
  ) +
  theme_minimal()

ggsave(
  filename = file.path("outputs", "K6_FOF_SRM3_emmeans.png"),
  plot     = p_srm,
  width    = 7,
  height   = 5,
  dpi      = 300
)


# -------------------------------------------------------------------
# Kuvio 4: Forest-tyyppinen koontikuva FOF vs non_FOF -kontrasteista
# -------------------------------------------------------------------

library(dplyr)
library(forcats)
library(ggplot2)

# Lisätään moderaattorin nimi ja luokka samaan runkoon
pain_contr <- emm_pain_contrasts_df %>%
  mutate(
    domain  = "PainVAS0_G2",
    stratum = PainVAS0_G2
  )

srh_contr <- emm_srh_contrasts_df %>%
  mutate(
    domain  = "SRH_3class",
    stratum = SRH_3class
  )

srm_contr <- emm_srm_contrasts_df %>%
  mutate(
    domain  = "SRM_3class",
    stratum = SRM_3class
  )

contr_all <- bind_rows(pain_contr, srh_contr, srm_contr) %>%
  # Poimitaan FOF vs non_FOF -kontrastit
  filter(grepl("FOF", contrast)) %>%
  mutate(
    domain  = factor(domain, levels = c("PainVAS0_G2", "SRH_3class", "SRM_3class")),
    stratum = factor(
      stratum,
      levels = c("low", "high", "good", "intermediate", "poor")
    ),
    label = paste(domain, as.character(stratum), sep = ": ")
  )

p_forest <- ggplot(
  contr_all,
  aes(
    x = estimate,
    y = fct_rev(label)  # käännetään järjestys, jotta skaalat luetaan ylhäältä alas
  )
) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  geom_pointrange(
    aes(xmin = lower.CL, xmax = upper.CL)
  ) +
  labs(
    title = "FOF vs non_FOF erot Delta_Composite_Z:ssa\nmoderaattoreiden ja luokkien mukaan",
    x     = "Erotus (Delta_Composite_Z, FOF − non_FOF)",
    y     = "Moderaattori ja luokka"
  ) +
  theme_minimal()

ggsave(
  filename = file.path("outputs", "K6_FOF_contrasts_forest.png"),
  plot     = p_forest,
  width    = 7,
  height   = 5,
  dpi      = 300
)





# --------------------------------------------------------------------
# Output- ja manifest-lohko K6-skriptin päämalleille
# --------------------------------------------------------------------

# Varmista, että outputs-kansio on olemassa
if (!dir.exists("outputs")) {
  dir.create("outputs", recursive = TRUE)
}

# Skriptin tunniste ja manifest-polku
script_label  <- "K6_main"
manifest_path <- file.path("outputs", "manifest.csv")

# Yhdistetty päämallitaulukko:
# - yksi rivi per malli
# - keskitytään FOF_status x G -interaktiotermin Type III -testiin

main_results <- dplyr::bind_rows(
  # FOF x PainVAS0_G2
  anova_pain_tidy %>%
    dplyr::filter(term == "FOF_status:PainVAS0_G2") %>%
    dplyr::transmute(
      model   = "FOF x PainVAS0_G2",
      term    = term,
      sum_sq  = `Sum Sq`,
      df      = Df,
      f_value = `F value`,
      p_value = `Pr(>F)`
    ),
  
  # FOF x SRH_3class
  anova_srh_tidy %>%
    dplyr::filter(term == "FOF_status:SRH_3class") %>%
    dplyr::transmute(
      model   = "FOF x SRH_3class",
      term    = term,
      sum_sq  = `Sum Sq`,
      df      = Df,
      f_value = `F value`,
      p_value = `Pr(>F)`
    ),
  
  # FOF x SRM_3class
  anova_srm_tidy %>%
    dplyr::filter(term == "FOF_status:SRM_3class") %>%
    dplyr::transmute(
      model   = "FOF x SRM_3class",
      term    = term,
      sum_sq  = `Sum Sq`,
      df      = Df,
      f_value = `F value`,
      p_value = `Pr(>F)`
    )
)

# Kirjoita päämallien tulokset CSV:hen
main_results_path <- file.path("outputs", paste0(script_label, "_main_results.csv"))
utils::write.csv(main_results, main_results_path, row.names = FALSE)
message("K6-päämallien tulokset tallennettu: ", main_results_path)

# Manifest-rivit K6-skriptin keskeisille tuloksille
# Tässä lisätään ainakin päämallitaulukko; voit laajentaa listaa myöhemmin,
# jos alat tallentaa myös esim. anova_tidy- tai emmeans-kontrastitaulukoita
# omiin CSV-tiedostoihinsa.

manifest_rows <- data.frame(
  script      = script_label,
  type        = c("table"),
  filename    = c(paste0(script_label, "_main_results.csv")),
  description = c("K6 ANCOVA -paamallien yhteenvetotaulukko (FOF x PainVAS0_G2, SRH_3class, SRM_3class)"),
  stringsAsFactors = FALSE
)

# Kirjoita tai paivita manifest.csv samaan logiikkaan kuin K5-skriptissa
if (!file.exists(manifest_path)) {
  utils::write.table(
    manifest_rows,
    file      = manifest_path,
    sep       = ",",
    row.names = FALSE,
    col.names = TRUE,
    append    = FALSE,
    qmethod   = "double"
  )
} else {
  utils::write.table(
    manifest_rows,
    file      = manifest_path,
    sep       = ",",
    row.names = FALSE,
    col.names = FALSE,
    append    = TRUE,
    qmethod   = "double"
  )
}

message("Manifest paivitetty: ", manifest_path)
