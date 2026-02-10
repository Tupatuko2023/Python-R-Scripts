# **Tietoturvallisen ja Toistettavan R-Analyysiarkkitehtuurin Suunnittelu: Data-Code Decoupling \-Strategia**

## **A) Suositeltu arkkitehtuuri (DATA\_ROOT \+ repo)**

Nykyaikaisen datatieteen, erityisesti arkaluonteista terveystietoa tai henkilötietoa käsittelevien hankkeiden, keskeisin haaste on ristiriita avoimuuden ja tietosuojan välillä. Reproduktiivisuus eli toistettavuus vaatii koodin ja prosessien läpinäkyvyyttä, kun taas tietosuoja (GDPR, organisaation sisäiset säännöt) vaatii aineiston tiukkaa rajaamista. Ratkaisu tähän dilemmaan on arkkitehtuuri, joka erottaa täydellisesti laskennallisen logiikan (koodin) ja sen operoiman aineiston (datan). Tätä kutsutaan "Code-Data Decoupling" \-periaatteeksi.

Tässä raportissa määritellään arkkitehtuuri, jossa R-analyysirepositorio toimii "Metadata-Only" \-periaatteella. Se sisältää vain prosessin kuvauksen ja metatiedot, kun taas varsinainen aineisto elää täysin erillisessä, suojatussa DATA\_ROOT-ympäristössä. Tämä lähestymistapa eliminoi inhimilliset virheet polkujen määrittelyssä, estää vahingossa tapahtuvat tietovuodot versionhallintaan ja takaa, että analyysi on toistettavissa missä tahansa valtuutetussa ympäristössä ilman koodimuutoksia.

### **1\. Arkkitehtuurin Yleisrakenne ja Komponentit**

Ehdotettu malli jakaa analyysiympäristön kahteen fyysisesti ja loogisesti erilliseen kokonaisuuteen:

1. **Analyysirepositorio (Git):** Sisältää logiikan, skeemat ja synteettisen datan.  
2. **DATA\_ROOT (Secure Storage):** Sisältää tuotantodatan, väliaikaistiedostot ja auditointilokit.

#### **Analyysirepositorio (Git-hallittu)**

Repositorio on "stateless" eli tilaton komponentti. Sen tulee olla kloonattavissa mille tahansa koneelle ja se on itsessään vaaraton, koska se ei sisällä riviäkään todellista henkilötietoa.

* **R/**: Sisältää funktionaalisen ohjelmoinnin periaatteilla rakennetut R-funktiot. Koodi ei sisällä kovakoodattuja polkuja (esim. C:/Users/Matti/Data), vaan viittaa aina suhteellisiin polkuihin, jotka johdetaan konfiguraatiosta.1  
* **config/**: Järjestelmän "aivot". Täällä sijaitsevat CSV- ja YAML-tiedostot, jotka ohjaavat datan tulkintaa:  
  * data\_dictionary.csv: Määrittää, miltä "ideaalin" datan pitäisi näyttää (sarakkeet, tyypit, sallitut arvot). Tämä on tavoitetila.3  
  * VARIABLE\_STANDARDIZATION\_codex.csv: Toimii "Rosetta Stone" \-käännöstaulukkona, joka yhdistää Excelien epämääräiset sarakenimet (esim. "Sotu", "Hetu", "Henkilötunnus") standardoituihin sisäisiin nimiin (personal\_id).3  
  * ingest\_config.yaml: Tekniset asetukset, kuten mitkä Excel-sheetit ohitetaan tai miten päivämäärät parsitaan.  
* **tests/**: Sisältää yksikkötestit ja **synteettisen testidatan**. Synteettinen data (tests/test\_data/fake\_raw.xlsx) on rakenteellisesti identtinen oikean datan kanssa, mutta sisältää satunnaistettua roskaa. Tämä mahdollistaa putken kehittämisen ja testaamisen CI/CD-ympäristöissä ilman pääsyä tuotantodataan.  
* **.env.template**: Tiedosto, joka kertoo uudelle kehittäjälle tai agentille, mitä ympäristömuuttujia analyysi vaatii toimiakseen, paljastamatta salaisuuksia.

#### **DATA\_ROOT (Ulkoinen tallennus)**

Tämä on tiedostojärjestelmän polku (esim. verkkolevy, salattu paikallinen osio tai S3-mount), joka määritellään ympäristökohtaisesti.

* **raw/ (Read-Only):** "Golden copy" alkuperäisestä datasta. Tähän kansioon on kirjoitusoikeus vain datan omistajalla (data steward), ei analyysiskripteillä. R-skriptit kohtelevat tätä *immutable*\-lähteenä. Excelit (.xlsx) sijaitsevat täällä.  
* **staging/ (Read-Write):** R-prosessin "työmuisti". Tänne tallennetaan Excelistä luetut, validoidut ja Parquet-muotoon muunnetut tiedostot. Tämä kansio voidaan tuhota ja luoda uudelleen milloin tahansa ajamalla ingest-skripti.  
* **derived/ (Read-Write):** Analyysiä varten yhdistetyt ja jalostetut aineistot (esim. "Analysis Ready Data").  
* **manifests/ (Audit Log):** Järjestelmän tuottamat JSON- tai CSV-raportit, jotka kertovat, *mitä* tiedostoja luettiin, *milloin*, ja mitkä olivat niiden SHA256-tiivisteet.4

### **2\. Konfiguraation Hallinta: .env ja dotenv**

Jotta analyysi olisi toistettava ilman, että käyttäjä joutuu syöttämään polkuja manuaalisesti (joka rikkoo automaation ja on virhealtista), käytetään teollisuusstandardin mukaista .env \-konfiguraatiota. R-kielessä tämä toteutetaan dotenv-paketilla 6 tai R:n sisäänrakennetulla .Renviron-mekanismilla.8

#### **Toimintalogiikka**

1. **Repo-taso:** Repositoriossa on .gitignore-tiedosto, joka estää .env-tiedoston latautumisen Gitiin. Tämä on tietoturvan ehdoton vaatimus.  
2. **Käyttäjätaso:** Kun uusi analyytikko tai agentti aloittaa työn, hän luo projektin juureen tiedoston .env käyttäen .env.template-mallia.  
3. **Sisältö:** .env-tiedosto sisältää avain-arvo \-pareja:  
   Bash  
   \#.env \- Local Configuration  
   DATA\_ROOT="/secure/network/share/project\_alpha\_data"  
   \# Windows-esimerkki:  
   \# DATA\_ROOT="X:/Research/Sensitive/ProjectAlpha"  
   LOG\_LEVEL="INFO"

4. **R-lataus:** Analyysin käynnistysskripti (esim. 00\_setup.R) lukee nämä muuttujat.

R

\# R/00\_setup.R  
library(dotenv)  
library(fs)

\# Yritä ladata.env tiedosto, jos se on olemassa  
if (file.exists(".env")) {  
  dotenv::load\_dot\_env(".env")  
}

\# Lue DATA\_ROOT ympäristömuuttujasta  
DATA\_ROOT \<- Sys.getenv("DATA\_ROOT")

\# Validointi: Pysäytä prosessi välittömästi, jos konfiguraatio puuttuu  
if (DATA\_ROOT \== "") {  
  stop("VIRHE: 'DATA\_ROOT' ympäristömuuttujaa ei ole määritelty. Luo.env tiedosto.")  
}

\# Varmista, että polku on olemassa ja meillä on lukuoikeus  
if (\!dir\_exists(DATA\_ROOT)) {  
  stop(paste("VIRHE: Määriteltyä data-hakemistoa ei löydy tai siihen ei ole pääsyä:", DATA\_ROOT))  
}

\# Määrittele alipolut  
DIRS \<- list(  
  raw     \= path(DATA\_ROOT, "raw"),  
  staging \= path(DATA\_ROOT, "staging"),  
  derived \= path(DATA\_ROOT, "derived"),  
  manifest \= path(DATA\_ROOT, "manifests")  
)

\# Luo tarvittaessa output-kansiot (idempotentti operaatio)  
dir\_create(c(DIRS$staging, DIRS$derived, DIRS$manifest))

Tämä menetelmä täyttää vaatimuksen: käyttäjän ei tarvitse syöttää polkuja chattiin. Agentti tai käyttäjä konfiguroi ympäristön kerran, ja sen jälkeen kaikki skriptit toimivat suhteessa abstraktiin DATA\_ROOT-muuttujaan.8

### **3\. "Metadata-Only" ja Synteettinen Data**

Tietoturvan maksimoimiseksi repositorion tests/test\_data/ \-kansioon luodaan synteettinen vastine DATA\_ROOT/raw \-kansiosta. Jos oikea data on Excel, jossa on välilehdet Potilaat ja Käynnit, synteettisessä Excelissä on samat välilehdet ja samat sarakkeet (Henkilötunnus, Pvm), mutta arvot ovat satunnaisia (010101-999X, 2099-01-01).

Tämä mahdollistaa sen, että ingest-logiikkaa (ks. osio B) voidaan kehittää ja testata täysin avoimesti. Kun koodi siirretään suojattuun ympäristöön, ainoa muutos on .env-tiedoston DATA\_ROOT-muuttujan osoittaminen oikeaan dataan synteettisen sijaan.

## ---

**B) Excel ingest: monisivuiset lähteet ja virheenkesto**

Excel on analyysin kannalta ongelmallinen formaatti: se on epärakenteellinen, altis manuaalisille muokkauksille ja teknisesti raskas lukea. Luotettava analyysiputki vaatii "defensiivisen" ingest-moduulin, joka olettaa datan olevan viallista, kunnes toisin todistetaan.

### **1\. Monisivuiset Excel-tiedostot**

Lähdeaineisto on kuvattu useina Excel-tiedostoina, joissa on useita välilehtiä (esim. snippetissä 3 mainittu KAAOS\_data.xlsx). Usein analyytikot tekevät virheen olettamalla, että data on aina ensimmäisellä välilehdellä tai tietyllä nimellä.

**Oikea lähestymistapa: Dynaaminen kartoitus**

1. **Listaus:** Käytetään readxl::excel\_sheets()-funktiota listaamaan kaikki välilehdet ennen lukemista.11  
2. **Suodatus:** Verrataan löytyneitä välilehtiä sallittujen listaan (whitelist) tai poistetaan tunnetut turhat (blacklist, esim. "ReadMe", "Sheet3").  
3. **Iteraatio:** Luetaan jokainen validi välilehti erikseen lapply tai purrr::map \-funktiolla.11

R

\# Pseudokoodi logiikasta  
all\_sheets \<- excel\_sheets(file\_path)  
valid\_sheets \<- all\_sheets

data\_list \<- map(valid\_sheets, function(sheet) {  
  read\_excel(file\_path, sheet \= sheet, col\_types \= "text") \# Kaikki tekstinä aluksi  
})

Tärkeä yksityiskohta on lukea kaikki sarakkeet aluksi tekstinä (col\_types \= "text"). Excelissä samassa sarakkeessa voi olla lukuja ja tekstiä, mikä saa R:n arvauslogiikan sekaisin. Tyyppimuunnokset on turvallisempaa tehdä hallitusti R:n puolella (esim. readr::parse\_number), kun data on jo ladattu.

### **2\. Salasanasuojatut ja Lukukelvottomat Tiedostot**

Käyttäjä mainitsi, että osa lähteistä voi olla lukukelvottomia, esimerkiksi salasanasuojattuja. R:n readxl-paketti ei tue salasanasuojattujen tiedostojen avaamista ja palauttaa virheen (esim. "zip file cannot be opened").15

**Virheenkäsittely ja "Fail-Safe" \-arkkitehtuuri:**

Emme yritä purkaa salasanaa skriptillä (tämä on epävarmaa ja tietoturvariski 16). Sen sijaan rakennamme putken, joka:

1. Tunnistaa suojatun tiedoston.  
2. Kirjaa sen "manifestiin" virhetilalla (ERROR\_ENCRYPTED).  
3. **Ei kaadu**, vaan jatkaa muiden tiedostojen käsittelyä.  
4. Raportoi käyttäjälle: "Tiedosto X on suojattu. Tallenna se ilman salasanaa kansioon raw/unlocked/".

Tämä toteutetaan tryCatch-rakenteella:

R

sheets \<- tryCatch(  
  { excel\_sheets(file\_path) },  
  error \= function(e) {  
    \# Tunnistetaan readxl:n virheilmoitus salauksesta  
    if (grepl("cannot be opened", e$message) |

| grepl("encrypted", e$message)) {  
      return("ENCRYPTED")  
    }  
    return("CORRUPT")  
  }  
)

### **3\. Sarakkeiden Standardointi ja Gating-mekanismi**

Excel-tiedostoissa sarakkeiden nimet vaihtelevat (Sotu, Hetu, Henkilötunnus). Ennen analyysia nämä on pakotettava yhteen muotoon. Tämä on kriittinen vaihe tietosuojan ("Metadata-only") ja toistettavuuden kannalta.

Käytämme "Infer \-\> Verify \-\> Freeze" \-mallia ja matchmaker-pakettia.18

1. **Infer (Päättely):** Skripti lukee raakanimet.  
2. **Verify (Varmistus):** Skripti vertaa nimiä VARIABLE\_STANDARDIZATION\_codex.csv \-tiedostoon.3  
3. **Rename (Uudelleennimeäminen):**  
   * Jos nimi löytyy koodistosta (variable\_original), se muutetaan standardinimeksi (variable\_en).  
   * Jos nimeä **ei löydy**, sarakkeelle annetaan etuliite UNMAPPED\_ (esim. UNMAPPED\_Lisätieto).

**Gating-sääntö:**

Ingest-vaiheen lopussa ajetaan validointi. Jos aineistossa on sarakkeita, joiden nimi alkaa UNMAPPED\_ ja jotka eivät ole tyhjiä, prosessi voi joko varoittaa tai pysähtyä. Tämä estää tilanteen, jossa analyytikko luulee käyttävänsä kaikkea dataa, mutta tärkeä uusi sarake (jonka nimi muuttui lähteessä) jääkin huomiotta. Se estää "arvaamisen".

## ---

**C) R-toteutusmalli (pseudokoodi \+ funktiorakenne)**

Tässä osiossa kuvataan konkreettinen koodirakenne. Suosittelemme käyttämään arrow-pakettia datan tallennukseen, koska se on huomattavasti Exceliä nopeampi ja tukee tiukkoja skeemoja.19

### **Suositellut Paketit**

* readxl: Excelin lukuun.  
* arrow: Parquet-tiedostojen käsittelyyn.  
* dplyr / purrr: Datan manipulointiin ja iterointiin.  
* pointblank: Datan validointiin.  
* digest: Tiedostojen eheyden varmistukseen (hashing).  
* fs / dotenv: Tiedostojärjestelmän ja konfiguraation hallintaan.

### **Funktiorakenne: "One-Way Door" Ingest**

Tavoitteena on muuntaa Excelit kerran deterministisesti Parquet-muotoon staging-kansioon. Analyysi ei koskaan lue Exceliä suoraan, vaan aina validoidun Parquet-tiedoston.

#### **1\. Ingest-funktio (R/ingest\_functions.R)**

R

library(readxl)  
library(arrow)  
library(purrr)  
library(dplyr)  
library(stringr)

\# Funktio yhden tiedoston käsittelyyn  
process\_excel\_file \<- function(file\_path, codex\_map) {  
    
  \# 1\. Turvallinen sheet-listaus (Virheenkesto)  
  sheets \<- tryCatch(  
    excel\_sheets(file\_path),  
    error \= function(e) {  
      warning(paste("SKIP: Ei voitu avata tiedostoa", basename(file\_path), "-", e$message))  
      return(NULL)  
    }  
  )  
    
  if (is.null(sheets)) return(NULL)  
    
  \# 2\. Iteraatio sheetien yli  
  file\_data \<- map\_dfr(sheets, function(sheet\_name) {  
      
    \# Ohita tunnetut turhat sheetit  
    if (sheet\_name %in% c("Ohje", "Metadata")) return(NULL)  
      
    \# Lue data "text"-muodossa tyyppiturvallisuuden vuoksi  
    \#.name\_repair="minimal" sallii oudot nimet, jotta voimme korjata ne itse  
    raw\_df \<- read\_excel(file\_path, sheet \= sheet\_name, col\_types \= "text",.name\_repair \= "minimal")  
      
    \# 3\. Standardoi sarakkeet (Gating)  
    \# Haetaan uudet nimet codex\_mapista  
    new\_names \<- map\_chr(names(raw\_df), function(orig\_name) {  
      match \<- codex\_map %\>% filter(variable\_original \== orig\_name)  
      if (nrow(match) \== 1) {  
        return(match$variable\_en)  
      } else {  
        \# Merkitään tuntemattomat, jotta pointblank voi myöhemmin liputtaa ne  
        return(paste0("UNMAPPED\_", orig\_name))  
      }  
    })  
    names(raw\_df) \<- new\_names  
      
    \# 4\. Lisää Lineage-metadata  
    raw\_df %\>%  
      mutate(  
        source\_file \= basename(file\_path),  
        source\_sheet \= sheet\_name,  
        ingest\_timestamp \= Sys.time()  
      )  
  })  
    
  return(file\_data)  
}

#### **2\. Orkestrointi (R/run\_ingest.R)**

R

source("R/00\_setup.R") \# Lataa DATA\_ROOT  
source("R/ingest\_functions.R")

\# Lataa metatiedot config-kansiosta  
codex \<- read\_csv("config/VARIABLE\_STANDARDIZATION\_codex.csv", show\_col\_types \= FALSE)

\# Hae kaikki Excelit raw-kansiosta  
files \<- dir\_ls(DIRS$raw, glob \= "\*.xlsx")

\# Suorita ingest kaikille  
all\_data \<- map\_dfr(files, \~process\_excel\_file(.x, codex))

\# 5\. Tallenna tulos Parquet-muotoon (Staging)  
if (nrow(all\_data) \> 0) {  
  \# Partitioning nopeuttaa lukemista, jos halutaan vain tietty lähde myöhemmin  
  arrow::write\_dataset(  
    all\_data,   
    path \= DIRS$staging,   
    format \= "parquet",  
    partitioning \= c("source\_file")   
  )  
  message("Ingest valmis: Data tallennettu staging-alueelle Parquet-muodossa.")  
} else {  
  warning("Ingest ei tuottanut dataa.")  
}

### **Vaihtoehtoinen malli: Miksi Parquet?**

Analyysissä, jossa luetaan 20+ Excel-tiedostoa, pelkkä read\_excel on hidas ja muistisyöppö. R lataa kaiken RAM-muistiin.

* **Excel:** Raskas, ei tue skeemaa (päivämäärät voivat olla lukuja tai tekstiä), rivirajoitteet.  
* **Parquet \+ Arrow:** Binäärimuoto, tukee pakkausta (pienempi levytila), sarake-orientoitu (nopea suodatus sarakkeiden mukaan) ja **Lazy Loading**. arrow::open\_dataset() ei lue dataa muistiin ennen kuin collect()-käsky annetaan.19

Tämä mahdollistaa sen, että analyysirepo voi käsitellä satojen megatavujen aineistoja kevyesti, vaikka DATA\_ROOT olisi hitaalla verkkolevyllä.

## ---

**D) QC ja toistettavuus (manifest, hashit, skeema, testidata)**

Jotta analyysi olisi luotettava, meidän on tiedettävä tarkalleen, *mitä* dataa on käytetty. Tiedostonimi analyysi\_final\_v2.xlsx ei kerro mitään sisällöstä.

### **1\. File Fingerprinting (Sormenjäljet)**

Käytetään kryptografista tiivistettä (SHA-256) tunnistamaan tiedoston sisältö yksikäsitteisesti. Jos yksikin solu Excelissä muuttuu, sen hash muuttuu täysin.22

R

library(digest)

calculate\_file\_hash \<- function(filepath) {  
  \# serialize=FALSE on tärkeä: haluamme tiedoston binäärisen hashin,   
  \# emme R-objektin hashia.  
  digest(file \= filepath, algo \= "sha256", serialize \= FALSE)  
}

### **2\. Datan Manifesti (Inventory)**

Ennen ingest-prosessia luodaan "Manifesti" – luettelo kaikista DATA\_ROOT-kansiossa olevista tiedostoista. Tämä toimii analyysin "kuittina".

**Manifestin luonti:**

R

generate\_manifest \<- function(dir) {  
  files \<- dir\_ls(dir, recurse \= TRUE, type \= "file")  
    
  tibble(  
    path \= path\_rel(files, start \= dir),  
    size\_bytes \= file\_size(files),  
    modified\_time \= file\_info(files)$modification\_time,  
    sha256 \= map\_chr(files, calculate\_file\_hash)  
  )  
}

\# Tallenna manifesti joka ajokerralla  
manifest \<- generate\_manifest(DIRS$raw)  
write\_csv(manifest, path(DIRS$manifest, paste0("manifest\_", Sys.Date(), ".csv")))

Tämä mahdollistaa muutosten havaitsemisen: vertaamalla tämän päivän manifestia eiliseen, näemme heti, onko joku muokannut Exceliä tai lisännyt uuden tiedoston.

### **3\. Skeemavalidointi (pointblank)**

Kun data on luettu ja standardoitu, se on validoitava ennen analyysia. pointblank-paketti on tähän erinomainen.25

Validointi kohdistuu staging-alueen Parquet-dataan.

R

library(pointblank)

\# Määritellään odotukset  
agent \<- create\_agent(tbl \= arrow::open\_dataset(DIRS$staging)) %\>%  
  \# Sääntö 1: Tärkeät sarakkeet eivät saa puuttua  
  col\_exists(columns \= c("personal\_id", "visit\_date")) %\>%  
  \# Sääntö 2: Standardointi onnistui (ei UNMAPPED-alkuisia sarakkeita)  
  col\_vals\_regex(  
    columns \= everything(),  
    regex \= "^(?\!UNMAPPED\_).\*",   
    label \= "Check for unmapped columns"  
  ) %\>%  
  \# Sääntö 3: Tietotyypit  
  col\_is\_character(columns \= c("personal\_id")) %\>%  
  col\_is\_date(columns \= c("visit\_date"))

\# Suorita tarkistus  
interrogate(agent)

Jos validointi epäonnistuu (esim. liikaa UNMAPPED-sarakkeita), prosessi voidaan konfiguroida pysähtymään (stop\_on\_fail \= TRUE).

## ---

**E) Miksi nykyinen Python-kartutus voi arveluttaa, ja miten korjataan**

Käyttäjä mainitsi aiemman toimintatavan: Python-skriptit, jotka "kartuttavat" dataa. Tämä viittaa usein **inkrementaaliseen** malliin, jossa uutta dataa haetaan ja lisätään (append) olemassa olevan tiedoston perään.

### **Riskianalyysi**

1. **Indeterminismi (Epämääräisyys):** "Kartuttava" skripti on tilallinen (stateful). Lopputulos riippuu siitä, *montako kertaa* skripti on ajettu. Jos ajat sen vahingossa kahdesti, saatat saada duplikaattirivejä. Jos ajat sen eri järjestyksessä, tulos voi olla eri.  
2. **Tilan korruptoituminen:** Jos kirjoitusprosessi katkeaa (esim. verkkovirhe), kohdetiedosto voi jäädä epämääräiseen tilaan (puolet uudesta datasta kirjoitettu, puolet ei). Korjaaminen on vaikeaa ilman transaktioita.  
3. **Jäljitettävyyden (Lineage) puute:** Suuressa, kartutetussa tiedostossa on vaikea sanoa, mikä rivi tuli mistäkin lähdetiedostosta ja milloin. Jos lähdetiedostossa huomataan virhe kuukauden päästä, sen siivoaminen kartutetusta massasta on painajainen.

### **Korjaava Malli: Funktionaalinen ja Idempotentti Pipeline**

Ehdotettu R-arkkitehtuuri perustuu **idempotenssiin**:

* **Input (Excelit):** Read-Only. Niihin ei kosketa.  
* **Process:** Deterministinen funktio f(input) \= output.  
* **Output (Staging):** Luodaan aina "tyhjästä" tai korvataan kokonaan.

Emme "päivitä" staging.parquet \-tiedostoa lisäämällä rivejä. Me **ylikirjoitamme** sen uudella versiolla, joka on laskettu nykyisestä raakadatasta.

**Miten varmistetaan tehokkuus?** Jos dataa on teratavuja, täysi uudelleenlaskenta on raskasta. Tällöin käytetään *osioitua* (partitioned) kirjoitusta.20

1. Luetaan Manifest.  
2. Tarkistetaan, mitkä tiedostot (hashit) on jo prosessoitu staging-kansioon.  
3. Prosessoidaan vain *uudet* tai *muuttuneet* tiedostot.  
4. Kirjoitetaan ne omiin Parquet-tiedostoihinsa (part-xyz.parquet).  
5. Koska Parquet on kokoelma tiedostoja, vanhoihin ei tarvitse koskea. arrow::open\_dataset näkee kansion yhtenä tauluna.

Tämä on turvallista kartuttamista: jokainen part-tiedosto vastaa yhtä lähdetiedostoa (Lineage säilyy). Jos lähdetiedosto poistuu, poistamme vastaavan part-tiedoston.

## ---

**F) Nopein etenemissuunnitelma (1-2 tuntia)**

Tässä on "Runbook" siirtymiseen Python-kartutuksesta turvalliseen R-putkeen heti.

### **Vaihe 1: Repon alustus ja Config (30 min)**

1. **Luo tiedosto .env** projektin juureen. Lisää sinne: DATA\_ROOT="X:/Polku/Oikeaan/Dataan".  
2. **Päivitä .gitignore**: Lisää rivit: .env, data/, \*.RData.  
3. **Luo R/00\_setup.R**: Kopioi yllä oleva (Osio A) koodi, joka lataa dotenv:n ja tarkistaa DATA\_ROOT:n.  
4. **Luo config/ \-kansio**: Siirrä data\_dictionary.csv ja VARIABLE\_STANDARDIZATION\_codex.csv sinne.

### **Vaihe 2: Metadata ja Gating (30 min)**

1. Avaa VARIABLE\_STANDARDIZATION\_codex.csv.  
2. Varmista, että kriittiset sarakkeet (esim. Henkilötunnus) on mapattu muotoon:  
   * variable\_original: "Sotu"  
   * variable\_en: "personal\_id"  
3. Tämä varmistaa, että ingest-skripti osaa käsitellä ne oikein (esim. pseudonymisoida tai hashata).

### **Vaihe 3: Ingest-skripti (60 min)**

1. Kirjoita R/01\_ingest.R käyttäen Osiossa C annettua process\_excel\_file-mallia.  
2. **Testaa synteettisellä datalla:** Luo kansioon tests/test\_data pieni Excel, joka matkii oikeaa rakennetta. Aja skripti osoittaen DATA\_ROOT tähän kansioon (muuta .env väliaikaisesti tai ylikirjoita R-istunnossa).  
3. Varmista, että tuloksena syntyy staging/ \-kansioon Parquet-tiedostoja.

### **Vaihe 4: Mitä jätetään reposta POIS (Checklist)**

* \[ \] **EI** Excel-tiedostoja (paitsi tests/fake\_data.xlsx).  
* \[ \] **EI** dataset.csv tai dataset.rds tiedostoja, jotka sisältävät oikeita rivejä.  
* \[ \] **EI** .Rhistory-tiedostoa (saattaa sisältää vahingossa kirjoitettuja salasanoja).  
* \[ \] **EI** Kovakoodattuja polkuja koodissa.

Tällä suunnitelmalla muutat "arvailevan" ja riskialttiin prosessin deterministiseksi, tietoturvalliseksi ja auditointikelpoiseksi pipelineksi yhdessä iltapäivässä.

#### **Lähdeartikkelit**

1. Structuring R projects \- R-bloggers, avattu helmikuuta 10, 2026, [https://www.r-bloggers.com/2018/08/structuring-r-projects/](https://www.r-bloggers.com/2018/08/structuring-r-projects/)  
2. Programming with R: Best Practices for Writing R Code \- Software Carpentry Lessons, avattu helmikuuta 10, 2026, [https://swcarpentry.github.io/r-novice-inflammation/06-best-practices-R.html](https://swcarpentry.github.io/r-novice-inflammation/06-best-practices-R.html)  
3. data\_dictionary.csv  
4. rhash checker \- GitHub Gist, avattu helmikuuta 10, 2026, [https://gist.github.com/dayne/250a9da0832b1d8c76ae11a1fa026f9c](https://gist.github.com/dayne/250a9da0832b1d8c76ae11a1fa026f9c)  
5. How to generate manifest (List of files with their sizes and count) for a folder in linux, avattu helmikuuta 10, 2026, [https://stackoverflow.com/questions/15682063/how-to-generate-manifest-list-of-files-with-their-sizes-and-count-for-a-folder](https://stackoverflow.com/questions/15682063/how-to-generate-manifest-list-of-files-with-their-sizes-and-count-for-a-folder)  
6. dotenv-package Load configuration parameters from .env into environment variables, avattu helmikuuta 10, 2026, [https://www.rdocumentation.org/packages/dotenv/versions/1.0.3/topics/dotenv-package](https://www.rdocumentation.org/packages/dotenv/versions/1.0.3/topics/dotenv-package)  
7. Using dotenv to Hide Sensitive Information in R \- Towards Data Science, avattu helmikuuta 10, 2026, [https://towardsdatascience.com/using-dotenv-to-hide-sensitive-information-in-r-8b878fa72020/](https://towardsdatascience.com/using-dotenv-to-hide-sensitive-information-in-r-8b878fa72020/)  
8. Managing R – RStudio User Guide \- Posit Docs, avattu helmikuuta 10, 2026, [https://docs.posit.co/ide/user/ide/guide/environments/r/managing-r.html](https://docs.posit.co/ide/user/ide/guide/environments/r/managing-r.html)  
9. 7 R Startup \- What They Forgot to Teach You About R, avattu helmikuuta 10, 2026, [https://rstats.wtf/r-startup.html](https://rstats.wtf/r-startup.html)  
10. Creating Data Analysis Pipelines using DuckDB and RStudio \- Fedora Magazine, avattu helmikuuta 10, 2026, [https://fedoramagazine.org/creating-data-analysis-pipelines-using-duckdb-and-rstudio/](https://fedoramagazine.org/creating-data-analysis-pipelines-using-duckdb-and-rstudio/)  
11. Read all worksheets in an Excel workbook into an R list with data.frames \- Stack Overflow, avattu helmikuuta 10, 2026, [https://stackoverflow.com/questions/12945687/read-all-worksheets-in-an-excel-workbook-into-an-r-list-with-data-frames](https://stackoverflow.com/questions/12945687/read-all-worksheets-in-an-excel-workbook-into-an-r-list-with-data-frames)  
12. List all sheets in an excel spreadsheet — excel\_sheets \- readxl, avattu helmikuuta 10, 2026, [https://readxl.tidyverse.org/reference/excel\_sheets.html](https://readxl.tidyverse.org/reference/excel_sheets.html)  
13. Reading in Multiple Excel Sheets with lapply and {readxl} \- R-bloggers, avattu helmikuuta 10, 2026, [https://www.r-bloggers.com/2023/04/reading-in-multiple-excel-sheets-with-lapply-and-readxl/](https://www.r-bloggers.com/2023/04/reading-in-multiple-excel-sheets-with-lapply-and-readxl/)  
14. purrr (and readxl): How to read multiple sheets from multiple Excel files? : r/rstats \- Reddit, avattu helmikuuta 10, 2026, [https://www.reddit.com/r/rstats/comments/aifl86/purrr\_and\_readxl\_how\_to\_read\_multiple\_sheets\_from/](https://www.reddit.com/r/rstats/comments/aifl86/purrr_and_readxl_how_to_read_multiple_sheets_from/)  
15. Feature request: password for protected workbooks · Issue \#84 · tidyverse/readxl \- GitHub, avattu helmikuuta 10, 2026, [https://github.com/tidyverse/readxl/issues/84](https://github.com/tidyverse/readxl/issues/84)  
16. Importing a password protected xlsx file into R \- Stack Overflow, avattu helmikuuta 10, 2026, [https://stackoverflow.com/questions/66524024/importing-a-password-protected-xlsx-file-into-r](https://stackoverflow.com/questions/66524024/importing-a-password-protected-xlsx-file-into-r)  
17. Remove password protection from Excel sheets using R \- "R" you ready?, avattu helmikuuta 10, 2026, [https://ryouready.wordpress.com/2018/05/06/remove-password-protection-from-excel-sheets-using-r/](https://ryouready.wordpress.com/2018/05/06/remove-password-protection-from-excel-sheets-using-r/)  
18. Introduction to matchmaker \- CRAN, avattu helmikuuta 10, 2026, [https://cran.r-project.org/web/packages/matchmaker/vignettes/intro.html](https://cran.r-project.org/web/packages/matchmaker/vignettes/intro.html)  
19. 22 Arrow \- R for Data Science (2e), avattu helmikuuta 10, 2026, [https://r4ds.hadley.nz/arrow.html](https://r4ds.hadley.nz/arrow.html)  
20. Write a dataset — write\_dataset \- Apache Arrow, avattu helmikuuta 10, 2026, [https://arrow.apache.org/docs/r/reference/write\_dataset.html](https://arrow.apache.org/docs/r/reference/write_dataset.html)  
21. Folks, C'mon, Use Parquet \- Appsilon, avattu helmikuuta 10, 2026, [https://www.appsilon.com/post/csv-to-parquet-transition](https://www.appsilon.com/post/csv-to-parquet-transition)  
22. R package to create compact hash digests of R objects \- GitHub, avattu helmikuuta 10, 2026, [https://github.com/eddelbuettel/digest](https://github.com/eddelbuettel/digest)  
23. hash • rlang, avattu helmikuuta 10, 2026, [https://rlang.r-lib.org/reference/hash.html](https://rlang.r-lib.org/reference/hash.html)  
24. Create hash function digests for arbitrary R objects or files \- RDocumentation, avattu helmikuuta 10, 2026, [https://www.rdocumentation.org/packages/digest/versions/0.6.39/topics/digest](https://www.rdocumentation.org/packages/digest/versions/0.6.39/topics/digest)  
25. rstudio/pointblank: Data quality assessment and metadata reporting for data frames and database tables \- GitHub, avattu helmikuuta 10, 2026, [https://github.com/rstudio/pointblank](https://github.com/rstudio/pointblank)  
26. How to use pointblank to understand, validate, and document your data \- R Consortium, avattu helmikuuta 10, 2026, [https://r-consortium.org/webinars/how-to-use-pointblank-to-understand-validate-and-document-your-data.html](https://r-consortium.org/webinars/how-to-use-pointblank-to-understand-validate-and-document-your-data.html)  
27. Do columns in the table (and their types) match a predefined schema? — col\_schema\_match • pointblank \- rstudio.github.io, avattu helmikuuta 10, 2026, [https://rstudio.github.io/pointblank/reference/col\_schema\_match.html](https://rstudio.github.io/pointblank/reference/col_schema_match.html)  
28. 5 Datasets \- Scaling Up With R and Arrow, avattu helmikuuta 10, 2026, [https://arrowrbook.com/datasets.html](https://arrowrbook.com/datasets.html)