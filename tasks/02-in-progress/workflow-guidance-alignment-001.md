# Päärepon ja aliprojektien työnkulkuohjeiden yhtenäistäminen

## Context

- Tila: `IN_PROGRESS`
- Tehtävätunnus: `workflow-guidance-alignment-001`
- Omistaja: Tomi Korpi (`Tupatuko2023`)
- Orkestroija: `FCPO2`
- Projekti: `PRJ-WORKFLOW-GUIDANCE-ALIGNMENT` (`docs/governance/project_registry/PRJ-WORKFLOW-GUIDANCE-ALIGNMENT.md`)
- Repo: `Tupatuko2023/Python-R-Scripts`
- Varmennettu lähtörevisio (`origin/main`): `8e71adfa539b05f95361134eb7b8e57e6a898199`
- Eristetty työpuu ja tehtävähaara: `tmp/workflow-guidance-alignment-001` / `docs/workflow-guidance-alignment-001`
- Tavoite: Yhtenäistetään päärepon ja aliprojektien ristiriitaiset työnkulkuohjeet kolmessa rajatussa asiassa:
  1. Erotetaan työn valmistuminen katselmointiin (`03-review`), hyväksytty `main`-toimitus ja tekninen sulku (`04-done`) sekä erikseen valtuutettava työpuun ja haarojen siivous.
  2. Korjataan aliprojektien vanhat suorapush- ja automaattiset `DONE`-ohjeet vastaamaan `SKILLS.md`:n PR- ja ihmishyväksyntäportteja.
  3. Selkeytetään ohjeiden keskinäiset etusija- ja polkuviittaukset hallinnollisen työnkulun osalta säilyttäen aliprojektien omat tehtäväjonot ja kaikki tutkimusaineiston, ympäristön ja QC:n suojaukset.
- Hyväksytyt operaatiot ja toimitusraja (kanoninen sääntö: `SKILLS.md`): `git fetch origin main`, eristetyn worktreen ja tehtävähaaran luonti varmennetusta `origin/main`ista, tarvittaessa `npm ci` vain tässä uudessa eristetyssä worktreessä lukitustiedoston mukaisesti, tämän tehtäväkortin ja projektitietueen perustaminen, rajattu toteutus, tarkistukset ja virheiden korjaus hyväksytyissä poluissa, kohdistetut commitit, `git push` sekä PR:n luonti ja päivittäminen **PR-katselmointiin (`03-review`) asti** ilman välikuittauksia.
- Toimitusrajan ulkopuolella (kielletty tässä vaiheessa): ei mergeä, ei `04-done`-siirtoa, ei `delivered`/`closed`-merkintää eikä työpuiden tai haarojen poistoa. Likainen päächeckout ja kaikki olemassa olevat työpuut sekä haarat säilytetään koskemattomina.

### Ownerin toteutustäsmennykset (2026-11-18)

1. **Etusija rajataan hallintoon:** repojuuren `SKILLS.md`/`AGENTS.md`-etusijaviittaukset rajataan tehtäväkohtaiseen valtuutukseen, PR-menettelyyn, `main`-toimitukseen, tekniseen sulkuun ja siivoukseen. Tutkimusmenetelmien auktoriteettia ei muuteta eikä aliprojektien tiukempia tutkimus-, tietosuoja-, QC- tai ympäristörajoja heikennetä.
2. **Tiedostokohtaiset suhteelliset linkit vs. komentojen työjuuri:** tarkistetaan suhteelliset polut kunkin tiedoston sijainnista (esim. `Fear-of-Falling/tasks/_template.md` -> `../../SKILLS.md` ja `../agent_workflow.md`; aliprojektin juuresta -> `../SKILLS.md`) ja erotetaan Markdown-linkkien polut komentojen suoritushakemistosta.
3. **Suojattujen osioiden tavuntarkka säilytys:** säilytetään `Fear-of-Falling/SYSTEM_PROMPT_POWERSHELL7_S-FOF.md`:n ensimmäinen banner-rivi tavuntarkasti sekä `K18/QC Applicability Decision Gate`, Option B-, `AUTH_SOURCE`-, `DATA_ROOT`-, aggregaattien valtuutus- ja `n < 5` -suojaukset ennallaan ja todennetaan ne lähtörevisiota (`8e71adfa539b05f95361134eb7b8e57e6a898199`) vasten.
4. **Ympäristöerojen säilytys ja staattinen vs. ajonaikainen tarkistus:** säilytetään Windows PS7- ja Termux/PRoot-ohjeiden ympäristökohtaiset erot; ei käynnistetä tutkimusajoja tai ympäristömuutoksia; merkitään suorittamattomat ajonaikaiset lataus- ja käyttäytymistestit `NOT_RUN`.

## Inputs

- Ajantasainen `origin/main` (`8e71adfa539b05f95361134eb7b8e57e6a898199`): `SKILLS.md`, `WORKFLOW.md`, `AGENTS.md`, `GEMINI.md`, `config/steering.md`, `config/agent_policy.md`.
- `docs/governance/project_registry/README.md` ja `docs/governance/project_registry/TEMPLATE.md`.
- Aliprojektien työnkulku- ja järjestelmäohjeet: `Electronic-Frailty-Index/`, `Fear-of-Falling/`, `Quantify-FOF-Utilization-Costs/` ja `DEAC-Frailty-Index/`.
- Ownerin 2026-11-18 hyväksyntäpääös kirjoitusrajaukselle, lähdekuvaukselle ja toimitusrajalle.

## Outputs

- Sallitut seuratut kirjoituspolut (16 sisältö- ja rekisteripolkua repojuureen suhteutettuina):
  1. `SKILLS.md`
  2. `WORKFLOW.md`
  3. `Electronic-Frailty-Index/WORKFLOW.md`
  4. `Electronic-Frailty-Index/agent_workflow.md`
  5. `Fear-of-Falling/WORKFLOW.md`
  6. `Fear-of-Falling/agent_workflow.md`
  7. `Fear-of-Falling/tasks/_template.md`
  8. `Fear-of-Falling/SYSTEM_PROMPT_POWERSHELL7_S-FOF.md`
  9. `Fear-of-Falling/SYSTEM_PROMPT_TERMUX_S-FOF.md`
  10. `Fear-of-Falling/AGENTS.md`
  11. `Quantify-FOF-Utilization-Costs/WORKFLOW.md`
  12. `Quantify-FOF-Utilization-Costs/agent_workflow.md`
  13. `Quantify-FOF-Utilization-Costs/GEMINI.md`
  14. `Quantify-FOF-Utilization-Costs/AGENTS.md`
  15. `DEAC-Frailty-Index/AGENTS.md`
  16. `docs/governance/project_registry/PRJ-WORKFLOW-GUIDANCE-ALIGNMENT.md`
- Sallitut tämän tehtäväkortin elinkaaripolut eristetyssä worktreessä:
  - `tasks/01-ready/workflow-guidance-alignment-001.md`
  - `tasks/02-in-progress/workflow-guidance-alignment-001.md`
  - `tasks/03-review/workflow-guidance-alignment-001.md`
- Sallitut paikalliset `gitignored`-tulokset (ei commitoida):
  - `tools/project_registry/outputs/projects.csv` (sekä generaattorin atomisen julkaisun väliaikaistiedostot)
- Rajauksen ulkopuoliset toimet: historiallisten tai muiden tehtäväkorttien, muutoslokien (`CHANGELOG*`, `10_handover.md`, `.txt`-viennit), `CLAUDE.md`-konventioiden, `DEAC_HANDOVER.md`:n tai koodi-/analyysiskriptien muuttaminen; tutkimusajot; merge, `04-done` ja siivous.

## Definition of Done (DoD)

- [ ] `WORKFLOW.md` ja `SKILLS.md` erottavat työn valmistumisen (`03-review`), hyväksytyn `main`-toimituksen / teknisen `04-done`-sulun ja erikseen valtuutettavan työpuun/haaran/kloonin siivouksen ilman likaisen päächeckoutin päivityspakkoa.
- [ ] Aliprojektien `WORKFLOW.md`-, `agent_workflow.md`- ja `Fear-of-Falling/tasks/_template.md` -tiedostoista on poistettu vanhat automaattiset `git pull`-, suorapush (`or main if permitted`)-, `03-review`-mergen esto- ja automaattiset `04-done`-ohjeet ja ne on yhdenmukaistettu `SKILLS.md`:n PR- ja ihmishyväksyntämenettelyyn.
- [ ] Etusija- ja polkuviittaukset on rajattu hallinnolliseen työnkulkuun, suhteelliset linkit täsmäävät kunkin tiedoston sijainnista (ml. `../../SKILLS.md` polusta `Fear-of-Falling/tasks/_template.md`), ja aliprojektien omat tehtäväjonot säilyvät.
- [ ] PS7-ohjeen ensimmäinen banner-rivi, `K18/QC Applicability Decision Gate`, Option B-, `AUTH_SOURCE`-, `DATA_ROOT`-, aggregaatti- ja `n < 5` -suojaukset sekä Windows/Termux-ympäristöerot ovat säilyneet tavuntarkasti ennallaan lähtörevisioon (`8e71adfa...`) verrattuna.
- [ ] `PRJ-WORKFLOW-GUIDANCE-ALIGNMENT.md` ja `tools/project_registry/outputs/projects.csv` läpäisevät lähdehash-, `--verify-guard`-, determinismi-, `--check`-, `git check-ignore`- ja yksikkötestit.
- [ ] Muuttuneet Markdown-ohjeet läpäisevät `prettier --check`-, `markdownlint-cli2`-, LF-, `git diff --check`- ja `tools/run-gates.ps1 --mode pre-push --smoke` -tarkistukset; staattinen toimintatapavertailu on kirjattu ja suorittamattomat ajonaikaiset testit on merkitty `NOT_RUN`.
- [ ] Katselmoitava PR on avattu ja täsmärevisio odottaa riippumatonta ihmishyväksyntää; myöhempi `main`-toimitus ja `04-done`-sulku tehdään paikallisen menettelyn mukaisesti.

## Log

- 2026-11-18T17:35:00+02:00: Suoritettu read-only-nykytilan lukutarkastus suoraan `origin/main`-revisiosta `8e71adfa539b05f95361134eb7b8e57e6a898199` ja valmisteltu 16 polun kirjoitusrajaus projektille `PRJ-WORKFLOW-GUIDANCE-ALIGNMENT`.
- 2026-11-18T17:49:00+02:00: Owner hyväksyi kirjoitusrajauksen, lähdekuvauksen ja toimitusrajan PR-katselmointiin asti. `git fetch origin main` vahvisti lähtörevisioksi `8e71adfa539b05f95361134eb7b8e57e6a898199` (ei päällekkäisiä uusia muutoksia). Perustettu eristetty worktree `tmp/workflow-guidance-alignment-001` ja haara `docs/workflow-guidance-alignment-001` koskematta päächeckoutiin tai olemassa oleviin työpuihin. Valmisteltu `READY`-kortti ja projektitietue tilaan `planned / not_delivered` (`7e1955ae15da43dd2dfd093bdc7c88bf77af0684`).
- 2026-11-18T17:56:00+02:00: Suoritettu `--verify-guard` (`OK`, exit 0) revisiota `7e1955ae15da43dd2dfd093bdc7c88bf77af0684` vasten, siirretty kortti `01-ready` -> `02-in-progress`, vaihdettu `PRJ-WORKFLOW-GUIDANCE-ALIGNMENT.md` tilaan `active / not_delivered` ja toteutettu kaikki 15 hyväksyttyä ohjetiedostopäivitystä suojatut osiot tavuntarkasti säilyttäen.

## Blockers

- Ei aktiivisia esteitä PR-katselmointiin etenemiseksi.
- Pysähtymisehdot: tavoitteen, kirjoituspolkujen, vaikutusten tai operaatioiden laajennus, ratkaisematon porttivirhe tai ohjeristiriita edellyttää uutta päätöstä.

## Links

- `docs/governance/project_registry/PRJ-WORKFLOW-GUIDANCE-ALIGNMENT.md`
- `docs/governance/project_registry/README.md`
- `SKILLS.md`
- `WORKFLOW.md`
- `Electronic-Frailty-Index/WORKFLOW.md`
- `Electronic-Frailty-Index/agent_workflow.md`
- `Fear-of-Falling/WORKFLOW.md`
- `Fear-of-Falling/agent_workflow.md`
- `Fear-of-Falling/tasks/_template.md`
- `Fear-of-Falling/SYSTEM_PROMPT_POWERSHELL7_S-FOF.md`
- `Fear-of-Falling/SYSTEM_PROMPT_TERMUX_S-FOF.md`
- `Fear-of-Falling/AGENTS.md`
- `Quantify-FOF-Utilization-Costs/WORKFLOW.md`
- `Quantify-FOF-Utilization-Costs/agent_workflow.md`
- `Quantify-FOF-Utilization-Costs/GEMINI.md`
- `Quantify-FOF-Utilization-Costs/AGENTS.md`
- `DEAC-Frailty-Index/AGENTS.md`
