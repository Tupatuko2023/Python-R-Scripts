library(testthat)
library(dplyr)
library(tibble)

cat("Current WD:", getwd(), "\n")

# Robust sourcing
if (file.exists("src/analytics/table1_utils.R")) {
  source("src/analytics/table1_utils.R")
} else if (file.exists("../../src/analytics/table1_utils.R")) {
  source("../../src/analytics/table1_utils.R")
} else {
  stop("Could not find src/analytics/table1_utils.R from ", getwd())
}

test_that('create_table1 handles numeric and categorical data', {
  df <- tibble(
    age = c(50, 60, 70, 80, 55),
    gender = c('M', 'F', 'F', 'M', 'F')
  )
  
  tbl <- create_table1(df, vars = c('age', 'gender'))
  
  # Check Numeric
  age_row <- tbl %>% filter(Variable == 'age')
  expect_true(grepl('\\(', age_row$Stat)) 
  
  # Check Categorical
  gender_rows <- tbl %>% filter(Variable == 'gender')
  expect_equal(nrow(gender_rows), 2)
})

test_that('create_table1 enforces PRIVACY (n<5)', {
  df <- tibble(
    disease = c('Rare', 'Common', 'Common', 'Common', 'Common', 'Common')
  )
  
  tbl <- create_table1(df, vars = 'disease')
  
  # 'Rare' has n=1, must be suppressed
  rare_row <- tbl %>% filter(Level == 'Rare')
  expect_equal(rare_row$Stat, 'n<5')
  
  # 'Common' has n=5, must be shown
  common_row <- tbl %>% filter(Level == 'Common')
  expect_true(grepl('%', common_row$Stat))
})
