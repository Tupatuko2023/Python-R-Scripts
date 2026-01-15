library(testthat)
library(dplyr)
source("../../src/analytics/privacy_utils.R")

test_that("suppress_small_cells works on numeric columns", {
  df <- tibble(
    id = 1:3,
    count = c(2, 5, 10),
    other = c(10, 10, 10)
  )
  
  # Apply to 'count'
  res <- suppress_small_cells(df, count, min_n = 5)
  
  expect_equal(res$count, c("n<5", "5", "10"))
  expect_equal(class(res$count), "character")
  expect_equal(res$other, c(10, 10, 10)) # Should be untouched and numeric
})

test_that("tidy selection works", {
  df <- tibble(
    a_val = c(3, 6),
    b_val = c(4, 7),
    id = c("A", "B")
  )
  
  res <- suppress_small_cells(df, ends_with("val"), min_n = 5)
  
  expect_equal(res$a_val, c("n<5", "6"))
  expect_equal(res$b_val, c("n<5", "7"))
  expect_equal(res$id, c("A", "B"))
})

test_that("non-numeric columns are ignored gracefully", {
   df <- tibble(
    char_col = c("a", "b"),
    num_col = c(2, 10)
   )
   
   # Try to apply to char_col
   res <- suppress_small_cells(df, char_col, num_col)
   
   expect_equal(res$char_col, c("a", "b")) # Should be unchanged
   expect_equal(res$num_col, c("n<5", "10"))
})
