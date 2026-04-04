# K53 authoritative wide Table 2 from K50

## Context

- Orchestrator request: create a new K53 production path for a Table 2 style output.
- Structural gold standard remains manuscript Table 2.
- Population gold standard is no longer manuscript `77/199`, but the authoritative K50 WIDE modeled cohort documented in the K50 receipt/provenance chain.
- Scope must stay isolated: new K53 script and outputs only, with no K23/K50 raw logic changes.

## Inputs

- `prompts/2_12cafofv2.txt`
- `CLAUDE.md`
- `AGENTS.md`
- `R-scripts/K23/K23_TABLE2.V2.3_table2-paper01-replica-published.R`
- `R-scripts/K23/K23_TABLE2.V2.4_table2-paper01-paranoia-check.R`
- `R-scripts/K50/outputs/k50_wide_locomotor_capacity_input_receipt.txt`
- `R-scripts/K50/outputs/k50_wide_locomotor_capacity_modeled_cohort_provenance.txt`
- `/data/data/com.termux/files/home/FOF_LOCAL_DATA/paper_02/analysis/fof_analysis_k50_wide.rds`
- `/data/data/com.termux/files/home/FOF_LOCAL_DATA/paper_02/KAAOS_data_sotullinen.xlsx`

## Outputs

- `R-scripts/K53/K53_TABLE2.V1_table2-authoritative-wide.R`
- `R-scripts/K53/outputs/`
- `manifest/manifest.csv` rows for K53 artifacts

## Definition of Done (DoD)

- New K53 script exists as an independent production path.
- K53 derives authoritative modeled cohort counts from K50 WIDE input, not manuscript anchors.
- K53 writes production artifacts and manifest rows without modifying K23/K50.
- Task note records the final counts, validation commands, and any residual blockers.

## Log

- 2026-04-03 15:10:21 +0300 Task created from orchestrator prompt in `01-ready`.
- 2026-04-03 15:10:21 +0300 Moved `01-ready -> 02-in-progress` and began K53 design review from `CLAUDE.md`, `AGENTS.md`, K23 V2.3/V2.4, and the authoritative K50 receipt/provenance files.
- 2026-04-03 15:10:21 +0300 Ran `fof-preflight`; status PASS before edits.
- 2026-04-03 15:20:00 +0300 Verified authoritative K50 WIDE cohort contract from receipt/provenance: `rows_loaded=535`, modeled sample `N=230`, `FOF=0 n=69`, `FOF=1 n=161`.
- 2026-04-03 15:24:00 +0300 Verified `fof_analysis_k50_wide.rds` contains only authoritative cohort-defining fields plus locomotor capacity columns; identified that individual Table 2 performance measures must be joined from the immutable workbook source.
- 2026-04-03 15:28:00 +0300 Audited `KAAOS_data_sotullinen.xlsx` header structure and confirmed baseline `TK` plus 12-month `2SK` columns exist for SLS, FTSST, HGS, and 10 m walk time.
- 2026-04-03 15:32:00 +0300 Added new script `R-scripts/K53/K53_TABLE2.V1_table2-authoritative-wide.R` as an independent production path. K23 remained unchanged and was used only as a structural model.
- 2026-04-03 15:36:08 +0300 Validated K53 end-to-end with a temporary workbook CSV bridge under `/data/data/com.termux/files/usr/tmp/` to avoid local `readxl` package blockers in the current Termux R runtime. K53 wrote CSV, HTML, model-N audit, provenance receipt, session info, and manifest rows successfully.
- 2026-04-03 15:36:38 +0300 Re-ran `fof-preflight`; status PASS after edits. `git status -sb` shows only intended K53/task/manifest changes.
- 2026-04-03 19:18:32 +0300 Addressed expert PASS-WITH-NOTES follow-up in `R-scripts/K53/K53_TABLE2.V1_table2-authoritative-wide.R` without changing the authoritative cohort contract. Models A/B/C now use manuscript-style follow-up ANCOVA, FOF p-values are extracted with `drop1(..., test = "F")`, HGS female/male rows now report row-specific analytic Ns (`58/146/204` and `10/15/25`), and the brittle literal `69/161/230` hard stop was replaced by validation against K50 provenance.
- 2026-04-03 19:18:32 +0300 Added explicit join QC and outcome availability notes to `k53_table2_authoritative_wide_input_provenance.txt`; current run shows duplicate measure IDs `0`, unmatched modeled rows `0`, and HGS pair-complete count `229`.
- 2026-04-03 19:18:32 +0300 Re-ran K53 end-to-end with `--input=/data/data/com.termux/files/home/FOF_LOCAL_DATA/paper_02/analysis/fof_analysis_k50_wide.rds --raw_csv=/data/data/com.termux/files/usr/tmp/k53_workbook_extract.csv`. Regenerated CSV, HTML, audit, provenance, session info, and manifest rows. Cohort header remains authoritative `69/161/230`; row-level HGS Ns now vary where appropriate. `fof-preflight` PASS.
- 2026-04-03 21:17:32 +0300 Completed forensic sync rerun and build-stamped provenance. Current implementation is aligned end-to-end: `script == csv == html == audit == provenance`, task-log matches the actual K53 implementation, and provenance records `script_sha256=cc9c01affc1dcc8d4a9578bfaf1bee9e565314f6f1e5abaa21480c17262bbc09` for this rerun.

## Blockers

- Current Termux R runtime cannot load `readxl` because the local package stack is incomplete (`cli` missing). The production script still supports direct workbook reading via `readxl`, but this run validated with `--raw_csv=/data/data/com.termux/files/usr/tmp/k53_workbook_extract.csv` generated read-only from the immutable workbook.

## Links

- Prompt packet: `prompts/2_12cafofv2.txt`
