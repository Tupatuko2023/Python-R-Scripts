# Työpuiden ja paikallisten tehtävähaarojen rajattu siivous

## Context

- Tila: `READY`
- Tehtävätunnus: `worktree-cleanup-001`
- Omistaja: Tomi Korpi (`Tupatuko2023`)
- Orkestroija: `FCPO2`
- Repo: `Tupatuko2023/Python-R-Scripts`
- Projektitietue: Ei uutta `PRJ-*`-tietuetta (`docs/governance/project_registry/README.md`: yksittäinen siivoustehtävä toteutetaan pelkällä `TASK`-kortilla; olemassa olevien suljettujen projektien `PRJ-REGISTRY-ROLLOUT`, `PRJ-PROJECT-WRITE-SCOPE-POLICY` ja `PRJ-WORKFLOW-GUIDANCE-ALIGNMENT` worktree-taulukot päivitetään vain toteutuneiden poistojen osalta).
- Varmennettu lähtörevisio (`origin/main`): `b12155dd760e86bc0077d0ad966fc5ee08c0c135`
- Eristetty väliaikainen siivoustyöpuu ja haara: `tmp/worktree-cleanup-001` / `chore/worktree-cleanup-001`
- Tavoite: Poistetaan Ownerin 2026-11-19 hyväksymässä rajauksessa yksilöidyt 8 toimitettua ja tarkistettua työpuuta sekä 11 toimitettua paikallista tehtävähaaraa ilman pakotusta (`--force` tai `-D`), säilyttäen etähaarat, päächeckout paikallisine töineen, `tmp/deac-fira1-bootstrap` sekä kaikki muut säilytettäviksi merkityt työpuut, ja kirjataan vain toteutuneet poistot.
- Hyväksytyt operaatiot ja toimitusraja (`SKILLS.md`):
  - eristetyn `tmp/worktree-cleanup-001`-työpuun perustaminen varmennetusta `origin/main`ista (`b12155dd760e86bc0077d0ad966fc5ee08c0c135`) ja `npm ci` vain tässä työpuussa lukitustiedoston mukaisesti;
  - 8 nimetyn työpuun ja niissä yksilöityjen regeneroitavien `node_modules`-hakemistojen poisto sekä 11 nimetyn paikallisen haaran poisto (`git worktree remove`, `git branch -d`) jokaisen kohteen ennakkotarkistusten täytyttyä;
  - toteutuneiden poistojen kirjaus tähän tehtäväkorttiin ja 3 nimettyyn `PRJ-*.md`-tietueeseen, `projects.csv`-generointi, soveltuvat porttitarkistukset, kohdistetut commitit, `git push` ja PR-katselmointiin (`03-review`) saattaminen ilman välikuittauksia;
  - kunkin PR:n (`03-review` ja `04-done`-sulku-PR) täsmärevision pysyvä riippumaton ihmishyväksyntä varmennetaan ennen mergeä;
  - hyväksytyn `04-done`-sulku-PR:n `origin/main`-toimituksen jälkeen tämän tehtävän oman `tmp/worktree-cleanup-001`-työpuun ja sen tehtäväkohtaisten paikallisten haarojen loppusiivous samoilla tarkistuksilla, kirjaamalla poistonäyttö sulku-PR:n kommenttiin ja loppuraporttiin ilman uutta siivouskorttia tai PR-ketjua.

## Inputs

- Ajantasaiset `SKILLS.md`, `WORKFLOW.md`, `AGENTS.md`, `config/steering.md` ja `docs/governance/project_registry/README.md` (`origin/main` `b12155dd760e86bc0077d0ad966fc5ee08c0c135`).
- Nykyiset rekisteritietueet:
  - `docs/governance/project_registry/PRJ-REGISTRY-ROLLOUT.md`
  - `docs/governance/project_registry/PRJ-PROJECT-WRITE-SCOPE-POLICY.md`
  - `docs/governance/project_registry/PRJ-WORKFLOW-GUIDANCE-ALIGNMENT.md`
- 2026-11-19 suoritettu 15 työpuun read-only-inventaario (`git worktree list --porcelain`, GitHub PR- ja puu-/blob-vertailut) sekä Ownerin nimetty siivousvaltuutus.

## Outputs

- Sallitut seuratut kirjoituspolut (repojuureen suhteutettuina):
  - `tasks/01-ready/worktree-cleanup-001.md`
  - `tasks/02-in-progress/worktree-cleanup-001.md`
  - `tasks/03-review/worktree-cleanup-001.md`
  - `tasks/04-done/worktree-cleanup-001.md` (vasta sisältö-PR:n pysyvän ihmishyväksynnän ja `origin/main`-toimituksen jälkeen)
  - `docs/governance/project_registry/PRJ-REGISTRY-ROLLOUT.md`
  - `docs/governance/project_registry/PRJ-PROJECT-WRITE-SCOPE-POLICY.md`
  - `docs/governance/project_registry/PRJ-WORKFLOW-GUIDANCE-ALIGNMENT.md`
- Sallitut paikalliset `gitignored`-tulokset (ei commitoida):
  - `tools/project_registry/outputs/projects.csv` (sekä generaattorin atomisen julkaisun väliaikaistiedostot)
- Rajauksen ulkopuoliset toimet: uuden `PRJ-*`-tietueen luonti, vanhojen `DONE`-korttien avaaminen, etähaarojen poisto, `--force`- tai `git branch -D` -käyttö, `git clean` -massasiivous, `tmp/`-kansion yleinen tyhjennys sekä päächeckoutin, `tmp/deac-fira1-bootstrap`:n tai muiden säilytettävien työpuiden muuttaminen.

## Definition of Done (DoD)

- [ ] Ennen jokaista poistoa on varmennettu nykyinen `origin/main`, kohteen toimitus siihen (ml. squash-mergen PR-revisio ja puu-/sisältövertailu), kuuluminen `Tupatuko2023/Python-R-Scripts`-repoon sekä tracked/staged/untracked/ignored-sisältö ja käyttämättömyys.
- [ ] Vain hyväksytyt kohteet (enintään 8 työpuuta ja niiden regeneroitaviksi todennetut `node_modules`-kansiot sekä 11 paikallista tehtävähaaraa) on poistettu ilman `--force`- tai `-D`-lippuja; mahdolliset estyneet kohteet on jätetty säilytetyiksi syineen.
- [ ] Päächeckout (`C:/GitWork/Python-R-Scripts`), `tmp/deac-fira1-bootstrap`, kaikki muut säilytettäviksi merkityt työpuut sekä kaikki etähaarat (`origin/*`) ovat säilyneet täysin koskemattomina.
- [ ] `PRJ-REGISTRY-ROLLOUT.md`, `PRJ-PROJECT-WRITE-SCOPE-POLICY.md` ja `PRJ-WORKFLOW-GUIDANCE-ALIGNMENT.md` kirjaavat vain toteutuneet poistot säilyttäen `closed / delivered` -tilat, valmistumishistorian, lähdekuvaukset, SHA256-arvot ja totuudenmukaisen `worktree_inventory`-arvon (`unknown`).
- [ ] Soveltuvat rekisteri-, yksikkötesti-, Markdown-, LF- ja `tools/run-gates.ps1 --mode pre-push --smoke` -tarkistukset ovat läpäisseet.
- [ ] Siivouskirjauksen PR on avattu katselmointiin (`03-review`).
- [ ] PR:n täsmärevisio on saanut riippumattoman ihmishyväksynnän, yhdistetty `origin/main`iin, suljettu `04-done`-sulku-PR:llä ja sen yhdistämisen jälkeen `tmp/worktree-cleanup-001` paikallisine haaroineen on siivottu ja todennettu sulku-PR:n kommentissa ilman uutta PR-ketjua.

## Log

- 2026-11-19T20:16:00+02:00: Varmennettu `git fetch origin main` -> `b12155dd760e86bc0077d0ad966fc5ee08c0c135`, tarkistettu ettei vastaavaa tehtävää ole jonossa, perustettu eristetty työpuu `tmp/worktree-cleanup-001` haaralle `chore/worktree-cleanup-001` ja lisätty tehtäväkortti `READY`-tilaan.

## Blockers

- Ei aktiivisia esteitä.
- Pysähtymisehdot: jos yksittäisen poistokohteen tila on muuttunut tai poisto estyy ilman pakotusta, kyseinen kohde säilytetään ja syy raportoidaan; laajennukset hyväksyttyihin kirjoitus- tai poistokohteisiin vaativat uuden päätöksen.

## Links

- `SKILLS.md`
- `WORKFLOW.md`
- `docs/governance/project_registry/README.md`
- `docs/governance/project_registry/PRJ-REGISTRY-ROLLOUT.md`
- `docs/governance/project_registry/PRJ-PROJECT-WRITE-SCOPE-POLICY.md`
- `docs/governance/project_registry/PRJ-WORKFLOW-GUIDANCE-ALIGNMENT.md`
