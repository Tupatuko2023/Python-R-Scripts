# Handover: Aim 2 Paths & Environment Configuration

To: Codex Agents / Future Orchestrators

## Summary
Manual path discovery for Aim 2 register data is now **DEPRECATED**. We have established a robust, persistent configuration system that separates code from local data paths. All required register paths and ID columns are stored in `config/.env`.

## The "Golden Rule" (Startup Protocol)
To ensure scripts can find the data, you **MUST** load the environment variables at the start of every session.

Run this command immediately from the subproject root:
```bash
source scripts/bootstrap_env.sh
```

## Available Variables
After sourcing the environment, the following variables are automatically available in your session (via `Sys.getenv()` in R or `os.environ` in Python):

| Variable | Description |
| :--- | :--- |
| `DATA_ROOT` | The root directory of the local health data. |
| `PATH_AIM2_ANALYSIS` | Path to the aggregated person-level analysis file. |
| `PATH_PKL_VISITS_XLSX` | Path to the Outpatient (PKL) visit registry file. |
| `PATH_WARD_DIAGNOSIS_XLSX`| Path to the Inpatient (Ward) diagnosis registry file. |
| `PKL_ID_COL` | The ID column name in the outpatient file (e.g., "Henkilotunnus"). |
| `WARD_ID_COL` | The ID column name in the inpatient file (e.g., "Henkilotunnus"). |
| `ALLOW_AGGREGATES` | Set to `1` to allow writing output files. |
| `INTEND_AGGREGATES` | Set to `true` to confirm intent to generate results. |

## Verification
Always verify the setup before running scripts:
```bash
test -n "$DATA_ROOT" && echo "DATA_ROOT: OK"
test -n "$PATH_PKL_VISITS_XLSX" && echo "PKL_PATH: OK"
```

## Security & Maintenance
- **Privacy**: `REGISTER_PATHS.md` and other temporary path documentation files have been removed to prevent data leakage.
- **Persistence**: `config/.env` is ignored by Git. Never commit raw paths to the repository.
- **Updates**: If you discover new data files, add their paths to `config/.env` using the same `export KEY="VALUE"` format.

---
*Created by Gemini Orchestrator (gqf14) on February 8, 2026.*
