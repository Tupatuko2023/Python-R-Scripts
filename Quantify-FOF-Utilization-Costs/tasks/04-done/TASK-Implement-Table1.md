# TASK: Implement Table 1 Patient Characteristics

**Status**: 01-ready
**Assigned**: Gemini
**Created**: 2026-02-02

## OBJECTIVE

Implement a publication-ready baseline Table 1 by Fear of Falling (FOF) within the `Quantify-FOF-Utilization-Costs` subproject. This script must adhere to Option B security rules and support aggregated output generation.

## INPUTS

- `DATA_ROOT/derived/kaatumisenpelko.csv`
- `DATA_ROOT/derived/aim2_panel.csv`
- `DATA_ROOT/data/kaatumisenpelko.csv`

## STEPS

1. Create the R script `scripts/10_table1_patient_characteristics_by_fof.R`.
2. Ensure the script includes robust column mapping and recoding for FOF, sex, age, BMI, and other characteristics.
3. Implement N<5 suppression for all table cells and p-values to comply with Option B.
4. Add fail-closed mechanisms to prevent data leakage if `ALLOW_AGGREGATES` is not set.
5. Verify script execution and output generation in a secure environment.

## ACCEPTANCE CRITERIA

- [ ] Script `Quantify-FOF-Utilization-Costs/scripts/10_table1_patient_characteristics_by_fof.R` exists.
- [ ] Script follows standard intro conventions and Option B security rules.
- [ ] Aggregated CSV/HTML/DOCX outputs are generated correctly when permitted.
- [ ] N<5 suppression is active and verified.
