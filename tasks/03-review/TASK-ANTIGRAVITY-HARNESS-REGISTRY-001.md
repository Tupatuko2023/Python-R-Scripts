# Antigravity Harness: projektitietueen perustaminen projektirekisteriin

## Context

- Tavoite: perustaa `Tupatuko2023/Python-R-Scripts`-repon projektirekisteriin uusi projektitietue `PRJ-ANTIGRAVITY-HARNESS`, linkittää siihen aiempi `E1 R_P` -lähdejäljityspilotti ja nimetä seuraava työpaketti `WP-HARNESS-SYNTH-FILE-SEARCH-01`.
- Pohjarevisio: paikallinen `origin/main` `5ac1694491d786d4398132e687556af12416a02e` omassa puhtaassa työpuussa `antigravity-harness-registry-20261122`. Aiemman pilotin työpuu (`agy-aim1-nb-trace-pilot-20261121`) ja jaettu `919b5cc`-päätyöpuu säilytetään erillisinä.

## Inputs

- `docs/governance/project_registry/README.md` ja `docs/governance/project_registry/TEMPLATE.md` (`5ac1694491d786d4398132e687556af12416a02e`).
- Pilotin työpuusta tarkistettu korttipolku `tasks/03-review/TASK-AGY-AIM1-NB-TRACE-PILOT-20261121.md` (katselmointi-PR #248, commit `4d0d08f78ea6de8757db4bb0dd5f357b1faba6ce`) ja sen päivätyt havainnot.
- Ihmisomistajan sanatarkka lähdekuvausvirke lukittavaksi `source-description`-lohkoon.

## Outputs

- `docs/governance/project_registry/PRJ-ANTIGRAVITY-HARNESS.md` ja rekisterityökalun generoima ignoroitu `tools/project_registry/outputs/projects.csv`.
- Tämä tehtäväkortti katselmointitilassa `tasks/03-review/TASK-ANTIGRAVITY-HARNESS-REGISTRY-001.md`.
- Sallitut kirjoituspolut:
  - `docs/governance/project_registry/PRJ-ANTIGRAVITY-HARNESS.md`
  - `tasks/01-ready/TASK-ANTIGRAVITY-HARNESS-REGISTRY-001.md`
  - `tasks/02-in-progress/TASK-ANTIGRAVITY-HARNESS-REGISTRY-001.md`
  - `tasks/03-review/TASK-ANTIGRAVITY-HARNESS-REGISTRY-001.md`
  - ignoroitu johdannainen `tools/project_registry/outputs/projects.csv`
- Toimitusraja: alkuperäinen valtuutus kattoi rekisteritietueen validoinnin ja katselmointiin viennin paikallisessa työpuussa. Käyttäjän 22.11.2026 jatkovaltuutus kattaa paikallisen commitin, Linux-yksikkötestien ajon tarkalle HEAD-revisiolle, haaran `docs/antigravity-harness-registry-20261122` pushin sekä PR:n avaamisen ja ristiinlinkityksen pilotti-PR:ään (#248). Ei `main`-mergeä, `04-done`-siirtoa eikä työpuun siivousta.

## Definition of Done (DoD)

- Repoidentiteetti, `TEMPLATE.md`, olemassa olevat `PRJ-*.md`-tiedostot ja avoimet PR:t on tarkistettu ennen ensiluontia.
- `PRJ-ANTIGRAVITY-HARNESS.md` on luotu `TEMPLATE.md`-pohjasta oikeilla kentillä (`active` / `not_delivered`, `origin/main`, `worktree_inventory: "unknown"`), sanatarkalla yksirivisellä lähdekuvauksella ja erillisellä työsuunnitelmaosiolla.
- Lähdelohkon SHA-256 on laskettu `--print-source-hash`-komennolla, CSV on generoitu kahdesti tavutarkasti samoin tuloksin, `--check` ja ignore-portti läpäisevät ja `PRJ-ANTIGRAVITY-HARNESS` esiintyy CSV:ssä täsmälleen kerran.
- Rekisterin yksikkötestit (sekä Termux-havainto että täysi Linux-ajo), Prettier/markdownlint, `tools/run-gates.sh --mode pre-push --smoke` ja staged-diffin kirjoitusraja on tarkistettu.

## Log

- 2026-11-22T05:03:00Z: Kortti avattu `tasks/01-ready/`-kansioon ja siirretty `tasks/02-in-progress/`-tilaan puhtaassa työpuussa `antigravity-harness-registry-20261122` (`5ac1694491d786d4398132e687556af12416a02e`).
- 2026-11-22T05:04:27Z: Tarkistettiin repoidentiteetti (`Tupatuko2023/Python-R-Scripts`), olemassa olevat 5 projektitietuetta ja 2 avointa PR:ää (#244, #247): aiempaa `PRJ-ANTIGRAVITY-HARNESS`-tietuetta ei ollut. Tarkistettiin pilottikortin polku `tasks/03-review/TASK-AGY-AIM1-NB-TRACE-PILOT-20261121.md` sen omasta työpuusta.
- 2026-11-22T05:04:27Z: Luotiin `docs/governance/project_registry/PRJ-ANTIGRAVITY-HARNESS.md` pohjasta `TEMPLATE.md` (`state: "active"`, `delivery: "not_delivered"`, `repo_ref: "origin/main"`, `observed_commit: "5ac1694491d786d4398132e687556af12416a02e"`, `observed_worktree_label: "antigravity-harness-registry-20261122"`, `worktree_inventory: "unknown"`). Laskettiin lukitun lähdekuvauslohkon SHA-256 (`--print-source-hash`): `c01dbe65b20745aa873259765a97223d39fb4f1f02b528670f8be97e6037e86f`.
- 2026-11-22T05:05:30Z: Termux-ajossa rekisterin yksikkötestisarja (`test_render_projects_csv.py`) suoritti 62 testiä, joista 58 onnistui virheittä ja 4 kovaa linkkiä käyttävää testiä (`GitGateTests.test_ignored_hard_link_to_tracked_source_is_rejected`, `SafePublicationTests.test_alias_created_during_write_is_rechecked_before_replace`, `SafePublicationTests.test_atomic_replace_does_not_modify_other_hard_link`, `SafePublicationTests.test_hard_link_to_source_is_rejected`) pysähtyi Termux-Pythonin puuttuvaan `os.link`-ominaisuuteen (`AttributeError: module 'os' has no attribute 'link'`). Kortti siirrettiin `tasks/03-review/`-kansioon.
- 2026-11-22T06:11:30Z: Pilottikortin julkaisurajattu PR #248 (`4d0d08f78ea6de8757db4bb0dd5f357b1faba6ce`) avattiin ja kortin todelliseksi repojuuripoluksi vahvistettiin `tasks/03-review/TASK-AGY-AIM1-NB-TRACE-PILOT-20261121.md`. Päivitettiin projektitietueen jatkamismuistio pilotti-PR-viitteellä ja `04-done`-polun päivityshuomiolla, muotoiltiin Prettier `3.8.1`:llä, tarkistettiin lähdehash (`c01dbe65b20745aa873259765a97223d39fb4f1f02b528670f8be97e6037e86f`), CSV:n 2× tavutarkka toistettavuus, `--check`, ignore-portti ja yhden esiintymän ehto, ja valmisteltiin commit sekä Linux (`proot-distro` Debian, Python `3.13.5`) -yksikkötestiajo tarkalle HEAD-revisiolle.

## Blockers

- Termux-Pythonissa `test_render_projects_csv.py` antaa 62 testistä neljä `os.link` `AttributeError` -virhettä; täysi 62/62-sarja varmennetaan erikseen Linux-ympäristössä (`proot-distro` Debian) tämän PR:n tarkalle HEAD-revisiolle.
- Ihmiskatselmointi, `origin/main`-merge ja `04-done`-sulku eivät kuulu tähän valtuutukseen; jos pilottikortti (#248) siirtyy `tasks/04-done/`-kansioon ennen perustamis-PR:n mergeä, `PRJ-ANTIGRAVITY-HARNESS.md`:n tehtäväviite on päivitettävä lopulliseen polkuun ennen yhdistämistä.

## Links

- `docs/governance/project_registry/README.md`
- `docs/governance/project_registry/PRJ-ANTIGRAVITY-HARNESS.md`
- [PR #248](https://github.com/Tupatuko2023/Python-R-Scripts/pull/248)
