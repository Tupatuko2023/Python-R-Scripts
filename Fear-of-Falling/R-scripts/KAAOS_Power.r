install.packages("haven")
library(haven)

# 1: Määritellään tiedoston polku
file_path <- "C:/Users/korptom20/OneDrive - HUS/TUTKIMUS/P-Sote/VL_ Alustava kysely/KaatumisenPelko.dta"

# 2: Ladataan aineisto
data <- read_dta(file_path)

# 3: Tarkastellaan aineiston rakennetta
str(data)

# 4: Tulostetaan ensimmäiset rivit
head(data)

# 5: Asennetaan ja ladataan tarvittavat paketit
install.packages("pwr")
install.packages("dplyr")

library(pwr)
library(dplyr)

# 6: Tutkimuksen parametrit
alpha <- 0.05    # Merkitsevyystaso
power <- 0.80    # Power (1 - beta)
effect_size <- 0.20 / sqrt(1 - 0.20^2)  # Cohen's f (effect size)

# 7: Lasketaan tarvittava otoskoko ANCOVA:lle (kahden ryhmän vertailu)
sample_size <- pwr.anova.test(k = 2, f = effect_size, sig.level = alpha, power = power)

# 8: Tulostetaan tulokset
print(sample_size)

# 📌 Lisämuunnelmia Power-laskelmille

# 9: Laskea powerin nykyisellä otoskoolla:

pwr.anova.test(k = 2, f = effect_size, sig.level = alpha, n = 77)  # n = ryhmäkohtainen otoskoko

pwr.anova.test(k = 2, f = effect_size, sig.level = alpha, n = 199)  # n = ryhmäkohtainen otoskoko
