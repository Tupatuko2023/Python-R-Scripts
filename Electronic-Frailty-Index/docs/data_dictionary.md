# Data Dictionary - synthetic example

This describes the minimum fields for the synthetic demo data. Do not add PHI or PII to the repository.

## Table: `synthetic_patients.csv`

| Column           | Type    | Description                                         | Example |
|------------------|---------|-----------------------------------------------------|---------|
| id               | string  | Unique identifier, random or sequential             | P001    |
| age              | integer | Age in years                                        | 72      |
| sex              | string  | Sex code, e.g., F or M                              | F       |
| def_hypertension | 0 or 1  | Binary related to the deficit list                  | 1       |
| def_diabetes     | 0 or 1  | Binary                                              | 0       |
| def_cvd          | 0 or 1  | Binary                                              | 1       |
| def_copd         | 0 or 1  | Binary                                              | 0       |
| def_ckd          | 0 or 1  | Binary                                              | 0       |

Notes

- In the demo, EFI is computed as a simple ratio: sum(def_*) divided by the
  number of deficits. This is only an example.
- For a production EFI, add references, an approved code list, inclusion and
  exclusion criteria, and a validation report.
- The data is synthetic and does not represent real patients.
- Do not use this data for clinical decision-making.
- Ensure compliance with data protection regulations when handling real patient
  data.
- Contact "Tomi.Korpi at outlook.com" for questions.
- License: MIT License (see LICENSE file)
- Disclaimer: See DISCLAIMER.md file
