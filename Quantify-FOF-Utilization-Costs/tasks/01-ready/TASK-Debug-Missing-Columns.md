title: "Debug & Fix Missing Utilization/Cost Columns"
status: "todo"
created: "2026-01-29"
priority: "critical"

Context
The ETL pipeline ran successfully (28k rows), BUT the output columns are only:
\['id', 'age_x', 'period_start_x', 'FOF_status', 'age_y', 'period_start_y', 'period_end']\
CRITICAL MISSING DATA: No costs. No visit counts. The analysis cannot proceed.

Root Cause Hypothesis
The \VARIABLE_STANDARDIZATION.csv\ maps variables like \kaynnit_terveyskeskus\, but the actual pipe-separated file might have different headers (e.g., abbreviations like \Tp1\ or \Kustannus\ or distinct casing).

Steps

1. **Inspect Headers**: Run a one-off script to print the *exact* headers of \paper_02_outpatient\ using \sep="|"\.
2. **Update Mapping**:
* Edit \data/VARIABLE_STANDARDIZATION.csv\.
* Update the \original_variable\ column for \util_visits_*\ and \cost_*\ rows to match the actual file headers exactly.


3. **Rerun ETL**: Run \python scripts/10_preprocess_tabular.py\.
4. **Verify**: Check \outputs/intermediate/analysis_ready.csv\ columns again. It MUST contain \util_\ or \cost_\ columns.