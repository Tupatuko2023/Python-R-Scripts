# 32 CFA 3-item Methods and QC Appendix

## Methods

### Latent locomotor capacity construct

Locomotor capacity was operationalized as a latent construct representing
underlying locomotor performance. The construct was defined using three
objective physical performance indicators: gait speed, chair rise performance,
and standing balance. These indicators capture complementary aspects of
locomotor function, including locomotion speed, lower limb muscle power, and
postural control.

Gait speed was derived from a timed 10-meter walk test and expressed as meters
per second. Chair rise performance was measured as the time required to complete
five chair rises and transformed to a capacity-oriented scale so that higher
values represented better performance. Standing balance was derived from
single-leg stance performance using the mean of the right and left trials when
no direct balance summary variable was available.

### Confirmatory factor analysis

The locomotor capacity construct was estimated using confirmatory factor
analysis (CFA). A single latent factor model was specified with gait speed,
chair rise performance, and standing balance as reflective indicators:

`Capacity =~ gait + chair + balance`

Models were estimated in R using the `lavaan` package via explicit namespace
calls (`lavaan::cfa()`, `lavaan::lavPredict()`,
`lavaan::parameterEstimates()`, and `lavaan::lavInspect()`). Latent factor
scores were obtained using regression-based factor score estimation.

Because the model contained three indicators, it was just-identified.
Consequently, traditional global fit indices were not interpreted as evidence of
model adequacy. Instead, construct adequacy was evaluated using factor loading
magnitude and sign consistency together with factor score reliability.

### Factor score reliability

Factor score reliability was evaluated using factor determinacy. Factor
determinacy indicates how accurately the estimated factor scores approximate the
underlying latent construct. Values above 0.80 are generally considered good,
and values above 0.90 indicate excellent score reliability.

### Composite fallback score

To ensure robustness of the analysis pipeline and to preserve a deterministic
fallback if CFA scoring were unavailable, a standardized composite score was
also calculated. This score was computed as the row-wise mean of the
z-standardized gait, chair rise, and balance indicators (`z3` composite).

The latent CFA-based score served as the primary locomotor capacity measure,
while the `z3` composite was retained as a deterministic fallback and
sensitivity measure.

### Indicator mapping and preprocessing

Raw physical performance measures were read from
`DATA_ROOT/paper_02/KAAOS_data_sotullinen.xlsx`. Indicator extraction followed a
deterministic sheet-and-header audit procedure. The pipeline explored candidate
sheet and skip combinations, identified variables using predefined naming
patterns, and terminated with an error if mapping was ambiguous.

In the validated source-of-truth run, the selected workbook layout was
`sheet=Taul1` with `skip=1`. Gait was mapped from the raw 10-meter walk-time
variable and converted to gait speed as `10 / timed_seconds`. Chair rise was
mapped from the five-times chair stand time and oriented so that higher values
represented better performance. Balance was mapped from the right and left
single-leg stance variables and summarized as their mean. Implausible balance
values greater than 300 seconds were recoded to missing before aggregation.

Patient-level outputs were written only to a protected `DATA_ROOT` location,
whereas non-identifiable aggregate quality-control artifacts were written under
`R/32_cfa/outputs/<run_id>/` inside the repository.

## Results

### Source-of-truth run

Validated run ID: `20260311_203153`

Key run metrics:

- selected sheet: `Taul1`
- selected skip: `1`
- rows loaded from raw workbook: `630`
- rows with `z3` score available: `512`
- rows with complete-case CFA indicators: `438`

### CFA results

Standardized factor loadings were:

- gait: `0.967`
- chair: `0.571`
- balance: `0.581`

Factor determinacy was `0.969`, indicating excellent reliability of the latent
factor scores. As expected for a just-identified three-indicator CFA model,
global fit indices were numerically perfect and were not used as the primary
basis for model evaluation (`CFI=1.00`, `TLI=1.00`, `RMSEA=0.00`, `SRMR~0`).

### Suggested manuscript Results paragraph

A single-factor confirmatory factor analysis was fit for locomotor capacity
using gait speed, chair rise performance, and standing balance as reflective
indicators. All indicators loaded positively on the latent factor, with the
strongest loading observed for gait speed (standardized loading 0.97), followed
by chair rise performance (0.57) and balance (0.58). Factor determinacy was
0.97, indicating that the estimated factor scores closely approximated the
underlying locomotor capacity construct. Because the model was just-identified,
global fit indices were not interpreted as evidence of model adequacy.

## Discussion Note

Grip strength and self-reported mobility limitations were not included in the
core locomotor capacity model because grip strength was only available for a
subset of participants and self-reported mobility reflects functional ability
rather than intrinsic locomotor capacity.

## Future Extension

If subgroup stability is examined later, a natural next step is measurement
invariance testing across sex, age group, or frailty strata.
