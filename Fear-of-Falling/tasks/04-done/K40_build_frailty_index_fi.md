# K40 Build Frailty Index (FI) Vulnerability Score (Analysis Repo)

## Context

This K40 is an analysis-repository R implementation task in `Fear-of-Falling` (`R-scripts/K40/k40.r`).
It is explicitly not a dissertation-repository writing task.

Rationale for K40: K39 CFA latent path produced inadmissible latent scores by gate in this dataset, so K40 adopts a deterministic Frailty Index (FI = proportion of deficits) pathway.

Task-gate status: implementation has been completed in `tasks/02-in-progress/` and this card is ready for `tasks/03-review/`.

## Objective

Create a deterministic, governance-safe FI pipeline that builds a continuous Frailty/Vulnerability measure from non-performance deficits, explicitly excluding performance tests and primary exposures, with patient-level outputs externalized under `${DATA_ROOT}` and repository outputs aggregate-only.

## Inputs

- Required external inputs from `${DATA_ROOT}` only:
  `${DATA_ROOT}/paper_01/analysis/` (K33 canonical analysis datasets; key source for `id` and baseline analysis context).
- Optional external inputs:
  `${DATA_ROOT}/paper_01/capacity_scores/` (K32 capacity score for correlation diagnostics only),
  `${DATA_ROOT}/paper_01/frailty/` (K15 frailty outputs for comparison diagnostics only).
- Repo references:
  `data/data_dictionary.csv`, `data/Muuttujasanakirja.md`, `manifest/manifest.csv`, `config/.env`.

## Scope

- Implemented file: `R-scripts/K40/k40.r`.
- Require `DATA_ROOT`; stop with informative error if missing.
- Candidate discovery:
  clean names, create full column inventory, and evaluate candidate deficit variables deterministically.
- Hard exclusion rules (must never be FI deficits):
  performance indicators by regex:
  `puristus|grip|kavely|gait|tuoli|chair|seisom|single_leg|balance|sls`;
  Composite_Z components/outcomes (`Composite_Z*` and identifiable components);
  primary exposures: `FOF_status`, `kaatumisenpelkoOn`, `tasapainovaikeus`.
- Deterministic screening rules:
  primary missingness threshold `p_miss <= 0.20`;
  deterministic sensitivity branch `p_miss <= 0.30` only if primary branch yields fewer than 10 eligible deficits;
  no other missingness thresholding is allowed;
  binary prevalence bounds `0.01 <= prevalence <= 0.80`;
  ordinal requires at least 3 observed levels (or pre-justified 0/0.5/1 mapping rule documented in codebook-driven branch).
- Deterministic scoring rules:
  binary deficits mapped 0/1 as coded;
  ordinal deficits mapped to `[0,1]` by rank;
  continuous included only with pre-defined, codebook-justified clinical threshold direction; otherwise excluded (no data-driven threshold search).
  direction harmonization is allowed only when justified by codebook/documented coding lineage;
  correlation-driven sign flipping is explicitly prohibited.
- Deterministic redundancy rule (anti-double-counting):
  if multiple indicators represent the same domain (diagnosis vs functional limitation vs symptom vs medication proxy),
  retain one variable by fixed priority order:
  diagnosis/doctor-confirmed > functional limitation > symptom/self-report > medication proxy.
- FI computation:
  FI is row-wise mean of selected deficits in 0-1 scale (proportion of deficits);
  fixed minimum data rule: compute FI only if at least 60% of selected deficits are observed and observed deficit count is at least `N_deficits_min = 10`;
  deterministic handling: rows failing either threshold receive `FI = NA`, and failure counts are reported as red flags;
  derive `FI_z = scale(FI)` for modeling interpretability (secondary derivative of FI, not a separate construct).
- Data joins:
  deterministic join to K33 analysis dataset by `id`;
  optional join to K32 capacity score strictly for correlation diagnostics.
- Governance:
  patient-level outputs only to `${DATA_ROOT}/paper_01/frailty_vulnerability/`;
  repo stores only aggregate diagnostics, decision logs, session info, and export receipt.
- Keep model formulas in `docs/ANALYSIS_PLAN.md` unchanged in K40.

## Proposed Minimal Implementation (When 01-ready)

1. Resolve `DATA_ROOT` from environment / `config/.env`; resolve K33/K32/K15 paths.
2. Load K33 baseline-relevant patient table keyed by `id`.
3. Build candidate inventory and apply hard exclusions with reason tracking.
4. Apply deterministic screening:
   primary `p_miss <= 0.20`; if eligible deficits `< 10`, run deterministic sensitivity branch `p_miss <= 0.30`.
5. Build scored deficit matrix (0-1) with deterministic direction/scale rules.
6. Apply redundancy de-duplication by fixed priority order per domain.
7. Compute FI eligibility (`>=60%` observed and `N_deficits_min = 10`), compute FI (0-1), and derive `FI_z`.
8. Produce aggregate artifacts and append manifest rows.
9. Export patient-level FI dataset only under `${DATA_ROOT}/paper_01/frailty_vulnerability/` (CSV + RDS).
10. Write receipt in repo with path, md5, nrow, ncol.
11. Run validation gates (`K18` QC summarizer + `../tools/run-gates.sh --mode analysis --project Fear-of-Falling`) and leak-check.

## Outputs

- Repo aggregate outputs under `R-scripts/K40/outputs/` only:
  `k40_candidate_inventory.csv`,
  `k40_excluded_vars.csv`,
  `k40_selected_deficits.csv`,
  `k40_deficit_missingness_prevalence.csv`,
  `k40_fi_distribution_summary.csv` (must include FI and FI_z summaries),
  `k40_fi_vs_compositez_correlation.csv`,
  `k40_fi_vs_capacity_correlation.csv`,
  `k40_red_flags.csv`,
  `k40_decision_log.txt`,
  `k40_sessioninfo.txt`,
  `k40_patient_level_output_receipt.txt`.
- External patient-level outputs only:
  `${DATA_ROOT}/paper_01/frailty_vulnerability/kaatumisenpelko_with_frailty_index_k40.csv`,
  `${DATA_ROOT}/paper_01/frailty_vulnerability/kaatumisenpelko_with_frailty_index_k40.rds`.
- Manifest:
  append one row per repo artifact to `manifest/manifest.csv`.

## Reproduction Commands

`[TERMUX]`

```sh
cd Python-R-Scripts/Fear-of-Falling
ls -la tasks
ls -la tasks/00-backlog
test -f tasks/_template.md && echo "template: FOUND" || echo "template: MISSING"
set -a && . config/.env && set +a && echo "DATA_ROOT=$DATA_ROOT"
```

`[PROOT:DEBIAN]`

```sh
# Backlog-only stage: no proot commands required.
# Implementation stage (later, when moved to 01-ready):
# proot-distro login debian --termux-home -- bash -lc 'cd Python-R-Scripts/Fear-of-Falling && ...'
```

## Acceptance Criteria

- `tasks/00-backlog/K40_build_frailty_index_fi.md` exists and clearly states K40 is analysis-repo R work (not dissertation writing).
- Card explicitly bans performance indicators and primary exposures (`FOF_status`, `kaatumisenpelkoOn`, `tasapainovaikeus`) from FI deficit list.
- Card defines deterministic FI screening/scoring rules:
  fixed rules include:
  `N_deficits_min = 10`, `>=60%` observed coverage,
  primary `p_miss <= 0.20` and sensitivity `p_miss <= 0.30` only when primary eligible deficits `< 10`,
  no correlation-driven direction flipping,
  redundancy de-duplication with fixed priority order,
  FI in 0-1 plus derived FI_z reporting.
- Card defines aggregate-only repo artifacts plus external-only patient-level export and receipt requirements including md5/nrow/ncol.
- Card defines implementation-stage validation expectations:
  QC pass, run-gates pass, leak-check pass.
- No `R-scripts/K40/k40.r` implementation is created at backlog stage.

## Definition of Done (DoD)

- `R-scripts/K40/k40.r` runs end-to-end in Debian proot with `DATA_ROOT` loaded.
- Aggregate-only repo outputs are written under `R-scripts/K40/outputs/` and logged in `manifest/manifest.csv`.
- Patient-level outputs are externalized only under `${DATA_ROOT}/paper_01/frailty_vulnerability/`.
- Receipt contains external paths, md5, and nrow/ncol.
- QC summarizer and run-gates analysis checks pass.

## Log

- 2026-03-02 18:16:53 created K40 backlog card from template for deterministic FI pathway after K39 latent inadmissibility
- 2026-03-02 18:20:28 added reviewer-proof deterministic refinements (fixed N_deficits_min, missingness sensitivity branch, codebook-only direction rule, redundancy priority, FI_z reporting)
- 2026-03-02 19:10:44 moved K40 card to `tasks/02-in-progress/` and created `R-scripts/K40/k40.r`.
- 2026-03-02 19:24:26 first proot end-to-end run passed but selected deficit pool was too small (2); improved optional K15 join logic.
- 2026-03-02 19:26:47 reran K40 in proot with K15-enriched candidate pool; selected deficits=60, FI coverage gate passed for 274/276 rows.
- 2026-03-02 19:27:42 external output check PASS:
  `${DATA_ROOT}/paper_01/frailty_vulnerability/kaatumisenpelko_with_frailty_index_k40.csv` and `.rds` exist;
  md5 csv=`cc29b3d6e08a213152bf8c540c2460a1`, md5 rds=`5b571b3e4b0885229c3a4a3bf82cdc23`.
- 2026-03-02 19:28:04 validation checks PASS:
  `bash scripts/termux/run_qc_summarizer_proot.sh` (exit 0),
  `bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling` (exit 0),
  leak-check found no patient-level CSV dumps in `R-scripts/K40/outputs/`.
- 2026-03-02 19:41:33 compliance correction + rerun:
  tightened exclusions to prevent primary exposures and derived frailty constructs from entering FI deficits
  (`fof_status*`, `kaatumisenpelko*`, `tasapainovaikeus*`, `frailty_*`, `fi*`);
  reran `R-scripts/K40/k40.r` in proot (exit 0),
  selected deficits after deterministic filtering = 34,
  red flags now show `rows_below_coverage_or_min_deficits=0`,
  updated external md5 csv=`3a82e4b165e463dd3223370f1eb0be84`,
  rds=`f37e6d84cfc93b466c4cd207cb363fb5`.

## Blockers

- None currently. Card is ready for human review in `tasks/03-review/`.

## Links

- Prior step in review: `tasks/03-review/K39_build_frailty_vulnerability_latent.md`
