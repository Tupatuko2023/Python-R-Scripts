
# Temporal Distribution and Visualization of Mortality Data
# : Analyzing Yearly Death Trends

# This R script [Death_Year_Distribution.R ] visualizes the distribution of death 
# years, showing counts and percentages with a bar plot using custom colors, 
# and saves the plot as an image.

###############################################################################
##############################################################################

# 1: Load necessary libraries
library(dplyr)
library(ggplot2)
library(RColorBrewer)

# 2: Clean the Kuolinvuosi column
data_separated <- data_separated %>%
  mutate(Kuolinvuosi = as.numeric(Kuolinvuosi)) %>%
  filter(!is.na(Kuolinvuosi) & Kuolinvuosi > 1900 & Kuolinvuosi <= 2024)

# 3: Calculate the percentage for each year of death
data_percentage <- data_separated %>%
  count(Kuolinvuosi) %>%
  mutate(percentage = n / sum(n) * 100)

# 4: Generate a color palette with 38 distinct colors
color_palette <- brewer.pal(n = 8, name = "Dark2")
color_palette <- colorRampPalette(color_palette)(38)

# 5: Year of Death Bar Chart with Percentage Labels and Custom Colors
death_year_distribution <- ggplot(data_percentage, aes(x = Kuolinvuosi, y = n, fill = as.factor(Kuolinvuosi))) +
  geom_bar(stat = "identity", color = "black") +
  scale_fill_manual(values = color_palette) +
  geom_text(aes(label = paste0(round(percentage, 1), "%")), vjust = -0.5) +  # Labels with one decimal place
  labs(title = "Year of Death Distribution", x = "Year of Death", y = "Count", fill = "Groups") +  # Custom legend title
  scale_x_continuous(breaks = seq(1970, 2025, by = 5)) +  # Custom x-axis breaks at 5-year intervals from 1970 to 2025
  theme_minimal() +
  theme(panel.background = element_rect(fill = "white", color = NA),  # Ensure white background
        plot.background = element_rect(fill = "white", color = NA)) +  # Ensure white background
  annotate("text", x = 1985, y = max(data_percentage$n) * 1.1, label = "Numbers above bars represent percentages (%)", hjust = 0, vjust = 1, size = 4)

# 6: Display the plot
print(death_year_distribution)

# 7: Save the plot to the specified directory with a white background
output_file_path_death <- "/mnt/data/Year_of_Death_Distribution.png"
ggsave(output_file_path_death, plot = death_year_distribution, width = 8, height = 6, bg = "white")
