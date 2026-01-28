# Repository Context for Agents

Tämä tiedosto kuvaa repositorion korkean tason "maailmankuvaa" AI-agenteille. Lue tämä ymmärtääksesi projektin luonteen.

## Projektin Tavoite

Tämä on analyysirepo (R + Python), jossa on useita aliprojekteja. Tavoitteena on tuottaa toistettavia analyyseja, pipeline-ajot ja QC-tarkistukset hallitusti sekä pitää tuotokset järjestetyissä output-polkuissa.

## Tekninen Ympäristö

- **Ohjelmointikielet:** Python ja R data-analyysiin.
- **Toistettavuus:** R-puolella käytetään aliprojektikohtaista `renv/`-ympäristöä (esim. `Fear-of-Falling/renv/`). Pythonissa käytetään `requirements.txt`-riippuvuuksia repojuuressa.
- **Kieli ja Termistö:**
  - Käytä suomea dokumentaatiossa ja commit-viesteissä.
  - Pidä tekniset termit (esim. "dataframe", "pipeline", "artifact") englanniksi tai vakiintuneessa muodossa.
- **Versionhallinta:** Git.

## Tärkeät Sijainnit

- `Electronic-Frailty-Index/`: EFI-aliprojekti (analyysit, raportit, taulukot, testit).
- `Fear-of-Falling/`: FOF-aliprojekti (R-skriptit, `renv/`, manifest/outputs).
- `Quantify-FOF-Utilization-Costs/`: erillinen FOF-analyysialiprojekti (scripts/outputs/reports).
- `src/`: yhteiset Python-moduulit ja analyysikoodi.
- `tests/`: pytest + R testthat -rakenteet.
- `data/`: esimerkkidata ja jaetut syötteet (älä muokkaa raakadataa ilman erillistä tehtävää).
- `scripts/`: apuskriptit ja ajorutit (esim. `scripts/ralph/`).
- `config/`: agenttien ohjeet ja ohjausdokumentit.
- `docs/` ja `reports/`: dokumentaatio ja raportit (vain jos tehtävä pyytää).
- `tasks/`: agenttien työjono (Agent-First).

## Työskentelytapa

- Olet tarkka, analyyttinen ja noudatat projektin ohjeita. Et arvaile, vaan verifioit. Jos et tiedä jotain, pysähdy ja kysy (luo `blocker`-tehtävä tai pyydä palautetta).
- Minimoi muutokset: koske vain tehtävään liittyviin tiedostoihin.
- Älä lisää raakadataa, salaisuuksia tai generoituja outputteja ilman nimenomaista pyyntöä.
