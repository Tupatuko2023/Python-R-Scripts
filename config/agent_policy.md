# Agent Policy (Repo-Local)

Tämä tiedosto täydentää SKILLS.md:tä. Jos ristiriitaa: SKILLS.md voittaa.

## Ennen työn aloitusta (MUST)

- Lue `SKILLS.md` ja `config/steering.md`.
- Uutta toteutustehtävää valittaessa varmista, että `tasks/01-ready/` sisältää
  tehtävän. Muuten STOP. Jo hyväksytyn `03-review`-tehtävän tekninen sulkeminen
  ei vaadi ready-tehtävää; tarkista ensin `SKILLS.md`:n riippumaton
  ihmishyväksynnän näyttö.
- Noudata `config/steering.md`: max 5 file change/run, safe mode, approvals required, kielipolitiikka.

## Tehtäväjono (Agent-First)

- Valitse uusi toteutustehtävä vain `tasks/01-ready/`-kansiosta. Hyväksytyn
  `03-review`-tehtävän tekninen `04-done`-sulku on tästä valinnasta erillinen.
- Siirrä uusi toteutustehtävä `tasks/02-in-progress/`-kansioon ennen työn
  aloittamista; hyväksyttyä `03-review`-tehtävää ei palauteta sinne sulkua varten.
- Lokita aikaleimalla jokainen merkittävä toimi.
- Siirrä uusi toteutustehtävä `tasks/03-review/`-kansioon vasta kun DoD on täytetty.

## DoD (analyysirepo)

- Suorita vähintään yksi smoke-run (Rscript/python) aliprojektin ohjeiden mukaan.
- Aja QC-runner, jos repo tarjoaa sellaisen.
- Jos `renv/` on käytössä, varmista `renv::restore()` mahdollisuus ja kirjaa tarvittaessa `sessionInfo()`/`renv::diagnostics()` lokiin.

## Blocker-protokolla

- Jos et voi edetä, kirjaa blocker tehtävään ja pyydä ihmiseltä täsmennys.
