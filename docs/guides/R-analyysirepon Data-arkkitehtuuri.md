# Tietoturvallisen ja Toistettavan R-Analyysiarkkitehtuurin Suunnittelu: Data-Code Decoupling -Strategia

## A) Suositeltu arkkitehtuuri (DATA_ROOT + repo)

Nykyaikaisen datatieteen, erityisesti arkaluontoista terveystietoa tai henkilötietoa
käsittelevien hankkeiden, keskeisin haaste on ristiriita avoimuuden ja tietosuojan välillä.
Reproduktiivisuus eli toistettavuus vaatii koodin ja prosessien läpinäkyvyyttä, kun taas
tietosuoja (GDPR, organisaation sisäiset säännöt) vaatii aineiston tiukkaa rajaamista.
Ratkaisu tähän dilemmaan on arkkitehtuuri, joka erottaa täydellisesti laskennallisen
logiikan (koodin) ja sen operoiman aineiston (datan). Tätä kutsutaan
"Code-Data Decoupling" -periaatteeksi.

Tässä raportissa määritellään arkkitehtuuri, jossa R-analyysirepositorio toimii
"Metadata-Only" -periaatteella. Se sisältää vain prosessin kuvauksen ja metatiedot,
kun taas varsinainen aineisto elää täysin erillisessä, suojatussa DATA_ROOT-ympäristössä.
Tämä lähestymistapa eliminoi inhimilliset virheet polkujen määrittelyssä, estää vahingossa
tapahtuvat tietovuodot versionhallintaan ja takaa, että analyysi on toistettavissa missä
tahansa valtuutetussa ympäristössä ilman koodimuutoksia.

### 1. Arkkitehtuurin Yleisrakenne ja Komponentit

Ehdotettu malli jakaa analyysiympäristön kahteen fyysisesti ja loogisesti erilliseen kokonaisuuteen:

1. **Analyysirepositorio (Git):** Sisältää logiikan, skeemat ja synteettisen datan.
2. **DATA_ROOT (Secure Storage):** Sisältää tuotantodatan, väliaikaistiedostot ja auditointilokit.

#### Analyysirepositorio (Git-hallittu)

Repositorio on "stateless" eli tilaton komponentti. Sen tulee olla kloonattavissa mille
tahansa koneelle ja se on itsessään vaaraton, koska se ei sisällä riviäkään todellista
henkilötietoa.

- **R/**: Sisältää funktionaalisen ohjelmoinnin periaatteilla rakennetut R-funktiot.
  Koodi ei sisällä kovakoodattuja polkuja, vaan viittaa aina suhteellisiin polkuihin.
- **config/**: Järjestelmän "aivot". Täällä sijaitsevat CSV- ja YAML-tiedostot, jotka
  ohjaavat datan tulkintaa:
  - data_dictionary.csv: Määrittää, miltä "ideaalin" datan pitäisi näyttää.
  - VARIABLE_STANDARDIZATION_codex.csv: Toimii "Rosetta Stone" -käännöstaulukkona.
  - ingest_config.yaml: Tekniset asetukset Excel-lukuun.
- **tests/**: Sisältää yksikkötestit ja **synteettisen testidatan**.
- **.env.template**: Tiedosto, joka kertoo uudelle kehittäjälle vaaditut ympäristömuuttujat.

#### DATA_ROOT (Ulkoinen tallennus)

Tämä on tiedostojärjestelmän polku, joka määritellään ympäristökohtaisesti.

- **raw/ (Read-Only):** "Golden copy" alkuperäisestä datasta.
- **staging/ (Read-Write):** R-prosessin "työmuisti" (Parquet-muoto).
- **derived/ (Read-Write):** Analyysiä varten yhdistetyt ja jalostetut aineistot.
- **manifests/ (Audit Log):** Järjestelmän tuottamat JSON- tai CSV-raportit.

### 2. Konfiguraation Hallinta: .env ja dotenv

Jotta analyysi olisi toistettava ilman manuaalisia polkuja, käytetään .env -konfiguraatiota.

#### Toimintalogiikka

1. **Repo-taso:** .gitignore-tiedosto estää .env-tiedoston latautumisen Gitiin.
2. **Käyttäjätaso:** Analyytikko luo .env-tiedoston käyttäen .env.template-mallia.
3. **Sisältö:** .env-tiedosto sisältää avain-arvo -pareja (esim. DATA_ROOT).
4. **R-lataus:** Analyysin käynnistysskripti lukee nämä muuttujat dotenv-paketilla.

```r
# R/00_setup.R
library(dotenv)
library(fs)

# Yritä ladata .env tiedosto
if (file.exists(".env")) {
  dotenv::load_dot_env(".env")
}

# Lue DATA_ROOT ympäristömuuttujasta
DATA_ROOT <- Sys.getenv("DATA_ROOT")

# Validointi
if (DATA_ROOT == "") {
  stop("VIRHE: 'DATA_ROOT' ympäristömuuttujaa ei ole määritelty.")
}
```

### 3. "Metadata-Only" ja Synteettinen Data

Tietoturvan maksimoimiseksi käytetään synteettistä dataa kehitysvaiheessa. Tämä mahdollistaa
ingest-logiikan kehittämisen avoimesti.

---

## B) Excel ingest: monisivuiset lähteet ja virheenkesto

Excel on analyysin kannalta ongelmallinen formaatti. Luotettava analyysiputki vaatii
"defensiivisen" ingest-moduulin.

### 1. Monisivuiset Excel-tiedostot

Oikea lähestymistapa: Dynaaminen kartoitus readxl::excel_sheets()-funktiolla.

```r
# Pseudokoodi logiikasta
all_sheets <- excel_sheets(file_path)
data_list <- map(all_sheets, function(sheet) {
  read_excel(file_path, sheet = sheet, col_types = "text")
})
```

### 2. Salasanasuojatut ja Lukukelvottomat Tiedostot

Emme yritä purkaa salasanaa skriptillä. Rakennamme putken, joka tunnistaa suojatun
tiedoston ja kirjaa sen manifestiin virhetilalla.

### 3. Sarakkeiden Standardointi ja Gating-mekanismi

Käytämme "Infer -> Verify -> Freeze" -mallia sarakkeiden nimeämiseen.

---

## C) R-toteutusmalli (pseudokoodi + funktiorakenne)

### Suositellut Paketit

- readxl, arrow, dplyr, purrr, pointblank, digest, fs, dotenv.

### Funktiorakenne: "One-Way Door" Ingest

Analyysi ei koskaan lue Exceliä suoraan, vaan aina validoidun Parquet-tiedoston.

---

## D) QC ja toistettavuus (manifest, hashit, skeema, testidata)

### 1. File Fingerprinting (Sormenjäljet)

Käytetään SHA-256 -tiivistettä tunnistamaan tiedoston sisältö yksikäsitteisesti.

### 2. Datan Manifesti (Inventory)

Luodaan "Manifesti" – luettelo kaikista DATA_ROOT-kansiossa olevista tiedostoista.

### 3. Skeemavalidointi (pointblank)

Data on validoitava pointblank-paketilla ennen analyysia.

---

## E) Miksi nykyinen Python-kartutus voi arveluttaa, ja miten korjataan

"Kartuttava" skripti on tilallinen (stateful) ja altis virheille (indeterminismi).

### Korjaava Malli: Funktionaalinen ja Idempotentti Pipeline

Ehdotettu R-arkkitehtuuri perustuu **idempotenssiin**: Input on Read-Only, ja
Output luodaan aina "tyhjästä" tai korvataan kokonaan.

---

## F) Nopein etenemissuunnitelma (1-2 tuntia)

### Vaihe 1: Repon alustus ja Config
### Vaihe 2: Metadata ja Gating
### Vaihe 3: Ingest-skripti
### Vaihe 4: Mitä jätetään reposta POIS (Checklist)

---

#### Lähdeartikkelit

1. [Structuring R projects](https://www.r-bloggers.com/2018/08/structuring-r-projects/)
2. [Programming with R: Best Practices](https://swcarpentry.github.io/r-novice-inflammation/06-best-practices-R.html)
... (ja muut linkit listana)
