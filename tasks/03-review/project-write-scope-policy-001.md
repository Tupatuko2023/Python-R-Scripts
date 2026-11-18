# Tehtäväkohtainen kirjoitusrajaus viiden tiedoston ajorajan tilalle

## Context

Tila: REVIEW. Tehtävätunnus: `project-write-scope-policy-001`.
Omistaja: Tomi Korpi. Orkestroija: FCPO2.
Projekti: `PRJ-PROJECT-WRITE-SCOPE-POLICY` (`docs/governance/project_registry/PRJ-PROJECT-WRITE-SCOPE-POLICY.md`).
Repo: `Tupatuko2023/Python-R-Scripts`.
Perustahaara ja varmennettu `origin/main`: `b0499e2de483e68f1f73f65d88859cac9b6778af`.
Työpuu ja tehtävähaara: `tmp/project-write-scope-policy-001` / `docs/project-write-scope-policy-001`.
PR: https://github.com/Tupatuko2023/Python-R-Scripts/pull/227

Projektirekisterin yleisen käyttöönoton suunnittelussa viiden tiedoston
ajokohtainen raja johti neljään erilliseen ajoon ja ehdotukseen pyytää
jatkokuittaus jokaisen ajon välissä. Korttisiirrot laskettiin kahdeksi poluksi.
Tämä on 17.11.2026 toimitetun agenttiraportin havainto, joka varmennettiin
18.11.2026 read-only-selvityksessä suoraan `origin/main`-revisiosta
`b0499e2de483e68f1f73f65d88859cac9b6778af` (`tasks/04-done/project-registry-general-adoption-001.md`
sekä 10 aktiivista viittausta nykyohjeissa ja `tools/run-gates.sh`:ssa).

Tavoite on korvata mekaaninen tiedostomääräraja ennalta hyväksytyllä,
tehtäväkohtaisella tavoitteella ja täsmällisillä kirjoituspoluilla. Hyväksytyn
rajauksen sisällä agentti voi edetä sovittuun toimitusvaiheeseen ilman saman
luvan toistuvaa kysymistä. Tarkistukset ja riippumaton katselmointi säilyvät.

### Ownerin toteutuspäätös ja valtuutus (2026-11-18)

- **Nimetty kertapoikkeus:** Owner myönsi vain tälle tehtävälle kertapoikkeuksen
  voimassa olevasta viiden tiedoston ajorajasta alla yksilöityihin sisältöpolkuihin
  ja tämän tehtäväkortin elinkaarisiirtoihin. Uusi sääntö tulee yleiseen käyttöön
  muissa tehtävissä vasta hyväksytyn `main`-toimituksen jälkeen.
- **Hyväksytyt operaatiot ja toimitusraja:** `git fetch origin main`, eristetyn
  worktreen (`tmp/project-write-scope-policy-001`) ja haaran
  (`docs/project-write-scope-policy-001`) perustaminen, tarvittaessa `npm ci`
  vain tässä eristetyssä worktreessä lukitustiedoston mukaisesti, valmistelu,
  toteutus, tarkistukset, kohdistetut commitit, `git push` sekä PR:n luonti ja
  päivittäminen **PR-katselmointiin (`03-review`) asti**. Valtuutus kattaa saman
  tehtävän jatkamisen uudessa sessiossa, kun nykytila ja kirjattu valtuutus on
  tarkistettu.
- **Toimitusrajan ulkopuolella (kielletty tässä vaiheessa):** ei mergeä, ei
  `04-done`-siirtoa, ei `delivered`/`closed`-merkintää projektirekisteriin, ei
  haarojen poistoja eikä worktree-siivousta. Likainen päächeckout, sen
  seuraamaton backlog-kopio ja kaikki 12 muuta olemassa olevaa työpuuta
  säilytetään koskemattomina. Ei R-analyysejä, tutkimusaineiston käsittelyä,
  yleistä aliprojektiohjeiden refaktorointia tai muiden tehtävien muutoksia.

## Inputs

- Ajantasaiset `config/steering.md`, `config/agent_policy.md`, `SKILLS.md`,
  `AGENTS.md`, `GEMINI.md` ja `Fear-of-Falling/GEMINI.md` (`origin/main`
  `b0499e2de483e68f1f73f65d88859cac9b6778af`).
- `.codex/skills/make-repo-contribution/SKILL.md` ja `.github/CONTRIBUTING.md`.
- `tasks/_template.md`, `tools/run-gates.sh`, `tools/run-gates.ps1` ja
  `.github/workflows/markdownlint.yml`.
- `docs/governance/project_registry/README.md`,
  `docs/governance/project_registry/TEMPLATE.md` ja
  `docs/governance/project_registry/PRJ-REGISTRY-ROLLOUT.md`.
- `tasks/04-done/project-registry-general-adoption-001.md` (varmennettu valmiiksi
  `origin/main`issa; ei avata uudelleen).
- Ownerin 2026-11-18 päätökset: projektiseuranta (`PRJ-PROJECT-WRITE-SCOPE-POLICY`)
  sekä toteutusvaltuutus ja kertapoikkeus PR-katselmointiin asti.

## Outputs

Hyväksytyt seuratut sisältö- ja rekisteripolut (repojuureen suhteutettuina):

- `config/steering.md`
- `SKILLS.md` (kanoninen ylläpitopaikka + mekaanisen PR-listan `git add -A` ja
  automerge-ohjeen korjaus kohdistettuun stageaukseen ja toimitus-/ihmishyväksyntärajaan)
- `config/agent_policy.md`
- `AGENTS.md`
- `GEMINI.md`
- `Fear-of-Falling/GEMINI.md`
- `docs/governance/project_registry/README.md`
- `.codex/skills/make-repo-contribution/SKILL.md`
- `tasks/_template.md`
- `tools/run-gates.sh` (vain vanhaa tiedostorajaa kuvaava ilmoitusteksti;
  porttilogiikkaa ei heikennetä)
- `docs/governance/project_registry/PRJ-PROJECT-WRITE-SCOPE-POLICY.md`

Lisäksi tämän tehtäväkortin elinkaaripolut eristetyssä worktreessä:

- `tasks/01-ready/project-write-scope-policy-001.md`
- `tasks/02-in-progress/project-write-scope-policy-001.md`
- `tasks/03-review/project-write-scope-policy-001.md`

Paikallinen generoitu tulos (gitignored, ei commitoida):

- `tools/project_registry/outputs/projects.csv` (sekä generaattorin atomisen
  julkaisun väliaikaistiedostot)

### Korvaavan säännön tavoite ja Ownerin täsmennykset

- `SKILLS.md` on säännön kanoninen ylläpitopaikka; muut ohjeet viittaavat siihen
  tai tiivistävät sen luomatta poikkeavia sääntöversioita.
- Jokaisella toteutuksella on hyväksytty tavoite, yksilöidyt kirjoituspolut
  (ml. kortin elinkaaripolut, mahdollinen nimetty `PRJ-*.md` ja tarpeelliset
  paikalliset generoidut tulokset), hyväksytyt operaatiot ja toimitusraja.
- Muutosmäärä raportoidaan katselmointia varten. Pelkkä tiedostolukumäärä,
  commit, työkalukutsu tai keskusteluvuoro ei muodosta uutta hyväksyntäporttia.
- Valtuutus säilyy saman tehtävän hyväksytyssä rajauksessa sovittuun
  toimitusrajaan asti myös uuteen sessioon jatkettaessa, kun nykytila ja
  tallennettu valtuutus on tarkistettu; puuttuvaa valtuutusnäyttöä ei keksitä.
- Pakollisen portin tai tarkistuksen virheen saa korjata hyväksytyissä poluissa
  ja tavoitteen sisällä ilman uutta lupaa. Porttia ei saa ohittaa; ratkaisematon
  virhe estää toimituksen, ja rajauksen laajennus vaatii uuden kootun päätöksen.
- Operaatiot (kuten `git fetch`, `git push`, PR:n luonti/päivitys) eivät tule
  automaattisesti sallituiksi pelkän kirjoituspolkulistan perusteella, mutta ne
  voidaan hyväksyä yhdessä tehtävän alussa. Kun operaatio sisältyy jo kirjattuun
  valtuutukseen ja toimitusrajaan, samaa lupaa ei kysytä uudelleen jokaisella
  käyttökerralla. Merge, `04-done` ja poistot vaativat oman valtuutuksensa ja
  paikallisten sääntöjen mukaisen riippumattoman ihmishyväksyntänäytön.
- Kohdistettu stageaus, diff-katselmointi, pakolliset portit, suojatut polut,
  tutkimusaineiston suojaus ja muiden työn säilyttäminen pysyvät voimassa.

## Definition of Done (DoD)

- [x] Nykyinen viiden tiedoston sääntö, sen viittaukset ja mahdollinen
      koneellinen valvonta on selvitetty tiedosto- ja revisionäytöllä.
- [x] Hyväksytty korvaava sääntö määrittelee tavoitteen, kirjoitusrajauksen,
      valtuutuksen voimassaolon, toimitusrajan ja uutta päätöstä vaativat muutokset
      kanonisesti `SKILLS.md`:ssä (sekä korjaa `git add -A`- ja automerge-kohdat).
- [x] Nykyohjeisiin ei jää ristiriitaista yleistä viiden tiedoston ajorajaa.
      Historialliset tehtäväkortit ja aiempien päätösten näyttö säilyvät.
- [x] Aliprojektien soveltamisalat on huomioitu ilman yleistä ohjerefactorointia.
- [x] Dokumentoitu tapausvertailu osoittaa vähintään seuraavat tulokset:
      hyväksytyt kuusi sisältöpolkua eivät aiheuta lukumääräpysähdystä;
      uusi hyväksymätön polku aiheuttaa rajauspäätöksen;
      saman tehtävän session jatko ei pyydä samaa lupaa;
      PR:ään rajattu valtuutus ei salli mergeä;
      muiden paikallinen työ säilyy;
      pakollisen portin epäonnistuminen ei oikeuta sen ohittamista.
- [x] Projektitietue `PRJ-PROJECT-WRITE-SCOPE-POLICY.md` ja generoitu
      `tools/project_registry/outputs/projects.csv` läpäisevät lähdehash-,
      `--verify-guard`-, determinismi-, `--check`-, `git check-ignore`- ja
      yksikkötestitarkistukset.
- [x] Soveltuvat Markdown- ja toimitusportit sekä `git diff --check` läpäisevät.
      `tools/run-gates.sh` päivittää vain vanhan ilmoitustekstin heikentämättä
      porttia. Tutkimusanalyysejä tai K18/QC-ajoja ei käynnistetä (`NOT APPLICABLE`).
- [ ] Riippumaton hyväksyntänäyttö kohdistuu katselmoituun revisioon, ja toimitus
      kanoniseen mainiin sekä tehtävän sulku on varmennettu paikallisin säännöin
      (myöhempi sulkuvaihe PR-katselmoinnin jälkeen).
- [x] Työpuun säilytys tai erikseen valtuutettu siivous on raportoitu erillään
      toteutuksesta ja main-toimituksesta (`tmp/project-write-scope-policy-001`
      `active`, päächeckout ja 12 muuta työpuuta säilytetty koskemattomina).

## Tapausvertailu (6 skenaariota — dokumentoitu sääntö- ja toimintatapavertailu)

_Huomio: Alla oleva taulukko on dokumentoitu sääntö- ja toimintatapavertailu
sekä tämän tehtävän todellisten työvaiheiden havainnointi — se ei ole
koneellisesti suoritettu valtuutusvalvonnan automaattitesti (`tools/run-gates.sh`
ei koneellisesti vertaa muutospolkuja tehtävän valtuutukseen)._

| # | Skenaario | Vanha 5 tiedoston ajoraja (`b0499e2d`) | Uusi tehtäväkohtainen kirjoitusrajaus (`SKILLS.md`) | Todennettu havainto tässä tehtävässä |
| :--- | :--- | :--- | :--- | :--- |
| 1 | **Hyväksytyt >= 6 sisältöpolkua** | Mekaaninen pysähdys 5 polun kohdalla (ml. kortin `git mv` = 2 polkua + `PRJ`), pilkkominen 4 erilliseen ajoon välikuittauksin. | Etenee yhtenä kokonaisuutena hyväksyttyyn toimitusrajaan ilman lukumäärä-, commit- tai vuoroporttia; muutosmäärä raportoidaan katselmointiin (`SKILLS.md` r. 46–61). | Commit `9ec97525` kattoi 11 hyväksyttyä sisältö-/rekisteripolkua + kortin yhdessä loogisessa toteutusvaiheessa ilman välikyselyjä. |
| 2 | **Uusi hyväksymätön polku** | Saattoi mahtua lukumäärän sisään (jos <= 5 polkua) tai vaatia sekä uuden ajon että polun tarkistuksen. | Välitön pysähdys ja yksi koottu muutosesitys perusteluineen ennen kirjoitusta (`SKILLS.md` r. 66–69; `.codex/skills/make-repo-contribution/SKILL.md` r. 58–59). | `npm ci` paljasti, ettei `.gitignore` sisällä `node_modules/`-riviä; `.gitignore` ei kuulunut hyväksyttyihin polkuihin, joten sitä ei muokattu vaan käytettiin kohdistettua stageausta. |
| 3 | **Saman tehtävän session jatko** | Epäselvä "per run / per batch" -tulkinta johti uuden luvan kysymiseen uuden session tai keskusteluvuoron alussa. | Tarkistaa nykytilan ja tallennetun valtuutuksen tehtäväkortista/`PRJ`-tietueesta ja jatkaa sovittuun toimitusrajaan asti ilman saman luvan toistamista (`SKILLS.md` r. 56–61). | Valtuutus, hyväksytyt polut ja toimitusraja on tallennettu pysyvästi sekä tähän korttiin että `PRJ-PROJECT-WRITE-SCOPE-POLICY.md`-tietueeseen. |
| 4 | **PR:ään rajattu valtuutus vs. merge** | `SKILLS.md`:n vanha mekaaninen PR-lista ohjeisti `gh pr merge --auto --squash` tarkistusten jälkeen. | Toimitus päättyy PR:n avaamiseen/päivittämiseen; merge ja auto-merge vaativat aina erillisen merge-valtuutuksen ja riippumattoman ihmishyväksyntänäytön (`SKILLS.md` r. 70–76, 260–271). | PR #227 on avattu katselmointiin; mergeä, auto-mergeä, `04-done`-siirtoa tai `delivered`/`closed`-tilaa ei ole tehty. |
| 5 | **Muiden paikallisen työn säilytys** | `SKILLS.md`:n vanha `git add -A` vaaransi likaisen työpuun ja seuraamattomat tiedostot. | Eristetty worktree ja pakollinen kohdistettu stageaus (`git add -- <approved-paths>`; `SKILLS.md` r. 247–256) pitävät muut tiedostot koskemattomina. | Päächeckoutin 2 muokattua seurattua tiedostoa, 19 seuraamatonta polkua (ml. `tasks/00-backlog/project-write-scope-policy-001.md`), kaikki 12 muuta worktreetä ja tämän worktreen `node_modules/` säilyivät koskemattomina/commitoimattomina. |
| 6 | **Pakollisen portin epäonnistuminen** | Riski pyytää turha uusi lupa hyväksytyn polun muotoilukorjaukseen tai yrittää ohittaa portti. | Virheen saa korjata suoraan hyväksytyissä poluissa ilman uutta lupaa, mutta pakollista porttia ei saa koskaan ohittaa; ratkaisematon virhe estää toimituksen (`SKILLS.md` r. 62–65). | `markdownlint-cli2` / Prettier havaitsi `PRJ-PROJECT-WRITE-SCOPE-POLICY.md`:n taulukkosarakkeen `MD060`-tasausvirheen; virhe korjattiin hyväksytyssä polussa ja portit ajettiin uudelleen tuloksella PASS (`5e46c7af...` säilyi). |

## Tarkistusten tulokset (PASS / FAIL / SKIPPED / NOT APPLICABLE)

- **PASS:**
  - `render_projects_csv.py --print-source-hash docs/governance/project_registry/PRJ-PROJECT-WRITE-SCOPE-POLICY.md`: `5e46c7af00b837cf3ede2eed2e5256bc1df5f11f7d71785160bcfe98b6ee4367` (tallennetusta lähdelohkosta laskettu ja säilynyt tavuntarkasti myös Prettier-muotoilun jälkeen; `PRJ-REGISTRY-ROLLOUT.md` säilyi `83d725739700bef4dbd47f3bb23777d389cdf7096148d40b0a57301b3af27dd1`).
  - `render_projects_csv.py --verify-guard` ennen molempia päivityksiä (`479813b6...` ja `9ec97525...`): `OK` (exit 0).
  - `render_projects_csv.py` CSV-generointi kahdesti peräkkäin kohteeseen `tools/project_registry/outputs/projects.csv`: tavuntarkasti identtiset ajot sekä `render_projects_csv.py --check` (`OK`, exit 0).
  - `git check-ignore -v -- tools/project_registry/outputs/projects.csv`: `.gitignore:43:**/outputs/` (exit 0).
  - `python -B -m unittest discover -s tools/project_registry/tests -p test_render_projects_csv.py`: 62 testiä ajettu, 60 PASS (exit 0).
  - `npx --no-install prettier --check` kaikille muuttuneille CI-piirin Markdown-tiedostoille (`SKILLS.md`, `AGENTS.md`, `GEMINI.md`, `Fear-of-Falling/GEMINI.md`, `docs/governance/project_registry/README.md`, `docs/governance/project_registry/PRJ-PROJECT-WRITE-SCOPE-POLICY.md`, `.codex/skills/make-repo-contribution/SKILL.md`): exit 0.
  - `npx --no-install markdownlint-cli2` edellä mainituille + `config/steering.md`, `config/agent_policy.md`, `tasks/_template.md`: 0 virhettä (exit 0).
  - Staged `& ./tools/run-gates.ps1 --mode pre-push --smoke`: `OK: guardrails (pre-push)`, `OK: renv check (pre-push)`, `OK: smoke gates (pre-push)` ja täsmennetty muistutusilmoitus (`follow task-approved write scope (changed paths vs. task authorization are not mechanically validated by this gate)`) (exit 0).
  - `git diff --check` ja LF-rivinvaihtojen tarkistus (`tools/run-gates.sh` ja kaikki muokatut tiedostot): exit 0.
  - Aktiivisten ohjeiden `git grep` vanhalle 5 tiedoston ajorajalle: 0 jäänyttä sääntöviittausta nykyohjeissa; historialliset tehtäväkortit säilytetty koskemattomina.
- **FAIL:** Ei avoimia epäonnistuneita tarkistuksia (`0`).
- **SKIPPED:** `test_render_projects_csv.py`:n 2 Windows-symlink-oikeustestiä (`skipped=2`, normaali Windowsin ei-admin-käytös).
- **NOT APPLICABLE:** `K18/QC` ja R-/Python-tutkimusanalyysiajot — päärepon ei-tieteellinen hallinta- ja rekisteriohjemuutos; tutkimusdataa, mallikoodia tai `.py`/`.R`-tiedostoja ei muutettu.

## PR #227 katselmointihavaintojen (Sourcery #1–#6 ja PR-kuvaus) ratkaisut

1. **Sourcery #1 (`reports/K18_QC_runbook.md` merge-komento):** Paikannettu
   polkuun `reports/K18_QC_runbook.md` (`origin/main` `b0499e2d`, Git-blob
   `2d995d91d189221bf5a7cf25067f081a33fb770c`, rivit 197–198:
   `# Merge with squash strategy` / `gh pr merge <PR_NUM> --squash --delete-branch`).
   Kyseessä on historiallisen PR #49:n (`909f534`, 2026-01-05)
   operaattorirunbookin komentoesimerkki, joka on alisteinen `SKILLS.md`:n
   ylimmälle etusijalle, `Fear-of-Falling/GEMINI.md`:n PR-etusijasäännölle sekä
   `.codex/skills/make-repo-contribution/SKILL.md`:n turvarajalle #1
   (dokumenttiproosan komentoja ei suoriteta sellaisenaan) ja eksplisiittiselle
   merge-kiellolle. Polku ei kuulu tämän tehtävän hyväksyttyyn kirjoitusrajaukseen,
   joten sitä ei muokattu; mahdollinen yhden polun vapaaehtoinen täsmennysehdotus
   on raportoitu Ownerille.
2. **Sourcery #2 (`tools/run-gates.sh` r. 24 ilmoitusteksti):** Ratkaistu
   täsmentämällä rivin 24 `echo`-ilmoitus muotoon, joka ilmaisee tehtäväkohtaisen
   kirjoitusrajauksen olevan noudatettava käytäntö, mutta ettei portti
   koneellisesti validoi muutospolkujen vastaavuutta tehtävän valtuutukseen.
   Porttilogiikkaa ei muutettu.
3. **Sourcery #3 (kortti `02-in-progress`-polussa) ja #4 (tapausvertailu ja
   review-tila):** Havainnot kohdistuivat aiempaan välivaiheen committiin
   `9ec9752537e2e72c6d295cb8b028b97a0e3d37af`. Ne on ratkaistu jo
   review-handoff-commitissa `aacb5ad4da973c4b0e08a530985b1fd7820d027f`, jossa
   kortti on polussa `tasks/03-review/project-write-scope-policy-001.md`
   (`Tila: REVIEW`), kuuden skenaarion dokumentoitu tapausvertailu on tässä
   kortissa ja `docs/governance/project_registry/PRJ-PROJECT-WRITE-SCOPE-POLICY.md`
   viittaa `03-review`-polkuun.
4. **Sourcery #5 (viiden tiedoston ajorajan poistaminen ja >5 polun muutos):**
   Tarkoituksellinen, tehtävän tavoitteen mukainen muutos. Ownerin 2026-11-18
   päätös ja nimetty kertapoikkeus vanhasta 5 tiedoston ajorajasta on kirjattu
   tämän kortin osioon `Ownerin toteutuspäätös ja valtuutus (2026-11-18)`.
   Viiden tiedoston rajaa ei palauteta.
5. **Sourcery #6 (`.codex/skills/make-repo-contribution/SKILL.md` uudet
   ohjetekstit englanniksi):** Ratkaistu suomentamalla tässä PR:ssä lisätyt ja
   muutetut ohjekohdat (`Approval Model` ja `Validation` viimeinen luettelokohta)
   repon kielipolitiikan mukaisesti kääntämättä vanhaa muuttumatonta tiedostoa.
6. **PR #227 -kuvauksen rikkoutuneet merkit ja koodiaidat:** Ratkaistu
   päivittämällä PR #227:n kuvaus PowerShellin literal here-stringillä (`@'...'@`)
   ja `gh pr edit 227 --body-file` -komennolla ilman kontrollimerkkejä.

## Erillisiksi jätetyt rajauksen ulkopuoliset havainnot

- Päärepon `WORKFLOW.md` (r. 44) sisältää edelleen yleisen worktree-poistovaatimuksen ennen `04-done`-tilaa, kun taas projektirekisterin `README.md` ja Owner-päätökset erottavat `main`-toimituksen ja erikseen valtuutettavan worktree-siivouksen (`SKILLS.md` voittaa).
- Aliprojektien vanhat `WORKFLOW.md`- ja `agent_workflow.md`-tiedostot (`Electronic-Frailty-Index/`, `Fear-of-Falling/`, `Quantify-FOF-Utilization-Costs/`) sisältävät historiallisia `gpa1qf-gpa4qf`-suorapush/`04-done`-ohjeita, jotka ohittuvat repojuuren `SKILLS.md`-etusijalla.
- Repojuuren `.gitignore` ei listaa `node_modules/`-hakemistoa; paikallinen `npm ci` pidettiin commitoimattomana kohdistetulla stageauksella.

## Log

- 2026-11-17: Ownerin pyynnöstä laadittu BACKLOG-kortti liitteen
  `tasks/_template.md`-rakenteen mukaisesti. Toteutusta, reposääntöjen muutosta,
  etävarmennusta tai testiajoja ei ole tehty tämän kortin laatimisessa.
- 2026-11-18T16:00:00+02:00: Suoritettu read-only-nykytilaselvitys ja valmisteltu
  koottu toteutusrajaus (`origin/main` `b0499e2de483e68f1f73f65d88859cac9b6778af`).
- 2026-11-18T16:09:00+02:00: Owner hyväksyi toteutusrajauksen PR-katselmointiin
  asti, nimetyn kertapoikkeuksen 5 tiedoston ajorajasta sekä projektitietueen
  `PRJ-PROJECT-WRITE-SCOPE-POLICY` perustamisen. `git fetch origin main` varmisti
  kannaksi `b0499e2de483e68f1f73f65d88859cac9b6778af`. Perustettu eristetty
  worktree `tmp/project-write-scope-policy-001` ja haara
  `docs/project-write-scope-policy-001` koskematta päächeckoutiin tai muihin
  työpuihin. Valmisteltu READY-kortti ja projektitietue `planned` /
  `not_delivered` -alkutilaan (`479813b6380eb5b541c67e8dd6c9cccccd0e8ee4`).
- 2026-11-18T16:15:00+02:00: Suoritettu `--verify-guard` (`OK`, exit 0)
  revisiota `479813b6380eb5b541c67e8dd6c9cccccd0e8ee4` vasten, siirretty kortti
  `01-ready` -> `02-in-progress` (`68fc70ad442b597c06b2bd1435702bccab2578cc`),
  vaihdettu `PRJ-PROJECT-WRITE-SCOPE-POLICY.md` `active` / `not_delivered` -tilaan
  ja toteutettu korvaava sääntö kanonisesti `SKILLS.md`:hen (ml. kohdistettu
  stageaus ja automerge-rajaus) sekä viite-/pohja-/ilmoituspäivitykset hyväksyttyihin
  polkuihin (`9ec9752537e2e72c6d295cb8b028b97a0e3d37af`).
- 2026-11-18T16:20:00+02:00: Avattu PR #227 katselmointiin, suoritettu
  `--verify-guard` (`OK`, exit 0) revisiota `9ec9752537e2e72c6d295cb8b028b97a0e3d37af`
  vasten, siirretty kortti `02-in-progress` -> `03-review`, kirjattu kuuden
  tapauksen vertailu ja validointinäyttö sekä päivitetty `PRJ-PROJECT-WRITE-SCOPE-POLICY.md`
  viittaamaan PR #227:ään ja `03-review`-polkuun (`active` / `not_delivered`,
  `aacb5ad4da973c4b0e08a530985b1fd7820d027f`).
- 2026-11-18T16:33:00+02:00: Jatkettiin aiemmalla valtuutuksella PR #227:n
  katselmointikorjauksiin (`--verify-guard` `OK` revisiolle
  `aacb5ad4da973c4b0e08a530985b1fd7820d027f`). Täsmennetty `tools/run-gates.sh`
  r. 24 ilmoitusteksti (ei koneellista muutospolkuvalvontaa), suomennettu
  `.codex/skills/make-repo-contribution/SKILL.md`:n tässä PR:ssä lisätyt/muutetut
  kohdat, selvitetty `reports/K18_QC_runbook.md` (blob `2d995d91...`) muuttamatta
  rajauksen ulkopuolista polkua, kirjattu Sourcery #1–#6 vastineet tähän korttiin
  sekä korjattu PR #227:n kuvaus ilman kontrollimerkkejä.

## Blockers

Ei aktiivisia esteitä PR-katselmointiin etenemiseksi. Merge, `04-done`-sulku ja
mahdollinen työpuun siivous odottavat PR-katselmoinnin jälkeistä erillistä
ihmishyväksyntää.

## Links

- `docs/governance/project_registry/PRJ-PROJECT-WRITE-SCOPE-POLICY.md`
- `docs/governance/project_registry/README.md`
- `SKILLS.md`
- `config/steering.md`
- `config/agent_policy.md`
- `AGENTS.md`
- `GEMINI.md`
- `Fear-of-Falling/GEMINI.md`
- `.codex/skills/make-repo-contribution/SKILL.md`
- `tasks/_template.md`
- `tools/run-gates.sh`
