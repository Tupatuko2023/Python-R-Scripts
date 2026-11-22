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
latest_status: "2026-11-22: Pilotti-PR #248 (6e68aaac…) ja perustamis-PR #249 (463e020f…) on yhdistetty origin/main-haaraan. Työpaketti WP-HARNESS-SYNTH-FILE-SEARCH-01 on toteutettu ja todennettu paikallisesti (TASK-WP-HARNESS-SYNTH-FILE-SEARCH-01, 03-review): tuore agy-istunto (da5edbee…, gemini-4-carbon-medium) löysi synteettisestä työtilasta oikean lähdetiedoston runs/20261119_model_s2_primary/model_estimates.tsv ja osoitti kohderivin rivi 4 tarkkoine arvoineen ilman kiellettyjä työkaluja tai työtilan ulkopuolisia datapolkuja (PASS)."
next_step: "Katselmoi ja vie PR-katselmointiin WP-HARNESS-SYNTH-FILE-SEARCH-01, toista dokumentoitu synteettinen tiedostohaku toisessa riippumattomassa istunnossa 1. vaiheen valmistumiskriteerin vahvistamiseksi ja vertaa sen jälkeen B- ja B′-ohjeita samoilla tiedostoilla ja työkaluilla; päivitä aiempien korttien (#248, #249) tehtäväviitteet 04-done-polkuihin niiden myöhemmän sulun yhteydessä."
source_description_sha256: "c01dbe65b20745aa873259765a97223d39fb4f1f02b528670f8be97e6037e86f"
source_captured_at: "2026-11-22"
observed_at: "2026-11-22"
observed_commit: "463e020f727ec2fc64e2d3dd4207ffda46442798"
observed_worktree_label: "wp-harness-synth-file-search-01"
blocker: "Antigravity CLI 1.5.14 natiivi read_file ei noudata polkukohtaista permissions.deny-estoa, joten synteettiset ja tulevat kokeet vaativat ulkopuolisen nimeämättömän vastausavainpolun, suojatun tutkimusaineiston poissaolon samasta ajoympäristöstä sekä stream-json-tapahtumavirran polkutarkistuksen. Toisen istunnon toistokoe ja B vs. B′ -vertailu ovat vielä tekemättä."
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
  - "TASK-WP-HARNESS-SYNTH-FILE-SEARCH-01"
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
| `Tupatuko2023/Python-R-Scripts` | `TASK-WP-HARNESS-SYNTH-FILE-SEARCH-01`  | `tasks/03-review/TASK-WP-HARNESS-SYNTH-FILE-SEARCH-01.md`  |

## Kehittyvä työsuunnitelma ja jatkamismuistio

- **Projektin tarkoitus ja 1. vaiheen valmistumiskriteeri:** rakennetaan toistettava Antigravity CLI -työnkulku, jolla agentti löytää väitteen lähteen, osoittaa tarkistetun yhteyden ja tunnistaa, milloin muutoksen syy tai tiedon siirtotapa jää avoimeksi. Ensimmäinen vaihe valmistuu, kun toinen istunto pystyy toistamaan dokumentoidun synteettisen tiedostohaun ja vertaamaan vastausta ennakolta kirjattuihin odotuksiin niin, että raportista käyvät ilmi löydetyt lähteet, perustellut ja perusteettomat päätelmät sekä ajon rajoitteet.
- **Aiemman vaiheen varmennettu `origin/main`-toimitushistoria (2026-11-22):** pilottikortin PR #248 (hyväksytty HEAD `4d0d08f78ea6de8757db4bb0dd5f357b1faba6ce`, squash-merge `6e68aaacc210e573a3ebeb509708eda91f540797`) ja perustamistietueen PR #249 (hyväksytty HEAD `862f324ab8b791a76f6c88603e0cb4769a3bab4a`, squash-merge `463e020f727ec2fc64e2d3dd4207ffda46442798`) yhdistettiin ihmisomistajan hyväksynnöillä `origin/main`-haaraan. Molemmat kortit jätettiin ohjeen mukaisesti `tasks/03-review/`-polkuun yhdistämisen ajaksi; niiden polut tässä taulukossa päivitetään `tasks/04-done/`-polkuihin myöhemmän teknisen `04-done`-siirron yhteydessä.
- **Päivätty jatkovaihe `WP-HARNESS-SYNTH-FILE-SEARCH-01` (2026-11-22):** rakennettiin vakiokirjastopohjainen synteettisen työtilan generaattori ja `stream-json`-jälkiarvioija (`tools/antigravity_harness/synth_file_search_fixture.py`), yksikkötestit (`5/5 OK` Termuxissa ja Debian Linuxissa) sekä toisto-ohje (`tools/antigravity_harness/README.md`). Varmennetussa ajossa (`da5edbee-d179-4ad7-9b84-866d5153b5e7`, `gemini-4-carbon-medium`, `effort=medium`, vastausavain `05eaf5b1…`, vastaus `e83fe5e8…`) tuore istunto käytti vain sallittua `mcp(filesystem/directory_tree)`-listausta ja `7` työtilan sisäistä `read_file`-kutsua (`outside_workspace_paths = []`, `forbidden_tools_used = []`), erotti oikean lähdetiedoston `runs/20261119_model_s2_primary/model_estimates.tsv` kolmesta harhautustiedostosta, osoitti kohderivin `rivi 4` tarkkoine arvoineen (`1.4204`, `1.1102`, `1.8173`, `0.0052`) ja jätti QMD-siirtomekanismin perustellusti avoimeksi (`primary_criterion_pass = True`).
- **Uusi, vielä testaamaton tarkistusehdotus (B′):** kun toinen istunto on toistanut tämän tiedostopohjaisen lähtötason, voidaan verrata nykyistä B-ohjetta ja uudella ohjeella täydennettyä B′-ohjetta (_”Tarkista jokaisesta pääpäätelmästä, mitä näytetty lähde osoittaa. Jos selität, miten luku siirrettiin tai miksi muutos tapahtui, yksilöi myös tämän selityksen lähde tai jätä mekanismi avoimeksi.”_) samoilla tiedostoilla ja työkaluilla.
- **Vaiheiden erottelu (2026-11-22):** aiemmat PR:t #248 ja #249 on toimitettu `origin/main`-haaraan; uusi työpaketti `WP-HARNESS-SYNTH-FILE-SEARCH-01` on paikallisessa `03-review`-tilassa työpuussa `wp-harness-synth-file-search-01` (`delivery: "not_delivered"` tälle jatkovaiheelle). Paikallisen pilottinäytön sisältävä työpuu `agy-aim1-nb-trace-pilot-20261121` on säilytetty koskemattomana.

## Worktree-havainnot

| label                                 | state    | evidence                                                                                                         |
| ------------------------------------- | -------- | ---------------------------------------------------------------------------------------------------------------- |
| wp-harness-synth-file-search-01       | active   | Puhdas `origin/main`-pohjainen (`463e020f…`) työpuu työpaketille `WP-HARNESS-SYNTH-FILE-SEARCH-01` (22.11.2026). |
| agy-aim1-nb-trace-pilot-20261121      | retained | Säilytetty koskemattomana paikallisen pilottinäytön (otteet, lokit ja rajaamaton korttikopio) turvaamiseksi.     |
| antigravity-harness-registry-20261122 | retained | Perustamisvaiheen työpuu (PR #249 yhdistetty `origin/main`-commitiin `463e020f…`); siivousta ei ole valtuutettu. |
| shared-main-checkout                  | retained | Jaettu päätyöpuu (`919b5cc`), jossa muiden töiden paikalliset muutokset on säilytetty koskemattomina.            |

Inventaarion kattavuus on `unknown`; taulukko kirjaa vain tähän projektiin liittyvät tunnetut työpuut.
