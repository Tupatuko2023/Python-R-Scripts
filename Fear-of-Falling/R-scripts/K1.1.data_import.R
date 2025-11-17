# KAAOS 1.1: R Script for Data Import and Preliminary Processing of the KaatumisenPelko Dataset
# [K1.1.data_import.R]

# "This R script imports a Stata dataset, loads key libraries, inspects its structure, and 
# converts key categorical variables to factors for analysis."

########################################################################################################
#  Sequence list
########################################################################################################

# 1: Install and Load Required Packages
# 2: Load Required Libraries
# 3: Define the File Path
# 4: Read the Dataset
# 5: Inspect the Structure of the Dataset and Preview the Data
# 6: Convert Categorical Variables to Factors

########################################################################################################
########################################################################################################

# 1: Install and Load Required Packages

#install.packages("ggplot2")  # For visualization
#install.packages("dplyr")    # For data manipulation
#install.packages("tidyr")    # For transforming data into long format
#install.packages("boot")     # For calculating confidence intervals
#install.packages("haven")    # For reading .dta files
#install.packages("tidyverse")
#install.packages("moments")  # For skewness and kurtosis calculations
#install.packages("broom")
#install.packages("stringr")

# 2: Load Required Libraries
library(ggplot2)   # For data visualization
library(dplyr)     # For data manipulation
library(tidyr)     # For reshaping data into long format
library(boot)      # For computing confidence intervals
library(haven)     # For reading Stata (.dta) files
library(stringr)   # For string manipulation
library(broom)     # For tidying statistical test outputs
library(moments)   # For computing skewness and kurtosis
library(stringr)   # for str_detect()

# 3: Define the File Path
file_path <- "C:/Users/tomik/OneDrive/TUTKIMUS/Päijät-Sote/P-Sote/P-Sote/dataset/KaatumisenPelko.dta"

# 4: Read the Dataset
data <- read_dta(file_path)

# 5: Inspect the Structure of the Dataset and Preview the Data
str(data)    # Displays the structure and variable types of the dataset
head(data)   # Displays the first few rows of the dataset

# 6: Convert Categorical Variables to Factors
data$kaatumisenpelkoOn <- as.factor(data$kaatumisenpelkoOn)  # 0 = no fear, 1 = fear of falling
data$sex <- as.factor(data$sex)                              # 0 = female, 1 = male

# End of K1.1.data_import.R
