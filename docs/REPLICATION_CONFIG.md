# REPLICATION CONFIG: Injury-Only Outcomes

This document provides the specific file paths and column names required to filter utilization data for injury-related outcomes (ICD-10 S00-S99, T00-T14) to replicate the original manuscript findings.

## 1. Outpatient Utilization (Polyclinical)

- **File Path**: `paper_02/Tutkimusaineisto_pkl_kaynnit_2010_2019.csv` (relative to `DATA_ROOT`)
- **ID Column**: `Henkilotunnus` (Links to `id` in panel after cleanup)
- **Date Column**: `Kayntipvm` (Format: YYYYMMDD)
- **Primary ICD-10 Column**: `Pdgo`
- **Secondary ICD-10 Columns**: `Sdg1o`, `Sdg2o`, `Sdg3o`, `Sdg4o`, `Sdg5o`, `Sdg6o`, `Sdg7o`, `Sdg8o`, `Sdg9o`

## 2. Inpatient Utilization (Hospital Periods)

- **File Path**: `paper_02/Tutkimusaineisto_osastojakso_diagnoosit (1).xlsx` (relative to `DATA_ROOT`)
- **ID Column**: `Henkilotunnus` (Links to `id` in panel after cleanup)
- **Admission Date Column**: `OsastojaksoAlkuPvm` (Format: YYYYMMDD or Date object)
- **Primary ICD-10 Column**: `Pdgo`
- **Secondary ICD-10 Columns**: `Sdg1o`, `Sdg2o`, `Sdg3o`, `Sdg4o`, `Sdg5o`, `Sdg6o`, `Sdg7o`, `Sdg8o`, `Sdg9o`

## 3. Analysis Panel (Derived)

- **File Path**: `derived/aim2_panel.csv` (relative to `DATA_ROOT`)
- **ID Column**: `id`
- **Year/Period Column**: `period` (Format: YYYY)

## 4. Replication Filtering Logic (Heuristic)

To identify an injury-related event:
1.  Load the raw file.
2.  Filter rows where any of the ICD-10 columns (`Pdgo` or `Sdg1o-9o`) starts with the letters **'S'** or **'T'** (specifically S00-S99, T00-T14).
3.  Aggregate by ID and Year (extracted from the date column).
4.  Merge back to the `aim2_panel.csv` to create new outcome variables (e.g., `util_inj_outpatient`, `util_inj_inpatient`).
