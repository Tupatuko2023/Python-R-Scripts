
# Calculating and Visualizing the Distribution of Patients' Status by Group

# This R script [Distribution_of_Patients'_Status.R] calculates and visualizes 
# the distribution of patients' status by group, using a bar plot with percentages 
# and saving the plot as an image.

###############################################################################
##############################################################################

# 1: Load necessary libraries
library(ggplot2)

# 2: Create a contingency table for plotting
contingency_table_plot <- unique_status_per_patient %>%
  count(Group, Status) %>%
  mutate(percentage = n / sum(n) * 100)

# 3: Plot the distribution of patients' status by group
status_distribution_plot <- ggplot(contingency_table_plot, aes(x = Group, y = n, fill = Status)) +
  geom_bar(stat = "identity", position = "dodge", color = "black") +
  scale_fill_manual(values = c("Deceased" = "red", "Living" = "skyblue")) +
  geom_text(aes(label = paste0(round(percentage, 1), "%")), 
            position = position_dodge(width = 0.9), vjust = -0.5) +
  labs(title = "Distribution of Patients Status by Group", 
       x = "Group", y = "Count") +
  theme_minimal() +
  theme(panel.background = element_rect(fill = "white", color = NA), 
        plot.background = element_rect(fill = "white", color = NA))

# 4: Display the plot
print(status_distribution_plot)

# 5:Save the plot to the specified directory with a white background
output_file_path_status_distribution <- "/mnt/data/Status_Distribution_By_Group.png"
ggsave(output_file_path_status_distribution, plot = status_distribution_plot, width = 8, height = 6, bg = "white")
