# Projektirekisterihankkeen rajattu siivouskirjaus

## State

- State: `03-review`
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

- 2026-11-03: READY löydetty ja Git-näkyvyys varmennettu erillisessä admission-työosuudessa; in-progress ennen siivouskirjausta.

## Toteutuneet siivoustoimet 2026-11-03

Poistettu tavallisella git worktree remove -komennolla, ei forcea:
- FOF: duplicate-keys, safe-export, directory-alias ja validation -worktreet
  C:/GitWork/fof-project-registry-<nimike>-001.
- Python-R-Scripts: tmp/project-registry-local-adaptation-001 ja
  tmp/project-registry-rollout-001.

Kaikista ennen poistoa status/index/untracked puhdas. Lähderepon neljässä ei
ignored-tiedostoja. Paikallissovituksessa vain kaksi uudelleen muodostettavaa
pyc-tiedostoa; rolloutissa vain validoitu/regeneroitava projects.csv (--check PASS).
Worktree-rekisteristä ja levyltä poissaolo tarkistetaan lopuksi. Kohteisiin
viittaavia erillisiä Python/Codex/Node/Bash/Git-prosesseja ei löydetty.

Source duplicate/safe/alias: HEAD mainin esi-isä ja DONE-kortti identtinen.
Source validation PR #349/#350/#351 sekä target rollout #219/#220: kokonaiset
Git-puut identtiset squash-mergeihin, jotka sisältyvät origin/mainiin.
Target transfer #216:n koko puu eroaa unrelated-main-pohjamuutoksista, mutta
kaikki neljä taskin tuoteblobia täsmäävät. #218 DONE-blobi täsmää mainiin.
Paikallissovituksen d9004251 ja baseline ce44996 ovat toimitetun PR #216:n
commit-listassa. Pelkkää commit-lukumäärää tai hakemistonimeä ei käytetty näyttönä.

Poistettu git branch -d:llä 8 haaraa (neljä per repo), nimet pilotin taulukon
jälkeisessä luettelossa. 3 vanhaa haaraa säilytetty normaalin -d:n kieltäydyttyä;
upstreamia, reflog-evidenssiä tai force-lippuja ei käytetty suojan ohittamiseen.

Säilytetty baseline (21 ignored-tiedostoa) ja transfer (1606 ignored-tiedostoa):
Quantifyn paikalliset tulokset ja manifesti, transferissa lisäksi CI-näyttö ja
Markdown-riippuvuudet. Ei niiden sisällön siirtoa, julkaisua tai poistoa.
FOF SKR1-maintenance-002 on eri, aktiivinen/likainen tehtävä; ei scopea.

Tämä task pysyy review-tilassa, kun kirjauksen portit/CI täyttyvät. Sen
DONE-siirrolle ei ole erillistä pysyvää ihmisomistajan hyväksyntää. Valtuutettu
siivouskirjaus voidaan toimittaa mainiin; main-toimitus ei ole taskin hyväksyntä.

- 2026-11-03: Kuuden poiston levy-/rekisterivarmennus PASS. CSV toimitus=delivered,
  siivous=retained, lähdekuvaus ennallaan. Markdown ja --check PASS. Kirjaus reviewiin;
  lopullisen HEADin CI ja julkaisu seurataan samalla Owner-valtuutuksella.
