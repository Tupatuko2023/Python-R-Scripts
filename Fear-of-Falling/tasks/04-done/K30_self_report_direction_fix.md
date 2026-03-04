# K30 Self-Report Direction Fix

## Context

### Objective
Replace correlation-based self-report orientation selection in `R-scripts/K30/k30.r` with codebook-driven directionality for `oma_arvio_liikuntakyky`, so higher final capacity coding always reflects better function. Keep z-composite as primary capacity score and keep triad CFA outputs diagnostic-only.

### Reproduction commands
- `cd Python-R-Scripts/Fear-of-Falling`
- Current behavior run:
  - `proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; cd Python-R-Scripts/Fear-of-Falling && /usr/bin/Rscript R-scripts/K30/k30.r'`
- Inspect current heuristic branch in script:
  - `grep -n "oma_arvio_liikuntakyky" R-scripts/K30/k30.r`
- Codebook lookup to anchor final mapping (authoritative source):
  - `grep -n "oma_arvio_liikuntakyky" data/Muuttujasanakirja.md || true`
  - `awk 'BEGIN{IGNORECASE=1} /oma_arvio_liikuntakyky|liikuntakyky|oma_arvio/{for(i=NR-5;i<=NR+12;i++) ctx[i]=1} {if(ctx[NR]) print NR ":" $0}' data/Muuttujasanakirja.md 2>/dev/null || true`
  - `grep -n "oma_arvio_liikuntakyky\\|liikuntakyky\\|oma_arvio" data/data_dictionary.csv || true`
  - `proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; cd Python-R-Scripts/Fear-of-Falling && /usr/bin/Rscript -e "d<-read.csv(\"data/data_dictionary.csv\", stringsAsFactors=FALSE); m<-d[apply(d,1,function(r) any(grepl(\"oma_arvio_liikuntakyky|liikuntakyky|oma_arvio\", r, ignore.case=TRUE))),,drop=FALSE]; print(m);" '`

### Proposed minimal fix (for when task moves to 01-ready)
- In `R-scripts/K30/k30.r`:
  - remove/disable correlation-driven A/B auto-orientation selection,
  - implement explicit codebook-driven recode for `oma_arvio_liikuntakyky` (including documented inversion if codebook implies higher=poorer original coding),
  - keep `capacity_score_primary` and `capacity_score_primary_sensitivity` as z-composite primary metrics,
  - keep CFA outputs as diagnostics only (no change to primary decision rule),
  - add `k30_direction_check.csv` artifact containing correlations/sign checks for documentation only (no auto-flip logic),
  - update decision log text to: direction set by codebook.
- Manifest discipline:
  - append one manifest row for new `k30_direction_check.csv` artifact via existing helper path.

## Inputs
- `R-scripts/K30/k30.r`
- `data/Muuttujasanakirja.md`
- `data/data_dictionary.csv`
- Existing K30 outputs/manifest conventions

## Outputs
- Updated `R-scripts/K30/k30.r` with codebook-driven self-report direction
- New artifact: `R-scripts/K30/outputs/k30_direction_check.csv`
- Updated decision log and manifest row for direction-check artifact

## Definition of Done (DoD)

### Acceptance criteria
- Self-report directionality in K30 is set explicitly by codebook, not by correlation auto-selection.
- `capacity_score_primary` remains the published primary score (z-composite), with gait0 sensitivity preserved.
- CFA remains diagnostic-only and inadmissibility handling remains explicit.
- `k30_direction_check.csv` is produced and logged in manifest.
- No raw data files are modified.

## Log

- 2026-02-28 17:04:00 Backlog task created for codebook-driven self-report direction fix in K30.
- 2026-02-28 17:30:00 Task moved `00-backlog -> 01-ready -> 02-in-progress`.
- 2026-02-28 17:31:00 Implemented minimal K30 change:
  - removed correlation-based auto-orientation (A/B),
  - applied deterministic recode rule for `oma_arvio_liikuntakyky`: `0 -> limitation`, `1/2 -> better function`,
  - added `k30_direction_check.csv` artifact and manifest append row.
- 2026-02-28 17:32:00 Validation run command:
  `proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; cd Python-R-Scripts/Fear-of-Falling && /usr/bin/Rscript R-scripts/K30/k30.r'`
- 2026-02-28 17:32:00 Validation result: success (exit 0); output and manifest rows regenerated.
- 2026-02-28 17:32:00 `fof-preflight` run after changes: PASS.
- 2026-02-28 17:32:00 Note: direct variable entry for `oma_arvio_liikuntakyky` was not found in `data/Muuttujasanakirja.md` / `data/data_dictionary.csv`; deterministic mapping anchored to documented project rule already used in K15 comments (`0=Weak, 1=Moderate, 2=Good`) and recorded in decision log.

## Blockers
- Optional documentation hardening: add explicit `oma_arvio_liikuntakyky` coding row to `data/data_dictionary.csv` for future fully codebook-local anchoring.

## Links
- `prompts/Frailty_Model_Copilot_2.txt`
- `R-scripts/K30/k30.r`
- `data/Muuttujasanakirja.md`
- `data/data_dictionary.csv`
