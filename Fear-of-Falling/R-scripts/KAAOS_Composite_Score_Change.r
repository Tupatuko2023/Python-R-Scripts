# Asenna ja lataa tarvittavat paketit
# install.packages("haven")   # .dta tiedoston lukemiseen
install.packages("effsize") # Cohenin d:n laskemiseen
install.packages("boot")    # Bootstrapping luottamusvälien laskemiseen
library(haven)
library(effsize)
library(boot)


# 1: Määritellään tiedoston polku
file_path <- "C:/Users/korptom20/OneDrive - HUS/TUTKIMUS/P-Sote/VL_ Alustava kysely/KaatumisenPelko.dta"

# 2: Ladataan aineisto
data <- read_dta(file_path)

# 3: Tarkastellaan aineiston rakennetta
str(data)
head(data)

# 4: Muutetaan ryhmämuuttuja faktoriksi (0=ei pelkää, 1=pelkää)
data$kaatumisenpelkoOn <- as.factor(data$kaatumisenpelkoOn)

# 5: Luodaan muutosmuuttuja suorituskykysummalle (delta)
data$DeltaToimintaKyky <- data$ToimintaKykySummary2 - data$ToimintaKykySummary0

# 6: Lasketaan Cohenin d kahden ryhmän välillä (FOF vs. ei-FOF)
cohen_d <- cohen.d(data$DeltaToimintaKyky ~ data$kaatumisenpelkoOn, hedges.correction = TRUE)

# Tulostetaan Cohenin d
print(cohen_d)

# 7: Lasketaan 95 % bootstrapping-luottamusvälit Cohenin d:lle
boot_cohen_d <- function(data, indices) {
  d <- data[indices, ]
  cohen.d(d$DeltaToimintaKyky ~ d$kaatumisenpelkoOn, hedges.correction = TRUE)$estimate
}

set.seed(123)  # Toistettavuuden varmistamiseksi
boot_res <- boot(data, statistic = boot_cohen_d, R = 10000)

# 8: Tulostetaan 95 % luottamusväli Cohenin d:lle
boot.ci(boot_res, type = "perc")


###############################
###############################

# 3: Luodaan muutosmuuttujat (lopputulos - alkutulos)
data$Delta_kavelynopeus <- data$z_kavelynopeus2 - data$z_kavelynopeus0
data$Delta_Tuoli <- data$z_Tuoli2 - data$z_Tuoli0
data$Delta_Seisominen <- data$z_Seisominen2 - data$z_Seisominen0
data$Delta_Puristus <- data$z_Puristus2 - data$z_Puristus0

# 4: Lasketaan Cohenin d jokaiselle testille
cohen_d_kavelynopeus <- cohen.d(data$Delta_kavelynopeus ~ data$kaatumisenpelkoOn, hedges.correction = TRUE)
cohen_d_Tuoli <- cohen.d(data$Delta_Tuoli ~ data$kaatumisenpelkoOn, hedges.correction = TRUE)
cohen_d_Seisominen <- cohen.d(data$Delta_Seisominen ~ data$kaatumisenpelkoOn, hedges.correction = TRUE)
cohen_d_Puristus <- cohen.d(data$Delta_Puristus ~ data$kaatumisenpelkoOn, hedges.correction = TRUE)

# 5: Tulostetaan Cohenin d tulokset
print(cohen_d_kavelynopeus)
print(cohen_d_Tuoli)
print(cohen_d_Seisominen)
print(cohen_d_Puristus)

# 6: Bootstrapping-funktio Cohenin d:lle
boot_cohen_d <- function(data, indices, var) {
  d <- data[indices, ]
  cohen.d(d[[var]] ~ d$kaatumisenpelkoOn, hedges.correction = TRUE)$estimate
}

# 7: Bootstrapping (5000 iterointia) jokaiselle testille
set.seed(123)  # Toistettavuuden varmistamiseksi
boot_kavelynopeus <- boot(data, statistic = function(d, i) boot_cohen_d(d, i, "Delta_kavelynopeus"), R = 5000)
boot_Tuoli <- boot(data, statistic = function(d, i) boot_cohen_d(d, i, "Delta_Tuoli"), R = 5000)
boot_Seisominen <- boot(data, statistic = function(d, i) boot_cohen_d(d, i, "Delta_Seisominen"), R = 5000)
boot_Puristus <- boot(data, statistic = function(d, i) boot_cohen_d(d, i, "Delta_Puristus"), R = 5000)

# 8: Tulostetaan bootstrapping 95 % luottamusvälit
boot.ci(boot_kavelynopeus, type = "perc")
boot.ci(boot_Tuoli, type = "perc")
boot.ci(boot_Seisominen, type = "perc")
boot.ci(boot_Puristus, type = "perc")


###########################################################
# R-koodi efektikoon laskemiseksi molemmille ryhmille erikseen
###########################################################
###########################################################

# 1: Luodaan kaksi data-alijoukkoa: FOF ja ei-FOF
FOF_group <- data[data$kaatumisenpelkoOn == 1, ]
NoFOF_group <- data[data$kaatumisenpelkoOn == 0, ]

# 2: Funktio Cohenin d:n laskemiseksi jokaiselle testille erikseen
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

# 3: Cohenin d molemmille ryhmille ja jokaiselle testille
cohen_d_FOF_kavelynopeus <- calculate_cohen_d(FOF_group$z_kavelynopeus0, FOF_group$z_kavelynopeus2)
cohen_d_NoFOF_kavelynopeus <- calculate_cohen_d(NoFOF_group$z_kavelynopeus0, NoFOF_group$z_kavelynopeus2)

cohen_d_FOF_Tuoli <- calculate_cohen_d(FOF_group$z_Tuoli0, FOF_group$z_Tuoli2)
cohen_d_NoFOF_Tuoli <- calculate_cohen_d(NoFOF_group$z_Tuoli0, NoFOF_group$z_Tuoli2)

cohen_d_FOF_Seisominen <- calculate_cohen_d(FOF_group$z_Seisominen0, FOF_group$z_Seisominen2)
cohen_d_NoFOF_Seisominen <- calculate_cohen_d(NoFOF_group$z_Seisominen0, NoFOF_group$z_Seisominen2)

cohen_d_FOF_Puristus <- calculate_cohen_d(FOF_group$z_Puristus0, FOF_group$z_Puristus2)
cohen_d_NoFOF_Puristus <- calculate_cohen_d(NoFOF_group$z_Puristus0, NoFOF_group$z_Puristus2)

# 4: Tulostetaan efektikoot molemmille ryhmille
cat("Cohen's d - Kävelynopeus FOF ryhmässä:", cohen_d_FOF_kavelynopeus, "\n")
cat("Cohen's d - Kävelynopeus Ei-FOF ryhmässä:", cohen_d_NoFOF_kavelynopeus, "\n")

cat("Cohen's d - Tuoliltanousu FOF ryhmässä:", cohen_d_FOF_Tuoli, "\n")
cat("Cohen's d - Tuoliltanousu Ei-FOF ryhmässä:", cohen_d_NoFOF_Tuoli, "\n")

cat("Cohen's d - Yhdellä jalalla seisominen FOF ryhmässä:", cohen_d_FOF_Seisominen, "\n")
cat("Cohen's d - Yhdellä jalalla seisominen Ei-FOF ryhmässä:", cohen_d_NoFOF_Seisominen, "\n")

cat("Cohen's d - Puristusvoima FOF ryhmässä:", cohen_d_FOF_Puristus, "\n")
cat("Cohen's d - Puristusvoima Ei-FOF ryhmässä:", cohen_d_NoFOF_Puristus, "\n")

# Tilastollisen merkitsevyyden tarkistaminen (Parillinen t-testi)

t.test(FOF_group$z_kavelynopeus0, FOF_group$z_kavelynopeus2, paired = TRUE)
t.test(NoFOF_group$z_kavelynopeus0, NoFOF_group$z_kavelynopeus2, paired = TRUE)

###########################################################
# R-koodi Cohenin d:n laskemiseksi alkuperäisistä muuttujista
###########################################################
###########################################################


# 1: Muutetaan Cohenin d:n laskentafunktio huomioimaan Tuoliltanousu oikein
calculate_cohen_d <- function(pre, post, inverse = FALSE) {
  mean_pre <- mean(pre, na.rm = TRUE)
  mean_post <- mean(post, na.rm = TRUE)
  sd_pre <- sd(pre, na.rm = TRUE)
  sd_post <- sd(post, na.rm = TRUE)
  
  # Pooled standard deviation
  pooled_sd <- sqrt((sd_pre^2 + sd_post^2) / 2)
  
  # Cohen's d laskenta (käänteinen jos inverse = TRUE, eli Tuoliltanousu)
  if (inverse) {
    d <- (mean_pre - mean_post) / pooled_sd  # Käännetään merkki, jotta parannus on positiivinen
  } else {
    d <- (mean_post - mean_pre) / pooled_sd
  }
  
  return(d)
}

# 2: Lasketaan Cohenin d molemmille ryhmille KÄÄNNETTYNÄ Tuoliltanousulle
cohen_d_FOF_Tuoli <- calculate_cohen_d(FOF_group$tuoliltanousu0, FOF_group$tuoliltanousu2, inverse = TRUE)
cohen_d_NoFOF_Tuoli <- calculate_cohen_d(NoFOF_group$tuoliltanousu0, NoFOF_group$tuoliltanousu2, inverse = TRUE)

# 3: Cohenin d muille muuttujille normaalisti
cohen_d_FOF_kavelynopeus <- calculate_cohen_d(FOF_group$kavelynopeus_m_sek0, FOF_group$kavelynopeus_m_sek2)
cohen_d_NoFOF_kavelynopeus <- calculate_cohen_d(NoFOF_group$kavelynopeus_m_sek0, NoFOF_group$kavelynopeus_m_sek2)

cohen_d_FOF_Seisominen <- calculate_cohen_d(FOF_group$Seisominen0, FOF_group$Seisominen2)
cohen_d_NoFOF_Seisominen <- calculate_cohen_d(NoFOF_group$Seisominen0, NoFOF_group$Seisominen2)

cohen_d_FOF_Puristus <- calculate_cohen_d(FOF_group$Puristus0, FOF_group$Puristus2)
cohen_d_NoFOF_Puristus <- calculate_cohen_d(NoFOF_group$Puristus0, NoFOF_group$Puristus2)

# 4: Tulostetaan korjatut efektikoot
cat("Cohen's d - Kävelynopeus FOF ryhmässä:", cohen_d_FOF_kavelynopeus, "\n")
cat("Cohen's d - Kävelynopeus Ei-FOF ryhmässä:", cohen_d_NoFOF_kavelynopeus, "\n")

cat("Cohen's d - Tuoliltanousu FOF ryhmässä (korjattu):", cohen_d_FOF_Tuoli, "\n")
cat("Cohen's d - Tuoliltanousu Ei-FOF ryhmässä (korjattu):", cohen_d_NoFOF_Tuoli, "\n")

cat("Cohen's d - Yhdellä jalalla seisominen FOF ryhmässä:", cohen_d_FOF_Seisominen, "\n")
cat("Cohen's d - Yhdellä jalalla seisominen Ei-FOF ryhmässä:", cohen_d_NoFOF_Seisominen, "\n")

cat("Cohen's d - Puristusvoima FOF ryhmässä:", cohen_d_FOF_Puristus, "\n")
cat("Cohen's d - Puristusvoima Ei-FOF ryhmässä:", cohen_d_NoFOF_Puristus, "\n")


###########################################################
# R-koodi bootstrappingin suorittamiseksi Cohenin d:lle
###########################################################
###########################################################

# 1: Määritellään bootstrapping-funktio Cohenin d:lle, joka poistaa NA-arvot
boot_cohen_d <- function(data, indices, var1, var2) {
  d <- data[indices, ]
  # Poistetaan NA-arvot
  d <- na.omit(d[, c(var1, var2)])
  
  # Jos data on tyhjä NA-poiston jälkeen, palautetaan NA (estää virheen)
  if (nrow(d) == 0) {
    return(NA)
  }
  
  # Lasketaan Cohen's d
  return(cohen.d(d[[var1]], d[[var2]], paired = TRUE)$estimate)
}

# 2: Bootstrapping FOF-ryhmälle jokaiselle testille
set.seed(123)  # Toistettavuuden varmistamiseksi
boot_FOF_Tuoli <- boot(FOF_group, statistic = function(d, i) boot_cohen_d(d, i, "tuoliltanousu0", "tuoliltanousu2"), R = 5000)
boot_FOF_Seisominen <- boot(FOF_group, statistic = function(d, i) boot_cohen_d(d, i, "Seisominen0", "Seisominen2"), R = 5000)
boot_FOF_Kavelynopeus <- boot(FOF_group, statistic = function(d, i) boot_cohen_d(d, i, "kavelynopeus_m_sek0", "kavelynopeus_m_sek2"), R = 5000)
boot_FOF_Puristus <- boot(FOF_group, statistic = function(d, i) boot_cohen_d(d, i, "Puristus0", "Puristus2"), R = 5000)

# 3: Bootstrapping Ei-FOF-ryhmälle jokaiselle testille
boot_NoFOF_Tuoli <- boot(NoFOF_group, statistic = function(d, i) boot_cohen_d(d, i, "tuoliltanousu0", "tuoliltanousu2"), R = 5000)
boot_NoFOF_Seisominen <- boot(NoFOF_group, statistic = function(d, i) boot_cohen_d(d, i, "Seisominen0", "Seisominen2"), R = 5000)
boot_NoFOF_Kavelynopeus <- boot(NoFOF_group, statistic = function(d, i) boot_cohen_d(d, i, "kavelynopeus_m_sek0", "kavelynopeus_m_sek2"), R = 5000)
boot_NoFOF_Puristus <- boot(NoFOF_group, statistic = function(d, i) boot_cohen_d(d, i, "Puristus0", "Puristus2"), R = 5000)

# 4: Tulostetaan 95 % luottamusvälit Cohenin d:lle
cat("Bootstrapped 95% CI - Tuoliltanousu FOF ryhmässä:", boot.ci(boot_FOF_Tuoli, type = "perc")$percent, "\n")
cat("Bootstrapped 95% CI - Tuoliltanousu Ei-FOF ryhmässä:", boot.ci(boot_NoFOF_Tuoli, type = "perc")$percent, "\n")

cat("Bootstrapped 95% CI - Seisominen FOF ryhmässä:", boot.ci(boot_FOF_Seisominen, type = "perc")$percent, "\n")
cat("Bootstrapped 95% CI - Seisominen Ei-FOF ryhmässä:", boot.ci(boot_NoFOF_Seisominen, type = "perc")$percent, "\n")

cat("Bootstrapped 95% CI - Kävelynopeus FOF ryhmässä:", boot.ci(boot_FOF_Kavelynopeus, type = "perc")$percent, "\n")
cat("Bootstrapped 95% CI - Kävelynopeus Ei-FOF ryhmässä:", boot.ci(boot_NoFOF_Kavelynopeus, type = "perc")$percent, "\n")

cat("Bootstrapped 95% CI - Puristusvoima FOF ryhmässä:", boot.ci(boot_FOF_Puristus, type = "perc")$percent, "\n")
cat("Bootstrapped 95% CI - Puristusvoima Ei-FOF ryhmässä:", boot.ci(boot_NoFOF_Puristus, type = "perc")$percent, "\n")




###########################################################
# Uusi R-koodi Cohenin d -laskenta erikseen naisille ja miehille 
###########################################################
###########################################################

# 1: Luodaan alijoukot sukupuolen perusteella
FOF_women <- FOF_group[FOF_group$sex == 0, ]
FOF_men <- FOF_group[FOF_group$sex == 1, ]

NoFOF_women <- NoFOF_group[NoFOF_group$sex == 0, ]
NoFOF_men <- NoFOF_group[NoFOF_group$sex == 1, ]

# 2: Muutetaan Cohenin d -laskentafunktio huomioimaan Tuoliltanousu oikein
calculate_cohen_d <- function(pre, post, inverse = FALSE) {
  mean_pre <- mean(pre, na.rm = TRUE)
  mean_post <- mean(post, na.rm = TRUE)
  sd_pre <- sd(pre, na.rm = TRUE)
  sd_post <- sd(post, na.rm = TRUE)
  
  # Pooled standard deviation
  pooled_sd <- sqrt((sd_pre^2 + sd_post^2) / 2)
  
  # Cohen's d laskenta (käänteinen jos inverse = TRUE, eli Tuoliltanousu)
  if (inverse) {
    d <- (mean_pre - mean_post) / pooled_sd  # Käännetään merkki, jotta parannus on positiivinen
  } else {
    d <- (mean_post - mean_pre) / pooled_sd
  }
  
  return(d)
}

# 3: Lasketaan Cohenin d erikseen naisille ja miehille FOF- ja Ei-FOF-ryhmissä
cohen_d_FOF_women_Tuoli <- calculate_cohen_d(FOF_women$tuoliltanousu0, FOF_women$tuoliltanousu2, inverse = TRUE)
cohen_d_FOF_men_Tuoli <- calculate_cohen_d(FOF_men$tuoliltanousu0, FOF_men$tuoliltanousu2, inverse = TRUE)

cohen_d_NoFOF_women_Tuoli <- calculate_cohen_d(NoFOF_women$tuoliltanousu0, NoFOF_women$tuoliltanousu2, inverse = TRUE)
cohen_d_NoFOF_men_Tuoli <- calculate_cohen_d(NoFOF_men$tuoliltanousu0, NoFOF_men$tuoliltanousu2, inverse = TRUE)

cohen_d_FOF_women_Kavelynopeus <- calculate_cohen_d(FOF_women$kavelynopeus_m_sek0, FOF_women$kavelynopeus_m_sek2)
cohen_d_FOF_men_Kavelynopeus <- calculate_cohen_d(FOF_men$kavelynopeus_m_sek0, FOF_men$kavelynopeus_m_sek2)

cohen_d_NoFOF_women_Kavelynopeus <- calculate_cohen_d(NoFOF_women$kavelynopeus_m_sek0, NoFOF_women$kavelynopeus_m_sek2)
cohen_d_NoFOF_men_Kavelynopeus <- calculate_cohen_d(NoFOF_men$kavelynopeus_m_sek0, NoFOF_men$kavelynopeus_m_sek2)

cohen_d_FOF_women_Seisominen <- calculate_cohen_d(FOF_women$Seisominen0, FOF_women$Seisominen2)
cohen_d_FOF_men_Seisominen <- calculate_cohen_d(FOF_men$Seisominen0, FOF_men$Seisominen2)

cohen_d_NoFOF_women_Seisominen <- calculate_cohen_d(NoFOF_women$Seisominen0, NoFOF_women$Seisominen2)
cohen_d_NoFOF_men_Seisominen <- calculate_cohen_d(NoFOF_men$Seisominen0, NoFOF_men$Seisominen2)

cohen_d_FOF_women_Puristus <- calculate_cohen_d(FOF_women$Puristus0, FOF_women$Puristus2)
cohen_d_FOF_men_Puristus <- calculate_cohen_d(FOF_men$Puristus0, FOF_men$Puristus2)

cohen_d_NoFOF_women_Puristus <- calculate_cohen_d(NoFOF_women$Puristus0, NoFOF_women$Puristus2)
cohen_d_NoFOF_men_Puristus <- calculate_cohen_d(NoFOF_men$Puristus0, NoFOF_men$Puristus2)

# 4: Tulostetaan Cohenin d erikseen naisille ja miehille
cat("Cohen's d - Kävelynopeus (FOF, Naiset):", cohen_d_FOF_women_Kavelynopeus, "\n")
cat("Cohen's d - Kävelynopeus (FOF, Miehet):", cohen_d_FOF_men_Kavelynopeus, "\n")
cat("Cohen's d - Kävelynopeus (Ei-FOF, Naiset):", cohen_d_NoFOF_women_Kavelynopeus, "\n")
cat("Cohen's d - Kävelynopeus (Ei-FOF, Miehet):", cohen_d_NoFOF_men_Kavelynopeus, "\n")

cat("Cohen's d - Tuoliltanousu (FOF, Naiset):", cohen_d_FOF_women_Tuoli, "\n")
cat("Cohen's d - Tuoliltanousu (FOF, Miehet):", cohen_d_FOF_men_Tuoli, "\n")
cat("Cohen's d - Tuoliltanousu (Ei-FOF, Naiset):", cohen_d_NoFOF_women_Tuoli, "\n")
cat("Cohen's d - Tuoliltanousu (Ei-FOF, Miehet):", cohen_d_NoFOF_men_Tuoli, "\n")

cat("Cohen's d - Yhdellä jalalla seisominen (FOF, Naiset):", cohen_d_FOF_women_Seisominen, "\n")
cat("Cohen's d - Yhdellä jalalla seisominen (FOF, Miehet):", cohen_d_FOF_men_Seisominen, "\n")
cat("Cohen's d - Yhdellä jalalla seisominen (Ei-FOF, Naiset):", cohen_d_NoFOF_women_Seisominen, "\n")
cat("Cohen's d - Yhdellä jalalla seisominen (Ei-FOF, Miehet):", cohen_d_NoFOF_men_Seisominen, "\n")

cat("Cohen's d - Puristusvoima (FOF, Naiset):", cohen_d_FOF_women_Puristus, "\n")
cat("Cohen's d - Puristusvoima (FOF, Miehet):", cohen_d_FOF_men_Puristus, "\n")
cat("Cohen's d - Puristusvoima (Ei-FOF, Naiset):", cohen_d_NoFOF_women_Puristus, "\n")
cat("Cohen's d - Puristusvoima (Ei-FOF, Miehet):", cohen_d_NoFOF_men_Puristus, "\n")

