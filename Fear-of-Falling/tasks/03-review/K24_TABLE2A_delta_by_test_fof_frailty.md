# K24_TABLE2A delta-by-test with joint FOF + frailty model

## Context
Implement K24 Table 2A analysis per docs/ANALYSIS_PLAN.md canonical variables: `FOF_status`, `frailty_cat_3` / `frailty_score_3`, `tasapainovaikeus`, `age`, `sex`, `BMI`.

## Inputs
- `data/external/KaatumisenPelko.csv` (default)
- CLI override: `--input`

## Outputs
- `R-scripts/K24/outputs/K24_TABLE2A/table2A_delta_by_test_with_frailty.html`
- `R-scripts/K24/outputs/K24_TABLE2A/table2A_delta_by_test_with_frailty.csv`
- `R-scripts/K24/outputs/K24_TABLE2A/sessionInfo.txt`
- Manifest rows in `manifest/manifest.csv`

## Definition of Done (DoD)
- New script added at `R-scripts/K24/K24_TABLE2A.V1_delta-by-test-fof-frailty.R`.
- Delta models include FOF + frailty in same model with baseline + covariates.
- HGS women/men strata included and sex dropped within strata models.
- Artifacts saved under K24 output discipline and logged to manifest.
- README has short K24 run section.
- Smoke checks pass (`fof-preflight`, run-gates, script run).

## Log
- 2026-02-24 00:00:00 Task created in 01-ready.
- 2026-02-24 00:02:00 Moved 01-ready -> 02-in-progress.
- 2026-02-24 00:05:00 Added `R-scripts/K24/K24_TABLE2A.V1_delta-by-test-fof-frailty.R` with canonical mapping block, CLI (`--input --output_html --output_csv --frailty_mode --include_balance --balance_var`), delta-per-test models with joint FOF+frailty effects, HGS sex strata, and Model_N output.
- 2026-02-24 00:06:00 Added README section `Table 2A / K24_TABLE2A (FOF + Frailty)` with canonical variable note, run command, and output paths.
- 2026-02-24 00:08:00 `bash scripts/fof-preflight.sh` => PASS.
- 2026-02-24 00:08:30 `bash ../tools/run-gates.sh --mode pre-push --smoke` => PASS.
- 2026-02-24 00:10:00 Proot run succeeded for primary mode (`--frailty_mode cat --include_balance FALSE`) and produced K24 outputs.
- 2026-02-24 00:11:00 Manifest K24 duplicate rows from reruns deduped safely for K24 keys only (keep latest per `script,label,kind,path`).
- 2026-02-24 00:12:00 K24 final manifest state: exactly 3 rows (CSV, HTML, sessionInfo).
- 2026-02-24 00:15:00 Added `R-scripts/K24/K24_TABLE2A.V1.1_paper-ready-delta-by-test-fof-frailty.R` as paper-ready presentation version (no model logic changes).
- 2026-02-24 00:16:00 V1.1 run succeeded in proot (`--frailty_mode cat --include_balance FALSE`) and produced paper/audit/session outputs + manifest rows.

## Blockers
- None.

## Links
- `docs/ANALYSIS_PLAN.md`
- `R-scripts/K24/K24_TABLE2A.V1_delta-by-test-fof-frailty.R`
- `R-scripts/K24/outputs/K24_TABLE2A/table2A_delta_by_test_with_frailty.csv`
- `R-scripts/K24/outputs/K24_TABLE2A/table2A_delta_by_test_with_frailty.html`
- `R-scripts/K24/outputs/K24_TABLE2A/sessionInfo.txt`
- `manifest/manifest.csv`

## V1.1 paper-ready adjustments

- New file:
  - `R-scripts/K24/K24_TABLE2A.V1.1_paper-ready-delta-by-test-fof-frailty.R`
- Paper output (`table2A_paper_ready_v1_1.csv/.html`):
  - pooled HGS row removed
  - only `MWS`, `FTSST`, `SLS`, `HGS (Women)`, `HGS (Men)` remain
  - `N_without` / `N_with` columns included
  - baseline/delta cells include `N=` prefix for visibility
  - `Frailty_Contrasts` omitted
  - `Model_N` retained
- Audit output (`table2A_audit_v1_1.csv`):
  - retains pooled `HGS` row
  - retains `Frailty_Contrasts`
  - retains `N_without` / `N_with` and `Model_N`
- Crosscheck:
  - paper CSV has no `Outcome == "HGS"` pooled row
  - paper CSV includes visible N per group
  - audit CSV preserves full traceability fields

## V1.2 frailty continuous sensitivity (per +1)

- New script:
  - `R-scripts/K24/K24_TABLE2A.V1.2_paper-ready-delta-by-test-fof-frailty-score.R`
- Model spec:
  - `delta ~ FOF_status + frailty_score_3 + baseline + age + sex + BMI (+ optional tasapainovaikeus)`
  - HGS Women/Men strata reported separately; `sex` removed inside strata.
- Run:
  - `/usr/bin/Rscript R-scripts/K24/K24_TABLE2A.V1.2_paper-ready-delta-by-test-fof-frailty-score.R --input data/external/KaatumisenPelko.csv --include_balance FALSE`
- New artifacts:
  - `R-scripts/K24/outputs/K24_TABLE2A/table2A_paper_ready_score_v1_2.html`
  - `R-scripts/K24/outputs/K24_TABLE2A/table2A_paper_ready_score_v1_2.csv`
  - `R-scripts/K24/outputs/K24_TABLE2A/table2A_audit_score_v1_2.csv`
  - `R-scripts/K24/outputs/K24_TABLE2A/table2A_cat_vs_score_compare_v1_2.csv`
  - `R-scripts/K24/outputs/K24_TABLE2A/sessionInfo_v1_2.txt`
- Manifest rows appended (unique):
  - `table2A_paper_ready_score_v1_2_csv`
  - `table2A_audit_score_v1_2_csv`
  - `table2A_cat_vs_score_compare_v1_2_csv`
  - `table2A_paper_ready_score_v1_2_html`
  - `sessionInfo_v1_2`
- QC highlights:
  - `frailty_score_3` observed range is `0..2` (no all-NA); distribution reported in compare CSV (`Frailty_score_dist_all`, `Frailty_score_dist_model`).
  - HGS Men remains small-N (`Model_N=24`; score distribution `0=17;1=6;2=1`).
  - Paper-ready score table keeps same presentation structure as V1.1 (rows: MWS, FTSST, SLS, HGS Women, HGS Men; includes `N_without/N_with` and `Model_N`).
  - Compare CSV provides side-by-side `AIC_cat` vs `AIC_score`, frailty cat contrasts, frailty score effect, and deterministic `Agreement_Flag`.

## Frailty provenance (K24/K25 check)
- Provenance artifacts:
  - `R-scripts/K24/outputs/K24_TABLE2A/k24_k25_frailty_provenance_check.csv`
  - `R-scripts/K24/outputs/K24_TABLE2A/k24_k25_frailty_provenance_check.txt`
- Deterministic evidence: raw input header used in recorded K24 runs does not contain `frailty_cat_3` / `frailty_score_3`, while K24 V1/V1.1/V1.2 code contains deterministic morbidity fallback logic.
- Conclusion for historical K24 runs: `fallback (derived from morbidity)`; this is evidenced as `TRUE` in provenance report (trigger conditions satisfied).
- Compare/audit outputs remain consistent with cat/score modeling, but do not themselves encode a `frailty_source` column; source inference is code+input driven.

## V2 canonical rerun (K15_RData) - DONE
- New script: `R-scripts/K24/K24_TABLE2A.V2_canonical-delta-by-test-fof-frailty.R` (canonical-only loader, no fallback derivation).
- Canonical run used: `--input R-scripts/K15/outputs/K15_frailty_analysis_data.RData`.
- V2 outputs generated and manifest-appended:
  - `table2A_paper_ready_canonical_cat_v2.{csv,html}`
  - `table2A_paper_ready_canonical_score_v2.{csv,html}`
  - `table2A_audit_canonical_v2.csv`
  - `table2A_cat_vs_score_compare_canonical_v2.csv`
  - `K24_frailty_provenance_v2.txt`
  - `sessionInfo_v2.txt`
- Provenance gate PASS (`R-scripts/K24/outputs/K24_TABLE2A/K24_frailty_provenance_v2.txt`):
  - `frailty_cat_source=K15_RData`
  - `frailty_score_source=K15_RData`
  - `fallback_used=FALSE`
  - `crosscheck_ok=TRUE`
- Methodological status: V1/V1.1/V1.2 fallback-era runs are retained as historical audit trail and marked `HISTORICAL/REJECTED` for primary canonical conclusions.

## 04-done signoff checklist (K24/K25 V2 canonical)
1. Provenance gate file exists and is canonical:
   `R-scripts/K24/outputs/K24_TABLE2A/K24_frailty_provenance_v2.txt`.
2. Provenance content PASS:
   `frailty_cat_source=K15_RData`, `frailty_score_source=K15_RData`,
   `fallback_used=FALSE`, `crosscheck_ok=TRUE`, `placeholder_used=FALSE`.
3. K24 canonical cat outputs exist:
   `table2A_paper_ready_canonical_cat_v2.csv/.html`.
4. K24 canonical score outputs exist:
   `table2A_paper_ready_canonical_score_v2.csv/.html`.
5. K24 audit + compare outputs exist:
   `table2A_audit_canonical_v2.csv` and
   `table2A_cat_vs_score_compare_canonical_v2.csv`.
6. Paper CSV sanity PASS:
   5 rows (`MWS`, `FTSST`, `SLS`, `HGS (Women)`, `HGS (Men)`), and columns include
   `N_without`, `N_with`, `Model_N`.
7. Compare CSV sanity PASS:
   includes `AIC_cat`, `AIC_score`, and `Agreement_Flag`.
8. K25 canonical outputs exist:
   list + narrative md/txt + `sessionInfo_v2.txt`.
9. K25 narrative provenance sentence present:
   “K15 canonical pipeline (K15_RData input; no fallback derivation).”
10. Table-to-text spot-check PASS:
    one outcome (recommended: `MWS`) matches exactly between
    `table2A_paper_ready_canonical_cat_v2.csv` and
    `results_table2A_from_K24_canonical_v2_narrative.md`.
11. Manifest uniqueness PASS:
    one row per K24/K25 V2 label (`script,label,kind,path` unique; no duplicates).
12. Smoke gate PASS:
    `run-gates --mode pre-push --smoke` exits OK (known non-blocking WARN notes allowed if unchanged).

### Commands
`[TERMUX]`
```bash
cd ~/Python-R-Scripts/Fear-of-Falling
sed -n '1,220p' R-scripts/K24/outputs/K24_TABLE2A/K24_frailty_provenance_v2.txt
ls -la R-scripts/K24/outputs/K24_TABLE2A | grep -E "canonical|v2|provenance|compare|sessionInfo"
head -n 8 R-scripts/K24/outputs/K24_TABLE2A/table2A_paper_ready_canonical_cat_v2.csv
head -n 8 R-scripts/K24/outputs/K24_TABLE2A/table2A_paper_ready_canonical_score_v2.csv
head -n 12 R-scripts/K24/outputs/K24_TABLE2A/table2A_cat_vs_score_compare_canonical_v2.csv
ls -la R-scripts/K25/outputs/K25_RESULTS | grep -E "canonical|v2|sessionInfo"
sed -n '1,120p' R-scripts/K25/outputs/K25_RESULTS/results_table2A_from_K24_canonical_v2_narrative.md
grep "K24_TABLE2A" manifest/manifest.csv | tail -80
grep "K25_RESULTS" manifest/manifest.csv | tail -80
```

`[PROOT:DEBIAN]`
```bash
proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin && cd ~/Python-R-Scripts/Fear-of-Falling && /usr/bin/Rscript R-scripts/K25/K25_RESULTS.V2_table2A-results-text-canonical.R --input R-scripts/K24/outputs/K24_TABLE2A/table2A_paper_ready_canonical_cat_v2.csv --style narrative'
proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin && cd ~/Python-R-Scripts/Fear-of-Falling && bash ../tools/run-gates.sh --mode pre-push --smoke'
```

### PASS decision rule
- PASS: all 12 checks above succeed.
- HOLD: any mismatch in provenance, missing artifact, duplicate manifest label, or CSV↔text mismatch.
- Note: this checklist prepares human signoff only; task move to `04-done` is manual.

## K24_VIS forest plots (canonical V2)
- New script:
  - `R-scripts/K24/K24_VIS.V1_forestplots_table2A_cat_vs_score.R`
- Run command:
  - `/usr/bin/Rscript R-scripts/K24/K24_VIS.V1_forestplots_table2A_cat_vs_score.R --input R-scripts/K24/outputs/K24_TABLE2A/table2A_cat_vs_score_compare_canonical_v2.csv --format both --make_cat_p TRUE --qc_tol 0.10 --qc_strict FALSE`
- Produced figure artifacts under:
  - `R-scripts/K24/outputs/K24_TABLE2A/figures/K24_VIS/`
  - `K24_canonicalV2_forest_FOF.{png,pdf}`
  - `K24_canonicalV2_forest_FrailtyScore.{png,pdf}`
  - `K24_canonicalV2_frailtyCat_overallP.{png,pdf}`
  - `plot_manifest.txt`, `sessionInfo.txt`
- Delimiter sniff:
  - compare input parsed as comma-delimited (`input_delimiter=,` in `plot_manifest.txt`).
- QC result:
  - `qc_fof_cat_vs_score_diff.csv` generated and retained as documentation.
  - Reviewer-ready semantics: default QC status is `PASS` or `WARN` by CI-based `z_diff` (+ sign-flip check), and strict `FAIL` is only used when `--qc_strict TRUE`.
  - Current rerun status: `PASS` with `z_tol=1.96` and `sign_flip_any=FALSE`; `plot_manifest.txt` reports:
    - `outlier_outcome=HGS (Men)` (small N),
    - `max_z_diff_all=0.105604`,
    - `max_z_diff_excl_hgs_men=0.029745`,
    - legacy `max_abs_beta_diff=0.602000` retained for audit only.
  - Frailty cat p-panel layout fixed (`xlim 0..1` + right margin) to prevent label clipping in PNG/PDF.
- Manifest:
  - one row appended per figure + qc csv + plot_manifest + sessionInfo under `script=K24_VIS`.

## K24_VIS enhancements (contrasts + standardized beta)
- Added new reviewer-oriented plots (no analysis/model changes):
  - `K24_canonicalV2_forest_FrailtyCatContrasts.{png,pdf}` (pre-frail vs robust; frail vs robust)
  - `K24_canonicalV2_forest_FOF_standardized.{png,pdf}`
  - `K24_canonicalV2_forest_FrailtyScore_standardized.{png,pdf}`
- Standardization definition is deterministic and documented:
  - `standardized beta = beta / SD_baseline` per outcome, where `SD_baseline` is pooled from audit baseline SDs (`Without_FOF_Baseline`, `With_FOF_Baseline`) using group Ns.
  - `plot_manifest.txt` records `std_method=baseline_sd` and `sd_source=audit`.
- QC extension:
  - `qc_sd_baseline_missing.csv` is written only if `SD_baseline` is missing/non-positive (current rerun: `sd_baseline_missing_n=0`).
  - Existing z-diff/sign-flip QC remains unchanged (`qc_status=PASS`, outlier `HGS (Men)` with small N context).
- Manifest:
  - unique new K24_VIS rows appended for the three new plot pairs; duplicate key check (`script,label,kind,path`) remains enforced by script.

## Gate status (local PASS vs infra FAIL)
- K24_VIS local run PASS evidence:
  - Proot run command exits with code `0`:
    - `/usr/bin/Rscript R-scripts/K24/K24_VIS.V1_forestplots_table2A_cat_vs_score.R --input R-scripts/K24/outputs/K24_TABLE2A/table2A_cat_vs_score_compare_canonical_v2.csv --audit_input R-scripts/K24/outputs/K24_TABLE2A/table2A_audit_canonical_v2.csv --format both --make_cat_p TRUE --qc_strict FALSE --z_tol 1.96`
  - Output directory contains all expected V2 figures (including contrasts + standardized PNG/PDF pairs).
  - `plot_manifest.txt` confirms:
    - `qc_status=PASS`
    - `std_method=baseline_sd`
    - `sd_source=audit`
    - `sd_baseline_missing_n=0`
- Manifest uniqueness check (for `script=K24_VIS`) PASS:
  - duplicate count by `(script,label,kind,path)` = `0`.
- `run-gates --smoke` in proot is classified as infra/renv bootstrap failure (not a K24_VIS regression). Snippet from `gate_err.log`:
  - `Error ... failed to install: installation of renv failed`
  - `running command '/data/data/com.termux/files/usr/lib/R/bin/R' ... had status 1`
  - `ERROR: renv lockfile read failed. Fix renv.lock or install renv.`
- Smoke fallback checklist (when gates fail for infra reasons):
  1. Run K24_VIS command above and verify exit code `0`.
  2. `ls -la R-scripts/K24/outputs/K24_TABLE2A/figures/K24_VIS` and verify new artifacts exist.
  3. `grep -nE "qc_status|sd_baseline_missing_n|std_method|sd_source" R-scripts/K24/outputs/K24_TABLE2A/figures/K24_VIS/plot_manifest.txt`.
  4. Verify manifest uniqueness for K24_VIS with a `(script,label,kind,path)` duplicate check.
