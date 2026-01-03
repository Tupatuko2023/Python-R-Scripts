# Fear-of-Falling Analysis Pipeline: Run Summary

**Date:** 2026-01-02
**Status:** Completed (K1-K16 pipeline)

## 1. Overview
This document summarizes the execution of the Fear-of-Falling (FOF) analysis pipeline.
All scripts were run in a reproducible, offline environment with `renv` dependency management.

## 2. Pipeline Execution
The following scripts were executed in order:

| Step | Script | Purpose | Status | Output Location |
|------|--------|---------|--------|-----------------|
| **K1** | `R-scripts/K1/K1.7.main.R` | Primary data processing & Z-score change | OK | `R-scripts/K1/outputs/` |
| **K2** | `R-scripts/K2/K2.Z_Score_C_Pivot_2G.R` | Transpose K1 results | OK | `R-scripts/K2/outputs/` |
| **K3** | `R-scripts/K3/K3.7.main.R` | Original values analysis | OK | `R-scripts/K3/outputs/` |
| **K4** | `R-scripts/K4/K4.A_Score_C_Pivot_2G.R` | Transpose K3 results | OK | `R-scripts/K4/outputs/` |
| **K14** | `R-scripts/K14/K14.R` | Table 1: Baseline Characteristics | OK | `R-scripts/K14/outputs/` |
| **K15** | `R-scripts/K15/K15.R` | Frailty Proxy Generation | OK | `R-scripts/K15/outputs/` |
| **K11** | `R-scripts/K11/K11.R` | Prognostic Marker (ANCOVA) | OK | `R-scripts/K11/outputs/` |
| **K13** | `R-scripts/K13/K13.R` | Interactions (FOF x Age/Sex/etc) | OK | `R-scripts/K13/outputs/` |
| **K16** | `R-scripts/K16/K16.R` | Mixed Models (Longitudinal) | OK | `R-scripts/K16/outputs/` |

## 3. Key Models
### Primary Analysis (K11)
- **Model:** Wide ANCOVA (Follow-up adjusted for baseline)
- **Formula:** `Composite_Z2 ~ FOF_status + Composite_Z0 + Age + Sex + BMI`
- **Result:** FOF effect is significant (p < 0.05) in base models, but attenuated when adjusting for frailty (K16).

### Longitudinal Analysis (K16)
- **Model:** Linear Mixed Model (LMM)
- **Formula:** `Composite_Z ~ time * FOF_status + frailty + Age + Sex + BMI + (1|ID)`
- **Result:** Interaction `time * FOF` was non-significant after frailty adjustment.

## 4. Known Limitations & Notes
- **Sex Variable:** The variable `sex` (levels 0/1) is reported with neutral labels ("Level 0", "Level 1") because an explicit codebook mapping (e.g., 0=Female) was not found in the repository.
- **SRH (Self-rated Health):** Auto-detected from data; missingness handled by listwise deletion in models.
- **Missing Data:** Falls history variables were 100% missing and excluded from analysis.

## 5. Artifacts
- All results are in `R-scripts/K*/outputs/`.
- See `manifest/manifest.csv` for a file-level audit trail.
