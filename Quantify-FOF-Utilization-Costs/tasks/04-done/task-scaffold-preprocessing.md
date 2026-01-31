---
title: Scaffold Preprocessing Pipeline and Synthetic Data
status: in-progress
assignee: gpa4qf
---

# Objectives

1. Populate data/ with metadata CSVs.
2. Create data/synthetic_sample.csv for CI-safe testing.
3. Implement scripts/10_preprocess_tabular.py skeleton.

# Specs

* **Data Policy:** Option B (Real data external, Synthetic internal).
* **Script logic:**
  * If --use-sample: Load data/synthetic_sample.csv.
  * Else: Load from os.getenv('DATA_ROOT').
* **Validation:** Check columns against data_dictionary.csv.
