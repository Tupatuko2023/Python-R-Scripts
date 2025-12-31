# Project Configuration — Fear of Falling (FOF) × Time — R Mixed/ANCOVA Pipeline

## CRITICAL RULES (NON-NEGOTIABLE)

1. Do not edit raw data files. All transformations must be in code.
2. Do not guess variable meanings or units. If unclear: ask for (a)
   data_dictionary.csv or (b) `names(df)` + `glimpse(df)` + a 10-row sample.
3. Every code change must be:
   - Minimal and reversible
   - Logged (what/why)
   - Proposed as a diff-style patch when possible
4. Reproducibility is mandatory:
   - Use `renv` (lock package versions)
   - Use `set.seed(20251124)` where randomness exists (bootstrap, MI,
     resampling)
   - Save `sessionInfo()` (or `renv::diagnostics()`) into `manifest/`
5. Output discipline:
   - All tables/figures go to: `R-scripts/<script_label>/outputs/` (where
     `<script_label>` = K11, K12, etc.; created by `init_paths(script_label)`)
   - Always write one `manifest/manifest.csv` row per output artifact (file,
     date, script, git hash if available)

6. Every Kxx script MUST start with the standardized intro/header block in:
   **"## STANDARD SCRIPT INTRO (MANDATORY)"** (no exceptions).

## STANDARD SCRIPT INTRO (MANDATORY)

**Purpose** Every new script (Kxx) MUST start with a standardized intro/header
block. This operationalizes:

- Reproducibility rules (renv + seed + sessionInfo)
- Output discipline + manifest logging (R-scripts/<script>/outputs/ + 1 manifest
  row per output artifact)
- "Do not invent variables" by forcing an explicit Required Vars list

### Script-ID + file tag conventions (MANDATORY)

- **SCRIPT_ID format:** `K{number}[.{sub}]_{suffix}` Examples: `K5_MA`,
  `K5.1_MA`, `K11_MAIN`, `K16_FRAILTY`
- **File tag (recommended filename):** `{SCRIPT_ID}.V{version}_{name}.R`
  - MUST start with `{SCRIPT_ID}.V` Example: `K5.1_MA.V1_baseline-ancova.R`
- **Canonical script_label:** MUST equal `SCRIPT_ID`. If run via `Rscript`,
  derive as: prefix before `.V`.

### Output + manifest conventions (MANDATORY)

- All artifacts MUST be written under: `R-scripts/<script_label>/outputs/`
  (e.g., K11 outputs go to `R-scripts/K11/outputs/fit_primary_ancova.csv`)
- Every artifact MUST append exactly one row to `manifest/manifest.csv`
  (include: file, date, script, git hash if available).
- Filenames SHOULD include the file tag prefix (at minimum `SCRIPT_ID`).

### set.seed convention (MANDATORY WHEN RANDOMNESS)

- Use `set.seed(20251124)` ONLY when randomness exists
  (MI/bootstrap/resampling).
- The seed value MUST be documented in the script intro.

### Required vars rule (DO NOT INVENT VARIABLES)

- The intro’s **Required Vars** list MUST contain only columns actually used in
  code.
- The script MUST include a column-check vector (e.g. `req_cols <- c(...)`) that
  matches the intro Required Vars list **1:1**.
- If unclear variable meaning/units -> stop and request codebook or
  `names/glimpse/sample`.

### Copy-paste R header template (MANDATORY)

```r
#!/usr/bin/env Rscript
# ==============================================================================
# {{SCRIPT_ID}} - {{TITLE}}
# File tag: {{FILE_TAG}}          # e.g. {{SCRIPT_ID}}.V1_short-name.R
# Purpose: {{ONE_LINE_PURPOSE}}
#
# Outcome: {{OUTCOME}}
# Predictors: {{PREDICTORS}}
# Moderator/interaction: {{MODERATOR}}
# Grouping variable: {{GROUP}}
# Covariates: {{COVARIATES}}
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# {{REQUIRED_VARS}}
#
# Mapping example (optional; raw -> analysis; keep minimal + explicit):
# {{MAPPING_EXAMPLE}}
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: {{SEED}} (set only when randomness is used: MI/bootstrap/resampling)
#
# Outputs + manifest:
# - script_label: {{SCRIPT_ID}} (canonical)
# - outputs dir: R-scripts/{{SCRIPT_ID}}/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load raw data (immutable; no edits)
# 03) Standardize vars + QC (sanity checks early)
# 04) Derive/rename vars (document mapping)
# 05) Prepare analysis dataset (complete-case and/or MI flag)
# 06) Fit primary model (ANCOVA or mixed per project strategy)
# 07) Sensitivity models (if feasible; document)
# 08) Reporting tables (estimates + 95% CI; emmeans as needed)
# 09) Save artifacts -> R-scripts/{{SCRIPT_ID}}/outputs/
# 10) Append manifest row per artifact
# 11) Save sessionInfo / renv diagnostics to manifest/
# 12) EOF marker
# ==============================================================================
#
suppressPackageStartupMessages({
  {{REQUIRED_PACKAGES}}
})

# --- Standard init (MANDATORY) -----------------------------------------------
# Derive script_label from --file, supporting file tags like: K5.1_MA.V1_name.R
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "{{SCRIPT_ID}}"  # interactive fallback
}

script_label <- sub("\.V.*$", "", script_base)  # canonical SCRIPT_ID
if (is.na(script_label) || script_label == "") script_label <- "{{SCRIPT_ID}}"

# init_paths() must set outputs_dir + manifest_path (+ options fof.*)
paths <- init_paths(script_label)
outputs_dir   <- paths$outputs_dir
manifest_path <- paths$manifest_path

# seed (ONLY when needed):
# set.seed({{SEED}})
```

### Template requirements (non-negotiable)

- Must include: shebang + metadata block + workflow lines + 5-12 step list +
  required vars list + (optional) mapping snippet.
- Must define `script_label` and output directory via `init_paths(script_label)`
  (or equivalent project-standard).
- Must state manifest append policy (one row per artifact).
- The intro block MUST be the first content in the script (before data
  reads/model fits).

### “Valid script” checklist (MANDATORY)

A new Kxx script is valid only if:

1. It starts with the full STANDARD SCRIPT INTRO block (placeholders filled).
2. `script_label` equals `SCRIPT_ID` (or is derived as prefix before `.V` in
   file tag).
3. All output paths are under `R-scripts/<script_label>/outputs/`
4. `req_cols` exists and matches Required Vars in the intro **1:1**.
5. Every saved table/figure/text/model artifact appends exactly one manifest
   row.
6. If MI/bootstrap/resampling used -> `set.seed(20251124)` is set and
   documented.
7. Before final Results text: follow **TABLE-TO-TEXT CROSSCHECK** rules.

### Integration pointers (how this connects)

- Reproducibility rules: see **CRITICAL RULES #4**.
- Output + manifest rules: see **CRITICAL RULES #5** and **Output discipline**
  sections.
- QC expectations: see **DATA QUALITY CHECKS (MUST RUN EARLY)**.
- Reporting expectations: see **REPORTING RULES**.
- Text integrity: see **TABLE-TO-TEXT CROSSCHECK**.

> Note: Do not paste unified diffs into this document. Diffs belong to PRs /
> change logs / agent output.

## PROJECT GOAL

Refactor and stabilize all Kxx.R scripts (i.e., any K-numbered R
scripts/folders). Run a reproducible analysis to identify which factors (FOF /
age / FOF_status, etc.) are associated with 12-month change in physical
performance.

Current analysis focus (example): K11–K16. (Examples only; rules/conventions in
this document apply to all Kxx scripts.)

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
- `FOF_status_f = factor(FOF_status, levels = c(0, 1), labels = c("Ei FOF",
"FOF"))`

Minimal required columns to proceed (pick A or B):

- ID, age, sex, BMI (if used), FOF_status (0/1), baseline composite, follow-up
  composite OR time + Composite_Z.

## REPO STRUCTURE (RECOMMENDED)

- data/
  - raw/ (immutable)
  - processed/ (derived)
- R/
  - functions/ (helpers; e.g., io, checks, modeling)
  - pipeline/ (import -> clean -> model -> report)
- R-scripts/
  - Kxx/ (e.g., K01/ K02/ ... /K99/)
    - Kxx.R (or file-tagged scripts like K5.1_MA.V1_name.R)
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
- Composite_Z12: `ToimintaKykySummary2` (12 months)
- Delta_Composite_Z: `ToimintaKykySummary2 - ToimintaKykySummary0` (12-month change)

Note: Legacy code may reference `Composite_Z2` or `Composite_Z3`; these should be
interpreted as 12-month follow-up (Z12) per current naming convention.

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
     (Implementation note: use the actual ID column name from the dataset,
     e.g. `(1 | id)` per VERIFIED VARIABLE MAP.)
   - Two-timepoint long change model: Can use `time_f` (0 vs 12) without
     baseline covariate, as baseline is included as an outcome row. This
     approach estimates change via time coefficient while accounting for
     within-subject correlation through random effects.

### Why this structure

- ANCOVA is efficient for 2-timepoint change while controlling baseline.
- Mixed models generalize to missing follow-ups and > 2 timepoints.

## SENSITIVITY / ROBUSTNESS (RUN IF FEASIBLE)

- Robust regression / quantile regression (if heavy tails/outliers materially
  affect results)
- `nlme` with correlation structures (only if needed)
- Multiple imputation with `mice` for covariate missingness (document
  assumptions; compare to complete-case)

## REQUIRED PACKAGES (R)

Core:

- tidyverse (dplyr, tidyr, readr), broom/broom.mixed, ggplot2

Modeling:

- lme4 (+ lmerTest if p-values needed), nlme (optional), brms (optional Bayesian
  sensitivity)

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

- `Rscript R-scripts/Kxx/Kxx.R` (generic pattern)
- `Rscript R-scripts/<K_FOLDER>/<SCRIPT_FILE>.R` (placeholder form)
- Example (file-tagged): `Rscript
R-scripts/<K_FOLDER>/<SCRIPT_ID>.V1_short-name.R`

Save environment info:

- `Rscript -e "sessionInfo()" > manifest/sessionInfo.txt`

## DATA QUALITY CHECKS (MUST RUN EARLY)

1. Column presence + types
2. ID uniqueness (wide) OR repeated structure (long)
3. FOF_status only {0, 1} and factor labeling is explicit
4. Delta computation check:
   - `delta_composite_z == composite_z12 - composite_z0` (allow small float
     tolerance)
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
- If discrepancies found -> fix table generation or text, never guess.
- Consider automated checks (e.g., `testthat`) for critical values.
- Maintain a changelog of any text-table adjustments for transparency.
- Final sign-off: author + reviewer confirm crosscheck complete.
- This step is non-negotiable for scientific integrity.
- Failure to comply invalidates the analysis.
- Adhere strictly to maintain trustworthiness of reported findings.
- Document compliance in project records.
- This rule applies to all Kxx scripts generating results for publication.
- End of document marker.
