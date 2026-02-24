# K26_LMM_MOD time-frailty-CompositeZ0 moderation

REVIEW SUMMARY (canonical rerun PASS)

K26 rerun executed with canonical frailty from K15 .RData input: R-scripts/K15/outputs/K15_frailty_analysis_data.RData.
Provenance gate: frailty_cat_source=K15_RData; frailty_score_source=K15_RData; fallback_used=FALSE; derived_rule=none.
Reporting QC: placeholder_used=FALSE and crosscheck_ok=TRUE for both modes (cat + score).
Sample sizes: n_wide_unique_id=276; n_long_rows=552; n_complete=476 (cat + score).
Outputs present (cat + score): LRT tables, fixed-effects tables, simple-slopes tables, Finnish results text, model RDS, sessionInfo, provenance.
Workflow: ready for human move to tasks/04-done/ for tasks/01-ready/K15_add_frailty_score_3_to_RData.md and tasks/01-ready/K26_rerun_canonical_frailty.md (do not commit outputs).
Status now: canonical rerun PASS (K15_RData; fallback_used=FALSE); previous fallback-based run rejected.

## Context
Implement K26 long-LMM backbone (time×FOF) with exploratory moderation (time×frailty×cComposite_Z0) and run both frailty modes (cat + score) in one script, following init_paths/reporting manifest conventions.

**Metodologinen päätös (gate):** frailty-fallback (`derived_morbidity` + `score->cat`) hylätty analyysispesifikaatiosta. Uusi rerun-tehtävä luotu: `tasks/01-ready/K26_rerun_canonical_frailty.md`.
**Pipeline-päivitys:** canonical-only K26 käyttää vain K15 frailty-augmented `.RData`-inputtia (`--input`), ei raw CSV:tä.

## Inputs
- `R-scripts/K15/outputs/K15_frailty_analysis_data.RData` (canonical)
- CLI override: `--input` (`.RData` only in canonical-only mode; raw CSV blocked)

## Outputs
- `R-scripts/K26/outputs/K26/K26_LMM_MOD/K26_LRT_primary_vs_mod_cat.csv`
- `R-scripts/K26/outputs/K26/K26_LMM_MOD/K26_LRT_primary_vs_mod_score.csv`
- `R-scripts/K26/outputs/K26/K26_LMM_MOD/K26_fixed_effects_primary_cat.csv`
- `R-scripts/K26/outputs/K26/K26_LMM_MOD/K26_fixed_effects_moderation_cat.csv`
- `R-scripts/K26/outputs/K26/K26_LMM_MOD/K26_simple_slopes_change_cat.csv`
- `R-scripts/K26/outputs/K26/K26_LMM_MOD/K26_results_text_fi_cat.txt`
- score-mode counterparts + model RDS files + `sessionInfo.txt`
- manifest rows in `manifest/manifest.csv` (one per artifact)

## Definition of Done (DoD)
- K26 script exists with STANDARD SCRIPT INTRO and explicit mapping/req cols checks.
- Script runs cat+score modes and writes artifacts to K26 output subdir.
- Manifest rows appended using `manifest_row()` + `append_manifest()`.
- Results text values are generated from produced tables (table-to-text crosscheck).
- `PROJECT_FILE_MAP.md` has a minimal K26 entry.

## Log
Historical entries below include pre-canonical runs; current gate status is defined by REVIEW SUMMARY + current provenance.
- 2026-02-24 00:00:00 Task created in 00-backlog.
- 2026-02-24 00:01:00 Moved 00-backlog -> 01-ready -> 02-in-progress.
- 2026-02-24 00:10:00 Added script `R-scripts/K26/K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R`.
- 2026-02-24 00:12:00 Updated `PROJECT_FILE_MAP.md` with minimal K26 entry (purpose/reads/writes/run).
- 2026-02-24 00:20:00 Added deterministic proot wrappers:
  - `scripts/termux/run_proot_r_clean.sh`
  - `scripts/termux/run_k26_proot_clean.sh`
  - patched `scripts/termux/run_qc_summarizer_proot.sh` to unset `LD_*` and `R_*` before proot R calls.
- 2026-02-24 00:21:00 Preflight PASS (clean env):
  - proot `command -v Rscript` => `/usr/bin/Rscript`
  - `/usr/bin/Rscript -e "sessionInfo()"` works.
- 2026-02-24 00:23:00 K26 run via wrapper (PRE-CANONICAL / HISTORICAL):
  - `scripts/termux/run_k26_proot_clean.sh --input data/external/KaatumisenPelko.csv --include_balance TRUE --run_cat TRUE --run_score TRUE`
  - produced cat + score runtime artifacts under `R-scripts/K26/outputs/K26/K26_LMM_MOD/`
  - appended K26 manifest rows (one per artifact key after K26-only dedupe).
- 2026-02-24 00:30:00 K26 review-hardening PASS:
  - added explicit frailty provenance trace artifact `K26_frailty_provenance.txt`
  - added fallback WARNING to console when fallback path is used
  - added `crosscheck_ok` per mode to provenance artifact
  - reran K26 via wrapper and refreshed K26 manifest rows (deduped per artifact key)
- 2026-02-24 00:15:00 Smoke attempts:
  - `proot-distro login debian --termux-home -- /usr/bin/Rscript ...` -> failed (path context / bad ELF magic in proot).
  - `proot-distro login debian --termux-home -- bash -lc 'cd ... && /usr/bin/Rscript ...'` -> failed (`bad ELF magic` in proot Debian rootfs).
  - local `Rscript ...` -> failed (`here` package missing in current R env).
  - `Rscript -e 'renv::restore(prompt=FALSE)'` -> failed due renv/sysreqs platform detection error in current Termux environment.
  - `Rscript -e 'parse(file=\"R-scripts/K26/K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R\")'` -> PASS (syntax OK).

## Deliverable Summary

### Changed files
- `R-scripts/K26/K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R` (new)
- `PROJECT_FILE_MAP.md` (K26 minimal map entry)
- `scripts/termux/run_proot_r_clean.sh` (new)
- `scripts/termux/run_k26_proot_clean.sh` (new)
- `scripts/termux/run_qc_summarizer_proot.sh` (env cleanup patch)
- `tasks/03-review/K26_LMM_MOD_time-frailty-CompositeZ0_moderation.md` (this report)

### Commands run (historical + canonical)
- `proot-distro login debian --termux-home -- /usr/bin/Rscript R-scripts/K26/K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R --input data/external/KaatumisenPelko.csv --include_balance TRUE --run_cat TRUE --run_score TRUE`
- `proot-distro login debian --termux-home -- bash -lc 'cd ~/Python-R-Scripts/Fear-of-Falling && /usr/bin/Rscript ...'`
- `Rscript R-scripts/K26/K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R --input data/external/KaatumisenPelko.csv --include_balance TRUE --run_cat TRUE --run_score TRUE`
- `Rscript -e 'if (!requireNamespace(\"renv\", quietly=TRUE)) install.packages(\"renv\"); renv::restore(prompt=FALSE)'`
- `Rscript -e 'parse(file=\"R-scripts/K26/K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R\")'`
- `proot-distro login debian --termux-home -- bash -lc 'unset LD_PRELOAD LD_LIBRARY_PATH R_HOME R_LIBS R_LIBS_USER; export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; echo \"Rscript=$(command -v Rscript)\"; /usr/bin/Rscript -e \"sessionInfo()\"'`
- `scripts/termux/run_k26_proot_clean.sh --input data/external/KaatumisenPelko.csv --include_balance TRUE --run_cat TRUE --run_score TRUE`

### Produced artifacts
- Runtime artifacts produced in:
  - `R-scripts/K26/outputs/K26/K26_LMM_MOD/`
  - includes `K26_LRT_*`, `K26_fixed_effects_*`, `K26_simple_slopes_*`, `K26_results_text_fi_*`, `K26_model_*.rds`, `sessionInfo.txt`
- Additional QC trace artifact:
  - `R-scripts/K26/outputs/K26/K26_LMM_MOD/K26_frailty_provenance.txt`
- Manifest rows appended for all K26 artifacts and deduped to one row per `(script,label,kind,path)` key.

### Assumptions / fallbacks used
- ID mapping fallback order: `ID` -> `id` -> `Jnro` -> `NRO`.
- FOF mapping fallback: `FOF_status` or `kaatumisenpelkoOn` (0/1 -> `nonFOF`/`FOF`).
- Composite mapping fallback: `Composite_Z0`/`Composite_Z12` or `ToimintaKykySummary0`/`ToimintaKykySummary2`.
- Frailty score fallback hierarchy:
  - canonical `frailty_score_3`
  - fallback `frailty_count_3`
  - final fallback `derived_morbidity = diabetes + alzheimer + parkinson`
- Frailty cat fallback hierarchy:
  - canonical `frailty_cat_3`
  - fallback `derived_from_score` rule `0/1/>=2` -> `Robust/Pre-frail/Frail`
- All fallback paths are explicitly recorded in:
  - `R-scripts/K26/outputs/K26/K26_LMM_MOD/K26_frailty_provenance.txt`

## Blockers
- No active blockers for K26 canonical run via wrapper.
- Root cause of earlier `bad ELF magic`: Termux env contamination (`LD_PRELOAD` + PATH selecting Termux Rscript) into proot; fixed by clean-env wrappers forcing `/usr/bin/Rscript`.

## Links
- `CLAUDE.md`
- `R/functions/reporting.R`
- `R/functions/init.R`
- `R-scripts/K26/K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R`
- `PROJECT_FILE_MAP.md`

## Canonical run command (deterministic)

Use this command for all K26 runs to avoid Termux->proot contamination:

`scripts/termux/run_k26_proot_clean.sh --input R-scripts/K15/outputs/K15_frailty_analysis_data.RData --include_balance TRUE --run_cat TRUE --run_score TRUE`

This wrapper always:
- unsets `LD_PRELOAD`, `LD_LIBRARY_PATH`, `R_HOME`, `R_LIBS`, `R_LIBS_USER`
- sets clean Debian `PATH`
- executes `/usr/bin/Rscript` in proot Debian.
- Raw CSV input is blocked in canonical-only mode.

## Frailty fallback policy (HISTORICAL — REJECTED)

This section documents an earlier run that was rejected. Superseded by canonical rerun using `K15_RData` (see REVIEW SUMMARY and provenance).

- Provenance artifact to review:
  - `R-scripts/K26/outputs/K26/K26_LMM_MOD/K26_frailty_provenance.txt`
- Historical rejected run status:
  - `frailty_score_source=derived_morbidity`
  - `frailty_cat_source=derived_from_score`
  - `derived_rule=0/1/>=2`
  - `fallback_used=TRUE` [HISTORICAL REJECTED]
  - `crosscheck_ok=TRUE` for both `cat` and `score` modes

### Review checklist (human approval)
- Do not use fallback history for gate decisions.
- Use canonical rerun evidence (`fallback_used=FALSE`, `frailty_*_source=K15_RData`) for 04-done decision.

## K26_VIS reviewer figure set
- New script: `R-scripts/K26/K26_VIS.V1_composite-delta-predicted-plots.R`
- Canonical inputs used:
  - `R-scripts/K26/outputs/K26/K26_LMM_MOD/K26_model_moderation_cat.rds`
  - `R-scripts/K26/outputs/K26/K26_LMM_MOD/K26_model_moderation_score.rds`
  - `R-scripts/K15/outputs/K15_frailty_analysis_data.RData`
- Run command:
  - `/usr/bin/Rscript R-scripts/K26/K26_VIS.V1_composite-delta-predicted-plots.R --format both`
- Produced artifacts:
  - `R-scripts/K26/outputs/K26_VIS/figures/K26_VIS_predicted_delta_by_frailtycat_x_fof.{png,pdf}`
  - `R-scripts/K26/outputs/K26_VIS/figures/K26_VIS_moderation_delta_vs_baseline_by_frailtycat.{png,pdf}`
  - `R-scripts/K26/outputs/K26_VIS/figures/K26_VIS_predicted_delta_by_frailtyscore_x_fof.{png,pdf}`
  - `R-scripts/K26/outputs/K26_VIS/K26_VIS_provenance.txt`
  - `R-scripts/K26/outputs/K26_VIS/qc_summary.csv`
  - `R-scripts/K26/outputs/K26_VIS/sessionInfo.txt`
- QC/provenance status:
  - `qc_summary.csv`: overall `PASS`
  - provenance explicitly documents `delta_definition=Composite_Z12 - Composite_Z0` and canonical frailty source (`K15/K26 pipeline; no fallback`).
- Manifest:
  - `script=K26_VIS` rows appended with unique keys (`script,label,kind,path`), duplicate count `0`.
