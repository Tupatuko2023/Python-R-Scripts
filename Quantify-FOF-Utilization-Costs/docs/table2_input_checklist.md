# Table 2 input checklist (PATH_* and usage)

Purpose: Confirm all required Table 2 inputs are set locally before running the Table 2 script. This does not print or request paths. Refer to `docs/table2_runbook.md` and the data dictionary in this project for column definitions.

## Required PATH_* inputs
- `PATH_AIM2_ANALYSIS`
  - Used for: Participant-level analysis dataset (`aim2_analysis`).
  - Script use: Reads `id`, `FOF_status`, `age`, `sex`, `followup_days`, then derives `person_years`.

- `PATH_PKL_VISITS_XLSX`
  - Used for: Outpatient visits register file (poliklinikka visits).
  - Script use: Reads `Pdgo` (primary diagnosis) and the ID column specified by `PKL_ID_COL`, then ICD-10 block mapping and per-person counts.

- `PATH_WARD_DIAGNOSIS_XLSX`
  - Used for: Inpatient/ward diagnosis register file (osastojaksodiagnoosit).
  - Script use: Reads `Pdgo` and the ID column specified by `WARD_ID_COL` to count treatment periods.

## Required ID column names (env vars)
- `PKL_ID_COL`
  - Used for: ID column name in outpatient visits file.
  - Must match the exact column name in the Excel header.

- `WARD_ID_COL`
  - Used for: ID column name in inpatient/ward file.
  - Must match the exact column name in the Excel header.

## Linkage (required if IDs do not match)
- `PATH_LINK_TABLE` (required when `aim2_analysis$id` does not match registry IDs)
  - Script use: Maps `id` ↔ `register_id` via link table.
- Optional override names if link table uses different column names:
  - `LINK_ID_COL` (default `id`)
  - `LINK_REGISTER_COL` (default `register_id`)

## Optional episode identifier
- `WARD_EPISODE_ID_COL` (optional)
  - If set, script uses it to count unique treatment periods.
  - If not set, script uses `OsastojaksoAlkuPvm` + `OsastojaksoLoppuPvm` as episode key (these columns must exist).

## Data-root guardrail
- `DATA_ROOT` must be set locally and accessible.
- All `PATH_*` inputs must be under `DATA_ROOT` (enforced by the script).

## Output location (gitignored)
- `R/15_table2/outputs/table2_generated.csv`

## Run command (double-gate required)
- `ALLOW_AGGREGATES=1 INTEND_AGGREGATES=true Rscript R/15_table2/15_table2_usage_injury_services.R`
