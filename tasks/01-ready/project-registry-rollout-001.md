# Projektirekisterin käyttöönotto päärepossa

## State

- State: `01-ready`
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
