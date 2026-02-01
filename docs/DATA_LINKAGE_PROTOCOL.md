# Data Linkage Protocol: Expanded Frailty Cohort (Aim 2)

## 1. Overview
This protocol describes the "Rescue" operation used to expand the study population from the clinical follow-up subset (N=276) to the full baseline cohort (N=486). The expansion was achieved by mining raw baseline data from the monorepo's source Excel files.

## 2. Source Files
- **Primary Source**: `KAAOS_data_sotullinen.xlsx` (N=630). Contains baseline metrics for the full cohort.
- **Mapping Fallback**: `verrokitjatutkimushenkilöt.xlsx`. Used to link participants who were missing from the primary Sotu mapping file but were present in the study's internal ID registers.

## 3. ID Linkage Hierarchy
To maximize the match rate while ensuring data integrity, the following hierarchy was applied:
1.  **Primary**: Direct extraction of the `Sotu` (Finnish Social Security Number) from Column 2 of `KAAOS_data_sotullinen.xlsx`.
2.  **Secondary (Fallback)**: If `Sotu` is missing in the primary file, use the `NRO` (Column 0) to look up the corresponding Sotu in `verrokitjatutkimushenkilöt.xlsx` (Internal ID `Tutkimus-henkilön numero` mapping to `Tutkimus-henkilön henkilötunnus`).

Final Result: **N=551** participants linked to a valid Sotu ID.

## 4. Variable Mapping (Raw to Analysis)

### 4.1 Demographics & Grouping
| Variable | Raw Column Index | Excel Label | Logic |
| :--- | :--- | :--- | :--- |
| **NRO** | 0 | NRO | Internal sequence number |
| **Age** | 4 | ikä(a) | Years |
| **Sex** | 5 | sukupuoli | 0=Female, 1=Male |
| **BMI** | 17 | BMI | kg/m² |
| **FOF** | 34 | kaatumisen pelko | 0=No, 1=Yes (Dropped EOS/2/3) |

### 4.2 Frailty Components (Fried-Inspired Proxy)
The proxy uses 3 components (Sum 0-3). Exhaustion is excluded as per technical audit.

#### A. Strength (Weakness)
- **Source**: `StrengthR` (Col 45) and `StrengthL` (Col 46).
- **Unit**: Categorical Classes (kl) 0-5.
- **Mapping**: Class 1 ≈ 10kg, Class 2 ≈ 17kg.
- **Cutoff**: **Weak** if `max(R, L) <= 1` (Women) or `<= 2` (Men).

#### B. Speed (Slowness)
- **Source**: `Speed10m_sec` (Col 47).
- **Unit**: Seconds for 10 meters.
- **Cutoff**: **Slow** if `time > 12.5 sec` (Equivalent to < 0.8 m/s).

#### C. Activity (Low Activity)
- **Source**: `ActSR` (Col 26), `Act500m` (Col 27), `Act2km` (Col 28), `MaxWalk` (Col 37).
- **Logic**: **Low Activity** if any of:
    - Self-assessment (`ActSR`) == 2 (Heikko).
    - 500m difficulty (`Act500m`) in {1, 2}.
    - 2km difficulty (`Act2km`) in {1, 2}.
    - Max walk distance (`MaxWalk`) < 400m.

## 5. Statistical Implementation
- **Script**: `Quantify-FOF-Utilization-Costs/scripts/build_real_panel.py`.
- **Reference Level**: "Robust" (Score 0) is enforced as the reference level in all Negative Binomial and Gamma models.
- **Exclusion**: Participants with "Unknown" frailty (missing component data) are excluded from interaction models but retained in overall descriptive statistics.

---
*Protocol Version: 1.0 (2026-02-01)*
# OUTCOME MAPPING: Utilization & Costs

This document maps the clinical concepts of "Polyclinical Visits" and "Hospital Periods" to their respective column names in the source data and the derived panel.

## Identified Source Columns

Based on `Quantify-FOF-Utilization-Costs/scripts/21_refine_hfrs_mapping.py` and the data dictionary:

| Clinical Concept | Source File | Source Variable | Description |
| :--- | :--- | :--- | :--- |
| **Polyclinical Visits** | `Tutkimusaineisto_pkl_kaynnit_2010_2019.csv` | `Henkilotunnus`, `Kayntipvm` | Outpatient/Specialized care visits. Each row in the source file represents one visit. |
| **Hospital Periods** | `Tutkimusaineisto_osastojakso_diagnoosit (1).xlsx` | `Henkilotunnus`, `OsastojaksoAlkuPvm` | Inpatient episodes/ward periods. |

## Panel Columns (Target)

In the current `aim2_panel.csv` (as constructed by `build_real_panel.py`), these are currently summed into a total. To meet the expert's requirement for separation, we should use:

1.  **`util_visits_outpatient`**: (To be implemented) Count of unique visits from the PKL source.
2.  **`util_visits_inpatient`**: (To be implemented) Count of unique admissions/periods from the Inpatient source.

## Construction Logic (Current)

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

## Gap Analysis
- The panel builder currently produces `util_visits_total`.
- To satisfy the IRR 1.18 vs 1.70 comparison, the modeling script `R/30_models_panel_nb_gamma.R` should be updated to run separate models for `util_visits_outpatient` (Polyclinical) and `util_visits_inpatient` (Hospital Periods).
- **Hospital Periods Variable**: `util_visits_inpatient` (derived from `OsastojaksoAlkuPvm` events).
- **Polyclinical Visits Variable**: `util_visits_outpatient` (derived from `Kayntipvm` events in PKL data).
