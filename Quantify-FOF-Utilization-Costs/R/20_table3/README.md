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
