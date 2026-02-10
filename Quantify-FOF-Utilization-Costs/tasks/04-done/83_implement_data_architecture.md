# TASK: Implement Data Architecture for Quantify-FOF (PR #83)

**Status:** IN_PROGRESS
**Assignee:** Gemini (S-QF)
**Branch:** feat/implement-data-architecture-12473190439772066551
**Created:** 2026-02-10

## Context
Jules on luonut datainfrastruktuurin (Option B), joka erottaa raakadatan (DATA_ROOT) ja koodin. Tämä taski kattaa koodikatselmoinnin, smoke-testauksen ja dokumentaation validoinnin ennen mergeä.

## Objectives
1. [x] **Code Review:** Varmista, että `DATA_ROOT` luetaan ympäristömuuttujasta eikä koodissa ole kovakoodattuja polkuja.
2. [ ] **Smoke Test (Synthetic):** Aja `scripts/99_generate_synthetic_raw.py` ja sen jälkeen koko putki synteettisellä datalla.
3. [ ] **Gate Validation:** Varmista, että `outputs/` kansioon syntyy vain sallittuja tiedostoja (ei raakadataa).
4. [ ] **Remote Sync:** Varmista, että kaikki muutokset on pusketettu ennen `04-done` -siirtoa.

## Work Log
- [2026-02-10] Task alustettu. Haara checkattu ulos. Validointi alkaa.
- [2026-02-10] `40_run_secure_panel_analysis.R` tarkistettu:
    - Käyttää `Sys.getenv("RUN_ID")`.
    - `log_msg` funktio oletetaan olevan ladattu aiemmin.
    - Aggregoinnin logiikka näyttää turvalliselta (n<5 suppressio mainittu kommenteissa, varmistettava ajossa).
- [2026-02-10] Smoke Test (Synthetic) suoritettu:
    - `scripts/99_generate_synthetic_raw.py` päivitetty kattamaan kaikki vaaditut sarakkeet.
    - `R/30_models_panel_nb_gamma.R` päivitetty sallimaan `BOOTSTRAP_B` ympäristömuuttujan käyttö.
    - Pipeline ajettu onnistuneesti `BOOTSTRAP_B=2` ja `ALLOW_AGGREGATES=1` asetuksilla.
- [2026-02-10] Gate Validation: Varmistettu, että `outputs/archive/` sisältää vain aggregoidut tulokset.

## Definition of Done (DoD)
- [x] `python -m unittest` menee läpi.
- [x] Synteettinen ajo tuottaa `outputs/qc_summary.csv` (tai vastaavat) ilman virheitä.
- [x] Ei raakadataa git-status listauksessa.

