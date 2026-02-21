# CHANGELOG NOTE

## Scope

Updated `docs/ANALYSIS_PLAN.md` to align Aim 1 with FOF + frailty + balance framing for 12-month physical performance change (`Composite_Z` trajectory).

## What Was Updated

- Objective and Primary Comparison:
  - Expanded from FOF-only to FOF + frailty + balance.
  - Added explicit definitions for:
    - independent effects = joint estimation of exposure-by-time terms in one model
    - relative effects = common-scale effect reporting + optional Wald/`linearHypothesis` contrasts
- Data & Variables:
  - Added canonical frailty exposures: `frailty_cat_3` (primary), `frailty_score_3` (sensitivity).
  - Added balance exposure `tasapainovaikeus`.
  - Added objective balance candidate note (`Seisominen0/Seisominen2` vs `SLS0/SLS2`) with TODO for canonical confirmation in `data/data_dictionary.csv`.
- Statistical Models:
  - Primary LMM expanded to include `time * FOF_status + time * frailty_cat_3 + time * tasapainovaikeus`.
  - Cross-check ANCOVA expanded with `FOF_status + frailty_cat_3 + tasapainovaikeus` (plus baseline outcome and covariates).
  - Marked 3-way interactions as exploratory only.
- QC Gates:
  - Added exposure-level validation for frailty/balance.
  - Added frailty/balance missingness reporting extension.

## TODO / Open Items

- Confirm canonical objective balance variable naming at analysis-plan level from `data/data_dictionary.csv`:
  - whether to standardize as raw `Seisominen0/Seisominen2` or derived `SLS0/SLS2`.
- `Tutkimussuunnitelma.qmd` (or case-variant equivalent) was not found in-repo; Aim wording was implemented from task packet objective and existing repository frailty/balance conventions.
