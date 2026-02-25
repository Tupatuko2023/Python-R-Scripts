# K27: Baseline Table 1 frailty_cat_3 -ryhmittäin

## Context
`codex_task_packet` pyytää toteuttamaan Fear-of-Falling -aliprojektiin uuden skriptin `R-scripts/K27/K27.R`, ajamaan sen renv-yhteensopivasti ja validoimaan CSV/HTML/log/manifest/sessionInfo -artefaktit.

## Inputs
- Working directory: `Python-R-Scripts/Fear-of-Falling/`
- Input data: `data/external/KaatumisenPelko.csv`
- Helperit: `R/functions/io.R`, `R/functions/checks.R`, `R/functions/modeling.R`, `R/functions/reporting.R`
- K27-logiikan lähde: `FOFxtime_mixed_model_copilot_3.txt`

## Outputs
- `R-scripts/K27/K27.R`
- `R-scripts/K27/outputs/K27_run.log`
- `R-scripts/K27/outputs/K27_baseline_by_frailty.csv`
- `R-scripts/K27/outputs/K27_baseline_by_frailty.html`
- `manifest/manifest.csv` (uudet K27-rivit)
- sessionInfo-artefakti `save_sessioninfo_manifest()`-konvention mukaan

## Definition of Done (DoD)
- Tehtävä on siirretty `tasks/01-ready/` -> `tasks/02-in-progress/` ennen toteutusta.
- K27-skripti luotu ja ajettu onnistuneesti (`exit code 0`).
- CSV + HTML + run-log + manifest-rivit + sessionInfo syntyneet ja validoitu.
- Raportointi PASS/FAIL + olennaiset polut + diagnostiset tail/listaus virhetilanteessa.

## Log

- 2026-02-25 14:24:00 Created from template because matching K27 task was not present in `tasks/01-ready/`; execution intentionally stopped per workflow rule.
- 2026-02-25 14:26:00 Task moved to `02-in-progress`, preflight PASS, and K27 script scaffolded from `prompts/FOFxtime_mixed_model_copilot_3.txt`.
- 2026-02-25 14:44:00 `renv::restore(prompt = FALSE)` failed in Debian proot at `nloptr` due missing system dependency `cmake`; execution stopped per fail-fast rule.
- 2026-02-25 15:03:00 Installed Debian sysdeps in proot (`cmake`, build toolchain, `libnlopt-dev`, and additional graphics/text deps for `systemfonts`/`ragg`), re-ran `renv::restore(prompt = FALSE)` successfully (`EXIT_CODE:0`).
- 2026-02-25 15:03:00 Ran `/usr/bin/Rscript R-scripts/K27/K27.R` successfully (`K27_EXIT_CODE:0`) and validated outputs + manifest rows.

### Commands Executed

- TERMUX:
  - `cd /data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling`
  - `test -f R-scripts/K27/K27.R`
  - `mkdir -p R-scripts/K27/outputs`
- PROOT:DEBIAN (successful sequence):
  - `apt-get update`
  - `apt-get install -y --no-install-recommends cmake build-essential gfortran pkg-config libnlopt-dev liblapack-dev libblas-dev`
  - `apt-get install -y --no-install-recommends libcairo2-dev libfontconfig1-dev libfreetype6-dev libx11-dev pandoc libharfbuzz-dev libfribidi-dev libxml2-dev libssl-dev`
  - `apt-get install -y --no-install-recommends libfreetype-dev libpng-dev libtiff5-dev libjpeg-dev libwebp-dev zlib1g-dev libbz2-dev`
  - `/usr/bin/R -q -e '... renv::restore(prompt = FALSE)' > R-scripts/K27/outputs/K27_renv_restore.log 2>&1`
  - `/usr/bin/Rscript R-scripts/K27/K27.R > R-scripts/K27/outputs/K27_run.log 2>&1`

### Result

- PASS

### Artifacts

- `R-scripts/K27/K27.R`
- `R-scripts/K27/outputs/K27_renv_restore.log`
- `R-scripts/K27/outputs/K27_run.log`
- `R-scripts/K27/outputs/K27_baseline_by_frailty.csv`
- `R-scripts/K27/outputs/K27_baseline_by_frailty.html`
- `R-scripts/K27/outputs/sessioninfo_K27.txt`
- `manifest/manifest.csv` (uudet K27-rivit)

### Manifest Excerpt (K27)

- `2026-02-25 15:02:55.804558,K27,K27_baseline_by_frailty,table_csv,R-scripts/K27/outputs/K27_baseline_by_frailty.csv,250,NA`
- `2026-02-25 15:02:56.103428,K27,K27_baseline_by_frailty,table_html,R-scripts/K27/outputs/K27_baseline_by_frailty.html,250,NA`
- `2026-02-25 15:02:56.377453,K27,sessioninfo,sessioninfo,R-scripts/K27/outputs/sessioninfo_K27.txt,NA,NA`

## Blockers

- None (resolved during this run).

## Links

- `tasks/_template.md`
- `tools/run-gates.sh`
