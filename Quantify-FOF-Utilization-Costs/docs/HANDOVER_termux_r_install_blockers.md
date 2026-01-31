# HANDOVER: Termux R / Rscript -ajot estyvät agenttiympäristössä

## TL;DR

Tässä agenttiympäristössä R-ajojen (smoke/QC) ajaminen epäonnistuu, koska:

1. PRoot Debianissa **/usr/bin/Rscript puuttuu** ja R:n asennus PRootiin ei onnistu, koska **apt/apt-get on estetty ympäristötasolla** ("Ability to run this command as root has been disabled permanently for safety purposes.").
2. Termuxin natiivilla R:llä (pkg `r-base`) Rscript saadaan käyttöön, mutta projektin ajuri vaatii `readr`/`dplyr` (ja `tibble`), joita ei saada asennettua CRANista tässä ympäristössä, koska lähdekäännös epäonnistuu (`cli`, `tzdb`, mm. `bthread.h` puuttuu).

Näin ollen smoke-ajot eivät läpäise tällä hetkellä ilman joko:

- ajurin muuttamista **base-R-only** (poistaa readr/dplyr/tibble riippuvuudet), tai
- vaihtoehtoista pakettien toimitustapaa (Termux prebuilt `r-cran-*`, micromamba/conda), tai
- ajamista eri ympäristössä (desktop/CI/Docker), jossa R + paketit asentuvat normaalisti.

## Tausta / konteksti

Tavoitteena oli suorittaa vähintään “smoke” (QC-only ja gated models) R-ajurilla:

- `R/40_run_secure_panel_analysis.R`

ja varmistaa, että ajo ei kaadu binäärin puutteeseen (exit 127) ja että vähintään QC-only vaihe käynnistyy.

Huom: Raportissa ei käytetä absoluuttisia polkuja. Käytetään placeholderia:

- `<REPO_ROOT>` = projektin repojuuri
- `<DATA_ROOT>` = Option B:n mukainen datajuuri (repo ulkopuolella)

## Mitä kokeiltiin ja mitä tapahtui

### 1) PRoot Debian -strategia (hylätty: ympäristö estää)

**Odotus:** Aja Termuxista PRootiin: `/usr/bin/Rscript ...`

**Havainto A:** `/usr/bin/Rscript` puuttuu PRoot Debianista -> `exit 127`
**Havainto B:** R:n asentaminen PRootiin ei onnistu, koska `apt-get`/`apt` ei ole käytettävissä rootina:

> "Ability to run this command as root has been disabled permanently for safety purposes."

**Johtopäätös:** PRoot Debian ei ole käyttökelpoinen R:n asentamiseen tässä agenttiympäristössä.

### 2) Termux-native R (pkg) -strategia (osittain onnistui, paketit estävät)

**Toimenpide:** Asennettiin Termuxiin R:

- `pkg install -y r-base`

**Tulos:** `Rscript` löytyi PATHista ja `Rscript --version` onnistui.

**Ongelma:** Varsinaiset smoke-ajot kaatuivat, koska ajuri edellyttää `readr` ja `dplyr`:

- QC-only ajo: `exit 1`
- Models ajo: `exit 1`
- Virhesyy lokeissa: `there is no package called 'readr'` (ja/tai dplyr)

### 3) CRAN-lähdekäännös Termuxissa (hylätty: käännösvirheet)

**Yritettiin:** asentaa puuttuvat paketit CRANista (`install.packages("readr")`, `install.packages("dplyr")`)

**Tulos:** Lähdekäännös epäonnistui:

- `cli`-paketin käännös: `bthread.h` puuttuu / vastaava compile failure
- `tzdb`-paketin käännös: compile errors

**Lisähavainto:** Termux-toolchain muutokset:

- `gcc-15` asennus tehtiin riippuvuuksien toivossa
- tämä poisti `ndk-sysroot`-paketin, mikä voi vaikuttaa clang/NDK-pohjaisiin build-skenaarioihin

**Johtopäätös:** "Asenna tidyverse/CRAN lähteestä Termuxissa" ei ole luotettava polku tässä ympäristössä.

## Vaikutus tilaan / tuotokset

- Ajurin executable-bit on palautettu 644:iin (ei ajettava), jotta diff pysyy minimissä.
- Varsinaiset smoke-ajot eivät ole läpäisseet: kaatuvat puuttuviin R-paketteihin.

## Miksi tämä ei ole “user error”

Rajoitteet ovat ympäristöperäisiä:

- PRootissa apt-get on estetty pysyvästi (turvapolitiikka)
- Termuxissa CRAN-pakettien lähdekäännös voi epäonnistua (puuttuvat headerit/toolchain-ristiriidat) etenkin `cli`/`tzdb`-ketjussa

## Vaihtoehdot jatkoon (priorisoitu)

### Vaihtoehto 1 (suositus): Muuta ajuri base-R-only (ei readr/dplyr/tibble)

**Idea:** Poista riippuvuudet `readr`, `dplyr`, `tibble` ajurista:

- `readr::read_csv` -> `utils::read.csv`
- `readr::write_csv` -> `utils::write.csv`
- `dplyr::n_distinct` -> `length(unique(x))`
- `tibble::tibble` -> `data.frame(..., stringsAsFactors=FALSE)`

**Plussat:**

- Smoke/QC onnistuu Termux-native R:llä ilman CRAN-asennuksia
- Minimoi ympäristöriippuvuudet

**Miinukset:**

- Ajurin muutos (mutta rajattavissa yhteen tiedostoon)

### Vaihtoehto 2: Termux prebuilt R-paketit (r-cran-\*) erillisestä repositoriosta

**Idea:** Käytä Termux-yhteisörepoa, joka tarjoaa valmiiksi käännettyjä `r-cran-*` paketteja.

**Plussat:**

- Ei CRAN-lähdekäännöstä, vähemmän toolchain-kipua

**Miinukset:**

- Infra-riippuvuus (lisärepo), voi vaihdella laitteesta/arkkitehtuurista riippuen
- Vaatii dokumentoinnin ja ylläpidon

### Vaihtoehto 3: Micromamba/Conda user-space R

**Idea:** Asenna micromamba ja luo conda-forge R-ympäristö, jossa paketit tulevat binäärinä.

**Plussat:**

- Voi ratkaista `cli/tzdb` build-ongelmat

**Miinukset:**

- Lisää uusi dependency manager ja ympäristön kompleksisuus
- Ei aina toimi kaikissa rajoitetuissa ympäristöissä

### Vaihtoehto 4: Aja smoke eri ympäristössä (desktop/CI/Docker)

**Idea:** Suorita smoke-ajot koneessa/CI:ssä, jossa apt-get ja R-paketit asentuvat normaalisti.

**Plussat:**

- Nopein tapa saada validointi läpi

**Miinukset:**

- Ei toista agenttiympäristöä 1:1
- Vaatii erillisen ajopaikan ja logien siirron (redaktoituna)

## Suositeltu next step

1. Toteuta Vaihtoehto 1: base-R-only muutos ajuriin (yksi tiedosto).
2. Aja smoke Termux-native R:llä:
   - QC-only ensin (`RUN_QC_ONLY=true`)
   - mallit vain double-gated (`ALLOW_AGGREGATES=1` + `INTEND_AGGREGATES=true`)
3. Jos base-R-only muutos ei ole hyväksyttävissä, valitse Vaihtoehto 2 tai 3 (infra/paketointipolku).

## Päätöspisteet / mitä tarvitaan päätökseen

- Onko hyväksyttävää muuttaa ajuria poistamaan tidyverse-riippuvuudet? (suositus: kyllä)
- Vai vaaditaanko tidyverse: silloin valittava Termux prebuilt / conda / ulkoinen ajopaikka.

## Turva- ja tietosuojahuomiot

- Älä koskaan tulosta absoluuttisia polkuja stdoutiin (DATA_ROOT, repo polku).
- Älä liitä lokeihin/patcheihin osallistuja- tai rivitason dataa.
- Aggregoidut ajot vain double-gated (käyttäjän intent + `ALLOW_AGGREGATES=1`).
