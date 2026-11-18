# Analysis Ops Workflow

Tämä repositorio noudattaa Agent-First -metodologiaa analyysityössä (R + Python).
Hallinnollisessa työnkulussa (tehtäväkohtainen kirjoitus- ja toimitusrajaus,
PR-menettely, `main`-toimitus, tekninen `04-done`-sulku ja siivous) ylin kanoninen
ohje on [SKILLS.md](SKILLS.md). Aliprojektien tiukemmat tutkimus-, tietosuoja-,
QC- ja ympäristörajat säilyvät täysimääräisesti voimassa; ratkaisematon ristiriita
ohjeiden välillä pysäyttää riippuvan toimenpiteen (`STOP`) eikä anna lupaa valita
heikompaa sääntöä.

## Tehtäväjonon määrittely (`<queue-root>`)

Jokaisella tehtäväkortilla on oma kiinteä tehtäväjono (`<queue-root>`):

- päärepon tehtäville `tasks/`
- aliprojektin tehtäville kyseisen aliprojektin oma `<aliprojekti>/tasks/` (esim.
  `Fear-of-Falling/tasks/` tai `Quantify-FOF-Utilization-Costs/tasks/`).

Kaikki elinkaarisiirrot (`<queue-root>/00-backlog/` -> `<queue-root>/01-ready/` ->
`<queue-root>/02-in-progress/` -> `<queue-root>/03-review/` ->
`<queue-root>/04-done/`) tehdään **aina tehtävän omassa tehtäväjonossa**.
Aliprojektin tehtäväkortti ei koskaan siirry päärepon `tasks/`-jonoon eikä
päärepon kortti aliprojektin jonoon.

Jos tehtävä on linkitetty projektirekisteritietueeseen
(`docs/governance/project_registry/PRJ-*.md`), tietueen tehtävätaulukon
repojuureen suhteutettu `path` päivitetään **samassa muutoksessa** jokaisen
tehtäväkortin siirron kanssa ([projektirekisterin käyttöohje](docs/governance/project_registry/README.md)).

## Roolit

- **Human Supervisor (Ihmistutkija):**
  - Luo tehtäviä asianomaisen jonon `<queue-root>/00-backlog/`-kansioon.
  - Määrittelee tehtävän tavoitteen, kirjoituspolut, toimitusrajan ja
    hyväksymiskriteerit (`Definition of Done`) sekä siirtää tehtävän saman jonon
    `<queue-root>/01-ready/`-kansioon.
  - Tarkistaa `<queue-root>/03-review/`-kansion tuotokset ja PR:n.
  - Tekee tehtävän hyväksymis- tai hylkäyspäätöksen ja arvioi sekä mergeää PR:n.
  - Hallinnoi [config/steering.md](config/steering.md) -fokusta.

- **AI Researcher (Agentti):**
  - Lukee [SKILLS.md](SKILLS.md), [AGENTS.md](AGENTS.md),
    [config/agent_policy.md](config/agent_policy.md) ja
    [REPO_CONTEXT.md](REPO_CONTEXT.md).
  - Poimii uuden toteutustehtävän vain asianomaisen jonon `<queue-root>/01-ready/`-kansiosta.
  - Etenee hyväksytyissä kirjoituspoluissa sovittuun toimitusrajaan asti ja
    siirtää tehtävän saman jonon `<queue-root>/03-review/`-kansioon PR-katselmointia
    varten (päivittäen samalla mahdollisen linkitetyn `PRJ-*.md`-tietueen tehtäväpolun).
  - Saa todennetun, pysyvän riippumattoman ihmishyväksynnän jälkeen tehdä saman
    tehtävän teknisen `<queue-root>/04-done/`-siirron, validoinnin ja sulku-PR:n;
    ei hyväksy omaa työtään.

## Prosessi ja vaiheiden erottelu (Workflow)

1. **Speksaus (Spec):**
   - Ihminen luo idean `<queue-root>/00-backlog/`-kansioon.
   - Kun tavoite, kirjoituspolut, hyväksytyt operaatiot, toimitusraja ja DoD ovat
     selkeät, tehtävä siirretään saman jonon `<queue-root>/01-ready/`-kansioon.

2. **Suoritus (Execute):**
   - Agentti hakee `git fetch origin main`, ottaa talteen ja varmentaa täyden
     lähtö-commit-SHA:n ja perustaa eristetyn tehtäväworktreen sekä tehtävähaaran
     suoraan tästä varmennetusta SHA:sta koskematta päächeckoutin haaraan tai
     paikallisiin muutoksiin ([SKILLS.md](SKILLS.md)). Rinnakkaiset tehtävät
     käyttävät eri worktreitä.
   - Agentti siirtää kortin saman jonon `<queue-root>/02-in-progress/`-kansioon ja,
     jos tehtävä on linkitetty `PRJ-*.md`-rekisteritietueeseen, päivittää tietueen
     tehtäväpolun samassa muutoksessa (`--verify-guard`).
   - Agentti toteuttaa muutokset vain hyväksytyissä kirjoituspoluissa ja päivittää
     tehtäväkortin lokia.

3. **Valmistuminen katselmointiin (`03-review` + PR):**
   - **Ennen `03-review`-siirtoa suoritettavat soveltuvat tarkistukset:**
     - _Soveltuvat toimitus- ja dokumentaatiotarkistukset ovat aina pakollisia:_
       aja repon valmiit portit ja tarkistukset (kuten toimitusportti,
       Markdown-lint ja projektirekisteritarkistukset) saman eristetyn worktreen
       repojuuresta laajentamatta työkaluketjua luvatta.
     - _Analyysikoodi-, datajohdannais- ja ympäristömuutokset:_ aja aliprojektin
       ohjeiden mukainen smoke-run (`Rscript` tai `python`) aliprojektin omasta
       työjuuresta, tarkista `renv/`-ympäristö ja kirjaa tarvittaessa
       `sessionInfo()` tai `renv::diagnostics()`, sekä aja aliprojektin QC-portti
       (esim. `K18/QC`) kun se on soveltuva.
     - _Puhdas hallinto- tai dokumentaatiomuutos:_ ei itsessään valtuuta tai
       käynnistä tutkimusajoa eikä suojatun aineiston (`DATA_ROOT`/`AUTH_SOURCE`)
       lukua; soveltumattomat analyysi- ja QC-ajot merkitään perustellusti
       `NOT APPLICABLE`.
   - Agentti siirtää tehtävän saman jonon `<queue-root>/03-review/`-kansioon,
     päivittää mahdollisen linkitetyn `PRJ-*.md`-tietueen tehtäväpolun samassa
     muutoksessa ja avaa tai päivittää PR:n sovitun toimitusrajan puitteissa.
     Suora push `main`-haaraan on kielletty.

4. **Hyväksytty `main`-toimitus ja tekninen sulku (`04-done`):**
   - **Hyväksyntä ja toimitus:** Owner tai muu tehtävälle määrätty ihminen kirjaa
     hyväksymispäätöksen täsmärevisiolle agentin task-lokista riippumattomaan,
     pysyvään lähteeseen [SKILLS.md](SKILLS.md):n näyttövaatimusten mukaisesti.
     Agentin oma task-merkintä ei kelpaa päätökseksi. Hyväksytty toteutus-PR
     yhdistetään `main`iin vasta erillisen merge-valtuutuksen ja tarkistusten
     läpäisyn jälkeen, ja toimitus varmennetaan `origin/main`ista.
   - **Tekninen `TASK`-sulku ja erillinen `PRJ`-tarkistus:** Varmennetun
     `main`-toimituksen ja hyväksynnän jälkeen agentti saa valtuutuksen mukaisesti
     siirtää saman tehtävän teknisesti saman jonon `<queue-root>/03-review/` ->
     `<queue-root>/04-done/` ja kirjata hyväksyntä- ja toimitusprovenancen. Jos
     tehtävä on linkitetty `PRJ-*.md`-tietueeseen, tehtävätaulukon polku
     päivitetään samassa muutoksessa (`.../04-done/...`). **Yhden tehtävän `DONE`
     ei automaattisesti sulje koko projektia:** projektitietueen `state`- ja
     `delivery`-kentät määräytyvät projektin omista valmistumiskriteereistä
     (`done_criterion`), mahdollisista muista avoimista tehtävistä ja koko
     projektin toimitusnäytöstä (`closed` / `delivered` asetetaan vain, kun koko
     projektin kriteerit täyttyvät ja sulku sisältyy valtuutukseen). Lopuksi
     muutos validoidaan ja avataan sulku-PR ihmiskatselmointiin.
   - **Hylätty tai korjattava:** Tarvittavat katselmointikorjaukset tehdään
     hyväksytyissä poluissa samaan PR:ään tai tehtävä palautetaan saman jonon
     `<queue-root>/01-ready/`-kansioon (rekisteripolku päivittäen) palautteen kera.

5. **Työpuun, haaran ja kloonin siivous (erillinen vaihe, EI `DONE`-edellytys):**
   - Toteutuksen valmistuminen (`03-review`), `main`-toimitus / `04-done`-sulku
     ja siivous ovat erillisiä vaiheita: oletus toimituksen jälkeen on työpuiden,
     haarojen ja päächeckoutin säilyttäminen (`retained`).
   - Työpuita, haaroja tai väliaikaisia erillisklooneja poistetaan **vain
     ihmisomistajan nimenomaisella erillisellä siivousvaltuutuksella** noudattaen
     [SKILLS.md](SKILLS.md):n ehdollista siivousmenettelyä (toimituksen varmennus
     myös squash-mergelle, tracked/staged/untracked/ignored-sisällön ja aktiivisen
     käytön tarkistus, oikea poisto- ja haarajärjestys sekä välitön pysäytys
     virheessä; ei `--force`-, `git branch -D`- tai virheiden ohitusmenettelyä).
   - Käyttäjän ensisijainen tai paikallisia muutoksia sisältävä checkout
     säilytetään aina koskemattomana. Toteutuneet poistot ja säilytetyt kohteet
     perusteluineen kirjataan erillään `main`-toimituksesta.

## Hakemistorakenne

- `tasks/`: Päärepon tehtäväjono (aliprojekteilla on omat erilliset tehtäväjononsa, esim. `Fear-of-Falling/tasks/` ja `Quantify-FOF-Utilization-Costs/tasks/`)
- `config/`: Ohjaus ja asetukset (Steering)
- `docs/`: Dokumentaatio ja projektirekisteri (`docs/governance/project_registry/`)
- `data/`: Data (älä muokkaa raakadataa)
- `src/`: Koodi ja analyysit
