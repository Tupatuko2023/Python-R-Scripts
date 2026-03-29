## Task: K50/K20 person dedup helper consolidation

### Goal
Reduce drift risk after PR review by consolidating duplicated DATA_ROOT, bridge-key, and person-dedup selection logic into `R/functions/person_dedup_lookup.R`.

### Scope
- Move shared env/lookup/bridge normalization usage to `person_dedup_lookup.R`
- Make K50 cohort-flow consume shared helper output instead of local dedup logic
- Make K20 diagnostics consume shared helper env/lookup logic and shared ambiguity selection
- Keep participant policy and dedup conflict handling unchanged

### Definition of Done
- K50 cohort-flow no longer maintains its own parallel person-dedup chooser
- K20 diagnostics no longer maintains duplicate DATA_ROOT / bridge-key / lookup logic
- Current local-input behavior remains unchanged versus `HEAD`

### Progress Notes
- Shared chooser logic moved into `R/functions/person_dedup_lookup.R`
- `K50.1_COHORT_FLOW.V1_derive-cohort-flow.R` now consumes shared helper output instead of maintaining its own parallel chooser
- `K20_duplicate_person_diagnostics.R` now uses shared DATA_ROOT, lookup-path, bridge-key, and ambiguity logic
- `fof-preflight` now passes at WARN level only
- PR #124 follow-up addressed review feedback by neutralizing shared-helper error messages, removing extra K20 normalization type flips, and hardening `count_non_missing` call sites without changing behavior

### Validation Notes
- `Rscript -e 'parse(...)'` passed for helper, K20, and K50 cohort-flow
- `K20_duplicate_person_diagnostics.R` ran successfully with `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE`
- `K50.1_COHORT_FLOW.V1_derive-cohort-flow.R --shape LONG --outcome locomotor_capacity` ran successfully with `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE`
- Direct `HEAD` versus refactored-helper comparison on the current local `DATA_ROOT` input matched exactly: `raw_id_n=535`, `n_raw_person_lookup=525`, `ex_duplicate_person_lookup=0`, `ex_person_conflict_ambiguous=0`
- The historical `527 / 14 / 8 / 225` control was not reproducible on this machine's current local input in either `HEAD` or the refactored branch, so that mismatch is treated as an input/artifact-history difference rather than a regression from this refactor
