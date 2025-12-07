# KAAOS 1: Longitudinal Analysis of Fear of Falling and Functional Performance: Data Processing
#          and Statistical Computation in R
# [K1.Z_Score_Change_2G_v3.R]
# This R script processes longitudinal data on fear of falling, transforms it,
# computes statistical summaries, performs t-tests, and exports the results.
########################################################################################################
#  Sequence list
########################################################################################################
# 1: Install and load required packages
# 2: Define the File Path
# 3: Load the Dataset
# 4: Inspect the Structure of the Dataset
# 5: Data Transformation
# 6: Statistical Computation
# 7: T-tests
# 8: Export Results
########################################################################################################
# 1: Install and load required packages
########################################################################################################
# Uncomment and run the following lines to install the required packages
# install.packages("dplyr")
# install.packages("tidyr")
# install.packages("ggplot2")
# install.packages("readr")
# install.packages("purrr")
# install.packages("broom")

# Load the required packages
library(dplyr)
library(tidyr)
library(ggplot2)
library(readr)
library(purrr)
library(broom)
########################################################################################################
# 2: Define the File Path
########################################################################################################
# Set the file path to the location of your dataset
file_path <- "path/to/your/dataset.csv"
########################################################################################################
# 3: Load the Dataset
########################################################################################################
# Load the dataset into R
data <- read_csv(file_path)
########################################################################################################
# 4: Inspect the Structure of the Dataset
########################################################################################################
# View the first few rows of the dataset
head(data)

# Get a summary of the dataset
summary(data)

# Check the structure of the dataset
str(data)
########################################################################################################
# 5: Data Transformation
########################################################################################################
# Transform the data as needed for analysis
# This may include filtering rows, selecting columns, renaming variables, etc.

# Example: Filter rows where fear_of_falling is not NA
data_filtered <- data %>% 
  filter(!is.na(fear_of_falling))
########################################################################################################
# 6: Statistical Computation
########################################################################################################
# Compute statistical summaries of the data
# This may include means, medians, standard deviations, etc.

# Example: Compute the mean and standard deviation of fear_of_falling
stats <- data_filtered %>% 
  summarise(
    mean_fear_of_falling = mean(fear_of_falling, na.rm = TRUE),
    sd_fear_of_falling = sd(fear_of_falling, na.rm = TRUE)
  )
########################################################################################################
# 7: T-tests
########################################################################################################
# Perform t-tests to compare groups
# This may include independent t-tests, paired t-tests, etc.

# Example: Perform a t-test comparing fear_of_falling between two groups
t_test_results <- t.test(fear_of_falling ~ group, data = data_filtered)
########################################################################################################
# 8: Export Results
########################################################################################################
# Export the results of the analysis to a file
# This may include writing tables, figures, etc. to files

# Example: Write the statistical summaries to a CSV file
write_csv(stats, "path/to/save/stats.csv")

# Example: Save the t-test results to a text file
capture.output(t_test_results, file = "path/to/save/t_test_results.txt")