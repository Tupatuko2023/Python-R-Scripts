# K34 Primary Models LMM ANCOVA

## Context
Run primary and cross-check models from `docs/ANALYSIS_PLAN.md` after K33 has produced canonical, QC-passing datasets.

K20 numbering is reserved; this task uses K34.

## Inputs
- K33 PASS artifacts (canonical long/wide datasets in `${DATA_ROOT}`)
- `docs/ANALYSIS_PLAN.md`

## Outputs
- Model result tables and diagnostics (aggregate, in-repo)
- In-repo receipts + manifest rows
- No patient-level outputs written in repo

## Hard Precondition
- K34 must not move to `01-ready` until K33 is complete and QC PASS is documented.

## Primary Model (Long, LMM)
Formula must be copied exactly:
```r
Composite_Z ~ time * FOF_status + time * frailty_cat_3 + time * tasapainovaikeus +
  age + sex + BMI + (1 | id)
```

## Cross-Check Model (Wide, ANCOVA)
Formula must be copied exactly:
```r
Composite_Z_12m ~ Composite_Z_baseline + FOF_status + frailty_cat_3 +
  tasapainovaikeus + age + sex + BMI
```

## Sensitivity (Frailty Proxy Construction)
Same common-sample comparison as plan:
```r
delta_composite_z ~ frailty_cat_3 + FOF_status + age + sex + BMI

delta_composite_z ~ frailty_cat_3_balance + FOF_status + age + sex + BMI
```
Compare AIC and adjusted R² on identical N.

## Critical Balance Distinction (non-negotiable)
- Exposure in models remains `tasapainovaikeus`.
- Objective balance (`Seisominen*`) is not a replacement exposure in these primary formulas.
- Keep distinction explicit in model notes/output.

## Governance Rules
- Patient-level datasets remain external in `${DATA_ROOT}`.
- Repo outputs are aggregate model results + receipts only.
- Manifest logging for in-repo artifacts only.

## Proposed Implementation (when moved to 01-ready)
1. Load K33 canonical long/wide datasets from `${DATA_ROOT}`.
2. Fit LMM exactly as specified.
3. Fit ANCOVA exactly as specified.
4. Run sensitivity model pair and compare fit metrics.
5. Export aggregate result tables/diagnostics; write receipt; append manifest rows.

## Definition of Done (DoD)
- LMM and ANCOVA executed with exact formulas.
- Sensitivity comparison executed on common sample.
- Output discipline and manifest discipline preserved.
- No patient-level repo leakage.

## Log
- 2026-03-01 15:52: Backlog task created from template and populated from `docs/ANALYSIS_PLAN.md`.
- 2026-03-01 16:34: Implemented `R-scripts/K34/k34.r` for primary LMM + ANCOVA + frailty-proxy sensitivity on K33 canonical datasets.
- 2026-03-01 16:35: Ran `proot-distro ... /usr/bin/Rscript R-scripts/K34/k34.r` -> PASS.
- 2026-03-01 16:35: Produced aggregate outputs under `R-scripts/K34/outputs/`:
  - `k34_lmm_primary_coefficients.csv`
  - `k34_lmm_primary_summary.txt`
  - `k34_ancova_coefficients.csv`
  - `k34_ancova_summary.txt`
  - `k34_sensitivity_frailty_proxy_comparison.csv`
  - `k34_decision_log.txt`
  - `k34_sessioninfo.txt`
- 2026-03-01 16:35: Manifest rows appended for all K34 artifacts (`k34_*` labels).
- 2026-03-01 16:35: Ran `bash scripts/termux/run_qc_summarizer_proot.sh` -> PASS.
- 2026-03-01 16:35: Ran `bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling` -> PASS.
- 2026-03-01 16:35: Leak-check PASS (no patient-level analysis CSV/RDS in repo outputs).

## Run Notes
- K34 sensitivity mapping used `frailty_cat_3_B` from externalized K15 data as `frailty_cat_3_balance`.
- Primary balance exposure remained `tasapainovaikeus` in all primary formulas.

## Blockers
- Blocked until K33 PASS.

## Links
- `docs/ANALYSIS_PLAN.md`
- `tasks/00-backlog/K33_build_analysis_dataset.md`
