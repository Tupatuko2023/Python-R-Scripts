# Task: Update Variable Standardization for Aim 2

## Status

* **Source:** docs/analysis_plan.md
* **Target:** data/VARIABLE_STANDARDIZATION.csv

## Context

Analysis Plan Aim 2 requires specific panel variables (`period`, `person_time`, `frailty`, costs) to be standardized before R scripts can be written. Since raw column names are currently "KB missing", we will map them from placeholders (e.g., `period_raw`) to the locked standard names.

## Instructions

1. Run the python script below to append the Aim 2 variables to `data/VARIABLE_STANDARDIZATION.csv`.
2. Ensure no duplicate headers are created.

### Python Script to Apply Changes

```python
import csv
import os

file_path = "data/VARIABLE_STANDARDIZATION.csv"

# Columns: source_dataset, original_variable, standard_variable, transform_rule, unit, coding, notes

new_rows = [
    # Panel Time structure
    ["paper_02_panel", "period_raw", "period", "as_factor", "calendar_year", "", "Aim 2 panel period"],
    ["paper_02_panel", "person_time_raw", "person_time", "as_numeric", "person_years", "non-negative", "Aim 2 offset"],
    
    # Covariates
    ["paper_02_covariates", "frailty_score_raw", "frailty_fried", "as_numeric", "points", "0-5", "Fried frailty proxy"],
    ["paper_02_covariates", "prior_falls_n", "prior_falls", "as_integer", "count", "non-negative", "Falls in 12m prior baseline"],
    ["paper_02_covariates", "morbidity_index", "morbidity_charlson", "as_integer", "points", "non-negative", "Charlson Index"],

    # Outcomes (Costs - additional)
    ["paper_02_costs", "cost_total_eur", "cost_total_eur", "eur_numeric", "EUR", "non-negative", "Total direct hc costs"],
    ["paper_02_costs", "cost_inpatient_eur", "cost_inpatient_eur", "eur_numeric", "EUR", "non-negative", "Inpatient costs"],
    ["paper_02_costs", "cost_outpatient_eur", "cost_outpatient_eur", "eur_numeric", "EUR", "non-negative", "Outpatient costs"]
]

# Read existing to prevent exact duplicates
existing_standards = set()
if os.path.exists(file_path):
    with open(file_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            existing_standards.add(row["standard_variable"])

# Append
with open(file_path, "a", encoding="utf-8", newline="") as f:
    writer = csv.writer(f)
    for row in new_rows:
        std_var = row[2]
        if std_var not in existing_standards:
            writer.writerow(row)
            print(f"Added: {std_var}")
        else:
            print(f"Skipped (exists): {std_var}")
```
