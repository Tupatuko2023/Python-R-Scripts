# Analysis Ops Workflow

Tämä repositorio noudattaa Agent-First -metodologiaa analyysityössä (R + Python).

## Roolit

- **Human Supervisor (Ihmistutkija):**
  - Luo tehtäviä `tasks/00-backlog/`.
  - Määrittelee tehtävän vaatimukset (`definition_of_done`) ja siirtää `tasks/01-ready/`.
  - Tarkistaa `tasks/03-review/` kansion tuotokset.
  - Hallinnoi `config/steering.md` fokusta.

- **AI Researcher (Agentti):**
  - Lukee `config/agent_policy.md` ja `REPO_CONTEXT.md`.
  - Poimii tehtäviä `tasks/01-ready/`.
  - Suorittaa työn ja siirtää tehtävän `tasks/03-review/`.

## Prosessi (Workflow)

1.  **Speksaus (Spec):**
    - Ihminen luo idean `tasks/00-backlog/`.
    - Kun idea on kypsä (selkeät input/output ja DoD), ihminen siirtää tiedoston `tasks/01-ready/`.

2.  **Suoritus (Execute):**
    - Agentti valitsee tehtävän (ks. `config/agent_policy.md`).
    - Agentti siirtää tiedoston `tasks/02-in-progress/`.
    - Agentti suorittaa työn (koodaa, kirjoittaa, analysoi).
    - Agentti päivittää lokia tehtävätiedostossa.

3.  **Tarkistus (Review):**
    - Agentti siirtää valmiin työn `tasks/03-review/`.
    - Ihminen tarkistaa työn laadun.

4.  **Hyväksyntä (Done):**
    - **Ennen siirtoa:**
      - Suorita vähintään yksi tyypillinen smoke-run (Rscript tai python) kyseisen aliprojektin ohjeiden mukaan.
      - Jos aliprojektissa on `renv/`, varmista että ympäristö on palautettavissa (`renv::restore()` tarpeen mukaan) ja kirjaa tarvittaessa `sessionInfo()` tai `renv::diagnostics()` lokiin.
      - Jos aliprojektissa on QC-runner (esim. `K18`-tyyppinen QC tai termux-runner), aja se ennen review-siirtoa.
      - Aja testit/lintit vain jos repo jo tarjoaa ne eikä se laajenna toolchainia (esim. `python -m pytest` tai projektin oma komento).
    - **Hyväksytty:** Ihminen siirtää tiedoston `tasks/04-done/`.
    - **Hylätty:** Ihminen palauttaa tiedoston `tasks/01-ready/` ja lisää palautteen tehtävänanto-osioon.

## Hakemistorakenne

- `tasks/`: Tehtäväjono (The Queue)
- `config/`: Ohjaus ja asetukset (Steering)
- `docs/`: Dokumentaatio (vain jos tehtävä vaatii)
- `data/`: Data (älä muokkaa raakadataa ilman erillistä tehtävää)
- `src/`: Koodi ja analyysit
