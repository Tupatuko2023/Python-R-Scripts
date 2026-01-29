# Build integration map + local-only assembly for paper_02 (multi-source xlsx+csv) and enable QC

## Orchestration packet (qfta2)
Agent: qfta2

Default gate sequence (reminder): docs → tests → sample QC → inventory manifest → assembly → QC → report → knowledge package

Canonical commands (CI-safe):
- python -m unittest discover -s Quantify-FOF-Utilization-Costs/tests
- python Quantify-FOF-Utilization-Costs/scripts/30_qc_summary.py --use-sample
- python Quantify-FOF-Utilization-Costs/scripts/00_inventory_manifest.py --scan paper_02
- python -m unittest Quantify-FOF-Utilization-Costs.tests.test_end_to_end_smoke
- python Quantify-FOF-Utilization-Costs/scripts/50_build_report.py
- python Quantify-FOF-Utilization-Costs/scripts/40_build_knowledge_package.py

Option B red lines:
- No absolute paths anywhere.
- Logs must say only “--input provided locally”.
- No raw values in logs or artifacts.
- Outputs only under outputs/ (gitignored).
- Manifests are metadata-only.
- Never commit outputs/ or docs/derived_text/.

## Context
paper_02 sisältää useita lähteitä (xlsx + csv). Nykyinen QC-skripti `Quantify-FOF-Utilization-Costs/scripts/30_qc_summary.py` olettaa yhden tiedoston ja kaatuu, jos sille annetaan hakemisto tai jos data vaatii yhdistämistä useasta taulusta.

Tarve: yhdistää useita datasettejä (mm. käynnit, osastojaksot, diagnoosit, verrokit, mahdolliset kustannus/hinnasto- tai KAAOS/Lifecare-lähteet). Lisäksi KAAOS-exceleissä otsikkorivi ei ole ensimmäisellä rivillä vaan rivillä 2.

Option B: absoluuttisia polkuja ei saa kirjoittua mihinkään output-artefaktiin eikä task-lokiin. Kaikki ajo tehdään paikallisesti, ja lokiin kirjataan vain “--input provided locally” ja success/failure sekä lyhyt yhteenveto ilman polkuja.

## Inputs (local only; do not paste paths)
Data source inventory (observed):
- `Tutkimusaineisto_pkl_kaynnit_2010_2019.csv` (pipe-separated; header present)
- `Tutkimusaineisto_pkl-käynnit_2010_2019.xlsx` (Taul1; header present)
- `Tutkimusaineisto_osastojaksot_2010_2019.xlsx` (Sheet1; header present)
- `Tutkimusaineisto_osastojakso_diagnoosit (1).xlsx` (Sheet1; header present)
- `Lifecare potilasaineisto.xlsx` (Taul1; header present)
- `Verrokit.XLSX` (multiple sheets)
- `verrokitjatutkimushenkilöt.xlsx` (Taul1)
- `aineisto_U1662_a.xlsx` (KUOLEMANSYYT_U1662_A)
- `sotut.xlsx` (Taul2 looks meaningful)
- `KAAOS_data*.xlsx` (Taul1/ Taul2; header row is 2, not 1)

KAAOS header detection result:
- All KAAOS files: FIRST_TEXTY_ROW = 2

Known corrupted copies (ignore these):
- `Lifecare potilasaineisto – kopio.xlsx` -> BadZipFile
- `verrokitjatutkimushenkilöt – kopio.xlsx` -> BadZipFile

## Objective
1) Create an integration map for paper_02:
   - list each source table, its role (events, diagnoses, procedures, cohort, linkage, cost/price),
   - identify join keys and any temporal join rules (dates, validity ranges),
   - describe minimal assembly outputs needed for downstream analysis.

2) Implement a local-only assembly step that produces an analysis-ready dataset (or a small set of normalized outputs) under gitignored outputs, without ever writing absolute paths.

3) Update QC so it can be executed deterministically for:
   - each source table (basic shape, missingness, key uniqueness),
   - and the assembled dataset (join coverage, duplicates, date sanity).
   QC must fail if any absolute path-like strings appear in QC outputs.

## Target files
- `Quantify-FOF-Utilization-Costs/scripts/30_qc_summary.py`
- `Quantify-FOF-Utilization-Costs/scripts/qc_no_abs_paths_check.py` (create if missing; or extend)
- NEW: `Quantify-FOF-Utilization-Costs/scripts/20_assemble_paper02.py` (local-only assembly runner)
- Task file itself (log only)

## Plan
1) Read-only discovery
   - Confirm which files are canonical sources (prefer non-copy originals).
   - Confirm KAAOS header row handling: use row 2 as header (skip first row).

2) Integration map (write to outputs/reports, gitignored)
   - Produce a short markdown artifact describing:
     - sources, columns, keys, and intended joins,
     - which dataset is the “primary events” table for utilization and costs,
     - what the assembled dataset will contain.

3) Assembly implementation (local-only)
   - Implement `20_assemble_paper02.py`:
     - Accept `--input-root` (directory) and/or a manifest file name (no absolute paths in logs).
     - Read xlsx via openpyxl or pandas.
     - Read csv with correct delimiter (the CSV appears pipe-separated).
     - Apply transformations needed to align keys and date formats.
     - Write assembled outputs to `Quantify-FOF-Utilization-Costs/outputs/` in gitignored location.
     - Never write absolute paths into outputs; store only relative identifiers or placeholders.

4) QC update
   - Update `30_qc_summary.py` so it can run on:
     - a single file (csv/xlsx),
     - or a manifest describing multiple sources,
     - or the assembled output.
   - Add/extend `qc_no_abs_paths_check.py`:
     - scan QC outputs for path-like patterns (Termux/Linux/Windows),
     - fail with generic message without printing matches.

5) Run locally (Option B)
   - Set input root locally (provided locally, not logged).
   - Run assembly, then QC.
   - Record only success/failure and high-level counts, no paths, no command lines containing paths.

6) After work
   - Move this task from `tasks/02-in-progress/` to `tasks/03-review/`.
   - Never move to `tasks/04-done/` (human decides).

## Acceptance criteria
- Integration map exists (gitignored artifact) and is consistent with observed headers:
  - PKL events include Pdgo/Sdg* and Tp* fields
  - Osastojaksot joined to osastojakso_diagnoosit by person + osastojakso start/end
  - KAAOS header row handled as row 2
  - Corrupted “copy” xlsx files ignored
- Assembly script produces assembled output(s) in gitignored outputs
- QC runs against sources and assembled output with exit code 0 OR fails with safe generic reason
- No absolute paths are written to any QC or assembly output artifacts
- Task log contains only:
  - “--input provided locally”
  - QC_SUCCESS or QC_FAILURE
  - 1 to 4 bullets summarizing what was enforced (redaction, header row, checker)

## Log
- 2026-01-28 CREATED: Multi-source paper_02 requires integration map + assembly before QC.
- 2026-01-28: --input provided locally
- 2026-01-28: QC_SUCCESS
  - abs-path checker enforced on QC/report/knowledge artifacts
  - KAAOS header row=2 handled
  - corrupted kopio XLSX ignored
  - XLSX missing dependency fails closed
  - shared IO utils extracted; integration map scanned; manifest path normalization handles Windows separators
## Notes / guardrails (non-negotiable)
- Do not paste or write absolute paths anywhere (chat, tasks, outputs).
- Do not write any person identifiers or raw data values into logs or reports.
- Output artifacts must be gitignored and safe for Option B.
- If a required dependency is missing in the runtime, install locally but do not commit environment changes.
