# Työpuiden ja paikallisten tehtävähaarojen rajattu siivous

## Context

- Tila: `DONE`
- Tehtävätunnus: `worktree-cleanup-001`
- Omistaja: Tomi Korpi (`Tupatuko2023`)
- Orkestroija: `FCPO2`
- Toteutus-PR: <https://github.com/Tupatuko2023/Python-R-Scripts/pull/231> (`MERGED`, `3bfb9ba3f9527f9737c07477d872f1f12ef3273e`)
- Repo: `Tupatuko2023/Python-R-Scripts`
- Projektitietue: Ei uutta `PRJ-*`-tietuetta (`docs/governance/project_registry/README.md`: yksittäinen siivoustehtävä toteutetaan pelkällä `TASK`-kortilla; olemassa olevien suljettujen projektien `PRJ-REGISTRY-ROLLOUT`, `PRJ-PROJECT-WRITE-SCOPE-POLICY` ja `PRJ-WORKFLOW-GUIDANCE-ALIGNMENT` worktree-taulukot päivitettiin toteutuneiden poistojen osalta PR #231:ssä).
- Varmennettu lähtörevisio (`origin/main`): `b12155dd760e86bc0077d0ad966fc5ee08c0c135` (toimitettu `origin/main` PR #231:n jälkeen: `3bfb9ba3f9527f9737c07477d872f1f12ef3273e`)
- Eristetty väliaikainen siivoustyöpuu ja haarat: `tmp/worktree-cleanup-001` / `chore/worktree-cleanup-001` (`b3b464822514dd39bb536e004dcb015e213db3d8`) ja sulkuhaara `chore/worktree-cleanup-closeout-001` (vielä paikallaan; odottavat tämän sulku-PR:n `origin/main`-toimituksen jälkeistä loppusiivousta)
- Tavoite: Poistetaan Ownerin 2026-11-19 hyväksymässä rajauksessa yksilöidyt 8 toimitettua ja tarkistettua työpuuta sekä 11 toimitettua paikallista tehtävähaaraa ilman pakotusta (`--force` tai `-D`), säilyttäen etähaarat, päächeckout paikallisine töineen, `tmp/deac-fira1-bootstrap` sekä kaikki muut säilytettäviksi merkityt työpuut, ja kirjataan vain toteutuneet poistot.
- Hyväksytyt operaatiot ja toimitusraja (`SKILLS.md`):
  - eristetyn `tmp/worktree-cleanup-001`-työpuun perustaminen varmennetusta `origin/main`ista (`b12155dd760e86bc0077d0ad966fc5ee08c0c135`) ja `npm ci` vain tässä työpuussa lukitustiedoston mukaisesti;
  - 8 nimetyn työpuun ja niissä yksilöityjen regeneroitavien `node_modules`-, välimuisti- ja CSV-tulosten poisto sekä 11 nimetyn paikallisen haaran poisto (`git worktree remove`, `git branch -d`) jokaisen kohteen ennakkotarkistusten täytyttyä;
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

- [x] Ennen jokaista poistoa on varmennettu nykyinen `origin/main`, kohteen toimitus siihen (ml. squash-mergen PR-revisio ja puu-/sisältövertailu), kuuluminen `Tupatuko2023/Python-R-Scripts`-repoon sekä tracked/staged/untracked/ignored-sisältö ja käyttämättömyys.
- [x] Vain hyväksytyt kohteet (8 työpuuta ja niiden regeneroitaviksi todennetut `node_modules`-/välimuisti-/CSV-tulokset sekä 11 paikallista tehtävähaaraa) on poistettu ilman `--force`- tai `-D`-lippuja.
- [x] Päächeckout, `tmp/deac-fira1-bootstrap`, kaikki muut säilytettäviksi merkityt työpuut sekä kaikki etähaarat (`origin/*`) ovat säilyneet täysin koskemattomina.
- [x] `PRJ-REGISTRY-ROLLOUT.md`, `PRJ-PROJECT-WRITE-SCOPE-POLICY.md` ja `PRJ-WORKFLOW-GUIDANCE-ALIGNMENT.md` kirjaavat vain toteutuneet poistot säilyttäen `closed / delivered` -tilat, valmistumishistorian, lähdekuvaukset, SHA256-arvot ja totuudenmukaisen `worktree_inventory`-arvon (`unknown`).
- [x] Soveltuvat rekisteri-, yksikkötesti-, Markdown-, LF- ja `tools/run-gates.ps1 --mode pre-push --smoke` -tarkistukset ovat läpäisseet ja siivouskirjauksen PR (#231) on avattu katselmointiin (`03-review`).
- [x] PR #231:n täsmärevisio (`b3b464822514dd39bb536e004dcb015e213db3d8`) on saanut riippumattoman ihmishyväksynnän (`Tupatuko2023`, `2026-11-19T18:48:14Z`, `#issuecomment-7018697697`), yhdistetty `origin/main`iin (`3bfb9ba3f9527f9737c07477d872f1f12ef3273e`) ja kortti on siirretty polkuun `tasks/04-done/worktree-cleanup-001.md` omaa sulku-PR:ää varten (`tmp/worktree-cleanup-001` odottaa vielä sulku-PR:n yhdistämisen jälkeistä loppusiivousta).

## Riippumaton ihmishyväksyntä, `main`-toimitus ja odottava oman työpuun loppusiivous

1. **Riippumaton ihmishyväksyntänäyttö (`SKILLS.md`):**
   - Hyväksyjä: Tomi Korpi (`Tupatuko2023`)
   - Päätöksen aika: `2026-11-19T18:48:14Z` (`2026-11-19T20:48:14+02:00`)
   - Kohdetehtävä: `worktree-cleanup-001`
   - Hyväksytty täsmärevisio: `b3b464822514dd39bb536e004dcb015e213db3d8`
   - Pysyvä hyväksyntä-URL: <https://github.com/Tupatuko2023/Python-R-Scripts/pull/231#issuecomment-7018697697>
2. **Varmennettu `main`-toimitus (PR #231):**
   - Yhdistetty komennolla `gh pr merge 231 --squash --match-head-commit b3b464822514dd39bb536e004dcb015e213db3d8` ilman haaran poistoa (`mergedAt: 2026-11-19T18:50:01Z`).
   - `git fetch origin main` vahvisti kanoniseksi `origin/main`-merge-commitiksi `3bfb9ba3f9527f9737c07477d872f1f12ef3273e` (kaikki 4 polkua toimitettiin `origin/main`iin).
3. **Oman siivoustyöpuun vielä odottava loppusiivous (EI merkitty ennakolta poistetuksi):**
   - Tämän tehtävän oma väliaikainen työpuu `tmp/worktree-cleanup-001` sekä sen paikalliset tehtävähaarat (`chore/worktree-cleanup-001` ja `chore/worktree-cleanup-closeout-001`) ovat tämän `04-done`-sulku-PR:n aikana edelleen olemassa (`retained / pending post-merge cleanup`).
   - Vasta kun tämä sulku-PR on saanut riippumattoman ihmishyväksynnän, yhdistetty `origin/main`iin ja varmennettu tuoreesta `origin/main`ista, `tmp/worktree-cleanup-001` (regeneroitava `node_modules/` ja mahdolliset välimuistit tarkistettuina) sekä sen kaksi paikallista tehtävähaaraa poistetaan ilman pakotusta, ja toteutunut poistonäyttö kirjataan sulku-PR:n kommenttiin ja loppuraporttiin ilman uutta tehtävää tai PR-ketjua.

## Toteutuneet poistot ja säilytetyt kohteet (2026-11-19)

### 1. Poistetut 8 työpuuta (`git worktree remove`, ei `--force`)

Jokaisesta kohteesta varmennettiin ennen poistoa: (a) kuuluminen `Tupatuko2023/Python-R-Scripts`-repon yhteiseen `.git`-hakemistoon ja `worktree list --porcelain` -rekisteriin (0 `.lock`-tiedostoa), (b) toimitus `origin/main`iin (`b12155dd760e86bc0077d0ad966fc5ee08c0c135`), (c) 0 `staged`- ja 0 `unstaged`-muutosta sekä vain ennalta yksilöidyt regeneroitavat generoidut tulokset ja (d) ulkopuolisten prosessiviitteiden puuttuminen:

| #   | Työpuu (looginen sijainti)                                                          | `HEAD`                    | Toimitusnäyttö `origin/main`iin                                                                          | Ennen `worktree remove` -ajoa poistetut regeneroitavat kohteet                                           | Lopputulos |
| --- | ----------------------------------------------------------------------------------- | ------------------------- | -------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- | ---------- |
| 1   | `tmp/project-registry-general-adoption-001`                                         | `627a2470d9`              | PR #225 (`e603111a94`) & PR #226 (`b0499e2de4`), 100 % sama squash-puu                                   | `tools/project_registry/outputs/projects.csv`                                                            | `REMOVED`  |
| 2   | `tmp/project-write-scope-policy-001`                                                | `899dc00b16`              | PR #227 (`e96e146b3a`) & PR #228 (`8e71adfa53`), 100 % sama squash-puu                                   | `node_modules/` (`package-lock.json` varmennettu), `projects.csv`                                        | `REMOVED`  |
| 3   | `tmp/workflow-guidance-alignment-001`                                               | `4a5ade34ad`              | PR #229 (`8657ea22e7`) & PR #230 (`b12155dd76`), 100 % sama squash-puu                                   | `node_modules/` (`package-lock.json` varmennettu), `projects.csv`, `tools/project_registry/__pycache__/` | `REMOVED`  |
| 4   | `../prs-wt-windows-termux-20261006-main`                                            | `8721c5dd00`              | PR #194 (`ac265f075a`), suora `origin/main`-esivanhempi (`anc_main=True`)                                | Ei generoituja tiedostoja                                                                                | `REMOVED`  |
| 5   | `../prs-wt-windows-termux-done-ac265f0`                                             | `323aeecc0b`              | PR #196 (`4605520e1b`), 100 % sama squash-puu                                                            | Ei generoituja tiedostoja                                                                                | `REMOVED`  |
| 6   | `../prs-wt-windows-termux-review-0a8e5990`                                          | `8f676ac9f3` (`detached`) | PR #194 `headRefOid` (`ac265f075a`), suora `origin/main`-esivanhempi                                     | `.pytest_cache/`, `Fear-of-Falling/.pytest_cache/`                                                       | `REMOVED`  |
| 7   | `../FOF-Dissertation-Project/.worktrees/upstream-production-contract-prep-20261003` | `cf38fbcba6`              | PR #181 (`0f9996d5d9`), 100 % sama squash-puu; Git-omistajuus `Python-R-Scripts`-repoon todennettu       | Ei generoituja tiedostoja                                                                                | `REMOVED`  |
| 8   | `../prs-wt-transfer-runbook-4605520`                                                | `e0a57d7ad5`              | Suora esivanhempi PR #197:n `headRefOid`-revisiolle `e40d105d33` -> squash `43398dd81d` (100 % sama puu) | `Fear-of-Falling/.pytest_cache/`, `2x __pycache__/`                                                      | `REMOVED`  |

### 2. Poistetut 11 paikallista tehtävähaaraa (`git branch -d`, ei `-D`; etähaarat säilytetty)

Kaikkien 11 haaran `origin/main`-toimitusnäyttö (suora esivanhemmuus tai PR:n squash-puu-/blob-vastaavuus) varmennettiin erikseen ennen `git branch -d` -komentoa:

1. `docs/project-registry-general-adoption-001` (`8bd959ea`, PR #225 -> `e603111a`)
2. `chore/project-registry-general-adoption-closeout-001` (`627a2470`, PR #226 -> `b0499e2d`)
3. `docs/project-write-scope-policy-001` (`87cd0490`, PR #227 -> `e96e146b`)
4. `chore/project-write-scope-policy-closeout-001` (`899dc00b`, PR #228 -> `8e71adfa`)
5. `docs/workflow-guidance-alignment-001` (`fa29be19`, PR #229 -> `8657ea22`)
6. `chore/workflow-guidance-alignment-closeout-001` (`4a5ade34`, PR #230 -> `b12155dd`)
7. `chore/windows-termux-verified-pull-20261006-main` (`8721c5dd`, PR #194 -> `ac265f07`)
8. `docs/task-windows-termux-verified-pull-done` (`323aeecc`, PR #196 -> `4605520e`)
9. `docs/fof-production-entrypoint-contract` (`cf38fbcb`, PR #181 -> `0f9996d5`)
10. `docs/fof-production-entrypoint-contract-prep` (`ba8a7779`, PR #180 merge-commit)
11. `docs/bidirectional-local-file-transfer-runbook` (`e0a57d7a`, PR #197 -> `43398dd8`)

### 3. Säilytetyt työpuut (7 aiempaa + tämä väliaikainen toimitusworktree)

1. **Päächeckout (`main` @ `495644686c`):** säilytetty täysin koskemattomana (`2` unstaged `ANALYSIS_PLAN.md`-muokkausta, `19` untracked-merkintää sekä paikalliset analyysioutputit ennallaan).
2. **`../FOF-Dissertation-Project/.worktrees/prs-internal-exact-transfer-20261114` (`495644686c`):** säilytetty (`4` unstaged koodimuokkausta ja `1` untracked tehtäväkortti, ei toimitettu).
3. **`../prs-wt-windows-termux-20261006` (`6ca1031909`):** säilytetty (`5` staged-tiedostoa indeksissä).
4. **`../prs-wt-windows-termux-830040ad` (`830040ad42`):** säilytetty (seuraamaton paikallinen `docs/KB_PULL_SYNTHETIC/`-kansio).
5. **`tmp/deac-fira1-bootstrap` (`73d98b5c11`):** säilytetty Ownerin päätöksen mukaisesti (PR #165:n `c1dc26aa0d`-esivanhemmuus puuttuu paikallisesta objektikannasta ja päächeckoutissa on samanniminen untracked-kortti).
6. **`tmp/project-registry-baseline-001` (`ce44996a40`, `detached`):** säilytetty (`gitignored` Quantify-tulokset ja `manifest/run_log.local.csv`).
7. **`tmp/project-registry-transfer-001` (`bef9422eac`):** säilytetty (`03-review`-kortin `project-registry-cleanup-001` toimitusworktree sekä Quantify-tulokset ja CI-näyttö).
8. **`tmp/worktree-cleanup-001` (`chore/worktree-cleanup-closeout-001`):** tämän siivouskirjauksen oma väliaikainen toimitusworktree; **edelleen paikallaan (ei poistettu ennakolta)** ja odottaa tämän `04-done`-sulku-PR:n hyväksytyn `origin/main`-toimituksen jälkeistä loppusiivousta, jonka poistonäyttö kirjataan sulku-PR:n kommenttiin.

### 4. Siivousnäytön raja ja tarkistustulokset

- **Siivousnäytön raja:** Käyttämättömyystarkistus yhdisti tehtävä- ja PR-toimitusprovenancen, Git-worktree-lukkojen puuttumisen, status/ignored-tarkistuksen sekä prosessihaun (oman ajoketjun ulkopuoliset prosessit `0`), mutta käyttöjärjestelmätason poissulkevaa tiedostojärjestelmälukkoa ei käytetty.
- **Tarkistukset:**
  - `render_projects_csv.py --verify-guard` kaikille 3 `PRJ-*.md`-tietueelle ennen muokkausta: **PASS** (`OK`, exit `0`)
  - `render_projects_csv.py --print-source-hash` (`PRJ-REGISTRY-ROLLOUT`: `83d72573...`, `PRJ-PROJECT-WRITE-SCOPE-POLICY`: `5e46c7af...`, `PRJ-WORKFLOW-GUIDANCE-ALIGNMENT`: `6d8d4564...`): **PASS** (muuttumattomat)
  - `render_projects_csv.py` tuplagenerointi (`CSV_HASH_EQUAL=True`, `6487` tavua), `--check` (`OK`), `git check-ignore -v` (exit `0`) ja `test_render_projects_csv.py` (`60 passed`, `2 skipped` Windows-symlink): **PASS**
  - `prettier --check` ja `markdownlint-cli2` kaikille 4 muuttuneelle Markdown-tiedostolle: **PASS** (`0 issues`)
  - LF-tarkistus, `git diff --cached --check` ja `& ./tools/run-gates.ps1 --mode pre-push --smoke`: **PASS** (exit `0`)
  - Tutkimus- ja `K18/QC`-ajot: **NOT APPLICABLE** (hallinnollinen työpuusiivous ja rekisterikirjaus)

## Log

- 2026-11-19T20:16:00+02:00: Varmennettu `git fetch origin main` -> `b12155dd760e86bc0077d0ad966fc5ee08c0c135`, tarkistettu ettei vastaavaa tehtävää ole jonossa, perustettu eristetty työpuu `tmp/worktree-cleanup-001` haaralle `chore/worktree-cleanup-001` ja lisätty tehtäväkortti `READY`-tilaan (`6ff4242a35f7ce6fa135a69e0816e84c20afa0fd`).
- 2026-11-19T20:21:00+02:00: Suoritettu `--verify-guard` (`OK`, exit 0) kaikille kolmelle `PRJ-*.md`-tiedostolle, siirretty kortti `01-ready -> 02-in-progress`, todennettu kaikkien 8 hyväksytyn työpuun Git-omistajuus (`Python-R-Scripts`), `origin/main`-toimitus ja sisältö sekä poistettu kaikki 8 työpuuta (`git worktree remove`) ja 11 paikallista tehtävähaaraa (`git branch -d`) ilman pakotusta. Päivitetty 3 `PRJ-*.md`-tietuetta toteutuneilla poistoilla (`4706734`).
- 2026-11-19T20:26:00+02:00: Avattu PR #231 (<https://github.com/Tupatuko2023/Python-R-Scripts/pull/231>), siirretty kortti polkuun `tasks/03-review/worktree-cleanup-001.md` (`REVIEW`), suoritettu kaikki Markdown-, rekisteri- ja toimitusportit ja toimitettu katselmoitavaksi (`b3b464822514dd39bb536e004dcb015e213db3d8`).
- 2026-11-19T20:50:00+02:00: Varmennettu Ownerin (`Tupatuko2023`) pysyvä ihmishyväksyntä (`2026-11-19T18:48:14Z`, `#issuecomment-7018697697`) täsmärevisiolle `b3b464822514dd39bb536e004dcb015e213db3d8`, yhdistetty PR #231 `--squash --match-head-commit` -suojauksella ilman haaran poistoa, varmennettu `origin/main`-toimitus (`3bfb9ba3f9527f9737c07477d872f1f12ef3273e`) ja siirretty tämä kortti polkuun `tasks/04-done/worktree-cleanup-001.md` (`DONE`) sulku-PR:ää varten (`tmp/worktree-cleanup-001` odottaa edelleen sulku-PR:n yhdistämisen jälkeistä loppusiivousta).

## Blockers

- Ei aktiivisia esteitä. Odottaa riippumatonta ihmishyväksyntää tämän `04-done`-sulku-PR:n täsmärevisiolle ennen mergeä ja `tmp/worktree-cleanup-001`:n loppusiivousta.

## Links

- `SKILLS.md`
- `WORKFLOW.md`
- `docs/governance/project_registry/README.md`
- `docs/governance/project_registry/PRJ-REGISTRY-ROLLOUT.md`
- `docs/governance/project_registry/PRJ-PROJECT-WRITE-SCOPE-POLICY.md`
- `docs/governance/project_registry/PRJ-WORKFLOW-GUIDANCE-ALIGNMENT.md`
