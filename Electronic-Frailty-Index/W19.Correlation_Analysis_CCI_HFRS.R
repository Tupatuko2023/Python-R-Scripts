# Work 19: Correlation Analysis and Visualization of CCI and HFRS Using R [W19.Correlation_Analysis_CCI_HFRS.R] 

# "This R script loads data, ensures numeric columns, drops missing values, performs correlation analysis, 
#  and visualizes results with heatmaps and scatter plots."

########################################################################################################
#  Sequence list
########################################################################################################

# 1: Load necessary libraries
# 2: Load the updated data
# 3: Ensure columns are numeric
# 4: Drop rows with missing values in CCI or HFRS
# 5: Perform correlation analysis
# 6a: Visualize the correlation
# 7b: Save the Visualization
# 8a: Scatter plot for additional visualization
# 9b: Save the Scatter plot
# 10: Correlation analysis completed

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

# 5: Perform correlation analysis
correlation <- cor(data$CCI, data$HFRS)
correlation_matrix <- cor(data[, c('CCI', 'HFRS')])
print("4: Correlation analysis:")
print(correlation_matrix)

# 6a: Visualize the correlation
correlation_melt <- melt(correlation_matrix)
heatmap <- ggplot(correlation_melt, aes(Var1, Var2, fill = value)) +
  geom_tile() +
  geom_text(aes(label = round(value, 2)), color = "white") +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                       midpoint = 0, limit = c(-1, 1), space = "Lab", 
                       name="Pearson\nCorrelation") +
  theme_minimal() +
  ggtitle("Correlation between CCI and HFRS") +
  xlab("CCI (Charlson Comorbidity Index)") +
  ylab("HFRS (Hospital Frailty Risk Score)") +
  theme(plot.title = element_text(hjust = 0.5, size = 16),
        axis.title = element_text(size = 14),
        axis.text = element_text(size = 12)) +
  labs(caption = "This heatmap shows the Pearson correlation between CCI and HFRS. Values close to 1 or -1 indicate strong correlation.")

print("6a: Visualized correlation successfully.")

# 7b: Save the Visualization
plot_path_viz <- '/home/work/plots/Rcode/W19.correlation_of_HFRS_CCI.png'
ggsave(plot_path_viz, plot = heatmap, width = 10, height = 6)

print(paste("7b: Visualization of correlation saved to", plot_path_viz))

# 8a: Scatter plot for additional visualization
scatter_plot <- ggplot(data, aes(x = CCI, y = HFRS)) +
  geom_point() +
  geom_smooth(method = 'lm', col = 'blue') +
  ggtitle('Scatter Plot of CCI vs. HFRS') +
  xlab('CCI (Charlson Comorbidity Index)') +
  ylab('HFRS (Hospital Frailty Risk Score)') +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 16),
        axis.title = element_text(size = 14),
        axis.text = element_text(size = 12))

print("8a: Scatter plot done successfully.")

# 9b: Save the Scatter plot
plot_path_scatter <- '/home/work/plots/Rcode/W19.scatter_plot_of_HFRS_CCI.png'
ggsave(plot_path_scatter, plot = scatter_plot, width = 10, height = 6)

print(paste("9b: Visualization of Scatter plot saved to", plot_path_scatter))

print("10: Correlation analysis completed.")
