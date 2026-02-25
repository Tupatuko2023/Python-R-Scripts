# K15 refactor to modified 3-item physical frailty proxy (motor-oriented)

## Objective
Refactor all K15 frailty derivation scripts so that:
- falls (`kaatuminen`) is removed from low activity component
- informative missingness is handled with parallel A/B paths
- naming is updated to modified 3-item physical frailty proxy (motor-oriented)
- QC artifacts and manifest rows are preserved and extended
- lightweight self-checks are added

## Scope
- Fear-of-Falling subproject only
- Primary targets under `R-scripts/K15` and related frailty scripts in `R-scripts`
- Touch K18/QC only if smoke test shows downstream break from renamed variables

## Inputs
- Objective/plan from codex task packet (2026-02-25)
- Existing K15 scripts and current reporting/manifest helpers

## Outputs
- Updated K15 frailty derivation scripts with A/B paths and self-checks
- New QC tables (component missingness, score missingness, legacy vs new)
- Manifest rows for each produced QC artifact

## Definition of Done (DoD)
- Repo scan documented with file + line hits
- No falls usage in active low-activity logic
- A/B outputs produced: `frailty_count_3_A/B`, `frailty_cat_3_A/B`
- Naming uses modified 3-item physical frailty proxy (motor-oriented)
- Constraint included: does not include exhaustion or weight loss
- Self-check assertions pass
- K15 + K18/QC smoke run passes (or documented blocker)

## Log
- 2026-02-25 21:31:00 task created in `tasks/00-backlog`.
- 2026-02-25 21:34:00 moved `00-backlog -> 01-ready -> 02-in-progress`.
- 2026-02-25 21:35:00 repo scan recorded (key hits):
  - `R-scripts/K15_MAIN/K15_MAIN.V1_frailty-proxy.R:191-208` (low_activity, frailty_count_3, frailty_cat_3, falls refs).
  - `R-scripts/K15/K15.R:374,433-443` (low_activity + frailty_count_3/frailty_cat_3).
  - `R-scripts/K15/K15.3.frailty_n_balance.R:523,582-590` (low_activity + frailty_count_3/frailty_cat_3).
- 2026-02-25 21:46:00 patches applied:
  - low_activity now based only on `oma_arvio_liikuntakyky`.
  - added `frailty_count_3_A/B` and `frailty_cat_3_A/B` + back-compat aliases.
  - added QC artifacts + manifest via `save_table_csv_html(..., write_html = FALSE)`.
  - added guarded legacy-vs-new table and required self-check assertions.
- 2026-02-25 21:51:00 smoke runs blocked by environment:
  - Termux R missing package `here`.
  - Debian proot R broken (`bad ELF magic`, `uname`/`utils` namespace load failure).
  - K18_QC runner and `fof-qc-summarizer` fail for same reason.
- 2026-02-25 22:02:00 PRoot runtime fixed:
  - root cause: Debian linker stubs (`/usr/lib/aarch64-linux-gnu/libc.so`, `libm.so`) were ld scripts in this proot context and caused `bad ELF magic`.
  - fix applied inside proot distro: symlinked `libc.so -> libc.so.6` and `libm.so -> libm.so.6`.
  - execution path stabilized with Debian PATH:
    `export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin`.
- 2026-02-25 22:04:00 deterministic smoke rerun PASS:
  - `K15_MAIN` PASS via `/usr/bin/Rscript`.
  - `K15` PASS via `/usr/bin/Rscript`.
  - `K15.3` first run hit proot bus error in `vroom/readr`; rerun with `VROOM_THREADS=1` PASS.
- 2026-02-25 22:06:00 housekeeping:
  - removed untracked run-meta/sessionInfo/renv-diagnostics txt files from `manifest/`.
  - restored generated `outputs/` files from git index to keep review diff focused.

## Blockers
- K15 smoke/runtime blockers resolved.
- K18 QC runner still not executable in this workspace because input file is missing:
  - `data/processed/analysis_long.csv` not found.

## Validation
- Status: PASS (K15 review gate).
- Runtime checks:
  - `proot-distro login debian --termux-home -- bash -lc 'command -v Rscript && /usr/bin/Rscript --version'` -> PASS
  - `proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; /usr/bin/Rscript -e "sessionInfo()"'` -> PASS
  - `proot-distro login debian --termux-home -- bash -lc 'export PATH=...; cd ~/Python-R-Scripts/Fear-of-Falling; /usr/bin/Rscript -e "if (!requireNamespace(\"renv\", quietly=TRUE)) install.packages(\"renv\"); renv::restore(); renv::status()"'` -> PASS (status warns lockfile R 4.4.2 vs runtime R 4.5.0)
  - `... /usr/bin/Rscript R-scripts/K15_MAIN/K15_MAIN.V1_frailty-proxy.R` -> PASS
  - `... /usr/bin/Rscript R-scripts/K15/K15.R` -> PASS
  - `... /usr/bin/Rscript R-scripts/K15/K15.3.frailty_n_balance.R` -> PASS with `VROOM_THREADS=1`
- Artifact checks:
  - QC labels present in `manifest/manifest.csv`:
    - `K15_frailty_components_missingness`
    - `K15_frailty_score_missingness`
    - `K15_frailty_legacy_vs_new`
    - `K15.3._frailty_components_missingness`
    - `K15.3._frailty_score_missingness`
    - `K15.3._frailty_legacy_vs_new`
  - `K15_MAIN` QC CSV files present under `R-scripts/K15_MAIN/outputs/`.
- Method note:
  - Pragmatic B-path equals A-path in current implementation because explicit unable/not-performed recode rules were not detected in the K15 derivation code.
- Table-to-text crosscheck (QC CSV -> this task card): PASS
  - Component missingness (all three runs): weakness `3/276` (1.09%), slowness `24/276` (8.70%), low_activity `3/276` (1.09%).
  - Score missingness (all three runs): `frailty_count_3_A = 29/276` (10.51%), `frailty_count_3_B = 29/276` (10.51%) -> confirms `B == A` missingness.
  - Legacy vs new:
    - `K15_MAIN` table shows `54/276` (19.6%) category changes vs legacy.
    - `K15` and `K15.3` tables show `57/276` (20.7%) category changes vs legacy.
    - All legacy tables are computed (no `legacy_not_available` note in this workspace).
- Manifest structure/path check: PASS
  - Manifest columns: `timestamp, script, label, kind, path, n, notes`.
  - Frailty-QC rows use `kind=table_csv` and paths under project outputs:
    - `R-scripts/K15_MAIN/outputs/...`
    - `R-scripts/K15/outputs/...`
  - No `/tmp` paths found in the relevant frailty-QC manifest entries.
- Known limitation (non-blocking for K15 review):
  - `K18_QC` runner not executed end-to-end in this workspace because `data/processed/analysis_long.csv` is missing.
  - This is documented as data availability issue, not a K15 runtime failure.

## Ready
- Ready for human approval in `03-review`; human may move to `04-done`.

## Links
- `AGENTS.md`
- `.codex/skills/fof-preflight/SKILL.md`
- `.codex/skills/fof-qc-summarizer/SKILL.md`
