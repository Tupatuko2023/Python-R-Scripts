# Analysis Ops Workflow

Tämä repositorio noudattaa Agent-First -metodologiaa analyysityössä (R + Python).
Hallinnollisessa työnkulussa (tehtäväkohtainen kirjoitus- ja toimitusrajaus,
PR-menettely, `main`-toimitus, tekninen `04-done`-sulku ja siivous) ylin kanoninen
ohje on [SKILLS.md](SKILLS.md). Aliprojektien tiukemmat tutkimus-, tietosuoja-,
QC- ja ympäristörajat säilyvät täysimääräisesti voimassa.

## Roolit

- **Human Supervisor (Ihmistutkija):**
  - Luo tehtäviä `tasks/00-backlog/` (tai aliprojektin omaan `tasks/00-backlog/`).
  - Määrittelee tehtävän tavoitteen, kirjoituspolut, toimitusrajan ja
    hyväksymiskriteerit (`Definition of Done`) sekä siirtää tehtävän
    `tasks/01-ready/`.
  - Tarkistaa `tasks/03-review/`-kansion tuotokset ja PR:n.
  - Tekee tehtävän hyväksymis- tai hylkäyspäätöksen ja arvioi sekä mergeää PR:n.
  - Hallinnoi [config/steering.md](config/steering.md) -fokusta.

- **AI Researcher (Agentti):**
  - Lukee [SKILLS.md](SKILLS.md), [AGENTS.md](AGENTS.md),
    [config/agent_policy.md](config/agent_policy.md) ja
    [REPO_CONTEXT.md](REPO_CONTEXT.md).
  - Poimii uuden toteutustehtävän vain `tasks/01-ready/`-kansiosta (tai
    aliprojektin omasta `tasks/01-ready/`-jonosta).
  - Etenee hyväksytyissä kirjoituspoluissa sovittuun toimitusrajaan asti ja
    siirtää tehtävän `tasks/03-review/`-kansioon PR-katselmointia varten.
  - Saa todennetun, pysyvän riippumattoman ihmishyväksynnän jälkeen tehdä saman
    tehtävän teknisen `04-done`-siirron, validoinnin ja sulku-PR:n; ei hyväksy
    omaa työtään.

## Prosessi ja vaiheiden erottelu (Workflow)

1. **Speksaus (Spec):**
   - Ihminen luo idean `tasks/00-backlog/`.
   - Kun tavoite, kirjoituspolut, hyväksytyt operaatiot, toimitusraja ja DoD ovat
     selkeät, tehtävä siirretään `tasks/01-ready/`.

2. **Suoritus (Execute):**
   - Agentti varmistaa ajantasaisen lähtötilan (likaista päächeckoutia
     pakottamatta, esim. eristetyssä worktreessä varmennetusta `origin/main`ista)
     ja siirtää kortin `tasks/02-in-progress/`.
   - Agentti toteuttaa muutokset vain hyväksytyissä kirjoituspoluissa ja päivittää
     tehtäväkortin lokia.
   - Jos tehtävä nimeää projektitietueen (`docs/governance/project_registry/PRJ-*.md`),
     noudatetaan [projektirekisterin käyttöohjetta](docs/governance/project_registry/README.md).

3. **Valmistuminen katselmointiin (`03-review` + PR):**
   - **Ennen `03-review`-siirtoa suoritettavat soveltuvat tarkistukset:**
     - Jos muutos koskee analyysikoodia, datajohdannaisia tai ympäristöä, aja
       aliprojektin ohjeiden mukainen smoke-run (Rscript tai Python) aliprojektin
       omasta työjuuresta, tarkista `renv/`-ympäristö ja kirjaa tarvittaessa
       `sessionInfo()` tai `renv::diagnostics()`, sekä aja aliprojektin QC-portti
       (esim. `K18/QC`) kun se on soveltuva. Ei-tieteellisissä hallinta- ja
       dokumentaatiotehtävissä analyysi- ja QC-ajot merkitään perustellusti
       `NOT APPLICABLE` eikä niitä käynnistetä turhaan.
     - Aja repon valmiit portit ja tarkistukset (kuten toimitusportti,
       Markdown-lint ja projektirekisteritarkistukset) worktreen repojuuresta
       laajentamatta työkaluketjua luvatta.
   - Agentti siirtää tehtävän `tasks/03-review/`-kansioon ja avaa tai päivittää
     PR:n sovitun toimitusrajan puitteissa. Suora push `main`-haaraan on kielletty.

4. **Hyväksytty `main`-toimitus ja tekninen sulku (`04-done`):**
   - **Hyväksyntä ja toimitus:** Owner tai muu tehtävälle määrätty ihminen kirjaa
     hyväksymispäätöksen täsmärevisiolle agentin task-lokista riippumattomaan,
     pysyvään lähteeseen [SKILLS.md](SKILLS.md):n näyttövaatimusten mukaisesti.
     Agentin oma task-merkintä ei kelpaa päätökseksi. Hyväksytty toteutus-PR
     yhdistetään `main`iin vasta erillisen merge-valtuutuksen ja tarkistusten
     läpäisyn jälkeen, ja toimitus varmennetaan `origin/main`ista.
   - **Tekninen sulku:** Varmennetun `main`-toimituksen ja hyväksynnän jälkeen
     agentti saa valtuutuksen mukaisesti siirtää saman tehtävän teknisesti
     `tasks/03-review/` -> `tasks/04-done/`, kirjata hyväksyntä- ja
     toimitusprovenancen, päivittää mahdollisen nimetyn `PRJ-*.md`-tietueen
     (`closed` / `delivered`), validoida rajatun muutoksen ja avata sulku-PR:n
     ihmiskatselmointiin.
   - **Hylätty tai korjattava:** Tarvittavat katselmointikorjaukset tehdään
     hyväksytyissä poluissa samaan PR:ään tai tehtävä palautetaan `tasks/01-ready/`
     palautteen kera.

5. **Työpuun, haaran ja kloonin siivous (erillinen vaihe, EI `DONE`-edellytys):**
   - Toteutuksen valmistuminen (`03-review`), `main`-toimitus / `04-done`-sulku
     ja siivous ovat erillisiä vaiheita: oletus toimituksen jälkeen on työpuiden,
     haarojen ja päächeckoutin säilyttäminen (`retained`).
   - Työpuita (`git worktree remove`, ei `--force`), haaroja (`git branch -d`,
     `git push origin --delete`) tai väliaikaisia erillisklooneja poistetaan
     **vain ihmisomistajan nimenomaisella erillisellä siivousvaltuutuksella** sen
     jälkeen, kun `main`-toimitus on varmennettu eikä kohteessa ole
     julkaisemattomia committeja, paikallisia säilytettäviä tuloksia tai aktiivista
     käyttöä.
   - Käyttäjän ensisijainen tai paikallisia muutoksia sisältävä checkout
     säilytetään aina koskemattomana. Toteutuneet poistot ja säilytetyt kohteet
     perusteluineen kirjataan erillään `main`-toimituksesta.

## Hakemistorakenne

- `tasks/`: Päärepon tehtäväjono (aliprojekteilla on omat tehtäväjononsa, esim. `Fear-of-Falling/tasks/` ja `Quantify-FOF-Utilization-Costs/tasks/`)
- `config/`: Ohjaus ja asetukset (Steering)
- `docs/`: Dokumentaatio ja projektirekisteri (`docs/governance/project_registry/`)
- `data/`: Data (älä muokkaa raakadataa)
- `src/`: Koodi ja analyysit
