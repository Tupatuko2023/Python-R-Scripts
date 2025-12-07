# KAAOS 3.7: Main Script for Longitudinal Analysis Pipeline of Fear of Falling & Functional Performance
# [K3.7.main.R]

# "Executes a full analysis pipeline: imports & preprocesses data, transforms it, 
#  computes stats & effect sizes, merges results, and exports CSV"

########################################################################################################
#  Sequence list
########################################################################################################

# 1: Set Working Directory
# 2: Data Import and Preliminary Processing
# 3: Data Transformation
# 4: Statistical Analysis
# 5: Effect Size Calculations and Helper Functions
# 6: Skewness and Kurtosis Helper Functions
# 7: Combining and Exporting Results
# 8: End of Main Script

########################################################################################################
########################################################################################################

# 1: Set Working Directory C:\Users\tomik\OneDrive\TUTKIMUS\Päijät-Sote\P-Sote\P-Sote
setwd("C:/Users/tomik/OneDrive/TUTKIMUS/Päijät-Sote/P-Sote/P-Sote")

# 2: Data Import and Preliminary Processing
source("K1.1.data_import.R")

# 3: Data Transformation
source("K3.2.data_transformation.R")

# 4: Statistical Analysis
source("K3.3.statistical_analysis.R")

# 5: Effect Size Calculations and Helper Functions
source("K3.4.effect_sizes.R")

# 6: Skewness and Kurtosis Helper Functions
source("K1.5.kurtosis_skewness.R")

# 7: Combining Results
source("K3.6.results_export.R")

# 8: End of Main Script
cat("Analysis pipeline completed successfully.\n")


