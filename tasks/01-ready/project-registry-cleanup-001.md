# Projektirekisterihankkeen rajattu siivouskirjaus

## State

- State: `01-ready`
- Tunniste: `project-registry-cleanup-001`
- Repo: Tupatuko2023/Python-R-Scripts
- Haara: chore/project-registry-cleanup-001
- Säilyvä toimitusworktree: tmp/project-registry-transfer-001.
- Pohja: c6b4953bdfe41aa85e07f667b2280d215f85c789.

## Context

Owner valtuutti tässä keskustelussa vain tämän hankkeen varmennettujen,
puhtaiden ja kokonaan toimitettujen worktreeiden ja paikallisten tehtävähaarojen
poistot ilman pakotusta sekä pilotin totuudenmukaisen siivouskirjauksen
commitit, pushin, PR:n ja toimituksen. Epäselvät kohteet säilytetään.
Päächeckouteja, muiden töitä tai etähaaroja ei muuteta. #12/#14–16 pysyvät avoimina.

## Inputs

AGENTS, SKILLS, steering, kontribuutioskill, molempien repoiden worktree-
ja haara-inventaariot, Git-tilat (myös ignored), DONE-kortit, PR:n HEAD/merge-
provenance sekä mainin Git-puu-/blob-vertailut squash-toimituksia varten.

## Outputs

- docs/governance/project_registry/PRJ-REGISTRY-ROLLOUT.md: vain toteutuneisiin
  poistoihin perustuva siivoushavainto ja säilytettyjen kohteiden syyt.
- Tämä uusi kortti; vanhoja DONE-tehtäviä ei avata uudelleen.

Viiden polun raja: valmistelu yksi polku, admission kaksi; toteutus pilotin
päivitys ja in-progress/review-korttipolut kolme. Poistot rajataan varmennettuun
Git-worktree-rekisteriin; ei manuaalisia hakemistopoistoja tai force-lippuja.

## Definition of Done (DoD)

- Omistajuus osoitettu tehtävillä ja toimituksilla, ei hakemistonimellä.
- Aiemmat tuotokset ja DONE-kortit mainissa, squash huomioitu puu-/blob-näytöllä.
- Ennen poistoa puhdas index/työpuu, ei säilytettäviä untracked/ignored-artefakteja,
  eikä muuta aktiivista tehtävää/agenttia. Epäselvät kohteet säilytetään syineen.
- Vain git worktree remove ja git branch -d, ei forcea tai etähaarojen poistoja.
- Pilotin CSV validoitu, main-toimitus erillään todellisesta worktree-tilasta.
- Soveltuvat portit ja CI läpäisevät; siivouskirjaus toimitettu valtuutuksen mukaan.
- Tämä kirjaustehtävä pysyy review-tilassa erillistä ihmisen sulkemishyväksyntää
  varten; sen toimitus ei väitä Ownerin antaneen taskin DONE-hyväksyntää.

## Log

- 2026-11-03: Inventaariot ja toimitukset tarkistettu. SKR1-maintenance on eri
  keskeneräinen tehtävä, se säilytetään. Baseline- ja transfer-worktreissä
  ignored Quantify-artefakteja/CI-näyttöä: säilytetään. Paikallisen sovituksen
  d9004251 on PR #216:n commit-listassa; pycache on uudelleen muodostettava.

## Blockers

Säilytettävät ignored-artefaktit estävät vain kyseisten worktreeiden poiston.

## Links

- Pilotti: docs/governance/project_registry/PRJ-REGISTRY-ROLLOUT.md
- Käyttöönotto: tasks/04-done/project-registry-rollout-001.md
