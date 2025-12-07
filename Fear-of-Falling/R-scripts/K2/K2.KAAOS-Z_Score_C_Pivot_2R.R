# Asenna ja lataa tarvittavat paketit
# Asennetaan ja ladataan tarvittavat paketit
# install.packages("ggplot2")  # Visualisointia varten
# install.packages("dplyr")    # Datan käsittelyyn
# install.packages("tidyr")    # Pitkä formaattiin muuntamiseen
# install.packages("boot")     # Luottamusvälien laskemiseen
# install.packages("haven")
# install.packages("tidyverse") 
# install.packages("tibble") 
# install.packages("readr") 

# Ladataan tarvittavat kirjastot
library(dplyr)
library(tidyr)
library(readr)
library(tibble)  # Tarvitaan rivien muuttamiseen sarakkeiksi

# 📌 1: Ladataan alkuperäinen data
file_path <- "C:/Users/korptom20/OneDrive - HUS/TUTKIMUS/vanha.P-Sote/taulukot/KAAOS-Z_Score_Change_2R.csv"
df <- read_csv(file_path)

# 📌 2: Muutetaan testien nimet uuteen muotoon kaatumisenpelkoOn-arvon mukaan
df <- df %>%
  mutate(Testi = case_when(
    Testi == "Kävelynopeus" & kaatumisenpelkoOn == 0 ~ "MWS_Without_FOF",
    Testi == "Kävelynopeus" & kaatumisenpelkoOn == 1 ~ "MWS_With_FOF",
    Testi == "Puristusvoima" & kaatumisenpelkoOn == 0 ~ "HGS_Without_FOF",
    Testi == "Puristusvoima" & kaatumisenpelkoOn == 1 ~ "HGS_With_FOF",
    Testi == "Seisominen" & kaatumisenpelkoOn == 0 ~ "SLS_Without_FOF",
    Testi == "Seisominen" & kaatumisenpelkoOn == 1 ~ "SLS_With_FOF",
    Testi == "Tuoliltanousu" & kaatumisenpelkoOn == 0 ~ "FTSST_Without_FOF",
    Testi == "Tuoliltanousu" & kaatumisenpelkoOn == 1 ~ "FTSST_With_FOF",
    TRUE ~ Testi  # Jätetään muut muuttumattomiksi
  ))

# 📌 3: Poistetaan alkuperäinen "kaatumisenpelkoOn"-sarake, koska tieto on nyt Testi-nimessä
df <- df %>% select(-kaatumisenpelkoOn)

# 📌 4: Muutetaan "Testi"-sarake rivien nimeksi
df_transposed <- df %>%
  column_to_rownames(var = "Testi")  # Siirretään testien nimet riveiksi

# 📌 5: Transponoidaan taulukko
df_transposed <- as.data.frame(t(df_transposed))

# 📌 6: Lisätään ensimmäiseen sarakkeeseen alkuperäiset sarakenimet
df_transposed <- df_transposed %>%
  rownames_to_column(var = "Parameter")  # Muutetaan sarakenimet riveiksi

# 📌 7: Tallennetaan uusi pystysuuntainen taulukko CSV-muodossa
output_path <- "C:/Users/korptom20/OneDrive - HUS/TUTKIMUS/vanha.P-Sote/taulukot/KAAOS-Z_Score_Change_Transposed.csv"
write_csv(df_transposed, output_path)

# 📌 8: Tulostetaan tiedoston sijainti varmistukseksi
print(paste("Tiedosto tallennettu: ", output_path))

# 📌 9: Tarkistetaan lopullinen taulukko
print(head(df_transposed))
