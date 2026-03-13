# Task: Lock Upstream Locomotor Outcome Architecture

## Context

Fear-of-Falling has a stable K50 modeling contract, but upstream outcome
construction rules remain distributed across the CFA appendix, FI22 appendix,
and functional-test schema notes. This task locks the current outcome
architecture without introducing a new composite outcome.

## Inputs

- `Fear-of-Falling/docs/ANALYSIS_PLAN.md`
- `Quantify-FOF-Utilization-Costs/R/32_cfa/32_cfa_3item_methods_and_qc_appendix.md`
- `Fear-of-Falling/docs/FUNCTIONAL_TESTS_DERIVED_SCHEMA.md`
- `Quantify-FOF-Utilization-Costs/R/40_FI/K40_FI_KAAOS_methods_and_qc_appendix.md`
- `prompts/3_1cafofv2.txt`
- `prompts/1_Z_Score_Composite_Advisor.txt`

## Outputs

- Updated `Fear-of-Falling/docs/ANALYSIS_PLAN.md`
- New `Fear-of-Falling/docs/FOF_UPSTREAM_LOCOMOTOR_OUTCOME_SPEC.md`

## Definition of Done (DoD)

- [ ] `ANALYSIS_PLAN.md` confirms `locomotor_capacity` as primary,
      `z3` as fallback/sensitivity, and `Composite_Z` as legacy bridge only.
- [ ] `FI22_nonperformance_KAAOS` remains documented only as a separate
      `sensitivity_index`.
- [ ] `FI22_nonperformance_KAAOS` is the only active frailty/vulnerability
      index in the current plan; `frailty_cat_3` is removed from active
      analysis-plan terms.
- [ ] `grip_*` remains outside the core locomotor outcome branch.
- [ ] `tasapainovaikeus` remains a separate predictor/covariate branch.
- [ ] New upstream spec distinguishes `Verified`, `Inference`, and
      `Needs verification`.
- [ ] No raw data, outputs, or manifest files are changed.

## Log

- 2026-03-12 18:00:00 Created from `tasks/_template.md` for K50 upstream
  outcome-architecture governance lock.
- 2026-03-13 00:00:00 Review follow-up clarified canonical long-format
  `time = 0/12`, status-label definitions, and baseline-anchored `z3`
  standardization wording.

## Blockers

- None currently. Concrete implementation entrypoints can be frozen later in a
  separate script-layer task if needed.

## Links

- `Fear-of-Falling/docs/ANALYSIS_PLAN.md`
- `Fear-of-Falling/docs/FOF_UPSTREAM_LOCOMOTOR_OUTCOME_SPEC.md`
