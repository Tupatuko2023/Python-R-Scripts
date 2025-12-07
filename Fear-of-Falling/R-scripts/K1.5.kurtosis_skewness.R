# KAAOS 1.5: R Script for Interpreting Distribution Normality (Skewness & Kurtosis)
# [K1.5.kurtosis_skewness.R]

# "Interprets distribution normality by labeling skewness and kurtosis, following 
# Hair et al. (2022) thresholds for nonnormality and guidelines in usage."

########################################################################################################
#  Sequence list
########################################################################################################

# 1: Function to interpret skewness 
# 2: Function to interpret kurtosis 

# Reference: Hair, J. F., Hult, G. T. M., Ringle, C. M., & Sarstedt, M. (2022). A Primer on Partial 
#            Least Squares Structural Equation Modeling (PLS-SEM) (3 ed.). Thousand Oaks, CA: Sage.
########################################################################################################
########################################################################################################

# 1: Function to interpret skewness
skewness_label <- function(skew_val) {
  if (is.na(skew_val)) return("")
  abs_skew <- abs(skew_val)
  if (abs_skew <= 1) {
    return("Excellent")
  } else if (abs_skew <= 2) {
    return("Generally Acceptable")
  } else {
    return("Substantial nonnormality")
  }
}

# 2: Function to interpret kurtosis 
kurtosis_label <- function(kurt_val) {
  if (is.na(kurt_val)) return("")
  if (kurt_val > 2) {
    return("Too peaked")
  } else if (kurt_val < -2) {
    return("Too flat")
  } else {
    return("Normal distribution")
  }
}


