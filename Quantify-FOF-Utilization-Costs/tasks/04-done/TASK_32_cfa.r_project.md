# TASK: 32 CFA 3-item locomotor capacity model

**Status**: 04-done
**Assigned**: Codex / 2qfca
**Created**: 2026-03-11

## OBJECTIVE

Implement a new raw-Excel-based 3-item locomotor capacity CFA script for the
Quantify-FOF-Utilization-Costs subproject and validate it in the correct project
context.

Primary specification:

- raw source: `DATA_ROOT/paper_02/KAAOS_data_sotullinen.xlsx`
- core factor: `gait + chair + balance`
- no `grip`
- no `self_report` in the core pipeline or default outputs
- always compute `z3` fallback scores

## INPUTS

- `DATA_ROOT/paper_02/KAAOS_data_sotullinen.xlsx`
- Reference architecture only:
  - `../Fear-of-Falling/R-scripts/K32/k32.r`
  - `../Fear-of-Falling/R-scripts/K32/k32_validation.r`
- Subproject config:
  - `config/.env`
  - `manifest/manifest.csv`

## IMPLEMENTATION

1. Added new script:
   - `R/32_cfa/32_cfa_3item.r`
2. Added local ignore rule:
   - `R/32_cfa/.gitignore`
3. Added manuscript-ready methods/QC appendix:
   - `R/32_cfa/32_cfa_3item_methods_and_qc_appendix.md`
4. Added manuscript-ready measurement model note:
   - `R/32_cfa/32_cfa_3item_measurement_model.md`
5. Implemented deterministic raw Excel sheet/skip audit with fail-closed mapping.
6. Mapped indicators from raw workbook:
   - gait: `TK: 10 metrin kävelynopeus (sek)` -> `10 / seconds`
   - chair: `TK: Tuolilta nousu 5 krt (sek)` -> `-time`
   - balance: mean of right/left single-leg stance
7. Added guardrail for implausible balance values:
   - values `>300` seconds -> `NA`
8. Removed all `grip` logic.
9. Removed all `self_report` remnants from the core path and default outputs.
10. Wrote repo-local aggregate artifacts under:
   - `R/32_cfa/outputs/<run_id>/`
11. Wrote patient-level outputs only to:
   - `DATA_ROOT/paper_02/capacity_scores/`
12. Added manuscript-ready wording for Methods, Results, Discussion, and model
    figure reuse.

## VALIDATION

Smoke-run executed from the correct subproject root:

```bash
cd Quantify-FOF-Utilization-Costs
set -a && . config/.env && set +a
Rscript R/32_cfa/32_cfa_3item.r
```

Validated run summary:

- selected sheet: `Taul1`
- selected skip: `1`
- rows loaded: `630`
- rows with z3 score: `512`
- rows in complete-case CFA: `438`

Final CFA diagnostics:

- converged: `TRUE`
- negative residual variances: `FALSE`
- standardized loading > 1: `FALSE`
- loading signs coherent: `TRUE`
- admissible: `TRUE`
- factor determinacy: `0.969`
- CFI: `1.000`
- TLI: `1.000`
- RMSEA: `0.000`
- SRMR: `0.000`

Audit resolution note:

- post-implementation review confirmed that CFA estimation is explicitly present
  in `R/32_cfa/32_cfa_3item.r` via namespaced calls:
  - `lavaan::cfa(...)`
  - `lavaan::lavPredict(...)`
  - `lavaan::parameterEstimates(...)`
  - `lavaan::lavInspect(...)`
- therefore, the absence of `library(lavaan)` at the top of the script is not a
  methodological issue; CFA is estimated directly through the `lavaan::`
  namespace.
- follow-up QC patch added richer CFA diagnostics to the aggregate artifact,
  including factor determinacy and standard fit measures (`CFI`, `TLI`,
  `RMSEA`, `SRMR`, `chisq`, `df`, `pvalue`) without changing the modeling
  pipeline.

Observed standardized loadings:

- gait: `0.967`
- chair: `0.571`
- balance: `0.581`

## OUTPUTS

Repo-local aggregate/QC artifacts:

- `R/32_cfa/outputs/<run_id>/32_cfa_3item_excel_layout_candidates.csv`
- `R/32_cfa/outputs/<run_id>/32_cfa_3item_mapping.csv`
- `R/32_cfa/outputs/<run_id>/32_cfa_3item_audit_continuous.csv`
- `R/32_cfa/outputs/<run_id>/32_cfa_3item_audit_correlations.csv`
- `R/32_cfa/outputs/<run_id>/32_cfa_3item_red_flags.csv`
- `R/32_cfa/outputs/<run_id>/32_cfa_3item_cfa_diagnostics.csv`
- `R/32_cfa/outputs/<run_id>/32_cfa_3item_cfa_primary_loadings.csv`
- `R/32_cfa/outputs/<run_id>/32_cfa_3item_cfa_sensitivity_loadings.csv`
- `R/32_cfa/outputs/<run_id>/32_cfa_3item_scores_summary.csv`
- `R/32_cfa/outputs/<run_id>/32_cfa_3item_decision_log.txt`
- `R/32_cfa/outputs/<run_id>/32_cfa_3item_patient_level_output_receipt.txt`
- `R/32_cfa/outputs/<run_id>/32_cfa_3item_sessioninfo.txt`

Patient-level local-only outputs:

- `DATA_ROOT/paper_02/capacity_scores/kaaos_with_capacity_scores_32_cfa_3item.csv`
- `DATA_ROOT/paper_02/capacity_scores/kaaos_with_capacity_scores_32_cfa_3item.rds`

## DATA SAFETY

- No raw data copied into the repo.
- No patient-level output written into the repo.
- `R/32_cfa/outputs/` is gitignored via `R/32_cfa/.gitignore`.

## ACCEPTANCE CRITERIA

- [x] New script exists at `R/32_cfa/32_cfa_3item.r`
- [x] Raw Excel source comes from `DATA_ROOT/paper_02/KAAOS_data_sotullinen.xlsx`
- [x] Core model is `gait + chair + balance`
- [x] `grip` removed
- [x] `self_report` removed from core path
- [x] `z3` fallback implemented
- [x] Smoke-run executed from Quantify-FOF-Utilization-Costs context
- [x] Patient-level output written only to `DATA_ROOT`
- [x] Repo outputs protected from tracking

## FINAL STATUS

Accepted. Scope completed as a new 3-item locomotor capacity CFA pipeline in the
Quantify-FOF-Utilization-Costs subproject.
