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
latest_status: "2026-11-22: WP-HARNESS-B-VS-BPRIME-02 toimitettiin PR #253:ssä origin/main-haaraan hyväksytyltä täsmärevisiolta 2c02853d… squash-commitilla 3f54f0208e0f3c00064d2ccb675fe68e120d0f8b, ja tehtäväkortti siirrettiin 04-done-jonoon. Neljässä tuoreessa synteettisessä CLI-istunnossa lähdehaku täyttyi 4/4, siirtomekanismin arviointi 4/4 ja lokitarkistus 3/4 (open_mechanism/B luki kaksi rajauksen ulkopuolista SQLite-skeematiedostoa ilman SQLite-työkalusuorituksia; syy jäi avoimeksi). Laadullisena havaintona molemmat B′-vastaukset rajasivat lisäksi avoimeksi malliversion vaihtumisen syyn. Projekti jatkuu aktiivisena."
next_step: "Katselmoi ja yhdistä WP-02:n tekninen 04-done-sulku-PR ja päätä sen jälkeen ihmisomistajan kanssa seuraava työpaketti (esim. monivaiheisempi synteettinen ketju tai aiempien korttien #248 ja #249 tekninen 04-done-sulku)."
source_description_sha256: "c01dbe65b20745aa873259765a97223d39fb4f1f02b528670f8be97e6037e86f"
source_captured_at: "2026-11-22"
observed_at: "2026-11-22"
observed_commit: "3f54f0208e0f3c00064d2ccb675fe68e120d0f8b"
observed_worktree_label: "wp-harness-b-vs-bprime-02-close"
blocker: "Antigravity CLI 1.5.14 natiivi read_file voi lukea paikallisia polkuja ja estettyjen MCP-palvelimien staattisia kuvaustiedostoja ilman suoritusta, joten teknisen hakemistoeristyksen todentaminen pidetään erillään havaitun ajolokin tarkistuksesta ja kokeet ajetaan ilman suojattua tutkimusaineistoa. WP-02:n tekninen 04-done-sulku-PR odottaa ihmiskatselmointia."
orchestrator: "Owner"
agent: "Termux Antigravity"
agent_tool: "Antigravity CLI"
environment: "Android Termux"
started_date: "2026-11-21"
paused_date: ""
completed_date: ""
pause_reason: ""
link: "https://github.com/Tupatuko2023/Python-R-Scripts/pull/253"
worktree_inventory: "unknown"
tasks:
  - "TASK-AGY-AIM1-NB-TRACE-PILOT-20261121"
  - "TASK-ANTIGRAVITY-HARNESS-REGISTRY-001"
  - "TASK-WP-HARNESS-SYNTH-FILE-SEARCH-01"
  - "TASK-WP-HARNESS-B-VS-BPRIME-02"
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
| `Tupatuko2023/Python-R-Scripts` | `TASK-WP-HARNESS-B-VS-BPRIME-02`        | `tasks/04-done/TASK-WP-HARNESS-B-VS-BPRIME-02.md`          |

## Kehittyvä työsuunnitelma ja jatkamismuistio

- **Projektin tarkoitus ja 1. vaiheen valmistumiskriteeri:** rakennetaan toistettava Antigravity CLI -työnkulku, jolla agentti löytää väitteen lähteen, osoittaa tarkistetun yhteyden ja tunnistaa, milloin muutoksen syy tai tiedon siirtotapa jää avoimeksi. Ensimmäinen vaihe valmistuu, kun toinen istunto pystyy toistamaan dokumentoidun synteettisen tiedostohaun ja vertaamaan vastausta ennakolta kirjattuihin odotuksiin niin, että raportista käyvät ilmi löydetyt lähteet, perustellut ja perusteettomat päätelmät sekä ajon rajoitteet.
- **Varmennettu `origin/main`-toimitushistoria (2026-11-22):**
  1. Pilottikortin PR #248 (hyväksytty HEAD `4d0d08f78ea6de8757db4bb0dd5f357b1faba6ce`, squash-merge `6e68aaacc210e573a3ebeb509708eda91f540797`).
  2. Perustamistietueen PR #249 (hyväksytty HEAD `862f324ab8b791a76f6c88603e0cb4769a3bab4a`, squash-merge `463e020f727ec2fc64e2d3dd4207ffda46442798`).
  3. Työpaketin `WP-HARNESS-SYNTH-FILE-SEARCH-01` PR #250 (ihmisomistajan `Tupatuko2023` hyväksymä HEAD `3f3dd2ccbed367849951df38801a499e567b97bc`, squash-merge `039c545a08de86764b90a14b7d28508519e602d3`).
  4. Työpaketin `WP-01` tekninen `04-done`-sulku PR #251 (hyväksytty HEAD `8cd9b92b620e5036f2da36da28f5e6c9202be61a`, squash-merge `e34ea168637934e135c273672cb950709642eb69`).
  5. Työpaketin `WP-HARNESS-B-VS-BPRIME-02` PR #253 (ihmisomistajan `Tupatuko2023` hyväksymä HEAD `2c02853dafee07e934be409c2393bc56c33e987a`, pysyvä hyväksyntä `pull/253#issuecomment-7083337107`, squash-merge `3f54f0208e0f3c00064d2ccb675fe68e120d0f8b` varmennettu `origin/main`ista).
- **Toimitetun työpaketin `WP-HARNESS-SYNTH-FILE-SEARCH-01` havainnot:** synteettisen työtilan generaattori ja `stream-json`-jälkiarvioija (`tools/antigravity_harness/synth_file_search_fixture.py`), yksikkö- ja regressiotestit (`8/8 OK`) sekä toisto-ohje (`tools/antigravity_harness/README.md`) erottavat lähdehaun tuloksen (`source_search_pass`), ajolokissa havaittujen työkalujen ja polkujen sääntöjenmukaisuuden (`log_compliance_pass`, ml. SQLite-kuvaustiedoston luku erillään työkalusuorituksesta) ja erillisenä kysymyksenä pidettävän teknisen hakemistoeristyksen. Kahdessa riippumattomassa tuoreessa `gemini-4-carbon-medium`-ajossa (`da5edbee…` ja `4e545ac4…`) molemmat löysivät oikean lähdetiedoston `runs/20261119_model_s2_primary/model_estimates.tsv` kohderivin `rivi 4` (`1.4204`, `1.1102`, `1.8173`, `0.0052`) ja jättivät QMD-siirtomekanismin avoimeksi (`source_search_pass = PASS` molemmissa; `log_compliance_pass = PASS` Ajossa 1 ja `FAIL` Ajossa 2 kahden `mcp/sqlite/*.json`-skeemaluvun vuoksi ilman työkalusuoritusta).
- **Toimitetun työpaketin `WP-HARNESS-B-VS-BPRIME-02` havainnot:** kahden synteettisen tapauksen (`documented_script` ja `open_mechanism`, ennakkoon lukitut vastausavaimet `821c0557…` ja `d825e7da…`) ja neljän tuoreen `gemini-4-carbon-medium` (`effort=medium`) -istunnon (`b1b8df40…`, `220f6cf0…`, `8c1eea41…`, `70feefa7…`) vertailussa lähdehaku täyttyi `4/4` ja siirtomekanismin arviointi `4/4`: `documented_script`-tapauksessa molemmat osoittivat vientilokin `logs/m2_table_export_20261121T073000Z.txt` (`scripts/render_qmd_outcome_table.py`) ja manifestin `scripts/fit_m2_nb_v2.R`, ja `open_mechanism`-tapauksessa molemmat jättivät `M2_ED_VISITS`-rivin siirtotavan avoimeksi yleistämättä `M1_OUTPATIENT`-lokia. Laadullisena havaintona molemmat `B′`-vastaukset rajasivat lisäksi avoimeksi malliversion vaihtumisen syyn (`unadjusted_nb_v1` -> `adjusted_nb_v2`). Lokitarkistus läpäisi `3/4` ajoa (`open_mechanism / B` luki kaksi rajauksen ulkopuolista SQLite-skeematiedostoa `mcp/sqlite/{list_tables,execute_query}.json`, SQLite-työkalusuorituksia oli `0`, ja poikkeaman syy jäi avoimeksi).
- **Vaiheiden erottelu (2026-11-22):** PR:t #248, #249, #250, #251 ja #253 on toimitettu `origin/main`-haaraan (`3f54f020…`), ja `TASK-WP-HARNESS-B-VS-BPRIME-02` siirretään `tasks/04-done/`-jonoon omassa teknisessä sulku-PR:ssään. Projekti jatkuu aktiivisena (`state: "active"`, `delivery: "not_delivered"` koko monitehtäväiselle projektille). Toteutustyöpuut `wp-harness-b-vs-bprime-02` (neljän ajon vastausavaimet ja raakalokit), `wp-harness-synth-file-search-01` (`WP-01`-lokit ja rinnakkaisraportit) sekä pilottityöpuu `agy-aim1-nb-trace-pilot-20261121` on säilytetty koskemattomina.

## Worktree-havainnot

| label                                 | state    | evidence                                                                                                                                    |
| ------------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| wp-harness-b-vs-bprime-02-close       | active   | Puhdas `origin/main`-pohjainen (`3f54f020…`) sulkutyöpuu tehtävän `TASK-WP-HARNESS-B-VS-BPRIME-02` tekniseen `04-done`-siirtoon.            |
| wp-harness-b-vs-bprime-02             | retained | Säilytetty koskemattomana `WP-02`:n neljän koeajon ennakkoon lukittujen vastausavainten ja raakalokien turvaamiseksi (PR #253 `3f54f020…`). |
| wp-harness-synth-file-search-01-close | retained | `WP-01`:n teknisen `04-done`-sulun työpuu (PR #251 yhdistetty `origin/main`-commitiin `e34ea168…`).                                         |
| wp-harness-synth-file-search-01       | retained | Säilytetty koskemattomana molempien ajojen alkuperäisten `session_stream.jsonl`-lokien ja rinnakkaisten `v1`/`v2`-raporttien turvaamiseksi. |
| agy-aim1-nb-trace-pilot-20261121      | retained | Säilytetty koskemattomana paikallisen pilottinäytön (otteet, lokit ja rajaamaton korttikopio) turvaamiseksi.                                |
| antigravity-harness-registry-20261122 | retained | Perustamisvaiheen työpuu (PR #249 yhdistetty `origin/main`-commitiin `463e020f…`); siivousta ei ole valtuutettu.                            |
| shared-main-checkout                  | retained | Jaettu päätyöpuu (`919b5cc`), jossa muiden töiden paikalliset muutokset on säilytetty koskemattomina.                                       |

Inventaarion kattavuus on `unknown`; taulukko kirjaa vain tähän projektiin liittyvät tunnetut työpuut.
