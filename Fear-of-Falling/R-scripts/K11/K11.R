# K11

# ==============================================================================

# ---------------------------------------------------------------
# 0. PACKAGES ---------------------------------------------------
# ---------------------------------------------------------------

library(dplyr)
library(tidyr)
library(ggplot2)
library(forcats)
library(broom)
library(car)       # Anova(type = "III")
library(emmeans)   # Estimated marginal means
library(effectsize)
library(mice)
library(knitr)
library(MASS)
library(scales)

set.seed(20251124)  # jos myöhemmin käytetään satunnaisuutta (esim. bootstrap)

# ==============================================================================
# ---------------------------------------------------------------
# 1: Load the dataset -------------------------------------------
# ---------------------------------------------------------------

file_path <- here::here("data", "external", "KaatumisenPelko.csv")

raw_data <- readr::read_csv(file_path, show_col_types = FALSE)

## Working copy so the original stays untouched
if (!exists("raw_data")) {
  stop("Object 'raw_data' not found. Please load your data as raw_data first.")
}

## Tee raaka- ja työkopio
analysis_data  <- raw_data
glimpse(analysis_data)
names(analysis_data)

# ---------------------------------------------------------------
# 2: Output-kansio K11:n alle ------------------------------------
# ---------------------------------------------------------------

## .../Fear-of-Falling/R-scripts/K11/outputs
outputs_dir <- here::here("R-scripts", "K11", "outputs")
if (!dir.exists(outputs_dir)) {
  dir.create(outputs_dir, recursive = TRUE)
}

## 2.1: --- Skriptin tunniste ---
script_label <- "K11"   

## 2.2: --- Erillinen manifest-kansio projektissa: ./manifest ------------------
# Projektin juurikansio oletetaan olevan .../Fear-of-Falling
manifest_dir <- here::here("manifest")
if (!dir.exists(manifest_dir)) {
  dir.create(manifest_dir, recursive = TRUE)
}
manifest_path <- file.path(manifest_dir, "manifest.csv")

# 2.3: --- Helper to save CSV + simple HTML table ------------------------------

save_table_csv_html <- function(df, basename,
                                out_dir = outputs_dir) {
  
  # Varmista, että kansio on olemassa
  if (!dir.exists(out_dir)) {
    dir.create(out_dir, recursive = TRUE)
  }
  
  csv_path  <- file.path(out_dir, paste0(basename, ".csv"))
  html_path <- file.path(out_dir, paste0(basename, ".html"))
  
  # CSV
  readr::write_csv(df, csv_path)
  
  # HTML-taulukko
  html_table <- knitr::kable(
    df, format = "html",
    table.attr = "border='1' style='border-collapse:collapse;'"
  )
  
  html_content <- paste0(
    "<html><head><meta charset='UTF-8'></head><body>",
    "<h3>", basename, "</h3>",
    html_table,
    "</body></html>"
  )
  
  writeLines(html_content, con = html_path)
  
  invisible(list(csv = csv_path, html = html_path))
}

# ---------------------------------------------------------------
# 3. DATA CHECKING ----------------------------------------------
# ---------------------------------------------------------------

# 3.1: Varmista että analysis_data on olemassa
if (!exists("analysis_data")) {
  stop("Objektia 'analysis_data' ei löytynyt. Lataa data ennen skriptin ajamista.")
}

# 3.2: Yleiskuva
names(analysis_data)
str(analysis_data)

# 3.3: Tarkennettu rakennekatsaus keskeisille muuttujille (muokkaa tarvittaessa)
analysis_data %>% 
  dplyr::select(
    age, sex, BMI, MOIindeksiindeksi, diabetes,
    kaatumisenpelkoOn,
    alzheimer, parkinson, AVH,
    ToimintaKykySummary0, ToimintaKykySummary2,
    dplyr::starts_with("Puristus"),
    dplyr::starts_with("kavely"),
    dplyr::starts_with("Tuoli"),
    dplyr::starts_with("Seisominen"),
    SRH = dplyr::any_of("SRH"),
    koettuterveydentila = dplyr::any_of("koettuterveydentila"),
    oma_arvio_liikuntakyky = dplyr::any_of("oma_arvio_liikuntakyky"),
    PainVAS0 = dplyr::any_of("PainVAS0")
  ) %>% 
  glimpse()

# ---------------------------------------------------------------
# 4. RECODINGS --------------------------------------------------
# ---------------------------------------------------------------

analysis_data_rec <- analysis_data %>%
  mutate(
    # FOF-status
    FOF_status = factor(
      kaatumisenpelkoOn,
      levels = c(0, 1),
      labels = c("nonFOF", "FOF")
    ),
    
    # Ikäluokat
    AgeClass = case_when(
      age < 65                 ~ "65_74",
      age >= 65 & age <= 74    ~ "65_74",
      age >= 75 & age <= 84    ~ "75_84",
      age >= 85                ~ "85plus",
      TRUE                     ~ NA_character_
    ),
    AgeClass = factor(AgeClass, levels = c("65_74", "75_84", "85plus"), ordered = TRUE),
    
    # Neuro
    Neuro_any_num = if_else(
      (alzheimer == 1 | parkinson == 1 | AVH == 1),
      1L, 0L,
      missing = 0L
    ),
    # AVH = aivoverenkiertohäiriö
    AVH_factor = factor(
      AVH,
      levels = c(0, 1),
      labels = c("nonAVH", "AVH")
    ),  
    Neuro_any = factor(
      Neuro_any_num,
      levels = c(0, 1),
      labels = c("no_neuro", "neuro")
    ),
    
    # Sukupuoli: 0 = female, 1 = male
    sex_factor = factor(
      sex,
      levels = c(0, 1),
      labels = c("female", "male")
    )
  )

# 4a. Frekvenssit ------------------------------------------------

# Pääjakaumat
analysis_data_rec %>%
  count(FOF_status)

analysis_data_rec %>%
  count(AgeClass)

analysis_data_rec %>%
  count(Neuro_any)

analysis_data_rec %>%
  count(AVH_factor)

# Ristiintaulukot
analysis_data_rec %>%
  count(FOF_status, AgeClass) %>%
  arrange(AgeClass,FOF_status)

analysis_data_rec %>%
  count(FOF_status, AgeClass, Neuro_any) %>%
  arrange(AgeClass,FOF_status, Neuro_any)

# ---------------------------------------------------------------
# 5.Outcome-muuttujat: DeltaComposite ja Delta-PBT:t-------------
# ---------------------------------------------------------------

# 5.1 Composite-muutos

# Tarkistetaan ensin, mitä sarakkeita on
has_DeltaComposite    <- "DeltaComposite" %in% names(analysis_data_rec)
has_DeltaComposite_Z  <- "Delta_Composite_Z" %in% names(analysis_data_rec)

if (has_DeltaComposite) {
  # Käytä valmista saraketta sellaisenaan
  message("Using existing DeltaComposite column.")
  
} else if (has_DeltaComposite_Z) {
  # Luo DeltaComposite tästä
  analysis_data_rec <- analysis_data_rec %>%
    mutate(DeltaComposite = Delta_Composite_Z)
  message("Created DeltaComposite from Delta_Composite_Z.")
  
} else {
  # Laske muutos suoraan
  analysis_data_rec <- analysis_data_rec %>%
    mutate(DeltaComposite = ToimintaKykySummary2 - ToimintaKykySummary0)
  message("Created DeltaComposite as ToimintaKykySummary2 - ToimintaKykySummary0.")
}


# 5.2 PBT-muutokset (HGS, MWS, FTSST, SLS)

analysis_data_rec <- analysis_data_rec %>%
  mutate(
    # HGS: positiivinen = parannus
    Delta_HGS = case_when(
      "PuristusMuutos" %in% names(analysis_data_rec) ~ PuristusMuutos,
      "Puristus0" %in% names(analysis_data_rec) & "Puristus2" %in% names(analysis_data_rec) ~ 
        Puristus2 - Puristus0,
      TRUE ~ NA_real_
    ),
    
    # MWS: positiivinen = parannus
    Delta_MWS = case_when(
      "Kävelymuutos" %in% names(analysis_data_rec) ~ Kävelymuutos,
      "kavelynopeus_m_sek0" %in% names(analysis_data_rec) & "kavelynopeus_m_sek2" %in% names(analysis_data_rec) ~
        kavelynopeus_m_sek2 - kavelynopeus_m_sek0,
      TRUE ~ NA_real_
    ),
    
    # FTSST (Tuoli): pienempi aika = parempi -> muutoksen merkki käännetään
    Delta_FTSST = case_when(
      "Tuolimuutos" %in% names(analysis_data_rec) ~ Tuolimuutos * (-1),
      "Tuoli0" %in% names(analysis_data_rec) & "Tuoli2" %in% names(analysis_data_rec) ~
        (Tuoli0 - Tuoli2),  # positiivinen = nopeampi testi
      TRUE ~ NA_real_
    ),
    
    # SLS (Seisominen): suurempi aika = parempi
    Delta_SLS = case_when(
      "TasapainoMuutos" %in% names(analysis_data_rec) ~ TasapainoMuutos,
      "Seisominen0" %in% names(analysis_data_rec) & "Seisominen2" %in% names(analysis_data_rec) ~
        Seisominen2 - Seisominen0,
      TRUE ~ NA_real_
    )
  )

# 5.3: Alias-sarakkeet analyysia varten --------------------------

analysis_data_rec <- analysis_data_rec %>%
  mutate(
    # Baseline-komposiitti
    Composite_Z0      = ToimintaKykySummary0,
    # Muutoskomposiitti; aiemmin loit jo DeltaComposite:n
    Delta_Composite_Z = DeltaComposite,
    # Sukupuoli faktoriksi
    sex = factor(
      sex,
      levels = c(0, 1),
      labels = c("female", "male")
    ),
    # MOI = Mikkelin osteoporoosi-indeksi (osteoporoosiriskin mittari)
    MOI_score = MOIindeksiindeksi
  )


# 5.4: Analyysidatan rajaus ja täydelliset havainnot --------------

dat_fof <- analysis_data_rec %>%
  dplyr::select(
    id,
    Delta_Composite_Z,
    Composite_Z0,
    age,
    BMI,
    sex,
   FOF_status,
    # MOI osteoporoosiriskin mittarina
    MOI_score,
    # komorbiditeetit ja muut kliiniset kovariaatit
    diabetes,
    alzheimer,
    parkinson,
    AVH,
    previous_falls = kaatuminen,
    psych_score    = mieliala
  ) %>%
  filter(
    !is.na(Delta_Composite_Z),
    !is.na(Composite_Z0),
    !is.na(age),
    !is.na(BMI),
    !is.na(sex),
    !is.na(FOF_status)
  ) %>%
  mutate(
   FOF_status = relevel(FOF_status, ref = "nonFOF")
  )

str(dat_fof)


# ---------------------------------------------------------------
# 6. FOF itsenäisenä prognostisena markkerina--------------------
# ---------------------------------------------------------------

# 6.1: R-mallipohjat (lineaarinen regressio)

mod_base <- lm(
  Delta_Composite_Z ~ FOF_status + Composite_Z0 + age + BMI + sex,
  data = dat_fof
)

summary(mod_base)

tab_base <- broom::tidy(mod_base, conf.int = TRUE)
fof_base <- tab_base %>% 
  dplyr::filter(grepl("^FOF_status", term))


# 6.2 Laajennettu malli: MOI erillisenä osteoporoosiriskin kovariaattina

mod_ext <- lm(
  Delta_Composite_Z ~ FOF_status + Composite_Z0 + age + BMI + sex +
    MOI_score +               # osteoporoosiriskin indeksi (Mikkelin MOI)
    diabetes + alzheimer +
    parkinson + AVH +
    previous_falls +          # kaatumishistoria
    psych_score,              # mieliala / psyykkinen kuormitus
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

# ---------------------------------------------------------------
# 7. FOF-efektin vertailu perus vs laajennettu malli:------------
# ---------------------------------------------------------------

library(broom)
tab_base <- tidy(mod_base, conf.int = TRUE)
tab_ext  <- tidy(mod_ext,  conf.int = TRUE)

# FOF-kertoimet ja LV:t rinnakkain
fof_base <- subset(tab_base, term == "FOF_status1")
fof_ext  <- subset(tab_ext,  term == "FOF_status1")
fof_base
fof_ext


standardize_parameters(mod_ext)


# 7.1: Missing data: MICE workflow -------------------------------

# Valitse MICE-imputointiin mukaan otettavat muuttujat
required_columns <- c(
  "Delta_Composite_Z",
  "FOF_status",
  "Composite_Z0",
  "age",
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

mice_data <- dat_fof[, required_columns]

# Puuttuvuuskuvio
md_pattern <- mice::md.pattern(mice_data, plot = FALSE)
md_pattern_df <- as.data.frame(md_pattern)
save_table_csv_html(md_pattern_df, "missing_data_pattern")

# Alkuasetukset: predictorMatrix
ini  <- mice::mice(mice_data, m = 1, maxit = 0, printFlag = FALSE)
pred <- ini$predictorMatrix

# Ei imputoida lopputulosta (Delta_Composite_Z)
pred["Delta_Composite_Z", ] <- 0

# Varsinainen imputointi, esim. 20 imputoitua datasettiä
imp <- mice::mice(
  mice_data,
  m = 20,
  predictorMatrix = pred,
  seed = 20251124,
  printFlag = FALSE
)

# Perusmalli imputoidussa datassa
fit_base <- with(imp, lm(Delta_Composite_Z ~ FOF_status + Composite_Z0 + age + BMI + sex))
pool(fit_base)

# Laajennettu malli imputoidussa datassa
fit_ext <- with(imp, lm(
  Delta_Composite_Z ~ FOF_status + Composite_Z0 + age + BMI + sex +
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

# Tallennus CSV + HTML
save_table_csv_html(tab_base_imp, "mice_pooled_model_base")
save_table_csv_html(tab_ext_imp,  "mice_pooled_model_extended")

tab_base_imp %>% dplyr::filter(term == "FOF_status1")
tab_ext_imp  %>% dplyr::filter(term == "FOF_status1")

# ---------------------------------------------------------------
# 8. Responder- / ordinal-analyysi kliinisesti merkittävästä parantumisesta
# ---------------------------------------------------------------

# 8.1: R-mallipohjat (logistinen + ordinaalinen)

## Muodostetaan responder-muuttuja (kynnys valittavissa, esim. 0.3 SD):
delta_cut <- 0.3  # valitse kliinisesti perusteltu raja
dat_fof$responder <- ifelse(dat_fof$Delta_Composite_Z >= delta_cut, 1, 0)
dat_fof$responder <- factor(dat_fof$responder, levels = c(0, 1))  # 0 = ei-responder, 1 = responder

# Logistinen regressio:
mod_resp <- glm(
  responder ~ FOF_status + Composite_Z0 + age + BMI + sex,
  data   = dat_fof,
  family = binomial(link = "logit")
)

summary(mod_resp)

tab_resp <- tidy(mod_resp, conf.int = TRUE, exponentiate = TRUE)
tab_resp  # nyt kertoimet ovat OR-arvoja

# 8.2. Ordinaalinen analyysi (heikentynyt – stabiili – parantunut)

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
  change_cat ~ FOF_status + Composite_Z0 + age + BMI + sex,
  data = dat_fof,
  Hess = TRUE
)

summary(mod_ord)

# Kertoimet ja luottamusvälit OR-muodossa
(ctab <- coef(summary(mod_ord)))

ci <- confint(mod_ord)  # luottamusvälit log-asteikolla
OR  <- exp(cbind(Estimate = coef(mod_ord), ci))
OR  # hae tästä FOF-rivi

# ---------------------------------------------------------------
# 9. Ikäkvartiilit dataan
# ---------------------------------------------------------------

## 9.1: Ikäkvartiilit (4 yhtä suurta ryhmää havaintomäärän mukaan)
dat_fof <- dat_fof %>%
  mutate(
    age_quartile = dplyr::ntile(age, 4),           # arvot 1,2,3,4
    age_quartile = factor(
      age_quartile,
      levels = 1:4,
      labels = c("Q1 (nuorimmat)", 
                 "Q2", 
                 "Q3", 
                 "Q4 (vanhimmat)")
    )
  )

dat_fof %>% 
  group_by(age_quartile) %>% 
  summarise(
    n   = n(),
    min_age = min(age),
    median_age = median(age),
    max_age = max(age)
  )

## 9.2. Responder-osuuksien laskeminen ikäkvartiileittain ja FOF-statuksen mukaan

responder_by_age_fof <- dat_fof %>%
  group_by(age_quartile, FOF_status) %>%
  summarise(
    n_total     = n(),
    n_resp      = sum(as.numeric(as.character(responder)) == 1, na.rm = TRUE),
    prop_resp   = n_resp / n_total
  ) %>%
  ungroup()

responder_by_age_fof

## 9.3: Yksinkertaiset p-arvot kvartiileittain (FOF vs nonFOF)

p_by_quartile <- dat_fof %>%
  group_by(age_quartile) %>%
  group_modify(~{
    tab <- table(.x$responder, .x$FOF_status)
    
    # Jos solut pieniä → Fisher; muuten khii-neliö
    test <- if (any(tab < 5)) {
      fisher.test(tab)
    } else {
      chisq.test(tab, correct = FALSE)
    }
    
    tibble(
      age_quartile = unique(.x$age_quartile),
      test_type    = if (any(tab < 5)) "Fisher" else "Chi-square",
      p_value      = test$p.value
    )
  }) %>%
  ungroup()

p_by_quartile


## 9.4: Malli, jossa mukana interaktio: FOF_status * age_quartile

mod_resp_age_int <- glm(
  responder ~ FOF_status * age_quartile + Composite_Z0 + age + BMI + sex,
  data   = dat_fof,
  family = binomial(link = "logit")
)

# A) Globaalit p-arvot (mm. interaktio: muuttuuko FOF-efekti iän mukaan?)
Anova(mod_resp_age_int, type = "III")

# B) FOF vs nonFOF -vertailu kussakin ikäkvartiilissa (OR + p-arvo)
emm_fof_by_age <- emmeans(
  mod_resp_age_int,
  ~ FOF_status | age_quartile,
  type = "response"     # antaa myös todennäköisyyksiä
)

contr_fof_by_age <- contrast(
  emm_fof_by_age,
  method = "revpairwise",   # FOF vs nonFOF per kvartiili
  by     = "age_quartile",
  adjust = "none"           # halutessasi esim. "bonferroni"
)

summary(contr_fof_by_age, infer = TRUE, type = "response")


## 9.5 P-arvot tietokehikkoon

# Oleta, että p_by_quartile on laskettu tämän tyyppisenä:
# age_quartile, test_type, p_value

sig_df <- responder_by_age_fof %>%
  left_join(p_by_quartile, by = "age_quartile") %>%
  group_by(age_quartile) %>%
  summarise(
    # korkein responder-osuus kvartiilissa
    y_max   = max(prop_resp, na.rm = TRUE),
    p_value = first(p_value)
  ) %>%
  ungroup() %>%
  mutate(
    # lisätään pieni marginaali tekstille
    y_label = y_max + 0.05,
    # mitä näytetään: tähdet tai p-arvo
    label = dplyr::case_when(
      p_value < 0.001 ~ "***",
      p_value < 0.01  ~ "**",
      p_value < 0.05  ~ "*",
      p_value < 0.10  ~ paste0("p = ", round(p_value, 2)),  # esim. p = 0.08
      TRUE            ~ ""                                 # ei näytetä mitään
    )
  )

sig_df_plot <- sig_df %>% filter(label != "")

## 9.6: Kuva: responder-osuus iän kvartiileittain FOF/nonFOF mukaan

plot_responder_osuus <- ggplot(responder_by_age_fof,
       aes(x = age_quartile,
           y = prop_resp,
           fill = FOF_status)) +
  geom_col(position = position_dodge(width = 0.8)) +
  scale_y_continuous(
    name = "Responder-osuus",
    limits = c(0, 1)
  ) +
  labs(
    x    = "Ikäkvartiili",
    fill = "FOF-status",
    title = "Responder-osuus iän kvartiileittain FOF/nonFOF mukaan"
  ) +
  theme_minimal()

ggsave(
  filename = file.path(outputs_dir, "Responder_osuus.png"),
  plot     = plot_responder_osuus,
  width = 7, height = 5, dpi = 300
)

plot_responderosuus_per <- ggplot(responder_by_age_fof,
                                  aes(x = age_quartile,
                                      y = prop_resp,
                                      fill = FOF_status)) +
  geom_col(position = position_dodge(width = 0.8)) +
  scale_y_continuous(
    name = "Responder-osuus (%)",
    limits = c(0, 1),
    labels = scales::percent_format(accuracy = 1)
  ) +
  labs(
    x    = "Ikäkvartiili",
    fill = "FOF-status",
    title = "Responder-osuus iän kvartiileittain FOF/nonFOF mukaan"
  ) +
  theme_minimal()

# Sama kuva + p-arvo-/tähtitekstit ikäkvartiilin päälle
plot_responderosuus_per_annot <- plot_responderosuus_per +
  geom_text(
    data = sig_df %>% filter(label != ""),
    aes(x = age_quartile, y = y_label, label = label),
    inherit.aes = FALSE,
    vjust = 0   # teksti hieman pisteen yläpuolelle
  ) +
  # pieni lisävaraa y-akselille, jos tarvitsee
  coord_cartesian(ylim = c(0, 1.05))

# Tallenna
ggsave(
  filename = file.path(outputs_dir, "Responder_osuus_percent_annot.png"),
  plot     = plot_responderosuus_per_annot,
  width = 7, height = 5, dpi = 300
)


# End of K11.R