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

# Tarkista, että muuttuja oma_arvio_liikuntakyky ei sisällä NA-arvoja
table(data$oma_arvio_liikuntakyky, useNA = "always")

# Jos NA-arvoja löytyy, ne voidaan poistaa tai käsitellä:
data <- data %>% filter(!is.na(oma_arvio_liikuntakyky))



# Asennetaan tarvittavat paketit, jos ei ole vielä asennettu
# install.packages("ggplot2")
# install.packages("dplyr")
# install.packages("tidyr")

# Ladataan kirjastot
library(ggplot2)
library(dplyr)
library(tidyr)

# Luodaan data visualisointia varten
mobility_data <- data %>%
  count(kaatumisenpelkoOn, oma_arvio_liikuntakyky) %>%  # Lasketaan ryhmäkohtaiset frekvenssit
  group_by(kaatumisenpelkoOn) %>% 
  mutate(percentage = n / sum(n) * 100)  # Lasketaan prosenttiosuudet

# Muutetaan faktoreiksi oikeassa järjestyksessä
mobility_data$oma_arvio_liikuntakyky <- factor(mobility_data$oma_arvio_liikuntakyky, 
                                               levels = c("Good", "Moderate", "Weak"))

# Piirretään pylväskaavio
ggplot(mobility_data, aes(x = oma_arvio_liikuntakyky, y = percentage, fill = kaatumisenpelkoOn)) +
  geom_bar(stat = "identity", position = "dodge") +  
  labs(title = "Self-Rated Mobility by FOF Group",
       x = "Self-Rated Mobility",
       y = "Percentage (%)",
       fill = "FOF Status") +
  scale_fill_manual(values = c("#0072B2", "#D55E00"), labels = c("Without FOF", "With FOF")) +  
  theme_minimal()


# Ladataan kirjastot
library(rcompanion)
library(dplyr)
library(knitr)

# Muutetaan muuttujat faktoreiksi, jotta R ymmärtää ne kategorisina
data$kaatumisenpelkoOn <- as.factor(data$kaatumisenpelkoOn)
data$oma_arvio_liikuntakyky <- as.factor(data$oma_arvio_liikuntakyky)

# Luodaan ristiintaulukointi
mobility_table <- table(data$kaatumisenpelkoOn, data$oma_arvio_liikuntakyky)

# Khiin neliötesti kokonaisuudelle
chi_test_mobility <- chisq.test(mobility_table)
p_overall <- chi_test_mobility$p.value  # Kokonaisp-arvo

# Post hoc -testi: parittaiset vertailut Bonferroni-korjauksella
pairwise_results_liikunta <- pairwiseNominalIndependence(mobility_table, method = "bonferroni")

# Haetaan p-arvot eri luokkien välille
p_good <- pairwise_results_liikunta$p.adj.Fisher[1]  # Good (0)
p_moderate <- pairwise_results_liikunta$p.adj.Fisher[2]  # Moderate (1)
p_weak <- pairwise_results_liikunta$p.adj.Fisher[3]  # Weak (2)

# Rakennetaan taulukko tuloksista
mobility_results <- data.frame(
  `Self-Rated Mobility` = c("Good", "Moderate", "Weak", "Kokonaisp-arvo"),
  `p-arvo (kaatumisenpelkoOn 0 vs. 1)` = c(p_good, p_moderate, p_weak, p_overall)
)

# Tulostetaan taulukko RStudioon
mobility_results %>%
  kable("html", caption = "P-arvot Self-Rated Mobility -ryhmien välillä")


# Asennetaan tarvittavat paketit, jos ei ole vielä asennettu
# install.packages("ggplot2")
# install.packages("dplyr")
# install.packages("tidyr")

# Ladataan kirjastot
library(ggplot2)
library(dplyr)
library(tidyr)

# Luodaan data visualisointia varten
mobility_data <- data %>%
  count(kaatumisenpelkoOn, oma_arvio_liikuntakyky) %>%  # Lasketaan frekvenssit
  group_by(kaatumisenpelkoOn) %>% 
  mutate(percentage = n / sum(n) * 100)  # Lasketaan prosenttiosuudet

# Muutetaan faktoreiksi oikeassa järjestyksessä
mobility_data$oma_arvio_liikuntakyky <- factor(mobility_data$oma_arvio_liikuntakyky, 
                                               levels = c("Good", "Moderate", "Weak"))

# Piirretään pylväsdiagrammi
ggplot(mobility_data, aes(x = oma_arvio_liikuntakyky, y = percentage, fill = kaatumisenpelkoOn)) +
  geom_bar(stat = "identity", position = "dodge") +  
  labs(title = "Self-Rated Mobility by FOF Group",
       x = "Self-Rated Mobility",
       y = "Percentage (%)",
       fill = "FOF Status") +
  scale_fill_manual(values = c("#0072B2", "#D55E00"), labels = c("Without FOF", "With FOF")) +  
  theme_minimal()

###################################
###################################

# Asennetaan tarvittavat paketit, jos ei ole vielä asennettu
# install.packages("ggplot2")
# install.packages("dplyr")
# install.packages("tidyr")

# Ladataan kirjastot
library(ggplot2)
library(dplyr)
library(tidyr)

data$oma_arvio_liikuntakyky <- factor(data$oma_arvio_liikuntakyky, levels = c(0, 1, 2), labels = c("Good", "Moderate", "Weak"))

# Tarkistetaan vielä
str(data$oma_arvio_liikuntakyky)


# Luodaan data visualisointia varten
mobility_data <- data %>%
  count(kaatumisenpelkoOn, oma_arvio_liikuntakyky) %>%  # Lasketaan frekvenssit
  group_by(kaatumisenpelkoOn) %>% 
  mutate(percentage = n / sum(n) * 100)  # Lasketaan prosenttiosuudet

# Muutetaan faktoreiksi oikeassa järjestyksessä
mobility_data$oma_arvio_liikuntakyky <- factor(mobility_data$oma_arvio_liikuntakyky, 
                                               levels = c("Good", "Moderate", "Weak"))

# Piirretään pylväsdiagrammi
ggplot(mobility_data, aes(x = kaatumisenpelkoOn, y = percentage, fill = oma_arvio_liikuntakyky)) +
  geom_bar(stat = "identity", position = "dodge") +  
  labs(title = "Comparison of Self-Rated Mobility Groups within FOF Status",
       x = "FOF Status (0 = Without FOF, 1 = With FOF)",
       y = "Percentage (%)",
       fill = "Self-Rated Mobility") +
  scale_fill_manual(values = c("#1b9e77", "#d95f02", "#7570b3")) +  
  theme_minimal()

###################################
###################################


# Piirretään viivakaavio
ggplot(mobility_data, aes(x = kaatumisenpelkoOn, y = percentage, group = oma_arvio_liikuntakyky, color = oma_arvio_liikuntakyky)) +
  geom_line(size = 1.2) +
  geom_point(size = 3) +
  labs(title = "Self-Rated Mobility Trends by FOF Status",
       x = "FOF Status (0 = Without FOF, 1 = With FOF)",
       y = "Percentage (%)",
       color = "Self-Rated Mobility") +
  scale_color_manual(values = c("#1b9e77", "#d95f02", "#7570b3")) +
  theme_minimal()


