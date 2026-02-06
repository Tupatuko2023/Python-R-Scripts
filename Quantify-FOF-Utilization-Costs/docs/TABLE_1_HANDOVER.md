# Table 1 Handover (FOF Baseline Characteristics)

## Problem (historical context)
Earlier runs reported N=126/276 and assumed N=486 from aim2_panel.csv. That was
insufficient for Table 1 because baseline variables are not all in the panel
and linkage keys were inconsistent.

**Final expected run outputs (accepted):**
- Table 1 sample N (age >= 65 & FOF not missing): 441
- Frailty match_rate: 0.98
- Frailty distribution: robust=115, pre-frail=187, frail=130, unknown=9
- Smoking: No=417, Yes=24, Unknown=0

## Fix 2 (FINAL): Canonical linkage + frailty mapping for Table 1

### Panel (aim2_panel.csv)
- Treat aim2_panel.csv as a long-form panel (multiple rows per person).
- Create a deterministic baseline panel cohort by keeping 1 row per id:
  - If period exists and is sortable: arrange by (id, period) and slice(1).
  - Otherwise: arrange by (id) and slice(1).

### Crosswalk (sotut.xlsx)
- Use sotut.xlsx as the required bridge between panel id and baseline identifiers.
- Deterministic dedup rule: if multiple NRO per key, keep min NRO per key.
- Hard fail on conflicting mappings that cannot be deterministically resolved.

### Baseline (KAAOS_data_sotullinen.xlsx)
- Baseline file can contain multiple rows per NRO/visit.
- Reduce to 1 row per NRO deterministically (prefer earliest visit date if parseable; else slice(1)).

### Frailty mapping (from panel)
Derive 3-class frailty from frailty_fried:
- 0 -> Robust
- 1-2 -> Pre-frail
- 3 -> Frail
- >3 or NA -> Unknown

Validate with a gate:
- fail if the deduped panel baseline produces 100% Unknown for frailty_cat_3.

### Smoking (from baseline)
Smoking is taken from baseline KAAOS (not panel) and must be present after baseline read/dedup.

## Fix 3 (FINAL): Data integrity gates (mandatory)

1) Panel dedup size gate (effective cohort)
- Acceptable effective panel baseline cohort is ~474-477.
- Fail if panel_dedup < 470.

2) Frailty baseline sanity gate
- Fail if frailty_cat_3 is 100% Unknown on the deduped panel baseline.

3) Linkage match rate gate (Table 1 sample)
- Compute match_rate on the final Table 1 sample.
- Require match_rate >= 0.70.

