# PR description (copy-paste)

This file is the single source of truth for the PR description.
All paths should be interpreted relative to `<REPO_ROOT>/Fear-of-Falling`.

## Summary
This PR adds canonical K24/K25/K26 scripts and reviewer-facing visualization/reporting updates for the Fear-of-Falling pipeline while keeping generated artifacts out of version control. The analysis chain is documented and reproducible from canonical inputs.

## Included (code/docs only)
- `R-scripts/K24/*.R` (including `K24_TABLE2A.V2_*` and `K24_VIS.V1_*`)
- `R-scripts/K25/*.R` (including `K25_RESULTS.V2_*`)
- `R-scripts/K26/*.R` (including `K26_LMM_MOD.V1_*` and `K26_VIS.V1_*`)
- `README.md`
- `manifest/manifest.csv`
- `tasks/01-ready/*.md`
- `tasks/03-review/*.md`

## Explicitly excluded (no outputs committed)
- No `R-scripts/*/outputs/**` files
- No `.png/.pdf` figures
- No `sessionInfo*.txt`, `*provenance*.txt`, `plot_manifest.txt`
- No `qc_*.csv`
- No run logs (`gate_err.log`, `gate_out.log`, etc.)

## Canonical scripts to use
- K24 table pipeline: `R-scripts/K24/K24_TABLE2A.V2_canonical-delta-by-test-fof-frailty.R`
- K24 visuals: `R-scripts/K24/K24_VIS.V1_forestplots_table2A_cat_vs_score.R`
- K25 results text: `R-scripts/K25/K25_RESULTS.V2_table2A-results-text-canonical.R`
- K26 visuals: `R-scripts/K26/K26_VIS.V1_composite-delta-predicted-plots.R`

## Reproducibility (local/home machine)
Run from repo root:

```bash
cd <REPO_ROOT>/Fear-of-Falling

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

## Reproducibility (Termux + PRoot Debian)
Adjust `<REPO_ROOT>` to your local checkout path.

```bash
export FOF_ROOT="<REPO_ROOT>/Fear-of-Falling"
cd "$FOF_ROOT"

proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin && cd '"$FOF_ROOT"' && /usr/bin/Rscript R-scripts/K24/K24_TABLE2A.V2_canonical-delta-by-test-fof-frailty.R --input R-scripts/K15/outputs/K15_frailty_analysis_data.RData --frailty_mode both --include_balance FALSE'

proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin && cd '"$FOF_ROOT"' && /usr/bin/Rscript R-scripts/K24/K24_VIS.V1_forestplots_table2A_cat_vs_score.R --input R-scripts/K24/outputs/K24_TABLE2A/table2A_cat_vs_score_compare_canonical_v2.csv --audit_input R-scripts/K24/outputs/K24_TABLE2A/table2A_audit_canonical_v2.csv --format both --make_cat_p TRUE --qc_strict FALSE --z_tol 1.96'

proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin && cd '"$FOF_ROOT"' && /usr/bin/Rscript R-scripts/K25/K25_RESULTS.V2_table2A-results-text-canonical.R --input R-scripts/K24/outputs/K24_TABLE2A/table2A_paper_ready_canonical_cat_v2.csv --style both'

proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin && cd '"$FOF_ROOT"' && /usr/bin/Rscript R-scripts/K26/K26_VIS.V1_composite-delta-predicted-plots.R --format both'
```

## QC / provenance checkpoints
- K24 VIS: `R-scripts/K24/outputs/K24_TABLE2A/figures/K24_VIS/plot_manifest.txt`
  - expected: `qc_status=PASS`, `std_method=baseline_sd`, `sd_source=audit`
- K26 VIS: `R-scripts/K26/outputs/K26_VIS/K26_VIS_provenance.txt`
  - expected: `delta_definition=Composite_Z12 - Composite_Z0 (12-month follow-up minus baseline)`
  - expected canonical-source note present (K15/K26 pipeline; no fallback derivation)
- K26 VIS QC: `R-scripts/K26/outputs/K26_VIS/qc_summary.csv`
  - expected: overall `PASS`

## Reviewer signoff checklist (03-review -> 04-done)
- [ ] Run canonical commands (local or Termux/PRoot) and verify successful exits
- [ ] Confirm QC/provenance values at the checkpoints above
- [ ] Confirm outputs are not staged:
  - `git status`
  - `git diff --name-only --cached | grep -E "outputs/|\\.png$|\\.pdf$|qc_|sessionInfo|provenance|plot_manifest" || true`
- [ ] Confirm manifest/task docs updated and consistent with canonical chain
- [ ] Keep tasks in `03-review`; human performs `04-done` move after approval

## Pre-merge verification
- [ ] No outputs committed (`git diff --name-only`)
- [ ] Canonical scripts documented
- [ ] Repro commands verified locally
- [ ] QC checkpoints documented
- [ ] Tasks remain in `03-review`
