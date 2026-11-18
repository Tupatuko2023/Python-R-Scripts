# Tehtäväkohtainen kirjoitusrajaus viiden tiedoston ajorajan tilalle

## Context

Tila: IN_PROGRESS. Tehtävätunnus: `project-write-scope-policy-001`.
Omistaja: Tomi Korpi. Orkestroija: FCPO2.
Projekti: `PRJ-PROJECT-WRITE-SCOPE-POLICY` (`docs/governance/project_registry/PRJ-PROJECT-WRITE-SCOPE-POLICY.md`).
Repo: `Tupatuko2023/Python-R-Scripts`.
Perustahaara ja varmennettu `origin/main`: `b0499e2de483e68f1f73f65d88859cac9b6778af`.
Työpuu ja tehtävähaara: `tmp/project-write-scope-policy-001` / `docs/project-write-scope-policy-001`.

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

- [ ] Nykyinen viiden tiedoston sääntö, sen viittaukset ja mahdollinen
      koneellinen valvonta on selvitetty tiedosto- ja revisionäytöllä.
- [ ] Hyväksytty korvaava sääntö määrittelee tavoitteen, kirjoitusrajauksen,
      valtuutuksen voimassaolon, toimitusrajan ja uutta päätöstä vaativat muutokset
      kanonisesti `SKILLS.md`:ssä (sekä korjaa `git add -A`- ja automerge-kohdat).
- [ ] Nykyohjeisiin ei jää ristiriitaista yleistä viiden tiedoston ajorajaa.
      Historialliset tehtäväkortit ja aiempien päätösten näyttö säilyvät.
- [ ] Aliprojektien soveltamisalat on huomioitu ilman yleistä ohjerefactorointia.
- [ ] Dokumentoitu tapausvertailu osoittaa vähintään seuraavat tulokset:
      hyväksytyt kuusi sisältöpolkua eivät aiheuta lukumääräpysähdystä;
      uusi hyväksymätön polku aiheuttaa rajauspäätöksen;
      saman tehtävän session jatko ei pyydä samaa lupaa;
      PR:ään rajattu valtuutus ei salli mergeä;
      muiden paikallinen työ säilyy;
      pakollisen portin epäonnistuminen ei oikeuta sen ohittamista.
- [ ] Projektitietue `PRJ-PROJECT-WRITE-SCOPE-POLICY.md` ja generoitu
      `tools/project_registry/outputs/projects.csv` läpäisevät lähdehash-,
      `--verify-guard`-, determinismi-, `--check`-, `git check-ignore`- ja
      yksikkötestitarkistukset.
- [ ] Soveltuvat Markdown- ja toimitusportit sekä `git diff --check` läpäisevät.
      `tools/run-gates.sh` päivittää vain vanhan ilmoitustekstin heikentämättä
      porttia. Tutkimusanalyysejä tai K18/QC-ajoja ei käynnistetä (`NOT APPLICABLE`).
- [ ] Riippumaton hyväksyntänäyttö kohdistuu katselmoituun revisioon, ja toimitus
      kanoniseen mainiin sekä tehtävän sulku on varmennettu paikallisin säännöin
      (myöhempi sulkuvaihe PR-katselmoinnin jälkeen).
- [ ] Työpuun säilytys tai erikseen valtuutettu siivous on raportoitu erillään
      toteutuksesta ja main-toimituksesta.

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
  työpuihin. Valmisteltu tämä READY-kortti ja projektitietue `planned` /
  `not_delivered` -alkutilaan (`479813b6380eb5b541c67e8dd6c9cccccd0e8ee4`).
- 2026-11-18T16:15:00+02:00: Suoritettu `--verify-guard` (`OK`, exit 0)
  revisiota `479813b6380eb5b541c67e8dd6c9cccccd0e8ee4` vasten, siirretty kortti
  `01-ready` -> `02-in-progress`, vaihdettu `PRJ-PROJECT-WRITE-SCOPE-POLICY.md`
  `active` / `not_delivered` -tilaan ja toteutettu korvaava sääntö kanonisesti
  `SKILLS.md`:hen (ml. kohdistettu stageaus ja automerge-rajaus) sekä
  viite-/pohja-/ilmoituspäivitykset hyväksyttyihin polkuihin (`config/steering.md`,
  `config/agent_policy.md`, `AGENTS.md`, `GEMINI.md`, `Fear-of-Falling/GEMINI.md`,
  `docs/governance/project_registry/README.md`,
  `.codex/skills/make-repo-contribution/SKILL.md`, `tasks/_template.md`,
  `tools/run-gates.sh`).

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
