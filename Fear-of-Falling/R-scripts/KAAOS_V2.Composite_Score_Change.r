# Asenna ja lataa tarvittavat paketit, jos niitä ei vielä ole
# install.packages("ggplot2")  # Visualisointia varten
# install.packages("dplyr")    # Datan käsittelyyn
# install.packages("haven")    # .dta-tiedoston lukemiseen
# install.packages("effsize")  # Cohenin d:n laskemiseen
# install.packages("boot")     # Bootstrapping luottamusvälien laskemiseen

library(ggplot2)
library(dplyr)
library(haven)
library(effsize)
library(boot)

# 1: Määritellään tiedoston polku
file_path <- "C:/Users/tomik/OneDrive/ARTIKKELI/Aineistot/KaatumisenPelko.dta"

# 2: Ladataan aineisto
data <- read_dta(file_path)

# 3: Tarkastellaan aineiston rakennetta
str(data)
head(data)

# 4: Muutetaan ryhmämuuttuja faktoriksi (0=ei pelkää, 1=pelkää)
data$kaatumisenpelkoOn <- as.factor(data$kaatumisenpelkoOn)

# 5: Luodaan muutosmuuttuja suorituskykysummalle (delta)
data$DeltaToimintaKyky <- data$ToimintaKykySummary2 - data$ToimintaKykySummary0

# 6: Lasketaan keskimääräinen suorituskykymuutos ryhmittäin
data_summary <- data %>%
  group_by(kaatumisenpelkoOn) %>%
  summarise(
    Mean_Change = mean(DeltaToimintaKyky, na.rm = TRUE),
    SD_Change = sd(DeltaToimintaKyky, na.rm = TRUE),
    N = n()
  )

# 7: Luodaan viivakaavio suorituskyvyn muutoksesta seurannan aikana
ggplot(data, aes(x = kaatumisenpelkoOn, y = DeltaToimintaKyky, color = kaatumisenpelkoOn, group = kaatumisenpelkoOn)) +
  geom_jitter(width = 0.2, alpha = 0.6) +  # Yksittäiset datapisteet
  geom_boxplot(alpha = 0.3, outlier.shape = NA) + # Laatikko ja viikset
  stat_summary(fun = mean, geom = "point", size = 4, shape = 23, fill = "white") + # Keskiarvot
  scale_x_discrete(labels = c("Ei FOF", "FOF")) +
  labs(title = "Fyysisen suorituskyvyn muutos seurannan aikana",
       x = "Ryhmä",
       y = "Muutos Z-score",
       color = "Ryhmä") +
  theme_minimal()

# 8: Cohenin d laskeminen ryhmien välillä
cohen_d <- cohen.d(data$DeltaToimintaKyky ~ data$kaatumisenpelkoOn, hedges.correction = TRUE)
print(cohen_d)

###########################################################
# R-koodi Cohenin d:n laskemiseksi molemmille ryhmille alussa ja lopussa
###########################################################
###########################################################

# 1: Funktio Cohenin d:n laskemiseksi kahdelle ajankohdalle
calculate_cohen_d <- function(pre, post) {
  mean_pre <- mean(pre, na.rm = TRUE)
  mean_post <- mean(post, na.rm = TRUE)
  sd_pre <- sd(pre, na.rm = TRUE)
  sd_post <- sd(post, na.rm = TRUE)
  
  # Pooled standard deviation
  pooled_sd <- sqrt((sd_pre^2 + sd_post^2) / 2)
  
  # Cohen's d laskenta
  d <- (mean_post - mean_pre) / pooled_sd
  return(d)
}

# 2: Lasketaan Cohenin d molemmille ryhmille ja composite-scorelle
cohen_d_FOF_composite <- calculate_cohen_d(FOF_group$ToimintaKykySummary0, FOF_group$ToimintaKykySummary2)
cohen_d_NoFOF_composite <- calculate_cohen_d(NoFOF_group$ToimintaKykySummary0, NoFOF_group$ToimintaKykySummary2)

# 3: Tulostetaan efektikoot
cat("Cohen's d - Composite score (FOF-ryhmässä):", cohen_d_FOF_composite, "\n")
cat("Cohen's d - Composite score (Ei-FOF ryhmässä):", cohen_d_NoFOF_composite, "\n")

# 4: Viivakaavio efektikoosta ajan suhteen
composite_data <- data.frame(
  Group = rep(c("FOF", "Ei FOF"), each = 2),
  Time = rep(c("Baseline", "Follow-up"), 2),
  Composite_Score = c(mean(FOF_group$ToimintaKykySummary0, na.rm = TRUE),
                      mean(FOF_group$ToimintaKykySummary2, na.rm = TRUE),
                      mean(NoFOF_group$ToimintaKykySummary0, na.rm = TRUE),
                      mean(NoFOF_group$ToimintaKykySummary2, na.rm = TRUE))
)

# 5: Piirretään viivakaavio
ggplot(composite_data, aes(x = Time, y = Composite_Score, group = Group, color = Group)) +
  geom_line(size = 1.2) +
  geom_point(size = 4) +
  labs(title = "Composite Score - Efektikoot ajan suhteen",
       x = "Aika",
       y = "Composite Score",
       color = "Ryhmä") +
  theme_minimal()

###########################################################
# R-koodi Cohenin d:n laskemiseksi molemmille ryhmille alussa ja lopussa
###########################################################
###########################################################

# Funktio bootstrap-luottamusvälien laskemiseksi
bootstrap_ci <- function(data, variable, R = 5000) {
  boot_fn <- function(data, indices) {
    mean(data[indices], na.rm = TRUE)
  }
  boot_res <- boot(data[[variable]], statistic = boot_fn, R = R)
  ci <- boot.ci(boot_res, type = "perc")$percent[4:5] # 95% CI
  return(ci)
}

# Lasketaan 95% bootstrap-luottamusvälit molemmille ryhmille (Baseline ja Follow-up)
ci_FOF_baseline <- bootstrap_ci(FOF_group, "ToimintaKykySummary0")
ci_FOF_followup <- bootstrap_ci(FOF_group, "ToimintaKykySummary2")

ci_NoFOF_baseline <- bootstrap_ci(NoFOF_group, "ToimintaKykySummary0")
ci_NoFOF_followup <- bootstrap_ci(NoFOF_group, "ToimintaKykySummary2")

# Luodaan dataframe sisältämään keskiarvot ja luottamusvälit
composite_data <- data.frame(
  Group = rep(c("FOF", "Ei FOF"), each = 2),
  Time = rep(c("Baseline", "Follow-up"), 2),
  Composite_Score = c(mean(FOF_group$ToimintaKykySummary0, na.rm = TRUE),
                      mean(FOF_group$ToimintaKykySummary2, na.rm = TRUE),
                      mean(NoFOF_group$ToimintaKykySummary0, na.rm = TRUE),
                      mean(NoFOF_group$ToimintaKykySummary2, na.rm = TRUE)),
  Lower_CI = c(ci_FOF_baseline[1], ci_FOF_followup[1], ci_NoFOF_baseline[1], ci_NoFOF_followup[1]),
  Upper_CI = c(ci_FOF_baseline[2], ci_FOF_followup[2], ci_NoFOF_baseline[2], ci_NoFOF_followup[2])
)

# Päivitetään factoriksi, jotta voidaan käyttää position_dodge()
composite_data$Time <- factor(composite_data$Time, levels = c("Baseline", "Follow-up"))

# Luodaan viivakaavio, jossa ryhmät erotetaan x-akselilla
ggplot(composite_data, aes(x = Time, y = Composite_Score, group = Group, color = Group)) +
  geom_line(aes(group = Group), position = position_dodge(width = 0.2), size = 1.2) +  # Siirretään viivat erilleen
  geom_point(position = position_dodge(width = 0.2), size = 4) +  # Pisteet eivät ole päällekkäin
  geom_errorbar(aes(ymin = Lower_CI, ymax = Upper_CI), 
                position = position_dodge(width = 0.2), width = 0.2, size = 1) +  # Luottamusvälit eroteltuna
  labs(title = "Composite Score - Efektikoot ajan suhteen (95% CI)",
       x = "Aika",
       y = "Composite Score",
       color = "Ryhmä") +
  theme_minimal()

###########################################################
# R-koodi vakioidulle efektikoolle
###########################################################
###########################################################


# 1. Lisätään ryhmätunniste ja yhdistetään datasetit
FOF_group$group <- "FOF"
NoFOF_group$group <- "NoFOF"

data_combined <- rbind(FOF_group, NoFOF_group)

# 2. Poistetaan puuttuvat arvot vain tarvittavista sarakkeista
data_clean <- na.omit(data_combined[, c("ToimintaKykySummary0", "ToimintaKykySummary2", "age", "sex", "BMI", "group")])

# 3. Sovitetaan lineaarinen regressiomalli baseline- ja follow-up-arvoille
model_baseline <- lm(ToimintaKykySummary0 ~ age + sex + BMI, data = data_clean)
model_followup <- lm(ToimintaKykySummary2 ~ age + sex + BMI, data = data_clean)

# 4. Haetaan mallin jäännökset (vakioidut composite scoret)
data_clean$Adjusted_Baseline <- residuals(model_baseline)
data_clean$Adjusted_Followup <- residuals(model_followup)

# 5. Erotellaan FOF- ja NoFOF-ryhmät uudestaan
FOF_adjusted <- data_clean[data_clean$group == "FOF", ]
NoFOF_adjusted <- data_clean[data_clean$group == "NoFOF", ]

# 6. Lasketaan Cohen’s d vakioiduille composite scoreille
cohen_d_baseline <- cohen.d(FOF_adjusted$Adjusted_Baseline, NoFOF_adjusted$Adjusted_Baseline)
cohen_d_followup <- cohen.d(FOF_adjusted$Adjusted_Followup, NoFOF_adjusted$Adjusted_Followup)

# 7. Tulostetaan efektikoot
cat("Cohen's d - Vakioitu Composite Score (Baseline):", cohen_d_baseline$estimate, "\n")
cat("Cohen's d - Vakioitu Composite Score (Follow-up):", cohen_d_followup$estimate, "\n")

###########################################################
# Tarkistukset: R-koodi vakioidulle efektikoolle
###########################################################
###########################################################

mean(FOF_adjusted$Adjusted_Baseline)
mean(NoFOF_adjusted$Adjusted_Baseline)

mean(FOF_adjusted$Adjusted_Followup)
mean(NoFOF_adjusted$Adjusted_Followup)

sd(FOF_adjusted$Adjusted_Baseline)
sd(NoFOF_adjusted$Adjusted_Baseline)

sd(FOF_adjusted$Adjusted_Followup)
sd(NoFOF_adjusted$Adjusted_Followup)


cohen.d(FOF_group$ToimintaKykySummary0, NoFOF_group$ToimintaKykySummary0)
cohen.d(FOF_group$ToimintaKykySummary2, NoFOF_group$ToimintaKykySummary2)

###########################################################
# Luo kuvaajan, jossa esitetään vakioidut efektikoot (Cohen's d) 
#  FOF- ja Ei-FOF-ryhmille Baseline- ja Follow-up-vaiheessa, voit seurata seuraavaa R-koodia.
###########################################################
###########################################################


# 1: Luodaan dataframe Cohenin d -efektikokojen visualisoimiseksi
effect_size_data <- data.frame(
  Group = rep(c("FOF", "Ei FOF"), each = 2),
  Time = rep(c("Baseline", "Follow-up"), 2),
  Effect_Size = c(cohen_d_baseline$estimate, cohen_d_followup$estimate,
                  cohen_d_baseline$estimate, cohen_d_followup$estimate),
  CI_Lower = c(cohen_d_baseline$conf.int[1], cohen_d_followup$conf.int[1],
               cohen_d_baseline$conf.int[1], cohen_d_followup$conf.int[1]),
  CI_Upper = c(cohen_d_baseline$conf.int[2], cohen_d_followup$conf.int[2],
               cohen_d_baseline$conf.int[2], cohen_d_followup$conf.int[2])
)

# Päivitetään Time muuttujaksi, jotta voidaan erotella x-akselilla
effect_size_data$Time <- factor(effect_size_data$Time, levels = c("Baseline", "Follow-up"))

# Piirretään parannettu kuvaaja
ggplot(effect_size_data, aes(x = Time, y = Effect_Size, group = Group, color = Group)) +
  geom_line(aes(group = Group), size = 1.2, position = position_dodge(width = 0.3)) +  # Erotellaan viivat x-akselilla
  geom_point(size = 4, position = position_dodge(width = 0.3)) +  # Erotellaan pisteet
  geom_errorbar(aes(ymin = CI_Lower, ymax = CI_Upper), width = 0.1, size = 1, position = position_dodge(width = 0.3)) +  # Luottamusvälit
  labs(title = "Vakioidut efektikoot FOF- ja Ei-FOF-ryhmille (Baseline → Follow-up)",
       x = "Aika",
       y = "Cohen's d - Efektikoko",
       color = "Ryhmä") +
  theme_minimal()

###########################################################
# Tarkistetaan regressiomallin summary(), jotta nähdään kuinka paljon 
#  ToimintaKykySummary0 selittää Follow-up-arvosta:
###########################################################
###########################################################

summary(model_followup)

sd(FOF_adjusted$Adjusted_Followup)
sd(NoFOF_adjusted$Adjusted_Followup)

###########################################################
# Lasketaan Cohen’s d ilman vakiointia
###########################################################
###########################################################

cohen_d_FOF_raw <- calculate_cohen_d(FOF_group$ToimintaKykySummary0, FOF_group$ToimintaKykySummary2)
cohen_d_NoFOF_raw <- calculate_cohen_d(NoFOF_group$ToimintaKykySummary0, NoFOF_group$ToimintaKykySummary2)

cat("Cohen's d ilman vakiointia - FOF:", cohen_d_FOF_raw, "\n")
cat("Cohen's d ilman vakiointia - Ei-FOF:", cohen_d_NoFOF_raw, "\n")

###########################################################
# Verrataan vakioituun Cohen’s d:hen
###########################################################
###########################################################

cat("Cohen's d vakioituna - FOF:", cohen_d_baseline$estimate, "\n")
cat("Cohen's d vakioituna - Ei-FOF:", cohen_d_followup$estimate, "\n")


cat("Cohen's d vakioituna - FOF:", cohen_d_baseline$estimate, "\n")
cat("Cohen's d vakioituna - Ei-FOF:", cohen_d_followup$estimate, "\n")

###########################################################
# Voimme kokeilla vakioida vain baseline-arvon, mutta ei ikää ja BMI:tä:
###########################################################
###########################################################

model_followup_baseline <- lm(ToimintaKykySummary2 ~ ToimintaKykySummary0, data = data_clean)

summary(model_followup_baseline)

###########################################################
# R-koodi Cohen’s d laskemiseksi vain baseline-vakioinnin jälkeen
###########################################################
###########################################################

# 1. Haetaan baseline-vakioidut jäännösarvot (residualit)
data_clean$Adjusted_BaselineOnly <- residuals(model_followup_baseline)

# 2. Erotellaan FOF- ja Ei-FOF-ryhmät
FOF_adjusted_baseline <- data_clean[data_clean$group == "FOF", ]
NoFOF_adjusted_baseline <- data_clean[data_clean$group == "NoFOF", ]

# 3. Lasketaan Cohen’s d vain baseline-vakioinnilla
cohen_d_baseline_only <- cohen.d(FOF_adjusted_baseline$Adjusted_BaselineOnly, NoFOF_adjusted_baseline$Adjusted_BaselineOnly)

# 4. Tulostetaan uusi Cohen’s d
cat("Cohen's d vakioituna VAIN baseline-arvon mukaan:", cohen_d_baseline_only$estimate, "\n")

###########################################################
# R-koodi Cohen’s d laskemiseksi vain baseline-vakioinnin jälkeen
###########################################################
###########################################################

# 1. Lasketaan Cohen's d FOF-ryhmälle (Baseline-vakioidut arvot)
cohen_d_FOF_baseline_only <- calculate_cohen_d(FOF_adjusted_baseline$Adjusted_BaselineOnly, FOF_group$ToimintaKykySummary2)

# 2. Lasketaan Cohen's d Ei-FOF-ryhmälle (Baseline-vakioidut arvot)
cohen_d_NoFOF_baseline_only <- calculate_cohen_d(NoFOF_adjusted_baseline$Adjusted_BaselineOnly, NoFOF_group$ToimintaKykySummary2)

# 3. Tulostetaan molemmat efektikoot
cat("Cohen's d vakioituna VAIN baseline-arvon mukaan - FOF:", cohen_d_FOF_baseline_only, "\n")
cat("Cohen's d vakioituna VAIN baseline-arvon mukaan - Ei-FOF:", cohen_d_NoFOF_baseline_only, "\n")

