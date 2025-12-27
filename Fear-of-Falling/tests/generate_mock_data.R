#!/usr/bin/env Rscript
# ==============================================================================
# Generate Mock Data for CI/CD Smoke Tests
# ==============================================================================
# Purpose: Create synthetic dataset with same structure as KaatumisenPelko.csv
#          for automated testing in GitHub Actions (where real data is encrypted)
#
# Usage: Rscript tests/generate_mock_data.R [output_path]
#        Default output: data/testing/mock_KaatumisenPelko.csv
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

set.seed(20251226)  # Reproducible mock data

# Sample size for mock data (keep it small for fast tests)
n <- 300

cat("Generating mock data with n =", n, "participants...\n")

# Generate synthetic dataset with all required columns
mock_data <- tibble(
  # === Core identifiers ===
  id = 1:n,
  NRO = 1:n,  # Alternative ID format used in some scripts

  # === Demographics ===
  age = round(rnorm(n, mean = 75, sd = 7)),  # Elderly population
  sex = sample(0:1, n, replace = TRUE, prob = c(0.9, 0.1)),  # 90% female
  BMI = round(rnorm(n, mean = 27, sd = 5), 1),

  # === Primary outcome: Fear of Falling (FOF) ===
  kaatumisenpelkoOn = sample(0:1, n, replace = TRUE, prob = c(0.6, 0.4)),  # 40% with FOF

  # === Composite functional performance (z-scores) ===
  ToimintaKykySummary0 = rnorm(n, mean = 0, sd = 1),  # Baseline composite
  ToimintaKykySummary2 = rnorm(n, mean = 0.1, sd = 1),  # 12-month follow-up

  # === Individual test z-scores (baseline and follow-up) ===
  # Walking speed (kävelynopeus)
  z_kavelynopeus0 = rnorm(n, mean = 0, sd = 1),
  z_kavelynopeus2 = rnorm(n, mean = 0.1, sd = 1),

  # Chair stand (Tuoli / FTSST)
  z_Tuoli0 = rnorm(n, mean = 0, sd = 1),
  z_Tuoli2 = rnorm(n, mean = 0.1, sd = 1),

  # Standing balance (Seisominen / SLS)
  z_Seisominen0 = rnorm(n, mean = 0, sd = 1),
  z_Seisominen2 = rnorm(n, mean = 0.1, sd = 1),

  # Grip strength (Puristus / HGS)
  z_Puristus0 = rnorm(n, mean = 0, sd = 1),
  z_Puristus2 = rnorm(n, mean = 0.1, sd = 1),

  # === Raw test values (for K3/K4 scripts that use original values) ===
  # Maximum walking speed (m/s) - English and Finnish names
  MWS0 = round(rnorm(n, mean = 1.2, sd = 0.3), 2),
  MWS2 = round(rnorm(n, mean = 1.25, sd = 0.3), 2),
  kavelynopeus_m_sek0 = round(rnorm(n, mean = 1.2, sd = 0.3), 2),
  kavelynopeus_m_sek2 = round(rnorm(n, mean = 1.25, sd = 0.3), 2),

  # Five times sit-to-stand test (seconds) - English and Finnish names
  FTSST0 = round(rnorm(n, mean = 15, sd = 5), 1),
  FTSST2 = round(rnorm(n, mean = 14.5, sd = 5), 1),
  tuoliltanousu0 = round(rnorm(n, mean = 15, sd = 5), 1),
  tuoliltanousu2 = round(rnorm(n, mean = 14.5, sd = 5), 1),

  # Single leg stand (seconds) - English and Finnish names
  SLS0 = round(rnorm(n, mean = 8, sd = 6), 1),
  SLS2 = round(rnorm(n, mean = 8.5, sd = 6), 1),
  Seisominen0 = round(rnorm(n, mean = 8, sd = 6), 1),
  Seisominen2 = round(rnorm(n, mean = 8.5, sd = 6), 1),

  # Hand grip strength (kg) - English and Finnish names
  HGS0 = round(rnorm(n, mean = 22, sd = 6), 1),
  HGS2 = round(rnorm(n, mean = 22.5, sd = 6), 1),
  Puristus0 = round(rnorm(n, mean = 22, sd = 6), 1),
  Puristus2 = round(rnorm(n, mean = 22.5, sd = 6), 1),

  # === Health covariates ===
  # Osteoporosis index (MOI)
  MOIindeksiindeksi = round(rnorm(n, mean = 11, sd = 3)),

  # Comorbidities (binary)
  diabetes = sample(0:1, n, replace = TRUE, prob = c(0.85, 0.15)),
  alzheimer = sample(0:1, n, replace = TRUE, prob = c(0.95, 0.05)),
  parkinson = sample(0:1, n, replace = TRUE, prob = c(0.97, 0.03)),
  AVH = sample(0:1, n, replace = TRUE, prob = c(0.92, 0.08)),  # Stroke

  # Previous falls
  kaatuminen = sample(0:1, n, replace = TRUE, prob = c(0.4, 0.6)),

  # Psychological/mood score
  mieliala = sample(0:3, n, replace = TRUE),

  # === Subjective health measures ===
  # Pain VAS (0-10 scale)
  PainVAS0 = round(runif(n, min = 0, max = 10), 1),
  PainVAS2 = round(runif(n, min = 0, max = 10), 1),

  # Self-rated health (ordinal: 0=poor, 1=fair, 2=good)
  SRH = sample(0:2, n, replace = TRUE, prob = c(0.2, 0.5, 0.3)),

  # Self-rated mobility (ordinal: 0=poor, 1=fair, 2=good)
  oma_arvio_liikuntakyky = sample(0:2, n, replace = TRUE, prob = c(0.2, 0.5, 0.3)),

  # === Walking difficulty (for K7/K8 scripts) ===
  # 500m walking difficulty (0=no, 1=some, 2=much, 3=cannot) - English and Finnish
  Walk500m = sample(0:3, n, replace = TRUE, prob = c(0.4, 0.3, 0.2, 0.1)),
  Vaikeus500m = sample(0:3, n, replace = TRUE, prob = c(0.4, 0.3, 0.2, 0.1)),

  # Balance problems (0=no, 1=yes)
  Balance_problem = sample(0:1, n, replace = TRUE, prob = c(0.7, 0.3)),

  # === Frailty components (for K15/K16 scripts) ===
  # Weight loss
  weight_loss = sample(0:1, n, replace = TRUE, prob = c(0.8, 0.2)),

  # Exhaustion
  exhaustion = sample(0:1, n, replace = TRUE, prob = c(0.7, 0.3)),

  # Slowness (derived from walking speed, but explicit column)
  slowness = sample(0:1, n, replace = TRUE, prob = c(0.6, 0.4)),

  # Low physical activity
  low_activity = sample(0:1, n, replace = TRUE, prob = c(0.5, 0.5)),

  # Weakness (derived from grip strength, but explicit column)
  weakness = sample(0:1, n, replace = TRUE, prob = c(0.6, 0.4))
)

# Ensure realistic correlations
# Make FOF status correlate with poorer function
mock_data <- mock_data %>%
  mutate(
    # People with FOF tend to have slightly worse baseline function
    ToimintaKykySummary0 = ifelse(kaatumisenpelkoOn == 1,
                                   ToimintaKykySummary0 - 0.3,
                                   ToimintaKykySummary0),
    # And smaller improvements
    ToimintaKykySummary2 = ifelse(kaatumisenpelkoOn == 1,
                                   ToimintaKykySummary0 + rnorm(n, 0.05, 0.8),
                                   ToimintaKykySummary0 + rnorm(n, 0.15, 0.8))
  )

# Clamp values to realistic ranges
mock_data <- mock_data %>%
  mutate(
    age = pmax(65, pmin(100, age)),
    BMI = pmax(15, pmin(45, BMI)),
    MWS0 = pmax(0.3, MWS0),
    MWS2 = pmax(0.3, MWS2),
    FTSST0 = pmax(5, FTSST0),
    FTSST2 = pmax(5, FTSST2),
    SLS0 = pmax(0, SLS0),
    SLS2 = pmax(0, SLS2),
    HGS0 = pmax(5, HGS0),
    HGS2 = pmax(5, HGS2),
    MOIindeksiindeksi = pmax(0, pmin(20, MOIindeksiindeksi))
  )

# Determine output path
args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0) {
  output_path <- args[1]
} else {
  output_path <- "data/testing/mock_KaatumisenPelko.csv"
}

# Create output directory if needed
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)

# Write mock data
write_csv(mock_data, output_path)

cat("✓ Mock data generated successfully\n")
cat("  Output file:", output_path, "\n")
cat("  Rows:", nrow(mock_data), "\n")
cat("  Columns:", ncol(mock_data), "\n")
cat("\nColumn names:\n")
cat(paste("  -", names(mock_data), collapse = "\n"), "\n")

# Verify key columns are present
required_for_k1 <- c("id", "ToimintaKykySummary0", "ToimintaKykySummary2",
                     "kaatumisenpelkoOn", "age", "sex", "BMI")
missing <- setdiff(required_for_k1, names(mock_data))
if (length(missing) > 0) {
  stop("ERROR: Missing required columns for K1: ", paste(missing, collapse = ", "))
}

cat("\n✓ All required columns for K1 script present\n")
