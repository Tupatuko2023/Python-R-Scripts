# FOF Upstream Locomotor Outcome Spec

**Status:** Implementation appendix for the current K50 analysis-plan contract  
**Role:** Describes upstream harmonization and outcome-construction rules
without replacing `ANALYSIS_PLAN.md` as the modeling/governance source of
truth.

## Status Label Definitions

- **Verified:** Directly supported by the current source documents or locked
  appendices.
- **Inference:** Recommended interpretation consistent with current source
  documents, but not explicitly locked as a verbatim rule.
- **Needs verification:** Not yet locked and must be confirmed from the
  implementation layer or source documentation before code freeze.

## Inputs

- **Verified:** The current primary locomotor outcome branch is based on gait,
  chair, and balance indicators documented in the CFA 3-item appendix.
- **Verified:** Functional-test harmonization uses canonical derived fields
  including `kavelynopeus_m_sek*`, `FTSST*`, and `SLS_mean*`.
- **Verified:** `FI22_nonperformance_KAAOS` is governed separately by the FI22
  appendix as a `sensitivity_index`.
- **Needs verification:** Concrete implementation entrypoint scripts and final
  external production paths remain implementation-layer concerns and are not
  frozen in this document.

## Functional Test Harmonization

- **Verified:** Gait is represented as gait speed using
  `kavelynopeus_m_sek0` and `kavelynopeus_m_sek2` when available.
- **Verified:** Fallback gait derivation is `10 / timed_seconds` when only
  timed 10-meter walk values are available.
- **Verified:** Chair input uses `FTSST0` and `FTSST2`.
- **Verified:** Balance input uses `SLS_mean0` and `SLS_mean2` as the core
  summary branch; `SLS_best*` is reserved for sensitivity use.
- **Verified:** `grip_*`, `Puristus_*`, and related grip-class variables remain
  a separate branch and must not be merged into the locomotor outcome branch.
- **Verified:** `tasapainovaikeus` is a separate auxiliary predictor/covariate,
  not a locomotor outcome indicator.

## Indicator Preprocessing

- **Verified:** Gait must be oriented as higher = better gait speed.
- **Verified:** Chair must be transformed to a capacity-oriented direction
  before CFA or z3 construction so that higher = better.
- **Needs verification:** The exact mathematical chair transformation is not
  frozen here unless restated from the verified implementation layer.
- **Verified:** Balance is built from `SLS_mean*`.
- **Verified:** Balance values `>300` are recoded to `NA` before aggregation.
- **Inference:** If direct summary variables are absent, the right/left balance
  mean is the preferred deterministic aggregation.

## z3 Standardization Branch

- **Verified:** `z3` is the deterministic fallback / sensitivity outcome built
  from gait, chair, and balance indicators representing the same locomotor
  construct as the CFA branch.
- **Inference:** Baseline-anchored standardization for follow-up values is
  methodologically coherent and preferred for longitudinal comparability.
- **Inference:** Baseline-anchored means that each indicator's baseline mean
  and standard deviation are estimated from the baseline analysis frame only,
  and both baseline and 12-month values are standardized using those same
  baseline parameters.
- **Needs verification:** This document does not lock whether z3 requires 2/3
  versus 3/3 indicators; the threshold must be frozen explicitly in the
  eventual implementation layer.
- **Needs verification:** The exact z3 standardization implementation should be
  matched against the verified measurement/QC implementation before code freeze,
  even when baseline-anchored standardization is used.

## CFA Branch

- **Verified:** `locomotor_capacity` is the current primary outcome.
- **Verified:** The CFA branch uses one latent factor with gait, chair, and
  balance as indicators.
- **Verified:** The latent score is the primary locomotor outcome branch, while
  `z3` remains the deterministic fallback / sensitivity branch.
- **Inference:** Wide outputs should map explicitly to
  `locomotor_capacity_0` and `locomotor_capacity_12m`, while long outputs use
  `locomotor_capacity` with `time`.

## Legacy Bridge Branch

- **Verified:** `Composite_Z` is a legacy bridge outcome only.
- **Verified:** `Composite_Z` must not be presented as the current whole-sample
  primary outcome.
- **Verified:** `Composite_Z` is produced only if the original
  `ToimintaKykySummary` definition can be verified sufficiently.
- **Needs verification:** Exact recreation of the original
  `ToimintaKykySummary` remains a separate verification task if bridge analyses
  are required.

## Canonical Output Names

- **Verified:** Primary branch names are `locomotor_capacity`,
  `locomotor_capacity_0`, `locomotor_capacity_12m`, and
  `delta_locomotor_capacity`.
- **Verified:** Fallback branch names are `z3`, `z3_0`, `z3_12m`, and
  `delta_z3`.
- **Verified:** Legacy bridge names remain `Composite_Z`, `Composite_Z_0`, and
  `Composite_Z_12m` only in bridge contexts.
- **Verified:** `FI22_nonperformance_KAAOS` remains separate from all locomotor
  outcome names.
- **Verified:** Categorical frailty structures such as `frailty_cat_3` are not
  retained as active outcome- or predictor-branch terms in the current plan.
- **Verified:** New aliases such as `new_composite`, `locomotor_z`, or
  `Composite_Z3` are not allowed.

## QC Checklist

- **Verified:** Confirm the outcome branch in use:
  `locomotor_capacity`, `z3`, or legacy `Composite_Z`.
- **Verified:** Confirm grip variables remain outside the core locomotor branch.
- **Verified:** Confirm `tasapainovaikeus` is modeled only as an auxiliary
  predictor/covariate when used.
- **Verified:** Confirm `FI22_nonperformance_KAAOS` is handled only as a
  separate `sensitivity_index`.
- **Inference:** Branch-level QC should report whether the working dataset is
  wide or long before primary modeling.
- **Needs verification:** The final implementation should freeze explicit
  acceptance gates for z3 coverage and branch-specific missing-data thresholds.
