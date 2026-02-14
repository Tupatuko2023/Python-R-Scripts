# TASK: Hospital Outcome Definition Reconciliation (Aim 2)

**Status:** READY
**Priority:** CRITICAL
**Context:** Path A selected. Strict replication required.
**Reference:** `docs/reports/2026-02-10_hospital_outcome_reconciliation.md`

## Objectives
1. [ ] **Discover the Definition:** Selvitä, millä logiikalla/tiedostolla päästään lukuun ~378 episodes/1000PY (nykyinen 62).
2. [ ] **Update Schema:** Päivitä `ingest_config.yaml` ja `01_ingest.R` vastaamaan löydöstä.
    * *Vihje:* Todennäköisin syy on puuttuva merge `episodefile` ja `dxfile` välillä (injury-diagnoosien poimimiseksi).
3. [ ] **Verify:** Aja QC ja varmista, että luvut täsmäävät käsikirjoitukseen.

## Execution Guide (Secure)
1.  Luo väliaikainen tutkimusskripti `scripts/debug_hospital_reconciliation.R`.
2.  Käytä `common.R` datan lataukseen.
3.  Tutki `DATA_ROOT`:n sisältöä: onko siellä tiedostoja, joita ei ole ingestoitu?
4.  Testaa merge: `episode` + `dx`.
5.  Raportoi löydökset ja päivitä konfiguraatio.

## Acceptance Criteria
- Hospital Episodes count match manuscript (approx 378/1000PY).
- No hardcoded paths.
- `ingest_config.yaml` updated.
