# TASK: Table 1 script relocate and docs

**Status**: 01-ready
**Assigned**: 3caqf
**Created**: 2026-02-05

## OBJECTIVE

Relocate the canonical Table 1 script into `R/10_table1/`, ensure a single generator, and update docs to point to the new single source of truth and output conventions.

## INPUTS

- `Quantify-FOF-Utilization-Costs/R/10_table1_patient_characteristics_by_fof.R`
- `Quantify-FOF-Utilization-Costs/10_handover.md`
- `Quantify-FOF-Utilization-Costs/README.md`
- `SKILLS.md`

## STEPS

1. Create canonical script at `R/10_table1/12_table1_patient_characteristics_by_fof_wfrailty.R`; ensure outputs only to `R/10_table1/outputs/`.
2. Convert old script to wrapper or remove, ensuring a single real generator.
3. Update `10_handover.md`, `README.md`, and `SKILLS.md` for single-source-of-truth and per-script outputs/logs.
4. Move task to `03-review/` when ready for review (after changes).

## ACCEPTANCE CRITERIA

- [ ] Canonical Table 1 script lives in `R/10_table1/12_table1_patient_characteristics_by_fof_wfrailty.R`.
- [ ] Old `R/10_table1_patient_characteristics_by_fof.R` is not a second generator (wrapper or removed).
- [ ] Outputs write only to `R/10_table1/outputs/` (no shared outputs/tables).
- [ ] Docs updated: `10_handover.md`, `Quantify-FOF-Utilization-Costs/README.md`, `SKILLS.md`.

## LOG

- 2026-02-05T05:05:35Z Updated 5 files (new canonical script in R/10_table1/, wrapper added, 10_handover.md + README.md + SKILLS.md). No runs performed; no outputs committed; wrapper is deprecation-only.
- 2026-02-05T08:19:15Z Run performed in approved environment. Frailty block present in generated CSV. No outputs/logs committed; no paths printed; ALLOW_AGGREGATES=1 used.
