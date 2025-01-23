# Work 21: to calculate the Pearson correlation coefficient 
# [W21.Pearson_Correlation_Coefficient.R] 

# "This R script calculates the Pearson correlation coefficient, performs linear regression, 
# and visualizes the relationship between CCI and HFRS."

########################################################################################################
#  Sequence list
########################################################################################################

# 1: Load necessary libraries
# 2: Load the updated data
# 3: Ensure columns are numeric
# 4: Drop rows with missing values in CCI or HFRS
# 5: Calculate Pearson correlation coefficient
# 6: Perform linear regression
# 7: Plotting the regression line
# 8: Save the Scatter plot
# 9: Correlation analysis completed

########################################################################################################
########################################################################################################

# 1: Load necessary libraries
library(ggplot2)
library(reshape2)

# 2: Load the updated data
data_path <- '/home/work/pp_all_data_with_cci.csv'
data <- read.csv(data_path)

print("2: Data loaded successfully.")

# 3: Ensure columns are numeric
data$CCI <- as.numeric(as.character(data$CCI))
data$HFRS <- as.numeric(as.character(data$HFRS))

# 4: Drop rows with missing values in CCI or HFRS
data <- na.omit(data[, c('CCI', 'HFRS')])

# 5: Calculate Pearson correlation coefficient
pearson_corr <- cor(data$CCI, data$HFRS)
p_value_corr <- cor.test(data$CCI, data$HFRS)$p.value
print(paste("5: Pearson correlation coefficient:", pearson_corr, ", p-value:", p_value_corr))

# 6: Perform linear regression
model <- lm(HFRS ~ CCI, data = data)
print(summary(model))

# 7: Plotting the regression line
scatter_plot <- ggplot(data, aes(x = CCI, y = HFRS)) +
  geom_point() +
  geom_smooth(method = 'lm', col = 'blue') +
  ggtitle('Scatter Plot of CCI vs. HFRS with Regression Line') +
  xlab('CCI (Charlson Comorbidity Index)') +
  ylab('HFRS (Hospital Frailty Risk Score)') +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 16),
        axis.title = element_text(size = 14),
        axis.text = element_text(size = 12)) +
  labs(caption = paste("Pearson correlation coefficient:", round(pearson_corr, 2), ", p-value:", round(p_value_corr, 4)))

print("7: Scatter plot done successfully.")

# 8: Save the Scatter plot
plot_path_scatter <- '/home/work/plots/Rcode/w21.scatter_plot_of_HFRS_CCI.png'
ggsave(plot_path_scatter, plot = scatter_plot, width = 10, height = 6)

print(paste("8: Visualization of Scatter plot saved to", plot_path_scatter))

print("9: Correlation analysis completed.")
