# Antigravity Harness: B- ja B′-lähdesidontaohjeiden vertailukoe synteettisellä tiedostohaulla (WP-HARNESS-B-VS-BPRIME-02)

## Context

- Projekti: `PRJ-ANTIGRAVITY-HARNESS` (aktiivinen; `WP-HARNESS-SYNTH-FILE-SEARCH-01` toimitettu `origin/main`-haaraan PR #250:ssä `039c545a08de86764b90a14b7d28508519e602d3` ja suljettu `04-done`-jonoon PR #251:ssä `e34ea168637934e135c273672cb950709642eb69`).
- Tavoite: toteuttaa projektirekisteriin kirjattu B/B′-vertailukoe kahdella synteettisellä tiedostohakutapauksella (`2 tapausta × {B, B′} = 4 tuoretta CLI-ajoa`):
  1. **Tapaus 1 (`documented_script`):** yksilöity ajoloki (`logs/m2_table_export_20261121T073000Z.txt`) ja ajomanifesti (`runs/20261120_m2_primary/run_manifest.json`) osoittavat, millä skriptillä kohderivi tuotettiin (`scripts/fit_m2_nb_v2.R`) ja vietiin käsikirjoitustaulukkoon (`scripts/render_qmd_outcome_table.py`).
  2. **Tapaus 2 (`open_mechanism`):** vastaava tulosrivi (`manuscripts/SYNTH_COHORT_REVIEW_20261121.qmd` rivi `17`) ja lähdetiedosto (`runs/20261120_m2_primary/model_estimates.tsv` rivi `4`) ovat työtilassa, mutta kohderivin tuotanto- ja siirtotapa jää avoimeksi (työtilan loki `logs/m1_table_export_20261119T160000Z.txt` koskee vain riviä `16` `M1_OUTPATIENT`).
- Vertailuasetelma: kummankin parin sisällä tiedostot, työkalut (`cli_settings.json`), malli (`gemini-4-carbon-medium`) ja `effort` (`medium`) pidettiin täsmälleen samoina; B käytti aiempaa lähdesidonnan lopputarkistusta ja B′ lisäsi siihen vain yhden virkkeen:
  _”Jos selität, miten luku siirrettiin tai miksi muutos tapahtui, yksilöi selityksen lähde tai jätä mekanismi avoimeksi.”_
- Pohjarevisio: varmennettu `origin/main` `e34ea168637934e135c273672cb950709642eb69` erillisessä työpuussa `wp-harness-b-vs-bprime-02` (`chore/wp-harness-b-vs-bprime-02`). Kaikki aiemmat työpuut ja lokit on säilytetty koskemattomina.

## Inputs

- `docs/governance/project_registry/PRJ-ANTIGRAVITY-HARNESS.md` (`e34ea168637934e135c273672cb950709642eb69`, tarkistettu `--verify-guard`-komennolla).
- `tools/antigravity_harness/synth_file_search_fixture.py` ja `tools/antigravity_harness/README.md`.
- Paikallinen Antigravity CLI (`agy` `1.5.14`, `gemini-4-carbon-medium`, `effort=medium`).

## Outputs

- B/B′-vertailutapauksien generaattori ja arvioija: `tools/antigravity_harness/b_vs_bprime_comparison.py` (vain Pythonin vakiokirjasto).
- Yksikkötestit: `tools/antigravity_harness/tests/test_b_vs_bprime_comparison.py`.
- Päivitetty ohje: `tools/antigravity_harness/README.md`.
- Päivitetty projektitietue: `docs/governance/project_registry/PRJ-ANTIGRAVITY-HARNESS.md`.
- Tämä tehtäväkortti suljettuna: `tasks/04-done/TASK-WP-HARNESS-B-VS-BPRIME-02.md` (yhdistetty toteutus-PR #253 squash-commitilla `3f54f0208e0f3c00064d2ccb675fe68e120d0f8b`).
- Git-ignoroidut ennakkoon lukitut vastausavaimet, neljän ajon `stream-json`-virrat, raakavastaukset ja arviointiraportit säilytetty paikallisessa työpuussa `wp-harness-b-vs-bprime-02` polussa `tools/antigravity_harness/outputs/wp_b_vs_bprime_20261122T1305Z/` sekä `tools/project_registry/outputs/projects.csv`.
- Sallitut kirjoituspolut:
  - `tasks/01-ready/TASK-WP-HARNESS-B-VS-BPRIME-02.md` -> `tasks/02-in-progress/TASK-WP-HARNESS-B-VS-BPRIME-02.md` -> `tasks/03-review/TASK-WP-HARNESS-B-VS-BPRIME-02.md` -> `tasks/04-done/TASK-WP-HARNESS-B-VS-BPRIME-02.md`
  - `tools/antigravity_harness/b_vs_bprime_comparison.py`
  - `tools/antigravity_harness/tests/test_b_vs_bprime_comparison.py`
  - `tools/antigravity_harness/README.md`
  - `docs/governance/project_registry/PRJ-ANTIGRAVITY-HARNESS.md`
  - ignoroidut `tools/antigravity_harness/outputs/**` ja `tools/project_registry/outputs/projects.csv`

## Definition of Done (DoD)

- [x] Molempien synteettisten tapausten (`documented_script` ja `open_mechanism`) odotetut vastausavaimet lukittiin ennen ensimmäistäkään CLI-ajoa (`2026-11-22T13:04:28Z`) koeagentin työtilan ulkopuoliseen arviointikansioon:
  - `documented_script/eval/expected_answer_key.json`: SHA-256 `821c055780f2f0fc996fd338f231267f2d522b96fc2fa97a23df2da2e19efeb7`
  - `open_mechanism/eval/expected_answer_key.json`: SHA-256 `d825e7da0b6ee3ce62c6b3ea92523568ad9516cc77e4da9505456109dc805d59`
- [x] Kaikki neljä ajoa (`documented_script` × `{B, B′}`, `open_mechanism` × `{B, B′}`) ajettiin tuoreissa `agy`-istunnoissa identtisillä parikohtaisilla tiedostoilla, `cli_settings.json`-säännöillä, mallilla (`gemini-4-carbon-medium`) ja `effort=medium`-asetuksella; ainoa kehote-ero oli B′:n lisävirke.
- [x] Jokaisesta ajosta on kirjattu alle kohderivi, väitetty tuotantotapa, tukeva lähdekohta, lokitarkistuksen tulos, kesto ja tokenit.
- [x] Yksikkötestit (`12/12` Termuxissa ja Debian Linuxissa + `62/62` projektirekisteritestit Linuxissa), rekisteritarkistukset, Prettier/markdownlint ja `tools/run-gates.sh --mode pre-push --smoke` läpäisevät.
- [x] Toteutus katselmoitu, hyväksytty (`Tupatuko2023`, `pull/253#issuecomment-7083337107`, revisio `2c02853dafee07e934be409c2393bc56c33e987a`) ja yhdistetty `origin/main`-haaraan PR #253:ssa squash-commitilla `3f54f0208e0f3c00064d2ccb675fe68e120d0f8b`.

## B/B′-vertailun tulokset (4 tuoretta istuntoa, `2026-11-22`)

| Ajo (tapaus / kehote)      | Istunto ja vastaus-SHA256                                             | Kohderivi (QMD -> lähde-TSV)                                                                                                 | Agentin väittämä tuotanto- ja siirtotapa                                                                                                                                                                                                              | Tukeva lähdekohta                                                                                                                                                                                                                           | Lokitarkistus (`log_compliance_pass`)                                                                                                                                           | Aika (s) | Tokenit (`in / out / think / cache / total`) |
| -------------------------- | --------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------: | -------------------------------------------- |
| `documented_script` / `B`  | `b1b8df40…` / `83902d21…` (`PASS`)                                    | `manuscripts/SYNTH_COHORT_REVIEW_20261121.qmd` rivi `17` -> `runs/20261120_m2_primary/model_estimates.tsv` rivi `4` (`PASS`) | Malliajo tuotettu skriptillä `scripts/fit_m2_nb_v2.R` ja siirretty staattiseen QMD-taulukkoon skriptillä `scripts/render_qmd_outcome_table.py`; puuttuvat skriptitiedostot (`scripts/`), syötedata ja otsikkolähde rajattu avoimiksi.                 | `runs/20261120_m2_primary/run_manifest.json` rivit `2–9` (rivi `5` `model_script`), `logs/m2_table_export_20261121T073000Z.txt` rivit `1–7` (rivit `2–5`), QMD rivit `4–5` ja `17`.                                                         | `PASS` (12 kutsua, 8 työtilalukua, vain `mcp/filesystem/{directory_tree,list_directory}.json`, `0` SQLite-skeemalukua, `0` SQLite-suoritusta)                                   | `228.28` | `20 806 / 15 805 / 10 337 / 36 769 / 36 611` |
| `documented_script` / `B′` | `220f6cf0…` / `b1c4faeff…` (`PASS`)                                   | `manuscripts/SYNTH_COHORT_REVIEW_20261121.qmd` rivi `17` -> `runs/20261120_m2_primary/model_estimates.tsv` rivi `4` (`PASS`) | Sama skriptiketju (`scripts/fit_m2_nb_v2.R` -> `scripts/render_qmd_outcome_table.py`); laadullisena havaintona rajasi lisäksi avoimeksi malliversion vaihtumisen syyn (`unadjusted_nb_v1` -> `adjusted_nb_v2`).                                       | `runs/20261120_m2_primary/run_manifest.json` rivit `2–9`, `logs/m2_table_export_20261121T073000Z.txt` rivit `1–7`, QMD rivit `4–5` ja `17`, `20261118_m2_prelim/model_estimates.tsv` rivi `3` (poissulku).                                  | `PASS` (12 kutsua, 8 työtilalukua, vain `mcp/filesystem/{directory_tree,list_directory}.json`, `0` SQLite-skeemalukua, `0` SQLite-suoritusta)                                   | `182.63` | `20 646 / 13 009 / 7 380 / 36 952 / 33 655`  |
| `open_mechanism` / `B`     | `8c1eea41…` / `aca85bc2…` (`FAIL` yhdistetty, lähde+mekanismi `PASS`) | `manuscripts/SYNTH_COHORT_REVIEW_20261121.qmd` rivi `17` -> `runs/20261120_m2_primary/model_estimates.tsv` rivi `4` (`PASS`) | Jätti `M2_ED_VISITS`-rivin (`rivi 17`) siirto- ja muotoilutavan (kirjaamaton skriptiajo vs. käsinkopiointi) sekä mallinnusskriptin avoimeksi; rajasi `scripts/render_qmd_outcome_table.py`-lokin koskemaan vain riviä `16` (`M1_OUTPATIENT`).         | `runs/20261120_m2_primary/run_manifest.json` rivit `2–8`, `model_estimates.tsv` rivi `4`, QMD rivit `4–5` ja `14–20` sekä poissulkevana rajauksena `logs/m1_table_export_20261119T160000Z.txt` rivit `1–6`.                                 | `FAIL` (17 kutsua, 8 työtilalukua; `tool_execution_compliant=True` / `0` SQLite-suoritusta, mutta `path_scope_compliant=False`: luki `sqlite/{list_tables,execute_query}.json`) | `175.44` | `23 528 / 11 518 / 6 395 / 51 676 / 35 046`  |
| `open_mechanism` / `B′`    | `70feefa7…` / `033409d6…` (`PASS`)                                    | `manuscripts/SYNTH_COHORT_REVIEW_20261121.qmd` rivi `17` -> `runs/20261120_m2_primary/model_estimates.tsv` rivi `4` (`PASS`) | Jätti `M2_ED_VISITS`-rivin siirto- ja muotoilutavan, `Outcome`-nimikkeen lähteen ja tilastokoodin avoimiksi; laadullisena havaintona rajasi lisäksi avoimeksi malliversioiden välisen muutoksen syyn (`20261118_m2_prelim` -> `20261120_m2_primary`). | `runs/20261120_m2_primary/run_manifest.json` rivit `2–8`, `model_estimates.tsv` rivit `3–5`, QMD rivit `4–5` ja `14–20`, `20261118_m2_prelim/model_estimates.tsv` rivit `1–3` sekä `logs/m1_table_export_20261119T160000Z.txt` rivit `1–6`. | `PASS` (14 kutsua, 8 työtilalukua, vain `mcp/filesystem/{directory_tree,list_directory,search_files}.json`, `0` SQLite-skeemalukua, `0` SQLite-suoritusta)                      | `176.00` | `23 968 / 14 563 / 8 999 / 51 699 / 38 531`  |

### Keskeiset vertailuhavainnot

1. **Lähdehaku (`4/4`) ja siirtomekanismin arviointi (`4/4`):** Kaikki neljä istuntoa löysivät oikean kohderivin (`manuscripts/SYNTH_COHORT_REVIEW_20261121.qmd` rivi `17` -> `runs/20261120_m2_primary/model_estimates.tsv` rivi `4`: `1.3604`, `1.0803`, `1.7131`, `0.0091`). Tapauksessa `documented_script` sekä B että B′ osoittivat lokista `logs/m2_table_export_20261121T073000Z.txt` vientiskriptin `scripts/render_qmd_outcome_table.py` ja manifestista malliskriptin `scripts/fit_m2_nb_v2.R`. Tapauksessa `open_mechanism` kumpikaan (B eikä B′) yleistänyt naapuririvin `16` (`M1_OUTPATIENT`) vientilokia kohderiville `17` (`M2_ED_VISITS`).
2. **Laadullinen havainto B′-vastauksissa:** Molemmissa B′-vastauksissa (`documented_script/response_Bprime.md` rivi `72` ja `open_mechanism/response_Bprime.md` rivi `84`) agentti otti erikseen kantaa myös alustavan mallin (`20261118_m2_prelim`, `unadjusted_nb_v1`) ja jäädytetyn päämallin (`20261120_m2_primary`, `adjusted_nb_v2`) välisen muutoksen syyhyn ja rajasi puuttuvan päätösmuistion avoimeksi.
3. **Lokitarkistus (`3/4`):** Ajossa `open_mechanism / B` istunto luki kaksi sallitun rajauksen ulkopuolista SQLite-skeematiedostoa (`mcp/sqlite/list_tables.json` ja `mcp/sqlite/execute_query.json`), kun taas varsinaisia SQLite-työkalusuorituksia oli nolla (`0`; `tool_execution_compliant = True`, `path_scope_compliant = False`, `log_compliance_pass = False`). Poikkeaman syy jäi avoimeksi.

## Log

- 2026-11-22T12:59:00Z: Kortti avattu `tasks/01-ready/`-kansioon varmennetusta `origin/main`-revisiosta `e34ea168637934e135c273672cb950709642eb69` erillisessä työpuussa `wp-harness-b-vs-bprime-02` (`--verify-guard` `OK`) ja siirretty `tasks/02-in-progress/`-kansioon.
- 2026-11-22T13:04:28Z: Toteutettu `tools/antigravity_harness/b_vs_bprime_comparison.py`, yksikkötestit (`12/12 OK`) sekä lukittu molempien tapausten odotetut vastausavaimet (`821c0557…` ja `d825e7da…`) ennen ensimmäistäkään CLI-ajoa.
- 2026-11-22T13:17:00Z: Ajettu kaikki neljä tuoretta `gemini-4-carbon-medium` (`effort=medium`) CLI-istuntoa (`b1b8df40…`, `220f6cf0…`, `8c1eea41…`, `70feefa7…`), tarkastettu raakavastaukset ja arviointiraportit sekä siirretty kortti `tasks/03-review/TASK-WP-HARNESS-B-VS-BPRIME-02.md`-tilaan katselmointia varten.
- 2026-11-22T18:05:36Z: Ihmisomistajan (`Tupatuko2023`, `OWNER`) pysyvä hyväksyntä PR #253:n revisiolle `2c02853dafee07e934be409c2393bc56c33e987a` (`https://github.com/Tupatuko2023/Python-R-Scripts/pull/253#issuecomment-7083337107`).
- 2026-11-22T18:06:53Z: PR #253 squash-yhdistetty `origin/main`-haaraan commitilla `3f54f0208e0f3c00064d2ccb675fe68e120d0f8b`; toimitus varmennettu `origin/main`ista ja kortti siirretty tekniseen `04-done`-sulkuun.

## Blockers

- Ei estettä; toteutus on toimitettu `origin/main`-haaraan (`3f54f0208e0f3c00064d2ccb675fe68e120d0f8b`) ja paikalliset koeajot sekä vastausavaimet on säilytetty työpuussa `wp-harness-b-vs-bprime-02`.

## Links

- https://github.com/Tupatuko2023/Python-R-Scripts/pull/253
- `docs/governance/project_registry/PRJ-ANTIGRAVITY-HARNESS.md`
- `tools/antigravity_harness/README.md`
- `tools/antigravity_harness/b_vs_bprime_comparison.py`
- `tools/antigravity_harness/tests/test_b_vs_bprime_comparison.py`
