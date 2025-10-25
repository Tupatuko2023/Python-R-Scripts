# EFI Minimums (v1.0)

---

title: "EFI Minimums"
version: "v1.0"
status: "Demo only — not for clinical use"
updated: "2025-10-25"

---

## Overview

**Purpose.** Demonstrate the Electronic Frailty Index (EFI) scoring pipeline
using **synthetic** data.
**Intended use.** Research or demo only. **Not** for clinical decision making.

> **Important:** This repository and its outputs are demonstrations using
> synthetic data. They are not validated for clinical care or patient-level
> decisions.

## 1. Scope

- **Data:** only `data/external/synthetic_patients.csv` (no PHI or PII).
- **Population:** synthetic adult sample.
- **Outputs:**
  - `out/efi_scores.csv` with at minimum columns `id` and `efi_score`
  - `out/report.md` as a simple run report

## 2. Minimum Inputs

- **Required columns:** `id`, `age`
- **Optional deficit indicators:** `def_*` coded as 0 or 1
- **Extensible fields:** diagnoses, medications, functional measures.
  Document any additions in `data_dictionary.md`.

## 3. Computation Overview

- **EFI definition:** approximately number of identified deficits divided by
  number of assessed deficits.
  _For academic validation and citations, see [future updates]._
- **Weights:** equal weights in v1.0 unless otherwise noted.
- **Normalization:** result scaled to 0–1.

## 4. Reproducible Example

```bash
python src/efi/cli.py \
  --input data/external/synthetic_patients.csv \
  --out out/efi_scores.csv \
  --report-md out/report.md
```

## 5. Limitations and Notes

Synthetic data may not reflect real-world distributions or correlations.

The implementation is a minimal, educational example.

Any extensions or changes should be documented and versioned.

## 6. References

**Pending peer-review citations.** References will be added when available.
For now, see [link to EFI literature/relevant papers] or [internal citation policy].
