# K26/K15 verification: RData requirement and frailty_cat_3 provenance

## Context
Varmennetaan repo-lähdekoodista väite: K26 hyväksyy vain .RData/.rda syötteen,
käyttää oletuksena/suosituksena K15-tuotosta, vaatii cat-modessa valmiin
frailty_cat_3-sarakkeen (ei johda sitä K26:ssa), normalisoi vain tasot, ja
hyväksyy edge-casena myös ei-K15 RData:n jos required columns -ehto täyttyy.

## Inputs
- `R-scripts/K26/K26_LMM_MOD*.R`
- `R-scripts/K15/K15*.R`
- `R/functions/io.R` (tarvittaessa)
- Repo-wide grep: `frailty_cat_3`, `frailty_count_3`,
  `normalize_frailty_cat`, `K15_frailty_analysis_data.RData`

## Outputs
- Päivitetty tehtäväraportti `<report>...</report>`-rakenteella sisältäen:
  - verdict (YES/NO/PARTIAL)
  - confidence
  - key_findings
  - evidence (väh. 5 path+line citationia)
  - risks_and_edge_cases
  - conclusion_one_liner
- Tehtävän siirto `01-ready -> 02-in-progress -> 03-review` kun suoritus alkaa.

## Definition of Done (DoD)
- Raportti erottaa eksplisiittisesti REQUIRED vs DEFAULT/RECOMMENDED K26-käytöksen.
- Raportissa on repo-wide grep -todisteet pyydetyistä avainsanoista.
- Raportissa vahvistetaan onko K26:ssa frailty_cat_3-derivointia (odotus: ei).
- Raportissa on line-range-viitteet K26 input enforcementiin,
  load_rdata_input valintaan, normalize_frailty_cat-toimintaan,
  K15 frailty_cat_3 derivointiin ja K15 save()-outputtiin.

## Log
- 2026-02-26 16:02:00 Created from template in `tasks/00-backlog/`.
- 2026-02-26 16:02:00 Blocked by workflow gate: task not yet in `tasks/01-ready/`.
- 2026-02-26 19:38:00 Moved to `tasks/02-in-progress/` and verification started.
- 2026-02-26 19:45:00 Evidence collection complete (K26/K15 line-citations + repo-wide grep).

## Blockers
- Ei aktiivisia blokkereita.

## Links
- `tasks/01-ready/K26_K15_verify_rdata_and_frailtycat_claim.md`

<report>
<verdict value="YES"/>
<confidence value="high"/>
<key_findings>
- REQUIRED by K26: input extension must be `.RData/.rda`; `.csv/.txt` and other extensions are explicitly stopped.
- DEFAULT/RECOMMENDED by K26: default input path points to `R-scripts/K15/outputs/K15_frailty_analysis_data.RData`, with fallback checks to both `K15` and `K15_MAIN` outputs.
- K26 cat-mode requires existing `frailty_cat_3`; score-mode requires existing `frailty_score_3`; missing mappings cause `stop(...)`.
- K26 does not derive `frailty_cat_3` from `frailty_count_3` or other proxies; it only normalizes provided `frailty_cat_3` values via `normalize_frailty_cat()`.
- Edge case confirmed: K26 accepts non-K15 RData when it contains any data.frame/tibble satisfying `has_required(...)` predicate; object `analysis_data` is preferred but not mandatory.
- K15 canonical production chain exists: `frailty_count_3_A -> frailty_cat_3_A -> aliases frailty_count_3/frailty_cat_3`, plus `save(analysis_data, ...K15_frailty_analysis_data.RData)`.
</key_findings>
<evidence>
- K26 default + fallback input path (DEFAULT/RECOMMENDED): `R-scripts/K26/K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R:93-122`
  - `parse_cli()` default input is `R-scripts/K15/outputs/K15_frailty_analysis_data.RData` (line 95).
  - `choose_input_path()` candidates include K15 and K15_MAIN output paths (lines 112-116).
- K26 extension enforcement (REQUIRED): `R-scripts/K26/K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R:431-439`
  - explicit stop for csv/txt (lines 434-435)
  - explicit stop for non-rdata/rda (lines 437-438)
- K26 load_rdata_input object selection + required predicate (REQUIRED): `R-scripts/K26/K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R:124-164`
  - prefers `analysis_data` if data.frame/tibble (lines 128-133)
  - otherwise finds first matching data.frame/tibble via `has_required()` (lines 135-149, 163)
  - required columns include `frailty_cat_3` and `frailty_score_3` (line 144; message lines 156-158)
- K26 frailty requirements + normalization-only behavior: `R-scripts/K26/K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R:193-202, 451-491`
  - `normalize_frailty_cat()` only recodes existing labels to factor levels Robust/Pre-frail/Frail (lines 193-202)
  - cat/score mappings are canonical-only (`frailty_cat_3`, `frailty_score_3`) (lines 451-452)
  - cat/score missing checks stop execution (lines 463-467, 487-491)
- K15 derivation + aliasing + save output: `R-scripts/K15/K15.R:433-448, 752-765`
  - `frailty_count_3_A` is computed then `frailty_cat_3_A` is derived via case logic 0/1/>=2 (lines 433-441)
  - aliases set `frailty_count_3 = frailty_count_3_A` and `frailty_cat_3 = frailty_cat_3_A` (lines 447-448)
  - K15 saves `analysis_data` to `R-scripts/K15/outputs/K15_frailty_analysis_data.RData` (lines 763-765)
- Repo-wide grep summaries:
  - `frailty_cat_3` appears in producer scripts (`K15`, `K15_MAIN`) and many consumer scripts (`K16`, `K17`, `K18`, `K24`, `K26`, `K27`, `K28`); confirms canonical naming propagation.
  - `K15_frailty_analysis_data.RData` references show writer in `K15/K15.R` and readers including `K16`, `K18`, `K21`, `K24`, `K26`, `K28`.
  - `frailty_count_3` chain appears in K15 derivation and downstream fallback logic in older scripts, but K26 canonical script itself has no `frailty_count_3` mapping path.
  - `normalize_frailty_cat` appears in K26/K24 visualization/analysis scripts as a label-normalizer function; no producer derivation semantics there.
- Absence check for K26 derivation: `rg -n "frailty_count_3|frailty_cat_3_A|frailty_cat_3_B|case_when\\(.*frailty_cat_3" R-scripts/K26/K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R` returned no hits.
</evidence>
<risks_and_edge_cases>
- REQUIRED vs DEFAULT distinction is critical: K26 recommends K15 output path, but code allows any RData source if required columns predicate is satisfied.
- `load_rdata_input()` selects the first matching data.frame/tibble (`matching[1]`), so multi-object RData files can be order-sensitive; still valid per current predicate logic.
- K26 canonical script is strict on frailty columns (`frailty_cat_3` / `frailty_score_3`) and will stop even if alternative naming exists.
</risks_and_edge_cases>
<conclusion_one_liner>Kyllä: K26 vaatii .RData/.rda ja käyttää valmiiksi syötteessä olevaa frailty_cat_3:ta (vain normalisoi tasot), ei johda sitä K26:ssa; K15 tuottaa ja tallentaa kanonisen frailty_cat_3-ketjun, ja ei-K15 RData hyväksytään jos required columns täyttyvät.</conclusion_one_liner>
</report>
