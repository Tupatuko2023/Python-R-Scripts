# Agent Policy (Repo-Local)

Tämä tiedosto täydentää SKILLS.md:tä. Jos ristiriitaa: SKILLS.md voittaa.

## Ennen työn aloitusta (MUST)
- Lue `SKILLS.md` ja `config/steering.md`.
- Varmista, että `tasks/01-ready/` sisältää tehtävän. Muuten STOP.
- Noudata `config/steering.md`: max 5 file change/run, safe mode, approvals required, kielipolitiikka.

## Tehtäväjono (Agent-First)
- Valitse vain `tasks/01-ready/`.
- Siirrä `tasks/02-in-progress/` ennen työn aloittamista.
- Lokita aikaleimalla jokainen merkittävä toimi.
- Siirrä `tasks/03-review/` vasta kun DoD on täytetty.

## DoD (analyysirepo)
- Suorita vähintään yksi smoke-run (Rscript/python) aliprojektin ohjeiden mukaan.
- Aja QC-runner, jos repo tarjoaa sellaisen.
- Jos `renv/` on käytössä, varmista `renv::restore()` mahdollisuus ja kirjaa tarvittaessa `sessionInfo()`/`renv::diagnostics()` lokiin.

## Blocker-protokolla
- Jos et voi edetä, kirjaa blocker tehtävään ja pyydä ihmiseltä täsmennys.
