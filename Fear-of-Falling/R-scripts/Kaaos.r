install.packages("haven")
library(haven)

# Määritellään tiedoston polku
file_path <- "C:/Users/korptom20/OneDrive - HUS/TUTKIMUS/P-Sote/VL_ Alustava kysely/KaatumisenPelko.dta"

# Ladataan aineisto
data <- read_dta(file_path)

# Tarkastellaan aineiston rakennetta
str(data)

# Tulostetaan ensimmäiset rivit
head(data)

# Tulostetaan ensimmäiset rivit
# > head(data)
# A tibble: 6 × 104
# NRO enter        age pvm0kk pvm1  pvm2  Agelka  Jnro KAAOSVastaanottokäynti   sex diabetes alzheimer parkinson   AVH
# <dbl> <date>     <dbl>  <dbl> <chr> <chr>  <dbl> <dbl> <date>                 <dbl>    <dbl>     <dbl>     <dbl> <dbl>
#   1   553 2013-10-07    78     10 6     12        70   310 NA                         0        0         0         0     0
# 2   198 2011-08-01    81      8 E1    9         80    67 NA                         0        0         0         0     1
# 3   648 2011-01-13    72      1 8     2         70   382 NA                         0        1         0         0     0
# 4   806 2013-01-14    77      1 E1    2         70   495 2013-01-14                 0        0         0         0     0
# 5   451 2013-01-04    76      2 E1    4         70   243 NA                         0        1         0         0     0
# 6   208 2011-02-17    96      2 E1    2         80    73 NA                         0        0         0         0     0
# ℹ 90 more variables: koettuterveydentila <dbl>, MOIindeksiindeksi <dbl>, pituudenlyhentyma <dbl>,
#   Kadet_apuna_noustessa <dbl>, paino <dbl>, pituus <dbl>, BMI <dbl>, tupakointi <dbl>, alkoholi <dbl>, kuulo <dbl>,
#   nako <dbl>, muisti <dbl>, mieliala <dbl>, nukkuminen <dbl>, ravitsemus <dbl>, oma_arvio_liikuntakyky <dbl>,
#   vaikeus_liikkua_500m <dbl>, vaikeus_liikkua_2km <dbl>, tasapainovaikeus <dbl>, kaatuminen <dbl>, murtumia <dbl>,
#   kaatumisenpelkoOn <dbl>, kaatumisenpelkoVAS <dbl>, maxkävelymatka <dbl>, PainVAS0 <dbl>, PEF0 <dbl>,
#   yhdella_jalalla_seisominen_Oik_0 <dbl>, yhdella_jalalla_seisominen_Vas_0 <dbl>, tuoliltanousu0 <dbl>,
#   Puristusvoima_lka_Oik_0 <dbl>, Puristusvoima_lka_Vas_0 <dbl>, kavelynopeus0 <dbl>, kavelynopeusApuvaline0 <dbl>,


# Tarvittavat kirjastot
# install.packages("rcompanion")  # Jos ei ole vielä asennettuna
library(rcompanion)

# Muutetaan 'kaatumisenpelkoOn' faktoriksi
data$kaatumisenpelkoOn <- as.factor(data$kaatumisenpelkoOn)

# Luokittelevat muuttujat myös faktoreiksi
data$SRH <- as.factor(data$SRH)
data$oma_arvio_liikuntakyky <- as.factor(data$oma_arvio_liikuntakyky)

### 1. Khiin neliötestit päämuuttujille
chi_srh <- chisq.test(table(data$kaatumisenpelkoOn, data$SRH))
chi_liikunta <- chisq.test(table(data$kaatumisenpelkoOn, data$oma_arvio_liikuntakyky))

# Tulostetaan testitulokset
print(chi_srh)
print(chi_liikunta)

### 2. Post hoc -analyysi (parittaiset vertailut)
# Jos khiin neliötestin p-arvo < 0.05, tehdään parittaiset testit

# Post hoc testit Self-rated Healthille
if (chi_srh$p.value < 0.05) {
  pairwise_results_srh <- pairwiseNominalIndependence(table(data$kaatumisenpelkoOn, data$SRH),
                                                      method = "bonferroni")
  print(pairwise_results_srh)
}

# Post hoc testit Self-Rated Mobilitylle
if (chi_liikunta$p.value < 0.05) {
  pairwise_results_liikunta <- pairwiseNominalIndependence(table(data$kaatumisenpelkoOn, data$oma_arvio_liikuntakyky),
                                                           method = "bonferroni")
  print(pairwise_results_liikunta)
}

# Selkeä ja helposti luettavan taulukko

#######################################

# Asennetaan tarvittavat paketit, jos ei ole vielä asennettu
# install.packages("rcompanion")  # Post hoc -testit
install.packages("knitr")       # Taulukon tulostamiseen
install.packages("kableExtra")  # Parempi muotoilu
install.packages("dplyr")       # Tiedon käsittelyyn

# Ladataan kirjastot
library(rcompanion)
library(knitr)
library(kableExtra)
library(dplyr)

# Luodaan ristiintaulukointi liikuntakyvylle ja kaatumisen pelolle
mobility_table <- table(data$kaatumisenpelkoOn, data$oma_arvio_liikuntakyky)

# Suoritetaan khiin neliötesti (kokonaisp-arvo)
chi_test_mobility <- chisq.test(mobility_table)
p_overall <- chi_test_mobility$p.value  # Tallennetaan p-arvo

# Suoritetaan post hoc -testi Bonferroni-korjauksella
pairwise_results_liikunta <- pairwiseNominalIndependence(mobility_table, method = "bonferroni")

# Haetaan parittaiset p-arvot
p_good_vs_moderate <- pairwise_results_liikunta$p.adj.Fisher[1]
p_good_vs_weak <- pairwise_results_liikunta$p.adj.Fisher[2]
p_moderate_vs_weak <- pairwise_results_liikunta$p.adj.Fisher[3]

# Luodaan lopullinen taulukko
mobility_results <- data.frame(
  `Self-Rated Mobility` = c("Good", "Moderate", "Weak", "Kokonaisp-arvo"),
  `Without FOF (n=77)` = c("20 (26%)", "42 (55%)", "15 (19%)", ""),
  `With FOF (n=199)` = c("30 (15%)", "91 (46%)", "75 (38%)", ""),
  `p-arvo` = c(p_good_vs_weak, p_good_vs_moderate, p_moderate_vs_weak, p_overall)
)

# Tulostetaan taulukko RStudioon
mobility_results %>%
  kable("html", caption = "Self-Rated Mobility Results") %>%
  kable_styling(full_width = F, bootstrap_options = c("striped", "hover", "condensed", "responsive"))
