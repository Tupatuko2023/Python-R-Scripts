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
latest_status: "2026-11-22: WP-HARNESS-SYNTH-FILE-SEARCH-01 on katselmoitavana PR #250:ssä. Kahdessa riippumattomassa tuoreessa synteettisessä CLI-ajossa (da5edbee… ja 4e545ac4…, gemini-4-carbon-medium) molemmat istunnot löysivät oikean lähdetiedoston runs/20261119_model_s2_primary/model_estimates.tsv ja kohderivin rivi 4 sekä rajasivat avoimet kohdat oikein (source_search_pass = True molemmissa); Ajossa 1 myös tiukka lokiraja täyttyi (primary_criterion_pass = True), kun taas Ajossa 2 kaksi mcp/sqlite/*.json-kuvaustiedoston read_file-lukua ilman SQLite-työkalun suoritusta antoi tiukalla rajauksella log_compliance_pass = False."
next_step: "Katselmoi PR #250 (jossa arviointiraportti erottaa lähdehaun tuloksen ja lokin työkalujen/polkujen sääntöjenmukaisuuden sekä SQLite-kuvaustiedoston luvun ja työkalusuorituksen säilyttäen tiukan yhdistetyn kriteerin), päätä sen yhdistämisestä ja etene seuraavaksi B- ja B′-ohjeiden vertailuun samoilla synteettisillä tiedostoilla ja työkaluilla; päivitä aiempien korttien (#248, #249) viitepolut 04-done-sulun yhteydessä."
source_description_sha256: "c01dbe65b20745aa873259765a97223d39fb4f1f02b528670f8be97e6037e86f"
source_captured_at: "2026-11-22"
observed_at: "2026-11-22"
observed_commit: "463e020f727ec2fc64e2d3dd4207ffda46442798"
observed_worktree_label: "wp-harness-synth-file-search-01"
blocker: "Antigravity CLI 1.5.14 natiivi read_file voi lukea paikallisia polkuja ja estettyjen MCP-palvelimien staattisia kuvaustiedostoja ilman suoritusta, joten kokeet vaativat ulkopuolisen nimeämättömän vastausavainpolun, suojatun tutkimusaineiston poissaolon samasta ympäristöstä sekä tiukan stream-json-jälkitarkistuksen. PR #250:n ihmishyväksyntä ja B vs. B′ -vertailu ovat vielä avoinna."
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
- **Päivätty jatkovaihe `WP-HARNESS-SYNTH-FILE-SEARCH-01` (PR #250, 2026-11-22):** rakennettiin vakiokirjastopohjainen synteettisen työtilan generaattori ja `stream-json`-jälkiarvioija (`tools/antigravity_harness/synth_file_search_fixture.py`), yksikkö- ja regressiotestit (`8/8 OK` Termuxissa ja Debian Linuxissa) sekä toisto-ohje (`tools/antigravity_harness/README.md`), joka erottaa ajossa havaittujen tapahtumien lokitarkistuksen (`log_compliance_pass`) teknisestä hakemistoeristyksestä. Kahdessa riippumattomassa tuoreessa `gemini-4-carbon-medium`-ajossa — **Ajo 1** (`da5edbee…`, `186.19 s`, `30 594` tokenia, vastausavain `05eaf5b1…`) ja **Ajo 2** (`4e545ac4…`, `178.48 s`, `32 626` tokenia, vastausavain `1ff26b8d…`) — molemmat istunnot löysivät oikean lähdetiedoston `runs/20261119_model_s2_primary/model_estimates.tsv` kohderivin `rivi 4` tarkkoine arvoineen (`1.4204`, `1.1102`, `1.8173`, `0.0052`), hylkäsivät kolme harhautustiedostoa ja jättivät QMD-siirtomekanismin perustellusti avoimeksi (`source_search_pass = True` molemmissa). Tallennettujen ajovirtojen rinnakkaisraporteissa (`evaluation_report_v2.{json,md}` alkuperäisten `evaluation_report.{json,md}` rinnalla) Ajo 1 läpäisi myös tiukan lokirajauksen (`log_compliance_pass = True`, `primary_criterion_pass = True`), kun taas Ajossa 2 kiellettyjä työkaluja ei suoritettu (`sqlite_tool_executions = []`), mutta alkukartoituksen `read_file` luki kaksi `mcp/sqlite/*.json`-kuvaustiedostoa (`sqlite_schema_reads = ['list_tables.json', 'execute_query.json']`), mikä antaa säilytetyllä tiukalla polkurajauksella `log_compliance_pass = False` ja `primary_criterion_pass = False`.
- **Uusi, vielä testaamaton tarkistusehdotus (B′):** kun `WP-HARNESS-SYNTH-FILE-SEARCH-01` (PR #250) on katselmoitu, samalla synteettisellä alustalla voidaan verrata nykyistä B-ohjetta ja uudella ohjeella täydennettyä B′-ohjetta (_”Tarkista jokaisesta pääpäätelmästä, mitä näytetty lähde osoittaa. Jos selität, miten luku siirrettiin tai miksi muutos tapahtui, yksilöi myös tämän selityksen lähde tai jätä mekanismi avoimeksi.”_) samoilla tiedostoilla ja työkaluilla.
- **Vaiheiden erottelu (2026-11-22):** PR:t #248 ja #249 on toimitettu `origin/main`-haaraan; `WP-HARNESS-SYNTH-FILE-SEARCH-01` on katselmoitavana PR #250:ssä (`delivery: "not_delivered"` tälle jatkovaiheelle ennen mergeä). Paikallisen pilottinäytön sisältävä työpuu `agy-aim1-nb-trace-pilot-20261121` on säilytetty koskemattomana.

## Worktree-havainnot

| label                                 | state    | evidence                                                                                                         |
| ------------------------------------- | -------- | ---------------------------------------------------------------------------------------------------------------- |
| wp-harness-synth-file-search-01       | active   | Puhdas `origin/main`-pohjainen (`463e020f…`) työpuu työpaketille `WP-HARNESS-SYNTH-FILE-SEARCH-01` (PR #250).    |
| agy-aim1-nb-trace-pilot-20261121      | retained | Säilytetty koskemattomana paikallisen pilottinäytön (otteet, lokit ja rajaamaton korttikopio) turvaamiseksi.     |
| antigravity-harness-registry-20261122 | retained | Perustamisvaiheen työpuu (PR #249 yhdistetty `origin/main`-commitiin `463e020f…`); siivousta ei ole valtuutettu. |
| shared-main-checkout                  | retained | Jaettu päätyöpuu (`919b5cc`), jossa muiden töiden paikalliset muutokset on säilytetty koskemattomina.            |

Inventaarion kattavuus on `unknown`; taulukko kirjaa vain tähän projektiin liittyvät tunnetut työpuut.
