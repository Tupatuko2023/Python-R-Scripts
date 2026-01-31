# RUNBOOK_SECURE_EXECUTION

## Yleiskuva ja periaatteet

Osa 1: Yleiskuva ja periaatteet

Tässä repossa ajetaan Aim 2 -analyysi paneeliaineistolla (henkilö–jakso, person–period), jossa altiste on lähtötilanteen Fear of Falling (FOF, binäärinen) ja vasteina ovat palvelukäytön lukumäärämuuttujat (count) sekä kustannukset (cost). Analyyttinen ydin noudattaa analyysisuunnitelmaa (ANALYSIS_PLAN.md):

- Count-vasteet mallinnetaan Negative Binomial -GLM:llä käyttäen person-time -offsetia `offset(log(person_time))`, jolloin tulokset liittyvät rate/PY -tasoon.
- Kustannukset mallinnetaan Gamma-GLM:llä log-linkillä positiivisissa kustannuksissa (cost > 0) ja samalla offsetilla `offset(log(person_time))`.
- Ensisijaiset raportoitavat vaikutusmitat ovat IRR (count, `exp(beta_FOF)`) ja mean ratio (cost, `exp(alpha_FOF)`) sekä recycled prediction -tulokset: ennustettu rate/PY tai €/PY FOF=1 vs FOF=0, niiden ratio ja absoluuttinen erotus.
- Epävarmuus recycled prediction -estimaateille tuotetaan cluster bootstrap -menetelmällä (resample id-tasolla).
- Jos kustannuksissa on merkittävä nollaosuus, käytetään herkkyysanalyysinä two-part/hurdle -mallia (logit any-cost + Gamma positive-cost), ja raportoidaan unconditional €/PY analyysisuunnitelman hengessä.

Tietoturvaperiaatteet (Option B, CLAUDE.md ja README.md):

- Raakadata tai henkilötason rekisteridata ei ole tässä Git-repossa. Kaikki datan luku tapahtuu vain `DATA_ROOT`-polun kautta (air-gapped/restricted-ympäristössä).
- Tulosteet ovat “safe-by-default”: vain aggregoidut yhteenvedot ja taulukot, ei rivitason tuloksia, eikä mitään tunnisteellista (esim. henkilöiden id-listoja, tapahtumakohtaisia rivejä).
- Lokitus ja audit trail ovat osa analyysiä: jokaisesta ajosta jää ajopäiväkirja (stdout/stderr), R-session tiedot ja käytetty commit-versio.
- Datan ulosvienti on kielletty: älä siirrä raakadataa tai rivitason tuloksia ympäristön ulkopuolelle. Julkaistava export tehdään vain erikseen määritellyistä “export safe” -tiedostoista ja tarvittaessa pienisoluja suppressioiden.

## Esivaatimukset ja ympäristö

Osa 2: Esivaatimukset ja ympäristö

R-versio ja paketit:

- Suositus: yhtenäinen, organisaation hyväksymä R 4.x -asennus (sama kaikille ajoille).
- Repo käyttää `renv`-pakettia ympäristön lukitukseen ja palautukseen (00_setup_env.R). Turvallisessa ympäristössä pakettien asentaminen onnistuu vain offline-mallilla, esimerkiksi:
  - organisaation sisäinen CRAN-peili, joka on saatavilla air-gapped-verkossa, tai
  - ennalta stagedatut pakettitiedostot (tar.gz / binaarit) hyväksytyssä sisäisessä jaossa, tai
  - valmiiksi esiasennetut paketit ja renv-cache.

Työhakemisto ja kansiorakenne:

- Aja komennot repon juuresta (root), koska skriptit viittaavat suhteellisiin polkuihin kuten `data/VARIABLE_STANDARDIZATION.csv`.
- Varmista, että seuraavat kansiot ovat olemassa (tai luodaan ajon yhteydessä):
  - `outputs/` aggregoiduille tuloksille (ei rivitasoa)
  - `logs/` ajolokeille (stdout/stderr, sessionInfo, parametrit)
  - `outputs/archive/<RUN_ID>/` ajokohtaiselle versioinnille ja audit trail -kopioille

Esimerkkikomento kansioiden luontiin (komentorivi):

```bash
mkdir -p logs outputs outputs/archive
```

Huomio turvallisuus:

- Älä tallenna raakadataa repon alle. Paneeliaineisto sijaitsee vain `DATA_ROOT/derived/aim2_panel.csv`.
- Varmista, että `outputs/` ja `logs/` eivät päädy versionhallintaan (käytä organisaation käytäntöä: gitignore tai erillinen “no-commit” -alue).

## DATA_ROOT ja konfigurointi

Osa 3: DATA_ROOT ja konfigurointi

Periaate: `DATA_ROOT` asetetaan ympäristömuuttujaksi, eikä sitä kovakoodata skripteihin. Skriptit 20 ja 30 lukevat `Sys.getenv("DATA_ROOT")`.

Vaihtoehto A (suositus): ympäristömuuttuja komentoriviltä

```bash
export DATA_ROOT=/secure/path/to/project_data   # esimerkki; käytä organisaation polkua
```

Vaihtoehto B: .Renviron (paikallinen, ei commit)

1. Luo projektikohtainen `.Renviron` (tai käyttäjän kotihakemistoon) ja lisää rivi:

```text
DATA_ROOT=/secure/path/to/project_data
```

1. Käynnistä R/RStudio uudelleen tai varmista, että ympäristö latautuu ennen ajoa.

Vaatimukset DATA_ROOT:lle (ilman datan tulostamista):

- Paneelitiedoston polku on oletuksena: `file.path(DATA_ROOT, "derived", "aim2_panel.csv")` (näin 20_qc_panel_summary.R ja 30_models_panel_nb_gamma.R).
- Tarkista tiedoston olemassaolo ja lukuoikeus ilman sisällön tulostamista:

```bash
test -r "$DATA_ROOT/derived/aim2_panel.csv"
```

Vastaava tarkistus R:ssä ilman datan tulostamista:

```r
DATA_ROOT <- Sys.getenv("DATA_ROOT")
panel_path <- file.path(DATA_ROOT, "derived", "aim2_panel.csv")

if (DATA_ROOT == "") stop("DATA_ROOT ei ole asetettu.")
if (!file.exists(panel_path)) stop("Paneeliaineisto puuttuu: derived/aim2_panel.csv")
if (file.access(panel_path, 4) != 0) stop("Ei lukuoikeutta paneeliaineistoon.")
```

## Ajosekvenssi

Osa 4: Ajosekvenssi (setup -> QC -> mallit)

Tavoite on ajaa analyysi deterministisesti ja auditoitavasti seuraavassa järjestyksessä, noudattaen repo-skriptejä:

1. Ympäristön asetus: `00_setup_env.R`
2. QC-yhteenveto paneelista: `20_qc_panel_summary.R`
3. Mallit ja recycled predictions + cluster bootstrap: `30_models_panel_nb_gamma.R`

Huomio aineistosta:

- Jos `DATA_ROOT/derived/aim2_panel.csv` ei ole vielä tuotettu, QC ja mallit eivät voi edetä. Repo sisältää myös rungon `10_build_panel_person_period.R`, mutta se on mallipohja ja vaatii organisaation dataintegraatiologikan toteutuksen. Käytännössä tuotantoajossa oletus on, että controllerit tuottavat `aim2_panel.csv` turvallisessa ympäristössä `DATA_ROOT`-alueelle.

Suositeltu ajotapa komentoriviltä lokituksella (yksi run id):

```bash
RUN_ID="$(date +%Y%m%dT%H%M%S)"
mkdir -p "logs" "outputs" "outputs/archive/${RUN_ID}"

Rscript --vanilla 00_setup_env.R          > "logs/${RUN_ID}_00_setup_env.log" 2>&1
Rscript --vanilla 20_qc_panel_summary.R   > "logs/${RUN_ID}_20_qc_panel_summary.log" 2>&1
Rscript --vanilla 30_models_panel_nb_gamma.R > "logs/${RUN_ID}_30_models_panel_nb_gamma.log" 2>&1

cp -f "outputs/qc_summary_aim2.txt" "outputs/archive/${RUN_ID}/" 2>/dev/null || true
cp -f "outputs/panel_models_summary.csv" "outputs/archive/${RUN_ID}/" 2>/dev/null || true
```

Mitä kukin vaihe tuottaa (oletuspolut skriptien perusteella):

- 00_setup_env.R: alustaa `renv`-ympäristön ja varmistaa riippuvuudet (mm. tidyverse, MASS, sandwich, lmtest, broom, here).
- 20_qc_panel_summary.R: lukee `DATA_ROOT/derived/aim2_panel.csv` ja kirjoittaa aggregoidun QC-yhteenvedon tiedostoon `outputs/qc_summary_aim2.txt` (mm. rivimäärä, id-määrä, puuttuvan FOF:n osuus, nollakustannusten osuus).
- 30_models_panel_nb_gamma.R:
  - Count-outcomes: Negative Binomial (MASS::glm.nb) offsetilla `log(person_time)` ja recycled prediction (rate/PY) FOF=0 vs FOF=1, sekä cluster bootstrap -percentile CI.
  - Cost-outcomes: Gamma(log) positiivisissa kustannuksissa, recycled prediction (€/PY positiivisilla) ja cluster bootstrap CI.
  - Tallentaa aggregoidut tulokset `outputs/panel_models_summary.csv`.

Epäonnistumistilanteiden käsittely (käytännön ohjeet):

- Puuttuva paneeli: 20_qc_panel_summary.R ilmoittaa paneelin puuttumisesta ja poistuu; 30_models_panel_nb_gamma.R pysähtyy, ellei CI-tila ole päällä. Ratkaisu: varmista `DATA_ROOT` ja `derived/aim2_panel.csv`.
- Puuttuvat sarakkeet: jos vaadittuja muuttujia ei ole (esim. `person_time`, `FOF_status`, `period`, `frailty_fried`), mallit eivät ole luotettavia tai kaatuvat. Ratkaisu: varmista, että paneelissa on analyysisuunnitelman edellyttämät standardoidut sarakkeet, ja että `data/VARIABLE_STANDARDIZATION.csv` on ajan tasalla.
- `person_time == 0` tai `person_time <= 0`: offset `log(person_time)` tuottaa epäkelpoja arvoja. Ratkaisu: korjaa paneelin riskiaika (person-time) tai suodata virheelliset rivit panel build -vaiheessa ja kirjaa päätös QC-raporttiin.
- Konvergenssiongelmat / glm.nb ei konvergoi: tyypillisesti liittyy separaatioon, outliereihin tai invalidiin offsetiin. Ratkaisu: tarkista QC-gatet (alla), harkitse mallin kontrolliasetuksia (maxit), ja varmista että vasteet ovat ei-negatiivisia ja (count) mielellään kokonaislukumaisia.
- Liian vähän positiivisia kustannuksia: 30_models_panel_nb_gamma.R palauttaa `NULL` jos positiivisia havaintoja on liian vähän (nykylogiikassa < 10). Tuloksiin voi tulla NA. Ratkaisu: arvioi perusteltu analyysitaso, aggregoi kustannuskomponentti, tai raportoi “ei estimoitavissa” organisaation käytännön mukaan.

## QC-gatet ja hyväksymiskriteerit

Osa 5: QC-gatet ja hyväksymiskriteerit

QC:n tarkoitus on varmistaa, että paneeli soveltuu offset-pohjaiseen mallinnukseen ja että raportoitavat tulokset ovat sisäisesti johdonmukaisia.

Minimitarkistukset (suorita ennen mallinnusta, ja tallenna aggregoituna QC-raporttiin):

- [ ] Count-vasteet: kaikki arvot ovat >= 0.
- [ ] Cost-vasteet: kaikki arvot ovat >= 0; erikseen nollaosuudet (cost == 0) raportoidaan.
- [ ] `person_time` on > 0 kaikilla analyysiriveillä (tai dokumentoitu suodatus).
- [ ] FOF-status ei puutu (tai puuttuvuus on pieni ja käsittely dokumentoitu); sama frailty-muuttujalle (esim. `frailty_fried`).
- [ ] Paneelin eheys: yksi rivi per henkilö–periodi (ei duplikaatteja id + period -tasolla), tai jos poikkeaa, käytetään johdonmukaista aggregointia panel build -vaiheessa.
- [ ] Jaksojen (period) arvoalue on dokumentoitu ja tulkittavissa faktorina; unbalanced panel on sallittu, mutta period-merkitys (esim. kalenterivuosi) on lukittu raportointiin.
- [ ] Offset-yksikkö on oikein: rate/PY ja €/PY tulkinnassa nimittäjä on person-time (PY).
- [ ] Nollaosuudet:
  - count-vasteissa nollien osuus voi olla suuri; arvioi, onko nolla-inflatoituminen todennäköinen.
  - kustannuksissa nollien osuus ohjaa two-part -herkkyysanalyysiä.

Nykyinen QC-skripti tuottaa osan mittareista (n_ids, n_rows, missing_fof, zeros_cost). Suositus on laajentaa QC:tä (tai ajaa erillinen QC-lisäajo) seuraavalla periaatteella: kaikki tulosteet tallennetaan tiedostoon, eikä näytetä datarivejä.

Esimerkkipohja QC-lisäajolle (tallentaa vain aggregaatteja):

```r
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

DATA_ROOT <- Sys.getenv("DATA_ROOT")
panel_path <- file.path(DATA_ROOT, "derived", "aim2_panel.csv")

panel <- read_csv(panel_path, show_col_types = FALSE)

required <- c("id","FOF_status","age","sex","period","person_time","frailty_fried")
missing_cols <- setdiff(required, names(panel))
if (length(missing_cols) > 0) stop(paste("Puuttuvat sarakkeet:", paste(missing_cols, collapse = ", ")))

qc <- panel %>%
  summarise(
    n_rows = n(),
    n_ids = n_distinct(.data$id),
    any_person_time_le0 = any(.data$person_time <= 0, na.rm = TRUE),
    share_missing_fof = mean(is.na(.data$FOF_status)),
    share_missing_frailty = mean(is.na(.data$frailty_fried)),
    share_zero_cost_total = mean(.data$cost_total_eur == 0, na.rm = TRUE),
    any_negative_cost_total = any(.data$cost_total_eur < 0, na.rm = TRUE),
    any_negative_util_total = any(.data$util_visits_total < 0, na.rm = TRUE),
    any_duplicate_id_period = any(duplicated(paste(.data$id, .data$period)))
  )

dir.create("outputs", showWarnings = FALSE)
writeLines(capture.output(qc), "outputs/qc_summary_aim2_extended.txt")
```

Miten QC vaikuttaa mallivalintaan (ANALYSIS_PLAN.md:n hengessä):

- Kustannukset: jos nollakustannusten osuus on merkittävä, Gamma-GLM pelkissä positiivisissa kustannuksissa ei anna unconditional €/PY -tulosta. Tällöin suositus on raportoida ensisijaisesti two-part -herkkyysmallin unconditional €/PY (Pr(cost>0) \* E[cost|cost>0]) recycled prediction -muodossa ja cluster bootstrap -LV:n kanssa.
- Count-vasteet: jos nollien osuus on erittäin korkea ja residuaalinen nolla-inflatoituminen epäilyttää, dokumentoi ZINB-herkkyysanalyysin tarve organisaation hyväksymän käytännön mukaan (ei pakollinen, mutta mainitaan QC-raportissa perusteltuna vaihtoehtona).
- Offset: jos person-time -määrittely poikkeaa suunnitellusta, älä jatka mallinnukseen ennen kuin person-time ja periodin tulkinta on lukittu.

## Tulosten tallennus, lokitus ja audit trail

Osa 6: Tulosten tallennus, lokitus ja audit trail

Yhtenäinen output-politiikka (turvallinen oletus):

- Tallenna vain aggregoidut taulukot ja yhteenvedot.
- Älä tallenna analyysidataa repon alle. Paneeli pysyy `DATA_ROOT`-alueella.
- Vältä pienisoluja: älä raportoi tuloksia niin pienillä alaryhmillä, että yksittäisiä henkilöitä voisi päätellä.

Lokit ja toistettavuus:

- Jokaisesta ajosta tulee syntyä:
  - stdout/stderr-loki jokaisesta skriptistä (`logs/<RUN_ID>_*.log`)
  - sessionInfo (R-versio ja pakettiversiot)
  - git commit hash (jos repo on gitissä tässä ympäristössä)
  - ajoparametrit: seed ja bootstrap-kierrosten määrä B, sekä päivämäärä ja RUN_ID

Koska 30_models_panel_nb_gamma.R ei oletuksena aseta siementä ja käyttää B=50 (debug), suositus tuotantoajoon on:

- aseta siemen eksplisiittisesti ja kirjaa se (esim. `SEED=20260130`)
- nosta bootstrap-toistot tuotantotasolle organisaation käytännön mukaan (esim. B=500 tai B=1000) ja kirjaa käytetty arvo
- tee tämä hallitusti: joko päivittämällä skriptiä (ja commitoimalla muutos sisäiseen git-historiaan), tai ajamalla skripti `source()`-kääreen kautta, jossa `set.seed()` tehdään ennen ajoa

Esimerkki: audit-metadata tiedostoon (ei tulosta dataa):

```r
run_id <- Sys.getenv("RUN_ID")
if (run_id == "") run_id <- format(Sys.time(), "%Y%m%dT%H%M%S")

dir.create("logs", showWarnings = FALSE)

git_hash <- tryCatch(system("git rev-parse HEAD", intern = TRUE), error = function(e) NA_character_)
meta <- c(
  paste0("run_id: ", run_id),
  paste0("timestamp: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  paste0("data_root_set: ", Sys.getenv("DATA_ROOT") != ""),
  paste0("git_hash: ", git_hash)
)

writeLines(meta, file.path("logs", paste0(run_id, "_run_metadata.txt")))
writeLines(capture.output(sessionInfo()), file.path("logs", paste0(run_id, "_sessionInfo.txt")))
```

Nimeämiskäytännöt ja versiointi:

- Käytä `RUN_ID`-tunnistetta kaikissa ajokohtaisissa lokeissa ja arkistokopioissa.
- Pidä “latest” -tiedostot selkeinä (esim. `outputs/panel_models_summary.csv`), mutta kopioi ne aina ajon jälkeen arkistoon `outputs/archive/<RUN_ID>/`.
- Jos muokkaat skriptejä (esim. seed ja B), kirjaa muutos commitiksi ja liitä commit hash run metadataan.

## Turvallinen julkaistava output

Osa 7: Turvallinen julkaistava output

“Export safe” -periaate: vain sellaiset tulosteet, jotka ovat aggregoituja ja joista ei voi palauttaa yksilötason tietoa.

Tyypillisesti export safe tässä putkessa:

- `outputs/panel_models_summary.csv` (tai sen ajokohtainen kopio `outputs/archive/<RUN_ID>/panel_models_summary.csv`), jos se sisältää vain aggregoidut recycled prediction -estimaatit ja niiden bootstrap-LV:t outcome-tasolla.
- `outputs/qc_summary_aim2.txt` ja mahdollinen laajennettu QC-raportti, jos ne sisältävät vain yleisiä kokonaislukuja ja osuuksia ilman pienisoluja tai tunnisteita.

Ei export safe (älä julkaise/siirrä):

- Mikään tiedosto, joka sisältää rivitasoisia havaintoja, id:tä, periodikohtaisia yksilörivejä tai pienin alaryhmin jaoteltuja tuloksia.
- Lokit, jos niissä on vahingossa polkuja tai muuta metadataa, jota organisaatio ei halua ulos. Jos lokit on tarkoitus toimittaa, tee erillinen “log sanitization” organisaation käytännön mukaan.

Pienisolu-suppressio ja aggregointi:

- Jos organisaatiolla on pienisolusääntö (esim. solukoko < 5 tai < 10), tee suppressio tai yhdistä soluja ennen ulosvientiä.
- Suositus: älä sisällytä exportiin alaryhmätaulukoita, ellei jokainen solu ole selvästi riittävän suuri ja riskit arvioitu.
- Jos tuotat taulukoita (Table 2/3 -tyyliin), varmista että ne ovat outcome-tasolla tai laajoissa luokissa, eivätkä sisällä harvinaisia yhdistelmäluokkia.

## Pikaohje

Osa 8: Pikaohje (TL;DR)

```bash
export DATA_ROOT=/secure/path/to/project_data

mkdir -p logs outputs outputs/archive
Rscript --vanilla 00_setup_env.R
Rscript --vanilla 20_qc_panel_summary.R
Rscript --vanilla 30_models_panel_nb_gamma.R

# Tulokset: outputs/qc_summary_aim2.txt ja outputs/panel_models_summary.csv
```
