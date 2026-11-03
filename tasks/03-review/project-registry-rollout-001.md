# Projektirekisterin käyttöönotto päärepossa

## State

- State: `03-review`
- Tunniste: `project-registry-rollout-001`
- Repo: `Tupatuko2023/Python-R-Scripts`
- Haara: `chore/project-registry-rollout-001`
- Worktree repojuuresta: `tmp/project-registry-rollout-001`
- Varmennettu origin/main: `f3da52a4d86de7aa3a2aa7ff951405568000f8a2`.
- Omistaja valtuutti valmistelun, admissionin, toteutuksen, testit, commitit,
  draft-PR:n, pushit ja CI:n. Ei mergeä, DONEa tai worktree-/haarapoistoja.

## Context

Siirtotehtävä project-registry-transfer-001 on DONE eikä sitä avata uudelleen.
Otamme työkalun käyttöön päärepon koordinointiin. Pilottiprojekti on tämän
projektirekisterin käyttöönotto, ei tutkimusprojekti. Aliprojektien tehtäväjonot,
FCOT2 ja hyväksynnät säilyvät. Likainen päächeckout jätetään muuttumattomaksi.

## Inputs

AGENTS.md, SKILLS.md, config/agent_policy.md, config/steering.md,
.codex/skills/make-repo-contribution/SKILL.md, tasks/_template.md,
docs/governance/project_registry/README.md, nykyinen generaattori ja testit,
työkalujen portit sekä Python-/Markdown-CI.

## Outputs

- AGENTS.md: lyhyt linkki READMEhen ja vain tehtävään nimetyn projektin päivitysvastuu.
- docs/governance/project_registry/TEMPLATE.md: tyhjä täyttöpohja, ei PRJ-nimeä.
- docs/governance/project_registry/PRJ-REGISTRY-ROLLOUT.md: yksi todellinen päärepon projekti.
- docs/governance/project_registry/README.md: ajantasainen käyttöönotto- ja pohjaohje.
- Vain tämän saman kortin normaalit lifecycle-polut.

Viiden tiedoston raja per ajo: (1) READY-valmistelu yksi kortti; (2) erillinen
admission ready->in-progress, kaksi korttipolkua; (3) README-sovitus ja kortti,
kaksi polkua; (4) AGENTS, TEMPLATE ja PRJ sekä in-progress->review-korttipolut,
yhteensä viisi. Commitit erottavat nämä rajatut työosuudet. Ei generaattorin,
testien, workflowien, riippuvuuksien, ignoren, datan tai aliprojektien muutoksia.
CSV ja pilotin koeartefaktit vain olemassa oleviin ignored-tuloshakemistoihin.

## Definition of Done (DoD)

- Agentti löytää README-ohjeen ja päivittää vain sallittua, nimettyä projektia.
- Pohja kuvaa nykyiset litteät kentät, lähdelohkon/hash-sopimuksen ja erillisen
  worktree-inventaarion; täyttämätön pohja ei ole projektitietue.
- Pilotti kertoo tavoitteen, todellisen nykytilan, seuraavan askeleen, esteet,
  repoidentiteetin sekä koko repojuureen suhteutetut tehtäväviitteet.
- Toteutuksen, main-toimituksen ja worktree-siivouksen tiedot ovat erilliset.
- Agentti päivittää pilotin tilaa; ennen päivitystä normaali Git-guard läpäisee.
- Oletuspolkuun tools/project_registry/outputs/projects.csv muodostettu CSV
  säilyttää pitkän lähdekuvauksen, seuraavan askeleen ja esteet; kaksi ajoa
  ovat tavuntarkasti samat ja --check sekä erillinen ignore-tarkistus läpäisevät.
- TEMPLATE ja alihakemistojen PRJ-tiedostot jäävät pois synteettisessä kokeessa.
- Jatkamiskoe tunnistaa projektin ja tehtäväviitteiden avulla seuraavan
  toimenpiteen ilman chattia. Näyttö kirjataan tähän korttiin.
- Soveltuvat staged-portit, Prettier ja markdownlint läpäisevät; CI:n todella
  suorittamat tarkistukset raportoidaan. Ei väitettä suorittamattomista testeistä.
- #12 ja #14–16 säilyvät READMEssä avoimina. Review-valmius ja draft-PR:n
  täsmä-HEAD raportoidaan; ei mergeä, DONEa tai muiden töiden muutoksia.

## Log

- 2026-11-03: Tuore origin/main varmennettu, haara/worktree/task-törmäystä ei ole.
  README ja generoijan sopimus luettu. Tämä vaihe valmistelee vain READY-kortin;
  admission ja toteutus seuraavat erillisissä työosuuksissa samalla valtuutuksella.

## Blockers

Ei tunnistettua scope-estettä. Windows-sandboxin Git Bash -käynnistysvirhe
käsitellään käyttämällä sallittua suoritusympäristöä; ei porttien ohitusta.

## Links

- Ohje: docs/governance/project_registry/README.md
- Pilotti: docs/governance/project_registry/PRJ-REGISTRY-ROLLOUT.md
- Edeltäjä: tasks/04-done/project-registry-transfer-001.md

- 2026-11-03: Erillinen admission: READY-kortti löydetty uudelleen ja Git-näkyvyys
  sekä puhdas työpuu varmennettu. Rajattu Owner-valtuutus voimassa.
  Kortti siirretty in-progressiin ennen sisältömuutoksia.

- 2026-11-03: Työosuus 3: README ajantasaistettu pilotin ja TEMPLATE-pohjan
  käyttöön, lähde-/paikallisprovenance ja avoimet #12/#14–16 säilytetty.
  Vain README ja tämän kortin loki muuttuvat tässä työosuudessa.

- 2026-11-03: Pilotti toteutettu: AGENTS-kytkentä koskee vain tehtävän sallimaa
  projektia; TEMPLATE ei ole PRJ-tietue. Ensiluonnin Prettier lisäsi tyhjän
  rivin lähdelohkoon ja ensimmäinen generointi hylkäsi hashin. Hash päivitetty
  vastaamaan lopullista lohkoa; tämän jälkeen kuvauksen tavut pidetään samoina.
- Todellinen CSV: yksi projekti, 1035 merkin lähdekuvaus sanatarkasti, seuraava
  askel ja este säilyvät. Kaksi generointia identtiset, --check ja ignore PASS.
  delivery=not_delivered, Worktree-siivous=retained; main ei ole vielä toimitettu.
- Synteettisessä Git-repossa kopioitu TEMPLATE ja invalidi nested/PRJ-NESTED.md
  jätettiin pois; vain suora nimetty pilotti kerättiin. Aliprojekteihin ei kirjoitettu.
- Jatkamiskoe ilman chattia: repoidentiteetti, kaksi täyttä tehtäväpolkua ja kortin
  tarkistukset löytyvät; agentin seuraava toimi on CI-validointi, omistajan
  seuraava päätös uuden revision katselmointi/toimitus. Viitteet todella löytyvät.
- Git-guard PASS ennen tilapäivitystä; latest_status ja next_step päivitetty
  alkuperäisen lähdelohkon sisältöä muuttamatta. Päivitetty vienti tarkistetaan.
- Markdownin frontmatter-title lasketaan otsikoksi: body-otsikot korjattu
  kakkostasolle MD025:n mukaisesti. Ei lint-sääntöjen poikkeuksia.

## Review-handoff 2026-11-03

- Draft-PR: https://github.com/Tupatuko2023/Python-R-Scripts/pull/219
- Toteutusrevisio b896f88acd22e352067cdf8cb3b99b7e02ec1903: Markdown-CI
  41690785273 suoritti Prettierin ja markdownlintin SUCCESS; CodeQL-CI
  41690785378 Python/JavaScript sekä CodeQL SUCCESS. K-smoke luokitteli
  dokumentaatiomuutoksen ei-soveltuvaksi; skippi ei ole PASS-testiajo.
- Python-workflow ei käynnisty vain Markdownia muuttavasta diffistä. Generaattori
  ja sen testit ovat tavuntarkasti mainin mukaiset; tämän tehtävän näyttö on
  oikealla työkalulla ajettu pilotti, ei väite uudesta Linux-pytest-ajosta.
- Koko diffi katselmoitu: AGENTS-linkki on 11 rivin rajattu velvoite; TEMPLATE
  ei ole PRJ-tietue; pilotti koskee vain käyttöönottoa. Repoidentiteetti ja
  täydet tehtäväpolut tarkistettu. Ei vahvistettua korjausta vaativaa löydöstä.
  Tämä on tekninen agenttikatselmointi, ei ihmisomistajan hyväksyntä.
- Projektitietueen suojattu toinen tilapäivitys kirjaa omistajan seuraavaksi
  toimijaksi ja PR:n katselmoinnin seuraavaksi toimeksi. Task-viite päivitetty
  samaan review-polkuun, jonne kortti siirtyy. Lähdekuvaus säilyy samana.
- Komennot: python -B tools/project_registry/render_projects_csv.py;
  sama --check; sama --verify-guard <projektipolku> --expect-commit <luettu HEAD>;
  git check-ignore -v -- tools/project_registry/outputs/projects.csv;
  Prettier --check ja markdownlint-cli2 neljälle sisältö-Markdownille;
  tools/run-gates.ps1 --mode pre-push --smoke staged-indeksistä; git diff --check.
  Sisältö/determinismi/keräilyraja/jatkaminen kokeiltu Python-assertioilla
  synteettisissä ignored-tilapäisrepoissa; ei pysyviä koerivejä aliprojekteihin.
- README päivitettiin omassa kahden polun työosuudessa. Tässä työosuudessa
  AGENTS/TEMPLATE/PRJ ja saman kortin in-progress/review-polut = enintään viisi.
- Lopullisen handoff-HEADin CI ja päivitetyn CSV:n sisältö varmennetaan ja
  kirjataan PR-kuvaukseen ilman uutta metadata-commit-kierrosta.
- #12 ja #14–16 säilyvät avoimina. Käyttö luotetulle, katselmoidulle rekisterille;
  ei yleistä tuntemattomien avainten/escapejen/lähdesymlink-rajan tai
  rinnakkaiskirjoittajien järjestystakuuta. Omistaja arvioi soveltuvuuden.
- Ei mergeä, DONE-siirtoa tai worktree-/haarapoistoja. Päächeckout säilytetty.
