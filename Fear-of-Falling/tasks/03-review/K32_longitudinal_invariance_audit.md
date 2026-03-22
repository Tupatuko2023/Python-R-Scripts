# K32 longitudinal invariance audit

## Context

Lisää minimaalinen longitudinal invariance -audit K32-pipelineen erillisenä
audit/validation-stepinä niin, että primary latent score construction pysyy
ennallaan.

## Inputs

- `R-scripts/K32/k32.r`
- `../prompts/16_Z_Score_Composite_Advisor.txt`
- `CLAUDE.md`
- `AGENTS.md`

## Outputs

- `R-scripts/K32/k32.r` sisältää advisorin mukaisen invarianssiauditin
- kolme uutta K32-output-artefaktia manifestimerkintöineen
- decision log sisältää invarianssiverdictin

## Definition of Done (DoD)

- `run_capacity_longitudinal_invariance(wide_export)` on lisätty
- `lc_invariance <- run_capacity_longitudinal_invariance(wide_export)` kutsutaan
  heti primary CFA:n jälkeen
- primary latent score construction ei muutu
- `parse(file="R-scripts/K32/k32.r")` onnistuu

## Log

- 2026-03-21 15:08:23 +0200 Task created from orchestrator prompt for K32 longitudinal invariance audit.
- 2026-03-21 15:08:23 +0200 Moved task to 02-in-progress and patched `R-scripts/K32/k32.r`.
- 2026-03-21 15:08:23 +0200 Added advisor-based longitudinal invariance audit, three output writes, manifest logging, and decision log summary lines.
- 2026-03-21 15:08:23 +0200 Validation: anchor grep OK, `Rscript -e "parse(file='R-scripts/K32/k32.r')"` OK, FOF preflight WARN-only due unrelated K40 dynamic contract.
- 2026-03-21 15:21:38 +0200 End-to-end K32 rerun completed in Debian PRoot with `config/.env` sourced and `DATA_ROOT=/data/data/com.termux/files/home/FOF_LOCAL_DATA`.
- 2026-03-21 15:21:38 +0200 Verified invariance artifacts in `R-scripts/K32/outputs/`: `k32_longitudinal_invariance.csv`, `k32_longitudinal_invariance_coverage.csv`, `k32_longitudinal_invariance_manuscript.txt`.
- 2026-03-21 15:21:38 +0200 Verified three manifest rows in `manifest/manifest.csv` for the invariance table, coverage table, and manuscript text.
- 2026-03-21 15:21:38 +0200 Table-to-text crosscheck passed: verdict `metric_not_supported`; metric row had `delta_cfi=-0.0117306`, `delta_rmsea=0.0193659`, `delta_srmr=0.0449522`, so manuscript cautionary wording matches the table and does not overclaim scalar/intercept support.
- 2026-03-21 15:21:38 +0200 Decision log crosscheck passed: `Longitudinal invariance verdict: metric_not_supported` present and practical summary matched manuscript text.
- 2026-03-21 15:21:38 +0200 Risk note: coverage was adequate for running the audit (`n_rows=535`, `n_complete_any_time=443`) but longitudinal complete cases were lower at 12 months (`n_complete_12m=266`, `n_complete_both_times=248`), so missingness remains a reporting caveat for the invariance check.
- 2026-03-21 15:21:38 +0200 No explicit lavaan warnings were emitted in the successful K32 rerun and the primary baseline CFA diagnostics remained admissible (`warning_count=0`); no hotfix was required.

## Blockers

- Tehtävä puuttui valmiista jonosta; luotu promptin perusteella metadata-only.

## End-to-End Validation Update

K32 pipeline executed on data: YES

Run path:
- Debian PRoot from `Python-R-Scripts/Fear-of-Falling/`
- `set -a && . config/.env && set +a && /usr/bin/Rscript R-scripts/K32/k32.r`

Invariance artifacts:
- `R-scripts/K32/outputs/k32_longitudinal_invariance.csv`
- `R-scripts/K32/outputs/k32_longitudinal_invariance_coverage.csv`
- `R-scripts/K32/outputs/k32_longitudinal_invariance_manuscript.txt`

Manifest verification:
- Present, one row per artifact in `manifest/manifest.csv`

Extracted verdict and table summary:
- verdict: `metric_not_supported`
- configural: converged `TRUE`
- metric: converged `TRUE`, `delta_cfi=-0.0117306`, `delta_rmsea=0.0193659`, `delta_srmr=0.0449522`, decision `not_supported`
- scalar: converged `TRUE`, decision `supported` locally versus metric baseline, but overall advisor verdict remains `metric_not_supported` because metric criteria failed

Coverage summary:
- `n_rows=535`
- `n_complete_any_time=443`
- `n_complete_baseline=425`
- `n_complete_12m=266`
- `n_complete_both_times=248`

Crosscheck result:
- manuscript text is aligned with the table
- decision log verdict line is present
- practical summary matches manuscript text

Warnings and risks:
- no explicit lavaan warnings observed during the successful rerun
- primary CFA diagnostics show `warning_count=0`
- missingness at 12 months and both-times complete-case coverage should be noted as a methodological caveat

Review status:
- patch is review-ready
- no technical hotfix was required in this validation round
- `04-done` remains blocked pending human approval

## Links

- `../prompts/1_7cafofv2.txt`
- `../prompts/16_Z_Score_Composite_Advisor.txt`
