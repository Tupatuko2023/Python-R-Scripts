# Päärepon ja aliprojektien työnkulkuohjeiden yhtenäistäminen

## Context

- Tila: `REVIEW`
- Tehtävätunnus: `workflow-guidance-alignment-001`
- Omistaja: Tomi Korpi (`Tupatuko2023`)
- Orkestroija: `FCPO2`
- Projekti: `PRJ-WORKFLOW-GUIDANCE-ALIGNMENT` (`docs/governance/project_registry/PRJ-WORKFLOW-GUIDANCE-ALIGNMENT.md`)
- PR: <https://github.com/Tupatuko2023/Python-R-Scripts/pull/229>
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

- [x] `WORKFLOW.md` ja `SKILLS.md` erottavat työn valmistumisen (`03-review`), hyväksytyn `main`-toimituksen / teknisen `04-done`-sulun ja erikseen valtuutettavan työpuun/haaran/kloonin siivouksen ilman likaisen päächeckoutin päivityspakkoa.
- [x] Aliprojektien `WORKFLOW.md`-, `agent_workflow.md`- ja `Fear-of-Falling/tasks/_template.md` -tiedostoista on poistettu vanhat automaattiset `git pull`-, suorapush (`or main if permitted`)-, `03-review`-mergen esto- ja automaattiset `04-done`-ohjeet ja ne on yhdenmukaistettu `SKILLS.md`:n PR- ja ihmishyväksyntämenettelyyn.
- [x] Etusija- ja polkuviittaukset on rajattu hallinnolliseen työnkulkuun, suhteelliset linkit täsmäävät kunkin tiedoston sijainnista (ml. `../../SKILLS.md` polusta `Fear-of-Falling/tasks/_template.md`), ja aliprojektien omat tehtäväjonot säilyvät.
- [x] PS7-ohjeen ensimmäinen banner-rivi, `K18/QC Applicability Decision Gate`, Option B-, `AUTH_SOURCE`-, `DATA_ROOT`-, aggregaatti- ja `n < 5` -suojaukset sekä Windows/Termux-ympäristöerot ovat säilyneet tavuntarkasti ennallaan lähtörevisioon (`8e71adfa...`) verrattuna.
- [x] `PRJ-WORKFLOW-GUIDANCE-ALIGNMENT.md` ja `tools/project_registry/outputs/projects.csv` läpäisevät lähdehash-, `--verify-guard`-, determinismi-, `--check`-, `git check-ignore`- ja yksikkötestit.
- [x] Muuttuneet Markdown-ohjeet läpäisevät `prettier --check`-, `markdownlint-cli2`-, LF-, `git diff --check`- ja `tools/run-gates.ps1 --mode pre-push --smoke` -tarkistukset; staattinen toimintatapavertailu on kirjattu ja suorittamattomat ajonaikaiset testit on merkitty `NOT_RUN`.
- [x] Katselmoitava PR (#229) on avattu ja tehtäväkortti siirretty polkuun `tasks/03-review/workflow-guidance-alignment-001.md`.
- [ ] PR:n täsmärevisio on saanut riippumattoman ihmishyväksynnän ja myöhempi `main`-toimitus sekä tekninen `04-done`-sulku on suoritettu paikallisen menettelyn mukaisesti.

## Staattinen toimintatapavertailu ja tarkistusnäyttö

> Huomio: Alla oleva nelikohtainen vertailu on dokumentoitu **staattinen ohjevertailu** (ei ajonaikainen järjestelmä- tai orkestrointitesti).

| Tapaus                                                        | Aiempi ohjeristiriita (`8e71adfa...`)                                                                                                                                                                                                                                                      | Yhtenäistetty sääntö tässä PR:ssä (#229)                                                                                                                                                                                                                                                                                                                                                                                                         |
| ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1. Valmistuminen vs. `main`-toimitus vs. siivous              | `WORKFLOW.md` ohjasi poistamaan tehtäväworktreen/kloonin heti työn valmistuttua ja edellytti päächeckoutin puhtautta/`git pull`ia.                                                                                                                                                         | `SKILLS.md`, `WORKFLOW.md` ja aliprojektien työnkulkuohjeet erottavat kolme eri vaihetta: (a) valmistuminen katselmointiin (`03-review`), (b) erikseen ihmishyväksytty `main`-toimitus + tekninen `04-done`-sulku ja (c) erikseen valtuutettava työpuun/haaran/kloonin siivous (`retained` oletuksena). Eristetty worktree perustetaan suoraan varmennetusta `origin/main`ista koskematta likaiseen päächeckoutiin.                              |
| 2. Aliprojektien PR- ja ihmishyväksyntäportti                 | Aliprojektien `WORKFLOW.md`, `agent_workflow.md`, `tasks/_template.md` ja S-FOF-järjestelmäohjeet sisälsivät vanhoja `or main if permitted`-, automaattisia `git pull`-, `MUST NOT be merged to main unless moved to 04-done`-, `Only a human may move`- ja `edellytys DONE:lle` -ohjeita. | Kaikki 15 muokattua ohjetiedostoa noudattavat `SKILLS.md`:n kaksivaiheista mallia: agentti vie työn `03-review`-PR:ään; vasta pysyvän riippumattoman ihmishyväksynnän jälkeen tehdään `main`-toimitus ja tekninen `04-done`-sulku. Automaattiset `git pull`- ja suorapush-viittaukset on poistettu (0 osumaa tarkistuksessa).                                                                                                                    |
| 3. Hallinnollinen etusija, tehtäväjonot ja suhteelliset polut | Yleisluontoiset etusijalauseet jättivät avoimeksi hallinnon ja tutkimussääntöjen rajan; `Fear-of-Falling/tasks/_template.md` ei erottanut tiedostokohtaisia linkkejä komentojen työjuuresta.                                                                                               | Repojuuren `SKILLS.md`/`AGENTS.md`-etusija on rajattu nimenomaisesti hallinnolliseen työnkulkuun. Aliprojektien omat tehtäväjonot (`Fear-of-Falling/tasks/`, `Quantify-FOF-Utilization-Costs/tasks/`) ja tiukemmat tutkimus-, tietosuoja-, QC- ja ympäristörajat säilyvät. Kaikki 92 suhteellista linkkiä on tarkistettu tiedostokohtaisesti (ml. `../../SKILLS.md` ja `../agent_workflow.md` tiedostosta `Fear-of-Falling/tasks/_template.md`). |
| 4. Työpuun säilytys ja jatkuvuus yhdellä hyväksynnällä        | Vanhat ohjeet viittasivat vanhentuneeseen sääntöihin ja aiheuttivat epäselvyyttä välilupien ja työpuun säilytyksen osalta.                                                                                                                                                                 | Toteutus eteni yhdellä tehtäväkohtaisella hyväksynnällä 16 polun rajauksessa suoraan PR-katselmointiin (#229) ilman välikuittauksia; likainen päächeckout ja 13 aiempaa työpuuta säilyivät koskemattomina.                                                                                                                                                                                                                                       |

### Suojattujen osioiden tavuntarkka säilytysnäyttö (vs. `8e71adfa539b05f95361134eb7b8e57e6a898199`)

Automaattinen tavutarkka vertailu lähtörevisiota `8e71adfa539b05f95361134eb7b8e57e6a898199` vasten: **PASS** kaikille 8 suojatulle kohteelle:

1. `Fear-of-Falling/SYSTEM_PROMPT_POWERSHELL7_S-FOF.md`: rivi 1 (`# GEMINI AGENT CONTEXT: Gemini PowerShell 7 Orchestrator GPT (S-FOF)`) + luvut 3–7 tavuntarkasti samat.
2. `Fear-of-Falling/SYSTEM_PROMPT_TERMUX_S-FOF.md`: rivi 1 + luvut 1–6 tavuntarkasti samat.
3. `Fear-of-Falling/agent_workflow.md`: `K18/QC Applicability Decision Gate` tavuntarkasti sama.
4. `Fear-of-Falling/tasks/_template.md`: `## QC applicability` -osio tavuntarkasti sama.
5. `Fear-of-Falling/AGENTS.md`: tuotantosopimus, `AUTH_SOURCE`, `DATA_ROOT`, K18-portti ja polkusäännöt tavuntarkasti samat.
6. `Quantify-FOF-Utilization-Costs/GEMINI.md`: Option B, Termux-rajoitteet, `n < 5` -suppressio ja operatiiviset ajokomennot tavuntarkasti samat.
7. `Quantify-FOF-Utilization-Costs/AGENTS.md`: `Conflict Resolution Protocol` ja aggregaattien valtuutussäännöt tavuntarkasti samat.
8. `DEAC-Frailty-Index/AGENTS.md`: tieteellinen ensisijainen auktoriteetti ja `DATA_ROOT`-tietosuoja tavuntarkasti samat.

### Tarkistusten tulokset

- `npx --no-install prettier --check` (15 ei-`tasks/` Markdown-tiedostoa): **PASS**
- `npx --no-install markdownlint-cli2` (16 Markdown-tiedostoa ml. `Fear-of-Falling/tasks/_template.md`): **PASS** (`0 issues`)
- Suhteellisten Markdown-linkkien kohdetarkistus (92 linkkiä kunkin tiedoston hakemistosta): **PASS**
- Vanhentuneiden merkkijonojen poissaolotarkistus (`gpa1qf`, `or main if permitted`, `edellytys DONE:lle`, `MUST NOT be merged to main unless moved to 04-done`, `Only a human may move`): **PASS** (`0` osumaa)
- `render_projects_csv.py --print-source-hash`: **PASS** (`6d8d4564d58eef72484dc6901f9a4c9bbb304f2f42afa415c0fa3b43b94fc6d0`)
- `render_projects_csv.py --verify-guard` ennen molempia rekisteripäivityksiä: **PASS** (`OK`, exit 0)
- `render_projects_csv.py` CSV-generointi kahdesti (determinismi) + `--check` + `git check-ignore -v`: **PASS** (`EQUAL=True`, `OK`, exit 0)
- `python -B -m unittest discover -s tools/project_registry/tests -p test_render_projects_csv.py`: **PASS** (`60 passed`, **`SKIPPED: 2`** Windows-symlink-testiä)
- LF-rivinvaihtojen ja `git diff --cached --check` -tarkistus: **PASS**
- `& ./tools/run-gates.ps1 --mode pre-push --smoke`: **PASS** (exit 0)
- Tutkimusajot, K18/QC-skriptit sekä R/Python-analyysiajot: **NOT APPLICABLE** (puhdas hallinto- ja työnkulkuohjemuutos)
- Suorittamattomat ajonaikaiset lataus- ja käyttäytymistestit: **`NOT_RUN`**
  - Windows PowerShell 7 `Fear-of-Falling/scripts/ps7/run_gemini_orchestrator.ps1` ajonaikainen promptin lataus- ja orkestrointiajo: `NOT_RUN` (rivi 1 säilytetty tavuntarkasti `ORCHESTRATOR_LOADING_CONTRACT.md`:n mukaisesti).
  - Termux/PRoot-ajonaikainen promptin lataus- ja käyttäytymistesti (`SYSTEM_PROMPT_TERMUX_S-FOF.md`): `NOT_RUN`.

## Log

- 2026-11-18T17:35:00+02:00: Suoritettu read-only-nykytilan lukutarkastus suoraan `origin/main`-revisiosta `8e71adfa539b05f95361134eb7b8e57e6a898199` ja valmisteltu 16 polun kirjoitusrajaus projektille `PRJ-WORKFLOW-GUIDANCE-ALIGNMENT`.
- 2026-11-18T17:49:00+02:00: Owner hyväksyi kirjoitusrajauksen, lähdekuvauksen ja toimitusrajan PR-katselmointiin asti. `git fetch origin main` vahvisti lähtörevisioksi `8e71adfa539b05f95361134eb7b8e57e6a898199` (ei päällekkäisiä uusia muutoksia). Perustettu eristetty worktree `tmp/workflow-guidance-alignment-001` ja haara `docs/workflow-guidance-alignment-001` koskematta päächeckoutiin tai olemassa oleviin työpuihin. Valmisteltu `READY`-kortti ja projektitietue tilaan `planned / not_delivered` (`7e1955ae15da43dd2dfd093bdc7c88bf77af0684`).
- 2026-11-18T17:56:00+02:00: Suoritettu `--verify-guard` (`OK`, exit 0) revisiota `7e1955ae15da43dd2dfd093bdc7c88bf77af0684` vasten, siirretty kortti `01-ready` -> `02-in-progress`, vaihdettu `PRJ-WORKFLOW-GUIDANCE-ALIGNMENT.md` tilaan `active / not_delivered` ja toteutettu kaikki 15 hyväksyttyä ohjetiedostopäivitystä suojatut osiot tavuntarkasti säilyttäen (`0fb0f2dec52205818f498948831959ac9b458c05`).
- 2026-11-18T18:02:00+02:00: Varmennettu projektirekisterin yksikkötestit (`62 ran, OK, skipped=2`), suoritettu `--verify-guard` (`OK`, exit 0) revisiota `0fb0f2dec52205818f498948831959ac9b458c05` vasten, pushattu haara, avattu PR #229 (<https://github.com/Tupatuko2023/Python-R-Scripts/pull/229>), siirretty tehtäväkortti polkuun `tasks/03-review/workflow-guidance-alignment-001.md` (`REVIEW`) ja päivitetty `PRJ-WORKFLOW-GUIDANCE-ALIGNMENT.md` katselmointivaiheeseen (`active / not_delivered`).

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
