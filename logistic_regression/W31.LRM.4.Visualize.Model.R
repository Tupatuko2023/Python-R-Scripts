# Work 31: Logistic Regression for Mortality Using CCI and HFRS with 
#          Gender-Specific Analyses and Comprehensive Model Visualizations
#  [W31.LRM.4.Visualize.Model.R]

# "Trains logistic regression on mortality with separate gender analyses, then visualizes all performance 
# metrics, thresholds, and coefficient insights"


########################################################################################################
#  Sequence list
########################################################################################################
# 1: Load necessary libraries
# 2: Load the data
# 3: Check the size of the original dataset
# 4: Ensure 'Potilas_ID' is the same type in both dataframes
# 5: Check if 'Potilas_ID' column exists in both dataframes
# 6: Convert columns to numeric
# 7: Check the number of missing values in CCI and HFRS
# 8: Remove missing values only from CCI and HFRS columns
# 9: Check the size of the dataset after removing NAs
# 10: Merge demographic data to add gender, birth year, and death year information
# 11: Create a new column indicating whether the person is alive or dead
# 12: Define independent variables and the target variable
# 13: Ensure all data is numeric
# 14: Remove rows with NaN values
# 15: Check the size of the dataset before splitting into training and testing sets
# 16: Split the data into training and testing sets
# 17: Fit a logistic regression model
# 18: Model summary
# 19: Make predictions on the test set
# 20: Print classification report
# 21: Perform logistic regression separately for men and women
# 22: Compute ROC and AUC
# 23: Plot ROC curve
# 24: Highlight the optimal point (Youden's J statistic)
# 25: Save ROC Curve and AUC
# 26: Confusion Matrix
# 27: Create a dataframe from the confusion matrix
# 28: Calculate accuracy, sensitivity, and specificity
# 29: Plot Confusion Matrix
# 30: Save Confusion Matrix plot
# 31: Precision-Recall Curve
# 32: Plot Precision-Recall Curve
# 33: Save Precision-Recall Curve
# 34: Coefficient Plot
# 35: Distribution of Predicted Probabilities
# 36: Save Distribution of Predicted Probabilities

########################################################################################################
########################################################################################################
# 1: Load necessary libraries
library(dplyr)
library(caret)
library(glmnet)
library(broom)
library(pROC)
library(ggplot2)
library(PRROC)

# 2: Load the data
data_path <- '/home/work/pp_all_data_with_cci.csv'
demo_path <- '/home/work/demographicd.csv'
data <- read.csv(data_path, stringsAsFactors = FALSE)
demo_df <- read.csv(demo_path, sep = '|', stringsAsFactors = FALSE)
cat("2: Data loaded.\n")

# 3: Check the size of the original dataset
cat("3: Size of the original dataset:", nrow(data), "\n")

# 4: Ensure 'Potilas_ID' is the same type in both dataframes
data$Potilas_ID <- as.character(data$Potilas_ID)
demo_df$Potilas_ID <- as.character(demo_df$Potilas_ID)

# 5: Check if 'Potilas_ID' column exists in both dataframes
if (!"Potilas_ID" %in% colnames(data)) {
  stop("'Potilas_ID' not found in data dataframe")
}
if (!"Potilas_ID" %in% colnames(demo_df)) {
  stop("'Potilas_ID' not found in demo_df dataframe")
}

# 6: Convert columns to numeric
data$CCI <- as.numeric(data$CCI)
data$HFRS <- as.numeric(data$HFRS)
demo_df$Syntymävuosi <- as.numeric(demo_df$Syntymävuosi)

# 7: Check the number of missing values in CCI and HFRS
cat("7: Missing values in CCI column:", sum(is.na(data$CCI)), "\n")
cat("7: Missing values in HFRS column:", sum(is.na(data$HFRS)), "\n")

# 8: Remove missing values only from CCI and HFRS columns
data <- data[complete.cases(data$CCI, data$HFRS), ]

# 9: Check the size of the dataset after removing NAs
cat("9: Size of the dataset after removing NAs:", nrow(data), "\n")

# 10: Merge demographic data to add gender, birth year, and death year information
data <- merge(
  data,
  demo_df[, c("Potilas_ID", "Syntymävuosi", "Sukupuoli", "Kuolinvuosi")],
  by = "Potilas_ID",
  all.x = TRUE
)

# 11: Create a new column indicating whether the person is alive or dead
data$Kuollut <- ifelse(is.na(data$Kuolinvuosi), 0, 1)

# 12: Define independent variables and the target variable
X <- data %>% select(CCI, HFRS, Syntymävuosi, Sukupuoli)
X <- X %>% mutate(Sukupuoli = ifelse(Sukupuoli == 'Mies', 1, 0))
y <- data$Kuollut

# 13: Ensure all data is numeric
X <- as.data.frame(sapply(X, as.numeric))
y <- as.numeric(y)

# 14: Remove rows with NaN values
X <- na.omit(X)
y <- y[complete.cases(X)]

# 15: Check the size of the dataset before splitting into training and testing sets
cat("15: Number of rows in X:", nrow(X), "\n")
cat("15: Number of rows in y:", length(y), "\n")

# 16: Split the data into training and testing sets
if (nrow(X) > 1 & length(y) > 1) {
  set.seed(42)
  trainIndex <- createDataPartition(y, p = 0.8, list = FALSE, times = 1)
  X_train <- X[trainIndex, ]
  X_test  <- X[-trainIndex, ]
  y_train <- y[trainIndex]
  y_test  <- y[-trainIndex]
  
  # 17: Fit a logistic regression model
  model <- glm(y_train ~ ., data = X_train, family = binomial())
  
  # 18: Model summary
  summary(model)
  
  # 19: Make predictions on the test set
  y_pred <- predict(model, newdata = X_test, type = "response")
  y_pred_class <- ifelse(y_pred > 0.5, 1, 0)
  
  # 20: Print classification report
  conf_matrix <- confusionMatrix(as.factor(y_pred_class), as.factor(y_test))
  print(conf_matrix)
  
  # 21: Perform logistic regression separately for men and women
  for (gender in c("Mies", "Nainen")) {
    data_gender <- subset(data, Sukupuoli == gender)
    X_gender <- data_gender %>% select(CCI, HFRS, Syntymävuosi)
    y_gender <- data_gender$Kuollut
    
    if (nrow(data_gender) > 1) {
      set.seed(42)
      trainIndex_gender <- createDataPartition(y_gender, p = 0.8, list = FALSE, times = 1)
      X_train_g <- X_gender[trainIndex_gender, ]
      X_test_g  <- X_gender[-trainIndex_gender, ]
      y_train_g <- y_gender[trainIndex_gender]
      y_test_g  <- y_gender[-trainIndex_gender]
      
      model_gender <- glm(y_train_g ~ ., data = X_train_g, family = binomial())
      
      cat("\nLogistic Regression Results for", gender, ":\n")
      print(summary(model_gender))
      
      y_pred_g <- predict(model_gender, newdata = X_test_g, type = "response")
      y_pred_class_g <- ifelse(y_pred_g > 0.5, 1, 0)
      
      conf_matrix_gender <- confusionMatrix(as.factor(y_pred_class_g), as.factor(y_test_g))
      print(conf_matrix_gender)
    } else {
      cat("21: Too little data to perform the analysis for gender:", gender, "\n")
    }
  }
  
  # 22: Compute ROC and AUC
  roc_curve <- roc(y_test, y_pred)
  auc_value <- auc(roc_curve)
  
  # 23: Plot ROC curve
  plot(
    roc_curve,
    main = paste("ROC Curve (AUC =", round(auc_value, 2), ")"),
    col = "blue",
    lwd = 2
  )
  abline(a = 0, b = 1, lty = 2, col = "red")
  
  # 24: Highlight the optimal point (Youden's J statistic)
  optimal_idx <- which.max(roc_curve$sensitivities + roc_curve$specificities - 1)
  optimal_threshold <- roc_curve$thresholds[optimal_idx]
  optimal_sensitivity <- roc_curve$sensitivities[optimal_idx]
  optimal_specificity <- roc_curve$specificities[optimal_idx]
  
  points(optimal_specificity, optimal_sensitivity, col = "green", pch = 19, cex = 1.5)
  text(
    optimal_specificity, optimal_sensitivity,
    labels = paste0("Threshold: ", round(optimal_threshold, 2)),
    pos = 4
  )
  
  legend(
    "bottomright",
    legend = c("ROC Curve", "Diagonal", "Optimal Point"),
    col = c("blue", "red", "green"),
    lty = c(1, 2, NA),
    pch = c(NA, NA, 19),
    lwd = c(2, 1, NA)
  )
  
  # 25: Save ROC Curve and AUC
  plot_ROC_Curve_and_AUC <- "/home/work/plots/Rcode/w31.ROC_Curve_and_AUC.png"
  png(plot_ROC_Curve_and_AUC)
  plot(
    roc_curve,
    main = paste("ROC Curve (AUC =", round(auc_value, 2), ")"),
    col = "blue",
    lwd = 2
  )
  abline(a = 0, b = 1, lty = 2, col = "red")
  points(optimal_specificity, optimal_sensitivity, col = "green", pch = 19, cex = 1.5)
  text(
    optimal_specificity, optimal_sensitivity,
    labels = paste0("Threshold: ", round(optimal_threshold, 2)),
    pos = 4
  )
  legend(
    "bottomright",
    legend = c("ROC Curve", "Diagonal", "Optimal Point"),
    col = c("blue", "red", "green"),
    lty = c(1, 2, NA),
    pch = c(NA, NA, 19),
    lwd = c(2, 1, NA)
  )
  dev.off()
  
  # 26: Confusion Matrix
  conf_matrix <- confusionMatrix(as.factor(y_pred_class), as.factor(y_test))
  
  # 27: Create a dataframe from the confusion matrix
  conf_df <- as.data.frame(conf_matrix$table)
  conf_df$Proportion <- conf_df$Freq / sum(conf_df$Freq)
  
  # 28: Calculate accuracy, sensitivity, and specificity
  accuracy <- sum(diag(conf_matrix$table)) / sum(conf_matrix$table)
  sensitivity <- conf_matrix$byClass["Sensitivity"]
  specificity <- conf_matrix$byClass["Specificity"]
  
  # 29: Plot Confusion Matrix
  conf_plot <- ggplot(conf_df, aes(Prediction, Reference, fill = Freq)) +
    geom_tile() +
    geom_text(aes(label = paste0(Freq, "\n(", round(Proportion * 100, 1), "%)")), color = "black") +
    scale_fill_gradient(low = "white", high = "blue") +
    ggtitle("Confusion Matrix") +
    xlab("Predicted Class") +
    ylab("Actual Class") +
    theme_minimal() +
    theme(
      plot.background = element_rect(fill = "gray90", color = NA),
      panel.background = element_rect(fill = "gray90", color = NA),
      axis.text = element_text(size = 12),
      axis.title = element_text(size = 14)
    ) +
    labs(caption = paste(
      "Accuracy:", round(accuracy, 2),
      "Sensitivity:", round(sensitivity, 2),
      "Specificity:", round(specificity, 2)
    ))
  
  # 30: Save Confusion Matrix plot
  plot_Confusion_Matrix <- "/home/work/plots/Rcode/w31.Confusion_Matrix.png"
  ggsave(plot_Confusion_Matrix, plot = conf_plot, width = 10, height = 6)
  
  # 31: Precision-Recall Curve
  pr <- pr.curve(scores.class0 = y_pred, weights.class0 = y_test, curve = TRUE)
  
  # 32: Plot Precision-Recall Curve
  plot(
    pr$curve,
    type = "l",
    col = "blue",
    lwd = 2,
    xlab = "Recall",
    ylab = "Precision",
    main = paste("PR curve", "\nAUC =", round(pr$auc.integral, 2))
  )
  abline(h = sum(y_test) / length(y_test), col = "red", lty = 2)
  legend(
    "bottomleft",
    legend = c("PR Curve", "Random Classifier"),
    col = c("blue", "red"),
    lty = c(1, 2),
    lwd = c(2, 1)
  )
  
  # 33: Save Precision-Recall Curve
  Precision_Recall_Curve_path <- "/home/work/plots/Rcode/w31.Precision_Recall_Curve.png"
  png(Precision_Recall_Curve_path)
  plot(
    pr$curve,
    type = "l",
    col = "blue",
    lwd = 2,
    xlab = "Recall",
    ylab = "Precision",
    main = paste("PR curve", "\nAUC =", round(pr$auc.integral, 2))
  )
  abline(h = sum(y_test) / length(y_test), col = "red", lty = 2)
  legend(
    "bottomleft",
    legend = c("PR Curve", "Random Classifier"),
    col = c("blue", "red"),
    lty = c(1, 2),
    lwd = c(2, 1)
  )
  dev.off()
  
  cat("33: Drew Precision-Recall Curve successfully.\n")
  cat(paste("33b: Precision-Recall Curve saved to", Precision_Recall_Curve_path, "\n"))
  
  # 34: Coefficient Plot
  coeff_data <- tidy(model)
  conf_intervals <- confint(model)
  coeff_data <- coeff_data %>%
    mutate(
      OR       = exp(estimate),
      Lower_CI = exp(conf_intervals[, 1]),
      Upper_CI = exp(conf_intervals[, 2])
    ) %>%
    filter(OR < 1000 & OR > -1000)
  
  coeff_plot <- ggplot(coeff_data, aes(x = term, y = OR)) +
    geom_bar(stat = "identity", fill = "skyblue", color = "black") +
    geom_errorbar(aes(ymin = Lower_CI, ymax = Upper_CI), width = 0.2) +
    ggtitle("Coefficient Plot with Confidence Intervals") +
    ylab("Odds Ratio") +
    xlab("Variables") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme_minimal(base_family = "Arial") +
    theme(
      plot.background = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA)
    )
  
  coeff_plot_path <- "/home/work/plots/Rcode/w31.Coefficient_Plot.png"
  ggsave(coeff_plot_path, plot = coeff_plot, width = 10, height = 6)
  
  # 35: Distribution of Predicted Probabilities
  y_pred <- predict(model, newdata = X_test, type = "response")
  
  ggplot(data.frame(y_pred), aes(x = y_pred)) +
    geom_histogram(bins = 50, fill = "blue", alpha = 0.7, color = "black") +
    geom_vline(aes(xintercept = mean(y_pred)), color = "red", linetype = "dashed", linewidth = 1) +
    geom_vline(aes(xintercept = median(y_pred)), color = "yellow", linetype = "dashed", linewidth = 1) +
    ggtitle("Distribution of Predicted Probabilities") +
    xlab("Predicted Probability of Mortality") +
    ylab("Frequency") +
    theme_minimal(base_family = "Arial") +
    theme(
      plot.background = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA)
    ) +
    labs(caption = paste(
      "Mean:", round(mean(y_pred), 2),
      "Median:", round(median(y_pred), 2)
    ))
  
  # 36: Save Distribution of Predicted Probabilities
  Db_Predicted_Probabilities_path <- "/home/work/plots/Rcode/w31.Db_Predicted_Probabilities.png"
  ggsave(Db_Predicted_Probabilities_path, width = 10, height = 6)
  
} else {
  cat("Too little data to perform the analysis.\n")
}


########################################################################################################
########################################################################################################


