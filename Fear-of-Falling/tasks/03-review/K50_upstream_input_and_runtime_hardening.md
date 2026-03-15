# Task: K50 Upstream Input And Runtime Hardening

## Context

`R-scripts/K50/K50.r` is accepted as the current correct analytical baseline.
Its contract must stay fail-closed:

- explicit `--shape LONG|WIDE`
- explicit `--outcome locomotor_capacity|z3|Composite_Z`
- `Composite_Z` only behind `--allow-composite-z VERIFIED`
- `FI22_nonperformance_KAAOS` sensitivity-only
- no heuristic alias expansion for missing locomotor outcomes

The remaining work is operational hardening:

1. confirm Debian/proot R runtime can parse/smoke-run K50 without the previous
   missing-`cli` failure
2. confirm whether upstream already surfaces a canonical K50-ready input with
   `locomotor_capacity` / `z3` in long `time={0,12}` or wide `*_0` / `*_12m`
   form

## Inputs

- `R-scripts/K50/K50.r`
- `R-scripts/K32/k32.r`
- `R-scripts/K33/k33.r`
- `R-scripts/K36/k36.r`
- `docs/ANALYSIS_PLAN.md`
- `docs/FOF_UPSTREAM_LOCOMOTOR_OUTCOME_SPEC.md`
- `prompts/2_3cafofv2.txt`

## Outputs

- Review-state note documenting runtime evidence and exact upstream input gap
- No analytical widening of `K50.r`

## Definition of Done (DoD)

- [x] `K50.r` still requires explicit `--shape LONG|WIDE`
- [x] `K50.r` still requires explicit `--outcome locomotor_capacity|z3|Composite_Z`
- [x] `Composite_Z` remains verification-only
- [x] `FI22_nonperformance_KAAOS` remains sensitivity-only
- [x] Debian/proot R runtime no longer fails on missing `cli`
- [x] Debian/proot can parse `R-scripts/K50/K50.r`
- [x] K50 smoke stop is now the intended missing-input failure, not runtime
- [x] Upstream inspection captured whether canonical K50-ready input exists
- [x] No raw data or heuristic outcome derivations were introduced

## Evidence

### Runtime

- `proot-distro login debian --termux-home -- ... renv::restore(prompt = FALSE)`
  completed without the prior `cli`-triggered startup failure
- `proot-distro login debian --termux-home -- ... library(cli)` returned
  `cli OK`
- `proot-distro login debian --termux-home -- ... parse(file = "R-scripts/K50/K50.r")`
  returned `K50 parse OK`
- `proot-distro login debian --termux-home -- ... Rscript R-scripts/K50/K50.r --shape LONG --outcome locomotor_capacity`
  now fails only with:
  `K50 could not resolve an input dataset`

### Upstream input inspection

- `K32` currently surfaces baseline-only capacity aliases:
  `capacity_score_latent_primary`, `capacity_score_z3_primary`,
  `capacity_score_z3_sensitivity`
- `K33` currently writes `fof_analysis_k33_long.*` and `fof_analysis_k33_wide.*`
  around `Composite_Z`, not canonical `locomotor_capacity` / `z3`
- `K36` consumes `K33` `Composite_Z` datasets and joins baseline
  `capacity_score_latent_primary`; it does not export canonical K50-ready
  `locomotor_capacity`/`z3` long or wide datasets
- sibling repo `../Quantify-FOF-Utilization-Costs/R/32_cfa/32_cfa_3item.r`
  contains the true CFA/z3 source logic and writes patient-level
  `kaaos_with_capacity_scores_32_cfa_3item.(csv|rds)` with
  `capacity_score_latent_primary` / `capacity_score_z3_primary`
- sibling repo `../Quantify-FOF-Utilization-Costs/R/40_FI/K40_FI_KAAOS.R`
  fixes `FI22_nonperformance_KAAOS` as
  `fi_variant_role = "sensitivity_index"` and excludes performance-test fields
  from FI construction
- functional-test schema and existing repo usage treat suffix `0` as baseline
  and suffix `2` as 12 months for locomotor source variables such as
  `kavelynopeus_m_sek0/2`, `FTSST0/2`, and `SLS_mean0/2` or `Seisominen0/2`

## Review Update

The canonical upstream export step now exists in `K32`, and `K50.r` remains a
pure consumer.

- `K32` now writes canonical K50-ready wide/long exports from the producing
  layer using the accepted `0 = baseline`, `2 = 12 months` source time map.
- Mapping ambiguity is now fail-closed: multiple candidate hits for a required
  target produce a dedicated mapping-audit artifact and stop the run.
- CFA factor-score method is now aligned with documentation: regression-based
  scoring from the baseline-fitted CFA model is used for both baseline and
  12-month rows.
- Chair orientation wording is now aligned with the already reoriented
  chair-capacity indicator: expected loading sign is positive post-orientation.
- The misleading non-distinct sensitivity-CFA branch was removed; `z3` remains
  the actual fallback / sensitivity branch.
- Canonical export QC now includes substantive content gates in addition to
  schema checks.

The remaining review condition is now intentional and explicit: canonical
export must fail closed before writing K50-ready outputs if the primary
baseline-fitted CFA is inadmissible or if canonical locomotor score
completeness falls below the implementation threshold.

## Log

- 2026-03-13: Moved K50-related upstream task into `02-in-progress` under the
  Fear-of-Falling subproject for operational hardening.
- 2026-03-13: Confirmed local upstream evidence: `K32` exposes baseline capacity
  aliases, `K33` exposes `Composite_Z` long/wide datasets, `K36` still models
  `Composite_Z` with joined baseline capacity.
- 2026-03-13: Fixed Debian/proot runtime path leakage by running with a clean
  Debian `PATH`, then verified `renv`, `cli`, and `K50` parse in Debian/proot.
- 2026-03-13: Confirmed K50 smoke failure is the intended missing canonical
  upstream input, not a runtime dependency failure.
- 2026-03-13: Cross-repo inspection confirmed that the canonical CFA and FI22
  source scripts live in sibling repo `Quantify-FOF-Utilization-Costs`, but
  Fear-of-Falling still does not expose their outputs as canonical K50-ready
  long/wide columns.
- 2026-03-14: Implemented canonical K50-ready upstream export in `K32`, then
  applied expert-audit hardening: ambiguity fail-closed, regression-method
  alignment, chair-sign wording cleanup, removal of the fake sensitivity-CFA
  branch, and hard export QC/content gates tied to primary CFA admissibility.

## Status

- Verified K50-ready upstream export now exists in `K32`.
- `K50.r` is no longer blocked by unresolved canonical input.
- Current review baseline is hardened and validated:
  ambiguity fail-closed, regression-based baseline-fit factor scoring,
  positive post-orientation chair-sign expectation,
  admissibility stop, completeness stop, and successful `K50` WIDE/LONG smoke.
- Remaining work, if any, is review-level regression confirmation or wording
  polish, not upstream export architecture.

## Links

- `R-scripts/K50/K50.r`
- `R-scripts/K32/k32.r`
- `R-scripts/K33/k33.r`
- `R-scripts/K36/k36.r`
- `docs/ANALYSIS_PLAN.md`
- `docs/FOF_UPSTREAM_LOCOMOTOR_OUTCOME_SPEC.md`
- `../Quantify-FOF-Utilization-Costs/R/32_cfa/32_cfa_3item.r`
- `../Quantify-FOF-Utilization-Costs/R/40_FI/K40_FI_KAAOS.R`
