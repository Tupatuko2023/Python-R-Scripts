# Päärepon ja aliprojektien työnkulkuohjeiden yhtenäistäminen

## Context

- Tila: `DONE`
- Tehtävätunnus: `workflow-guidance-alignment-001`
- Omistaja: Tomi Korpi (`Tupatuko2023`)
- Orkestroija: `FCPO2`
- Projekti: `PRJ-WORKFLOW-GUIDANCE-ALIGNMENT` (`docs/governance/project_registry/PRJ-WORKFLOW-GUIDANCE-ALIGNMENT.md`)
- Toteutus-PR: <https://github.com/Tupatuko2023/Python-R-Scripts/pull/229> (`MERGED`, `8657ea22e79bc14c35b04d0f43e934d7a8e95b17`)
- Repo: `Tupatuko2023/Python-R-Scripts`
- Varmennettu lähtörevisio (`origin/main`): `8e71adfa539b05f95361134eb7b8e57e6a898199` (toimitettu `origin/main` PR #229:n jälkeen: `8657ea22e79bc14c35b04d0f43e934d7a8e95b17`)
- Eristetty työpuu ja tehtävähaarat: `tmp/workflow-guidance-alignment-001` / `docs/workflow-guidance-alignment-001` (`fa29be19258f4a585af2afd76d97eed6051567b1`) ja sulkuhaara `chore/workflow-guidance-alignment-closeout-001` (säilytetty `retained`)
- Tavoite: Yhtenäistetään päärepon ja aliprojektien ristiriitaiset työnkulkuohjeet kolmessa rajatussa asiassa:
  1. Erotetaan työn valmistuminen katselmointiin (`03-review`), hyväksytty `main`-toimitus ja tekninen sulku (`04-done`) sekä erikseen valtuutettava työpuun ja haarojen siivous.
  2. Korjataan aliprojektien vanhat suorapush- ja automaattiset `DONE`-ohjeet vastaamaan `SKILLS.md`:n PR- ja ihmishyväksyntäportteja.
  3. Selkeytetään ohjeiden keskinäiset etusija- ja polkuviittaukset hallinnollisen työnkulun osalta säilyttäen aliprojektien omat tehtäväjonot ja kaikki tutkimusaineiston, ympäristön ja QC:n suojaukset.
- Hyväksytyt operaatiot ja toimitusraja (kanoninen sääntö: `SKILLS.md`): `git fetch origin main`, eristetyn worktreen ja tehtävähaaran luonti varmennetusta täydestä commit-SHA:sta, tarvittaessa `npm ci` vain tässä eristetyssä worktreessä lukitustiedoston mukaisesti, tämän tehtäväkortin ja projektitietueen perustaminen, rajattu toteutus ja katselmointikorjaukset hyväksytyissä poluissa, tarkistukset, kohdistetut commitit, `git push` sekä PR:n luonti ja päivittäminen **PR-katselmointiin (`03-review`) asti** ilman välikuittauksia.
- Toimitusrajan ulkopuolella (kielletty tässä vaiheessa): ei mergeä, ei `04-done`-siirtoa, ei `delivered`/`closed`-merkintää eikä työpuiden tai haarojen poistoa. Likainen päächeckout ja kaikki olemassa olevat työpuut sekä haarat säilytetään koskemattomina.

### Ownerin toteutustäsmennykset (2026-11-18)

1. **Etusija rajataan hallintoon:** repojuuren `SKILLS.md`/`AGENTS.md`-etusijaviittaukset (ml. `SKILLS.md`:n oma etusijalause) rajataan hallinnolliseen työnkulkuun. Tutkimusmenetelmien auktoriteettia ei muuteta eikä aliprojektien tiukempia tutkimus-, tietosuoja-, QC- tai ympäristörajoja heikennetä; ratkaisematon ristiriita pysäyttää riippuvan toimenpiteen eikä anna lupaa valita heikompaa sääntöä.
2. **Tiedostokohtaiset suhteelliset linkit vs. komentojen työjuuri:** tarkistetaan suhteelliset polut kunkin tiedoston sijainnista (esim. `Fear-of-Falling/tasks/_template.md` -> `../../SKILLS.md` ja `../agent_workflow.md`; aliprojektin juuresta -> `../SKILLS.md`) ja erotetaan Markdown-linkkien polut komentojen suoritushakemistosta.
3. **Suojattujen osioiden säilytys ja nimenomaisesti valtuutetut rajatut soveltamisalatäsmennykset (katselmointikierros 2026-11-18):**
   - Säilytetään tavuntarkasti muuttumattomina `Fear-of-Falling/SYSTEM_PROMPT_POWERSHELL7_S-FOF.md`:n rivi 1 sekä luvut 3.2–7, `Fear-of-Falling/SYSTEM_PROMPT_TERMUX_S-FOF.md`:n rivi 1 sekä luvut 1.2–6, `K18/QC Applicability Decision Gate`, `Fear-of-Falling/tasks/_template.md`:n `## QC applicability`, `Fear-of-Falling/AGENTS.md`:n tuotantosopimus/`AUTH_SOURCE`/`DATA_ROOT`/`K18`-osiot, `Quantify-FOF-Utilization-Costs/GEMINI.md`:n Option B -, `DATA_ROOT`-, Termux-, `n < 5` - ja analyysikomentolohkot, `Quantify-FOF-Utilization-Costs/AGENTS.md`:n `Conflict Resolution Protocol` sekä `DEAC-Frailty-Index/AGENTS.md`:n tieteellinen auktoriteetti ja `DATA_ROOT`-suojaus.
   - Ownerin erillisellä katselmointipäätöksellä sallitut rajatut soveltamisalatäsmennykset:
     a) `Quantify-FOF-Utilization-Costs/GEMINI.md`:n `## WORKFLOW & GATES (DoD)` -osiossa täsmennetään analyysivaiheiden (`Smoke Test` ja `Full Run`) edellyttävän analyysia tarvitsevaa tehtävää, tehtäväkohtaista valtuutusta ja turvaporttien täyttymistä (dokumentaatiotehtävä ei käynnistä `Full Run` -ajoa).
     b) `Fear-of-Falling/SYSTEM_PROMPT_POWERSHELL7_S-FOF.md`:n (`3.1 Working Directory`) ja `Fear-of-Falling/SYSTEM_PROMPT_TERMUX_S-FOF.md`:n (`1 Working Directory`) työhakemistosääntöihin täsmennetään rajattu poikkeus, jolla valtuutetut repojuuren hallintaportit ja rekisterikomennot suoritetaan saman eristetyn tehtäväworktreen repojuuressa rajatussa suorituskontekstissa analyysien ja tutkimus-QC:n pysyessä aina `Fear-of-Falling/`-työjuuressa.
4. **Ympäristöerojen säilytys ja staattinen vs. ajonaikainen tarkistus:** säilytetään Windows PS7- ja Termux/PRoot-ohjeiden ympäristökohtainen syntaksi; ei käynnistetä tutkimusajoja tai ympäristömuutoksia; merkitään suorittamattomat ajonaikaiset lataus- ja käyttäytymistestit `NOT_RUN`, ja etä-CI:n keskeneräiset ajot merkitään `PENDING` (keskeneräinen), ei koskaan `SKIPPED`.

## Inputs

- Ajantasainen `origin/main` (`8e71adfa539b05f95361134eb7b8e57e6a898199`): `SKILLS.md`, `WORKFLOW.md`, `AGENTS.md`, `GEMINI.md`, `config/steering.md`, `config/agent_policy.md`, `tasks/_template.md`.
- `docs/governance/project_registry/README.md` ja `docs/governance/project_registry/TEMPLATE.md`.
- Aliprojektien työnkulku- ja järjestelmäohjeet: `Electronic-Frailty-Index/`, `Fear-of-Falling/`, `Quantify-FOF-Utilization-Costs/` ja `DEAC-Frailty-Index/`.
- Ownerin 2026-11-18 toteutushyväksyntä sekä PR #229:n katselmointikorjausvaltuutus (revisio `66659456b09fdee12843a6428dd2d62fa2cd4c4a` -> katselmointikorjauserä).

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
  - `tasks/04-done/workflow-guidance-alignment-001.md` (Ownerin `2026-11-18T17:23:22Z` hyväksyntä- ja sulkuvaltuutuksella `#issuecomment-6986138907`)
- Sallitut paikalliset `gitignored`-tulokset (ei commitoida):
  - `tools/project_registry/outputs/projects.csv` (sekä generaattorin atomisen julkaisun väliaikaistiedostot)
- Rajauksen ulkopuoliset toimet: historiallisten tai muiden tehtäväkorttien, `tasks/_template.md`:n, muutoslokien (`CHANGELOG*`, `10_handover.md`, `.txt`-viennit), `CLAUDE.md`-konventioiden, `DEAC_HANDOVER.md`:n tai koodi-/analyysiskriptien muuttaminen; tutkimusajot; merge, `04-done` ja siivous.

## Definition of Done (DoD)

- [x] `WORKFLOW.md` ja `SKILLS.md` ohjaavat perustamaan eristetyn tehtäväworktreen varmennetusta täydestä commit-SHA:sta, erottavat valmistumisen (`03-review`), `main`-toimituksen / `TASK`-kohtaisen teknisen `04-done`-sulun, `PRJ`-tason valmistumiskriteerit sekä ehdollisen, erikseen valtuutettavan siivouksen (ilman ajettavaa poistolohkoa tai `--force`/`branch -D`/`|| true`-ohituksia).
- [x] Aliprojektien `WORKFLOW.md`-, `agent_workflow.md`- ja `Fear-of-Falling/tasks/_template.md` -tiedostoista on poistettu vanhat automaattiset `git pull`-, suorapush (`or main if permitted`)-, `03-review`-mergen esto- ja automaattiset `04-done`-ohjeet, ja jokainen elinkaarisiirto säilyttää kortin oman tehtäväjonon sekä päivittää linkitetyn `PRJ-*.md`-polun.
- [x] Etusijalauseet (ml. `SKILLS.md`) on rajattu hallinnolliseen työnkulkuun fail-closed-ristiriitasäännöllä, `DoD gate` ja Quantifyn `Full Run` vastaavat tehtävän luonnetta, FOF:n PS7-/Termux-hakemistosäännöt sallivat rajatun repojuuren porttikontekstin ja kaikki 102 suhteellista Markdown-linkkiä täsmäävät tiedostokohtaisesti.
- [x] Suojatut tutkimus-, tietosuoja-, `K18/QC`- ja ympäristöosiot ovat säilyneet tavuntarkasti muuttumattomina lähtörevisioon (`8e71adfa...`) verrattuna lukuun ottamatta Ownerin nimenomaisesti valtuuttamia kolmea rajattua soveltamisalatäsmennystä, jotka on eritelty alla.
- [x] `PRJ-WORKFLOW-GUIDANCE-ALIGNMENT.md` ja `tools/project_registry/outputs/projects.csv` läpäisevät lähdehash-, `--verify-guard`-, determinismi-, `--check`-, `git check-ignore`- ja yksikkötestit.
- [x] Muuttuneet Markdown-ohjeet läpäisevät `prettier --check`-, `markdownlint-cli2`-, LF-, `git diff --check`- ja `tools/run-gates.ps1 --mode pre-push --smoke` -tarkistukset; staattinen toimintatapavertailu ja Sourceryn 14 havainnon vastinetaulukko on kirjattu, ja suorittamattomat ajonaikaiset testit on merkitty `NOT_RUN`.
- [x] Katselmoitava PR (#229) ja katselmointikorjauserä on toimitettu ja tehtäväkortti on polussa `tasks/03-review/workflow-guidance-alignment-001.md`.
- [x] PR:n uusi täsmärevisio (`fa29be19258f4a585af2afd76d97eed6051567b1`) on saanut riippumattoman ihmishyväksynnän (`Tupatuko2023`, `2026-11-18T17:23:22Z`, `#issuecomment-6986138907`), toimitettu `origin/main`iin (`8657ea22e79bc14c35b04d0f43e934d7a8e95b17`) ja tekninen `04-done`-sulku on valmisteltu erilliseen sulku-PR:ään paikallisen menettelyn mukaisesti.

## Riippumaton ihmishyväksyntä, `main`-toimitus, tekninen sulku ja työpuun säilytys

1. **Riippumaton ihmishyväksyntänäyttö (`SKILLS.md`):**
   - Hyväksyjä: Tomi Korpi (`Tupatuko2023`)
   - Päätöksen aika: `2026-11-18T17:23:22Z` (`2026-11-18T19:23:22+02:00`)
   - Kohdetehtävä ja projekti: `workflow-guidance-alignment-001` / `PRJ-WORKFLOW-GUIDANCE-ALIGNMENT`
   - Hyväksytty täsmärevisio: `fa29be19258f4a585af2afd76d97eed6051567b1`
   - Pysyvä hyväksyntä-URL: <https://github.com/Tupatuko2023/Python-R-Scripts/pull/229#issuecomment-6986138907>
2. **Varmennettu `main`-toimitus (erillään teknisestä sulusta):**
   - Sisältö-PR [#229](https://github.com/Tupatuko2023/Python-R-Scripts/pull/229) yhdistettiin `--squash --match-head-commit fa29be19258f4a585af2afd76d97eed6051567b1` -suojauksella ilman haaran poistoa (`mergedAt: 2026-11-18T17:26:27Z`).
   - `git fetch origin main` vahvisti kanoniseksi `origin/main`-merge-commitiksi `8657ea22e79bc14c35b04d0f43e934d7a8e95b17` (kaikki 17 hyväksyttyä polkua toimitettiin `origin/main`iin).
3. **Tekninen `04-done`-sulku ja projektin valmistumiskriteerien (`done_criterion`) tarkistus:**
   - Tehtäväkortti on siirretty polkuun `tasks/04-done/workflow-guidance-alignment-001.md` (`DONE`).
   - Projektin `PRJ-WORKFLOW-GUIDANCE-ALIGNMENT` oma `done_criterion` tarkistettiin ennen projektin tilapäivitystä: kaikki kolme lähdekuvauksen osa-aluetta (valmistumisen/`main`-toimituksen/siivouksen erottelu, aliprojektien suorapush- ja `DONE`-ohjeiden korjaus sekä hallinnollisen etusijan ja polkuviittausten selkeytys tutkimus-/tietosuoja-/QC-/ympäristösuojaukset säilyttäen) on yhtenäistetty, validoitu, hyväksytty ja toimitettu `origin/main`iin (`8657ea22...`), muita avoimia tehtäviä ei projektissa ole (`tasks: ["workflow-guidance-alignment-001"]`) ja tehtävä suljetaan tässä sulku-PR:ssä -> `PRJ-WORKFLOW-GUIDANCE-ALIGNMENT.md` on asetettu tilaan `closed` / `delivered` (`completed_date: "2026-11-18"`).
4. **Suorittamattomat ajonaikaiset testit (`NOT_RUN`, erillään dokumentaatiovalidoinnista):**
   - Windows PowerShell 7 `Fear-of-Falling/scripts/ps7/run_gemini_orchestrator.ps1` ajonaikainen promptin lataus- ja käyttäytymisajo: `NOT_RUN`
   - Termux/PRoot-ajonaikainen promptin lataus- ja käyttäytymistesti (`SYSTEM_PROMPT_TERMUX_S-FOF.md`): `NOT_RUN`
5. **Työpuun ja haarojen säilytys (`retained`, erillään `main`-toimituksesta ja sulusta):**
   - Eristetty tehtäväworktree `tmp/workflow-guidance-alignment-001`, tehtävähaara `docs/workflow-guidance-alignment-001` (`fa29be19258f4a585af2afd76d97eed6051567b1`), sen etähaara, tämä sulkuhaara `chore/workflow-guidance-alignment-closeout-001`, likainen päächeckout sekä kaikki 13 aiempaa työpuuta on säilytetty koskemattomina ilman poistoja.

## Katselmointivastineet (Sourcery PR #229, 14 havaintoa)

| #   | Sourcery-havainto ja kohde                                                                                                                                | Tila                        | Ratkaisu ja perustelu                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| --- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1   | `SKILLS.md:291,293` — _Unmerged branch can be deleted_ (`gh pr view --json merged` ei pysäytä poistoa)                                                    | `korjattu`                  | Poistettu sellaisenaan ajettava poistolohko ja korvattu 5-kohtaisella ehdollisella siivousmenettelyllä: erillinen nimetty valtuutus, `origin/main`- ja squash-merge-toimitusnäyttö, sisällön ja aktiivisen käytön tarkistus, oikea järjestys ja välitön pysäytys virheessä ilman `--force`-, `branch -D`- tai virheiden ohitusmenettelyä.                                                                                                                                                                                |
| 2   | `SKILLS.md:221-223,228` — _Unrelated edits enter task branch_ (`git switch -c` jaetussa checkoutissa)                                                     | `korjattu`                  | Korvattu jaetun checkoutin `git switch -c` eristetyn tehtäväworktreen (`git worktree add -b ...`) perustamisella; päächeckoutin haaraan tai paikallisiin muutoksiin ei kosketa.                                                                                                                                                                                                                                                                                                                                          |
| 3   | `WORKFLOW.md:4-6`, `SKILLS.md:5,9` — _Research safeguards can be overridden_ (`SKILLS.md` voitti kaikissa ristiriidoissa)                                 | `korjattu`                  | Yhdenmukaistettu `SKILLS.md`:n oma etusijalause hallinnolliseen työnkulkuun, säilytetty aliprojektien tiukemmat tutkimus-, tietosuoja-, QC- ja ympäristörajat ja lisätty fail-closed-sääntö: ratkaisematon ristiriita pysäyttää riippuvan toimenpiteen eikä anna lupaa valita heikompaa sääntöä.                                                                                                                                                                                                                         |
| 4   | `Quantify-FOF-Utilization-Costs/GEMINI.md:45,50` — _Documentation tasks run analysis_ (`Full Run` pakollinen kaikille tehtäville)                         | `korjattu`                  | Täsmennetty Ownerin valtuutuksella `WORKFLOW & GATES (DoD)` -osiossa `Smoke Test`- ja `Full Run` -vaiheiden soveltamisala: analyysi edellyttää analyysia tarvitsevaa tehtävää, tehtäväkohtaista valtuutusta ja kaikkien turvaporttien (Option B, `DATA_ROOT`, aggregaattien kaksiosainen valtuutus, `n < 5`) täyttymistä; dokumentaatiotehtävä ei käynnistä `Full Run` -ajoa.                                                                                                                                            |
| 5   | `tasks/02-in-progress/workflow-guidance-alignment-001.md:5`, `PRJ-...:12,60` — _Review handoff remains unrecorded_                                        | `vanhentunut`               | Sourcery arvioi PR:n avaushetken välirevisiota (`0fb0f2de...`). Jo edellisessä katselmointicommitissa (`66659456...`) ja tässä revisiossa tehtäväkortti on siirretty polkuun `tasks/03-review/workflow-guidance-alignment-001.md` (`REVIEW`) ja rekisterin tehtäväviite osoittaa samaan `03-review`-polkuun.                                                                                                                                                                                                             |
| 6   | `SKILLS.md:227-228` — _Task branch uses an unverified base_ (`origin/main` ei lukittu täyteen SHA:han)                                                    | `korjattu`                  | `SKILLS.md`, `WORKFLOW.md` ja aliprojektien työnkulkuohjeet ottavat `git fetch origin main` -haun jälkeen talteen varmennetun täyden commit-SHA:n (`BASE_SHA="$(git rev-parse --verify origin/main^{commit})"`) ja perustavat eristetyn tehtäväworktreen suoraan siitä.                                                                                                                                                                                                                                                  |
| 7   | `WORKFLOW.md:73-74` — _One task closes its project_ (`PRJ-*.md` merkittiin suljetuksi tehtävän sulussa)                                                   | `korjattu`                  | Erotettu `TASK`-kortin `04-done`-sulku `PRJ-*.md`-projektin sulusta `WORKFLOW.md`:ssä, `SKILLS.md`:ssä ja aliprojektien ohjeissa: projektin `state`- ja `delivery`-kentät määräytyvät projektin omista valmistumiskriteereistä (`done_criterion`), avoimista tehtävistä ja koko projektin toimitusnäytöstä; yhden tehtävän `DONE` ei automaattisesti sulje projektia.                                                                                                                                                    |
| 8   | `SKILLS.md:228` — _Concurrent branch switches mix work_ (rinnakkaiset ajot samassa checkoutissa)                                                          | `korjattu`                  | `SKILLS.md` ja `WORKFLOW.md` edellyttävät jokaiselle tehtävälle ja rinnakkaiselle agenttiajolle omaa eristettyä tehtäväworktreetä; päächeckoutissa ei vaihdeta haaraa.                                                                                                                                                                                                                                                                                                                                                   |
| 9   | `Fear-of-Falling/WORKFLOW.md:9-13`, `agent_workflow.md:21`, S-FOF PS7/Termux prompts — _Required gates conflict with directory rule_                      | `korjattu`                  | Lisätty Ownerin valtuuttama rajattu `Working Directory` -täsmennys `SYSTEM_PROMPT_POWERSHELL7_S-FOF.md`:ään (`Push-Location ..; try { ... } finally { Pop-Location }`) ja `SYSTEM_PROMPT_TERMUX_S-FOF.md`:ään (`(cd .. && ...)`) sekä yhdenmukaistettu FOF:n `WORKFLOW.md`, `agent_workflow.md` ja `tasks/_template.md`: analyysit ja tutkimus-QC ajetaan aina `Fear-of-Falling/`-työjuuresta ja valtuutetut repojuuren hallinta-/rekisteriportit saman eristetyn worktreen repojuuresta rajatussa suorituskontekstissa. |
| 10  | `SKILLS.md:292` — _Local branch cleanup fails_ (`git branch -d` epäonnistuu checked-out-haaralle ja etäpoisto jatkuu)                                     | `korjattu`                  | Korvattu ehdollisella siivousjärjestyksellä: poistutaan ensin worktreestä -> `git worktree remove` -> `git branch -d` -> vasta virheettömien edeltävien vaiheiden jälkeen `git push origin --delete`; mikä tahansa epäonnistuminen pysäyttää ketjun välittömästi.                                                                                                                                                                                                                                                        |
| 11  | `WORKFLOW.md:60-61` — _Registry task link goes stale_ (rekisterin tehtäväpolku ei päivity siirrossa)                                                      | `korjattu`                  | `WORKFLOW.md`, `SKILLS.md` ja aliprojektien työnkulkuohjeet velvoittavat päivittämään linkitetyn `PRJ-*.md`-rekisteritietueen tehtävätaulukon polun samassa elinkaarimuutoksessa jokaisen korttisiirron yhteydessä.                                                                                                                                                                                                                                                                                                      |
| 12  | `WORKFLOW.md:24,60` — _Subproject tasks enter the wrong queue_ (paljaat `tasks/...`-polut ohjasivat päärepon jonoon)                                      | `korjattu`                  | `WORKFLOW.md` ja `SKILLS.md` määrittelevät tehtävän oman kiinteän tehtäväjonon (`<queue-root>`: `tasks/` tai `<aliprojekti>/tasks/`) ja käyttävät sitä jokaisessa elinkaarisiirrossa; aliprojektien ohjeet käyttävät eksplisiittisiä `<aliprojekti>/tasks/...`-polkuja.                                                                                                                                                                                                                                                  |
| 13  | `WORKFLOW.md:50-56` vs. `SKILLS.md:39` — _Required smoke test is waived_ (`DoD gate` vaati aina analyysi-smoke-runin)                                     | `korjattu`                  | Yhdenmukaistettu `SKILLS.md`:n `DoD gate` ja `WORKFLOW.md` tehtävän luonteen mukaisiksi: soveltuvat toimitus- ja dokumentaatiotarkistukset ovat aina pakollisia, analyysi-/koodi-/ympäristömuutokset vaativat aliprojektin smoke/QC-ajot, mutta puhdas hallintodokumentaation muutos ei itsessään valtuuta tutkimusajoa tai suojatun aineiston lukua (`K18/QC Applicability Decision Gate` pidetty muuttumattomana).                                                                                                     |
| 14  | `tasks/.../workflow-guidance-alignment-001.md` — _New task card has English headings_ (`Context`, `Inputs`, `Outputs`, `DoD`, `Log`, `Blockers`, `Links`) | `perustellusti ei muutosta` | Tarkistettu päärepon kanoninen tehtäväpohja `tasks/_template.md`, joka määrittelee nämä täsmälliset englanninkieliset rakenneotsikot koko päärepon tehtäväjonolle, eikä `tasks/_template.md` kuulu tämän tehtävän hyväksyttyihin kirjoituspolkuihin. Kaikki kortin varsinainen sisältöteksti ja lisätyt alaotsikot ovat suomeksi.                                                                                                                                                                                        |

## Staattinen toimintatapavertailu ja tarkistusnäyttö

> Huomio: Alla oleva nelikohtainen vertailu on dokumentoitu **staattinen ohjevertailu** (ei ajonaikainen järjestelmä- tai orkestrointitesti).

| Tapaus                                                                               | Aiempi ohjeristiriita (`8e71adfa...`)                                                                                                                                                                   | Yhtenäistetty sääntö tässä PR:ssä (#229)                                                                                                                                                                                                                                                                                                                                                       |
| ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. Eristetty aloitus, valmistuminen, `main`-toimitus ja ehdollinen siivous           | `WORKFLOW.md` ohjasi poistamaan tehtäväworktreen heti työn valmistuttua; aiempi `SKILLS.md`-esimerkki käytti jaetun checkoutin `git switch -c`- ja sokeaa poistolohkoa.                                 | Tehtävä aloitetaan aina eristetyssä tehtäväworktreessä varmennetusta täydestä commit-SHA:sta (`BASE_SHA`). Valmistuminen (`03-review`), ihmishyväksytty `main`-toimitus + `TASK`-sulku (`04-done`, erillään `PRJ`-sulusta) sekä erikseen valtuutettu, squash-mergen huomioiva ehdollinen siivous (`retained` oletuksena) on erotettu toisistaan.                                               |
| 2. Aliprojektien PR- ja ihmishyväksyntäportti sekä tarkistusten soveltuvuus          | Aliprojekteissa oli vanhoja `or main if permitted`-, automaattisia `git pull`- ja automaattisia `04-done`-ohjeita sekä dokumentaatiotyöhönkin ulottuva pakollinen `Full Run` / analyysi-smoke-vaatimus. | Kaikki 15 ohjetiedostoa noudattavat `SKILLS.md`:n PR- ja ihmishyväksyntäportteja. Soveltuvat toimitus- ja dokumentaatioportit ovat pakollisia, mutta puhdas hallintodokumentaation muutos ei käynnistä `Full Run` -analyysiajoa tai suojatun aineiston lukua.                                                                                                                                  |
| 3. Hallinnollinen etusija, tehtäväjonot (`<queue-root>`), rekisteripolku ja työjuuri | `SKILLS.md` voitti sanamuodoltaan kaikissa ristiriidoissa; paljaat `tasks/...`-viittaukset, päivittämätön rekisteripolku ja FOF:n ehdoton hakemistosääntö olivat keskenään ristiriidassa.               | Etusija (ml. `SKILLS.md`) on rajattu hallintoon ja ratkaisematon ristiriita pysäyttää toimenpiteen. Jokainen siirto säilyttää kortin oman `<queue-root>`-jonon ja päivittää linkitetyn `PRJ-*.md`-polun samassa muutoksessa. FOF-analyysit pysyvät `Fear-of-Falling/`-juuressa ja valtuutetut repojuuren portit ajetaan saman eristetyn worktreen repojuuressa rajatussa suorituskontekstissa. |
| 4. Työpuun säilytys ja jatkuvuus hyväksytyssä rajauksessa                            | Vanhat ohjeet aiheuttivat epäselvyyttä päächeckoutin muutosten siirtymisestä, väliluvista ja työpuun säilytyksestä.                                                                                     | Toteutus ja katselmointikorjaus etenivät hyväksytyssä 16 polun rajauksessa eristetyssä worktreessä koskematta likaiseen päächeckoutiin tai 13 aiempaan työpuuhun.                                                                                                                                                                                                                              |

### Suojattujen osioiden vertailu lähtörevisioon (`8e71adfa539b05f95361134eb7b8e57e6a898199`)

1. **Tavuntarkasti muuttumattomina säilytetyt suojatut osiot (`PASS`):**
   - `Fear-of-Falling/SYSTEM_PROMPT_POWERSHELL7_S-FOF.md`: rivi 1 (`# GEMINI AGENT CONTEXT: Gemini PowerShell 7 Orchestrator GPT (S-FOF)`), kohdat `3.2`–`3.5` (Data & Security, Fail-Closed, Policy Engine, Table-to-Text Crosscheck) sekä luvut `4`–`7` kokonaisuudessaan.
   - `Fear-of-Falling/SYSTEM_PROMPT_TERMUX_S-FOF.md`: rivi 1 (`# 1. Gemini Termux Orchestrator GPT (S-FOF) - SYSTEM PROMPT`), luvun `1` muut kohdat (Data & Security, Fail-Closed, Table-to-Text Crosscheck) sekä luvut `2`–`6` kokonaisuudessaan.
   - `Fear-of-Falling/agent_workflow.md`: koko `## K18/QC Applicability Decision Gate` -osio.
   - `Fear-of-Falling/tasks/_template.md`: koko `## QC applicability` -osio.
   - `Fear-of-Falling/AGENTS.md`: kaikki luvut ennen `## Change management` -osiota (tuotantosopimus, `AUTH_SOURCE`, `DATA_ROOT`, K18-portti ja polkusäännöt).
   - `Quantify-FOF-Utilization-Costs/GEMINI.md`: `## CRITICAL CONSTRAINTS` kohdat `1`–`3` (Option B, `DATA_ROOT`, Termux-natiivi suoritus, `outputs/`, `n < 5` -suppressio) sekä koko `## OPERATIONAL COMMANDS (HYBRID PIPELINE)` -osio.
   - `Quantify-FOF-Utilization-Costs/AGENTS.md`: koko `## Conflict Resolution Protocol` -osio.
   - `DEAC-Frailty-Index/AGENTS.md`: koko `## Auktoriteetti ja ensimmäinen ajo` -osio (`docs/DEAC_HANDOVER.md`, `METHODS_AND_SCORING.md` §3.1) sekä `## Data ja toteutus` -osion `DATA_ROOT`-, testi- ja laskentarajoitteet.
2. **Ownerin nimenomaisesti valtuuttamat rajatut soveltamisalatäsmennykset (3 kohtaa):**
   - `Quantify-FOF-Utilization-Costs/GEMINI.md` (`## WORKFLOW & GATES (DoD)`): täsmennetty analyysivaiheiden (`Smoke Test` ja `Full Run`) edellyttävän analyysia tarvitsevaa tehtävää, tehtäväkohtaista valtuutusta ja voimassa olevien turvaporttien täyttymistä; dokumentaatiotehtävä ei käynnistä `Full Run` -ajoa.
   - `Fear-of-Falling/SYSTEM_PROMPT_POWERSHELL7_S-FOF.md` (`3.1 Working Directory`): säilytetty `Fear-of-Falling\`-työjuuri kaikille analyyseille ja tutkimus-QC:lle ja sallittu vain valtuutettujen repojuuren hallinta-/rekisterikomentojen ajo saman eristetyn tehtäväworktreen repojuuressa rajatussa PS7-suorituskontekstissa (`Push-Location ..; try { ... } finally { Pop-Location }`).
   - `Fear-of-Falling/SYSTEM_PROMPT_TERMUX_S-FOF.md` (`1 Working Directory`): vastaava rajattu Termux/Bash-alikuoripoikkeus (`(cd .. && ...)`) valtuutetuille repojuuren hallinta-/rekisterikomennoille oletustyöhakemiston pysyessä `Fear-of-Falling/`-kansiossa.

### Tarkistusten tulokset

- `npx --no-install prettier --check` (15 ei-`tasks/` Markdown-tiedostoa + tämä kortti): **PASS**
- `npx --no-install markdownlint-cli2` (17 Markdown-tiedostoa ml. `Fear-of-Falling/tasks/_template.md` ja tämä kortti): **PASS** (`0 issues`)
- Suhteellisten Markdown-linkkien kohdetarkistus (102 linkkiä kunkin tiedoston hakemistosta): **PASS**
- Vanhentuneiden ja turvattomien merkkijonojen poissaolotarkistus (`gpa1qf`, `or main if permitted`, `edellytys DONE:lle`, `MUST NOT be merged to main unless moved to 04-done`, `Only a human may move`, jaetun checkoutin `git switch -c` sekä sokea `gh pr view --json merged` -poistolohko): **PASS** (`0` osumaa)
- `render_projects_csv.py --print-source-hash`: **PASS** (`6d8d4564d58eef72484dc6901f9a4c9bbb304f2f42afa415c0fa3b43b94fc6d0`)
- `render_projects_csv.py --verify-guard` ennen jokaista rekisteripäivitystä (`7e1955ae...`, `0fb0f2de...`, `66659456...`): **PASS** (`OK`, exit 0)
- `render_projects_csv.py` CSV-generointi kahdesti (determinismi) + `--check` + `git check-ignore -v`: **PASS** (`CSV_HASH_EQUAL=True`, `OK`, exit 0)
- `python -B -m unittest discover -s tools/project_registry/tests -p test_render_projects_csv.py`: **PASS** (`60 passed`, **`SKIPPED: 2`** Windows-symlink-testiä)
- LF-rivinvaihtojen ja `git diff --cached --check` -tarkistus: **PASS**
- `& ./tools/run-gates.ps1 --mode pre-push --smoke`: **PASS** (exit 0)
- Tutkimusajot, K18/QC-skriptit sekä R/Python-analyysiajot: **NOT APPLICABLE** (puhdas hallinto- ja työnkulkuohjemuutos)
- Suorittamattomat ajonaikaiset lataus- ja käyttäytymistestit: **`NOT_RUN`**
  - Windows PowerShell 7 `Fear-of-Falling/scripts/ps7/run_gemini_orchestrator.ps1` ajonaikainen promptin lataus- ja käyttäytymisajo: `NOT_RUN`
  - Termux/PRoot-ajonaikainen promptin lataus- ja käyttäytymistesti (`SYSTEM_PROMPT_TERMUX_S-FOF.md`): `NOT_RUN`

## Log

- 2026-11-18T17:35:00+02:00: Suoritettu read-only-nykytilan lukutarkastus suoraan `origin/main`-revisiosta `8e71adfa539b05f95361134eb7b8e57e6a898199` ja valmisteltu 16 polun kirjoitusrajaus projektille `PRJ-WORKFLOW-GUIDANCE-ALIGNMENT`.
- 2026-11-18T17:49:00+02:00: Owner hyväksyi kirjoitusrajauksen, lähdekuvauksen ja toimitusrajan PR-katselmointiin asti. `git fetch origin main` vahvisti lähtörevisioksi `8e71adfa539b05f95361134eb7b8e57e6a898199`. Perustettu eristetty worktree `tmp/workflow-guidance-alignment-001` ja haara `docs/workflow-guidance-alignment-001` koskematta päächeckoutiin tai olemassa oleviin työpuihin. Valmisteltu `READY`-kortti ja projektitietue tilaan `planned / not_delivered` (`7e1955ae15da43dd2dfd093bdc7c88bf77af0684`).
- 2026-11-18T17:56:00+02:00: Suoritettu `--verify-guard` (`OK`, exit 0) revisiota `7e1955ae15da43dd2dfd093bdc7c88bf77af0684` vasten, siirretty kortti `01-ready` -> `02-in-progress`, vaihdettu `PRJ-WORKFLOW-GUIDANCE-ALIGNMENT.md` tilaan `active / not_delivered` ja toteutettu 15 ohjetiedostopäivitystä (`0fb0f2dec52205818f498948831959ac9b458c05`).
- 2026-11-18T18:02:00+02:00: Varmennettu projektirekisterin yksikkötestit (`62 ran, OK, skipped=2`), suoritettu `--verify-guard` (`OK`, exit 0) revisiota `0fb0f2dec52205818f498948831959ac9b458c05` vasten, avattu PR #229 (<https://github.com/Tupatuko2023/Python-R-Scripts/pull/229>) ja siirretty tehtäväkortti polkuun `tasks/03-review/workflow-guidance-alignment-001.md` (`66659456b09fdee12843a6428dd2d62fa2cd4c4a`).
- 2026-11-18T18:22:00+02:00: Toteutettu Ownerin hyväksymä koottu katselmointikorjauserä PR #229:n Sourcery-havaintoihin (14 havaintoa käsitelty vastinetaulukossa: 12 korjattu, 1 vanhentunut, 1 perustellusti ei muutosta), suoritettu `--verify-guard` (`OK`, exit 0) revisiota `66659456b09fdee12843a6428dd2d62fa2cd4c4a` vasten, päivitetty `PRJ-WORKFLOW-GUIDANCE-ALIGNMENT.md` ja generoitu `projects.csv`, sekä toistettu kaikki soveltuvat Markdown-, linkki-, rekisteri- ja toimitusportit (`fa29be19258f4a585af2afd76d97eed6051567b1`).
- 2026-11-18T19:27:00+02:00: Varmennettu Ownerin (`Tupatuko2023`) pysyvä ihmishyväksyntä ja sulkuvaltuutus (`2026-11-18T17:23:22Z`, `#issuecomment-6986138907`) täsmärevisiolle `fa29be19258f4a585af2afd76d97eed6051567b1`, yhdistetty PR #229 `--squash --match-head-commit` -suojauksella ilman haaran poistoa, varmennettu `origin/main`-toimitus (`8657ea22e79bc14c35b04d0f43e934d7a8e95b17`), tarkistettu projektin `PRJ-WORKFLOW-GUIDANCE-ALIGNMENT` valmistumiskriteerit (`done_criterion`), suoritettu `--verify-guard` (`OK`, exit 0), siirretty kortti polkuun `tasks/04-done/workflow-guidance-alignment-001.md` (`DONE`), päivitetty `PRJ-WORKFLOW-GUIDANCE-ALIGNMENT.md` tilaan `closed / delivered` (työpuu ja haarat `retained`, ajonaikaiset PS7/Termux-testit `NOT_RUN`), generoitu `projects.csv` ja avattu sulku-PR ihmiskatselmointiin.

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
