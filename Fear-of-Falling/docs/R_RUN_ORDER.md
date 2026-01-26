# R Scripts Execution Order — Fear of Falling Analysis

**Last updated:** 2026-01-13
**Purpose:** Execution order for R analysis scripts with verified dependencies
**Context:** FOF (Fear of Falling) × time analysis pipeline

---

## Quick Reference: Verified Execution Chains

### Chain A: K1-K4 Foundational Data Processing

```bash
# From repo root: Fear-of-Falling/
cd Fear-of-Falling

# Restore R environment
R -q -e 'if (!requireNamespace("renv", quietly=TRUE)) install.packages("renv"); renv::restore(prompt=FALSE)'

# K1 → K2 pipeline (Z-score analysis)
Rscript R-scripts/K1/K1.7.main.R    # Creates K1_Z_Score_Change_2G.csv
Rscript R-scripts/K2/K2.Z_Score_C_Pivot_2G.R  # Depends on K1; transposes by FOF status

# K3 → K4 pipeline (Original values analysis)
Rscript R-scripts/K3/K3.7.main.R    # Creates K3_Values_2G.csv
Rscript R-scripts/K4/K4.A_Score_C_Pivot_2G.R  # Depends on K3; transposes by FOF status
```

**What this does:**

- **K1:** Z-score change analysis (baseline vs 12m); sources K1.1-K1.6; bootstrap seed 20251124
- **K2:** Transposes K1 z-score output by FOF status
- **K3:** Original test values analysis; shares K1.1 and K1.5 modules with K1
- **K4:** Transposes K3 original values by FOF status

---

### Chain B: QC → Frailty Pipeline (Stop-the-Line)

```bash
# From repo root: Fear-of-Falling/
cd Fear-of-Falling

# 1. Run QC (STOP-THE-LINE - must PASS before modeling)
Rscript R-scripts/K18/K18_QC.V1_qc-run.R \
  --data data/external/KaatumisenPelko.csv \
  --shape AUTO \
  --dict data/data_dictionary.csv

# 2. Verify QC PASS
# Check: R-scripts/K18/outputs/K18_QC/qc/qc_status_summary.csv
# Required: time_levels=TRUE, fof_levels=TRUE, overall_pass=TRUE

# 3. Run frailty proxy analysis
Rscript R-scripts/K15/K15.R    # Creates K15_frailty_analysis_data.RData

# 4. Run frailty-adjusted mixed model
Rscript R-scripts/K16/K16.R    # Depends on K15 RData
```

**What this does:**

- **K18_QC:** Validates data structure, FOF_status coding, time levels, missingness
  - **CRITICAL:** If QC fails, DO NOT proceed to K15/K16
  - CLI args: `--data` (required), `--shape` (default AUTO), `--dict` (default data/data_dictionary.csv)
  - Outputs QC artifacts to: `R-scripts/K18/outputs/K18_QC/qc/`
- **K15:** Creates frailty proxy variables; saves RData for K16
- **K16:** Frailty-adjusted ANCOVA/mixed models; loads K15 RData

---

## Dependency Summary

| Script     | Depends On | Reads                               | Writes                                                     |
| ---------- | ---------- | ----------------------------------- | ---------------------------------------------------------- |
| **K1**     | -          | `data/external/KaatumisenPelko.csv` | `R-scripts/K1/outputs/K1_Z_Score_Change_2G.csv`            |
| **K2**     | K1         | K1 outputs                          | `R-scripts/K2/outputs/K2_Z_Score_Change_2G_Transposed.csv` |
| **K3**     | -          | `data/external/KaatumisenPelko.csv` | `R-scripts/K3/outputs/K3_Values_2G.csv`                    |
| **K4**     | K3         | K3 outputs                          | `R-scripts/K4/outputs/K4_Values_2G_Transposed.csv`         |
| **K18_QC** | -          | CLI `--data` arg                    | `R-scripts/K18/outputs/K18_QC/qc/` (artifacts)             |
| **K15**    | -          | `data/external/KaatumisenPelko.csv` | `R-scripts/K15/outputs/K15_frailty_analysis_data.RData`    |
| **K16**    | K15        | K15 RData                           | `R-scripts/K16/outputs/` (CSV outputs)                     |

---

## Refactored Scripts (\_MAIN suffix) — Grep-Verified I/O Mappings

The repository contains refactored versions of K-scripts with `_MAIN` suffix (K01_MAIN through K19_MAIN). These follow CLAUDE.md standards with comprehensive I/O mappings extracted via grep analysis.

### Chain C: \_MAIN Z-score and Original Values (K01→K02 / K03→K04)

```bash
# From repo root: Fear-of-Falling/
cd Fear-of-Falling

# K01_MAIN → K02_MAIN pipeline (Z-score analysis, refactored)
Rscript R-scripts/K01_MAIN/K01_MAIN.V1_zscore-change.R    # Creates K1_Z_Score_Change_2G.csv
Rscript R-scripts/K02_MAIN/K02_MAIN.V1_zscore-pivot-2g.R  # Depends on K01_MAIN; transposes

# K03_MAIN → K04_MAIN pipeline (Original values analysis, refactored)
Rscript R-scripts/K03_MAIN/K03_MAIN.V1_original-values.R  # Creates K3_Values_2G.csv
Rscript R-scripts/K04_MAIN/K04_MAIN.V1_values-pivot-2g.R  # Depends on K03_MAIN; transposes
```

**What this does:**

- **K01_MAIN:** Refactored K1 with CLAUDE.md standards; same I/O as legacy K1
- **K02_MAIN:** Refactored K2; transposes K01_MAIN outputs by FOF status
- **K03_MAIN:** Refactored K3; original values instead of z-scores
- **K04_MAIN:** Refactored K4; transposes K03_MAIN outputs by FOF status

### Chain D: \_MAIN Frailty Pipeline (K15→K16/K18→K19)

```bash
# From repo root: Fear-of-Falling/
cd Fear-of-Falling

# 1. Create frailty proxy variables
Rscript R-scripts/K15_MAIN/K15_MAIN.V1_frailty-proxy.R

# 2a. Frailty-adjusted ANCOVA/mixed models
Rscript R-scripts/K16_MAIN/K16_MAIN.V1_frailty-adjusted-ancova-mixed.R  # Depends on K15_MAIN

# 2b. Frailty change contrasts (alternative path from K15)
Rscript R-scripts/K18_MAIN/K18_MAIN.V1_frailty-change-contrasts.R  # Depends on K15_MAIN

# 3. Frailty vs FOF evidence pack
Rscript R-scripts/K19_MAIN/K19_MAIN.V1_frailty-vs-fof-evidence-pack.R  # Depends on K18_MAIN
```

**What this does:**

- **K15_MAIN:** Creates frailty proxy vars; saves `K15_frailty_analysis_data.RData`
- **K16_MAIN:** Frailty-adjusted ANCOVA/mixed models; loads K15 RData
- **K18_MAIN:** Frailty change contrasts; saves `K18_all_models.RData`
- **K19_MAIN:** Frailty vs FOF comparison evidence; loads K18 RData

### Chain E: \_MAIN Independent Analyses (K05-K14, K17)

All scripts in this chain read `data/external/KaatumisenPelko.csv` and have no dependencies:

- **K05_MAIN:** Wide ANCOVA on composite_z12
- **K06_MAIN:** Moderators (pain, SRH, SRM) × FOF interactions on delta
- **K07_MAIN:** Multidomain moderators (neuro, SRH, SRM, walk) × FOF
- **K08_MAIN:** Balance/walk moderators × FOF
- **K09_MAIN:** Women-only FOF × age class analysis
- **K10_MAIN:** FOF delta visualizations (adjusted + raw means)
- **K11_MAIN:** FOF independent effects (base + extended models)
- **K12_MAIN:** PBT outcomes × FOF effects (multiple outcomes)
- **K13_MAIN:** FOF interactions (symptoms, SRH, SRM, walk, etc.)
- **K14_MAIN:** Baseline characteristics table by FOF status
- **K17_MAIN:** Baseline table with frailty variables

**Status:** All paths and I/O mappings verified via grep analysis (2026-01-13)

**See:** `docs/run_order.csv` for machine-readable dependency table

---

## File Tags Reference (CLAUDE.md Script IDs)

From verified script headers:

| script_id | file_tag                        | Notes                        |
| --------- | ------------------------------- | ---------------------------- |
| K1        | `K1_MAIN.V1_zscore-change.R`    | Legacy K1 pipeline           |
| K2        | `K2.V1_zscore-pivot-2g.R`       | Legacy K2                    |
| K3        | `K3_MAIN.V1_original-values.R`  | Legacy K3                    |
| K4        | `K4.V1_values-pivot-2g.R`       | Legacy K4                    |
| K18_QC    | `K18_QC.V1_qc-run.R`            | QC runner                    |
| K15       | `K15.R`                         | Legacy K15                   |
| K16       | `K16.R`                         | Legacy K16                   |
| K01_MAIN  | `K01_MAIN.V1_zscore-change.R`   | Refactored K1                |
| K02_MAIN  | `K02_MAIN.V1_zscore-pivot-2g.R` | Refactored K2                |
| ...       | ...                             | (K03_MAIN-K19_MAIN verified) |

---

## Output Conventions (CLAUDE.md Discipline)

**Legacy scripts (K1-K16):** Follow output discipline:

- K1-K4: `R-scripts/K{N}/outputs/`
- K15-K16: `R-scripts/K{N}/outputs/`
- K18_QC: `R-scripts/K18/outputs/K18_QC/qc/`

**Refactored scripts (\_MAIN):** Should follow:

- `R-scripts/{K}_MAIN/outputs/{script_label}/`
- Manifest logging: `manifest/manifest.csv` (1 row per artifact)

---

## Troubleshooting

### "K1 output file not found" (when running K2)

```bash
# Run K1 first
Rscript R-scripts/K1/K1.7.main.R

# Verify output exists
ls -la R-scripts/K1/outputs/K1_Z_Score_Change_2G.csv

# Then run K2
Rscript R-scripts/K2/K2.Z_Score_C_Pivot_2G.R
```

### "K15 RData file not found" (when running K16)

```bash
# Run K15 first
Rscript R-scripts/K15/K15.R

# Verify RData exists
ls -la R-scripts/K15/outputs/K15_frailty_analysis_data.RData

# Then run K16
Rscript R-scripts/K16/K16.R
```

### QC fails (time_levels or fof_levels = FALSE)

- Check `R-scripts/K18/outputs/K18_QC/qc/qc_time_levels.csv` for observed vs expected
- Check `R-scripts/K18/outputs/K18_QC/qc/qc_fof_levels.csv` for FOF_status values
- Update `data/VARIABLE_STANDARDIZATION.csv` if needed
- Re-run QC after fixing data coding

---

## Next Steps

1. ✅ **\_MAIN I/O mappings complete:** All K01_MAIN-K19_MAIN scripts verified via grep (2026-01-13)
2. ✅ **run_order.csv updated:** All \_MAIN scripts have verified depends_on + reads_primary + writes_primary
3. **Test execution (optional):** Run \_MAIN pipelines end-to-end to validate runtime behavior
4. **Update PROJECT_FILE_MAP.md:** Reconcile discrepancies found during verification (Task C)

---

## References

- **CLAUDE.md**: Project standards (SCRIPT_ID, output discipline, manifest rules)
- **README.md**: Quick start guide, K1-K4 pipeline details
- **QC_CHECKLIST.md**: QC checks specification and pass criteria
- **run_order.csv**: Machine-readable dependency table (in this directory)
- **make_run_order.py**: Python script that generated run_order.csv

---

**Document Status:**

- ✅ K1-K4 pipeline fully verified
- ✅ K18_QC stop-the-line documented
- ✅ K15→K16 frailty chain verified
- ✅ All \_MAIN script paths verified (K01_MAIN-K19_MAIN)
- ✅ \_MAIN I/O mappings grep-verified (depends_on, reads, writes)
- ✅ \_MAIN execution chains documented (Chain C, D, E)
- ⚠️ Legacy K5-K14, K17-K19 not included (postponed)

**Generated:** 2026-01-13
**Method:** Python script + ripgrep I/O analysis
**CSV:** `docs/run_order.csv` (26 scripts with full I/O mappings)
**Grep evidence:** All \_MAIN scripts verified with read_csv/load/save patterns
