# Fear-of-Falling: Artifact manifest specification

Tämä dokumentti määrittää, miten pipeline-artefaktit kirjataan manifestiin siten, että:

* jokainen output on jäljitettävissä (mistä syntyi, millä versiolla, millä komennolla)
* QC ja analyysi voidaan auditoida ja toistaa
* sensitiivistä dataa ei vuoda (ei osallistujatason id-listoja, ei salaisuuksia komentoihin)

Asetelma: analyysiputki (data -> QC -> mallit -> taulukot/kuvat -> raportti).

## 1) Suositus: 2-tasoinen manifestointi (kevyt ja käytännöllinen)

**Pakollinen minimi (tämä repo):** `manifest/manifest.csv`, *yksi rivi per tuotettu artefakti*.

**Valinnainen laajennus (ei pakollinen):** `manifest/manifest.jsonl` (append-only event log), jos myöhemmin halutaan tiukempi audit trail.

> Huom: älä ota JSONL:ää käyttöön ennen kuin se on erikseen hyväksytty ja sovitettu olemassa oleviin `manifest_row`/`append_manifest`-funktioihin.

## 2) Perusperiaatteet

### 2.1 Relative paths

* Manifestiin kirjataan aina polku projektin juuresta alkaen (esim. `R-scripts/K18/outputs/...`).
* Älä kirjaa absoluuttisia polkuja (esim. `C:\Users\...`), eikä verkkoasemapolkuja.

### 2.2 Yksi rivi per artefakti

* Jokainen skripti/QC-runner lisää **tasen yhden** manifest-rivin per tiedostoartefakti.
* Jos skripti tuottaa N tiedostoa, manifestiin tulee N riviä.

### 2.3 Deterministisyys ja toistettavuus

* Manifestiin kirjataan vain metatietoa; se ei saa sisältää osallistujatason rivejä tai id-listoja.
* Jos analyysissä on satunnaisuutta (MI/bootstrap/resampling), seed dokumentoidaan skriptin introon ja/tai manifest-metatietoon projektisäännön mukaan.

### 2.4 Sensitiivisyys ja privacy

Manifestiin ei saa kirjoittaa:

* osallistujatason tunnisteita, id-listoja tai rivitasoisia avaimia
* salaisuuksia komentoihin (token/apikey/password)

## 3) Minimi-skeema (tämän repon vaatimus)

**Minimi vastaa nykyistä `manifest_row(...)`-toteutusta (`R/functions/reporting.R`).**

Pakolliset kentät (toteutuksen mukaiset nimet):

* `path`: suhteellinen polku tiedostoon
* `timestamp`: aikaleima (esim. `as.character(Sys.time())`)
* `script`: skriptin tunniste (esim. `K18_QC`)
* `label`: artefaktin tunniste/nimi
* `kind`: artefaktin tyyppi (esim. `table_csv`, `qc`)

Valinnaiset kentät (nykyisessä toteutuksessa):

* `n`: rivilukumäärä (jos relevantti)
* `notes`: lisätiedot

## 4) Laajennettu skeema (OPTIONAL / future)

Seuraavat kentät ovat hyödyllisiä auditoinnissa, mutta **eivät ole pakollisia** eivätkä tällä hetkellä `manifest_row`-funktion tuottamia:

* `git_hash` (Git commit hash)
* `command` (lyhyt komento)

## 5) Käyttöohje (integraatiopisteet)

Kirjaa manifest-rivi heti kun tiedosto on kirjoitettu levylle:

* QC: jokainen `qc_*.csv` ja `qc_*.png`
* Analyysi: mallitaulukot, kontrastit, kuvat, logit, `sessionInfo()`

Käytä apufunktiota: `append_manifest(manifest_row(...), manifest_path)`

## 6) Validointi (kevyt)

Ajon lopussa voidaan (valinnaisesti) tarkistaa:

* että kaikki uudet output-tiedostot on kirjattu manifestiin
* että manifestissa ei ole salaisuuksia (`token=`, `apikey`, `password`)

## 7) Versiohistoria

* 2025-12-29: ensimmäinen versio (dokumentti). Mukautettu vastaamaan `R/functions/reporting.R` toteutusta.
