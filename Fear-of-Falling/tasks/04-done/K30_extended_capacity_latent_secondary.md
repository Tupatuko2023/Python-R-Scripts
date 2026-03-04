# K30 Extended Capacity Latent Secondary

## Context

### Objective
Stage an optional secondary latent capacity analysis in a new script `R-scripts/K31/k31.r` using >=4 theory-aligned baseline indicators, while leaving K30 composite primary analysis unchanged.

### Reproduction commands
- `cd Python-R-Scripts/Fear-of-Falling`
- Confirm K30 remains primary/diagnostic baseline reference:
  - `proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; cd Python-R-Scripts/Fear-of-Falling && /usr/bin/Rscript R-scripts/K30/k30.r'`
- Candidate baseline indicator discovery (example):
  - `proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; cd Python-R-Scripts/Fear-of-Falling && /usr/bin/Rscript -e "d<-read.csv(\"R-scripts/K30/outputs/kaatumisenpelko_with_capacity_scores.csv\"); cat(paste(names(d), collapse=\"\\n\"))"'`

### Proposed minimal fix (for when task moves to 01-ready)
- Create new script `R-scripts/K31/k31.r`:
  - use deterministic 4-5 indicator set with max 1 self-report:
    - objective core (required): grip + gait + chair + balance
    - optional 5th: one self-report mobility item only
  - load the same analysis dataset and initialize outputs/manifest with K31 conventions,
  - define a small explicit mapping block for >=4 baseline physical performance indicators (e.g. grip, gait, chair-rise, balance) with fail-fast unresolved mapping behavior,
  - fit one-factor CFA (WLSMV only if ordered indicator included) as secondary model,
  - add strict admissibility diagnostics:
    - no negative residual variances,
    - no `|Std.all| > 1`,
    - acceptable score NA share threshold,
    - coherent objective loading direction,
  - output scores only when admissible; otherwise emit diagnostics/report and skip score output,
  - compare admissible latent score (if produced) against K30 composite via correlation table.
  - no MI-based residual covariances and no modification-index fit chasing.
- Keep K30 unchanged as primary pipeline by design.

## Inputs
- New script path: `R-scripts/K31/k31.r`
- Existing primary outputs from K30
- Shared manifest/reporting helpers in `R/functions/reporting.R`

## Outputs
- Secondary diagnostics artifacts under `R-scripts/K31/outputs/`
- Secondary latent scores only if model admissibility criteria are met
- Manifest rows for K31 artifacts

## Definition of Done (DoD)

### Acceptance criteria
- `R-scripts/K31/k31.r` runs and writes diagnostics.
- If model admissible, latent scores are written and compared to K30 composite.
- If model inadmissible, no latent scores are published and diagnostics clearly state fallback to composite.
- K30 script and primary results remain unchanged.
- No raw data files are modified.

## Log

- 2026-02-28 17:04:00 Backlog task created for optional secondary >=4-indicator latent capacity analysis (K31).
- 2026-02-28 18:30:00 Task moved `00-backlog -> 01-ready -> 02-in-progress`.
- 2026-02-28 18:37:00 Implemented new script `R-scripts/K31/k31.r` with deterministic indicator defaults:
  - grip=`puristus0_clean` (fallbacks),
  - gait=`kavelynopeus_m_sek0` with primary/sensitivity zero handling,
  - chair=`tuoli0` (fallback `tuoliltanousu0`, transformed to capacity direction),
  - balance=`seisominen0` (fallback right/left single-leg mean),
  - optional single self-report from walking difficulty variables.
- 2026-02-28 18:38:00 Added deterministic admissibility gate for latent score release:
  `converged_ok && !has_neg_resid_var && !has_std_loading_gt1 && loading_signs_ok && score_na_share <= threshold`.
- 2026-02-28 18:38:00 Added always-on z-composite outputs (`z4` and `z5`) for primary and gait sensitivity variants.
- 2026-02-28 18:38:00 Validation run command:
  `proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; cd Python-R-Scripts/Fear-of-Falling && /usr/bin/Rscript R-scripts/K31/k31.r'`
- 2026-02-28 18:38:00 Validation result: success (exit 0); outputs generated under `R-scripts/K31/outputs/` and manifest rows appended.
- 2026-02-28 18:38:00 Admissibility outcome in this run: latent not released (`loading_sign_mismatch`), so latent score columns are NA and z-composites remain recommended secondary outputs.
- 2026-02-28 18:38:00 `fof-preflight` after implementation: PASS.

## Blockers
- Optional theory refinement: confirm whether chair/balance directional transforms should be fixed a priori in codebook docs for future consistency.

## Links
- `prompts/Frailty_Model_Copilot_2.txt`
- `R-scripts/K30/k30.r`
- Planned new script: `R-scripts/K31/k31.r`
