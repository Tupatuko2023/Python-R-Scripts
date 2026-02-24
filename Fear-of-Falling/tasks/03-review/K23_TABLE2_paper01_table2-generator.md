# K23_TABLE2 paper_01 table2 generator

## Context
Lisätään Fear-of-Falling-aliprojektiin uusi Table 2 -generaattori (paper_01) K23-skriptinä repo-konventioiden mukaan. Toteutus pitää analyysilogiikan vakaana ja lisää vain CLI/polku/output/manifest/dokumentaatio-parannukset.

## Inputs
- `data/external/KaatumisenPelko.csv` (default)
- Mahdollinen override: `--input <path>`
- Mahdollinen varmap override: `--varmap_json <path>`

## Outputs
- `R-scripts/K23/outputs/K23_TABLE2/table2_paper01.html`
- `R-scripts/K23/outputs/K23_TABLE2/table2_paper01.csv`
- `R-scripts/K23/outputs/K23_TABLE2/sessionInfo.txt`
- Manifest-rivit: `manifest/manifest.csv`

## Definition of Done (DoD)
- Uusi skripti `R-scripts/K23/K23_TABLE2.V1_table2-paper01.R` toimii repo-rootista yhdellä komennolla.
- Tuottaa vähintään HTML + konsoliprintin (ja CSV suosituksena).
- Kirjaa kaikki artefaktit manifestiin (1 rivi / artefakti).
- README sisältää Paper_01 / Table 2 -ajamisohjeen + sanity check -maininnan.
- Ei raw data -muutoksia eikä tarpeettomia refaktoreita.

## Log
- 2026-02-24 00:00:00 Task created in backlog.
- 2026-02-24 09:03:37 Moved backlog -> 01-ready -> 02-in-progress.
- 2026-02-24 09:04:00 Added `R-scripts/K23/K23_TABLE2.V1_table2-paper01.R` with standard intro, CLI flags (`--input`, `--output_html`, `--output_csv`, `--varmap_json`), gt HTML + CSV output, console print, and manifest logging hooks.
- 2026-02-24 09:04:30 Updated `README.md` with section `Paper_01 / Table 2 (K23_TABLE2)` including run commands, inputs, outputs, varmap note, and sanity-check (77/199).
- 2026-02-24 09:05:00 Smoke run attempt failed in this environment due missing R packages (`here`) and broken proot runtime (`bad ELF magic`), so artifact generation + manifest append could not be validated here.
- 2026-02-24 09:05:20 `bash scripts/fof-preflight.sh` => PASS.
- 2026-02-24 09:05:40 `../tools/run-gates.sh --mode pre-push --smoke` => PASS (with renv warnings in current environment).
- 2026-02-24 09:20:00 Environment triage: `bad ELF magic` root-cause was PATH resolving Termux binaries (`/data/data/com.termux/files/usr/bin/uname`, `rm`) inside proot; fixed for run commands by forcing PATH to Debian system paths.
- 2026-02-24 09:22:00 `renv::restore(prompt=FALSE)` succeeded in proot Debian with PATH override; library synchronized (system package warnings shown by renv).
- 2026-02-24 09:24:56 First K23 run reached model/CSV stage and failed at HTML save because `gt` was missing; this produced one partial CSV manifest row before failure.
- 2026-02-24 09:27:00 Installed missing system dependency in proot: `apt-get install -y libnode-dev` (required by R package V8 -> gt).
- 2026-02-24 09:28:00 Installed R package `gt` in renv and reran script successfully.
- 2026-02-24 09:29:00 Successful outputs confirmed in `R-scripts/K23/outputs/K23_TABLE2/`: `table2_paper01.html`, `table2_paper01.csv`, `sessionInfo.txt`.
- 2026-02-24 09:29:10 Manifest now contains K23_TABLE2 rows for CSV, HTML, and sessionInfo; includes one earlier CSV row from the failed pre-gt run.
- 2026-02-24 09:30-09:38 Manifest dedupe hygiene completed for K23_TABLE2 key duplication (see section below).
- 2026-02-24 09:34-09:35 Table-to-text crosscheck completed for `table2_paper01.csv` (see section below).

## Blockers
- None currently blocking K23 first successful run.

## Manifest Dedupe Done

- Scope: only K23_TABLE2 duplicate key cleanup.
- Dedupe key: `(script,label,kind,path)` keeping the newest `timestamp`.
- Target key deduped:
  - `K23_TABLE2 | table2_paper01_csv | table_csv | R-scripts/K23/outputs/K23_TABLE2/table2_paper01.csv`
- Row counts observed during dedupe run:
  - before: `1403`
  - after: `1402`
  - removed: `1` (older failed-run CSV row)
- Final K23_TABLE2 manifest state: exactly 1 row per produced artifact (CSV, HTML, sessionInfo).

## Table-to-Text Crosscheck Done

- Source checked: `R-scripts/K23/outputs/K23_TABLE2/table2_paper01.csv`.
- Manuscript anchor available in repo docs: raw group counts `Without FOF = 77`, `With FOF = 199` (README Table 2 section).
- Crosscheck findings:
  - Outcome rows present: `Composite`, `HGS`, `HGS (female)`, `HGS (male)`, `MWS`, `FTSST`, `SLS` -> PASS.
  - Raw N anchor check from dataset: `77/199` -> PASS.
  - Table row Ns vary by outcome (`N_without` 10..70, `N_with` 11..181) -> expected due complete-case + covariate-complete ANCOVA datasets.
  - P-value format (`P_Model_A/B/C`) numeric or `<0.001` -> PASS.
- Note: full manuscript cell-by-cell Table 2 was not found as a separate file in this repo snapshot; crosscheck was done against available manuscript anchors and table structure/format sanity.

## Links
- `R-scripts/K23/K23_TABLE2.V1_table2-paper01.R`
- `README.md`
- `manifest/manifest.csv`

## V2 Alignment Check

- V2 script added: `R-scripts/K23/K23_TABLE2.V2_table2-paper01-align-manuscript.R` (V1 left unchanged).
- FTSST sign handling: PASS.
  - V2 CSV `FTSST` baseline/follow-up cells are positive raw seconds:
    - Without FOF baseline/follow-up: `16.22` / `15.33`
    - With FOF baseline/follow-up: `18.21` / `17.44`
  - Delta remains `follow-up - baseline` and is directionally manuscript-aligned (negative values above).
- ANCOVA p-model alignment: PASS.
  - V2 uses follow-up DV models:
    - A: `followup ~ FOF_status_f`
    - B: `followup ~ FOF_status_f + baseline`
    - C: `followup ~ FOF_status_f + baseline + Sex_f + age + BMI` (Sex_f omitted only if 1 level)
  - No V1 extra covariates (e.g., MOI/diagnosis/psych) in V2 model C.
- N anchor (manuscript mode): DIFF documented.
  - V2 fixed-cohort counts are constant on non-sex-stratified rows: `N_without=67`, `N_with=155`, `N_total=222`.
  - This does not match manuscript anchor `77/199`; likely cause is stricter complete-case cohort definition
    (all Table 2 outcomes + model C covariates) and/or dataset-version differences.
- Sex-coding robustness: PASS.
  - Robust mapping supports numeric/text codes (`0/2/f/female/woman/nainen -> female`,
    `1/m/male/man/mies -> male`), others -> `NA` with warning.
  - HGS stratified rows produced successfully (`HGS (female)`, `HGS (male)`), so strata did not collapse.
- V2 artifacts created:
  - `R-scripts/K23/outputs/K23_TABLE2/table2_paper01_v2_align.csv`
  - `R-scripts/K23/outputs/K23_TABLE2/table2_paper01_v2_align.html`
  - `R-scripts/K23/outputs/K23_TABLE2/sessionInfo_v2.txt`
- Manifest v2 labels present once each (no v2 dedupe needed):
  - `table2_paper01_v2_csv`
  - `table2_paper01_v2_html`
  - `sessionInfo_v2`

Ready for human 03-review decision; keep in `tasks/03-review`.

## Cohort attrition explanation (K14 vs K23)

- Added QC script:
  - `R-scripts/K23/K23_TABLE2.V2.1_table2-paper01-cohort-attrition-qc.R`
- Added QC artifacts:
  - `R-scripts/K23/outputs/K23_TABLE2/table2_paper01_cohort_attrition_qc.csv`
  - `R-scripts/K23/outputs/K23_TABLE2/table2_paper01_missingness_matrix_by_fof.csv`
- Added manifest labels:
  - `table2_cohort_attrition_qc_csv`
  - `table2_missingness_matrix_qc_csv`

Deterministic step breakdown (from `table2_paper01_cohort_attrition_qc.csv`):
- `Step0_raw` (non-missing FOF): `77 / 199` (total 276)
- `Step1_covariates` (age+sex_mapped+BMI complete): `75 / 191` (drop `-2 / -8`)
- `Step3_all_outcomes` (Step1 + all outcome baseline+followup complete): `67 / 155` (drop vs Step1 `-8 / -36`)
- This exactly matches K23 V2 manuscript-mode fixed cohort used in non-sex-stratified Table 2 rows.

Largest missingness drivers (from `table2_paper01_missingness_matrix_by_fof.csv`):
- `MWS0_missing`: `3 / 21`
- `MWS2_missing`: `4 / 12`
- `FTSST2_missing`: `5 / 10`
- `SLS0_missing`: `2 / 8`
- `BMI missing`: `2 / 8`

Conclusion:
- K23 Table 2 V2 manuscript-mode shrinks because it uses intersection logic:
  covariates complete AND all four outcomes available at baseline+12m for the same participants.
- K14 Table 1 is baseline-oriented and does not require 12-month outcome availability in this way,
  so it does not undergo the same follow-up intersection attrition.

## V2.2 Manuscript mismatch diagnostics

- Added debug script:
  - `R-scripts/K23/K23_TABLE2.V2.2_table2-paper01-model-population-debug.R`
- Added debug artifacts:
  - `R-scripts/K23/outputs/K23_TABLE2/table2_paper01_v2_2_debug_models.csv`
  - `R-scripts/K23/outputs/K23_TABLE2/table2_paper01_v2_2_debug_summary.txt`
- Added manifest labels:
  - `table2_paper01_v2_2_debug_models_csv`
  - `table2_paper01_v2_2_debug_summary_txt`

Deterministic findings from V2.2:
- Grid computed for all outcomes/strata across:
  - DV modes: `followup`, `delta`
  - Populations: `raw`, `covariate_complete`, `all_outcomes_intersection`, `per_outcome_cc`
  - Models: A/B/C
- Population anchors confirmed in the same run:
  - `raw = 77/199`
  - `all_outcomes_intersection = 67/155`
- Manuscript p-reference availability is partial in repo snapshot:
  - only explicit anchor used in debug comparison: `MWS crude p_A = 0.220`
  - other manuscript p-cells not available as a verified source table file.
- Best match vs available anchor:
  - `MWS`, `DV=delta`, `population=raw`, `p_A=0.2197` (closest to 0.220)
  - follow-up ANCOVA for MWS is materially smaller (e.g. `p_A=0.0893` in raw mode).

Conclusion from V2.2:
- Available evidence favors **delta-model** p-values over follow-up ANCOVA for at least MWS crude.
- With only one verified manuscript anchor, full-table replication method cannot be proven uniquely yet.
- If full manuscript p-value grid is provided, the same V2.2 script can deterministically select the best matching
  model+population combination or show no-match (implying dataset/extraction mismatch).

## V2.3 Published replica

- Added script:
  - `R-scripts/K23/K23_TABLE2.V2.3_table2-paper01-replica-published.R`
- Added artifacts:
  - `R-scripts/K23/outputs/K23_TABLE2/table2_paper01_v2_3_replica.csv`
  - `R-scripts/K23/outputs/K23_TABLE2/table2_paper01_v2_3_replica.html`
  - `R-scripts/K23/outputs/K23_TABLE2/table2_paper01_v2_3_modelN_audit.csv`
  - `R-scripts/K23/outputs/K23_TABLE2/sessionInfo_v2_3.txt`
- Added manifest labels:
  - `table2_paper01_v2_3_csv`
  - `table2_paper01_v2_3_html`
  - `table2_paper01_v2_3_modelN_audit_csv`
  - `sessionInfo_v2_3`

Crosscheck:
- Table 2 CSV now reports fixed raw-population anchor `N_without=77`, `N_with=199` on all rows (published style).
- P-values are from delta models (A/B/C) in raw population.
- MWS crude p-value matches manuscript anchor: `P_Model_A = 0.220`.
- FTSST baseline/follow-up are positive raw seconds (`16.26 -> 15.22` without FOF; `18.87 -> 17.32` with FOF).

Transparency/QC:
- `table2_paper01_v2_3_modelN_audit.csv` records actual model-wise N after na.omit (A/B/C per outcome/strata).
- Example from audit:
  - MWS model A/B use `nobs=247` (`72/175`), while model C uses `nobs=238` (`70/168`).
  - This documents why published fixed N header and model-estimation N are not identical.

## V2.4 Paranoia-check (replica vs manuscript)

- Added script:
  - `R-scripts/K23/K23_TABLE2.V2.4_table2-paper01-paranoia-check.R`
- Added artifacts:
  - `R-scripts/K23/outputs/K23_TABLE2/table2_paper01_v2_3_paranoia_diff.csv`
  - `R-scripts/K23/outputs/K23_TABLE2/table2_paper01_v2_3_paranoia_summary.txt`
- Added manifest labels:
  - `table2_paper01_v2_3_paranoia_diff_csv`
  - `table2_paper01_v2_3_paranoia_summary_txt`

Run result:
- Input: `table2_paper01_v2_3_replica.csv`
- Compared outcomes: `MWS`, `FTSST`, `SLS`, `HGS (female)`, `HGS (male)`
- Compared fields per outcome: baseline mean/sd, delta mean/lcl/ucl, `p_A/p_B/p_C`, `N_without/N_with`
- `max_abs_diff = 0.000000`
- Tolerance verdict:
  - strict (`<= 0.005`): PASS
  - relaxed (`<= 0.01`): PASS
- Parsing warnings: `0`

Largest differences:
- All top differences are `0.000000` in this run (no non-zero deviations detected).
