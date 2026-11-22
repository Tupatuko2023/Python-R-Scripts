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
latest_status: "2026-11-22: WP-HARNESS-SYNTH-FILE-SEARCH-01 toimitettiin PR #250:ssä origin/main-haaraan hyväksytyltä täsmärevisiolta 3f3dd2cc… squash-commitilla 039c545a08de86764b90a14b7d28508519e602d3, ja tehtäväkortti siirrettiin 04-done-jonoon. Kahdessa riippumattomassa synteettisessä CLI-ajossa (da5edbee… ja 4e545ac4…) molemmat istunnot löysivät oikean lähteen ja kohderivin rivi 4 (source_search_pass = True); Ajossa 1 myös lokiraja täyttyi (primary_criterion_pass = True) ja Ajossa 2 kaksi mcp/sqlite/*.json-skeemalukua ilman työkalusuoritusta raportoitiin erikseen (log_compliance_pass = False). Projekti jatkuu aktiivisena."
next_step: "Katselmoi ja yhdistä WP-01:n tekninen 04-done-sulku-PR ja käynnistä sen jälkeen seuraava työpaketti B- ja B′-ohjeiden (mekanismin lähteen vaatimus) vertaamiseksi toimitetun synteettisen tiedostohakualustan päällä samoilla tiedostoilla ja työkaluilla; sulje haluttaessa myös aiemmat kortit (#248, #249) 04-done-jonoon."
source_description_sha256: "c01dbe65b20745aa873259765a97223d39fb4f1f02b528670f8be97e6037e86f"
source_captured_at: "2026-11-22"
observed_at: "2026-11-22"
observed_commit: "039c545a08de86764b90a14b7d28508519e602d3"
observed_worktree_label: "wp-harness-synth-file-search-01-close"
blocker: "Antigravity CLI 1.5.14 natiivi read_file voi lukea paikallisia polkuja ja estettyjen MCP-palvelimien staattisia kuvaustiedostoja ilman suoritusta, joten teknisen hakemistoeristyksen todentaminen pidetään erillään havaitun ajolokin tarkistuksesta ja kokeet ajetaan ilman suojattua tutkimusaineistoa. B- ja B′-ohjeiden vertailu on vielä tekemättä."
orchestrator: "Owner"
agent: "Termux Antigravity"
agent_tool: "Antigravity CLI"
environment: "Android Termux"
started_date: "2026-11-21"
paused_date: ""
completed_date: ""
pause_reason: ""
link: "https://github.com/Tupatuko2023/Python-R-Scripts/pull/250"
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
| `Tupatuko2023/Python-R-Scripts` | `TASK-WP-HARNESS-SYNTH-FILE-SEARCH-01`  | `tasks/04-done/TASK-WP-HARNESS-SYNTH-FILE-SEARCH-01.md`    |

## Kehittyvä työsuunnitelma ja jatkamismuistio

- **Projektin tarkoitus ja 1. vaiheen valmistumiskriteeri:** rakennetaan toistettava Antigravity CLI -työnkulku, jolla agentti löytää väitteen lähteen, osoittaa tarkistetun yhteyden ja tunnistaa, milloin muutoksen syy tai tiedon siirtotapa jää avoimeksi. Ensimmäinen vaihe valmistuu, kun toinen istunto pystyy toistamaan dokumentoidun synteettisen tiedostohaun ja vertaamaan vastausta ennakolta kirjattuihin odotuksiin niin, että raportista käyvät ilmi löydetyt lähteet, perustellut ja perusteettomat päätelmät sekä ajon rajoitteet.
- **Varmennettu `origin/main`-toimitushistoria (2026-11-22):**
  1. Pilottikortin PR #248 (hyväksytty HEAD `4d0d08f78ea6de8757db4bb0dd5f357b1faba6ce`, squash-merge `6e68aaacc210e573a3ebeb509708eda91f540797`).
  2. Perustamistietueen PR #249 (hyväksytty HEAD `862f324ab8b791a76f6c88603e0cb4769a3bab4a`, squash-merge `463e020f727ec2fc64e2d3dd4207ffda46442798`).
  3. Työpaketin `WP-HARNESS-SYNTH-FILE-SEARCH-01` PR #250 (ihmisomistajan `Tupatuko2023` hyväksymä HEAD `3f3dd2ccbed367849951df38801a499e567b97bc`, pysyvä hyväksyntä `pull/250#issuecomment-7078321820`, squash-merge `039c545a08de86764b90a14b7d28508519e602d3` varmennettu `origin/main`ista identtisellä puutiivisteellä `c66f31538750317617feccbd98c8de83c43f8b49`).
- **Toimitetun työpaketin `WP-HARNESS-SYNTH-FILE-SEARCH-01` havainnot:** synteettisen työtilan generaattori ja `stream-json`-jälkiarvioija (`tools/antigravity_harness/synth_file_search_fixture.py`), yksikkö- ja regressiotestit (`8/8 OK`) sekä toisto-ohje (`tools/antigravity_harness/README.md`) erottavat lähdehaun tuloksen (`source_search_pass`), ajolokissa havaittujen työkalujen ja polkujen sääntöjenmukaisuuden (`log_compliance_pass`, ml. SQLite-kuvaustiedoston luku erillään työkalusuorituksesta) ja erillisenä kysymyksenä pidettävän teknisen hakemistoeristyksen. Kahdessa riippumattomassa tuoreessa `gemini-4-carbon-medium`-ajossa (`da5edbee…` ja `4e545ac4…`) molemmat löysivät oikean lähdetiedoston `runs/20261119_model_s2_primary/model_estimates.tsv` kohderivin `rivi 4` (`1.4204`, `1.1102`, `1.8173`, `0.0052`) ja jättivät QMD-siirtomekanismin avoimeksi (`source_search_pass = PASS` molemmissa; `log_compliance_pass = PASS` Ajossa 1 ja `FAIL` Ajossa 2 kahden `mcp/sqlite/*.json`-skeemaluvun vuoksi ilman työkalusuoritusta).
- **Seuraava työpaketti (B vs. B′):** nyt toimitetun synteettisen tiedostohakualustan päällä voidaan verrata nykyistä B-ohjetta ja uudella mekanismiohjeella täydennettyä B′-ohjetta (_”Tarkista jokaisesta pääpäätelmästä, mitä näytetty lähde osoittaa. Jos selität, miten luku siirrettiin tai miksi muutos tapahtui, yksilöi myös tämän selityksen lähde tai jätä mekanismi avoimeksi.”_) samoilla tiedostoilla ja työkaluilla.
- **Vaiheiden erottelu (2026-11-22):** PR:t #248, #249 ja #250 on toimitettu `origin/main`-haaraan, ja `TASK-WP-HARNESS-SYNTH-FILE-SEARCH-01` on siirretty `tasks/04-done/`-jonoon omassa sulku-PR:ssään. Projekti jatkuu aktiivisena (`state: "active"`, `delivery: "not_delivered"` koko monitehtäväiselle projektille). Toteutustyöpuu `wp-harness-synth-file-search-01` (molempien ajojen alkuperäiset lokit ja rinnakkaiset `v1`/`v2`-arviointiraportit) sekä pilottityöpuu `agy-aim1-nb-trace-pilot-20261121` on säilytetty koskemattomina.

## Worktree-havainnot

| label                                 | state    | evidence                                                                                                                                    |
| ------------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| wp-harness-synth-file-search-01-close | active   | Puhdas `origin/main`-pohjainen (`039c545a…`) sulkutyöpuu tehtävän `TASK-WP-HARNESS-SYNTH-FILE-SEARCH-01` `04-done`-siirrolle.               |
| wp-harness-synth-file-search-01       | retained | Säilytetty koskemattomana molempien ajojen alkuperäisten `session_stream.jsonl`-lokien ja rinnakkaisten `v1`/`v2`-raporttien turvaamiseksi. |
| agy-aim1-nb-trace-pilot-20261121      | retained | Säilytetty koskemattomana paikallisen pilottinäytön (otteet, lokit ja rajaamaton korttikopio) turvaamiseksi.                                |
| antigravity-harness-registry-20261122 | retained | Perustamisvaiheen työpuu (PR #249 yhdistetty `origin/main`-commitiin `463e020f…`); siivousta ei ole valtuutettu.                            |
| shared-main-checkout                  | retained | Jaettu päätyöpuu (`919b5cc`), jossa muiden töiden paikalliset muutokset on säilytetty koskemattomina.                                       |

Inventaarion kattavuus on `unknown`; taulukko kirjaa vain tähän projektiin liittyvät tunnetut työpuut.
