#!/usr/bin/env Rscript
# ==============================================================================
# K1.5_DISTRIB - Distribution Normality Interpretation (Skewness & Kurtosis)
# File tag: K1.5_DISTRIB.V1_kurtosis-skewness.R
# Purpose: Provide helper functions to interpret skewness and kurtosis values
#
# Input: None (defines helper functions only)
# Output: Two functions available in environment: skewness_label(), kurtosis_label()
#
# Functions defined:
# - skewness_label(skew_val): Categorizes skewness as Excellent, Acceptable, or Substantial nonnormality
# - kurtosis_label(kurt_val): Categorizes kurtosis as Too peaked, Too flat, or Normal distribution
#
# Reference: Hair, J. F., Hult, G. T. M., Ringle, C. M., & Sarstedt, M. (2022).
#            A Primer on Partial Least Squares Structural Equation Modeling (PLS-SEM) (3rd ed.).
#            Thousand Oaks, CA: Sage.
#
# Note: This script is SHARED by both K1 and K3 pipelines
#       (sourced by K1.7.main.R and K3.7.main.R)
# ==============================================================================

# Function to interpret skewness
# Thresholds based on Hair et al. (2022):
# - Excellent: |skew| <= 1
# - Generally Acceptable: 1 < |skew| <= 2
# - Substantial nonnormality: |skew| > 2
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

# Function to interpret kurtosis
# Thresholds based on Hair et al. (2022):
# - Normal distribution: -2 <= kurtosis <= 2
# - Too peaked: kurtosis > 2
# - Too flat: kurtosis < -2
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

cat("Distribution normality interpretation functions loaded:\n")
cat("  - skewness_label()\n")
cat("  - kurtosis_label()\n")

# EOF
