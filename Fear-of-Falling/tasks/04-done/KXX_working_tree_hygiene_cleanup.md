# KXX Working Tree Hygiene Cleanup

## Context
K32 and K15 milestones are closed and analysis gates are green, but the working tree remains dirty due to a mixture of source edits and generated artifacts.

This task is hygiene-only and must not change analytical logic.

## Inputs
- `git status --porcelain`
- `git diff --name-only`
- Current output discipline rules (patient-level externalization + receipt-only in repo)

## Outputs
- Deterministic classification of dirty files:
  - source code / scripts
  - generated tracked artifacts
  - generated untracked artifacts
  - manifest/receipt/log files
- Minimal reversible cleanup plan (to execute only after move to `tasks/01-ready/`).

## Definition of Done (DoD)
1. Capture current dirty-tree state with deterministic commands.
2. Classify all changed paths into source vs generated categories.
3. Define exact cleanup steps:
   - keep intended source/task changes
   - revert accidental tracked generated changes (`git restore <path>`)
   - optionally update `.gitignore` for truly transient files only
4. Re-run `bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling` after cleanup.
5. Confirm leak-check remains clean.

## Deterministic Audit Commands
```bash
cd Python-R-Scripts/Fear-of-Falling
git status --porcelain
git diff --name-only
```

## Captured Snapshot: git status --porcelain
```text
 M Fear-of-Falling/R-scripts/K15/K15.R
 M Fear-of-Falling/R-scripts/K15/outputs/K15_chisq_FOF_by_frailty_cat3.csv
 M Fear-of-Falling/R-scripts/K15/outputs/K15_chisq_FOF_by_frailty_cat3.html
 M Fear-of-Falling/R-scripts/K15/outputs/K15_chisq_FOF_by_frailty_cat4.csv
 M Fear-of-Falling/R-scripts/K15/outputs/K15_chisq_FOF_by_frailty_cat4.html
 D Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_analysis_data.RData
 M Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_cat3_by_FOF.csv
 M Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_cat3_by_FOF.html
 M Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_cat3_by_FOF.png
 M Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_cat4_by_FOF.csv
 M Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_cat4_by_FOF.html
 M Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_cat_3_overall.csv
 M Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_cat_3_overall.html
 M Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_cat_4_overall.csv
 M Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_cat_4_overall.html
 M Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_count_3_overall.csv
 M Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_count_3_overall.html
 M Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_count_4_overall.csv
 M Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_count_4_overall.html
 M Fear-of-Falling/R-scripts/K15/outputs/sessioninfo_K15.txt
 M Fear-of-Falling/R-scripts/K18/K18_QC.V1_qc-run.R
 M Fear-of-Falling/R-scripts/K26/outputs/K26_VIS/K26_VIS_provenance.txt
 M Fear-of-Falling/R-scripts/K26/outputs/K26_VIS/figures/K26_VIS_moderation_delta_vs_baseline_by_frailtycat.pdf
 M Fear-of-Falling/R-scripts/K26/outputs/K26_VIS/figures/K26_VIS_moderation_delta_vs_baseline_by_frailtycat.png
 M Fear-of-Falling/R-scripts/K26/outputs/K26_VIS/figures/K26_VIS_predicted_delta_by_frailtycat_x_fof.pdf
 M Fear-of-Falling/R-scripts/K26/outputs/K26_VIS/figures/K26_VIS_predicted_delta_by_frailtycat_x_fof.png
 M Fear-of-Falling/R-scripts/K26/outputs/K26_VIS/figures/K26_VIS_predicted_delta_by_frailtyscore_x_fof.pdf
 M Fear-of-Falling/R-scripts/K26/outputs/K26_VIS/figures/K26_VIS_predicted_delta_by_frailtyscore_x_fof.png
 M Fear-of-Falling/R-scripts/K26/outputs/K26_VIS/sessionInfo.txt
 M Fear-of-Falling/R/functions/init.R
 M Fear-of-Falling/manifest/manifest.csv
 M Fear-of-Falling/scripts/termux/run_qc_summarizer_proot.sh
?? Fear-of-Falling/R-scripts/K30/
?? Fear-of-Falling/R-scripts/K31/
?? Fear-of-Falling/R-scripts/K32/
?? Fear-of-Falling/manifest/renv_diagnostics_20260226_145646.txt
?? Fear-of-Falling/manifest/renv_diagnostics_20260226_193936.txt
?? Fear-of-Falling/manifest/renv_diagnostics_20260228_160309.txt
?? Fear-of-Falling/manifest/renv_diagnostics_20260228_162855.txt
?? Fear-of-Falling/manifest/renv_diagnostics_20260228_165216.txt
?? Fear-of-Falling/manifest/renv_diagnostics_20260228_173052.txt
?? Fear-of-Falling/manifest/renv_diagnostics_20260228_183235.txt
?? Fear-of-Falling/manifest/renv_diagnostics_20260301_092827.txt
?? Fear-of-Falling/manifest/renv_diagnostics_20260301_095135.txt
?? Fear-of-Falling/manifest/renv_diagnostics_20260301_113521.txt
?? Fear-of-Falling/manifest/renv_diagnostics_20260301_125908.txt
?? Fear-of-Falling/manifest/renv_diagnostics_20260301_153048.txt
?? Fear-of-Falling/manifest/renv_diagnostics_20260301_153203.txt
?? Fear-of-Falling/manifest/run_meta_20260226_145646.txt
?? Fear-of-Falling/manifest/run_meta_20260226_193936.txt
?? Fear-of-Falling/manifest/run_meta_20260228_160309.txt
?? Fear-of-Falling/manifest/run_meta_20260228_162855.txt
?? Fear-of-Falling/manifest/run_meta_20260228_165216.txt
?? Fear-of-Falling/manifest/run_meta_20260228_173052.txt
?? Fear-of-Falling/manifest/run_meta_20260228_183235.txt
?? Fear-of-Falling/manifest/run_meta_20260301_092827.txt
?? Fear-of-Falling/manifest/run_meta_20260301_095135.txt
?? Fear-of-Falling/manifest/run_meta_20260301_113521.txt
?? Fear-of-Falling/manifest/run_meta_20260301_125908.txt
?? Fear-of-Falling/manifest/run_meta_20260301_153048.txt
?? Fear-of-Falling/manifest/run_meta_20260301_153203.txt
?? Fear-of-Falling/manifest/sessionInfo_20260226_145646.txt
?? Fear-of-Falling/manifest/sessionInfo_20260226_193936.txt
?? Fear-of-Falling/manifest/sessionInfo_20260228_160309.txt
?? Fear-of-Falling/manifest/sessionInfo_20260228_162855.txt
?? Fear-of-Falling/manifest/sessionInfo_20260228_165216.txt
?? Fear-of-Falling/manifest/sessionInfo_20260228_173052.txt
?? Fear-of-Falling/manifest/sessionInfo_20260228_183235.txt
?? Fear-of-Falling/manifest/sessionInfo_20260301_092827.txt
?? Fear-of-Falling/manifest/sessionInfo_20260301_095135.txt
?? Fear-of-Falling/manifest/sessionInfo_20260301_113521.txt
?? Fear-of-Falling/manifest/sessionInfo_20260301_125908.txt
?? Fear-of-Falling/manifest/sessionInfo_20260301_153048.txt
?? Fear-of-Falling/manifest/sessionInfo_20260301_153203.txt
?? Fear-of-Falling/manifest/sessionInfo_K28.txt
?? Fear-of-Falling/scripts/termux/run_k30_proot.sh
?? Fear-of-Falling/scripts/termux/run_k31_proot.sh
?? Fear-of-Falling/tasks/00-backlog/
?? Fear-of-Falling/tasks/03-review/K26_K15_verify_rdata_and_frailtycat_claim.md
?? Fear-of-Falling/tasks/04-done/K15_externalize_frailty_outputs.md
?? Fear-of-Falling/tasks/04-done/K18_qc_requires_data_arg_fix.md
?? Fear-of-Falling/tasks/04-done/K30_capacity_score.md
?? Fear-of-Falling/tasks/04-done/K30_extended_capacity_latent_secondary.md
?? Fear-of-Falling/tasks/04-done/K30_self_report_direction_fix.md
?? Fear-of-Falling/tasks/04-done/K32_extended_capacity_primary.md
?? Fear-of-Falling/tasks/04-done/K32_final_validation_layer.md
?? Fear-of-Falling/tasks/04-done/K32_loading_sign_mismatch_resolution.md
?? Fear-of-Falling/tasks/04-done/K32_validation_join_frailty_from_K15.md
?? Fear-of-Falling/tasks/04-done/KXX_externalize_patient_level_outputs.md
?? Fear-of-Falling/tasks/04-done/QC_runner_env_and_path_hardening.md
?? Fear-of-Falling/tasks/04-done/manifest_n_type_mismatch_fix.md
?? Fear-of-Falling/tasks/04-done/manifest_timestamp_type_mismatch_fix.md
```

## Captured Snapshot: git diff --name-only
```text
Fear-of-Falling/R-scripts/K15/K15.R
Fear-of-Falling/R-scripts/K15/outputs/K15_chisq_FOF_by_frailty_cat3.csv
Fear-of-Falling/R-scripts/K15/outputs/K15_chisq_FOF_by_frailty_cat3.html
Fear-of-Falling/R-scripts/K15/outputs/K15_chisq_FOF_by_frailty_cat4.csv
Fear-of-Falling/R-scripts/K15/outputs/K15_chisq_FOF_by_frailty_cat4.html
Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_analysis_data.RData
Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_cat3_by_FOF.csv
Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_cat3_by_FOF.html
Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_cat3_by_FOF.png
Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_cat4_by_FOF.csv
Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_cat4_by_FOF.html
Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_cat_3_overall.csv
Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_cat_3_overall.html
Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_cat_4_overall.csv
Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_cat_4_overall.html
Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_count_3_overall.csv
Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_count_3_overall.html
Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_count_4_overall.csv
Fear-of-Falling/R-scripts/K15/outputs/K15_frailty_count_4_overall.html
Fear-of-Falling/R-scripts/K15/outputs/sessioninfo_K15.txt
Fear-of-Falling/R-scripts/K18/K18_QC.V1_qc-run.R
Fear-of-Falling/R-scripts/K26/outputs/K26_VIS/K26_VIS_provenance.txt
Fear-of-Falling/R-scripts/K26/outputs/K26_VIS/figures/K26_VIS_moderation_delta_vs_baseline_by_frailtycat.pdf
Fear-of-Falling/R-scripts/K26/outputs/K26_VIS/figures/K26_VIS_moderation_delta_vs_baseline_by_frailtycat.png
Fear-of-Falling/R-scripts/K26/outputs/K26_VIS/figures/K26_VIS_predicted_delta_by_frailtycat_x_fof.pdf
Fear-of-Falling/R-scripts/K26/outputs/K26_VIS/figures/K26_VIS_predicted_delta_by_frailtycat_x_fof.png
Fear-of-Falling/R-scripts/K26/outputs/K26_VIS/figures/K26_VIS_predicted_delta_by_frailtyscore_x_fof.pdf
Fear-of-Falling/R-scripts/K26/outputs/K26_VIS/figures/K26_VIS_predicted_delta_by_frailtyscore_x_fof.png
Fear-of-Falling/R-scripts/K26/outputs/K26_VIS/sessionInfo.txt
Fear-of-Falling/R/functions/init.R
Fear-of-Falling/manifest/manifest.csv
Fear-of-Falling/scripts/termux/run_qc_summarizer_proot.sh
```

## Classification Rules
- `R/functions/*.R`, `R-scripts/*/*.R`, `scripts/termux/*.sh`: source/runtime logic changes.
- `tasks/**/*.md`: task workflow changes.
- `R-scripts/*/outputs/*` (tables/figures/sessioninfo): generated artifacts (usually revert unless policy says tracked final artifact).
- `manifest/manifest.csv` and `manifest/run_meta*` / `sessionInfo*` / `renv_diagnostics*`: runtime logging artifacts; keep only policy-required lines/files.
- `R-scripts/*/outputs/*receipt*.txt`: governance receipts (keep if they are required deliverables).

## Proposed Cleanup Steps (for future 01-ready implementation only)
1. Freeze evidence files required by closed tasks (receipts, required diagnostics, task markdown).
2. Revert non-required tracked generated files under `R-scripts/*/outputs/`.
3. Revert accidental tracked transient manifest/sessioninfo files if not required by policy.
4. Review untracked directories/files (`R-scripts/K30`, `K31`, `K32`, manifest run_meta/sessionInfo/renv diagnostics) and keep only task-required artifacts.
5. Add `.gitignore` entries only for confirmed transient files; do not ignore required receipts/diagnostics.
6. Re-run gates and leak-check.

## Log
- 2026-03-01 15:39: Created hygiene backlog task and captured deterministic dirty-tree snapshots.
- 2026-03-01 15:39: No cleanup actions performed at backlog stage.
- 2026-03-01 15:45: Restored tracked generated artifacts under `R-scripts/K15/outputs/` and `R-scripts/K26/outputs/` (kept governance-intended deletion: `K15_frailty_analysis_data.RData`).
- 2026-03-01 15:46: Added transient ignore rules: `manifest/run_meta_*.txt`, `manifest/sessionInfo_*.txt`, `manifest/renv_diagnostics_*.txt`.
- 2026-03-01 15:48: Re-ran `run_qc_summarizer_proot.sh` and `run-gates.sh --mode analysis --project Fear-of-Falling` (PASS).
- 2026-03-01 15:49: Post-clean status reduced from 92 to 27 `git status --porcelain` lines; remaining changes are source/task/governance-intended.

## Post-clean Snapshot (summary)
- `git status --porcelain` lines before: `92`
- `git status --porcelain` lines after: `27`
- Cleared categories:
  - tracked generated K15 tables/plots/sessioninfo diffs
  - tracked generated K26 VIS plots/sessioninfo/provenance diffs
- Still present (intended for later commit/triage):
  - source files: `K15.R`, `K18_QC.V1_qc-run.R`, `R/functions/init.R`, `run_qc_summarizer_proot.sh`
  - governance file: `manifest/manifest.csv`
  - task/runners/K30-K32 directories currently untracked in this worktree

## Blockers
- None.

## Links
- `tasks/04-done/K32_extended_capacity_primary.md`
- `tasks/04-done/K32_final_validation_layer.md`
- `tasks/04-done/K32_loading_sign_mismatch_resolution.md`
- `tasks/04-done/K32_validation_join_frailty_from_K15.md`
