
# Title: KAAOS 7: Fear of Falling and Physical Performance: Moderation Analyses
# Script: K7.R

# ==============================================================================

# K7-skripti tekee moderointianalyyseja kaatumisen pelon ja fyysisen
# suorituskyvyn välillä. Skriptin ajon lopussa se ilmoittaa tärkeimmät KUVAT
# keskitettyyn manifest/manifest.csv-tiedostoon. Yksi rivi vastaa yhtä kuvaa.
# Riviltä näkee, mikä skripti kuvan on tehnyt, minkä tyyppinen tulos on
# kyseessä, mistä tiedosto löytyy ja mitä se lyhyesti kuvaa.

## Packages ---------------------------------------------------------------
library(dplyr)
library(tidyr)
library(ggplot2)
library(forcats)
library(broom)
library(janitor)
library(purrr)
library(car)
library(emmeans)
library(rlang)
library(here)
library(tibble)

set.seed(20251114)
# ==============================================================================

# 1: Load the dataset ------------------------------------------------------

file_path <- here::here("data", "external", "KaatumisenPelko.csv")

raw_data <- readr::read_csv(file_path, show_col_types = FALSE)

# Working copy so the original stays untouched
## Tarkista, että analysis_data on olemassa -------------------------------
if (!exists("raw_data")) {
  stop("Object 'raw_data' not found. Please load your data as raw_data first.")
}

## Tee raaka- ja työkopio
analysis_data_raw  <- raw_data
glimpse(analysis_data_raw)
names(analysis_data_raw)


# 1a. Määritä kansiot ------------------------------------------------------
# Script directory
script_dir <- here::here("R-scripts", "K7")

# 1b. Output-kansio K6:n alle
outputs_dir <- here::here("R-scripts", "K7", "outputs")
if (!dir.exists(outputs_dir)) {
  dir.create(outputs_dir, recursive = TRUE)
}

# Erillinen manifest-kansio projektissa: ./manifest
manifest_dir <- here::here("manifest")
if (!dir.exists(manifest_dir)) {
  dir.create(manifest_dir, recursive = TRUE)
}
manifest_path <- file.path(manifest_dir, "manifest.csv")


# 1c: Rakenna analyysimuuttujat alkuperäisistä sarakkeista
analysis_data_raw <- raw_data %>%
  mutate(
    # Baseline-komposiitti ja muutoskomposiitti
    Composite_Z0      = ToimintaKykySummary0,
    Delta_Composite_Z = ToimintaKykySummary2 - ToimintaKykySummary0
  ) %>%
  # Nimeä kovariaatit analyysin mukaisiksi
  rename(
    Age = age,
    Sex = sex
  )

analysis_data_work <- analysis_data_raw


## FOF_status 0/1 -> factor -----------------------------------------------
if (!"kaatumisenpelkoOn" %in% names(analysis_data_work)) {
  stop("Variable 'kaatumisenpelkoOn' not found in analysis_data_work.")
}

analysis_data_work <- analysis_data_work %>%
  mutate(
    FOF_status = case_when(
      kaatumisenpelkoOn == 1 ~ "FOF",
      kaatumisenpelkoOn == 0 ~ "non-FOF",
      TRUE ~ NA_character_
    ),
    FOF_status = factor(FOF_status, levels = c("non-FOF", "FOF"))
  )

table(analysis_data_work$FOF_status, useNA = "ifany")

## Neurologinen komposiitti (jos muuttujat löytyvät) ----------------------
neuro_vars <- c("alzheimer", "parkinson", "AVH")

if (all(neuro_vars %in% names(analysis_data_work))) {
  analysis_data_work <- analysis_data_work %>%
    mutate(
      neuro_any = case_when(
        alzheimer == 1 | parkinson == 1 | AVH == 1 ~ "yes",
        alzheimer == 0 & parkinson == 0 & AVH == 0 ~ "no",
        TRUE ~ NA_character_
      ),
      neuro_any = factor(neuro_any, levels = c("no", "yes"))
    )
} else {
  warning("One or more neurological vars (alzheimer, parkinson, AVH) not found.")
}
table(analysis_data_work$neuro_any, useNA = "ifany")


## SRH: SRH tai koettuterveydentila ----------------------------------------
srh_candidates <- c("SRH", "koettuterveydentila")
srh_var <- srh_candidates[srh_candidates %in% names(analysis_data_work)][1]

if (length(srh_var) == 0) {
  warning("No SRH variable found for SRH_3class.")
} else {
  analysis_data_work %>%
    count(.data[[srh_var]]) %>%
    arrange(.data[[srh_var]])
  
  analysis_data_work <- analysis_data_work %>%
    mutate(
      SRH_3class = case_when(
        .data[[srh_var]] %in% c(1, "Hyvä", "good")           ~ "good",
        .data[[srh_var]] %in% c(2, "Keskinkertainen", "fair")~ "fair",
        .data[[srh_var]] %in% c(3, "Huono", "poor")          ~ "poor",
        TRUE ~ NA_character_
      ),
      SRH_3class = factor(SRH_3class, levels = c("good", "fair", "poor"))
    )
}

## SRM: oma_arvio_liikuntakyky --------------------------------------------
if ("oma_arvio_liikuntakyky" %in% names(analysis_data_work)) {
  analysis_data_work %>%
    count(oma_arvio_liikuntakyky) %>%
    arrange(oma_arvio_liikuntakyky)
  
  analysis_data_work <- analysis_data_work %>%
    mutate(
      SRM_3class = case_when(
        oma_arvio_liikuntakyky %in% c(1, "Hyvä", "good")            ~ "good",
        oma_arvio_liikuntakyky %in% c(2, "Kohtalainen", "fair")     ~ "fair",
        oma_arvio_liikuntakyky %in% c(3, "Huono", "poor")           ~ "poor",
        TRUE ~ NA_character_
      ),
      SRM_3class = factor(SRM_3class, levels = c("good", "fair", "poor"))
    )
} else {
  warning("oma_arvio_liikuntakyky not found for SRM_3class.")
}

table(analysis_data_work$SRM_3class, useNA = "ifany")

## 500 m kävely -----------------------------------------------------------
if ("Vaikeus500m" %in% names(analysis_data_work)) {
  analysis_data_work %>%
    count(Vaikeus500m) %>%
    arrange(Vaikeus500m)
  
  analysis_data_work <- analysis_data_work %>%
    mutate(
      Walk500m_3class = case_when(
        Vaikeus500m %in% c(0, "Ei vaikeuksia", "no difficulty") ~ "no difficulty",
        Vaikeus500m %in% c(1, "Jonkin verran", "some difficulty") ~ "some difficulty",
        Vaikeus500m %in% c(2, "Ei pysty", "unable") ~ "unable",
        TRUE ~ NA_character_
      ),
      Walk500m_3class = factor(Walk500m_3class,
                               levels = c("no difficulty", "some difficulty", "unable"))
    )
} else {
  warning("Vaikeus500m not found.")
}

## Alkoholi 0,1,2 ---------------------------------------------------------
if ("alkoholi" %in% names(analysis_data_work)) {
  analysis_data_work <- analysis_data_work %>%
    mutate(
      Alcohol_3class = factor(
        alkoholi,
        levels = c(0, 1, 2),
        labels = c("none", "moderate", "heavy")
      )
    )
}

## Tasapainovaikeus 0/1 -> factor -----------------------------------------
if ("tasapainovaikeus" %in% names(analysis_data_work)) {
  analysis_data_work <- analysis_data_work %>%
    mutate(
      Balance_problem = case_when(
        tasapainovaikeus == 1 ~ "yes",
        tasapainovaikeus == 0 ~ "no",
        TRUE ~ NA_character_
      ),
      Balance_problem = factor(Balance_problem, levels = c("no", "yes"))
    )
}

table(analysis_data_work$Balance_problem, useNA = "ifany")

## Tarkista keskeiset PBT-muuttujat ---------------------------------------
pbt_vars <- c(
  "Puristus0", "Puristus2",          # HGS summary
  "kavelynopeus_m_sek0", "kavelynopeus_m_sek2",
  "Tuoli0", "Tuoli2",
  "Seisominen0", "Seisominen2",
  "ToimintaKykySummary0", "ToimintaKykySummary2"
)

pbt_vars[pbt_vars %in% names(analysis_data_work)]

analysis_data_work %>%
  select(any_of(c("Puristus0", "Puristus2",
                  "kavelynopeus_m_sek0", "kavelynopeus_m_sek2",
                  "Tuoli0", "Tuoli2",
                  "Seisominen0", "Seisominen2"))) %>%
  summary()

## Käytä ToimintaKykySummary0/2 jos saatavilla ----------------------------
if (all(c("ToimintaKykySummary0", "ToimintaKykySummary2") %in% names(analysis_data_work))) {
  analysis_data_work <- analysis_data_work %>%
    mutate(
      Composite0 = ToimintaKykySummary0,
      Composite2 = ToimintaKykySummary2
    )
} else {
  stop("ToimintaKykySummary0/2 not found. If you prefer z-scores, we can adapt code.")
}

## Delta-muuttujat: positiivinen = parannus -------------------------------
analysis_data_work <- analysis_data_work %>%
  mutate(
    DeltaComposite = Composite2 - Composite0,
    
    Delta_HGS = if (all(c("Puristus0", "Puristus2") %in% names(analysis_data_work))) {
      Puristus2 - Puristus0
    } else NA_real_,
    
    Delta_MWS = if (all(c("kavelynopeus_m_sek0", "kavelynopeus_m_sek2") %in% names(analysis_data_work))) {
      kavelynopeus_m_sek2 - kavelynopeus_m_sek0
    } else NA_real_,
    
    ## FTSST: pienempi aika = parempi, joten baseline - follow up
    Delta_FTSST = if (all(c("Tuoli0", "Tuoli2") %in% names(analysis_data_work))) {
      Tuoli0 - Tuoli2
    } else NA_real_,
    
    Delta_SLS = if (all(c("Seisominen0", "Seisominen2") %in% names(analysis_data_work))) {
      Seisominen2 - Seisominen0
    } else NA_real_
  )

## Deskriptiikat delta-muuttujille FOF mukaan -----------------------------
delta_vars <- c("DeltaComposite", "Delta_HGS", "Delta_MWS", "Delta_FTSST", "Delta_SLS") %>%
  intersect(names(analysis_data_work))

summarise_delta_by_FOF <- function(data, var) {
  data %>%
    group_by(FOF_status) %>%
    summarise(
      n    = sum(!is.na(.data[[var]])),
      mean = mean(.data[[var]], na.rm = TRUE),
      sd   = sd(.data[[var]], na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(variable = var, .before = 1)
}

delta_desc_by_FOF <- purrr::map_dfr(
  delta_vars,
  ~ summarise_delta_by_FOF(analysis_data_work, .x)
)

delta_desc_by_FOF

ggplot(
  analysis_data_work,
  aes(x = FOF_status, y = DeltaComposite, fill = FOF_status)
) +
  geom_boxplot(alpha = 0.6) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(
    title = "Muutos komposiittisuoriutumisessa FOF-statuksen mukaan",
    x = "FOF-status",
    y = "DeltaComposite (follow up - baseline)"
  ) +
  theme_minimal() +
  theme(legend.position = "none")


## STEP 3: PBT-pohjaiset alaryhmät G_MWS, G_HGS jne. ----------------------------


## MWS: kolmiluokkainen versio -------------------------------------------

analysis_data_work <- analysis_data_work %>%
  mutate(
    G_MWS1 = case_when(
      kavelynopeus_m_sek0 < 1.0 ~ "<1.0 m/s",
      kavelynopeus_m_sek0 >= 1.0 ~ "≥1.0 m/s",
      TRUE ~ NA_character_
    ),
    G_MWS1 = factor(G_MWS1, levels = c("<1.0 m/s", "≥1.0 m/s"))
  )

analysis_data_work %>%
  filter(!is.na(FOF_status), !is.na(G_MWS1)) %>%
  count(G_MWS1, FOF_status)

## (Valinnainen) kaksi luokkaa: hidas vs muut ------------------------------


analysis_data_work <- analysis_data_work %>%
  mutate(
    G_MWS2 = case_when(
      kavelynopeus_m_sek0 < 1.3 ~ "<1.3 m/s",
      kavelynopeus_m_sek0 >= 1.3 ~ "≥1.3 m/s",
      TRUE ~ NA_character_
    ),
    G_MWS2 = factor(G_MWS2, levels = c("<1.3 m/s", "≥1.3 m/s"))
  )


## Solukoot FOF x G_MWS ---------------------------------------------------

tab_MWS1 <- analysis_data_work %>%
  filter(!is.na(FOF_status), !is.na(G_MWS1)) %>%
  count(G_MWS1, FOF_status) %>%
  group_by(G_MWS1) %>%
  mutate(total_in_G = sum(n)) %>%
  ungroup()

tab_MWS1

## (Valinnainen) kaksi luokkaa: hidas vs muut ------------------------------

tab_MWS2 <- analysis_data_work %>%
  filter(!is.na(FOF_status), !is.na(G_MWS2)) %>%
  count(G_MWS2, FOF_status) %>%
  group_by(G_MWS2) %>%
  mutate(total_in_G = sum(n)) %>%
  ungroup()

tab_MWS2

## SLS: <5 s, 5–<10 s, ≥10 s ---------------------------------------------
analysis_data_work <- analysis_data_work %>%
  mutate(
    G_SLS = case_when(
      Seisominen0 < 5                      ~ "<5 s",
      Seisominen0 >= 5 & Seisominen0 < 10  ~ "5–<10 s",
      Seisominen0 >= 10                    ~ "≥10 s",
      TRUE ~ NA_character_
    ),
    G_SLS = factor(G_SLS, levels = c("<5 s", "5–<10 s", "≥10 s"))
  )

tab_SLS <- analysis_data_work %>%
  filter(!is.na(FOF_status), !is.na(G_SLS)) %>%
  count(G_SLS, FOF_status) %>%
  group_by(G_SLS) %>%
  mutate(total_in_G = sum(n)) %>%
  ungroup() %>%
  mutate(flag_n_lt30 = n < 30)

tab_SLS

## (Valinnainen) yhdistä esim. kaksi parasta tasoryhmää
analysis_data_work <- analysis_data_work %>%
  mutate(
    G_SLS2 = fct_collapse(
      G_SLS,
      "<5 s"        = "<5 s",
      "≥5 s"        = c("5–<10 s", "≥10 s")
    )
  )

analysis_data_work %>%
  filter(!is.na(FOF_status), !is.na(G_SLS2)) %>%
  count(G_SLS2, FOF_status)

## FTSST: luodaan sekuntimuuttuja ja tertiilit ----------------------------
analysis_data_work <- analysis_data_work %>%
  mutate(
    FTSST0_sec = -Tuoli0   # nyt suurempi arvo = hitaampi (huonompi)
  )

quantile(analysis_data_work$FTSST0_sec, probs = c(1/3, 2/3), na.rm = TRUE)

q_FTSST <- quantile(analysis_data_work$FTSST0_sec,
                    probs = c(1/3, 2/3),
                    na.rm = TRUE)

analysis_data_work <- analysis_data_work %>%
  mutate(
    G_FTSST = case_when(
      FTSST0_sec <= q_FTSST[1]               ~ "fastest (best)",
      FTSST0_sec >  q_FTSST[1] & FTSST0_sec <= q_FTSST[2] ~ "intermediate",
      FTSST0_sec >  q_FTSST[2]               ~ "slowest (worst)",
      TRUE ~ NA_character_
    ),
    G_FTSST = factor(G_FTSST,
                     levels = c("slowest (worst)", "intermediate", "fastest (best)"))
  )

tab_FTSST <- analysis_data_work %>%
  filter(!is.na(FOF_status), !is.na(G_FTSST)) %>%
  count(G_FTSST, FOF_status) %>%
  group_by(G_FTSST) %>%
  mutate(total_in_G = sum(n)) %>%
  ungroup() %>%
  mutate(flag_n_lt30 = n < 30)

tab_FTSST

## (Valinnainen) kaksi luokkaa: hitaimmat vs muut -------------------------
analysis_data_work <- analysis_data_work %>%
  mutate(
    G_FTSST2 = fct_collapse(
      G_FTSST,
      "slowest third" = "slowest (worst)",
      "middle–fast"   = c("intermediate", "fastest (best)")
    )
  )

analysis_data_work %>%
  filter(!is.na(FOF_status), !is.na(G_FTSST2)) %>%
  count(G_FTSST2, FOF_status)


## STEP 4: ANCOVA-moderointi FOF x G_MWS jne. --------------------------

options(contrasts = c("contr.sum", "contr.poly"))

run_ancova_moderation <- function(data,
                                  G_var,          # esim. "G_MWS"
                                  delta_var,      # esim. "DeltaComposite"
                                  baseline_var,   # esim. "Composite0"
                                  outcome_label,  # tekstitunniste
                                  subgroup_label  # tekstitunniste (MWS / SLS / FTSST)
) {
  # Valitaan kovariaatit: käytetään Sex_factor jos olemassa, muuten Sex
  sex_var <- if ("Sex_factor" %in% names(data)) "Sex_factor" else "Sex"
  
  df <- data %>%
    select(FOF_status, all_of(c(G_var, delta_var, baseline_var, "Age", sex_var))) %>%
    filter(
      !is.na(FOF_status),
      !is.na(.data[[G_var]]),
      !is.na(.data[[delta_var]]),
      !is.na(.data[[baseline_var]]),
      !is.na(Age),
      !is.na(.data[[sex_var]])
    )
  
  formula_txt <- paste0(
    delta_var, " ~ FOF_status * ", G_var, " + ", baseline_var, " + Age + ", sex_var
  )
  form <- as.formula(formula_txt)
  
  fit <- lm(form, data = df)
  
  # Type III -testit
  anova_type3 <- car::Anova(fit, type = 3) %>%
    broom::tidy()
  
  # Johdetut marginaalikeskiarvot Delta: FOF_status x G
  emm <- emmeans::emmeans(fit, specs = "FOF_status", by = G_var)
  
  emm_df <- broom::tidy(emm) %>%
    mutate(
      outcome  = outcome_label,
      subgroup = subgroup_label
    )
  
  # Non-FOF – FOF -kontrastit kunkin G-tason sisällä
  contrast_df <- emmeans::contrast(
    emm,
    method = list("non-FOF minus FOF" = c(1, -1))
  ) %>%
    broom::tidy() %>%
    mutate(
      outcome  = outcome_label,
      subgroup = subgroup_label
    )
  
  # Deskriptiot DeltaOutcome FOF x G -soluissa
  desc_by_cell <- df %>%
    group_by(
      FOF_status,
      G = .data[[G_var]]
    ) %>%
    summarise(
      n          = n(),
      mean_delta = mean(.data[[delta_var]], na.rm = TRUE),
      sd_delta   = sd(.data[[delta_var]], na.rm = TRUE),
      .groups    = "drop"
    ) %>%
    mutate(
      outcome  = outcome_label,
      subgroup = subgroup_label
    )
  
  # Piirretään kuva: keskiarvot ja SE DeltaOutcome FOF_status x G
  p <- ggplot(df,
              aes(
                x     = .data[[G_var]],
                y     = .data[[delta_var]],
                color = FOF_status,
                group = FOF_status
              )) +
    stat_summary(fun.data = mean_se,
                 position = position_dodge(width = 0.3)) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    labs(
      title = paste0("Change in ", outcome_label,
                     " by FOF and ", subgroup_label, " subgroup"),
      x     = subgroup_label,
      y     = paste0(delta_var, " (follow-up minus baseline)"),
      color = "FOF status"
    ) +
    theme_minimal()
  
  list(
    data_used     = df,
    model         = fit,
    anova_type3   = anova_type3,
    emm_means     = emm_df,
    contrasts     = contrast_df,
    desc_by_cell  = desc_by_cell,
    plot          = p
  )
}


interpret_contrasts_generic <- function(tab, G_name, outcome_label,
                                        rope_width = 0.10) {
  tab %>%
    mutate(
      category = case_when(
        p.value < 0.05 & estimate > 0 ~ "sig_positive",
        p.value < 0.05 & estimate < 0 ~ "sig_negative",
        p.value >= 0.05 &
          conf.low > -rope_width &
          conf.high < rope_width      ~ "ns_narrow",
        TRUE                          ~ "ns_wide"
      ),
      verbal = case_when(
        category == "sig_positive" ~ paste0(
          "In subgroup ", .data[[G_name]],
          ", non-FOF showed greater improvement in ", outcome_label,
          " (difference ", round(estimate, 2),
          ", 95% CI ", round(conf.low, 2), " to ", round(conf.high, 2),
          ", p = ", signif(p.value, 2), ")."
        ),
        category == "sig_negative" ~ paste0(
          "In subgroup ", .data[[G_name]],
          ", participants with fear of falling improved more in ", outcome_label,
          " (difference ", round(estimate, 2),
          ", 95% CI ", round(conf.low, 2), " to ", round(conf.high, 2),
          ", p = ", signif(p.value, 2), ")."
        ),
        category == "ns_narrow" ~ paste0(
          "In subgroup ", .data[[G_name]],
          ", there was little to no difference in change in ", outcome_label,
          " between non-FOF and FOF (difference ", round(estimate, 2),
          ", 95% CI ", round(conf.low, 2), " to ", round(conf.high, 2),
          ", p = ", signif(p.value, 2),
          "; CI suggests any group difference is small)."
        ),
        category == "ns_wide" ~ paste0(
          "In subgroup ", .data[[G_name]],
          ", the difference in change in ", outcome_label,
          " between non-FOF and FOF was statistically non-significant (difference ",
          round(estimate, 2), ", 95% CI ", round(conf.low, 2), " to ",
          round(conf.high, 2), ", p = ", signif(p.value, 2),
          "), and the wide confidence interval indicates substantial uncertainty."
        ),
        TRUE ~ NA_character_
      )
    )
}

## a) DeltaComposite ~ FOF * G_MWS1 + Composite0 + Age + Sex

res_MWS1_Composite <- run_ancova_moderation(
  data           = analysis_data_work,
  G_var          = "G_MWS1",
  delta_var      = "DeltaComposite",
  baseline_var   = "Composite0",
  outcome_label  = "Composite PBT",
  subgroup_label = "MWS at baseline (<1.0 vs ≥1.0 m/s)"
)

res_MWS1_Composite$anova_type3
res_MWS1_Composite$contrasts
res_MWS1_Composite$plot

## b) Delta_MWS ~ FOF * G_MWS1 + MWS

res_MWS1_MWS <- run_ancova_moderation(
  data           = analysis_data_work,
  G_var          = "G_MWS1",
  delta_var      = "Delta_MWS",
  baseline_var   = "kavelynopeus_m_sek0",
  outcome_label  = "maximal walking speed",
  subgroup_label = "MWS at baseline (<1.0 vs ≥1.0 m/s)"
)

res_MWS1_MWS$anova_type3
res_MWS1_MWS$contrasts
res_MWS1_MWS$plot



## DeltaComposite ~ FOF * G_MWS2 + Composite0 + Age + Sex
res_MWS_Composite <- run_ancova_moderation(
  data           = analysis_data_work,
  G_var          = "G_MWS2",
  delta_var      = "DeltaComposite",
  baseline_var   = "Composite0",
  outcome_label  = "Composite PBT",
  subgroup_label = "MWS at baseline (<1.3 vs ≥1.3 m/s)"
)

res_MWS_Composite$anova_type3
res_MWS_Composite$contrasts
res_MWS_Composite$plot

## Delta_MWS ~ FOF * G_MWS2 + MWS0 + Age + Sex
res_MWS_MWS <- run_ancova_moderation(
  data           = analysis_data_work,
  G_var          = "G_MWS2",
  delta_var      = "Delta_MWS",
  baseline_var   = "kavelynopeus_m_sek0",
  outcome_label  = "maximal walking speed",
  subgroup_label = "MWS at baseline (<1.3 vs ≥1.3 m/s)"
)

res_MWS_MWS$anova_type3
res_MWS_MWS$contrasts
res_MWS_MWS$plot

## a) DeltaComposite ~ FOF * G_SLS + Composite0 + Age + Sex
res_SLS_Composite <- run_ancova_moderation(
  data          = analysis_data_work,
  G_var         = "G_SLS",
  delta_var     = "DeltaComposite",
  baseline_var  = "Composite0",
  outcome_label = "Composite PBT",
  subgroup_label = "SLS at baseline"
)

res_SLS_Composite$anova_type3
res_SLS_Composite$contrasts
res_SLS_Composite$plot

## b) Delta_SLS ~ FOF * G_SLS + SLS0 + Age + Sex
res_SLS_SLS <- run_ancova_moderation(
  data          = analysis_data_work,
  G_var         = "G_SLS",
  delta_var     = "Delta_SLS",
  baseline_var  = "Seisominen0",
  outcome_label = "single-leg stance",
  subgroup_label = "SLS at baseline"
)

res_SLS_SLS$anova_type3
res_SLS_SLS$contrasts
res_SLS_SLS$plot

## a) DeltaComposite ~ FOF * G_FTSST + Composite0 + Age + Sex

res_FTSST_Composite <- run_ancova_moderation(
  data          = analysis_data_work,
  G_var         = "G_FTSST",
  delta_var     = "DeltaComposite",
  baseline_var  = "Composite0",
  outcome_label = "Composite PBT",
  subgroup_label = "FTSST at baseline"
)

res_FTSST_Composite$anova_type3
res_FTSST_Composite$contrasts
res_FTSST_Composite$plot

## b) Delta_FTSST ~ FOF * G_FTSST + FTSST0_sec + Age + Sex

res_FTSST_FTSST <- run_ancova_moderation(
  data          = analysis_data_work,
  G_var         = "G_FTSST",
  delta_var     = "Delta_FTSST",
  baseline_var  = "FTSST0_sec",
  outcome_label = "five-times sit-to-stand",
  subgroup_label = "FTSST at baseline"
)

res_FTSST_FTSST$anova_type3
res_FTSST_FTSST$contrasts
res_FTSST_FTSST$plot

## MWS – Composite PBT, kontrastit + 95 % CI -------------------------------

mws1_composite_tab <- res_MWS1_Composite$contrasts %>%
  transmute(
    G_MWS1,
    contrast,
    estimate,
    std.error,
    df,
    conf.low  = estimate - qt(0.975, df) * std.error,
    conf.high = estimate + qt(0.975, df) * std.error,
    p.value
  )

mws1_comp_interpret <- interpret_contrasts_generic(
  mws1_composite_tab,
  G_name        = "G_MWS1",
  outcome_label = "composite physical performance"
)
mws1_comp_interpret %>%
  dplyr::select(G_MWS1, estimate, conf.low, conf.high, p.value, category, verbal)

## MWS – Delta_MWS, kontrastit + 95 % CI -----------------------------------

mws1_own_tab <- res_MWS1_MWS$contrasts %>%
  dplyr::transmute(
    G_MWS1,
    contrast,
    estimate,
    std.error,
    df,
    conf.low  = estimate - qt(0.975, df) * std.error,
    conf.high = estimate + qt(0.975, df) * std.error,
    p.value
  )

mws1_own_interpret <- interpret_contrasts_generic(
  mws1_own_tab,
  G_name       = "G_MWS1",
  outcome_label = "maximal walking speed"
)
mws1_own_interpret %>%
  dplyr::select(G_MWS1, estimate, conf.low, conf.high, p.value, category, verbal)


## MWS – Composite PBT, kontrastit + 95 % CI -------------------------------

mws_composite_tab <- res_MWS_Composite$contrasts %>%
  dplyr::transmute(
    G_MWS2,
    contrast,
    estimate,
    std.error,
    df,
    conf.low  = estimate - qt(0.975, df) * std.error,
    conf.high = estimate + qt(0.975, df) * std.error,
    p.value
  ) %>%
  dplyr::arrange(G_MWS2)

mws_composite_tab

## MWS – Delta_MWS, kontrastit + 95 % CI -----------------------------------
mws_own_tab <- res_MWS_MWS$contrasts %>%
  dplyr::transmute(
    G_MWS2,
    contrast,
    estimate,
    std.error,
    df,
    conf.low  = estimate - qt(0.975, df) * std.error,
    conf.high = estimate + qt(0.975, df) * std.error,
    p.value
  ) %>%
  dplyr::arrange(G_MWS2)

mws_own_tab

## Composite PBT, MWS-ryhmät
mws_comp_interpret <- interpret_contrasts_generic(
  mws_composite_tab,
  G_name       = "G_MWS2",
  outcome_label = "composite physical performance"
)

mws_comp_interpret %>%
  dplyr::select(G_MWS2, estimate, conf.low, conf.high, p.value, category, verbal)

## Delta_MWS, MWS-ryhmät
mws_own_interpret <- interpret_contrasts_generic(
  mws_own_tab,
  G_name       = "G_MWS2",
  outcome_label = "maximal walking speed"
)

mws_own_interpret %>%
  dplyr::select(G_MWS2, estimate, conf.low, conf.high, p.value, category, verbal)


## SLS – Composite PBT, kontrastit + 95 % CI -------------------------------
sls_composite_tab <- res_SLS_Composite$contrasts %>%
  dplyr::transmute(
    G_SLS,
    contrast,
    estimate,
    std.error,
    df,
    conf.low  = estimate - qt(0.975, df) * std.error,
    conf.high = estimate + qt(0.975, df) * std.error,
    p.value
  ) %>%
  dplyr::arrange(G_SLS)

sls_composite_tab


## SLS – Delta_SLS, kontrastit + 95 % CI -----------------------------------
sls_own_tab <- res_SLS_SLS$contrasts %>%
  dplyr::transmute(
    G_SLS,
    contrast,
    estimate,
    std.error,
    df,
    conf.low  = estimate - qt(0.975, df) * std.error,
    conf.high = estimate + qt(0.975, df) * std.error,
    p.value
  ) %>%
  dplyr::arrange(G_SLS)

sls_own_tab


## Composite PBT, SLS-ryhmät
sls_comp_interpret <- interpret_contrasts_generic(
  sls_composite_tab,
  G_name       = "G_SLS",
  outcome_label = "composite physical performance"
)

sls_comp_interpret %>%
  dplyr::select(G_SLS, estimate, conf.low, conf.high, p.value, category, verbal)

## Delta_SLS, SLS-ryhmät
sls_own_interpret <- interpret_contrasts_generic(
  sls_own_tab,
  G_name       = "G_SLS",
  outcome_label = "single-leg stance performance"
)

sls_own_interpret %>%
  dplyr::select(G_SLS, estimate, conf.low, conf.high, p.value, category, verbal)



## (a) Composite PBT -muutos FTSST-ryhmittäin ------------------------------
fts_composite_tab <- res_FTSST_Composite$contrasts %>%
  dplyr::transmute(
    G_FTSST,
    contrast,
    estimate,
    std.error,
    df,
    ## 95 % CI lasketaan t-kertointa käyttäen
    conf.low  = estimate - qt(0.975, df) * std.error,
    conf.high = estimate + qt(0.975, df) * std.error,
    p.value
  ) %>%
  dplyr::arrange(G_FTSST)

fts_composite_tab



## (b) FTSST-itse (Delta_FTSST) -------------------------------------------
fts_own_tab <- res_FTSST_FTSST$contrasts %>%
  dplyr::transmute(
    G_FTSST,
    contrast,
    estimate,
    std.error,
    df,
    conf.low  = estimate - qt(0.975, df) * std.error,
    conf.high = estimate + qt(0.975, df) * std.error,
    p.value
  ) %>%
  dplyr::arrange(G_FTSST)

fts_own_tab


## Tulkinta-apufunktio FTSST-ryhmien kontrasteille ------------------------

interpret_fts_contrasts <- function(tab, outcome_label,
                                    rope_width = 0.10) {
  tab %>%
    mutate(
      category = case_when(
        p.value < 0.05 & estimate > 0 ~ "sig_positive",
        p.value < 0.05 & estimate < 0 ~ "sig_negative",
        p.value >= 0.05 &
          conf.low > -rope_width &
          conf.high < rope_width      ~ "ns_narrow",
        TRUE                          ~ "ns_wide"
      ),
      verbal = case_when(
        category == "sig_positive" ~ paste0(
          "In FTSST group ", G_FTSST,
          ", non-FOF showed greater improvement in ", outcome_label,
          " (difference ", round(estimate, 2),
          ", 95% CI ", round(conf.low, 2), " to ", round(conf.high, 2),
          ", p = ", signif(p.value, 2), ")."
        ),
        category == "sig_negative" ~ paste0(
          "In FTSST group ", G_FTSST,
          ", participants with fear of falling improved more in ", outcome_label,
          " (difference ", round(estimate, 2),
          ", 95% CI ", round(conf.low, 2), " to ", round(conf.high, 2),
          ", p = ", signif(p.value, 2), ")."
        ),
        category == "ns_narrow" ~ paste0(
          "In FTSST group ", G_FTSST,
          ", there was little to no difference in change in ", outcome_label,
          " between non-FOF and FOF (difference ", round(estimate, 2),
          ", 95% CI ", round(conf.low, 2), " to ", round(conf.high, 2),
          ", p = ", signif(p.value, 2),
          "; CI suggests that any group difference is small)."
        ),
        category == "ns_wide" ~ paste0(
          "In FTSST group ", G_FTSST,
          ", the difference in change in ", outcome_label,
          " between non-FOF and FOF was statistically non-significant (difference ",
          round(estimate, 2), ", 95% CI ", round(conf.low, 2), " to ",
          round(conf.high, 2), ", p = ", signif(p.value, 2),
          "), but the wide confidence interval indicates substantial uncertainty."
        ),
        TRUE ~ NA_character_
      )
    )
}

## Composite PBT
fts_comp_interpret <- interpret_fts_contrasts(
  fts_composite_tab,
  outcome_label = "composite physical performance"
)

fts_comp_interpret %>%
  dplyr::select(G_FTSST, estimate, conf.low, conf.high, p.value, category, verbal)

## FTSST-itse
fts_own_interpret <- interpret_fts_contrasts(
  fts_own_tab,
  outcome_label = "five-times sit-to-stand performance"
)

fts_own_interpret %>%
  dplyr::select(G_FTSST, estimate, conf.low, conf.high, p.value, category, verbal)

## Composite PBT, MWS- ja SLS-ryhmät ---------------------------------------

mws_comp_interpret <- interpret_contrasts_generic(mws_composite_tab, "G_MWS2",
                                                  "composite physical performance")
sls_comp_interpret <- interpret_contrasts_generic(sls_composite_tab, "G_SLS",
                                                  "composite physical performance")
mws_comp_interpret %>%
  dplyr::select(G_MWS2, estimate, conf.low, conf.high, p.value, category, verbal)
sls_comp_interpret %>%
  dplyr::select(G_SLS, estimate, conf.low, conf.high, p.value, category, verbal)


## Kuvio A: DeltaComposite by FOF_status (boxplot) --------------------------

p_box_delta_comp <- ggplot(
  analysis_data_work,
  aes(x = FOF_status, y = DeltaComposite, fill = FOF_status)
) +
  geom_boxplot(alpha = 0.6, width = 0.5, outlier.alpha = 0.5) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(
    title = "Change in composite physical performance by FOF status",
    x     = "FOF status",
    y     = "DeltaComposite (follow-up minus baseline)"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    plot.title      = element_text(face = "bold")
  )

p_box_delta_comp

ggsave(
  filename = file.path(outputs_dir, "K7_box_DeltaComposite_FOF.png"),
  plot     = p_box_delta_comp,
  width    = 6,
  height   = 4,
  dpi      = 300
)


## Kuvio B: MWS2 x FOF, DeltaComposite -------------------------------------

p_mws_comp <- res_MWS_Composite$plot +
  labs(
    title = "Change in composite PBT by FOF and baseline MWS subgroup",
    x     = "Baseline MWS subgroup",
    y     = "DeltaComposite (follow-up minus baseline)",
    color = "FOF status"
  ) +
  theme_minimal() +
  theme(
    plot.title  = element_text(face = "bold"),
    axis.text.x = element_text(angle = 0, hjust = 0.5)
  )

p_mws_comp

ggsave(
  filename = file.path(outputs_dir, "K7_MWS_composite_interaction.png"),
  plot     = p_mws_comp,
  width    = 7,
  height   = 5,
  dpi      = 300
)


## Kuvio C: SLS x FOF, DeltaComposite --------------------------------------

p_sls_comp <- res_SLS_Composite$plot +
  labs(
    title = "Change in composite PBT by FOF and baseline SLS subgroup",
    x     = "Baseline SLS subgroup",
    y     = "DeltaComposite (follow-up minus baseline)",
    color = "FOF status"
  ) +
  theme_minimal() +
  theme(
    plot.title  = element_text(face = "bold"),
    axis.text.x = element_text(angle = 0, hjust = 0.5)
  )

p_sls_comp

ggsave(
  filename = file.path(outputs_dir, "K7_SLS_composite_interaction.png"),
  plot     = p_sls_comp,
  width    = 7,
  height   = 5,
  dpi      = 300
)


## Kuvio D: FTSST x FOF, DeltaComposite ------------------------------------

p_fts_comp <- res_FTSST_Composite$plot +
  labs(
    title = "Change in composite PBT by FOF and baseline FTSST subgroup",
    x     = "Baseline FTSST subgroup",
    y     = "DeltaComposite (follow-up minus baseline)",
    color = "FOF status"
  ) +
  theme_minimal() +
  theme(
    plot.title  = element_text(face = "bold"),
    axis.text.x = element_text(angle = 0, hjust = 0.5)
  )

p_fts_comp

ggsave(
  filename = file.path(outputs_dir, "K7_FTSST_composite_interaction.png"),
  plot     = p_fts_comp,
  width    = 7,
  height   = 5,
  dpi      = 300
)


## Apufunktio forest-kuville -----------------------------------------------

plot_forest_single <- function(tab, group_var, category_df = NULL,
                               title, y_lab) {
  df <- tab
  
  if (!is.null(category_df)) {
    df <- df %>%
      dplyr::left_join(
        category_df %>% dplyr::select(all_of(group_var), category),
        by = group_var
      )
  }
  
  df <- df %>%
    dplyr::mutate(
      group = forcats::fct_rev(factor(.data[[group_var]]))
    )
  
  ggplot(df, aes(x = estimate, y = group)) +
    geom_vline(xintercept = 0, linetype = "dashed") +
    geom_pointrange(
      aes(xmin = conf.low, xmax = conf.high, color = category),
      fatten = 1.2
    ) +
    labs(
      title = title,
      x     = "Difference in change (non-FOF minus FOF, 95% CI)",
      y     = y_lab,
      color = "Contrast category"
    ) +
    theme_minimal() +
    theme(
      plot.title  = element_text(face = "bold"),
      legend.position = "bottom"
    )
}


## Kuvio E1: Composite PBT, MWS-ryhmät -------------------------------------

p_mws_comp_forest <- plot_forest_single(
  tab         = mws_composite_tab,
  group_var   = "G_MWS2",
  category_df = mws_comp_interpret,
  title       = "Composite PBT: non-FOF minus FOF by baseline MWS subgroup",
  y_lab       = "Baseline MWS subgroup"
)

p_mws_comp_forest

ggsave(
  filename = file.path(outputs_dir, "K7_MWS_composite_forest.png"),
  plot     = p_mws_comp_forest,
  width    = 6,
  height   = 4,
  dpi      = 300
)


## Kuvio E2: Composite PBT, SLS-ryhmät -------------------------------------

p_sls_comp_forest <- plot_forest_single(
  tab         = sls_composite_tab,
  group_var   = "G_SLS",
  category_df = sls_comp_interpret,
  title       = "Composite PBT: non-FOF minus FOF by baseline SLS subgroup",
  y_lab       = "Baseline SLS subgroup"
)

p_sls_comp_forest

ggsave(
  filename = file.path(outputs_dir, "K7_SLS_comp_forest.png"),
  plot     = p_sls_comp_forest,
  width    = 6,
  height   = 4,
  dpi      = 300
)

## Kuvio E3: Composite PBT, FTSST-ryhmät -----------------------------------

p_fts_comp_forest <- plot_forest_single(
  tab         = fts_composite_tab,
  group_var   = "G_FTSST",
  category_df = fts_comp_interpret,
  title       = "Composite PBT: non-FOF minus FOF by baseline FTSST subgroup",
  y_lab       = "Baseline FTSST subgroup"
)

p_fts_comp_forest

ggsave(
  filename = file.path(outputs_dir, "K7_FTSST_comp_forest.png"),
  plot     = p_fts_comp_forest,
  width    = 6,
  height   = 4,
  dpi      = 300
)

## Kuvio F1: Delta_MWS, MWS-ryhmät ----------------------------------------

p_mws_own_forest <- plot_forest_single(
  tab         = mws_own_tab,
  group_var   = "G_MWS2",
  category_df = mws_own_interpret,
  title       = "Maximal walking speed: non-FOF minus FOF by baseline MWS subgroup",
  y_lab       = "Baseline MWS subgroup"
)

p_mws_own_forest

ggsave(
  filename = file.path(outputs_dir, "K7_MWS_own_forest.png"),
  plot     = p_mws_own_forest,
  width    = 6,
  height   = 4,
  dpi      = 300
)

## Kuvio F2: Delta_SLS, SLS-ryhmät -----------------------------------------

p_sls_own_forest <- plot_forest_single(
  tab         = sls_own_tab,
  group_var   = "G_SLS",
  category_df = sls_own_interpret,
  title       = "Single-leg stance: non-FOF minus FOF by baseline SLS subgroup",
  y_lab       = "Baseline SLS subgroup"
)

p_sls_own_forest

ggsave(
  filename = file.path(outputs_dir, "K7_SLS_own_forest.png"),
  plot     = p_sls_own_forest,
  width    = 6,
  height   = 4,
  dpi      = 300
)

## Kuvio F3: Delta_FTSST, FTSST-ryhmät -------------------------------------

p_fts_own_forest <- plot_forest_single(
  tab         = fts_own_tab,
  group_var   = "G_FTSST",
  category_df = fts_own_interpret,
  title       = "Five-times sit-to-stand: non-FOF minus FOF by baseline FTSST subgroup",
  y_lab       = "Baseline FTSST subgroup"
)

p_fts_own_forest

ggsave(
  filename = file.path(outputs_dir, "K7_FTSST_own_forest.png"),
  plot     = p_fts_own_forest,
  width    = 6,
  height   = 4,
  dpi      = 300
)

# 13. Manifestin päivitys: keskeiset kuvat K7-skriptistä --------------------

# Skriptin tunniste manifestia varten
script_label <- "K7"

# K7-skriptin tuottamat keskeiset kuvat (basename, ei koko polkua)
k7_plot_files <- c(
  "K7_box_DeltaComposite_FOF.png",
  "K7_MWS_composite_interaction.png",
  "K7_SLS_composite_interaction.png",
  "K7_FTSST_composite_interaction.png",
  "K7_MWS_composite_forest.png",
  "K7_SLS_comp_forest.png",
  "K7_FTSST_comp_forest.png",
  "K7_MWS_own_forest.png",
  "K7_SLS_own_forest.png",
  "K7_FTSST_own_forest.png"
)

# Lyhyet kuvaukset samoille riveille samassa järjestyksessä
k7_plot_descriptions <- c(
  "Change in composite physical performance by FOF status (boxplot)",
  "Change in composite PBT by FOF and baseline MWS subgroup (interaction plot)",
  "Change in composite PBT by FOF and baseline SLS subgroup (interaction plot)",
  "Change in composite PBT by FOF and baseline FTSST subgroup (interaction plot)",
  "Composite PBT: non-FOF minus FOF by baseline MWS subgroup (forest plot)",
  "Composite PBT: non-FOF minus FOF by baseline SLS subgroup (forest plot)",
  "Composite PBT: non-FOF minus FOF by baseline FTSST subgroup (forest plot)",
  "Maximal walking speed: non-FOF minus FOF by baseline MWS subgroup (forest plot)",
  "Single-leg stance: non-FOF minus FOF by baseline SLS subgroup (forest plot)",
  "Five-times sit-to-stand: non-FOF minus FOF by baseline FTSST subgroup (forest plot)"
)

# Rakennetaan manifestiin lisättävä data.frame
manifest_rows <- tibble(
  script     = script_label,
  type       = "plot",
  # Polku projektin tuloskansioon nähden, esim. "K7/K7_box_DeltaComposite_FOF.png"
  filename   = file.path(script_label, k7_plot_files),
  description = k7_plot_descriptions
)

# Varmista että manifest-kansio on olemassa
if (!dir.exists(manifest_dir)) {
  dir.create(manifest_dir, recursive = TRUE)
}

# Kirjoita tai appendaa manifest.csv
if (!file.exists(manifest_path)) {
  # Luodaan uusi manifest otsikkoriveineen
  write.table(
    manifest_rows,
    file      = manifest_path,
    sep       = ",",
    row.names = FALSE,
    col.names = TRUE,
    append    = FALSE,
    qmethod   = "double"
  )
} else {
  # Lisätään rivit olemassa olevaan manifestiin ilman otsikoita
  write.table(
    manifest_rows,
    file      = manifest_path,
    sep       = ",",
    row.names = FALSE,
    col.names = FALSE,
    append    = TRUE,
    qmethod   = "double"
  )
}

## =====================================================================
## K7: Manifest-päivitys – taulukot ja kuvat
## =====================================================================

script_label <- "K7"

## 1) Taulukot: tiedostopolut (oletus: CSV:t on jo kirjoitettu) -------

delta_desc_path      <- file.path(outputs_dir, "K7_delta_desc_by_FOF.csv")
cell_means_path      <- file.path(outputs_dir, "K7_cell_means_DeltaComposite_by_subgroup.csv")
ancova_type3_path    <- file.path(outputs_dir, "K7_ANCOVA_type3_all_models.csv")
contrasts_comp_path  <- file.path(outputs_dir, "K7_contrasts_CompositePBT_by_subgroups.csv")
contrasts_tests_path <- file.path(outputs_dir, "K7_contrasts_test_specific_by_subgroups.csv")
sample_sizes_path    <- file.path(outputs_dir, "K7_sample_sizes_by_subgroup.csv")

table_filenames <- c(
  file.path(script_label, basename(delta_desc_path)),
  file.path(script_label, basename(cell_means_path)),
  file.path(script_label, basename(ancova_type3_path)),
  file.path(script_label, basename(contrasts_comp_path)),
  file.path(script_label, basename(contrasts_tests_path)),
  file.path(script_label, basename(sample_sizes_path))
)

table_descriptions <- c(
  "Descriptive statistics for change variables (DeltaComposite, Delta_HGS, Delta_MWS, Delta_FTSST, Delta_SLS) by FOF status (n, mean, SD).",
  "Cell means for change in composite physical performance (DeltaComposite) by FOF status and baseline subgroups (MWS, SLS, FTSST).",
  "Type III ANCOVA results for all moderation models (MWS1, MWS2, SLS, FTSST; composite PBT and test-specific outcomes).",
  "Contrasts for change in composite physical performance (non-FOF minus FOF) by baseline subgroups (MWS, SLS, FTSST) with 95% CIs.",
  "Contrasts for test-specific changes (Delta_MWS, Delta_SLS, Delta_FTSST) by baseline subgroups (MWS, SLS, FTSST) with 95% CIs.",
  "Sample sizes for all FOF by subgroup combinations (MWS, SLS, FTSST; n and total per subgroup)."
)

## 2) Kuvat: tiedostonimet outputs_dir:ssä ------------------------------

plot_files <- c(
  "K7_box_DeltaComposite_FOF.png",
  "K7_MWS_composite_interaction.png",
  "K7_SLS_composite_interaction.png",
  "K7_FTSST_composite_interaction.png",
  "K7_MWS_composite_forest.png",
  "K7_SLS_comp_forest.png",
  "K7_FTSST_comp_forest.png",
  "K7_MWS_own_forest.png",
  "K7_SLS_own_forest.png",
  "K7_FTSST_own_forest.png"
)

plot_descriptions <- c(
  "Boxplot of change in composite physical performance (DeltaComposite) by FOF status.",
  "Interaction plot: change in composite PBT by FOF status and baseline MWS subgroup (<1.3 vs >=1.3 m/s).",
  "Interaction plot: change in composite PBT by FOF status and baseline SLS subgroup.",
  "Interaction plot: change in composite PBT by FOF status and baseline FTSST subgroup.",
  "Forest plot of contrasts in change in composite PBT (non-FOF minus FOF) by baseline MWS subgroup.",
  "Forest plot of contrasts in change in composite PBT (non-FOF minus FOF) by baseline SLS subgroup.",
  "Forest plot of contrasts in change in composite PBT (non-FOF minus FOF) by baseline FTSST subgroup.",
  "Forest plot of contrasts in change in maximal walking speed (Delta_MWS) by baseline MWS subgroup.",
  "Forest plot of contrasts in change in single-leg stance (Delta_SLS) by baseline SLS subgroup.",
  "Forest plot of contrasts in change in five-times sit-to-stand (Delta_FTSST) by baseline FTSST subgroup."
)

plot_filenames <- file.path(script_label, plot_files)

## 3) Yhdistä taulukot ja kuvat samaan manifest-data.frameen --------------

manifest_new <- dplyr::tibble(
  script     = script_label,
  type       = c(rep("table", length(table_filenames)),
                 rep("plot",  length(plot_filenames))),
  filename   = c(table_filenames, plot_filenames),
  description = c(table_descriptions, plot_descriptions)
)

## 4) Päivitä manifest_rows muistissa -----------------------------------

if (exists("manifest_rows")) {
  manifest_rows <- dplyr::bind_rows(manifest_rows, manifest_new)
} else {
  manifest_rows <- manifest_new
}

## 5) Kirjoita manifest.csv projektin manifest-kansioon -----------------

if (!dir.exists(manifest_dir)) {
  dir.create(manifest_dir, recursive = TRUE)
}

if (!file.exists(manifest_path)) {
  readr::write_csv(manifest_new, manifest_path)
} else {
  readr::write_csv(manifest_new, manifest_path,
                   append = TRUE, col_names = FALSE)
}


# End of K7.R