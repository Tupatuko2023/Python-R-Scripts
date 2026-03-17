# DATA LINKAGE PROTOCOL: Outcome Mapping

Tämä dokumentti määrittelee lopputulosmuuttujien (Outcomes) linkityksen ja laskennan
lähdedatasta analyysipaneeliin.

## Protocol Version

Protocol Version: 1.0 (2026-02-01)

## OUTCOME MAPPING: Utilization & Costs

This document maps the clinical concepts of "Polyclinical Visits" and "Hospital Periods"
to their respective column names in the source data and the derived panel.

### Identified Source Columns

Based on `Quantify-FOF-Utilization-Costs/scripts/21_refine_hfrs_mapping.py` and
the data dictionary:

| Clinical Concept        | Source File                                        | Source Variable                       | Description                                                                           |
| :---------------------- | :------------------------------------------------- | :------------------------------------ | :------------------------------------------------------------------------------------ |
| **Polyclinical Visits** | `Tutkimusaineisto_pkl_kaynnit_2010_2019.csv`       | `Henkilotunnus`, `Kayntipvm`          | Outpatient/Specialized care visits. Each row in the source file represents one visit. |
| **Hospital Periods**    | `Tutkimusaineisto_osastojakso_diagnoosit (1).xlsx` | `Henkilotunnus`, `OsastojaksoAlkuPvm` | Inpatient episodes/ward periods.                                                      |

### Panel Columns (Target)

In the current `aim2_panel.csv` (as constructed by `build_real_panel.py`), these are
currently summed into a total. To meet the expert's requirement for separation, we should use:

1. **`util_visits_outpatient`**: Count of unique visits from the PKL source.
2. **`util_visits_inpatient`**: Count of unique admissions/periods from the Inpatient source.

### Construction Logic (Current)

The current `util_visits_total` in `aim2_panel.csv` is constructed as:

- **Scripts**: `build_real_panel.py` and `21_refine_hfrs_mapping.py`.
- **Logic**:

  ```python
  # Outpatient
  out_visits = df_pkl_f.groupby('SSN').size().reset_index(name='Visits_Outpatient')
  # Inpatient
  in_visits = df_in_f.groupby('SSN').size().reset_index(name='Visits_Inpatient')
  # Total
  util_df['util_visits_total'] = util_df['Visits_Outpatient'] + util_df['Visits_Inpatient']
  ```

### Gap Analysis

- The panel builder currently produces `util_visits_total`.
- To satisfy the IRR 1.18 vs 1.70 comparison, the modeling script `R/30_models_panel_nb_gamma.R`
  should be updated to run separate models for `util_visits_outpatient` (Polyclinical)
  and `util_visits_inpatient` (Hospital Periods).
- **Hospital Periods Variable**: `util_visits_inpatient` (derived from `OsastojaksoAlkuPvm` events).
- **Polyclinical Visits Variable**: `util_visits_outpatient` (derived from `Kayntipvm` events in PKL data).
