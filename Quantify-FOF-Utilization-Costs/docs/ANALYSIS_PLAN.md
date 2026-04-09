Analysis Plan: Pelkokaadon (FOF) yhteys palvelukäyttöön ja kustannuksiin (paneelidata, Aim 2)
Status: Draft (paneelidata-päivitys)
Context: Aim 2 of the FOF Project
Governance: Option B (No raw data in repo)

1. Research Objectives
   Quantify Utilization (panel): Onko lähtötilanteen Fear of Falling (FOF) yhteydessä suurempaan terveyspalvelujen käyttöön (käynnit/episodit) seurannassa henkilö–jakso -paneelissa?
   Quantify Costs (panel): Onko lähtötilanteen FOF yhteydessä suurempiin suoriin terveydenhuollon kustannuksiin henkilö–jakso -paneelissa?
   Heterogeneity (secondary): Vaihteleeko FOF–käyttö-/kustannusyhteys haurauden (frailty; ensisijaisesti K40-johdettu `frailty_index_fi` / `FI_22`) tai ajan (periodi) mukaan (efektimodifikaatio, ei kausaaliväitteitä)?
2. Study Population & Design
   Cohort: MFFP-osallistujat (rekisterilinkitys kontrolloidussa ympäristössä).
   Linkage: Rekisteriaineistot DATA_ROOT-hakemistosta (esim. Avohilmo, Hilmo) + mahdolliset muut projektissa määritellyt lähteet.
   Time horizon: Paneeliseuranta lähtötilanteen indeksipäivästä seurannan loppuun (esim. kuolema/muutto/seurannan päättymispäivä).
   Panel definition: henkilö–jakso (person–period), unbalanced panel sallittu.
   Periodin pituus: KB missing → assumed: 1 kalenterivuosi. (Jos projekti lukitsee periodin kuukausi/kvartaali, käytetään sitä; analyysikoodi ja raportointi ovat periodi-agnostisia, kunhan period ja person_time ovat oikein.)
   Exposure groups: Lähtötilanteen FOF (FOF=1) vs ei-FOF (FOF=0). FOF on lähtötilanteen muuttuja, joka kantautuu kaikille henkilö–jakso -riveille.
3. Data Variables & Standardization
   Adherence / “Do not guess”: Kaikki analyysissä käytettävät muuttujat on oltava standardoituna tiedostossa data/VARIABLE_STANDARDIZATION.csv (Option B: repo sisältää vain metadataa; data pysyy DATA_ROOT:issa). Englanninkielisiä muuttujanimiä ei saa keksiä tai käyttää, ellei niitä ole standardoinnissa.
   Mapping governance: analyysissa saa käyttää vain `frozen`-status mappingeja DATA_DICTIONARY_WORKFLOW.md:n sääntöjen mukaan; `inferred`, `tbd` ja `artifact`-tilaiset rivit ovat oletuksena blokattuja.
   Cleanup deferral: artifact-, duplicate- ja redacted-riskit käsitellään erillisessä Phase 2 -taskissa, eivät tämän analyysisuunnitelman oletuspolussa.

3.1 Assumptions & definitions (locked)
Analyysiyksikkö: henkilö–jakso (person–period).
Aikajaksotus: paneeliaineisto; jokainen rivi kuvaa henkilöä id jaksolla period.
Seuranta-aika ja offset:
person_time = henkilön riskiaika kyseisessä periodissa (yksikkö: henkilövuotta, PY).
Offset: offset = log(person_time) kaikissa ensisijaisissa malleissa (count ja cost).
Censorointi: kuolema/muutto/seurannan loppu katkaisee periodin riskiajan; tällöin person_time < periodin täysi pituus.

Count-outcome (käynnit/episodit):
Lasketaan periodikohtaiset tapahtumamäärät (käynnit/episodit) per palveluluokka.
Raportointiyksikkö: rate/PY (ennustettu tapahtumatiheys per henkilövuosi).

Cost-outcome (kustannukset):
Periodikohtaiset kustannukset euroina (kokonaiskustannus ja/tai komponentit).
Raportointiyksikkö: €/PY (ennustettu kustannus per henkilövuosi).
Hintavuosi: KB missing → assumed: kustannukset ovat yhteismitallisia (yhden hintavuoden euroja). Hintavuosi ja deflatointi (jos tarpeen) on lukittava projektin costing mapissa ennen lopullista raportointia.

FOF ja frailty:
FOF: lähtötilanteen binäärimuuttuja (0/1).
Frailty: ensisijainen kovariaatti on K40 `FI22_nonperformance_KAAOS` -contractista johdettu potilastason `frailty_index_fi` (tai skaalattu `frailty_index_fi_z`); Fried-proxy säilyy vain fallback / sensitivity -roolissa, jos FI-kenttiä ei ole integroituna paneliaineistoon. Toissijaisesti efektimodifikaatio arvioidaan muodossa FOF×frailty_index_fi.

Nollakustannukset:
Gamma-GLM vaatii positiiviset kustannukset; nollien osuus arvioidaan QC-gatessa.
Jos nollia on merkittävästi, käytetään herkkyysanalyysinä two-part/hurdle (logit any_cost + Gamma(log) positive costs) ja raportoidaan unconditional €/PY.

3.2 Required fields (conceptual; must map to standardized names)
Standardoinnista löydetyt (esimerkkisnapshot):
id (henkilö-ID; pseudonymisoitu avain analyysiympäristössä)
FOF_status (FOF; binäärinen)
age (lähtötilanneikä; vuosina)
sex (esim. 1=M, 2=F standardoinnin mukaan)

KB missing → required for panel analysis (must be mapped/derived and added to standardization):
period (jakso; factor/numeric)
riskiaika per periodi (KB missing; needs standardization mapping before run)
frailty_index_fi / frailty_index_fi_z (ensisijainen K40 FI_22 -frailtykenttä)
n_deficits_observed / coverage / fi_eligible (K40 FI QC -kentät, jos FI-pohjainen malli ajetaan)
frailty*\_(Fried-proxy -indikaattori tai -pistemäärä; vain fallback / sensitivity)
lähtötilanteen komorbiditeettikenttä/-kentät (KB missing; needs standardization mapping before run)
aiemmat kaatumiset tai vastaava lähtötilanteen riskihistoriakenttä (KB missing; needs standardization mapping before run)

FI QC -kenttiä (`fi_eligible`, `coverage`, `n_deficits_observed`) käytetään FI-pohjaisten mallien analyysikelpoisuuden ja datan kattavuuden arviointiin; ne eivät itsessään määritä frailtya, mutta niitä voidaan käyttää analyyttisen otoksen rajaamiseen tai sensitivity-analyyseihin.

Count-outcomes: palveluluokkakohtaiset periodilaskurit (esim. päivystyskäynnit, osastoepisodit, avohoitokäynnit, kuntoutusepisodit, kotihoitokontaktit)
Cost-outcomes: periodikohtaiset kustannukset (kokonaiskustannus ja/tai komponentit)

3.3 Baseline variables carried forward
Kaikki lähtötilanteen muuttujat (FOF, ikä, sukupuoli, frailty, lähtötilanteen komorbiditeetit) liitetään henkilö–jakso -tauluun ja toistuvat kaikilla periodeilla samalle henkilölle.
Aikavaihtuvat kovariaatit (jos SAP määrittelee) mallinnetaan period-tasolla ja dokumentoidaan erikseen; oletuksena tässä suunnitelmassa kovariaatit ovat lähtötilanteen mittauksia, ellei projektin SAP lukitse muuta.

1. Statistical Models
   4.0 Mallivalinta (paneelirakenne ja epävarmuus)
   Paneeliaineistossa toistomittaukset huomioidaan ensisijaisesti population-averaged-tulkinnan mukaisesti käyttäen cluster-robust vakiovirheitä henkilötasolla (id).
   Mixed/GEE-estimaattorit voidaan lisätä, jos SAP/KB vaatii; tässä suunnitelmassa ensisijainen raportointi perustuu pooled-malleihin + robust SE + cluster bootstrap ennusteille.

4.1 Utilization (Count Data) — Primary: Negative Binomial with offset
Päämalli (kullekin count-outcomelle erikseen):
[
Y*{it} \sim \text{NegBin}, \quad \log(E[Y*{it}]) =
\beta*0 + \beta_1 \text{FOF}\_i + \gamma_t(\text{period}\_t) + \mathbf{X}\_i\boldsymbol{\beta}
\log(\text{person_time}*{it})
]
Spesifikaatio (template):
count_it ~ FOF_status + period + age + sex + morbidity + prior_falls + frailty_index_fi + offset(log(person_time))
Toissijaisesti: FOF_status × frailty_index_fi ja/tai FOF_status × period (vain jos raportointisuunnitelma/synopsis tätä edellyttää; muuten pidetään mallit parsimonisina). Fried-proxy-termit kuuluvat vain fallback / sensitivity -malleihin.

Raportointi (mallikertoimet):
FOF-kerroin IRR-muodossa: IRR = exp(β1) + 95% LV (cluster-robust).

Recycled predictions (ensisijaiset tulokset):
Ennustettu rate/PY FOF=1 vs FOF=0 (kaikille havainnoille vuorotellen asetettuna), sekä:
rate-ratio (FOF=1 / FOF=0)
absolute difference (FOF=1 − FOF=0) rate/PY

Epävarmuus ennusteille:
Cluster bootstrap (resample id) → 95% LV recycled prediction -estimaateille (percentile CI; BCa mahdollinen jos sovittu).

4.2 Costs (Continuous, skewed) — Primary: Gamma GLM (log link) with offset
Päämalli (kullekin cost-outcomelle erikseen):
[
\text{Cost}{it} \mid \text{Cost}{it}>0 \sim \Gamma,\quad
\log(E[\text{Cost}_{it}]) =
\alpha*0 + \alpha_1 \text{FOF}\_i + \gamma_t(\text{period}\_t) + \mathbf{X}\_i\boldsymbol{\alpha}
\log(\text{person_time}*{it})
]
Spesifikaatio (template):
cost_it ~ FOF_status + period + age + sex + morbidity + prior_falls + frailty_index_fi + offset(log(person_time)), family = Gamma(link="log")

Huom (positiivisuus):
Gamma-GLM sovitetaan positiivisille kustannuksille (cost>0). Nollaosuuden suuruus raportoidaan QC-gatessa.

Raportointi (mallikertoimet):
FOF-kerroin mean ratio -muodossa: MR = exp(α1) + 95% LV (cluster-robust).

Recycled predictions (ensisijaiset tulokset):
Ennustettu €/PY FOF=1 vs FOF=0 positiivisten kustannusten osajoukossa.
Jos nollaosuus on merkittävä, ensisijainen unconditional €/PY raportoidaan herkkyysmallista (two-part), ks. 4.3.

Epävarmuus ennusteille:
Cluster bootstrap (resample id) → 95% LV recycled prediction -estimaateille.

4.3 Sensitivity (choose one) — Primary sensitivity: Two-part / hurdle for costs
Perustelu: Paneeliperiodissa kustannuksissa on usein huomattava nollaosuus (ei palvelunkäyttöä kyseisenä periodina) ja voimakas vinous. Two-part tuottaa suoraan unconditional €/PY.
Two-part/hurdle:
Any-cost -osa: I(cost_it>0) ~ FOF_status + period + covariates (logit)
Positive-cost -osa: cost_it | cost_it>0 ~ Gamma(log) + offset(log(person_time))
Unconditional recycled prediction:
E[cost_it] = Pr(cost_it>0) × E[cost_it | cost_it>0]
Raportointi: €/PY FOF=1 vs 0, ratio ja absolute €-difference, + cluster bootstrap 95% LV.

1. QC Gates (Quality Control)
   Ennen mallinnusta tuotetaan QC-yhteenveto (metadata-only output outputs/-hakemistoon):
   Logical consistency: counts ≥ 0, costs ≥ 0, person_time > 0
   Completeness: FOF, frailty, covariates
   Panel integrity: periodien määrä, aukot
   Zeros & skew: nollaosuus, outlierit
   QC:n tulokset kirjataan lyhyesti ja niiden perusteella lukitaan two-part käyttö.
2. Runbook & Reproducibility
   Environment: renv::restore()
   Script naming:
   scripts/10_build_panel_person_period.R
   scripts/20_qc_panel_summary.R
   scripts/30_models_panel_nb_gamma.R
   Output logging: manifest/

# scripts/30_models_panel_nb_gamma.R

# Template-runner (Option B safe-by-default): packages -> prep -> NB + Gamma

# -> cluster-robust SE -> recycled predictions -> cluster bootstrap -> tables

suppressPackageStartupMessages({
library(dplyr)
library(readr)
library(stringr)
library(MASS) # glm.nb
library(sandwich) # vcovCL
library(lmtest) # coeftest
library(broom) # tidy
})

# [Full R code template implied from prompt]

#

1. Interpretation & Reporting
   7.1 Report-ready outputs (default)
   Counts: IRR(FOF), Recycled predictions (rate/PY, ratio, diff) + 95% boot CI
   Costs: MR(FOF) (pos), Recycled predictions (€/PY, ratio, diff) + 95% boot CI (Two-part if needed)

7.2 Conservative interpretation
Assosiaatiokieli. Efektikoot.

7.3 Table-to-text crosscheck
Varmista offset ja yksiköt.

7.4 Internal consistency check
Lukitse period, person_time, aktiivinen frailty-kenttä (`frailty_index_fi` / `frailty_index_fi_z`), mahdollinen FI QC -kelpoisuus (`fi_eligible`, `coverage`, `n_deficits_observed`) ja hintavuosi.
