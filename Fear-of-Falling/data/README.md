# data/README.md (Fear-of-Falling)

## 1) Mitä dataa tässä projektissa käytetään

Tässä aliprojektissa käsitellään kaatumisen pelkoon (FOF) liittyvää tutkimusdataa.

- **Oikea data (sensitiivinen, ei GitHubissa):**
  - Sisältää henkilötietoja tai muuten sensitiivistä tutkimusdataa.
  - Ei kuulu versionhallintaan eikä CI-ympäristöihin.
  - Source-of-truth on organisaation / tutkimusryhmän hallinnoima tallennusratkaisu (ei kuvata tarkkoja polkuja tässä).

- **Testi/mock-data (synteettinen, CI/smoke-testit):**
  - Pieni, keinotekoinen datasetti, jonka rakenne vastaa analyysiskriptien odotuksia.
  - Tarkoitus on varmistaa, että putki ja skriptit ajautuvat läpi automaatiossa ilman oikeaa dataa.

## 2) Data dictionary

Tämän aliprojektin muuttujakartan lähde on `data/data_dictionary.csv`.
Sitä käytetään automaattisissa validoinneissa ja smoke-testeissä (esim. sarake- ja
tyyppitarkistukset), ja se on source-of-truth muuttujien nimille ja rooleille.
Älä lisää uusia muuttujarivejä ilman varmistusta datasta tai codebookista.

Pikakäyttö (ohje, ei vaadi oikeaa dataa):

```r
# dd <- read.csv("data/data_dictionary.csv", stringsAsFactors = FALSE)
# names(dd)
# subset(dd, needs_confirmation == "yes")
```

## 3) Kansiorakenne ja oletetut polut

Minimimalli (suositus). Jos repo poikkeaa tästä, päivitä ja täydennä.

- `data/raw/`
  - Oikea raakadata (EI GitHubissa).
  - TODO: täsmennä, mikä tiedosto on "kanoninen" input (nimi, mutta ei sisältöä).

- `data/processed/`
  - Johdettu data (yleensä EI GitHubissa).
  - Jos jotain pitää versionhallita, pidä se pienenä ja ei-sensitiivisenä (esim. sanakirja/metatieto).

- `data/testing/`
  - Synteettinen testidata CI/smoke-testien ajamiseen.
  - Oletus: `data/testing/mock_KaatumisenPelko.csv`

- `data/README.md`
  - Tämä ohje.

## 4) Versionhallinta- ja .gitignore-säännöt

### DO

- Commitoi:
  - `data/README.md` ja muut dokumentit (metatieto, ohjeet, datadictionary ilman sensitiivisiä sisältöjä).
  - Pieni synteettinen mock-data, jos se on aidosti keinotekoinen eikä sisällä henkilötietoja.

### DON'T

- ÄLÄ commitoi:
  - oikeaa tutkimusdataa missään muodossa (csv/xlsx/parquet/rds/sav tms.)
  - henkilötietoja (PII) tai pseudonymisoitua aineistoa, jota voi yhdistää takaisin henkilöihin
  - suuria tiedostoja (suositusraja: pidä mock-data ja muut repo-data-artefaktit alle 5 MB)
  - salaisuuksia: API-avaimia, tokeneita, salasanoja, `.env`-tiedostoja

### Suositus .gitignore-linjauksiksi (täydennä repojuuressa tarvittaessa)

- Ignoroi kaikki oikea data ja johdetut datasetit:
  - `data/raw/`
  - `data/processed/`

- Salli vain testidata ja README:
  - `!data/testing/`
  - `!data/testing/**`
  - `!data/README.md`

TODO: varmista nykyinen .gitignore-käytäntö (repojuuri + aliprojekti) ja sovita nämä siihen.

## 5) Mock-data CI/smoke-testeihin

### Miksi mock-dataa käytetään

CI-ympäristössä (esim. GitHub Actions) oikea data ei ole käytettävissä, koska se on sensitiivistä ja/tai salattua.
Mock-data mahdollistaa sen, että:

- skriptit ja pipeline voidaan ajaa end-to-end pienellä aineistolla
- perusrakenne, sarakkeet ja tyyppimuunnokset toimivat
- regressiot koodissa huomataan nopeasti

### Miten mock-data generoidaan

Mock-data generoidaan R-skriptillä:

```bash
Rscript tests/generate_mock_data.R [output_path]
```

- Jos `output_path` puuttuu, käytä projektin oletuspolkua (esim. `data/testing/mock_KaatumisenPelko.csv`).
- Mock-datan tulee olla 100% synteettistä eikä saa sisältää oikeita henkilötietoja.
