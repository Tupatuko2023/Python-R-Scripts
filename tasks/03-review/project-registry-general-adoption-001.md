# Projektirekisterin yleinen käyttöönotto analyysirepossa

## State

- State: `03-review`
- Tunniste: `project-registry-general-adoption-001`
- Repo: `Tupatuko2023/Python-R-Scripts`
- Orkestroija: `FCPO2`
- Haara: `docs/project-registry-general-adoption-001`
- Worktree repojuuresta: `tmp/project-registry-general-adoption-001`
- Varmennettu `origin/main`: `495644686c9e149f7d95ac052c2a31874c387a0e`
- Valtuutusraja: Owner hyväksyi `git fetch origin main`, eristetyn worktreen ja
  haaran, READY-kortin, admissionin, hyväksytyt sisältömuutokset, validoinnit,
  kohdistetut commitit, pushin ja PR:n luonnin katselmointiin asti neljässä
  rajatussa ajossa. Ei mergeä, DONE-sulkua tai worktree-/haarasiivousta.

## Context

Projektirekisterin tekninen generaattori, testit, pohja ja yhden projektin
pilotti on toimitettu (`project-registry-transfer-001` ja
`project-registry-rollout-001` ovat `04-done`, eikä niitä avata uudelleen).
Siivouskirjaustehtävä `project-registry-cleanup-001` säilyy erillisenä
`03-review`-tilassa eikä sen sulkeminen kuulu tähän tehtävään.

Nykyinen ohjeistus rajaa rekisterin vielä pilottiin ja vain päärepon omiin
koordinointiprojekteihin. Tämä tehtävä ottaa olemassa olevan projektirekisterin
koko analyysirepon normaaliin käyttöön mukaan lukien aliprojektien nimetyt
projektit. Aliprojektien omat tehtäväjonot ja ohjeet säilyvät, eikä rinnakkaista
tehtäväseurantaa tai rekursiivista keräilyä luoda. Likainen päächeckout ja
kaikki aiemmat työpuut säilytetään koskemattomina.

## Inputs

- `AGENTS.md`, `GEMINI.md`, `SKILLS.md`, `config/agent_policy.md`,
  `config/steering.md`, `.codex/skills/make-repo-contribution/SKILL.md`
- `docs/governance/project_registry/README.md`
- `docs/governance/project_registry/TEMPLATE.md`
- `docs/governance/project_registry/PRJ-REGISTRY-ROLLOUT.md`
- `tools/project_registry/render_projects_csv.py` ja
  `tools/project_registry/tests/test_render_projects_csv.py`
- `tasks/04-done/project-registry-transfer-001.md`,
  `tasks/04-done/project-registry-rollout-001.md` ja
  `tasks/03-review/project-registry-cleanup-001.md`
- `tools/run-gates.ps1`, `tools/run-gates.sh`, `.github/workflows/markdownlint.yml`

## Outputs

Hyväksytyt muutospolut:

- `docs/governance/project_registry/README.md`
- `AGENTS.md`
- `SKILLS.md` (vain lyhyt rekisteriviite)
- `docs/governance/project_registry/PRJ-REGISTRY-ROLLOUT.md`
- tämän tehtäväkortin paikallisen elinkaaren mukaiset polut

Viiden tiedoston ajoraja (`config/steering.md`) erillisinä ajoina:

1. Ajo 1 (READY-valmistelu): vain `tasks/01-ready/project-registry-general-adoption-001.md` (1 polku).
2. Ajo 2 (Admission): siirto `tasks/01-ready/...` -> `tasks/02-in-progress/...` ja portin ajo (2 polkua).
3. Ajo 3 (Ohjeet): `docs/governance/project_registry/README.md`, `AGENTS.md`, `SKILLS.md` ja `02-in-progress`-kortin loki (4 polkua).
4. Ajo 4 (Projektitietue ja review-handoff): `docs/governance/project_registry/PRJ-REGISTRY-ROLLOUT.md` sekä kortin siirto `02-in-progress` -> `03-review` (3 polkua), validoinnit, push ja PR.

Ei generaattorimuutoksia ilman todettua tarvetta, massatuontia, analyysiajoja,
tutkimusaineiston käsittelyä tai työpuiden siivousta.

## Definition of Done (DoD)

- Yleinen rekisteröintisääntö ja `PRJ`/`TASK`-valintaperuste on dokumentoitu.
- Päärepon ja aliprojektien projektien kirjaaminen yhteiseen päärekisteriin on
  ohjeistettu ilman rinnakkaista tehtäväjonoa tai rekursiivista keräilyä.
- Luonti, suojattu päivitys, keskeytys, sulku (paikallinen pysyvä
  ihmishyväksyntänäyttö) ja jatkovaihe on määritelty.
- Eri worktreiden saman `PRJ`-tietueen kirjoitusten koordinointi ja ajantasaisen
  kohdehaaran tarkistus ennen yhdistämistä on dokumentoitu (Git-suoja ei lukitse
  eri worktreiden kirjoittajia).
- `PRJ-REGISTRY-ROLLOUT.md` kuvaa uutta vaihetta samalla tunnuksella
  (`state: "active"`, `delivery: "not_delivered"` toteutuksen ajan) päivätyllä
  jatkopäätöksellä; alkuperäinen lähdekuvauslohko ja sen SHA256
  (`83d725739700bef4dbd47f3bb23777d389cdf7096148d40b0a57301b3af27dd1`) säilyvät
  tavuntarkasti muuttumattomina ilman uudelleenmuotoilua.
- Pilotin toimitus-, hyväksyntä- ja siivoushistoria säilyy; vanha
  `tasks/03-review/project-registry-cleanup-001.md` lisätään vain viitteeksi eikä
  sitä suljeta. Worktree-inventaario arvioidaan uudelleen uuden työpuun myötä
  eikä vanhaa `complete`-arvoa siirretä automaattiseksi uuden vaiheen
  kattavuusväitteeksi.
- `tools/project_registry/outputs/projects.csv`-tulospolku ja avoimet
  Sourcery-havainnot (`#12` ja `#14–16`) säilyvät.
- Nykyiset generaattoritestit, synteettinen moniprojekti- ja
  aliprojektiviitekoe, CSV-generointi kahdesti samoilla tavuilla, `--check`,
  `git check-ignore`, muuttuneiden dokumenttien Markdown-tarkistukset,
  `git diff --check` sekä staged `tools/run-gates.ps1 --mode pre-push --smoke`
  läpäisevät.
- Enintään viiden tiedoston ajoraja täyttyy jokaisessa ajossa myös korttisiirrot
  huomioiden. Toteutus toimitetaan `03-review`-tilaan ja PR:ksi ilman mergeä.

## Log

- 2026-11-17T17:32:00+02:00: `git fetch origin main` varmisti HEADin
  `495644686c9e149f7d95ac052c2a31874c387a0e`. Eristetty worktree
  `tmp/project-registry-general-adoption-001` ja haara
  `docs/project-registry-general-adoption-001` perustettu koskematta päächeckoutiin
  tai muihin worktreeihin. Vain tämä READY-kortti valmisteltu Ajossa 1 (1 polku).
- 2026-11-17T17:38:00+02:00: Ajo 2 (admission): READY-kortti varmennettu,
  `tools/run-gates.ps1 --mode pre-push --smoke` PASS (guardrails, `renv.lock`,
  R/Python-syntaksi). Kortti siirretty `01-ready` -> `02-in-progress` ennen
  sisältömuutoksia (2 polkua tässä ajossa).
- 2026-11-17T18:03:00+02:00: Ajo 3 (ohjekytkennät): päivitetty
  `docs/governance/project_registry/README.md` yleiseen käyttöön (`PRJ`/`TASK`-valinta,
  aliprojektien projektiviitteet ilman rinnakkaista tehtäväjonoa, luonti/päivitys/keskeytys/sulku/jatkovaihe,
  eri worktreiden `PRJ`-kirjoitusten koordinointi, lähdelohkon muotoilukielto sekä
  alkuperäisen tulospolun, provenancen ja Sourcery `#12`/`#14–16` säilytys),
  päivitetty `AGENTS.md`:n projektirekisteriosio koko repolle ja lisätty lyhyt
  rekisteriviite `SKILLS.md`:hen. Vain 4 polkua muutettu tässä ajossa.
- 2026-11-17T18:20:00+02:00: Ajo 4 (projektitietue, validointi, review-siirto ja
  PR): tarkistettu `origin/main` (`d7ba40bd9c3c450059707386e287afdc21f23248`,
  vain Dependabot-päivitys `#224` polkuihin `package.json`/`package-lock.json`,
  ei päällekkäisyyttä rekisteripolkujen kanssa) sekä suoritettu `--verify-guard`
  tarkistuksella `66d1209f9aa716f36adf9125dff1d628e63f85bb` (`OK`, exit 0).
  Päivitetty `docs/governance/project_registry/PRJ-REGISTRY-ROLLOUT.md`
  jatkovaiheeseen (`state: "active"`, `delivery: "not_delivered"`,
  `worktree_inventory: "unknown"`, päivätty jatkopäätös, vanha
  `project-registry-cleanup-001` vain viitteenä). Alkuperäinen lähdelohko ja sen
  SHA256 (`83d725739700bef4dbd47f3bb23777d389cdf7096148d40b0a57301b3af27dd1`)
  varmennettu tavuntarkasti muuttumattomiksi ilman uudelleenmuotoilua. Kortti
  siirretty `02-in-progress` -> `03-review` (3 polkua tässä ajossa).

## Review-handoff ja validointinäyttö 2026-11-17

- Ajokohtainen 5 tiedoston raja toteutunut jokaisessa ajossa:
  - Ajo 1 (`f8b5477`): 1 polku (`tasks/01-ready/project-registry-general-adoption-001.md`).
  - Ajo 2 (`4bd8bd2`): 2 polkua (`01-ready` -> `02-in-progress`).
  - Ajo 3 (`66d1209`): 4 polkua (`README.md`, `AGENTS.md`, `SKILLS.md`, `02-in-progress`-kortti).
  - Ajo 4: 3 seurattua polkua (`PRJ-REGISTRY-ROLLOUT.md` sekä `02-in-progress` -> `03-review`) + gitignored CSV.
- Paikalliset validoinnit worktreen repojuuresta:
  - `--verify-guard docs/governance/project_registry/PRJ-REGISTRY-ROLLOUT.md --expect-commit 66d1209f9aa716f36adf9125dff1d628e63f85bb`: **PASS** (`OK`, exit 0).
  - `--print-source-hash docs/governance/project_registry/PRJ-REGISTRY-ROLLOUT.md`: **PASS** (`83d725739700bef4dbd47f3bb23777d389cdf7096148d40b0a57301b3af27dd1`, 1035 tavun lähdelohko tavuntarkasti identtinen `49564468...`-pohjan kanssa).
  - CSV-generointi kahdesti `tools/project_registry/outputs/projects.csv`: **PASS** (molemmat 2402 tavua, tavuntarkasti samat; `state=active`, `delivery=not_delivered`, `Worktree-siivous=retained`, `Orkestroija=FCPO2`).
  - `render_projects_csv.py --check`: **PASS** (exit 0).
  - `git check-ignore -v -- tools/project_registry/outputs/projects.csv`: **PASS** (`.gitignore:43:**/outputs/`, exit 0).
  - Generaattorin yksikkötestit (`python -B -m unittest discover -s tools/project_registry/tests -p test_render_projects_csv.py`): **62 testiä ajettu, 60 PASS, 2 Windows-symlink-oikeusohitusta** (exit 0; generaattoriin tai testeihin ei tehty muutoksia).
  - Synteettinen moniprojekti-, aliprojektiviite- ja keräilyrajakoe väliaikaisessa Git-repossa: **PASS** (`PRJ-FOF-SUBPROJ` + `PRJ-ROOT-COORD` lajiteltuina, `Fear-of-Falling/tasks/...`- ja `Quantify-FOF-Utilization-Costs/tasks/...`-polkuviitteet, `TEMPLATE.md` ja alihakemistojen `PRJ-*.md`-tiedostot rajautuvat pois, determinismi, `--check` ja ignore PASS). Jatkamispolut tarkistettu oikeasta rekisteritietueesta ilman chattia.
  - Prettier `--check` ja `markdownlint-cli2` kaikille neljälle muuttuneelle ei-`tasks/` Markdown-tiedostolle (`README.md`, `AGENTS.md`, `SKILLS.md`, `PRJ-REGISTRY-ROLLOUT.md`): **PASS** (0 virhettä, lähdelohkoa ei muotoiltu uudelleen).
  - Staged `tools/run-gates.ps1 --mode pre-push --smoke` ja `git diff --check`: **PASS** (exit 0).
  - `K18/QC: NOT APPLICABLE` — päärepon ei-tieteellinen hallinta- ja rekisteriohjemuutos; ei tutkimusdataa tai analyysikoodia. `.py`-tiedostoja ei muutettu, joten `python-ci.yml` ei aktivoidu pelkästä Markdown-diffistä (ei väitettä uudesta Linux-pytest-ajosta).
- Agentti ei hyväksy omaa työtään eikä tee mergeä, DONE-siirtoa tai worktree-/haarasiivousta. Merge ja sulku odottavat täsmärevision riippumatonta ihmishyväksyntää.

## Blockers

Ei aktiivisia esteitä.

## Links

- Ohje: `docs/governance/project_registry/README.md`
- Projektitietue: `docs/governance/project_registry/PRJ-REGISTRY-ROLLOUT.md`
- Edeltäjät: `tasks/04-done/project-registry-transfer-001.md`,
  `tasks/04-done/project-registry-rollout-001.md`
- Erillinen siivouskortti (ei suljeta tässä tehtävässä):
  `tasks/03-review/project-registry-cleanup-001.md`
