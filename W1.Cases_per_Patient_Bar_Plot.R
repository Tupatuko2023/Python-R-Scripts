
# Calculating and Visualizing the Number of Cases per Patient with a Bar Plot

# This R script "Cases_per_Patient_Bar_Plot.R" calculates and visualizes the 
# distribution of cases per patient using a bar plot, adding labels and saving 
# the plot as an image.

###############################################################################
###############################################################################

# 1: Load necessary libraries
library(dplyr)
library(ggplot2)

# 2: Calculate the number of cases per patient
cases_per_patient <- Case_df %>%
  group_by(Potilas_ID) %>%
  summarise(num_cases = n(), .groups = 'drop')

# 3: Plot the distribution of the number of cases per patient with enhancements
Uniq_Cases <- ggplot(cases_per_patient, aes(x = num_cases)) +
  geom_bar(fill = "skyblue", color = "black") +
  geom_text(stat = 'count', aes(label = after_stat(count)), vjust = -0.5, size = 3) + # Add labels on bars
  labs(title = "Distribution of Number of Cases per Patient",
       x = "Number of Cases",
       y = "Count of Patients") +
  theme_minimal() +
  theme(panel.background = element_rect(fill = "white", color = NA), # Ensure white background
        plot.background = element_rect(fill = "white", color = NA)) # Ensure white background

# 4: Display the plot
print(Uniq_Cases)

# 5: Save the plot to the specified directory with a white background
output_file_path2 <- "/mnt/data/Uniq_Cases.png"
ggsave(output_file_path2, plot = Uniq_Cases, width = 8, height = 6, bg = "white")
