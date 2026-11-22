---
id: "PRJ-ANTIGRAVITY-HARNESS"
title: "Antigravity Harness"
short_name: "Antigravity Harness"
repo: "Tupatuko2023/Python-R-Scripts"
repo_ref: "origin/main"
state: "active"
delivery: "not_delivered"
goal: "Rakentaa toistettava Antigravity CLI -työnkulku, jolla agentti löytää väitteen lähteen, osoittaa tarkistetun yhteyden ja tunnistaa, milloin muutoksen syy tai tiedon siirtotapa jää avoimeksi."
done_criterion: "Ensimmäisessä vaiheessa toinen istunto pystyy toistamaan dokumentoidun synteettisen tiedostohaun ja vertaamaan vastausta ennakolta kirjattuihin odotuksiin niin, että raportista käyvät ilmi löydetyt lähteet, perustellut ja perusteettomat päätelmät sekä ajon rajoitteet; projekti suljetaan vasta ihmisomistajan hyväksynnällä."
latest_status: "2026-11-22: PRJ-ANTIGRAVITY-HARNESS ja aiemman E1 R_P -lähdejäljityspilotin julkaisuun rajattu tehtäväkortti (PR #248, 4d0d08f7…) on viety PR-katselmointiin omissa työpuissaan. Pilotin kahdessa A/B-parissa (kaikissa nolla työkalukutsua) B rajasi versiovälin tarkemmin, mutta B2 esitti perusteettoman päätelmän käsin kopioinnista ja virheellisen selityksen rivisiirtymälle. Mekanismin lähdettä kysyvä uusi ohje on vielä testaamatta."
next_step: "Katselmoi perustamis- ja pilotti-PR:t ja toteuta sen jälkeen erillisessä tehtävässä työpaketti WP-HARNESS-SYNTH-FILE-SEARCH-01, jonka ensimmäinen onnistumiskriteeri on, että uusi CLI-istunto löytää synteettisestä työtilasta oikean lähdetiedoston ja osoittaa kohderivin täsmällisellä viitteellä; B- ja B′-ohjeiden vertailu tehdään vasta, kun tämä tiedostopohjainen lähtötaso toimii."
source_description_sha256: "c01dbe65b20745aa873259765a97223d39fb4f1f02b528670f8be97e6037e86f"
source_captured_at: "2026-11-22"
observed_at: "2026-11-22"
observed_commit: "5ac1694491d786d4398132e687556af12416a02e"
observed_worktree_label: "antigravity-harness-registry-20261122"
blocker: "Antigravity CLI 1.5.14 ei rajoita natiivia read_file-työkalua työhakemistoon --sandbox-tilassa eikä salli mcpServers-asetuksen tyhjennystä --settings-lipulla, joten tiedostopohjainen lähdehaku on todennettava ensin erillisessä synteettisessä työtilassa ilman suojattua tutkimusaineistoa. Mekanismin lähdettä vaativa uusi ohje on vielä testaamatta."
orchestrator: "Owner"
agent: "Termux Antigravity"
agent_tool: "Antigravity CLI"
environment: "Android Termux"
started_date: "2026-11-21"
paused_date: ""
completed_date: ""
pause_reason: ""
link: ""
worktree_inventory: "unknown"
tasks:
  - "TASK-AGY-AIM1-NB-TRACE-PILOT-20261121"
  - "TASK-ANTIGRAVITY-HARNESS-REGISTRY-001"
---

## Antigravity Harness

## Lähdekuvaus

<!-- prettier-ignore-start -->
<!-- source-description:begin -->
Koska projekti on työläs meidän pitää tehdä tästä harness tehtävästä oikea projekti projekti työkalulla, lue /worktrees/agy-aim1-nb-trace-pilot-20261121/docs/governance/project_registry/README.md.
<!-- source-description:end -->
<!-- prettier-ignore-end -->

## Tehtäväviitteet

| repo                            | task                                    | path                                                       |
| ------------------------------- | --------------------------------------- | ---------------------------------------------------------- |
| `Tupatuko2023/Python-R-Scripts` | `TASK-AGY-AIM1-NB-TRACE-PILOT-20261121` | `tasks/03-review/TASK-AGY-AIM1-NB-TRACE-PILOT-20261121.md` |
| `Tupatuko2023/Python-R-Scripts` | `TASK-ANTIGRAVITY-HARNESS-REGISTRY-001` | `tasks/03-review/TASK-ANTIGRAVITY-HARNESS-REGISTRY-001.md` |

## Kehittyvä työsuunnitelma ja jatkamismuistio

- **Projektin tarkoitus ja 1. vaiheen valmistumiskriteeri:** rakennetaan toistettava Antigravity CLI -työnkulku, jolla agentti löytää väitteen lähteen, osoittaa tarkistetun yhteyden ja tunnistaa, milloin muutoksen syy tai tiedon siirtotapa jää avoimeksi. Ensimmäinen vaihe valmistuu, kun toinen istunto pystyy toistamaan dokumentoidun synteettisen tiedostohaun ja vertaamaan vastausta ennakolta kirjattuihin odotuksiin niin, että raportista käyvät ilmi löydetyt lähteet, perustellut ja perusteettomat päätelmät sekä ajon rajoitteet.
- **Päivätty pilottihavainto (2026-11-22):** erillisessä työpuussa (`agy-aim1-nb-trace-pilot-20261121`, katselmointi-PR #248 commitissa `4d0d08f78ea6de8757db4bb0dd5f357b1faba6ce`, kortti `tasks/03-review/TASK-AGY-AIM1-NB-TRACE-PILOT-20261121.md`) suoritettiin kaksi A/B-paria (`A1`/`B1` ja positiivinen kontrolli `A2`/`B2`) samalla AIM1 `E1 R_P` -taulukkorivillä lähdeotteiden tulkintakokeena; kaikissa neljässä istunnossa oli nolla työkalukutsua (`tool_calls_count = 0`). B-haaran tarkistus rajasi todistetun versiovälin ja rivin A-haaraa tarkemmin, mutta jälkikatselmoinnissa havaittiin, että `B2` esitti silti perusteettoman päätelmän käsin kopioinnista ja virheellisen syyselityksen liitteen S2 rivisiirtymälle (`L243 → L245`). Yksityiset käsikirjoitusotteet, avoimet tutkimustulokset, vastausavaimet ja raakalokit pidetään paikallisina.
- **Pilottiviitteen elinkaarihuomio:** pilottikortin nykyinen repojuureen suhteutettu polku on `tasks/03-review/TASK-AGY-AIM1-NB-TRACE-PILOT-20261121.md`; jos pilottikortti siirtyy katselmoinnin aikana `tasks/04-done/TASK-AGY-AIM1-NB-TRACE-PILOT-20261121.md`-polkuun ennen tämän perustamis-PR:n yhdistämistä, yllä oleva viitetaulukko päivitetään lopulliseen polkuun ennen mergeä.
- **Uusi, vielä testaamaton tarkistusehdotus (B′):** tuleviin lähdejäljitystehtäviin on kirjattu ehdolle sanamuoto: _”Tarkista jokaisesta pääpäätelmästä, mitä näytetty lähde osoittaa. Jos selität, miten luku siirrettiin tai miksi muutos tapahtui, yksilöi myös tämän selityksen lähde tai jätä mekanismi avoimeksi.”_
- **Seuraava työpaketti (`WP-HARNESS-SYNTH-FILE-SEARCH-01`):** ensimmäisenä onnistumiskriteerinä uusi CLI-istunto löytää erillisestä synteettisestä työtilasta oikean lähdetiedoston ja osoittaa kohderivin täsmällisellä viitteellä ilman suojattua tutkimusdataa. Kun tämä tiedostopohjainen lähtötaso toimii, voidaan mitata uuden mekanismiohjeen lisähyötyä vertaamalla aiempaa B-ohjetta ja uudella ohjeella täydennettyä B′-ohjetta samoilla tiedostoilla ja työkaluilla.
- **Vaiheiden erottelu (2026-11-22):** perustamistietue ja pilottikortti on toimitettu PR-katselmointiin omissa työpuissaan; ihmisomistajan hyväksyntä on avoin, `origin/main`-toimitusta ei ole tehty (`not_delivered`) eikä työpuiden siivousta ole suoritettu.

## Worktree-havainnot

| label                                 | state    | evidence                                                                                                     |
| ------------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------ |
| antigravity-harness-registry-20261122 | active   | Puhdas `origin/main`-pohjainen (`5ac16944…`) perustamistyöpuu perustettu 22.11.2026; siivousta ei ole tehty. |
| agy-aim1-nb-trace-pilot-20261121      | retained | `E1 R_P` -pilotin erillinen työpuu (PR #248, `4d0d08f7…`), jonka paikalliset otteet ja lokit on säilytetty.  |
| shared-main-checkout                  | retained | Jaettu päätyöpuu (`919b5cc`), jossa muiden töiden paikalliset muutokset on säilytetty koskemattomina.        |

Inventaarion kattavuus on `unknown`; taulukko kirjaa vain tähän perustamiseen liittyvät tunnetut työpuut.
