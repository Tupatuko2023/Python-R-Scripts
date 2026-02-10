#!/usr/bin/env Rscript
# ==============================================================================
# check_ingest.R
# Purpose: Verify integrity of ingestion pipeline (Staging -> Derived).
# Usage: Rscript R/qc/check_ingest.R
# ==============================================================================

suppressPackageStartupMessages({
  library(arrow)
  library(testthat)
  library(dplyr)
})

# Load common utilities
common_script <- file.path("R", "common.R")
if (!file.exists(common_script)) {
  # Try relative to script location
  common_script <- file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly=FALSE), value=TRUE)[1])), "..", "common.R")
}
if (file.exists(common_script)) {
  source(common_script)
} else {
  stop("common.R not found.")
}

DATA_ROOT <- ensure_data_root()

staging_dir <- file.path(DATA_ROOT, "staging")
derived_dir <- file.path(DATA_ROOT, "derived")
manifest_path <- file.path(DATA_ROOT, "manifest", "manifest.csv")

test_that("Environment is sane", {
  expect_true(dir.exists(staging_dir))
  expect_true(dir.exists(derived_dir))
  expect_true(file.exists(manifest_path))
})

test_that("Staging files exist", {
  expect_true(file.exists(file.path(staging_dir, "paper_02_kaaos.parquet")))
  # sotut is optional but good to check
  if (file.exists(file.path(staging_dir, "paper_02_sotut.parquet"))) {
    sotut <- arrow::read_parquet(file.path(staging_dir, "paper_02_sotut.parquet"))
    expect_true("nro" %in% names(sotut))
  }
})

test_that("Staging schema is correct", {
  df <- arrow::read_parquet(file.path(staging_dir, "paper_02_kaaos.parquet"))
  expect_true("id" %in% names(df))
  expect_true("FOF" %in% names(df))
  expect_true("age" %in% names(df))
  expect_true("sex" %in% names(df))

  # Check types
  expect_true(is.integer(df$FOF) || is.numeric(df$FOF))
  expect_true(is.integer(df$age) || is.numeric(df$age))
})

test_that("Derived files exist", {
  expect_true(file.exists(file.path(derived_dir, "table1_cohort.parquet")))
})

test_that("Manifest is updated", {
  manifest <- read.csv(manifest_path)
  expect_true("staging/paper_02_kaaos.parquet" %in% manifest$file)
  expect_true("derived/table1_cohort.parquet" %in% manifest$file)
})

message("QC Check Complete: All tests passed.")
