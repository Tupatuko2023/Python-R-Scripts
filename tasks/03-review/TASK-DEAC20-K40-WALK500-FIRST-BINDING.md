# DEAC20: 500 m kävelyvaikeuden rajattu lähdesidonta

## Context

Yksityinen, hash-varmennettu toimeksianto rajaa ensimmäisen komponentin
lähdesidonnan. Nykyinen komponenttipisteyttäjä kattaa pisteytettävät luokat;
tehtävä lisää tarvittaessa vain yhden komponentin eristetyn sidonnan ja
synteettisen varmennuksen. Lähteen tarkka skeema ja koodiselite pysyvät
erillisessä yksityisessä toimituksessa. Tämä kortti ei hyväksy menetelmää,
tuotantoajoa eikä AIM1-kohderepon julkaisua.

## Inputs

- PRS:n nykyinen `deac_components.py` ja `deac_source_adapter.py`.
- Erikseen toimitettu yksityinen, vain metadataa sisältävä lähdepaketti.
- Ihmisomistajan 20.11.2026 antama rajattu toteutusvaltuutus.

## Outputs

- Yhden 500 m -komponentin lähdesidottu, synteettisesti testattava tulos.
- Yksityinen täsmäskeeman ja koodiselitteen tarkastusraportti.
- Päivitetty `PRJ-AIM1-REPO`-tilanne ja generoitu rekisterin CSV.

## Sallitut kirjoituspolut

- `tasks/01-ready/TASK-DEAC20-K40-WALK500-FIRST-BINDING.md` →
  `tasks/02-in-progress/` → `tasks/03-review/` saman tiedostonimen alla.
- `DEAC-Frailty-Index/src/deac_source_adapter.py` vain todettuun rajapinta-aukkoon.
- `tests/test_deac_source_adapter.py` vain synteettisiin yleisiin testeihin.
- `docs/governance/project_registry/PRJ-AIM1-REPO.md`.
- `tools/project_registry/outputs/projects.csv` vain ignoroituna johdannaisena.

Yksityinen täsmäsidonta ja raportti kirjoitetaan vain toimeksiannon nimeämään
Git-ignoroituun yksityiseen tuloshakemistoon. Muita seurattuja polkuja ei muuteta.

## Definition of Done (DoD)

- Lähdemetadata varmennettu ilman osallistujarivejä.
- Pisteyttäjä käytetään muuttumattomana; dokumentoimaton koodi ja väärä
  lähdesidonta hylätään, lähteen puuttuvuus käsitellään ennen pisteytystä.
- Rajatut synteettiset testit ja yksi smoke-ajo suoritettu; tulokset kirjattu.
- Julkinen diff sisältää vain yleisen koodin, synteettiset testit ja
  hallintadokumentaation. Yksityiset lähdetekstit ja polut pysyvät ulkona.
- Rekisteri ja CSV validoitu. Tehtävä siirretään katselmointiin, ei `04-done`.

## Log

- 2026-11-20T20:17:15+02:00 Tehtäväkortti luotu ihmisomistajan valtuuttamana;
  toimeksiannon SHA-256 ja suojatun metadatalähteen tiivisteet varmennettu.
- 2026-11-20T20:17:58+02:00 Kortti siirretty `02-in-progress`-tilaan;
  `tools/run-gates.sh --mode pre-push --smoke` läpäisi ja rekisterin
  kirjoitussuoja palautti `OK`.
- 2026-11-20T20:24:49+02:00 Yhden komponentin lähdesidonta lisätty
  olemassa olevan pisteyttäjän eteen. Yksityinen metadata- ja
  täsmäkoodistotarkistus läpäisi 16/16 synteettistä tapausta; alkuperäisen
  `tests/test_deac_source_adapter.py`-tiedoston rajattu ajo läpäisi 70/70
  testiä eristetyssä Python 3.14.6 / pytest 9.1.1 -ympäristössä.
  `git diff --check`, Python-käännös sekä repoportin smoke-tarkistus läpäisivät.
  Testiriippuvuudet asennettiin vain paikallisesta välimuistista `--offline`.
  Osallistujarivejä ei luettu, eikä indeksikokoajaa tai pisteyttäjää muutettu.
- 2026-11-20T20:25:47+02:00 Kortti siirretty `03-review`-tilaan
  teknisen toteutuksen ja rajattujen testien valmistuttua.
  Ihmisomistajan sisältöhyväksyntä ja mahdollinen PR-toimitus odottavat;
  tätä korttia ei siirretty `04-done`-tilaan.

## Blockers

- Menetelmän nykyinen §3.1-auktoriteetti ja AIM1-kohderepon julkaisuvaltuutus
  pysyvät erillisinä avoimina asioina; ne eivät estä tätä paikallista
  synteettistä teknistä tehtävää.

## Links

- `docs/governance/project_registry/PRJ-AIM1-REPO.md`
