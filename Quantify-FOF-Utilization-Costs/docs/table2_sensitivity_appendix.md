# Table 2 Sensitivity Appendix (T00–T98)

## Rationale
Primary Table 2 uses the locked hospital definition: injury-related collapsed dx days with ICD-10 S00–S99 and T00–T14. This appendix evaluates a broader T-range (T00–T98) to assess sensitivity of the hospital-day metric to ICD scope.

## Methods (Sensitivity Variant)
The sensitivity variant applies the same deterministic pipeline as the primary definition:
dxfile → injury ICD-10 → date-bounded merge → interval collapse → distinct days.
The only change is ICD scope: S00–S99 plus T00–T98 instead of T00–T14.

## Results (Rates / 1000 PY)
Collapsed injury-days with T00–T98:
- FOF_No: 463.45 / 1000 PY
- FOF_Yes: 633.14 / 1000 PY
- Overall: 582.51 / 1000 PY

For reference, the primary definition (T00–T14) yields:
- FOF_No: 377.93 / 1000 PY
- FOF_Yes: 500.59 / 1000 PY
- Overall: 463.99 / 1000 PY

## Interpretation
Broadening T-codes increases absolute rates for both groups while preserving the directionality. The main table retains the primary (T00–T14) definition to align with manuscript-scale hospital-day rates.

## Conclusion
This sensitivity check supports robustness of the hospital outcome definition. The primary Table 2 definition remains locked as `TABLE2_LOCKED_v2_collapsed_dx_days`.
