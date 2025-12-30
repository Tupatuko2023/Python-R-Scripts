# Fear-of-Falling/outputs/ (legacy) — rajadokumentti

## 1) Tarkoitus (miksi tämä outputs/README on olemassa)

Tämä `Fear-of-Falling/outputs/README.md` määrittää **datan ja outputtien rajat** sekä minimikäytännöt, jotta repo pysyy auditointikelpoisena, tietosuojan mukaisena ja toistettavana.

* `outputs/` repojuuressa on **legacy/deprecated** eikä ole ensisijainen paikka analyysiajojen artefakteille.
* Ensisijainen tarkoitus on estää vahingossa tapahtuva raakadata-, PII- tai rivitason tulosten päätyminen GitHubiin ja yhtenäistää manifest-kirjaus.

## 2) Mitä tähän output-alueeseen kuuluu (allowed artifacts)

Tähän `Fear-of-Falling/outputs/`-kansioon saa kuulua vain **pieniä, ei-arkaluonteisia, repo-yleisiä** tiedostoja, jotka tukevat käytäntöjä, eivät analyysiajoja.

Sallitut esimerkit:

* Tämä README ja mahdollinen `.gitkeep`.
* **Käytäntödokumentit ja mallit** (esim. manifest-skeeman esimerkki, nimikäytännön esimerkit), jotka eivät sisällä data-arvoja.
* **Koontitason, täysin aggregoidut** (ei rivitasoa) esimerkkitulosteet, jos niitä tarvitaan dokumentointiin, esim. “malli-taulukkoformaatti” dummy-arvoilla tai täysin synteettisellä datalla.
* Mahdollinen “output policy” -tarkistuslista tai CI:ssä käytettävä pieni validointikonfiguraatio (ei dataa).

Jos jokin artefakti liittyy tiettyyn Kxx-ajoon tai skriptiin, se ei kuulu tänne vaan skriptikohtaiseen output-polkuun (kohta 4).

## 3) Mitä EI saa koskaan tallentaa/commitoida

Kiellettyä sekä `outputs/`-kansiossa että GitHubissa yleisesti:

* **Raakadata** tai siihen verrattavat tiedostot (esim. alkuperäiset CSV:t, poiminnat, dumpit).
* **PII tai suorat tunnisteet**: nimet, syntymäajat, osoitteet, tarkat yksilöivät tunnisteet, tai mikä tahansa tieto, jonka avulla osallistuja voidaan tunnistaa.
* **Rivitason taulukot** (myös “pseudonymisoidut”), joissa on yksilötason havainnot, pitkä formaatti `id`-riveinä, tai yksilölistaukset.
* **QC-artefaktit rivitasolla** (esim. listat puuttuvista id:istä, duplikaattiriveistä, yksilökohtaisista poikkeamista). QC-outputit vain aggregaattina.
* **Kuvakaappaukset/screenshotit** analyysituloksista tai datanäkymistä (myös IDE/Excel/BI-näkymät), koska niihin voi päätyä rivitason tai tunnisteellista tietoa.
* **Lokit**, jos ne sisältävät polkuja tai sisältöä, joka voi paljastaa dataa tai tunnisteita. (Tekniset lokit ovat ok vain, jos ne ovat selvästi ei-arkaluonteisia ja ilman data-arvoja.)

Periaate: GitHubiin saa päätyä vain sellainen output, joka on **aidosti julkaistavissa** (koontitaso, ei tunnisteita, ei rivitasoa) ja joka on kirjattu manifestiin sääntöjen mukaan.

## 4) Missä varsinaiset analyysioutputit sijaitsevat (canoninen polku)

Varsinaiset analyysi- ja QC-ajojen tuotokset kuuluvat skriptikohtaiseen polkuun:

* `R-scripts/<K_FOLDER>/outputs/<script_label>/`

Tämä repojuuren `outputs/`-kansio **ei korvaa** yllä olevaa “output discipline” -käytäntöä, vaan toimii vain rajadokumenttina ja yleisenä policy-paikkana.

## 5) Nimeäminen ja rakenne (script_label, Kxx, alikansiot; esimerkkipolut)

### Kanoninen rakenne

* `SCRIPT_ID` = K-kansion nimi (esim. `K11`, `K5`, `K2`).
* `script_label` = kanoninen tunniste output-alikansiolle:

  * jos tiedosto on versioitu `K5.1.V4_...R`, `script_label = K5.1` (prefix ennen `.V`).
  * muuten `script_label = file_tag` (koko runko ilman päätettä).

### Esimerkkipolut

Hyviä:

* `R-scripts/K11/outputs/K11/fixed_effects.csv`
* `R-scripts/K11/outputs/K11/interaction_plot.png`
* `R-scripts/K5/outputs/K5.1/model_summary.html`
* `manifest/sessionInfo_K11.txt` (repro-artefakti)
* `manifest/renv_diagnostics_K11.txt` (repro-artefakti)

Huomio: tiedostonimet ovat raportointivalmiita (csv/html/png/txt) ja sisältävät vain koontitason tuloksia.

### Alikansiot (suositus, ei pakollinen)

Jos outputteja on paljon, salli nämä alikansiot skriptin output-hakemiston sisällä:

* `tables/` (csv/html)
* `figures/` (png)
* `logs/` (vain ei-arkaluonteiset tekniset lokit)
* `meta/` (sessionInfo, renv diagnostics, run-metadata)

Älä koskaan tee alikansiota “data/” outputteihin.

## 6) Manifest-käytäntö (pakolliset sarakkeet, 1 rivi per artefakti, esimerkkirivi)

Kaikki tuotetut artefaktit kirjataan `manifest/manifest.csv`-tiedostoon:

* **1 rivi per artefakti** (ei niputusta).
* Pakolliset sarakkeet:

  * `file` (suhteellinen polku repojuuresta)
  * `date` (aikaleima, esim. `Sys.time()` / ISO)
  * `script` (esim. `K11` tai `K5.1`)
  * `git_hash` (lyhyt commit-hash, jos saatavilla; muuten `NA`)

Suositellut (yhteensopivuuden vuoksi voi olla mukana, jos repo käyttää):

* `type`, `filename`, `description`

### Esimerkkisheader

```csv
file,date,script,git_hash
```

### Esimerkkirivi

```csv
R-scripts/K11/outputs/K11/fixed_effects.csv,2025-12-30T15:00:00+02:00,K11,1a2b3c4
```

Manifestiin ei koskaan kirjata rivitason dataa eikä “sisältöä”, vain polut ja metatiedot.

## 7) Reproducibility (renv, seed-käytäntö, ajon metadata)

Pakolliset käytännöt:

* **renv**: ajojen tulee perustua `renv.lock`-ympäristöön ja `renv::restore()` ajetaan ennen analyysiä.
* **Seed**: käytä `set.seed(20251124)` vain kun mukana on satunnaisuutta (bootstrap, multiple imputation, resampling). Deterministisissä malleissa sitä ei tarvita.
* **Ajon metadata** (suositus, mutta käytännössä pakollinen audit trailille):

  * tallenna `manifest/`-kansioon vähintään:

    * `sessionInfo_<script_label>.txt`
    * `renv_diagnostics_<script_label>.txt`
  * kirjaa nämäkin manifestiin (1 rivi per tiedosto).

## 8) QC / portit (ei mallinnusta ennen QC; outputteihin vain aggregaatit QC:sta)

Ennen mallinnusta datan tulee läpäistä QC-gatet (repo-ankkurit ja checklist).

Säännöt:

* Ei mallinnusta ennen kuin QC on ajettu ja läpäisty (esim. aikapisteiden määrä, `id`+`time`-uniikkius, koodaukset, puuttuvat).
* QC-outputit, jotka saa tallentaa:

  * vain aggregaatit: lukumäärät, jakaumat, prosentit, solulaskennat, tarkistusraportit ilman yksilörivejä.
* QC ei saa tuottaa tiedostoja, joissa on yksilölistoja tai “poikkeavat id:t” -listauksia.

## 9) Lyhyt “Do/Don’t” -checklist ja esimerkkejä

### Do

* Tallenna analyysioutputit aina: `R-scripts/<K_FOLDER>/outputs/<script_label>/`.
* Kirjaa jokainen artefakti `manifest/manifest.csv`:ään (1 rivi per tiedosto).
* Pidä tulokset neutraaleina havainnoivaan asetelmaan sopivina (assosiaatiot, ei kausaaliväitteitä).
* Varmista muuttujakoodaukset ja aikapisteet data_dictionaryn mukaan (esim. `FOF_status`, `time`, delta-säännöt).
* Tallenna toistettavuusartefaktit (`sessionInfo`, `renv diagnostics`) `manifest/`-kansioon ja kirjaa manifestiin.

### Don’t

* Älä commitoi raakadataa, rivitason taulukoita, yksilölistoja tai kuvakaappauksia.
* Älä tallenna QC:sta mitään, mikä sisältää yksilökohtaisia rivejä tai tunnisteita.
* Älä käytä repojuuren `outputs/`-kansiota analyysiajojen tulosten “dump”-paikkana.

### Hyvät outputit (esimerkkejä)

* `.../fixed_effects.csv` (koontitaulukko: estimaatit, SE, 95% LV)
* `.../emmeans_time_by_fof.csv` (koonti)
* `.../interaction_plot.png` (kuva ilman data-labelien rivitasoa)
* `manifest/sessionInfo_K11.txt`

### Huonot outputit (esimerkkejä)

* `outputs/all_rows_long.csv` (rivitason data)
* `outputs/missing_ids.txt` (yksilölista)
* `outputs/screenshot_excel.png` (riskialtis sisältö)
* `outputs/raw_extract_*.csv` (raakadata tai poiminta)

---

Notes (oletukset ja TODOt)

* En listannut `Fear-of-Falling/outputs/`-kansion nykyisiä tiedostoja, koska en tässä ajossa selaa GitHubin hakemistorakennetta; teksti olettaa, että kansio on tyhjä tai sisältää vain policy-tiedostoja.
* Manifestin pakolliset sarakkeet on otettu repo-README:n ja THESIS_SCOPE:n linjauksista; jos teillä on jo käytössä lisäsarakkeet (type/filename/description), pidä ne mukana yhteensopivuuden vuoksi.
* QC-portit viittaavat QC_CHECKLIST-ankkuriin, mutta en sisällyttänyt checklistin yksityiskohtia tähän rajadokkiin, jotta tämä pysyy “policy”-tasolla.
* Aikamuuttujan (`time`) ja follow-up-koodauksen yksityiskohdat kannattaa varmistaa `data_dictionary.csv`:stä ja pitää ne yhdessä paikassa, kuten muuttujasanakirjan selite suosittaa.
* Jos repo sisältää myös Python-ajoja, lisää myöhemmin tähän README:hen lyhyt alakohta “Python outputs” samalla polkulogiikalla (esim. `python/<script>/outputs/<label>/`), mutta pidä manifest-säännöt samoina.
* Tämä dokumentti on alustava ehdotus; tiimin sisäinen hyväksyntä ja mahdolliset tarkistukset ennen käyttöönottoa.