# Fear-of-Falling: GLOSSARY

## 0) How to use this glossary (agent instructions)

Tämä sanasto on tarkoitettu sekä kehittäjille että AI-agentille.

* Käytä tätä ensisijaisena lähteenä, kun kohtaat termin, lyhenteen, muuttujan tai polkukäytännön.
* Älä arvaile puuttuvia määritelmiä. Jos termi puuttuu tai on epäselvä, lisää se kohtaan **10) Assumptions / TODO** ja ehdota täsmennystä.
* Esimerkeissä ei koskaan käytetä PII:tä eikä rivitason dataa. Esimerkit ovat aina koontitason (aggregated) artefakteja tai polkuja.
* Kun kirjoitat outputteja tai manifest-merkintöjä, noudata repo-käytäntöjä (mm. `R-scripts/<K_FOLDER>/outputs/<script_label>/` ja `manifest/manifest.csv`).

---

## 1) Terminology conventions (capitalization, abbreviations, how terms are referenced)

### Term

**Definition:** “Term” tarkoittaa tässä dokumentissa yksiselitteisesti määriteltyä käsitettä, muuttujaa, käytäntöä tai artefaktia.
**Context in this repo:** Kaikki termit esitetään samalla rakenteella, jotta agentti voi tarkistaa määritelmän nopeasti.
**Example:** `### QC gate`
**Related terms:** [Acronym](#acronym), [Variable](#variable)

### Acronym

**Definition:** Lyhenne, joka kirjoitetaan yleensä isoilla kirjaimilla (esim. FOF, PII, QC).
**Context in this repo:** Lyhenteet listataan myös kohdassa **9) Acronyms list (A–Z)**.
**Example:** “FOF” viittaa “Fear of Falling” -käsitteeseen.
**Related terms:** [Fear of Falling (FOF)](#fear-of-falling-fof)

### Variable

**Definition:** Data- tai analyysimuuttuja, joka esiintyy datassa tai skripteissä.
**Context in this repo:** Muuttujat kirjoitetaan koodimuodossa (esim. `FOF_status`, `time`) ja niiden “yksi totuus” ankkuroidaan `data_dictionary.csv`:ään.
**Example:** `Composite_Z`
**Related terms:** [Data dictionary](#data-dictionary), [Standardized variable name](#standardized-variable-name)

### Token

**Definition:** Polkujen tai nimeämisen paikkamerkki (placeholder), jota käytetään ohjeissa.
**Context in this repo:** Tokenit kuten `<K_FOLDER>`, `<FILE_TAG>`, `<script_label>` esiintyvät runbook-ohjeissa ja output discipline -käytännöissä.
**Example:** `R-scripts/<K_FOLDER>/outputs/<script_label>/`
**Related terms:** [K_FOLDER](#k_folder), [script_label](#script_label), [Output discipline](#output-discipline)

---

## 2) Core research concepts (neutraali, ei kausaalikieltä)

### Fear of Falling (FOF)

**Definition:** Kaatumisen pelkoon liittyvä ilmiö, jota tarkastellaan tutkimuksessa neutraalisti (esim. yhteys toimintakykyyn tai ajassa tapahtuvaan muutokseen).
**Context in this repo:** Keskeinen käsite, joka näkyy mm. muuttujassa `FOF_status` ja interaktiossa `time * FOF_status`.
**Example:** “Mallissa tarkastellaan `time * FOF_status` -interaktiota `Composite_Z`-muutoksessa.”
**Related terms:** [FOF_status](#fof_status), [time](#time), [Composite_Z](#composite_z)

### Falls (kaatumiset)

**Definition:** Kaatumistapahtumat tai niihin liittyvä taustakonteksti. Tässä repo-kontekstissa termi esiintyy tausta- ja ohjelmakuvauksissa.
**Context in this repo:** Tutkimusasetelma liittyy kaatumisten ehkäisyn ohjelmakontekstiin, mutta analyysikieli pidetään havainnoivana.
**Example:** “Kohortti on osallistunut kaatumisten ehkäisyn ohjelmaan (taustakonteksti).”
**Related terms:** [Observational study](#observational-study), [Cohort](#cohort)

### Physical performance

**Definition:** Fyysisen toimintakyvyn osa-alue tai koonti, jota mitataan testein ja/tai johdetuilla mittareilla.
**Context in this repo:** Tyypillinen päätetulos on `Composite_Z` tai yksittäisiä suorituskykytestejä edustavat muuttujat.
**Example:** `Composite_Z` koontipistemääränä.
**Related terms:** [Composite_Z](#composite_z), [Z-score](#z-score)

### Balance

**Definition:** Tasapainoon liittyvä toimintakyvyn osa-alue.
**Context in this repo:** Voi esiintyä taustakuvauksissa ja mittareissa (esim. staattinen tasapaino).
**Example:** “Tasapainoa kuvaava mittari voidaan standardoida ja liittää koontiin.”
**Related terms:** [Single-leg stance](#single-leg-stance), [Composite_Z](#composite_z)

### Mobility

**Definition:** Liikkumiseen liittyvä toimintakyvyn osa-alue.
**Context in this repo:** Voi liittyä kävelynopeuteen, tuolilta ylösnousuun tai muihin suorituskykymittareihin.
**Example:** “Mobility voi näkyä `gait_speed`-tyyppisenä mittarina.”
**Related terms:** [Gait speed](#gait-speed), [FTSTS](#ftsts)

### Functional capacity

**Definition:** Toimintakyvyn yleisempi käsite, jota voidaan kuvata useilla mittareilla ja koonteina.
**Context in this repo:** Repo käyttää koontia `Composite_Z` (z-komposiitti) päätetuloksena.
**Example:** `Composite_Z` long-formaatissa aikapisteittäin.
**Related terms:** [Composite_Z](#composite_z), [Long format](#long-format)

### Association

**Definition:** Neutraali kuvaus kahden ilmiön välisestä suhteesta ilman kausaalipäätelmää.
**Context in this repo:** Koko repo korostaa havainnoivaa kieltä; vältä “aiheuttaa” -ilmaisuja.
**Example:** “FOF on yhteydessä muutokseen toimintakyvyn koontimittarissa.”
**Related terms:** [No causal language](#no-causal-language), [Observational study](#observational-study)

### No causal language

**Definition:** Kirjoituskäytäntö, jossa vältetään kausaaliväitteitä ja käytetään havainnoivaa, neutraalia ilmaisua.
**Context in this repo:** Vaadittu guardrail: tulkinnat esitetään assosiaatioina ja asetelmaa vastaavina.
**Example:** Hyvä: “yhteydessä”, “liittyy”. Huono: “aiheuttaa”, “johtaa”.
**Related terms:** [Association](#association)

---

## 3) Study design & data concepts (ilman PII:tä)

### Observational study

**Definition:** Tutkimusasetelma, jossa analysoidaan havaintoaineistoa ilman satunnaistettua interventioasetelmaa.
**Context in this repo:** Repo-tekstit ohjaavat neutraaliin analyysikieleen.
**Example:** “Asetelma on kohorttipohjainen pitkittäisanalyysi baseline ja follow-up.”
**Related terms:** [Cohort](#cohort), [Longitudinal](#longitudinal)

### Cohort

**Definition:** Tutkimusjoukko, jota seurataan ajassa.
**Context in this repo:** Aineisto on kohorttipohjainen ja sisältää vähintään kaksi aikapistettä.
**Example:** “Kohortissa analyysi tehdään long-formaatissa `id` ja `time`.”
**Related terms:** [Participant](#participant), [time](#time)

### Participant

**Definition:** Yksikkö (henkilö), johon mittaukset liittyvät.
**Context in this repo:** Osallistujat tunnistetaan vain teknisellä tunnisteella `id` ilman henkilötietoja.
**Example:** `id` esiintyy useilla `time`-arvoilla long-datassa.
**Related terms:** [id](#id), [PII](#pii)

### Unit of analysis

**Definition:** Analyysin perusyksikkö; voi olla henkilö tai havainto (henkilö-aikapiste).
**Context in this repo:** Sekamalli käyttää havaintoyksikkönä yleensä henkilö-aikapiste (long).
**Example:** “Rivi kuvaa yhden `id`-henkilön yhden `time`-aikapisteen havaintoa (ei julkaistavana outputtina).”
**Related terms:** [Long format](#long-format), [Row-level data](#row-level-data)

### Longitudinal

**Definition:** Ajan yli tapahtuva tarkastelu, jossa samaa yksikköä mitataan useamman kerran.
**Context in this repo:** Vähimmäisvaatimus QC:ssa: kaksi aikapistettä.
**Example:** “QC varmistaa, että `time` sisältää kaksi aikapistettä.”
**Related terms:** [QC gate](#qc-gate), [time](#time)

### Baseline

**Definition:** Ensimmäinen mittausajankohta (lähtötaso).
**Context in this repo:** Baseline on yksi `time`-arvoista; tarkka koodaus määritellään `data_dictionary.csv`:ssä.
**Example:** “Baseline voidaan koodata `time = 0` (jos näin on sovittu sanakirjassa).”
**Related terms:** [time](#time), [Data dictionary](#data-dictionary)

### Follow-up

**Definition:** Seurantamittaus (toinen aikapiste).
**Context in this repo:** Follow-up on toinen `time`-arvoista; tulkinta ja koodaus ankkuroidaan sanakirjaan.
**Example:** “Follow-up voidaan koodata `time = 1` (jos näin on sovittu sanakirjassa).”
**Related terms:** [time](#time), [Delta](#delta)

### Timepoint

**Definition:** Yksittäinen mittausajankohta (esim. baseline tai follow-up).
**Context in this repo:** `time` on ydinmuuttuja QC:lle ja mallille.
**Example:** “`time` validoidaan QC:ssa sallittuihin arvoihin.”
**Related terms:** [time](#time), [QC gate](#qc-gate)

---

## 4) Variables & metrics (mittausasteikot, aggregaatit, row-level vs aggregate)

### id

**Definition:** Tekninen, yksilöivä tunniste analyysia varten. Ei sisällä henkilötietoja.
**Context in this repo:** `id` esiintyy long-aineistossa useilla `time`-arvoilla ja on keskeinen QC-tarkistuksissa.
**Example:** Mallin satunnaisintersepti: `(1 | id)` (R).
**Related terms:** [PII](#pii), [QC gate](#qc-gate)

### time

**Definition:** Aikamuuttuja, joka erottaa mittausajankohdat (esim. baseline ja follow-up).
**Context in this repo:** Ydinmuuttuja; koodaus ja sallitut arvot määritellään `data_dictionary.csv`:ssä.
**Example:** `time * FOF_status` -interaktio päätetulosmallissa.
**Related terms:** [Baseline](#baseline), [Follow-up](#follow-up), [Data dictionary](#data-dictionary)

### FOF_status

**Definition:** Kaatumisen pelkoa kuvaava luokittelu (esim. 0/1-indikaattori tai faktori), jonka tarkka “totuusmuoto” ja referenssi määritellään sanakirjassa.
**Context in this repo:** Keskeinen selittäjä ja interaktion osapuoli `time * FOF_status`.
**Example:** Faktori: tasot `Ei FOF` ja `FOF`, referenssi `Ei FOF` (jos näin on määritelty).
**Related terms:** [Fear of Falling (FOF)](#fear-of-falling-fof), [Data dictionary](#data-dictionary)

### Composite_Z

**Definition:** Fyysisen toimintakyvyn koontipistemäärä (z-komposiitti), jota käytetään päätetuloksena long-formaatissa.
**Context in this repo:** Sekamallissa outcome on aikapisteittäin (`Composite_Z` per `time`).
**Example:** `Composite_Z` long-formaatissa, ei pelkkänä delta-muuttujana.
**Related terms:** [Z-score](#z-score), [Long format](#long-format)

### age

**Definition:** Ikämuuttuja; mittayksikkö tulee määrittää sanakirjassa (tyypillisesti vuosina).
**Context in this repo:** Vähintään yksi mallin kovariaate; nimeämisvariantit standardoidaan.
**Example:** Standardoitu nimi `age` (ei `Age`).
**Related terms:** [Standardized variable name](#standardized-variable-name), [Data dictionary](#data-dictionary)

### composite_z0

**Definition:** Toimintakykykomposiitti Z baseline-aikapisteessä (wide-format helper variable).
**Context in this repo:** Käytetään vain wide-format datassa; lähde `ToimintaKykySummary0`. Long-formaatissa vastaa `Composite_Z` kun `time = baseline`.
**Example:** Wide-format: `composite_z0` (lowercase). Lähdesarake: `ToimintaKykySummary0`.
**Related terms:** [Composite_Z](#composite_z), [Composite_Z0](#composite_z0), [ToimintaKykySummary0](#toimintakykysummary0)

### composite_z12

**Definition:** Toimintakykykomposiitti Z 12 kk follow-up-aikapisteessä (wide-format helper variable).
**Context in this repo:** Käytetään vain wide-format datassa; lähde `ToimintaKykySummary2`. Long-formaatissa vastaa `Composite_Z` kun `time = m12`.
**Example:** Wide-format: `composite_z12` (lowercase). Lähdesarake: `ToimintaKykySummary2`.
**Related terms:** [Composite_Z](#composite_z), [Composite_Z2](#composite_z2), [ToimintaKykySummary2](#toimintakykysummary2)

### Composite_Z0

**Definition:** Toimintakykykomposiitti Z baseline (wide-format, uppercase variant).
**Context in this repo:** Uppercase-nimeäminen lähdesarakkeesta; vastaa `composite_z0` (lowercase canonical form).
**Example:** Data dictionary mainitsee `Composite_Z0` = `ToimintaKykySummary0`.
**Related terms:** [composite_z0](#composite_z0), [Composite_Z](#composite_z), [Wide format](#wide-format)

### Composite_Z2

**Definition:** Toimintakykykomposiitti Z 12 kk (wide-format, uppercase variant).
**Context in this repo:** Uppercase-nimeäminen lähdesarakkeesta; vastaa `composite_z12` (lowercase canonical form).
**Example:** Data dictionary mainitsee `Composite_Z2` = `ToimintaKykySummary2`.
**Related terms:** [composite_z12](#composite_z12), [Composite_Z](#composite_z), [Wide format](#wide-format)

### delta_composite_z

**Definition:** Composite_Z muutos baseline -> 12 kk (lowercase canonical).
**Context in this repo:** Johdettu muuttuja: `delta_composite_z = composite_z12 - composite_z0`. Käytetään vain jos delta-analyysi on relevantti.
**Example:** Sallittu vain koontitason raportoinnissa, ei rivitason outputtina.
**Related terms:** [Delta](#delta), [Delta_Composite_Z](#delta_composite_z), [Derived variable](#derived-variable)

### Delta_Composite_Z

**Definition:** Composite_Z muutos baseline -> 12 kk (uppercase variant).
**Context in this repo:** Uppercase-nimeäminen; vastaa `delta_composite_z` (lowercase canonical form).
**Example:** Data dictionary mainitsee `Delta_Composite_Z` = `Composite_Z2 - Composite_Z0`.
**Related terms:** [delta_composite_z](#delta_composite_z), [Delta](#delta), [Wide format](#wide-format)

### sex

**Definition:** Sukupuolta kuvaava muuttuja; koodaus (0/1 tai merkkijono) tulee ankkuroida eksplisiittisesti sanakirjaan.
**Context in this repo:** Vähintään yksi mallin kovariaate; standardointi vaaditaan.
**Example:** “`sex` mapping: 0 = X, 1 = Y” (tarkka mapping määritellään sanakirjassa).
**Related terms:** [Data dictionary](#data-dictionary), [Mapping](#mapping)

### BMI

**Definition:** Painoindeksi; yksikkö ja laskentatapa tulee ankkuroida `data_dictionary.csv`:ään.
**Context in this repo:** Vähintään yksi mallin kovariaate; standardointi ja dokumentointi vaaditaan.
**Example:** Standardoitu nimi `BMI` (tai sovittu muoto) analyysissa.
**Related terms:** [Data dictionary](#data-dictionary)

### SRH

**Definition:** Self-Rated Health (oma arvioitu terveys); ordinaalinen tai kategoriaalinen mittari.
**Context in this repo:** Valinnainen kovariaate; asteikko ja suunta (higher=better?) tulee määrittää `data_dictionary.csv`:ssä.
**Example:** "SRH-asteikko määritellään sanakirjassa (esim. 1-5, TODO: confirm direction)."
**Related terms:** [Data dictionary](#data-dictionary), [Mapping](#mapping)

### Delta

**Definition:** Muutos kahden aikapisteen välillä, tyypillisesti follow-up miinus baseline.
**Context in this repo:** Jos deltaa käytetään, sen lähdesarakkeet ja aikapisteiden tulkinta tulee dokumentoida sanakirjaan.
**Example:** “delta = follow-up - baseline” (vain koontitasolla raportoiden).
**Related terms:** [Baseline](#baseline), [Follow-up](#follow-up), [Derived variable](#derived-variable)

### Z-score

**Definition:** Standardoitu mitta, jossa havainto suhteutetaan jakaumaan (esim. keskiarvo ja keskihajonta).
**Context in this repo:** K1/K2-putkissa esiintyy z-score -muunnoksia ja pivotointeja.
**Example:** “Z-score change tables” outputina (koontitason taulukko).
**Related terms:** [Composite_Z](#composite_z), [Aggregated output](#aggregated-output)

### Derived variable

**Definition:** Muuttuja, joka lasketaan muista muuttujista (kaava ja lähteet dokumentoitava).
**Context in this repo:** Johdannaiset (kuten delta) vaativat sanakirjaan kaavan ja lähdesarakkeet.
**Example:** “`Composite_Z` derivation: komponentit ja standardointi” (metatason dokumentaatio).
**Related terms:** [Data dictionary](#data-dictionary), [Delta](#delta)


### Wide format

**Definition:** Datarakenne, jossa jokainen henkilö on yksi rivi ja eri aikapisteet ovat eri sarakkeita.
**Context in this repo:** Wide-format muuttujat kuten `composite_z0`, `composite_z12` kuvaavat aikapisteitä sarakkeina. Konvertointi long-muotoon voi olla tarpeen mixed model -analyyseissä.
**Example:** Wide: `id | composite_z0 | composite_z12`. Long: `id | time | Composite_Z`.
**Related terms:** [Long format](#long-format), [composite_z0](#composite_z0), [composite_z12](#composite_z12)

### Long format

**Definition:** Datarakenne, jossa jokainen havainto (henkilö-aikapiste) on oma rivi.
**Context in this repo:** Long-format on ensisijainen mixed model -analyyseihin. Ydinmuuttujat: `id`, `time`, `Composite_Z`.
**Example:** Long: `id | time | Composite_Z` (useita rivejä per id).
**Related terms:** [Wide format](#wide-format), [Longitudinal](#longitudinal), [time](#time)
### Row-level data

**Definition:** Aineisto, jossa jokainen rivi kuvaa yksittäisen yksikön havaintoa (esim. henkilö-aikapiste).
**Context in this repo:** Rivitaso on kielletty GitHub-outputeissa; sitä käsitellään vain paikallisesti analyysissa.
**Example:** Huono output: “long_table.csv” jossa yksi rivi per `id` ja `time`.
**Related terms:** [PII](#pii), [Aggregated output](#aggregated-output)

### Aggregated output

**Definition:** Koontitason tulos (esim. lukumäärät, prosentit, estimaatit, luottamusvälit), josta ei voi palauttaa yksilörivejä.
**Context in this repo:** Ainoa sallittu analyysioutput GitHubiin ja manifestiin.
**Example:** `fixed_effects.csv` jossa on malliestimaatit ja 95 % LV.
**Related terms:** [Manifest](#manifest), [Outputs](#outputs)

---

## 5) Data governance terms (PII, de-identification, pseudonymization, access level, allowed outputs)

### PII

**Definition:** Henkilötiedot ja tunnisteet, joilla yksilö voidaan tunnistaa suoraan tai epäsuorasti.
**Context in this repo:** PII on kielletty outputeissa ja commiteissa. `id` ei ole PII vain, jos se on tekninen eikä palautettavissa henkilöön repo-ympäristön ulkopuolella.
**Example:** Kielletty: nimet, syntymäajat, osoitteet, yksilölistat.
**Related terms:** [Row-level data](#row-level-data), [De-identification](#de-identification)

### De-identification

**Definition:** Prosessi, jossa suorat tunnisteet poistetaan ja riskit minimoidaan.
**Context in this repo:** Outputtien tulee olla koontitasoisia; de-identification ei tee rivitasosta automaattisesti sallittua.
**Example:** Hyvä: mallitaulukko ilman yksilörivejä.
**Related terms:** [Pseudonymization](#pseudonymization), [Aggregated output](#aggregated-output)

### Pseudonymization

**Definition:** Tunnisteiden korvaaminen pseudonyymeillä, mutta linkitys voi olla olemassa.
**Context in this repo:** Pseudonymisoitu rivitaso on edelleen kielletty GitHub-outputeissa.
**Example:** Kielletty: “pseudonymized_long.csv” jossa rivi per `id`.
**Related terms:** [PII](#pii), [Row-level data](#row-level-data)

### Access level

**Definition:** Käyttöoikeustaso aineistoon ja johdettuihin aineistoihin.
**Context in this repo:** Raakadata on read-only ja käsitellään paikallisesti; GitHubiin päätyy vain koontitason artefakteja.
**Example:** “Raw data read-only; muunnokset vain skripteillä.”
**Related terms:** [Raw data](#raw-data), [Local vs GitHub](#local-vs-github)

### Raw data

**Definition:** Alkuperäinen aineisto tai sen suorat poiminnat, joita ei saa muokata käsin.
**Context in this repo:** Ei koskaan committiin eikä repo-root output-kansioihin.
**Example:** Kielletty: `data/external/*.csv` GitHubissa.
**Related terms:** [Data controller](#data-controller), [Local vs GitHub](#local-vs-github)

### Data controller

**Definition:** Tahot, joilla on vastuu aineiston hallinnasta ja luovutuksesta.
**Context in this repo:** Repo dokumentoi governance-periaatteita; agentti ei ohjeista raakadataa ulkopuolisiin palveluihin.
**Example:** “Aineistopoiminnat säilytetään vain hyväksytyissä ympäristöissä.”
**Related terms:** [Access level](#access-level)

### Allowed outputs

**Definition:** Sallitut outputit ovat koontitasoisia, auditointikelpoisia ja tietosuojan mukaisia.
**Context in this repo:** Output discipline ja manifest-käytännöt rajaavat, mitä tuotetaan ja mihin.
**Example:** `R-scripts/K11/outputs/K11/fixed_effects.csv`
**Related terms:** [Output discipline](#output-discipline), [Manifest](#manifest)

### QC-safe reporting

**Definition:** QC-raportointi, joka sisältää vain aggregaatteja (countit, jakaumat) ilman yksilölistoja.
**Context in this repo:** QC-artefaktit eivät saa sisältää “poikkeavat id:t” -listoja tai rivitasoa.
**Example:** “Puuttuvien havaintojen määrä per muuttuja” (taulukko).
**Related terms:** [QC gate](#qc-gate), [Aggregated output](#aggregated-output)

---

## 6) Repo artifacts & workflow (scripts, configs, renv/requirements, seeds, logging)

### R-scripts

**Definition:** R-ajettavat skriptit, jotka on organisoitu K-kansioihin (`R-scripts/Kxx/`).
**Context in this repo:** Suuri osa pipelineista ajetaan `Rscript R-scripts/<K_FOLDER>/<FILE_TAG>.R` -muodossa.
**Example:** `Rscript R-scripts/K1/K1.7.main.R`
**Related terms:** [Kxx](#kxx), [K_FOLDER](#k_folder), [FILE_TAG](#file_tag)

### Kxx

**Definition:** K-sarjan skriptikokonaisuuden tunniste (esim. K1, K11, K12).
**Context in this repo:** Jokainen `R-scripts/`-alikansio nimetään SCRIPT_ID:n mukaan.
**Example:** `R-scripts/K11/`
**Related terms:** [SCRIPT_ID](#script_id), [Pipeline](#pipeline)

### SCRIPT_ID

**Definition:** Skriptikansion tunniste, sama kuin K-kansion nimi (esim. `K11`).
**Context in this repo:** Käytetään poluissa ja manifestissa `script`-kentässä.
**Example:** `script = "K11"` manifestissa.
**Related terms:** [Manifest](#manifest), [script_label](#script_label)

### Pipeline

**Definition:** Useamman skriptin sarja, joka tuottaa määriteltyjä koontitason artefakteja.
**Context in this repo:** README kuvaa pipelineja (esim. K1–K4) tarkoitus, input, output, ajokomento.
**Example:** “K1: Z-score change analysis”
**Related terms:** [Run command](#run-command), [Outputs](#outputs)

### Run command

**Definition:** Komento, jolla skripti tai pipeline ajetaan.
**Context in this repo:** Usein `Rscript ...` repojuuresta.
**Example:** `Rscript R-scripts/K11/K11.R`
**Related terms:** [VS Code](#vs-code), [Working directory](#working-directory)

### VS Code

**Definition:** Kehitysympäristö, jota käytetään skriptien ajamiseen ja repo-työskentelyyn.
**Context in this repo:** Ajot tehdään usein terminaalista repojuuresta, jolloin polut ja manifest toimivat johdonmukaisesti.
**Example:** “Aja komennot VS Code terminalissa repojuuresta.”
**Related terms:** [Working directory](#working-directory), [here::here()](#herehere)

### Working directory

**Definition:** Hakemisto, josta komento ajetaan (vaikuttaa suhteellisiin polkuihin).
**Context in this repo:** Suositus: aja repojuuresta, jotta `manifest/` ja `R-scripts/` löytyvät odotetusti.
**Example:** `git clone ...` ja sitten `Rscript ...` repojuuresta.
**Related terms:** [Paths](#paths), [Manifest](#manifest)

### Paths

**Definition:** Hakemistorakenteet ja polut, jotka tulee pitää toistettavina ja suhteellisina.
**Context in this repo:** Polut kirjataan ohjeissa ja output discipline -käytännöissä.
**Example:** `R-scripts/<K_FOLDER>/outputs/<script_label>/`
**Related terms:** [Output discipline](#output-discipline), [init_paths()](#init_paths)

### here::here()

**Definition:** R-funktio, jolla muodostetaan toistettavia polkuja projektin juureen.
**Context in this repo:** README viittaa toistettaviin polkuihin yhdessä `init_paths()`-logiikan kanssa.
**Example:** `here::here("manifest", "manifest.csv")`
**Related terms:** [init_paths()](#init_paths), [Reproducible paths](#reproducible-paths)

### init_paths()

**Definition:** Repo-kohtainen polkujen alustuskäytäntö (abstraktio), joka auttaa löytämään oikeat kansiot.
**Context in this repo:** Käytetään yhdessä `here::here()`-ajattelun kanssa, jotta skriptit eivät kovakoodaa ympäristöpolkuja.
**Example:** “`init_paths()` palauttaa kanoniset polut outputeille.”
**Related terms:** [Paths](#paths), [Reproducible paths](#reproducible-paths)

### Logging

**Definition:** Tekniset lokit ajon aikana.
**Context in this repo:** Lokit ovat sallittuja vain, jos ne eivät sisällä data-arvoja tai tunnisteita; mieluummin `meta/` tai `manifest/`-tiedostoihin.
**Example:** `meta/run_log_K11.txt` ilman rivitason dataa.
**Related terms:** [PII](#pii), [Local vs GitHub](#local-vs-github)

### Seed

**Definition:** Satunnaislukugeneraattorin siemen, jota käytetään vain tarvittaessa (esim. bootstrap).
**Context in this repo:** Seed-käytäntö: aseta vain satunnaisuutta sisältäviin vaiheisiin.
**Example:** `set.seed(20251124)` (vain tarvittaessa).
**Related terms:** [Reproducibility](#reproducibility), [Bootstrap](#bootstrap)

---

## 7) Output & reproducibility vocabulary (manifest, run_id, timestamping, derived dataset, QC gate)

### Output discipline

**Definition:** Repo-käytäntö, jossa kaikki analyysi-artefaktit tallennetaan skriptikohtaiseen output-polkuun ja kirjataan manifestiin.
**Context in this repo:** Kanoninen output-polku: `R-scripts/<K_FOLDER>/outputs/<script_label>/`.
**Example:** `R-scripts/K5/outputs/K5.1/`
**Related terms:** [Outputs](#outputs), [Manifest](#manifest), [script_label](#script_label)

### Outputs

**Definition:** Raportointivalmiit koontitason taulukot, kuvat tai metatiedot, joita skriptit tuottavat.
**Context in this repo:** Repo-root `outputs/` on legacy; käytä aina skriptikohtaista output-polkuja.
**Example:** `R-scripts/K11/outputs/K11/fixed_effects.csv`
**Related terms:** [Output discipline](#output-discipline), [Legacy outputs](#legacy-outputs)

### Legacy outputs

**Definition:** Repojuuren `outputs/`-kansio, jota ei käytetä ensisijaisena analyysioutput-paikkana.
**Context in this repo:** Pidetään rajadokumenttina tai minimaalisten policy-artefaktien paikkana.
**Example:** “Vältä: repo-root `outputs/` (legacy/deprecated).”
**Related terms:** [Outputs](#outputs), [Allowed outputs](#allowed-outputs)

### Manifest

**Definition:** Kirjanpito tuotetuista artefakteista, 1 rivi per artefakti.
**Context in this repo:** `manifest/manifest.csv` sisältää pakolliset sarakkeet `file`, `date`, `script`, `git_hash`.
**Example:** `file = "R-scripts/K11/outputs/K11/fixed_effects.csv"`
**Related terms:** [Manifest entry](#manifest-entry), [git_hash](#git_hash)

### manifest/manifest.csv

**Definition:** CSV-tiedosto, johon kaikki outputit kirjataan.
**Context in this repo:** Vähimmäisskeema: `file,date,script,git_hash`.
**Example:** `manifest/manifest.csv`
**Related terms:** [Manifest](#manifest), [Manifest entry](#manifest-entry)

### Manifest entry

**Definition:** Yksi manifest-rivi, joka kuvaa yhtä output-tiedostoa.
**Context in this repo:** Ei niputusta; jokainen tiedosto saa oman rivin.
**Example:** `script = "K11"` ja `git_hash = "1a2b3c4"` (jos saatavilla).
**Related terms:** [Manifest](#manifest), [Timestamp](#timestamp)

### Timestamp

**Definition:** Aikaleima, joka kertoo milloin artefakti tuotettiin.
**Context in this repo:** Manifestin `date`-kenttä kirjataan ajon aikana (esim. `Sys.time()`).
**Example:** `date = 2025-12-30T15:00:00+02:00`
**Related terms:** [Manifest entry](#manifest-entry)

### git_hash

**Definition:** Git commit -tunniste, jolla ajo voidaan sitoa repo-versioon.
**Context in this repo:** Manifestiin kirjataan lyhyt hash, jos saatavilla; muuten `NA`.
**Example:** `git rev-parse --short HEAD`
**Related terms:** [Manifest](#manifest), [Reproducibility](#reproducibility)

### Reproducibility

**Definition:** Kyky toistaa analyysi samalla koodilla ja ympäristöllä.
**Context in this repo:** Ympäristö ankkuroidaan `renv.lock` ja manifest sitoo artefaktit skriptiin ja git_hashiin.
**Example:** “Aja `renv::restore()` ennen mallinnusta.”
**Related terms:** [renv](#renv), [renv.lock](#renvlock)

### renv

**Definition:** R-ympäristön hallintatyökalu, jolla paketit ja versiot lukitaan.
**Context in this repo:** Käytetään projektin toistettavuuden varmistamiseen.
**Example:** `renv::restore()`
**Related terms:** [renv.lock](#renvlock), [Reproducibility](#reproducibility)

### renv.lock

**Definition:** Tiedosto, joka määrittää lukitut R-pakettiversiot.
**Context in this repo:** Ajon R-version ja pakettiversiot tulee olla yhteensopivia tämän kanssa.
**Example:** `renv.lock` repojuuressa.
**Related terms:** [renv](#renv), [Reproducibility](#reproducibility)

### QC gate

**Definition:** Pakollinen tarkistusvaihe ennen mallinnusta (data-laatu, aikapisteet, koodaukset).
**Context in this repo:** Mallinnusta ei tehdä ennen kuin QC-kriteerit ovat läpäisty (viittaa QC_CHECKLIST).
**Example:** “Varmista 2 aikapistettä ja koodaukset ennen malliajoa.”
**Related terms:** [QC passed](#qc-passed), [QC checklist](#qc-checklist)

### QC passed

**Definition:** Tila, jossa aineisto täyttää QC-kriteerit ja mallinnus on sallittua.
**Context in this repo:** “QC passed” on ehto ennen päätetulosmallia ja ennen julkaistavia outputteja.
**Example:** “QC-raportti: lukumäärät ja jakaumat, ei yksilölistoja.”
**Related terms:** [QC gate](#qc-gate), [QC-safe reporting](#qc-safe-reporting)

### QC checklist

**Definition:** Dokumentti, joka määrittää QC-tarkistukset ja portit.
**Context in this repo:** `QC_CHECKLIST.md` on ensisijainen lähde tarkistuksille.
**Example:** “QC: id + time -uniikkius, puuttuvat, koodaukset.”
**Related terms:** [QC gate](#qc-gate), [Row-level data](#row-level-data)

### Data dictionary

**Definition:** Metatason sanakirja muuttujille, koodauksille ja johdannaisille.
**Context in this repo:** `data_dictionary.csv` on “yksi totuus” muuttujien merkityksille ja standardoinnille.
**Example:** “`FOF_status` truth-muoto ja referenssitaso määritellään sanakirjassa.”
**Related terms:** [Standardized variable name](#standardized-variable-name), [Mapping](#mapping)

### Standardized variable name

**Definition:** Sovittu kanoninen muuttujanimi analyysissa (esim. `age`, `sex`, `BMI`).
**Context in this repo:** Nimivariantit (Age vs age) standardoidaan ja kirjataan sanakirjaan.
**Example:** Käytä `age`, ei `Age`.
**Related terms:** [Data dictionary](#data-dictionary), [Mapping](#mapping)

### Mapping

**Definition:** Eksplisiittinen sääntö, jolla lähdedatan variantit muunnetaan standardiin muotoon.
**Context in this repo:** Tarvitaan erityisesti koodauksille (esim. `sex`, `FOF_status`) ja aikapisteille (`time`).
**Example:** “`sex` mapping dokumentoidaan sanakirjaan.”
**Related terms:** [Standardized variable name](#standardized-variable-name), [Data dictionary](#data-dictionary)

### Source columns

**Definition:** Alkuperäiset datassa esiintyvät sarakkeet, jotka standardoidaan kanonisiin muuttujanimiin.
**Context in this repo:** `VARIABLE_STANDARDIZATION.csv` määrittää mappaukset lähdesarakkeista kanonisiin nimiin.
**Example:** `ToimintaKykySummary0` -> `composite_z0`, `kaatumisenpelkoOn` -> `FOF_status`
**Related terms:** [Mapping](#mapping), [Standardized variable name](#standardized-variable-name)

### ToimintaKykySummary0

**Definition:** Lähdesarake baseline-toimintakykykompositille wide-format datassa.
**Context in this repo:** Standardoidaan nimeksi `composite_z0` (tai `Composite_Z0`). Lähde: alkuperäinen data-tiedosto.
**Example:** `VARIABLE_STANDARDIZATION.csv`: `composite_z0,ToimintaKykySummary0,10,rename_to_canonical`
**Related terms:** [composite_z0](#composite_z0), [Source columns](#source-columns), [Mapping](#mapping)

### ToimintaKykySummary2

**Definition:** Lähdesarake 12 kk follow-up -toimintakykykompositille wide-format datassa.
**Context in this repo:** Standardoidaan nimeksi `composite_z12` (tai `Composite_Z2`). Lähde: alkuperäinen data-tiedosto.
**Example:** `VARIABLE_STANDARDIZATION.csv`: `composite_z12,ToimintaKykySummary2,10,rename_to_canonical`
**Related terms:** [composite_z12](#composite_z12), [Source columns](#source-columns), [Mapping](#mapping)

### kaatumisenpelkoOn

**Definition:** Lähdesarake FOF_status-muuttujalle alkuperäisessä datassa.
**Context in this repo:** Standardoidaan nimeksi `FOF_status`. Alkuperäinen suomenkielinen sarake.
**Example:** `VARIABLE_STANDARDIZATION.csv`: `FOF_status,kaatumisenpelkoOn,10,rename_to_canonical`
**Related terms:** [FOF_status](#fof_status), [Source columns](#source-columns), [Mapping](#mapping)

### Derived dataset

**Definition:** Raakadatasta skriptein johdettu väliaikainen aineisto.
**Context in this repo:** Johdettu aineisto voi olla paikallinen, mutta sitä ei commitoida GitHubiin, ellei se ole täysin koontitasoinen ja hyväksytty.
**Example:** Sallittu vain paikallisesti: väliaikainen long-data.
**Related terms:** [Raw data](#raw-data), [Local vs GitHub](#local-vs-github)

### Local vs GitHub

**Definition:** Erottelu siitä, mitä tehdään paikallisesti ja mitä saa päätyä repossa versionhallintaan.
**Context in this repo:** Rivitaso ja raakadata vain paikallisesti; GitHubiin vain koontitason outputit ja metadokumentaatio.
**Example:** “Paikallisesti: data käsittely. GitHub: koontitaulukot + manifest.”
**Related terms:** [Row-level data](#row-level-data), [Aggregated output](#aggregated-output)

---

## 8) File/path naming glossary (Kxx, script_label, run_id, tokenit)

### K_FOLDER

**Definition:** K-kansion nimi `R-scripts/`-hakemistossa (esim. `K11`).
**Context in this repo:** Käytetään polkujen placeholderina runbook-ohjeissa.
**Example:** `R-scripts/K11/`
**Related terms:** [Kxx](#kxx), [FILE_TAG](#file_tag)

### FILE_TAG

**Definition:** Tiedostonimen kuvaava osa ilman `.R`-päätettä.
**Context in this repo:** Määritellään README:ssa ja käytetään ajokomentoihin.
**Example:** `K5.1.V4_Moderation_analysis` (file_tag)
**Related terms:** [file_tag](#file_tag), [script_label](#script_label)

### file_tag

**Definition:** Sama käsite kuin `FILE_TAG`, mutta sanastossa käytetään pientä muotoa kuvaamaan tiedoston runkoa.
**Context in this repo:** file_tag voi sisältää versionoinnin `.V4` osana.
**Example:** `K11.R` -> file_tag `K11`
**Related terms:** [script_label](#script_label), [Version tag](#version-tag)

### script_label

**Definition:** Kanoninen tunniste skriptille, johdettu tiedoston nimestä: jos versioitu, prefix ennen `.V`, muuten koko file_tag.
**Context in this repo:** Output-hakemisto ja manifest-merkinnät viittaavat `script_label`:iin.
**Example:** `K5.1.V4_*.R` -> `script_label = K5.1`
**Related terms:** [Output discipline](#output-discipline), [Version tag](#version-tag)

### Version tag

**Definition:** Tiedostonimessä oleva versio-osa (esim. `.V4`), jota käytetään kehityksen vaiheistamiseen.
**Context in this repo:** `script_label` katkaisee versionoinnin pois output-kansion nimestä.
**Example:** `K5.1.V4_Moderation_analysis.R` sisältää version tagin `V4`.
**Related terms:** [script_label](#script_label), [file_tag](#file_tag)

### run_id

**Definition:** Yksilöivä ajotunniste, jolla erotetaan ajokerrat (esim. aikaleiman tai hashin perusteella).
**Context in this repo:** Ei ole pakollinen peruskäytännössä, mutta voidaan ottaa käyttöön, jos tarvitaan useiden ajojen rinnakkaistallennus.
**Example:** `R-scripts/K11/outputs/K11/run_20251230T1500/` (vain jos käytäntö lisätään).
**Related terms:** [Timestamp](#timestamp), [Outputs](#outputs)

### Output path

**Definition:** Kanoninen polku, johon skriptin artefaktit tallennetaan.
**Context in this repo:** `R-scripts/<K_FOLDER>/outputs/<script_label>/`
**Example:** `R-scripts/K12/outputs/K12/`
**Related terms:** [Output discipline](#output-discipline), [Legacy outputs](#legacy-outputs)

### manifest/

**Definition:** Hakemisto, jossa ylläpidetään manifestia ja mahdollisia ajon metatiedostoja.
**Context in this repo:** Luodaan tarvittaessa; sisältää `manifest.csv`.
**Example:** `manifest/manifest.csv`
**Related terms:** [Manifest](#manifest), [Reproducibility](#reproducibility)

---

## 9) Acronyms list (A–Z)

* **ANCOVA**: Kovarianssianalyysi (käyttötapa riippuu skriptistä ja analyysista)
* **BMI**: Body Mass Index (painoindeksi)
* **CI**: Confidence Interval (luottamusväli)
* **CSV**: Comma-Separated Values
* **EHR**: Electronic Health Record (taustakonteksti, jos käytössä)
* **FOF**: Fear of Falling
* **FTSTS**: Five Times Sit-to-Stand (jos käytössä mittarina)
* **IDE**: Integrated Development Environment
* **LV**: Luottamusväli (Finnish shorthand)
* **PII**: Personally Identifiable Information
* **QC**: Quality Control
* **RNG**: Random Number Generator
* **SE**: Standard Error
* **VS Code**: Visual Studio Code

---

## 10) Assumptions / TODO

* **run_id**: Repo ei vaadi run_id:tä perusmanifestissa; termi on lisätty varauksella, jos halutaan erottaa useita ajoja. Päätä ja dokumentoi, jos otetaan käyttöön.
* **Mittarikohtaiset termit (FTSTS, gait speed, handgrip, single-leg stance)**: Nämä ovat yleisiä toimintakykymittareita, mutta niiden tarkka käyttö tässä repossa tulee varmistaa `data_dictionary.csv`:stä ja/tai skriptien muuttujalistoista.
* **Data dictionary polku**: Termi `data_dictionary.csv` on määritelty sanastossa repo-ohjeiden mukaisesti, mutta tarkka sijainti ja sarakerakenne kannattaa ankkuroida erillisellä “schema” -osiolla, jos agentti tekee automaattista validointia.
* **sex mapping**: Koodaus on tarkoituksella jätetty TODO-tilaan; lisää eksplisiittinen mapping sanakirjaan.
* **BMI unit**: Yksikkö ja laskenta tulee vahvistaa sanakirjasta tai mittaridokumentista.

---

Notes

* Repo-lähteisiin perustuvat termit ja määritelmät: `script_label`, `file_tag`, `K_FOLDER`, output-polku, `manifest/manifest.csv` ja sen pakolliset sarakkeet, output discipline, QC gate -ajatus, renv ja `renv.lock`, sekä ydinmuuttujat `id`, `time`, `FOF_status`, `Composite_Z`, `age`, `sex`, `BMI`, `SRH`; wide-format muuttujat `composite_z0`, `composite_z12` ja niiden lähteet `ToimintaKykySummary0/2`, `kaatumisenpelkoOn`.
* Oletuksiin perustuvat (yleistermit, jotka kannattaa varmistaa repo-datasta): mittarikohtaiset termit kuten gait speed, handgrip, FTSTS ja single-leg stance; lisäksi run_id on lisätty optiona.
* TODO-kohdat, jotka parantavat agentin varmuutta: (1) `data_dictionary.csv` sijainti ja schema, (2) `sex` ja `FOF_status` “truth” -muoto ja referenssitaso, (3) `time`-koodauksen sallitut arvot, (4) päätös käytetäänkö run_id-rakennetta outputeissa.
