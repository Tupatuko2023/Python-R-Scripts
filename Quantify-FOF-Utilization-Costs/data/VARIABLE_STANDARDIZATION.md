# VARIABLE_STANDARDIZATION (metadata-only)

## Purpose
Provide an English-standard naming layer and short, safe, **heuristic** descriptions for variables discovered from DATA_ROOT (Option B).
Descriptions are inferred from variable names and role_guess only; they must be confirmed by domain owners before publication.

## Artifacts
- `data/data_dictionary.csv`: per-source schema + safe aggregates + inferred English columns
- `data/VARIABLE_STANDARDIZATION.csv`: mapping table (original -> English/standard) + inferred descriptions

## Naming rules (English standard)
- Use `snake_case`
- Add units as suffix where obvious: `_eur`, `_days`, `_count`
- Dates end with `_date` when role_guess indicates a date
- Identifiers are treated as strings (pseudonymized)

## Direct identifiers
- Variables indicating direct personal identity codes are tagged in notes as DIRECT_IDENTIFIER and must not be used in repo outputs.

## Filename redaction (Option B)
- Source filenames containing identifier-like tokens are redacted in outputs.
- `identifier_like_filename=1` marks redacted filenames; use sha256_prefix1mb for deterministic linkage.

## Role summary (from role_guess heuristics)
- Total variables in mapping: 474
- date: 24
- identifier: 6

## Unreadable sources
Some files could not be read (e.g., password-protected copies). These are recorded as `FILE_UNREADABLE` and excluded from variable-level mapping.
- `Lifecare potilasaineisto – kopio.xlsx`: UNREADABLE/COPY/PASSWORD-PROTECTED (XLRDError: Can't find workbook in OLE2 compound document)
- `verrokitjatutkimushenkilöt – kopio.xlsx`: UNREADABLE/COPY/PASSWORD-PROTECTED (XLRDError: Can't find workbook in OLE2 compound document)

## How to use
1) Start from `VARIABLE_STANDARDIZATION.csv` to see the proposed English standard names and inferred descriptions.
2) Confirm/replace `description_en` (and optionally fill `description_fi`) in a separate governance step if needed.
3) Keep Option B: never add participant-level examples or raw values to repo artifacts.
