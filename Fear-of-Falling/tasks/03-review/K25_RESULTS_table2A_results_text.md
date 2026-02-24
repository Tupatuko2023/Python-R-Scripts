# K25_RESULTS table2A results text from csv

## Context
Generate manuscript-style Results text deterministically from K24 paper-ready Table 2A CSV (no new statistical computation).

## Inputs
- `R-scripts/K24/outputs/K24_TABLE2A/table2A_paper_ready_v1_1.csv` (default)
- CLI override: `--input`

## Outputs
- `R-scripts/K25/outputs/K25_RESULTS/results_table2A_from_K24_v1_1.md`
- `R-scripts/K25/outputs/K25_RESULTS/results_table2A_from_K24_v1_1.txt`
- `R-scripts/K25/outputs/K25_RESULTS/sessionInfo.txt`
- Manifest rows in `manifest/manifest.csv`

## Definition of Done (DoD)
- New K25 script added and reads K24 paper-ready CSV.
- Results text includes all 5 outcomes with FOF beta/CI and conservative interpretation.
- Text includes Model_N footnote, multiplicity caution, and HGS Men small-N note.
- Artifacts saved under K25 outputs and logged to manifest.

## Log
- 2026-02-24 00:00:00 Task created in 01-ready.
- 2026-02-24 00:01:00 Moved 01-ready -> 02-in-progress.
- 2026-02-24 10:25:00 Ran K25 in proot Debian with PATH override:
  - `/usr/bin/Rscript R-scripts/K25/K25_RESULTS.V1_table2A-results-text-from-csv.R --input R-scripts/K24/outputs/K24_TABLE2A/table2A_paper_ready_v1_1.csv`
- 2026-02-24 10:26:00 Artifacts created:
  - `R-scripts/K25/outputs/K25_RESULTS/results_table2A_from_K24_v1_1.md`
  - `R-scripts/K25/outputs/K25_RESULTS/results_table2A_from_K24_v1_1.txt`
  - `R-scripts/K25/outputs/K25_RESULTS/sessionInfo.txt`
- 2026-02-24 10:26:00 Manifest appended with 3 rows for `K25_RESULTS`:
  - `results_table2A_from_K24_v1_1_md` (doc_md)
  - `results_table2A_from_K24_v1_1_txt` (text)
  - `sessionInfo` (sessioninfo)
- 2026-02-24 10:26:00 Crosscheck PASS:
  - 5 outcomes present in generated text: MWS, FTSST, SLS, HGS (Women), HGS (Men)
  - Values match source CSV (`FOF_Beta_CI`, `P_FOF`, `P_Frailty_Overall`, `N_without/N_with`, `Model_N`)
  - Includes fixed Model_N note and multiplicity caution
  - Includes HGS (Men) small-N exploratory caveat

## Blockers
- None.

## Links
- `docs/ANALYSIS_PLAN.md`
- `R-scripts/K24/outputs/K24_TABLE2A/table2A_paper_ready_v1_1.csv`

## Status
- Ready for human review in `03-review`.

## V1.1 narrative refinement
- Purpose: improve wording to journal-style narrative while keeping table-linked numbers identical.
- New script: `R-scripts/K25/K25_RESULTS.V1.1_table2A-results-text-paper-ready.R`
- New CLI flag: `--style` (`narrative` default, `list` optional fallback).
- Run command:
  - `/usr/bin/Rscript R-scripts/K25/K25_RESULTS.V1.1_table2A-results-text-paper-ready.R --input R-scripts/K24/outputs/K24_TABLE2A/table2A_paper_ready_v1_1.csv --style narrative`
- New artifacts:
  - `R-scripts/K25/outputs/K25_RESULTS/results_table2A_from_K24_v1_1_narrative.md`
  - `R-scripts/K25/outputs/K25_RESULTS/results_table2A_from_K24_v1_1_narrative.txt`
  - `R-scripts/K25/outputs/K25_RESULTS/sessionInfo_v1_1.txt`
- Manifest rows appended (unique keys):
  - `results_table2A_from_K24_v1_1_narrative_md` (doc_md)
  - `results_table2A_from_K24_v1_1_narrative_txt` (text)
  - `sessionInfo_v1_1` (sessioninfo)
- Crosscheck PASS:
  - Narrative includes all 5 outcomes (MWS, FTSST, SLS, HGS Women, HGS Men).
  - FOF beta/CI, `P_FOF`, `P_Frailty_Overall`, `Model_N`, and group Ns match K24 paper-ready CSV values.
  - HGS Men small-N caveat and multiplicity caution retained.
  - No new analysis performed; wording/style only.

## Frailty provenance note
- K25 does not derive or model frailty variables; both V1 and V1.1 read the precomputed K24 paper-ready CSV (`R-scripts/K24/outputs/K24_TABLE2A/table2A_paper_ready_v1_1.csv` by default).
- Required input columns include `P_Frailty_Overall`; K25 only transforms table values into text.
- Provenance therefore inherits from the K24 run that produced the source CSV; see:
  - `R-scripts/K24/outputs/K24_TABLE2A/k24_k25_frailty_provenance_check.csv`
  - `R-scripts/K24/outputs/K24_TABLE2A/k24_k25_frailty_provenance_check.txt`

## V2 canonical text generation - DONE
- New script: `R-scripts/K25/K25_RESULTS.V2_table2A-results-text-canonical.R`.
- Canonical input used:
  - `R-scripts/K24/outputs/K24_TABLE2A/table2A_paper_ready_canonical_cat_v2.csv`
- Command executed:
  - `/usr/bin/Rscript R-scripts/K25/K25_RESULTS.V2_table2A-results-text-canonical.R --input R-scripts/K24/outputs/K24_TABLE2A/table2A_paper_ready_canonical_cat_v2.csv --style both`
- Produced outputs:
  - `results_table2A_from_K24_canonical_v2.{md,txt}`
  - `results_table2A_from_K24_canonical_v2_narrative.{md,txt}`
  - `sessionInfo_v2.txt`
- Crosscheck PASS:
  - V2 list and narrative numbers are read directly from canonical K24 V2 CSV.
  - Text contains provenance sentence: `Frailty variables were derived using the K15 canonical pipeline (K15_RData input; no fallback derivation).`
- Methodological status: V1/V1.1 remain historical list/narrative outputs from pre-canonical table versions; V2 is the primary canonical chain.

## 04-done signoff checklist (K25 V2 canonical)
1. K24 provenance anchor PASS:
   `R-scripts/K24/outputs/K24_TABLE2A/K24_frailty_provenance_v2.txt` shows
   `frailty_*_source=K15_RData` and `fallback_used=FALSE`.
2. K25 V2 input path is canonical K24 CSV:
   `R-scripts/K24/outputs/K24_TABLE2A/table2A_paper_ready_canonical_cat_v2.csv`.
3. K25 V2 outputs exist:
   `results_table2A_from_K24_canonical_v2.{md,txt}`,
   `results_table2A_from_K24_canonical_v2_narrative.{md,txt}`,
   `sessionInfo_v2.txt`.
4. Provenance sentence present in narrative output.
5. Spot-check PASS (one row, recommended `MWS`):
   narrative `FOF_Beta_CI`, `P_FOF`, `Model_N`, and group Ns match K24 canonical CSV.
6. Manifest uniqueness PASS:
   one row per K25 V2 label, no duplicates.
7. Optional rerun smoke PASS:
   K25 V2 narrative re-run exits successfully in proot clean env.

### Commands
`[TERMUX]`
```bash
cd ~/Python-R-Scripts/Fear-of-Falling
sed -n '1,120p' R-scripts/K24/outputs/K24_TABLE2A/K24_frailty_provenance_v2.txt
ls -la R-scripts/K25/outputs/K25_RESULTS | grep -E "canonical|v2|sessionInfo"
sed -n '1,140p' R-scripts/K25/outputs/K25_RESULTS/results_table2A_from_K24_canonical_v2_narrative.md
head -n 8 R-scripts/K24/outputs/K24_TABLE2A/table2A_paper_ready_canonical_cat_v2.csv
grep "K25_RESULTS" manifest/manifest.csv | tail -80
```

`[PROOT:DEBIAN]`
```bash
proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin && cd ~/Python-R-Scripts/Fear-of-Falling && /usr/bin/Rscript R-scripts/K25/K25_RESULTS.V2_table2A-results-text-canonical.R --input R-scripts/K24/outputs/K24_TABLE2A/table2A_paper_ready_canonical_cat_v2.csv --style narrative'
```

### PASS decision rule
- PASS: checks 1–7 succeed.
- HOLD: missing provenance sentence, CSV↔text mismatch, missing output, or duplicate manifest labels.
- Task movement to `04-done` remains human-only after signoff.
