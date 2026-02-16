# Table 3 (R/20_table3)

Generates manuscript-ready Table 3: injury-related health care usage vs control per 1000 patient-years,
stratified by FOF and case/control, with IRR (95% CI).

## Run (standalone)

```bash
cd Quantify-FOF-Utilization-Costs
export DATA_ROOT="/path/to/restricted/data"
Rscript R/20_table3/20_table3_injury_usage_per_1000_py.R \
  --data_root "$DATA_ROOT" \
  --output_dir "outputs/tables" \
  --visits_file "Tutkimusaineisto_pkl-käynnit_2010_2019.xlsx" \
  --treat_file "Tutkimusaineisto_osastojaksot_2010_2019.xlsx" \
  --engine "negbin"
```

## Outputs

- outputs/tables/table3.csv
- outputs/tables/table3.md
- optional: outputs/tables/table3.docx (`--make_docx`)

## Notes

- Variable mapping uses `data/VARIABLE_STANDARDIZATION.csv`.
- Rows with empty/FIXME `original_variable` are ignored (no guessing).

## Controls Inputs Required (Fail-Closed)

Table 3 build requires controls data in `DATA_ROOT` with explicit linkage in the same ID space as analysis data.

### 1) controls_link_table

- Config key: `table3.controls_link_table`
- Suggested path: `derived/controls_link_table.csv`
- Required columns:
  - `id` (analysis ID; same ID space as `derived/aim2_analysis.csv`)
  - `register_id` (same ID space as `table3.cohort_id_col`)
- Required rules:
  - `id` non-empty and unique
  - `register_id` non-empty and unique
  - no direct identifiers in this file

### 2) controls_panel_file

- Config key: `table3.controls_panel_file`
- Suggested path: `derived/controls_panel.csv`
- Required columns:
  - `id`, `case_status`, `fof_status`, `age`, `sex`, `py`
- Required rules:
  - `id` non-empty and unique
  - `case_status` must be `control` for all rows
  - `py > 0` for all rows
  - no direct identifiers in this file

### 3) Cohort gates enforced by build

- controls must exist in roster (`table3.cohort_file`)
- controls linkage/panel must be configured and readable
- `controls_panel.id` must map via `controls_link_table.id`
- case and control IDs must be disjoint (`case_ids ∩ control_ids = ∅`)
- pipeline stops on first failing gate (fail-closed)

## Readiness Check

```bash
cd Quantify-FOF-Utilization-Costs
snakemake -j 1 --forcerun build_table3_inputs table3
```

Expected behavior:

- Build passes only when controls linkage + controls panel are valid.
- Otherwise run stops with actionable gate message in `outputs/logs/table3_inputs.log`.
