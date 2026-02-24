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

## PR description (copy-paste)
### Summary
This PR adds canonical K24/K25/K26 scripts and reviewer-facing visualization/reporting updates for the Fear-of-Falling pipeline while keeping generated artifacts out of version control. The analysis chain is documented and reproducible from canonical inputs.

### Included (code/docs only)
- `R-scripts/K24/*.R` (including `K24_TABLE2A.V2_*` and `K24_VIS.V1_*`)
- `R-scripts/K25/*.R` (including `K25_RESULTS.V2_*`)
- `R-scripts/K26/*.R` (including `K26_LMM_MOD.V1_*` and `K26_VIS.V1_*`)
- `README.md`
- `manifest/manifest.csv`
- `tasks/01-ready/*.md`
- `tasks/03-review/*.md`

### Explicitly excluded (no outputs committed)
- No `R-scripts/*/outputs/**` files
- No `.png/.pdf` figures
- No `sessionInfo*.txt`, `*provenance*.txt`, `plot_manifest.txt`
- No `qc_*.csv`
- No run logs (`gate_err.log`, `gate_out.log`, etc.)

### Canonical scripts to use
- K24 table pipeline: `R-scripts/K24/K24_TABLE2A.V2_canonical-delta-by-test-fof-frailty.R`
- K24 visuals: `R-scripts/K24/K24_VIS.V1_forestplots_table2A_cat_vs_score.R`
- K25 results text: `R-scripts/K25/K25_RESULTS.V2_table2A-results-text-canonical.R`
- K26 visuals: `R-scripts/K26/K26_VIS.V1_composite-delta-predicted-plots.R`

### Reproducibility (local/home machine)
Run from `Fear-of-Falling/` root:
```bash
Rscript R-scripts/K24/K24_TABLE2A.V2_canonical-delta-by-test-fof-frailty.R \
  --input=R-scripts/K15/outputs/K15_frailty_analysis_data.RData \
  --frailty_mode=both \
  --include_balance=FALSE

Rscript R-scripts/K24/K24_VIS.V1_forestplots_table2A_cat_vs_score.R \
  --input=R-scripts/K24/outputs/K24_TABLE2A/table2A_cat_vs_score_compare_canonical_v2.csv \
  --audit_input=R-scripts/K24/outputs/K24_TABLE2A/table2A_audit_canonical_v2.csv \
  --format=both --make_cat_p=TRUE --qc_strict=FALSE --z_tol=1.96

Rscript R-scripts/K25/K25_RESULTS.V2_table2A-results-text-canonical.R \
  --input=R-scripts/K24/outputs/K24_TABLE2A/table2A_paper_ready_canonical_cat_v2.csv \
  --style=both

Rscript R-scripts/K26/K26_VIS.V1_composite-delta-predicted-plots.R --format=both
```

### Reproducibility (Termux + PRoot Debian)
```bash
cd ~/Python-R-Scripts/Fear-of-Falling
proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin && cd ~/Python-R-Scripts/Fear-of-Falling && /usr/bin/Rscript R-scripts/K24/K24_TABLE2A.V2_canonical-delta-by-test-fof-frailty.R --input R-scripts/K15/outputs/K15_frailty_analysis_data.RData --frailty_mode both --include_balance FALSE'
proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin && cd ~/Python-R-Scripts/Fear-of-Falling && /usr/bin/Rscript R-scripts/K24/K24_VIS.V1_forestplots_table2A_cat_vs_score.R --input R-scripts/K24/outputs/K24_TABLE2A/table2A_cat_vs_score_compare_canonical_v2.csv --audit_input R-scripts/K24/outputs/K24_TABLE2A/table2A_audit_canonical_v2.csv --format both --make_cat_p TRUE --qc_strict FALSE --z_tol 1.96'
proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin && cd ~/Python-R-Scripts/Fear-of-Falling && /usr/bin/Rscript R-scripts/K25/K25_RESULTS.V2_table2A-results-text-canonical.R --input R-scripts/K24/outputs/K24_TABLE2A/table2A_paper_ready_canonical_cat_v2.csv --style both'
proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin && cd ~/Python-R-Scripts/Fear-of-Falling && /usr/bin/Rscript R-scripts/K26/K26_VIS.V1_composite-delta-predicted-plots.R --format both'
```

### QC / provenance checkpoints
- K24 VIS: `R-scripts/K24/outputs/K24_TABLE2A/figures/K24_VIS/plot_manifest.txt`
  - expected: `qc_status=PASS`, `std_method=baseline_sd`, `sd_source=audit`
- K26 VIS: `R-scripts/K26/outputs/K26_VIS/K26_VIS_provenance.txt`
  - expected: `delta_definition=Composite_Z12 - Composite_Z0 (12-month follow-up minus baseline)`
  - expected canonical-source note present (K15/K26 pipeline; no fallback derivation)
- K26 VIS QC: `R-scripts/K26/outputs/K26_VIS/qc_summary.csv`
  - expected: overall `PASS`

### Reviewer signoff checklist (03-review -> 04-done)
- [ ] Run canonical commands (local or Termux/PRoot) and verify successful exits
- [ ] Confirm QC/provenance values at the checkpoints above
- [ ] Confirm outputs are not staged:
  - `git status`
  - `git diff --name-only --cached | grep -E "outputs/|\\.png$|\\.pdf$|qc_|sessionInfo|provenance|plot_manifest" || true`
- [ ] Confirm manifest/task docs updated and consistent with canonical chain
- [ ] Keep tasks in `03-review`; human performs `04-done` move after approval
