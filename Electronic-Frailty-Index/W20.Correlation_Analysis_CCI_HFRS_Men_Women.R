# Work 20: Correlation Analysis of CCI and HFRS by Gender: An R Script 
# [W20.Correlation_Analysis_CCI_HFRS_Men_Women.R] 

# "This R script performs correlation analysis between CCI and HFRS for men and women, 
#  visualizing results with heatmaps and scatter plots.#

########################################################################################################
#  Sequence list
########################################################################################################

# 1: Load necessary libraries
# 2: Load data
# 3: Ensure 'Potilas_ID' is the same type in both dataframes
# 4: Check if 'Potilas_ID' column exists in both dataframes
# 5: Ensure columns are numeric
# 6: Drop rows with missing values in CCI or HFRS
# 7: Merge demo_df to add gender information
# 8: Perform correlation analysis for men and women separately
# 9: Separate data for men and women
# 10: Calculate Pearson correlation coefficient
# 11: Visualize the correlation for men
# 12: Save the visualization
# 13: Visualize the correlation for women
# 14: Save the visualization
# 15: Scatter plot for men
# 16: Save the scatter plot for men
# 17: Scatter plot for women
# 18: Save the scatter plot for women
# 19: Correlation analysis for men and women completed

########################################################################################################
########################################################################################################

 
# 1: Load necessary libraries
library(ggplot2)
library(reshape2)

# 2: Load data
data_path <- '/home/work/pp_all_data_with_cci.csv'
demo_path <- '/home/work/demographicd.csv'

data <- read.csv(data_path, stringsAsFactors = FALSE)
demo_df <- read.csv(demo_path, sep = '|', stringsAsFactors = FALSE)

print("2: Data loaded successfully.")

# 3: Ensure 'Potilas_ID' is the same type in both dataframes
data$Potilas_ID <- as.character(data$Potilas_ID)
demo_df$Potilas_ID <- as.character(demo_df$Potilas_ID)

# 4: Check if 'Potilas_ID' column exists in both dataframes
if(!'Potilas_ID' %in% colnames(data)) stop("'Potilas_ID' not found in data dataframe")
if(!'Potilas_ID' %in% colnames(demo_df)) stop("'Potilas_ID' not found in demo_df dataframe")

# 5: Ensure columns are numeric
data$CCI <- as.numeric(as.character(data$CCI))
data$HFRS <- as.numeric(as.character(data$HFRS))

print("5: Columns are numeric.")

# 6: Drop rows with missing values in CCI or HFRS
data <- na.omit(data[, c('CCI', 'HFRS')])

print("6: Missing values dropped.")

# 7: Merge demo_df to add gender information
data <- merge(data, demo_df[, c('Potilas_ID', 'Sukupuoli')], by = 'Potilas_ID', all.x = TRUE)

print("7: Gender information merged successfully.")

# 8: Perform correlation analysis for men and women separately

# 9: Separate data for men and women
data_men <- subset(data, Sukupuoli == 'Mies')
data_women <- subset(data, Sukupuoli == 'Nainen')

# 10: Calculate Pearson correlation coefficient
correlation_men <- cor(data_men$CCI, data_men$HFRS)
p_value_corr_men <- cor.test(data_men$CCI, data_men$HFRS)$p.value
correlation_women <- cor(data_women$CCI, data_women$HFRS)
p_value_corr_women <- cor.test(data_women$CCI, data_women$HFRS)$p.value

print(paste("10: Men: Pearson correlation coefficient for men:", correlation_men, ", p-value:", p_value_corr_men))
print(paste("10: Women: Pearson correlation coefficient for women:", correlation_women, ", p-value:", p_value_corr_women))

# 11: Visualize the correlation for men
heatmap_men <- ggplot(melt(correlation_men), aes(Var1, Var2, fill = value)) +
  geom_tile() +
  geom_text(aes(label = round(value, 2)), color = "white") +
  scale_fill_gradient2(low = "lightblue", high = "darkred", mid = "white", 
                       midpoint = 0, limit = c(-1, 1), space = "Lab", 
                       name="Pearson\nCorrelation") +
  theme_classic() +
  ggtitle("Correlation between CCI and HFRS (Men)") +
  theme(plot.title = element_text(hjust = 0.5, size = 20),
        axis.title = element_text(size = 16),
        axis.text = element_text(size = 14))

# 12: Save the visualization
plot_path_viz_men <- '/home/work/plots/Rcode/w20.correlation_of_HFRS_CCI_men.png'
ggsave(plot_path_viz_men, plot = heatmap_men, width = 10, height = 6)

print(paste("12: Visualization of correlation for men saved to", plot_path_viz_men))

# 13: Visualize the correlation for women
heatmap_women <- ggplot(melt(correlation_women), aes(Var1, Var2, fill = value)) +
  geom_tile() +
  geom_text(aes(label = round(value, 2)), color = "white") +
  scale_fill_gradient2(low = "lightblue", high = "darkred", mid = "white", 
                       midpoint = 0, limit = c(-1, 1), space = "Lab", 
                       name="Pearson\nCorrelation") +
  theme_classic() +
  ggtitle("Correlation between CCI and HFRS (Women)") +
  theme(plot.title = element_text(hjust = 0.5, size = 20),
        axis.title = element_text(size = 16),
        axis.text = element_text(size = 14))

# 14: Save the visualization
plot_path_viz_women <- '/home/work/plots/Rcode/w20.correlation_of_HFRS_CCI_women.png'
ggsave(plot_path_viz_women, plot = heatmap_women, width = 10, height = 6)

print(paste("14: Visualization of correlation for women saved to", plot_path_viz_women))

# 15: Scatter plot for men
scatter_plot_men <- ggplot(data_men, aes(x = CCI, y = HFRS)) +
  geom_point() +
  geom_smooth(method = 'lm', col = 'blue', aes(linetype = "Regression Line")) +
  scale_linetype_manual(name = "Legend", values = c("Regression Line" = 1)) +
  ggtitle('Scatter Plot of CCI vs. HFRS (Men)') +
  xlab('CCI (Charlson Comorbidity Index)') +
  ylab('HFRS (Hospital Frailty Risk Score)') +
  theme_classic() +
  theme(plot.title = element_text(hjust = 0.5, size = 20),
        axis.title = element_text(size = 16),
        axis.text = element_text(size = 14),
        legend.title = element_text(size = 14),
        legend.text = element_text(size = 12)) +
  labs(caption = paste("Pearson correlation coefficient:", round(correlation_men, 2), ", p-value:", round(p_value_corr_men, 4)))

# 16: Save the scatter plot for men
plot_path_scatter_men <- '/home/work/plots/Rcode/w20.scatter_plot_of_HFRS_CCI_men.png'
ggsave(plot_path_scatter_men, plot = scatter_plot_men, width = 10, height = 6)

print(paste("16: Scatter plot for men saved to", plot_path_scatter_men))

# 17: Scatter plot for women
scatter_plot_women <- ggplot(data_women, aes(x = CCI, y = HFRS)) +
  geom_point() +
  geom_smooth(method = 'lm', col = 'blue', aes(linetype = "Regression Line")) +
  scale_linetype_manual(name = "Legend", values = c("Regression Line" = 1)) +
  ggtitle('Scatter Plot of CCI vs. HFRS (Women)') +
  xlab('CCI (Charlson Comorbidity Index)') +
  ylab('HFRS (Hospital Frailty Risk Score)') +
  theme_classic() +
  theme(plot.title = element_text(hjust = 0.5, size = 20),
        axis.title = element_text(size = 16),
        axis.text = element_text(size = 14),
        legend.title = element_text(size = 14),
        legend.text = element_text(size = 12)) +
  labs(caption = paste("Pearson correlation coefficient:", round(correlation_women, 2), ", p-value:", round(p_value_corr_women, 4)))

# 18: Save the scatter plot for women
plot_path_scatter_women <- '/home/work/plots/Rcode/w20.scatter_plot_of_HFRS_CCI_women.png'
ggsave(plot_path_scatter_women, plot = scatter_plot_women, width = 10, height = 6)

print(paste("18: Scatter plot for women saved to", plot_path_scatter_women))

print("19: Correlation analysis for men and women completed.")



