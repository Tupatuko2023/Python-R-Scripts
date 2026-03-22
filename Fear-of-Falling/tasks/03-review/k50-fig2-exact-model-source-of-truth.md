# K50 Figure 2 exact model source of truth

## Context

Figure 2 is currently reconstructed from exported fixed-effect terms instead of
the saved primary LONG mixed-model object. This task hardens the K50 pathway so
the figure uses exact model-based adjusted means and covariance-correct 95%
confidence intervals from the locked fitted model object.

## Inputs

- `R-scripts/K50/K50.r`
- `R-scripts/K50/make_fig2_trajectory.R`
- `prompts/1_8cafofv2.txt`
- `prompts/11_Locomotor_Capacity_Modeling_Copilot.txt`
- `manifest/manifest.csv`

## Outputs

- Updated `R-scripts/K50/K50.r`
- New `R-scripts/K50/K50.V2_make-fig2-trajectory-exact.R`
- Updated `R-scripts/K50/make_fig2_trajectory.R`
- Validation notes in this task log

## Definition of Done (DoD)

- [x] K50 primary LONG branch saves the exact model object and exact analysis
      frame as RDS artifacts with manifest rows.
- [x] New exact Figure 2 script uses the saved model object with `emmeans()`,
      not coefficient reconstruction.
- [x] Legacy `make_fig2_trajectory.R` no longer reconstructs Figure 2 from
      `*_model_terms_primary.csv`.
- [x] Validation confirms exact-script artifact structure or records blocker.
- [x] Task is moved to `tasks/03-review/` only after code edits and validation.

## Review Decision

- Analysis-repo scope is accepted as K50 code plus review-log artifacts only. `Results_Draft_version_2.qmd` is out of scope for `Fear-of-Falling` and is not required for this task.
- Review outcome: code patch accepted on analysis-repo criteria and runtime-validated in Debian/proot after repairing the shell PATH boundary in-command.
- Promotion gate: satisfied. The task is ready for human promotion to `tasks/04-done/`.

## Log

- 2026-03-22 14:54:32 +0200 Environment diagnosis: plain `proot-distro login debian --termux-home -- bash -lc ...` inherited Termux-prefixed PATH entries, and `command -v uname` / `command -v rm` resolved to `/data/data/com.termux/files/usr/bin/...`.
- 2026-03-22 14:54:32 +0200 Environment repair: running Debian commands inside the same proot shell with `export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; hash -r` forced `uname` and `rm` to resolve to `/usr/bin/...`, after which `/usr/bin/Rscript -e "sessionInfo()"` succeeded.
- 2026-03-22 14:54:32 +0200 Package probe succeeded in repaired proot shell: `emmeans`, `lme4`, `lmerTest`, `ggplot2`, `readr`, `dplyr`, and `here` all returned `TRUE`.
- 2026-03-22 14:54:32 +0200 Runtime validation succeeded with exact commands: `proot-distro login debian --termux-home -- bash -lc '''export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; hash -r; cd ~/Python-R-Scripts/Fear-of-Falling && /usr/bin/Rscript R-scripts/K50/K50.r --shape LONG --outcome locomotor_capacity'''` and `proot-distro login debian --termux-home -- bash -lc '''export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; hash -r; cd ~/Python-R-Scripts/Fear-of-Falling && /usr/bin/Rscript R-scripts/K50/K50.V2_make-fig2-trajectory-exact.R'''`.
- 2026-03-22 14:54:32 +0200 Artifact check passed: `k50_long_locomotor_capacity_model_primary.rds`, `k50_long_locomotor_capacity_model_frame_primary.rds`, `FIG2_trajectory_exact/k50_long_locomotor_capacity_fig2_predictions.csv`, `k50_fig2_trajectory_exact.png`, `k50_fig2_trajectory_exact.pdf`, and `k50_fig2_trajectory_exact_sessioninfo.txt` all exist. Prediction CSV has exactly 4 rows in canonical No FOF/FOF x baseline/12 months order.
- 2026-03-22 14:54:32 +0200 Review conclusion updated: environment gate cleared; task is ready for human move from `tasks/03-review/` to `tasks/04-done/`.
- 2026-03-22 14:43:00 +0200 Review pass: accepted manuscript edits as explicitly out of scope for this analysis repository; K50 review remains limited to code and task-log artifacts.
- 2026-03-22 14:43:00 +0200 Runtime validation retry in Debian/proot failed before package checks and model execution. `/usr/bin/Rscript -e "sessionInfo()"` and the package probe both halted in `utils::.onLoad` after Termux `coreutils` binaries (`uname`, `rm`) failed to link inside proot (`libc.so` missing from verneed).
- 2026-03-22 14:43:00 +0200 Review conclusion: K50 patch is analysis-repo complete in principle, but `tasks/04-done/` must wait for one successful runtime pass in a repaired Debian/proot R environment.
- 2026-03-22 14:31:42 +0200 Moved task from `tasks/01-ready/` to `tasks/02-in-progress/` before code edits.
- 2026-03-22 14:35:56 +0200 Patched `R-scripts/K50/K50.r` to save the primary LONG fitted model object and exact model frame as manifest-logged RDS artifacts.
- 2026-03-22 14:35:56 +0200 Added `R-scripts/K50/K50.V2_make-fig2-trajectory-exact.R` to generate exact Figure 2 predictions and figures from the saved model object via `emmeans()`.
- 2026-03-22 14:35:56 +0200 Replaced legacy `R-scripts/K50/make_fig2_trajectory.R` with a fail-loud deprecation shim that blocks coefficient-table reconstruction.
- 2026-03-22 14:35:56 +0200 Validation: `bash tools/run-gates.sh --mode pre-push --smoke` passed at repo root; `Rscript -e "parse(...)"` passed for all changed K50 scripts.
- 2026-03-22 14:35:56 +0200 Validation blocker: runtime execution could not be completed in this session because the local Termux R environment is missing required packages (`emmeans`, `lme4`, `lmerTest`, `ggplot2`), and Debian/proot R is broken (`utils`/`stats` missing during startup).
- 2026-03-22 14:35:56 +0200 Preflight note: `fof-preflight` failed on an unrelated pre-existing file `Fear-of-Falling/R-scripts/K50/K50_visualize_fi22_fof_delta.R` (missing Required vars header), not on this patch.
- 2026-03-22 14:35:56 +0200 Manuscript note: `Results_Draft_version_2.qmd` was not present under `Fear-of-Falling/`, so no manuscript text change was made in this run.
- 2026-03-22 14:35:56 +0200 Moved task to `tasks/03-review/` after code edits and validation logging.
- 2026-03-22 14:31:42 +0200 Created from `tasks/_template.md` for the K50
  Figure 2 exact-model source-of-truth patch.

## Blockers

- No remaining code or environment blocker in this repository. Human workflow rule still applies: only a person should move this task from `tasks/03-review/` to `tasks/04-done/`.

## Links

- `prompts/1_8cafofv2.txt`
- `prompts/11_Locomotor_Capacity_Modeling_Copilot.txt`
