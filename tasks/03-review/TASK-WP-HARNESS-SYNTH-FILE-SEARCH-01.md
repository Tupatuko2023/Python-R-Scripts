# Antigravity Harness: synteettisen tiedostohaun lähtötason toteutus ja todentaminen (WP-HARNESS-SYNTH-FILE-SEARCH-01)

## Context

- Projekti: `PRJ-ANTIGRAVITY-HARNESS` (aktiivinen; pilotti-PR #248 yhdistetty `origin/main`-commitiin `6e68aaacc210e573a3ebeb509708eda91f540797` ja perustamis-PR #249 yhdistetty `origin/main`-commitiin `463e020f727ec2fc64e2d3dd4207ffda46442798`).
- Tavoite: toteuttaa ja todentaa ensimmäinen varsinainen harness-työpaketti `WP-HARNESS-SYNTH-FILE-SEARCH-01`, jonka ensimmäisenä onnistumiskriteerinä tuore Antigravity CLI -istunto löytää erillisestä synteettisestä työtilasta oikean lähdetiedoston ja osoittaa kohderivin täsmällisellä viitteellä sekä vertaa tulosta ennakolta lukittuihin odotuksiin (löydetyt lähteet, perustellut ja perusteettomat päätelmät sekä ajon rajoitteet). B- ja B′-ohjeiden vertailu tehdään seuraavassa vaiheessa tämän tiedostopohjaisen lähtötason toimivuuden jälkeen.
- Pohjarevisio: varmennettu `origin/main` `463e020f727ec2fc64e2d3dd4207ffda46442798` erillisessä puhtaassa työpuussa `wp-harness-synth-file-search-01` (`chore/wp-harness-synth-file-search-01`). Pilottinäytön työpuu (`agy-aim1-nb-trace-pilot-20261121`), perustamistyöpuu (`antigravity-harness-registry-20261122`) ja jaettu `919b5cc`-päätyöpuu säilytetään koskemattomina.

## Inputs

- `docs/governance/project_registry/PRJ-ANTIGRAVITY-HARNESS.md` ja `docs/governance/project_registry/README.md` (`463e020f727ec2fc64e2d3dd4207ffda46442798`, tarkistettu `--verify-guard`-komennolla).
- `tasks/03-review/TASK-AGY-AIM1-NB-TRACE-PILOT-20261121.md` (`origin/main`).
- Paikallinen Antigravity CLI (`agy` `1.5.14`, malli `gemini-4-carbon-medium`, `effort=medium`).

## Outputs

- Deterministinen synteettisen työtilan ja erillisen vastausavaimen generaattori sekä vastaus-/tapahtumavirta-arvioija: `tools/antigravity_harness/synth_file_search_fixture.py` (vain Pythonin vakiokirjasto, ei uusia riippuvuuksia).
- Yksikkötestit: `tools/antigravity_harness/tests/test_synth_file_search_fixture.py`.
- Toistettava ajo- ja arviointiohje toiselle istunnolle: `tools/antigravity_harness/README.md`.
- Päivitetty projektitietue: `docs/governance/project_registry/PRJ-ANTIGRAVITY-HARNESS.md`.
- Tämä tehtäväkortti katselmointitilassa: `tasks/03-review/TASK-WP-HARNESS-SYNTH-FILE-SEARCH-01.md`.
- Git-ignoroidut ajotulokset ja arviointiartefaktit: `tools/antigravity_harness/outputs/wp_synth_verified_20261122T0901Z/` (sekä alustavan lupa-asetuskokeen `wp_synth_baseline_20261122T0850Z/`) ja `tools/project_registry/outputs/projects.csv`.
- Sallitut kirjoituspolut:
  - `tasks/01-ready/TASK-WP-HARNESS-SYNTH-FILE-SEARCH-01.md`
  - `tasks/02-in-progress/TASK-WP-HARNESS-SYNTH-FILE-SEARCH-01.md`
  - `tasks/03-review/TASK-WP-HARNESS-SYNTH-FILE-SEARCH-01.md`
  - `tools/antigravity_harness/synth_file_search_fixture.py`
  - `tools/antigravity_harness/tests/test_synth_file_search_fixture.py`
  - `tools/antigravity_harness/README.md`
  - `docs/governance/project_registry/PRJ-ANTIGRAVITY-HARNESS.md`
  - ignoroidut `tools/antigravity_harness/outputs/**` ja `tools/project_registry/outputs/projects.csv`
- Toimitusraja: paikallinen katselmointivalmis commit (`03-review`) tässä erillisessä työpuussa. Ei `git push`-, PR-, `merge`- tai `04-done`-toimia ilman erillistä valtuutusta.

## Definition of Done (DoD)

- Synteettinen työtila generoidaan repon ulkopuoliseen tyhjään hakemistoon ilman suojattua tutkimusaineistoa, ja ennakolta lukittu vastausavain tallennetaan työtilan ulkopuolelle ennen ajoa.
- Tuore Antigravity CLI -istunto suorittaa tiedostopohjaisen haun synteettisessä työtilassa (`workspace_read_count > 0`, `outside_workspace_paths == []`, `forbidden_tools_used == []`), löytää oikean lähdetiedoston kilpailevien harhautustiedostojen joukosta ja osoittaa kohderivin täsmällisellä tiedosto- ja riviviitteellä.
- Raportti ja arvioija dokumentoivat löydetyt lähteet, perustellut ja perusteettomat päätelmät sekä ajon rajoitteet, ja ohje (`tools/antigravity_harness/README.md`) mahdollistaa kokeen toistamisen toisessa istunnossa.
- Yksikkötestit (sekä Termuxissa että Linuxissa), rekisterin `--verify-guard` / `--print-source-hash` / CSV-tarkistukset, Prettier/markdownlint ja `tools/run-gates.sh --mode pre-push --smoke` läpäisevät.

## Log

- 2026-11-22T08:46:00Z: Kortti luotu `tasks/01-ready/`-kansioon varmennetusta `origin/main`-revisiosta `463e020f727ec2fc64e2d3dd4207ffda46442798` erillisessä työpuussa `wp-harness-synth-file-search-01`, `PRJ-ANTIGRAVITY-HARNESS.md` tarkistettu `--verify-guard`-suojalla (`OK`) ja kortti siirretty `tasks/02-in-progress/`-tilaan.
- 2026-11-22T08:53:14Z: Ensimmäisessä alustavassa koeajossa (`12d6ed64-5be2-4c87-b1ab-7cc8f13fb0a3`, vastausavain `137302bc…`) malli löysi oikean lähdetiedoston `runs/20261119_model_s2_primary/model_estimates.tsv` ja rivin `4`, mutta lippu `--dangerously-skip-permissions` sekä väärän muotoiset `run_command`-estot päästivät läpi `run_command`-yrityksen. Tarkistettiin `agy`:n virallinen lupasyntaksi (`command(*)`, `write_file(*)`, `read_url(*)`, `mcp(...)` ilman `--dangerously-skip-permissions`-lippua) ja todennettiin erillisellä savutestillä, että `command(*)` ja `mcp(shell/*)` estävät komentosuorituksen teknisesti, mutta `read_file(<polku>/**)` ei estä natiivia `read_file`-kutsua.
- 2026-11-22T09:06:42Z: **Varmennettu synteettinen tiedostohakuajo (`wp_synth_verified_20261122T0901Z`, `PASS`):** Lukittiin vastausavain ennen ajoa (`05eaf5b1863a5359eb3a64b000f35408b70f3fb167707f0129d6cabf79f30a5c`). Tuore `agy`-istunto (`da5edbee-d179-4ad7-9b84-866d5153b5e7`, `gemini-4-carbon-medium`, `effort=medium`, `186.19 s`, `30 594` tokenia, vastaus SHA-256 `e83fe5e8a5507b592b858ee44943f31aa84afb2f6091e6741e105927f449a1ab`) suoritti `11` työkalukutsua (`1` `mcp(filesystem/directory_tree)`, `3` MCP-skeemalukua ja `7` `read_file`-lukua synteettisen työtilan sisällä; `outside_workspace_paths = []`, `forbidden_tools_used = []`). Istunto tunnisti käsikirjoituksen rivin `17` (`manuscripts/SYNTH_COHORT_REVIEW_20261120.qmd`), löysi ensisijaisen lähdetiedoston `runs/20261119_model_s2_primary/model_estimates.tsv` kohderivin `rivi 4` tarkkoine arvoineen (`1.4204`, `1.1102`, `1.8173`, `0.0052`) sekä ajomanifestin (`run_manifest.json`), hylkäsi kaikki kolme harhautustiedostoa oikein perustein ja jätti QMD-siirtotavan (`käsin vai ulkoisella skriptillä`), `Recurrent fall rate` -nimikkeen koodikirjan, ylävirran `SYNTH_PANEL_V2`-syötteen ja SHA-256-tarkistussumman komentorivilaskennan eksplisiittisesti avoimiksi.
- 2026-11-22T09:08:30Z: Päivitettiin `PRJ-ANTIGRAVITY-HARNESS.md`, ajettiin yksikkötestit Termuxissa ja Debian Linuxissa, rekisteritarkistukset ja toimitusportit sekä siirrettiin kortti `tasks/03-review/`-kansioon paikalliseen katselmointiin.

## Blockers

- `agy` `1.5.14` natiivi `read_file` ei noudata polkukohtaista `permissions.deny`-rajausta, minkä vuoksi vastausavain on pidettävä kehotteessa nimeämättömässä ulkopuolisessa polussa, ajo on tehtävä ilman suojattua tutkimusaineistoa ja `stream-json`-polkuloki on tarkistettava mekaanisesti jokaisesta ajosta.
- Etäpush, PR:n avaus, `main`-merge ja aiempien korttien `04-done`-siirto odottavat erillistä ihmispäätöstä.

## Links

- `docs/governance/project_registry/PRJ-ANTIGRAVITY-HARNESS.md`
- `tools/antigravity_harness/README.md`
- `tools/antigravity_harness/synth_file_search_fixture.py`
