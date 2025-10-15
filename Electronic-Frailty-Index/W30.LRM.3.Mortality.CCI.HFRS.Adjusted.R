# Work 30: Logistic Regression Analysis on Mortality Using CCI and HFRS with Adjustments for Birth Year and Gender
# [W30.LRM.3.Mortality.CCI.HFRS.Adjusted.R] 

# "This R script performs logistic regression analysis on mortality using CCI and HFRS, adjusting for birth year and 
# gender, with separate models for men and women."

########################################################################################################
#  Sequence list
########################################################################################################

# 1: Install the necessary packages separately
# 2: Load the necessary libraries
# 3: Load the data
# 4: Check the size of the original dataset
# 5: Ensure that `Patient_ID` is of the same type in both data frames
# 6: Convert columns to numeric
# 7: Check how many missing values are in each column
# 8: Remove missing values only from CCI and HFRS columns
# 9: Check the size of the dataset after `na.omit` operation
# 10: Merge demographic data to add gender, birth year, and death year information
# 11: Create a new column indicating whether the person is alive or deceased
# 12: Define independent variables and target variable
# 13: Ensure all data is numeric
# 14: Remove rows with NaN values
# 15: Check the size of the datasets before splitting into training and testing sets
# 16: Split the data into training and testing sets
# 17: Fit a logistic regression model
# 18: Model summary
# 19: Make predictions on the test set
# 20: Print classification report
# 21: Perform logistic regression for men and women separately

########################################################################################################
########################################################################################################
# 1: Install the necessary packages separately
# install.packages("dplyr")
# install.packages("caret")
# install.packages("glmnet")
# install.packages("broom")

# 2: Load the necessary libraries
library(dplyr)
library(caret)
library(glmnet)
library(broom)

# 3: Load the data
data_path = '/home/work/pp_all_data_with_cci.csv'
demo_path = '/home/work/demographicd.csv'

data <- read.csv(data_path, stringsAsFactors = FALSE)
demo_df <- read.csv(demo_path, sep = '|', stringsAsFactors = FALSE)

# 4: Check the size of the original dataset
cat("Size of the original dataset: ", nrow(data), "\n")

# 5: Ensure that `Patient_ID` is of the same type in both data frames
data$Patient_ID <- as.character(data$Patient_ID)
demo_df$Patient_ID <- as.character(demo_df$Patient_ID)

# 6: Convert columns to numeric
data$CCI <- as.numeric(data$CCI)
data$HFRS <- as.numeric(data$HFRS)
demo_df$BirthYear <- as.numeric(demo_df$BirthYear)

# 7: Check how many missing values are in each column
cat("Missing values in CCI column: ", sum(is.na(data$CCI)), "\n")
cat("Missing values in HFRS column: ", sum(is.na(data$HFRS)), "\n")

# 8: Remove missing values only from CCI and HFRS columns
data <- data[complete.cases(data$CCI, data$HFRS), ]

# 9: Check the size of the dataset after `na.omit` operation
cat("Size of the dataset after `na.omit` operation: ", nrow(data), "\n")

# 10: Merge demographic data to add gender, birth year, and death year information
data <- merge(data, demo_df[, c('Patient_ID', 'BirthYear', 'Gender', 'DeathYear')], by = 'Patient_ID', all.x = TRUE)

# 11: Create a new column indicating whether the person is alive or deceased
data$Deceased <- ifelse(is.na(data$DeathYear), 0, 1)

# 12: Define independent variables and target variable
X <- data %>% select(CCI, HFRS, BirthYear, Gender)
X <- X %>% mutate(Gender = ifelse(Gender == 'Male', 1, 0)) # Convert gender to dummy variable
y <- data$Deceased

# 13: Ensure all data is numeric
X <- as.data.frame(sapply(X, as.numeric))
y <- as.numeric(y)

# 14: Remove rows with NaN values
X <- na.omit(X)
y <- y[complete.cases(X)]

# 15: Check the size of the datasets before splitting into training and testing sets
cat("Number of rows in X: ", nrow(X), "\n")
cat("Number of rows in y: ", length(y), "\n")

# 16: Split the data into training and testing sets
if (nrow(X) > 1 & length(y) > 1) {
  set.seed(42)
  trainIndex <- createDataPartition(y, p = .8, list = FALSE, times = 1)
  X_train <- X[trainIndex, ]
  X_test <- X[-trainIndex, ]
  y_train <- y[trainIndex]
  y_test <- y[-trainIndex]
  
  # 17: Fit a logistic regression model
  model <- glm(y_train ~ ., data = X_train, family = binomial())
  
  # 18: Model summary
  summary(model)
  
  # 19: Make predictions on the test set
  y_pred <- predict(model, newdata = X_test, type = 'response')
  y_pred_class <- ifelse(y_pred > 0.5, 1, 0)
  
  # 20: Print classification report
  conf_matrix <- confusionMatrix(as.factor(y_pred_class), as.factor(y_test))
  print(conf_matrix)
  
  # 21: Perform logistic regression for men and women separately
  for (gender in c('Male', 'Female')) {
    data_gender <- subset(data, Gender == gender)
    X_gender <- data_gender %>% select(CCI, HFRS, BirthYear)
    y_gender <- data_gender$Deceased
    
    if (nrow(data_gender) > 1) {
      set.seed(42)
      trainIndex_gender <- createDataPartition(y_gender, p = .8, list = FALSE, times = 1)
      X_train_g <- X_gender[trainIndex_gender, ]
      X_test_g <- X_gender[-trainIndex_gender, ]
      y_train_g <- y_gender[trainIndex_gender]
      y_test_g <- y_gender[-trainIndex_gender]
      
      model_gender <- glm(y_train_g ~ ., data = X_train_g, family = binomial())
      
      cat("\nLogistic Regression Results for", gender, ":\n")
      print(summary(model_gender))
      
      y_pred_g <- predict(model_gender, newdata = X_test_g, type = 'response')
      y_pred_class_g <- ifelse(y_pred_g > 0.5, 1, 0)
      
      conf_matrix_gender <- confusionMatrix(as.factor(y_pred_class_g), as.factor(y_test_g))
      print(conf_matrix_gender)
    } else {
      cat("Too little data to perform analysis.\n")
    }
  }
} else {
  cat("Too little data to perform analysis.\n")
}