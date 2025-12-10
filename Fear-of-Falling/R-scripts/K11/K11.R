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
library(nlme)
library(quantreg)
library(tibble)

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

# ---------------------------------------------------------------
# 10 Distributionaalinen näkökulma: hajonta ja kvanttilinjaregressio
# ---------------------------------------------------------------

## 10.1: R-mallipohjat (gls + rq)

## Heteroskedastisuus FOF-ryhmien välillä (gls)

### 10.1.A Perus-lm ja diagnostinen testi:

mod_lm <- lm(
  Delta_Composite_Z ~ FOF_status + Composite_Z0 + age + BMI + sex,
  data = dat_fof
)

# Esim. Breusch–Pagan heteroskedastisuustesti
library(lmtest)
bptest(mod_lm, ~ FOF_status, data = dat_fof)


### 10.1.B gls-mallit: oletus vs FOF-spesifinen varianssi

# Homoskedastinen malli
mod_gls_hom <- gls(
  Delta_Composite_Z ~ FOF_status+ Composite_Z0 + age + BMI + sex,
  data = dat_fof
)

# Eri varianssit FOF-ryhmille
mod_gls_het <- gls(
  Delta_Composite_Z ~ FOF_status+ Composite_Z0 + age + BMI + sex,
  data = dat_fof,
  weights = varIdent(form = ~ 1 | FOF_status)
)

anova(mod_gls_hom, mod_gls_het)  # testaa, parantaako heteroskedastisuus sovitusta

# Arvioidut residuaalivarianssit ryhmittäin
summary(mod_gls_het)$modelStruct$varStruct

## 10.2: Kvanttilinjaregressio (rq, quantreg)

taus <- c(0.25, 0.5, 0.75)

mod_rq_25 <- rq(
  Delta_Composite_Z ~ FOF_status + Composite_Z0 + age + BMI + sex,
  tau  = 0.25,
  data = dat_fof
)

mod_rq_50 <- rq(
  Delta_Composite_Z ~ FOF_status + Composite_Z0 + age + BMI + sex,
  tau  = 0.50,
  data = dat_fof
)

mod_rq_75 <- rq(
  Delta_Composite_Z ~ FOF_status + Composite_Z0 + age + BMI + sex,
  tau  = 0.75,
  data = dat_fof
)

summary(mod_rq_25)
summary(mod_rq_50)
summary(mod_rq_75)

# Esim. kerää FOF_status-kertoimet taulukkoon
get_fof <- function(fit) {
  cf <- summary(fit)$coefficients
  
  est <- cf["FOF_status1", "coefficients"]
  lo  <- cf["FOF_status1", "lower bd"]
  hi  <- cf["FOF_status1", "upper bd"]
  
  # approksimoidaan keskihajonta 95 % CI:stä
  se  <- (hi - lo) / (2 * 1.96)
  
  data.frame(
    tau      = fit$tau,
    beta_FOF = est,
    se_FOF   = se,
    ci_low   = lo,
    ci_high  = hi
  )
}


fof_rq <- rbind(
  get_fof(mod_rq_25),
  get_fof(mod_rq_50),
  get_fof(mod_rq_75)
)

fof_rq

# ---------------------------------------------------------------
# 11. Taulukoiden tallennus CSV + HTML --------------------------
# ---------------------------------------------------------------

# 11.1 Kuvailevat frekvenssit ja ikäkvartiilit ------------------

freq_FOF_status <- analysis_data_rec %>% 
  count(FOF_status)

freq_AgeClass <- analysis_data_rec %>% 
  count(AgeClass)

cross_FOF_AgeClass <- analysis_data_rec %>% 
  count(FOF_status, AgeClass)

age_quartile_summary <- dat_fof %>% 
  group_by(age_quartile) %>% 
  summarise(
    n          = n(),
    min_age    = min(age),
    median_age = median(age),
    max_age    = max(age),
    .groups    = "drop"
  )

save_table_csv_html(freq_FOF_status,      "freq_FOF_status")
save_table_csv_html(freq_AgeClass,        "freq_AgeClass")
save_table_csv_html(cross_FOF_AgeClass,   "cross_FOF_AgeClass")
save_table_csv_html(age_quartile_summary, "age_quartile_summary")


# 11.2 Lineaariset mallit: base & extended ----------------------

# tab_base ja tab_ext on jo luotu aiemmin, varmistetaan:
tab_base <- broom::tidy(mod_base, conf.int = TRUE)
tab_ext  <- broom::tidy(mod_ext,  conf.int = TRUE)

save_table_csv_html(tab_base, "lm_base_model_full")
save_table_csv_html(tab_ext,  "lm_extended_model_full")

# FOF-kertoimen kooste base vs extended
fof_base <- subset(tab_base, term == "FOF_status1")
fof_ext  <- subset(tab_ext,  term == "FOF_status1")

fof_comp <- fof_base %>% 
  mutate(model = "base") %>% 
  bind_rows(fof_ext %>% mutate(model = "extended")) %>% 
  dplyr::select(model, term, estimate, conf.low, conf.high, p.value)

save_table_csv_html(fof_comp, "FOF_effect_base_vs_extended")

# Standardoidut kertoimet extended-mallille
tab_std_ext <- standardize_parameters(mod_ext) %>% 
  as.data.frame()

save_table_csv_html(tab_std_ext, "lm_extended_standardized")


# 11.3 MICE – imputoidut mallit (osa jo tallennettu) ------------

# Huom: seuraavat oli jo tehty aiemmin skriptissä:
# md_pattern_df
# tab_base_imp
# tab_ext_imp
# save_table_csv_html(..., "missing_data_pattern")
# save_table_csv_html(..., "mice_pooled_model_base")
# save_table_csv_html(..., "mice_pooled_model_extended")

# Kooste FOF-kertoimista imputoiduissa malleissa
fof_base_imp <- tab_base_imp %>% dplyr::filter(term == "FOF_status1")
fof_ext_imp  <- tab_ext_imp  %>% dplyr::filter(term == "FOF_status1")

fof_imp_comp <- bind_rows(
  fof_base_imp %>% mutate(model = "base_imputed"),
  fof_ext_imp  %>% mutate(model = "extended_imputed")
)

save_table_csv_html(fof_imp_comp, "FOF_effect_MICE_base_vs_extended")


# 11.4 Responder- ja ordinaalimallit -----------------------------

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

# Responder-osuudet ikäkvartiileittain ja FOF-statuksen mukaan
save_table_csv_html(responder_by_age_fof, "responder_by_age_and_FOF")

# Kvartiilikohtaiset p-arvot (Chi-square/Fisher)
save_table_csv_html(p_by_quartile, "responder_pvalues_by_age_quartile")

# emmeans: FOF vs nonFOF per ikäkvartiili (OR + CI)
contr_fof_by_age_df <- as.data.frame(
  summary(contr_fof_by_age, infer = TRUE, type = "response")
)

save_table_csv_html(contr_fof_by_age_df, "emmeans_FOF_vs_nonFOF_by_agequartile")


# 11.5 Hajonta & kvanttilinjaregressio ---------------------------

# Breusch–Pagan heteroskedastisuustesti
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

# Residuaalivarianssien suhteet FOF-ryhmittäin
var_struct <- summary(mod_gls_het)$modelStruct$varStruct

# Poimitaan varIdent-kertoimet (ei sisällä baseline-ryhmää, jonka kerroin = 1)
var_coefs <- coef(var_struct, unconstrained = FALSE)

# FOF-status -faktorin tasot datasta
var_levels <- levels(dat_fof$FOF_status)

# Baseline-ryhmä on se taso, jota ei ole var_coefs-nimissä
baseline_level <- setdiff(var_levels, names(var_coefs))

# Jos jostain syystä baselinea ei löydy, oletetaan ensimmäinen taso
if (length(baseline_level) == 0) {
  baseline_level <- var_levels[1]
}

# Kootaan täysi suhteiden vektori: baseline = 1, muut = coef(var_struct)
ratios_full <- c(1, as.numeric(var_coefs))
names(ratios_full) <- c(baseline_level, names(var_coefs))

var_struct_df <- data.frame(
  group = names(ratios_full),
  ratio = as.numeric(ratios_full)
)

save_table_csv_html(var_struct_df, "gls_residual_variance_by_FOF")

# Kvanttilinjaregressio: FOF-kerroin eri kvantiileissa
save_table_csv_html(fof_rq, "quantile_reg_FOF_effect")


# ---------------------------------------------------------------
# 13. Manifestin päivitys: K11:n keskeiset taulukot ja kuvat ----
# ---------------------------------------------------------------



manifest_rows <- tibble::tibble(
  script     = script_label,
  type       = c(
    # taulukot
    rep("table", 21),
    # kuvat
    rep("plot",  2)
  ),
  filename   = c(
    # --- TABLES (CSV) ---
    file.path(script_label, "freq_FOF_status.csv"),
    file.path(script_label, "freq_AgeClass.csv"),
    file.path(script_label, "cross_FOF_AgeClass.csv"),
    file.path(script_label, "age_quartile_summary.csv"),
    file.path(script_label, "lm_base_model_full.csv"),
    file.path(script_label, "lm_extended_model_full.csv"),
    file.path(script_label, "lm_extended_standardized.csv"),
    file.path(script_label, "FOF_effect_base_vs_extended.csv"),
    file.path(script_label, "missing_data_pattern.csv"),
    file.path(script_label, "mice_pooled_model_base.csv"),
    file.path(script_label, "mice_pooled_model_extended.csv"),
    file.path(script_label, "FOF_effect_MICE_base_vs_extended.csv"),
    file.path(script_label, "logit_responder_model.csv"),
    file.path(script_label, "ordinal_polr_OR.csv"),
    file.path(script_label, "responder_by_age_and_FOF.csv"),
    file.path(script_label, "responder_pvalues_by_age_quartile.csv"),
    file.path(script_label, "emmeans_FOF_vs_nonFOF_by_agequartile.csv"),
    file.path(script_label, "BP_test_FOF_status.csv"),
    file.path(script_label, "gls_hom_vs_het_comparison.csv"),
    file.path(script_label, "gls_residual_variance_by_FOF.csv"),
    file.path(script_label, "quantile_reg_FOF_effect.csv"),
    # --- PLOTS (PNG) ---
    file.path(script_label, "Responder_osuus.png"),
    file.path(script_label, "Responder_osuus_percent_annot.png")
  ),
  description = c(
    # --- TABLE DESCRIPTIONS ---
    "FOF-statusin frekvenssijakauma (nonFOF vs FOF).",
    "Ikäluokkien (AgeClass: 65–74, 75–84, 85+) frekvenssijakauma.",
    "Ristiintaulukko FOF-status x AgeClass.",
    "Ikäkvartiilit: havaintomäärä, min, mediaani ja maksimi iän mukaan.",
    "Peruslineaarisen mallin (lm) kertoimet: Delta_Composite_Z ~ FOF_status + kovariaatit.",
    "Laajennetun lineaarisen mallin (lm) kertoimet (sis. MOI, komorbiditeetit, kaatumishistoria, mieliala).",
    "Laajennetun lineaarisen mallin standardoidut kertoimet.",
    "FOF-statusin kerroin ja 95 % LV perus- ja laajennetussa mallissa rinnakkain.",
    "MICE-missing data -kuvio: puuttuvuuspatterni analyysimuuttujille.",
    "MICE: poolattu perusmalli (lm) imputoidussa datassa.",
    "MICE: poolattu laajennettu malli (lm) imputoidussa datassa.",
    "MICE: FOF-statusin vaikutus (kerroin + LV) perus- ja laajennetussa mallissa (imputoitu data).",
    "Responder-logistisen regressiomallin (OR-kertoimet) FOF- ja kovariaattivaikutuksille.",
    "Ordinaalimallin (polr) odds ratio -kertoimet (heikentynyt–stabiili–parantunut).",
    "Responder-osuudet ikäkvartiileittain ja FOF-statusen mukaan.",
    "Ikäkvartiilikohtaiset p-arvot (FOF vs nonFOF responder-statuksessa, Fisher/Chi-square).",
    "FOF vs nonFOF -odds ratio kussakin ikäkvartiilissa (emmeans-contrasts).",
    "Breusch–Pagan heteroskedastisuustesti (FOF-status ryhmittäjänä).",
    "GLS-mallien vertailu: homoskedastinen vs FOF-spesifinen residuaalivarianssi.",
    "GLS: residuaalivarianssien suhteet FOF vs nonFOF -ryhmissä.",
    "Kvanttilinjaregression (rq) FOF-kerroin eri kvantiileissa (tau = 0.25, 0.50, 0.75).",
    # --- PLOT DESCRIPTIONS ---
    "Responder-osuuksien (proportio) pylväsdiagrammi ikäkvartiileittain FOF/nonFOF mukaan.",
    "Responder-osuudet prosentteina ikäkvartiileittain FOF/nonFOF mukaan, p-arvot/tähdet annotaatioina."
  )
)

# Kirjoitetaan / päivitetään projektin yhteinen manifest.csv
if (!file.exists(manifest_path)) {
  # Luodaan uusi manifest otsikkoriveineen
  readr::write_csv(manifest_rows, manifest_path)
} else {
  # Lisätään rivit olemassa olevan manifestin jatkoksi
  readr::write_csv(manifest_rows, manifest_path,
                   append = TRUE, col_names = FALSE)
}


# End of K11.R