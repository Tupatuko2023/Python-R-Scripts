
# Calculating and Visualizing the Age Distribution by Group

# This R script [Age_Distribution_by_ Group_Plot] calculates and visualizes 
# the age distribution of patients by group, categorizing them into age ranges 
# and displaying a grouped bar chart.

###############################################################################
##############################################################################

library(dplyr)
library(ggplot2)

# 1: Define the current year
current_year <- 2024

# 2: Calculate age for living patients
unique_status_per_patient <- unique_status_per_patient %>%
  mutate(Age = ifelse(is.na(DeathYear), current_year - as.numeric(BirthYear), AgeAtDeath))

# 3: Create age groups
unique_status_per_patient <- unique_status_per_patient %>%
  mutate(AgeGroup = cut(Age, breaks = c(30, 40, 50, 60, 70, 80, 90, 100), right = FALSE,
                        labels = c("30-39", "40-49", "50-59", "60-69", "70-79", "80-89", "90-99")))

# 4: Remove NA values from the AgeGroup column
unique_status_per_patient <- unique_status_per_patient %>%
  filter(!is.na(AgeGroup))

# 5: Count the number of patients by age group and category
age_group_counts <- unique_status_per_patient %>%
  count(Group, AgeGroup)

# 6: Calculate percentages
age_group_counts <- age_group_counts %>%
  group_by(Group) %>%
  mutate(Total = sum(n),
         Percentage = n / Total * 100)

# 7: Create the diagram
age_distribution_plot <- ggplot(age_group_counts, aes(x = AgeGroup, y = n, fill = Group)) +
  geom_bar(stat = "identity", position = "dodge", color = "black") +
  geom_text(aes(label = paste0(round(Percentage, 1), "%")),
            position = position_dodge(width = 0.9), vjust = -0.5) +
  labs(title = "Age Distribution by Group", x = "Age Group", y = "Count") +
  theme_minimal() +
  theme(panel.background = element_rect(fill = "white", color = NA),
        plot.background = element_rect(fill = "white", color = NA)) +
  scale_fill_manual(values = c("Toothdata" = "skyblue", "No_toothdata" = "red"))

# 8: Display the diagram
print(age_distribution_plot)

# 9:Save the plot to the specified directory with a white background
output_file_path_status_distribution <- "/mnt/data/age_distribution_plot.png"
ggsave(output_file_path_status_distribution, plot = status_distribution_plot, width = 8, height = 6, bg = "white")