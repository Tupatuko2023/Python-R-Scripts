# Project Configuration — Fear of Falling (FOF) × Time — R Mixed/ANCOVA Pipeline

## CRITICAL RULES (NON-NEGOTIABLE)

1. Do not edit raw data files. All transformations must be in code.
2. Do not guess variable meanings or units.
   If unclear: ask for (a) data_dictionary.csv or (b) `names(df)` + `glimpse(df)` + a 10-row sample.
3. Every code change must be:
   - Minimal and reversible
   - Logged (what/why)
   - Proposed as a diff-style patch when possible
4. Reproducibility is mandatory:
   - Use `renv` (lock package versions)
   - Use `set.seed(20251124)` where randomness exists (bootstrap, MI, resampling)
   - Save `sessionInfo()` (or `renv::diagnostics()`) into `manifest/`
5. Output discipline:
   - All tables/figures go to `outputs/<script>/...`
   - Always write one `manifest/manifest.csv` row per output artifact
     (file, date, script, git hash if available)

## PROJECT GOAL

Refactor and stabilize R scripts K11.R–K16.R and run a reproducible analysis to identify which factors
(FOF / age / FOF_status, etc.) are associated with 12-month change in physical performance.

- Primary outcome: `delta_composite_z` (12 months intervention change)
- Alternative outcome (long format): `Composite_Z` with `time` factor/continuous

## DATA ASSUMPTIONS (MUST VERIFY)

We may have either:

A) Wide (baseline + 12 months)

- composite_z0, composite_z12 (or similar)
- delta_composite_z = composite_z12 - composite_z0

B) Long (repeated measures)

- id
- time (0, 12)
- Composite_Z

FOF variables:

- `FOF` and/or `FOF_status` (0/1)
- `FOF_status_f = factor(FOF_status, levels = c(0, 1), labels = c("Ei FOF", "FOF"))`

Minimal required columns to proceed (pick A or B):

- ID, age, sex, BMI (if used), FOF_status (0/1), baseline composite, follow-up composite
  OR time + Composite_Z.

## REPO STRUCTURE (RECOMMENDED)

- data/
  - raw/ (immutable)
  - processed/ (derived)
- R/
  - functions/ (helpers; e.g., io, checks, modeling)
  - pipeline/ (import -> clean -> model -> report)
- R-scripts/
  - K11/ K12/ ... K16/
    - script.R
    - outputs/
- reports/
  - paper/ (Rmd / Quarto)
- tests/
  - testthat/ (optional but preferred for key checks)
- manifest/
  - manifest.csv
  - sessionInfo.txt
  - renv.lock

## VERIFIED VARIABLE MAP (from raw_data)

- id: `id`
- Age: `age`
- Sex: `sex` (coding TBD; do not label without verifying)
- BMI: `BMI`
- FOF_status (0/1): from `kaatumisenpelkoOn`
- Composite_Z0: `ToimintaKykySummary0`
- Composite_Z2: `ToimintaKykySummary2`
- Delta_Composite_Z: `ToimintaKykySummary2 - ToimintaKykySummary0`

## PRIMARY ANALYSIS STRATEGY (DEFAULT)

### Decision: Wide vs Long

1. If ONLY baseline + 12 months exist (2 timepoints):
   - Primary: ANCOVA on follow-up:
     `composite_z12 ~ FOF_status + composite_z0 + age + sex + BMI (+ other confounders)`
   - Secondary: delta model (only if justified):
     `delta_composite_z ~ FOF_status + composite_z0 + age + sex + BMI`
2. If repeated measures / long format:
   - Primary: mixed model (random intercept for ID):
     `Composite_Z ~ time * FOF_status + age + sex + BMI + (1 | ID)`

### Why this structure

- ANCOVA is efficient for 2-timepoint change while controlling baseline.
- Mixed models generalize to missing follow-ups and > 2 timepoints.

## SENSITIVITY / ROBUSTNESS (RUN IF FEASIBLE)

- Robust regression / quantile regression (if heavy tails/outliers materially affect results)
- `nlme` with correlation structures (only if needed)
- Multiple imputation with `mice` for covariate missingness
  (document assumptions; compare to complete-case)

## REQUIRED PACKAGES (R)

Core:

- tidyverse (dplyr, tidyr, readr), broom/broom.mixed, ggplot2

Modeling:

- lme4 (+ lmerTest if p-values needed), nlme (optional), brms (optional Bayesian sensitivity)

Inference:

- emmeans, marginaleffects (optional), performance, parameters, effectsize

Missing data:

- mice

Reporting:

- knitr, rmarkdown/quarto, modelsummary (optional), gt/kableExtra (optional)

## STANDARD COMMANDS (HOW TO RUN)

Setup once:

- `Rscript -e "renv::init()"`
- `Rscript -e "renv::snapshot()"`

Run a script:

- `Rscript R-scripts/K11/K11.R`

Save environment info:

- `Rscript -e "sessionInfo()" > manifest/sessionInfo.txt`

## DATA QUALITY CHECKS (MUST RUN EARLY)

1. Column presence + types
2. ID uniqueness (wide) OR repeated structure (long)
3. FOF_status only {0, 1} and factor labeling is explicit
4. Delta computation check:
   - `delta_composite_z == composite_z12 - composite_z0` (allow small float tolerance)
5. Missingness report:
   - counts and patterns (overall + by FOF group)

## REPORTING RULES

- Always report effect estimates + 95% CI (p-values optional/secondary).
- Prefer interpretable summaries:
  - adjusted mean change by group (emmeans)
  - group difference in change

For interaction (FOF × time): provide simple slopes / contrasts at timepoints.

## TABLE-TO-TEXT CROSSCHECK (MANDATORY BEFORE FINAL OUTPUT)

Before writing Results text:

- Verify table term names exactly
- Verify numeric values match (estimates, CIs)
- Document any rounding or formatting changes
