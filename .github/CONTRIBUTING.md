# Kontribuutio-ohjeet (Contributing Guidelines)

Tervetuloa kehittämään `Tupatuko2023/Python-R-Scripts` -monorepoa! Arvostamme panostasi.
Tämä dokumentti määrittelee säännöt ja käytännöt, joiden avulla varmistamme koodin
laadun, tutkimuksen toistettavuuden ja ehdottoman dataturvallisuuden.

## 1. Tervetuloa & mitä tähän repositorioon kuuluu

Tämä on R- ja Python-pohjainen analyysimonorepo, joka koostuu useista aliprojekteista
(esim. `Fear-of-Falling`, `Electronic-Frailty-Index`, `Quantify-FOF-Utilization-Costs`).
Kukin aliprojekti sisältää oman analyysiputkensa, omat skriptinsä (esim. Kxx-skriptit)
ja oman raportointinsa.

Säännöt koskevat koko monorepoa, mutta huomioi aina työskentelemäsi aliprojektin omat
spesifit ohjeet (kuten `Fear-of-Falling/CLAUDE.md` tai `GEMINI.md`).

## 2. Ennen kuin aloitat: Data, yksityisyys ja turvallisuus

**KRIITTINEN SÄÄNTÖ: Repoon ei saa koskaan päätyä potilastietoja (PHI) tai henkilötietoja (PII).**

- **Raakadata on muuttumatonta (immutable):** Älä koskaan muokkaa `data/`-kansion
  raakadatatiedostoja käsin (Excel, CSV jne.). Kaikki datan muokkaukset ja siivoukset
  on tehtävä koodin kautta.
- **Ei dataa committeihin:** Älä commitoi raakadataa, arkaluontoisia tuloksia tai
  salaisuuksia (esim. `.env`-tiedostoja, API-avaimia) versiohallintaan. Data on
  oletusarvoisesti `.gitignore`:ssa.
- **Fail-closed:** Jos data puuttuu tai sarake on väärin, koodin tulee kaatua
  selkeään virheeseen (ei "silent fail"). Älä arvaa muuttujien merkityksiä;
  tarkista ne `data_dictionary.csv`-tiedostosta.

## 3. Miten osallistua

1. **Issues:** Etsi avoimia issueita tai avaa uusi issue keskustellaksesi isommista
   muutoksista ennen koodauksen aloittamista.
2. **Pull Requests (PR):** Tee muutokset omassa haarassasi (branch) ja avaa PR
   päähaaraa (esim. `main` tai `master`) vasten.
3. **Tehtäväjono:** Projektissa voidaan käyttää tekoälyagenttien tehtäväjonoja
   (`tasks/`). Varmista, että et tee päällekkäistä työtä meneillään olevien
   automaattiajojen kanssa.

## 4. Työskentelytapa

- **Pienet muutokset:** Pidä PR:t pieninä ja loogisina kokonaisuuksina (yksi muutos per commit).
  Ei massiivisia refaktorointeja ilman ennakkoilmoitusta.
- **Oikea Working Directory:** Aja aliprojektin skriptit **aina** aliprojektin juuresta käsin.
  Älä suorita komentoja monorepon juuresta, ellei kyseessä ole globaali työkalu.

  ```bash
  # Esimerkki oikeasta hakemistosta:
  cd Python-R-Scripts/Fear-of-Falling
  ```

- **Suhteelliset polut:** Käytä koodissa aina suhteellisia polkuja tai `here::here()`-pakettia.
  Älä hardkoodaa absoluuttisia polkuja (kuten `C:/Users/...`).

## 5. Kehitysympäristö

Projekti tukee useita ympäristöjä (Windows PowerShell 7, Termux/PRoot Androidilla, Linux/macOS).

- **R-ympäristö (`renv`):**
  Analyysien toistettavuus taataan `renv`-paketilla. Palauta ympäristö aina ennen ajoa:

  ```r
  # R-konsolissa aliprojektin juuresta:
  if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
  renv::restore()
  ```

  _(Tee `renv::snapshot()` vain, jos lisäät uusia paketteja ja se on hyväksytty PR:ssä.)_

- **Python-ympäristö:**
  Käytä virtuaaliympäristöjä (esim. `venv`) ja asenna riippuvuudet repojuurta vastaavasta
  `requirements.txt`-tiedostosta, ellei aliprojektilla ole omaa konfiguraatiota.

## 6. Lint, format ja tyyliohjeet

- **R:** Noudatamme yleisesti lintr-sääntöjä (konfiguraatio `.lintr`-tiedostossa). Älä tee
  globaalia uudelleenmuotoilua muiden tiedostoihin ilman lupaa.
- **Python:** Noudatamme repossa määriteltyjä formatointityökaluja (Black, Ruff, jne.).
- **Markdown:** Pidä dokumentaatio siistinä (huomioi markdownlint-säännöt, kuten
  pakolliset kielitagit koodiblokeissa).

## 7. Testit ja verifiointi

Ennen PR:n lähettämistä, varmista että koodi toimii end-to-end.

- **Output Discipline:** Kaikkien tulosten tulee mennä määriteltyyn kansioon
  (esim. `R-scripts/<script_label>/outputs/`).
- **Manifesti-lokitus:** Jokaisesta tuotetusta artefaktista on kirjattava yksi rivi
  aliprojektin `manifest/manifest.csv`-tiedostoon. Myös `sessionInfo.txt` tulee tallentaa.
- **Table-to-Text Crosscheck:** Jos muokkaat raportointia, tarkista **aina** että tekstin
  numerot täsmäävät täsmälleen mallien tai taulukoiden tulostamiin lukuihin.
- **Smoke Testit:** Aja CI-putkea vastaavat paikalliset skriptit tai preflight-tarkistukset.

## 8. Commit- ja PR-käytännöt

- **Commit-viestit:** Kirjoita selkeitä, kuvaavia commit-viestejä. Kerro _mitä_ muutit
  ja _miksi_. (Esim. `fix: handle missing input column in K18`).
- **Ei generoitua dataa:** Älä commitoi automaattisesti generoituja `outputs/`-kansion
  tiedostoja tai raportteja, ellei sitä ole erikseen pyydetty.
- **PR-kuvaus:** Kerro PR:ssä selvästi:
  1. Mitä tiedostoja muutit.
  2. Miten ajoit ja validoit koodin (esitetyt komennot).
  3. Mitkä ovat mahdolliset riskit.

## 9. Turvarajat ja kielletyt toimet

- Älä ylikirjoita "virallisia" tuloksia ilman eksplisiittistä pyyntöä.
- Älä muuta analyysin tulkintaa tai päätuloksia salaa. Jos muutos vaikuttaa numeroihin
  tai malleihin, kerro siitä näkyvästi PR:ssä.
- Siemenluku (`set.seed(20251124)`) asetetaan vain skripteissä, jotka sisältävät
  aitoa satunnaisuutta (MI, bootstrap).

## 10. AI-avusteinen kontribuointi (Gemini, Claude, Copilot)

Tämä projekti hyödyntää laajasti tekoälyagentteja (esim. S-FOF Orchestrator).

- **Autonomia vs. laadunvarmistus:** Jos toimit ohjaavana AI-agenttina, noudata tiukasti
  `GEMINI.md`, `CLAUDE.md` ja `AGENTS.md` -tiedostoja (erityisesti fail-closed).
- **Koodausstandardit:** Agenttien tulee tuottaa valmiita, kohdistettuja muutoksia.
- **Ei hallusinaatioita:** Oleta vain olemassa olevat tiedostot ja säännöt.

## 11. Lisenssi ja viittauskäytäntö

Kontribuoimalla tähän repositorioon suostut siihen, että koodisi lisensoidaan samalla
lisenssillä kuin muu projekti (MIT). Jos viittaat projektiin akateemisessa työssä,
tarkista mahdollinen `CITATION.cff`-tiedosto.

## 12. Yhteydenotto

Jos sinulla on kysyttävää tietosuojasta tai analyysimenetelmistä, ota yhteyttä
repositoryn ylläpitäjään avaamalla GitHub Issue.
