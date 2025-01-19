
# Work 4: Demographic Distribution of Living and Deceased Individuals: A Statistical Visualization Using Bar Charts

# This R script [Living_Deceased_Distribution.R] Generates a bar plot that shows the distribution of living and deceased 
# individuals with counts displayed as normal integers. 

###############################################################################
##############################################################################

# Load necessary libraries
library(dplyr)
library(ggplot2)

# 1: Create a new column indicating whether an individual is living or deceased
data_separated <- data_separated %>%
  mutate(Status = if_else(is.na(Kuolinvuosi), "Living", "Deceased"))

# 2: Calculate counts for each status
status_count <- data_separated %>%
  count(Status)

# 3: Calculate the total count of living and deceased individuals
total_count <- sum(status_count$n)

# 4: Calculate percentages for each status
status_count <- status_count %>%
  mutate(percentage = n / total_count * 100)

# 5: Define custom colors for the status
status_colors <- c("Living" = "skyblue", "Deceased" = "red")

# 6: Status Distribution Bar Chart with Percentage Labels and Custom Colors
status_distribution <- ggplot(status_count, aes(x = Status, y = n, fill = Status)) +
  geom_bar(stat = "identity", color = "black") +
  scale_fill_manual(values = status_colors) +
  geom_text(aes(label = paste0(round(percentage, 1), "%")), vjust = -0.5) + # Percentage labels with one decimal place
  labs(title = "Living vs. Deceased Distribution", x = "Status", y = "Count") +
  scale_y_continuous(labels = scales::comma) + # Display count as normal integers
  theme_minimal() +
  theme(panel.background = element_rect(fill = "white", color = NA), # Ensure white background
        plot.background = element_rect(fill = "white", color = NA))   # Ensure white background

# 7: Display the plot
print(status_distribution)

# 8: Save the plot to the specified directory with a white background
output_file_path <- "/mnt/data/Status_Distribution.png"
ggsave(output_file_path, plot = status_distribution, width = 8, height = 6, bg = "white")
