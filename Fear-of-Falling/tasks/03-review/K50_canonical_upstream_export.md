# Task: K50 Canonical Upstream Export

## Context

`R-scripts/K50/K50.r` remains the correct analytical baseline and stays
fail-closed as a pure consumer. The canonical upstream-export step is now
implemented in `K32`, which writes K50-ready wide and long datasets with the
required canonical names.

Current review baseline:

- `K32` is the producing layer for canonical `locomotor_capacity` / `z3`
  export
- `K50` consumes those canonical datasets without analysis-side alias bridges
- `K33` and `K36` remain outside the primary locomotor-capacity export path
- sibling source scripts remain the original lineage evidence for CFA/z3 and
  FI22 role isolation

## Clarification: source vs derivation vs export

Three different layers must stay separate:

1. Raw data source:
   sibling scripts point to `${DATA_ROOT}/paper_02/KAAOS_data.xlsx` (or the
   related KAAOS raw xlsx lineage)

2. Verified derivation logic:
   sibling `32_cfa_3item.r` shows how baseline-oriented CFA/z3 source
   components are built; sibling `K40_FI_KAAOS.R` shows the locked FI22 logic

3. K50-ready canonical export:
   a patient-level long or wide dataset with exact K50 names

Knowing the raw XLSX source was necessary, but the review question is no longer
about missing canonical export availability. The review question is now whether
the implemented `K32` export is hardened and internally consistent.

## Accepted time-map interpretation

- Functional-test schema and existing repo usage already treat suffix `0` as
  baseline and suffix `2` as 12 months for gait, chair, and balance source
  variables.
- Under that project convention, the old raw-timepoint identification blocker
  is closed.
- The accepted implementation consequence is now locked: the producing layer
  must materialize canonical CFA/z3 export using that `0/2` source time map,
  and the current implementation does this in `K32`.

## Inputs

- `R-scripts/K32/k32.r`
- `R-scripts/K33/k33.r`
- `R-scripts/K36/k36.r`
- `R-scripts/K50/K50.r`
- `docs/ANALYSIS_PLAN.md`
- `docs/FOF_UPSTREAM_LOCOMOTOR_OUTCOME_SPEC.md`
- `tasks/03-review/K50_upstream_input_and_runtime_hardening.md`
- `../Quantify-FOF-Utilization-Costs/R/32_cfa/32_cfa_3item.r`
- `../Quantify-FOF-Utilization-Costs/R/40_FI/K40_FI_KAAOS.R`

## Goal

Confirm that the implemented `K32` export remains the correct smallest upstream
touchpoint and that its review hardening is sufficient: fail-closed on mapping
ambiguity, fail-closed on inadmissible primary CFA, fail-closed on insufficient
canonical score completeness, and still consumable by `K50`.

## Allowed target contracts

One of these must be produced exactly:

1. Long:
   `id`, `time`, `FOF_status`, `locomotor_capacity`, `z3`
   with `time in {0, 12}`

2. Wide:
   `locomotor_capacity_0`, `locomotor_capacity_12m`, `z3_0`, `z3_12m`

## Constraints

- Do not modify `R-scripts/K50/K50.r` analytically
- Do not redefine `Composite_Z` as `z3`
- Do not present `Composite_Z` as the current primary outcome
- Do not use `FI22_nonperformance_KAAOS` as part of locomotor construction
- Do not merge grip into the core locomotor branch
- Do not edit raw data
- Do not add uncontrolled aliases
- If verified upstream logic is still insufficient, stop and document the exact
  remaining derivation/export gap
- Do not skip sibling repo inspection of
  `../Quantify-FOF-Utilization-Costs/`

## Mandatory sibling-repo inspection

Before any upstream export patch is proposed, inspect at minimum:

- `../Quantify-FOF-Utilization-Costs/R/32_cfa/32_cfa_3item.r`
- `../Quantify-FOF-Utilization-Costs/R/40_FI/K40_FI_KAAOS.R`

## Sibling-repo finding

- The sibling repo does contain the true source logic for the locomotor
  CFA/z3 branch and the FI22 branch.
- `32_cfa_3item.r` writes patient-level
  `kaaos_with_capacity_scores_32_cfa_3item.(csv|rds)` with
  `capacity_score_latent_primary`, `capacity_score_z3_primary`, and
  `capacity_score_z3_sensitivity`, but from baseline-oriented `*0` raw inputs.
- This solves baseline CFA/z3 source lineage, not the final K50-ready export
  interface.
- If the same raw gait/chair/balance variables are present at `*2`, the
  remaining work is an explicit upstream export step, not a `K50` rewrite.
- `K40_FI_KAAOS.R` explicitly fixes
  `fi_variant = "FI22_nonperformance_KAAOS"` with
  `fi_variant_role = "sensitivity_index"` and excludes performance-test fields
  via deterministic regex.
- This solves FI22 lineage and role isolation, not the 12-month CFA/z3 export.
- Therefore verified source logic existed in the sibling repo before the
  Fear-of-Falling export layer was completed.
- The current review state is that Fear-of-Falling now does surface canonical
  `locomotor_capacity_12m` / `z3_12m` and long `locomotor_capacity` / `z3`
  with `time in {0,12}` from `K32`.

## Chosen upstream touchpoint

The chosen and now-implemented touchpoint is `K32`.

- `K32` reads the verified upstream locomotor source variables using the locked
  `0 = baseline`, `2 = 12 months` convention
- `K32` writes canonical outputs only:
  `locomotor_capacity_0`, `locomotor_capacity_12m`, `z3_0`, `z3_12m`
  and canonical long `id`, `time`, `locomotor_capacity`, `z3`
- `K50` remains unchanged analytically and consumes those outputs directly
- `K36` was not used as an export layer

## Definition of Done (DoD)

- [x] Canonical K50-ready upstream export exists in both long and wide form
- [x] Export uses exact canonical names:
      `locomotor_capacity`, `z3`, `locomotor_capacity_0`,
      `locomotor_capacity_12m`, `z3_0`, `z3_12m`
- [x] Export uses only verified upstream derivations
- [x] Export decision explicitly accounts for sibling source scripts
      `32_cfa_3item.r` and `K40_FI_KAAOS.R`
- [x] `Composite_Z` remains legacy/verification-only and is not relabeled
- [x] `FI22_nonperformance_KAAOS` remains a separate sensitivity index
- [x] Grip remains outside the core locomotor branch
- [x] Any new export artifacts are written with standard output/manifest
      conventions
- [x] `K50.r` can be validated end-to-end with explicit `--shape` and
      `--outcome` only because the canonical input now exists
- [x] Review hardening is in place: ambiguity fail-closed, regression-based
      baseline-fit factor scoring, positive post-orientation chair sign, and
      hard admissibility/completeness gate before canonical export writing

## Review Status

- Upstream canonical export is solved in `K32`; `K50` is no longer blocked by
  unresolved canonical input.
- The active review question is regression confirmation, not missing export
  architecture.
- Review artifacts now show:
  primary CFA admissibility is enforced as a real gate,
  canonical score completeness is enforced,
  mapping ambiguity fails closed with an audit artifact,
  and `K50` smoke continues to pass against the canonical export.

## Links

- `R-scripts/K32/k32.r`
- `R-scripts/K33/k33.r`
- `R-scripts/K36/k36.r`
- `R-scripts/K50/K50.r`
- `docs/ANALYSIS_PLAN.md`
- `docs/FOF_UPSTREAM_LOCOMOTOR_OUTCOME_SPEC.md`
- `tasks/03-review/K50_upstream_input_and_runtime_hardening.md`
- `../Quantify-FOF-Utilization-Costs/R/32_cfa/32_cfa_3item.r`
- `../Quantify-FOF-Utilization-Costs/R/40_FI/K40_FI_KAAOS.R`
