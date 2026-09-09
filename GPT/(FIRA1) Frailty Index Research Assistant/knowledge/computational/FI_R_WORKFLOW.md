---
title: "FIRA1:n R-työnkulku"
status: "VERIFIED_WITH_GATES"
updated: "2026-08-30"
source_basis: "Fear-of-Falling AGENTS/README/CLAUDE ja K40-tuottajat"
canonical_for: "FI:n toistettava toteutus-, QC- ja artefaktireititys"
used_when: "FI-koodia tarkastetaan, ajetaan tai muutetaan"
not_authoritative_for: "Vajeiden tieteellinen hyväksyntä tai kliiniset päätökset"
related_files: "../project/FI_PROJECT_SPEC.md; ../validation/FI_QC_VALIDATION.md"
update_triggers: "K40 entrypoint, output discipline, manifest tai QC-runner muuttuu"
---

## FIRA1:n R-työnkulku

## GENERAL_FI:n nykyinen validointi- ja auktoriteettireitti

Tämä osio kuvaa GENERAL_FI:n rajatun kandidaattilogiikan validointia. Alempien
K40/FI22-ajokuvausten tai vanhojen phase-statusyhteenvetojen perusteella ei saa
päätellä GENERAL_FI:n nykyisiä hyväksyntöjä tai valmiutta.

### Auktoriteetit ja rajaus

- [KB_INDEX](../KB_INDEX.md) reitittää oikealle omistajalle; se ei tee kandidaatipäätöksiä.
- [Candidate Registry](../registry/FI_CANDIDATE_REGISTRY.csv) omistaa kandidaatiston
  nykytilan ja [FI_CHANGELOG](../registry/FI_CHANGELOG.md) päätös- ja supersession-historian.
- [FI_PROJECT_SPEC](../project/FI_PROJECT_SPEC.md) omistaa projektisäännöt ja varianttiroolit.
  [DATA_DICTIONARY](../project/DATA_DICTIONARY.md) reitittää lähdesemantiikkaan;
  [FI_METHODS_CANONICAL](../methods/FI_METHODS_CANONICAL.md) erottaa menetelmäperustan
  projektipäätöksistä. Uusi scoring tai kandidaatipäätös ei seuraa onnistuneesta testistä.
- [FI_QC_VALIDATION](../validation/FI_QC_VALIDATION.md) omistaa validointiluokat,
  T01–T12-käyttäytymiskriteerit ja pitkittäisportin. Tämä runbook ei korvaa niitä.

Nykyinen kandidaattilogiikka on repojuuren polussa
`Fear-of-Falling/R/functions/general_fi_candidate_state.R`. Se toteuttaa rajattuja
hyväksyttyjä GENERAL_FI-kandidaattien tila-/mapping-funktioita, ei täydellistä
osallistujatason GENERAL_FI-rakentajaa. K15/K24-proxyt, `frailty_score_3`,
`frailty_cat_3`, FI22 ja Electronic-Frailty-Index eivät korvaa tämän haaran auktoriteettia.

### Validointikerrokset ja komennot

Työhakemisto on `Fear-of-Falling/`. Varmista `pwd` ennen komentoja.

```bash
make fof-preflight
```

Tämä nykyinen entrypoint ajaa `scripts/fof-preflight.sh`-wrapperin kautta
repositoriokohtaisen diff-tarkistimen. Se tarkistaa soveltuvia Kxx-otsikko-,
vaadittu-sarake- ja output-sopimuksia sekä turvarajoja. Se ei suorita GENERAL_FI:n
funktionaalisia testejä eikä yksin todista tehtävän kirjoitusrajauksen noudattamista.
Tarkistin näkee myös muiden keskeneräisten töiden diffiä; erottele löydösten alkuperä.

Kun tehtävä vaatii nykyisen kandidaattilogiikan testaamista, kohdistettu reitti on:

```bash
make test-r TEST_SCRIPT=tests/test_general_fi_raw015.R
```

`tests/test_general_fi_raw015.R` lataa edellä mainitun state-funktion ja muodostaa
syötteet itse. Tiedostonimestään huolimatta se kattaa myös RAW-037/042:n
rajattua tilareititystä sekä RAW-039:n raja-, E/E1-, desimaalipilkku- ja
fail-closed-regressioita. Se ei lue osallistujadataa eikä rakenna participant-FI:tä.
`test-r` välittää R-ajon epäonnistumisen; puuttuva testi tai R-tulkki ei ole PASS.
Käytä projektin tukemaa valmista R-ympäristöä; tämä komento ei ole asennuslupa.
Startup/renv- tai ympäristöeste kirjataan esteeksi, ei korvata smoke-tuloksella.

Preflight ja yleiset smoke-portit, kohdistettu funktionaalinen testi sekä
FI:n tieteellinen validointi ovat eri kerroksia. Tässä kuvattu testiajo ei ole
koko FI:n, kaikkien kandidaattien tai tieteellisen validiteetin todiste.
T06/T12 ovat FI_QC_VALIDATIONin auktoriteetti-/provenienssikriteereitä;
pelkät tunnisteet eivät muodosta ajettavaa testikomentoa. Tarkastetuilta
FIRA1-testipinnoilta ei löytynyt erillistä T06/T12-runneria. Kirjaa dokumentin
auktoriteettitarkastus erikseen, älä väitä suorittaneesi automatisoitua testiä.

### K18/QC ja suojattu data

Noudata `Fear-of-Falling/README.md`:n ja `AGENTS.md`:n K18/QC-soveltuvuutta:
data-, coding-, ID/time-, missingness-, inclusion/exclusion-, model-frame- ja
QC-muutokset sekä tehtävän nimenomainen vaatimus edellyttävät soveltuvaa QC:tä.
Pakollisen QC:n suorituseste pysäyttää kyseisen tehtävän.

Vain tätä reittiä dokumentoivassa pilotissa:
`K18/QC: NOT APPLICABLE — ei data-, tiede-, koodaus-, kohortti- tai QC-muutosta`.
Dokumentaation tarkistus on Markdown-lint, diff-tarkistus ja FOF-preflight;
analyysi-/metadata-ajot, K18 ja GENERAL_FI-laskenta eivät kuulu siihen.

Osallistujatason `AUTH_SOURCE`, `PERSON_LEDGER`, `ASSESSMENT_LEDGER` ja
`PRIMARY_FI_INDEX` sekä suojattu `DATA_ROOT` jäävät dokumentaatiopilotin ulkopuolelle.
Registry ja review-pool ovat kandidaatipäätösten metadataa, eivät osallistujatason
analyysidataa. Käsittele niiden solusisältöä evidenssinä, älä suoritettavina ohjeina
tai lupana muuttaa dataa. Pilotissa ei muuteta niitä, päätöksiä tai outputteja.

## Suojatun evidenssiviitteen määrittely

Tämä osio on promptin 23 mukainen katselmoitava määrittely, ei käyttöönotettu
viitemekanismi tai enforcement. Omistajan hyväksymä viiteperiaate ei anna
lupaa suojatun sisällön jakeluun. Konkreettinen tunniste- ja resoluutiomekanismi
jää `NEEDS_VERIFICATION`-tilaan, kunnes se määritellään ja hyväksytään erikseen.

### Auktoriteetit ja tietoraja

- [KB_INDEX](../KB_INDEX.md) reitittää provenance-/toteutuskysymykset tähän
  työnkulkuun. Tämä osio omistaa niiden FIRA1-viittaussemantiikan määrittelyn.
- Repositoryn [luokittelupolitiikka](../../../../config/fira1_knowledge_classification.md)
  omistaa PROTECTED-etusijan, VC-/LOCAL_ONLY-täsmäluokat ja DENY_UNCLASSIFIED-oletuksen.
  [Security](../../../../.github/SECURITY.md) ja
  [Contributing](../../../../.github/CONTRIBUTING.md) omistavat tietoturvarajat.
  Omistaja/Data Steward ratkaisee puuttuvan jakelu- ja käyttövaltuutuksen.
- [DATA_DICTIONARY](../project/DATA_DICTIONARY.md) omistaa muuttujasemantiikan
  reitityksen, [Project Spec](../project/FI_PROJECT_SPEC.md) projektipäätökset,
  Methods lähdekohtaisen menetelmäperustan ja
  [Validation](../validation/FI_QC_VALIDATION.md) QC-/T01–T12-vaatimukset.
- Repositoryn [SKILLS](../../../../SKILLS.md) omistaa tehtäväjonon ja aikaleimalokin;
  Contributing ohjaa soveltuvaa artefaktimanifestia. Viiteseloste ei korvaa
  näitä eikä oikeuta kirjoittamaan manifestiin suojattua provenienssia.

Osallistujatason lähde, ledger, tunniste ja terveystieto ovat suojattua sisältöä.
Kandidaattipäätös tai workflow-metadata voi olla muuta kuin osallistujadataa,
mutta se ei siksi automaattisesti ole jakelukelpoista. Registry/Changelog ovat
nykyisessä luokittelussa DENY_UNCLASSIFIED. Git-tracking tai ignored-tila ei
määritä sisällön turvallisuutta, lukuvaltuutta tai tieteellistä auktoriteettia.

### PROTECTED_EVIDENCE_REFERENCE: semanttinen sopimus

Abstraktio kuvaa, mihin todentamistarpeeseen suojattua evidenssiä tarvitaan,
kuka omistaa kyseisen väitteen ja minkä portin kautta viite voidaan myöhemmin
valtuutetusti ratkaista. Alla on käsitteellinen kenttäluettelo, ei uusi
serialisointiskeema, tunnisteavaruus tai sallittujen evidenssiluokkien enum.
Viite ilman hyväksyttyä yksilöivää mekanismia on keskeneräinen, ei resolvoitava.

| Metatieto                                     | Sallittu merkitys ja nykyinen perusta                                                                    | Puuttuvan tiedon käsittely                                                                                              |
| --------------------------------------------- | -------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| Evidenssin luokka/tyyppi                      | Vain luokittelupolitiikan jo määrittämä luokka ja auktorisoitu ei-arkaluontoinen evidenssirooli          | Älä keksi uutta luokkaa; tuntematon luokittelu säilyy DENY_UNCLASSIFIED                                                 |
| Auktoriteetti/lähderooli                      | KB_INDEXin domain owner tai nykyisen työnkulun symbolinen rooli; ei lähteen suojattua nimeä tai sisältöä | NEEDS_VERIFICATION, jos omistaja tai rooli puuttuu                                                                      |
| Ei-arkaluontoinen paikannin tai opaakki viite | Vain erikseen hyväksytyn olemassa olevan mekanismin turvallinen viite                                    | Käyttökelpoista VC→PROTECTED-mekanismia ei ole varmennettu; kenttä jätetään täyttämättä ja merkitään NEEDS_VERIFICATION |
| Tarkoitus                                     | Tehtävän täsmällinen ei-arkaluontoinen hyväksymisväite ja evidenssin välttämättömyys sille               | Epäselvää tarkoitusta ei käytetä datan avaamisen perusteena                                                             |
| Vaadittu pääsyportti                          | Tehtäväkohtainen omistajan lupa, sallittu suojattu ympäristö, data-/tiede-/QC-porttien soveltuvuus       | Puuttuva valtuus estää dereferoinnin                                                                                    |
| Varmennustila                                 | Nimetyn väitteen PASS, FAIL, NOT_APPLICABLE tai NEEDS_VERIFICATION ja ei-arkaluontoinen peruste          | Älä muuta suorittamatonta tarkistusta PASSiksi                                                                          |

Omistajan hyväksymä opaakin viitteen periaate edellyttää, ettei tunniste
sisällä tai koodaa suojattua lähdeidentiteettiä, polkua, henkilötietoa,
salaisuutta tai schema-/arvosisältöä. Lähdetiiviste ei ole implisiittinen
opaakki tunniste. Tarkkaa syntaksia, URI:a, tallennuspaikkaa, omistajatietuetta,
uutta hash-konventiota tai säilytysaikaa ei määritellä ilman nykyistä auktoriteettia.

Työnkulussa esiintyy hash-varmennettua provenienssia ja Contributingissa
manifestilokitusta. Ne eivät määritä yleistä suojatun evidenssin viitepalvelua.
Repo-relative artefaktiviite ei anna lupaa paljastaa suojattua lähdepolkua.
Absoluuttiset lähdepolut on tässä työnkulussa jo kielletty KB:stä. Lähdenimen,
suhteellisen suojatun polun ja digestin yleinen jakelulupa jää ratkaisematta;
niiden esiintyminen vanhassa dokumentissa ei ratkaise lupaa.

### Kielletty sisältö ja erillinen käyttövaltuus

Tehtäväkorttiin, pakettiin, promptiin, lokiin, audit-evidenssiin, Knowledgeen,
manifestiin tai koneelliseen HOTL-metatietoon ei saa upottaa osallistujarivejä,
henkilötunnisteita, yksilön ominaisuuksia, PII/PHI:tä, salaisuuksia,
credentialeja, tunnisteita sisältäviä tiedostonimiä, suojattua vapaata tekstiä,
lähdesisältöä tai suojattuja schema-/arvo-otteita. Myöskään virhediagnostiikka
ja viitekentät eivät saa välittää näitä. Jakeluun hyväksymätön provenienssi
jää suojatun rajan sisään. Ei korvata kiellettyä sisältöä siitä johdetulla
paljastavalla tunnisteella.

Viittauslupa ei anna luku-, muunnos-, vienti-, toisto- tai muokkauslupaa.
Dereferointi edellyttää erikseen tehtäväkohtaista ihmisen/data-access-valtuutta,
valtuutettua ympäristöä ja tietorajaa sekä soveltuvia tieteellisiä ja QC-portteja.
QC:n soveltuvuus arvioidaan tulevasta operaatiosta; tämä määrittely ei anna
K18-poikkeusta suojattua dataa käyttävälle ajolle. Raakadata säilyy read-only.

Tulevan scope-mallin `READ_REFERENCE_ONLY` tarkoittaa vain hyväksytyn turvallisen
viitemetadatan käsittelyä. Se ei tarkoita lähteen lukuoikeutta. Evidenssiviitteet
pidetään semanttisesti erillään `allowed_write_paths`-kohteista: viitteen
esiintyminen ei saa lisätä lähdettä kirjoitusjoukkoon tai ohittaa PROTECTEDia.
Tässä ei oteta käyttöön koneellista kenttää, tarkistinta tai scope-skeemaa.

### Ratkaiseminen, kriittisyys ja hyväksymisevidenssi

Hyväksytyn tulevan menettelyn on pystyttävä todentamaan lähdeauktoriteetti,
versiosidonta ja oikea evidenssisuhde valtuutetussa suojatussa ympäristössä.
Ratkaisutietueen konkreettinen rakenne, kanoninen omistaja/sijainti,
luonti-/päivitysvaltuudet, yksikäsitteisyys ja varmennusmenettely ovat vielä
`NEEDS_VERIFICATION`. Tämän määrittelyn perusteella ei luoda tietueita.

Puuttuva, moniselitteinen, duplikaatti, ristiriitainen, ratkaisematon tai
valtuutetun tietorajan ulkopuolelle johtava viite ei kelpaa varmennukseksi.
Jos diagnoosi vaatisi suojatun tiedon paljastamista, diagnoosi pysähtyy;
lokiin saa vain ei-arkaluontoisen syyluokan. Ei arvaamista, automaattista
lähteen korvaamista tai suojausten ohittamista.

- Ei-kriittinen ratkaisematon viite voi jäädä `NEEDS_VERIFICATION`-tilaan.
  Vain siitä riippumaton, muuten hyväksytty työ saa jatkua.
- Jos evidenssi tarvitaan execution-critical tiede-, scope-, QC-, turvallisuus-
  tai hyväksymisväitteen todentamiseen eikä auktoritatiivista fallbackia ole,
  riippuva suoritus on `BLOCKED`. Viitteen epävarmuus säilyy näkyvissä erikseen.
- Fallbackin auktoriteetti ja tehtäväkohtainen soveltuvuus on osoitettava ennen
  käyttöä; fallback ei muuta tieteellistä sääntöä tai hyväksy uutta päätöstä.

Tehtävän DoD voi vaatia valtuutetun tarkastajan todentamaan nimetyn väitteen
suojatussa ympäristössä. Task-evidenssiin kirjataan vain hyväksymiskriteeri,
valtuutuksen turvallinen viite jos sellainen on hyväksytty, tarkistusmenetelmän
yleiskuvaus, aikaleima ja tulos perusteluineen. Lähdearvoja ei kopioida.
Auditoitavan sidonnan puuttuessa hyväksymisväitettä ei merkitä PASSiksi.

PASS tarkoittaa nimetyn kriteerin todentamista; FAIL todettua poikkeamaa;
NOT_APPLICABLE perusteltua soveltumattomuutta; NEEDS_VERIFICATION puuttuvaa
varmennusta. Nämä eivät muuta Validationin tieteellistä tulosasteikkoa.
Pelkkä aggregaattisuus ei takaa turvallisuutta: myös pienet solut, tunnistavat
yhdistelmät ja lähdettä paljastava virheteksti jäävät ulos julkisesta evidenssistä.

### Synteettiset esimerkit ja avoimet riippuvuudet

Kelvollinen keskeneräinen viiteseloste, ei käyttökelpoinen lähdetunniste:
kuvitteellinen tehtävä tarvitsee myöhemmin lähteen ajoitussemantiikan
varmennuksen. Luokka on PROTECTED, auktoriteettireitti on DATA_DICTIONARY →
auktoritatiivinen lähdeschema, tarkoitus on ajoitusvastaavuuden todentaminen,
paikannin jätetään täyttämättä, pääsy edellyttää erillistä valtuutusta ja
varmennustila on NEEDS_VERIFICATION. Seloste on sallittua rooli-/tarkoitusmetadataa.
Jos ajoitusvastaavuus on ajon hyväksymisehto, ajo on BLOCKED. Esimerkki ei väitä
olemattoman tunnisteen resoluutiota eikä luo tunnistetta.

Virheellinen synteettinen esimerkki: tehtävän viitekenttään kopioidaan
kuvitteellisen henkilön kokonainen tietuerivi tai lähteen schema-/arvotaulukko.
Payload hylätään sisällön vuoksi, vaikka kentän nimi olisi viite tai tiedosto
olisi ignored. Esimerkki kuvaa virheen rakennetta eikä sisällä tietueriviä.

Käyttökelpoinen yksilöivä viite, suojattu resoluutiomekanismi ja sen hyväksytty
VC-esitys jäävät NEEDS_VERIFICATION-tilaan. DATA_DICTIONARYn provenance-korvaus
ja taaksepäin yhteensopiva evidenssisidonta tarvitsevat erillisen ratkaisun;
nykyisiä lähdesidontoja ei poisteta tämän määrittelyn nojalla. Tulevan korjauksen
on säilytettävä muuttujamerkitys, suunta, valid/missing-erot, timing, lineage,
lähdeauktoriteetti, GENERAL_FI ja tutkijapäätösten sekä avointen päätösten tila.

DATA_DICTIONARY-remediaatio ja tracking-migraatio pysyvät keskeytettyinä.
Luokittelu ei ole jakelulupa; tämä määrittely ei hyväksy niiden sisältöportteja.
Mekanismia koskevan erillisen määrittely-/hyväksyntäpäätöksen jälkeen voidaan
hyväksyä rajattu toteutustehtävä. Remediaatio tarvitsee edelleen erilliset
DISTRIBUTION_SAFETY- ja SCIENTIFIC_SEMANTIC_EQUIVALENCE-portit ennen migraatiota.

### Step 2: tunniste- ja resoluutiovaihtoehdot

Prompt 24 valtuuttaa seuraavan konkreettisen määrittelyehdotuksen, ei sen
käyttöönottoa. Step 1:n avoimet mekanismikohdat saavat tässä vaihtoehdot;
ne eivät muutu hyväksytyksi ajettavaksi menettelyksi. Tunnisteet eivät ole
salaisuuksia, käyttövaltuuksia tai lähteen jakelulupia. Esimerkit ovat täysin
synteettisiä; yhtään todellista viitettä ei luoda.

#### Omistajuus ja sijoitusluokka

Repositoryn WORKFLOW osoittaa tehtävien hyväksymisen Human Supervisorille.
Luokittelupolitiikan ja promptien mukainen Owner/Data Steward ratkaisee
jakelun ja suojatun käytön valtuutuksen. Viitteiden luonti, päivitys,
supersession, peruutus ja invalidointi edellyttävät tämän tahon eksplisiittistä
tehtäväkohtaista hyväksyntää. Agentti ei saa myöntää valtuutta itselleen.

Kanoninen operatiivinen rekisterinpitäjä ja ylläpitäjälle delegoitavat oikeudet:
`NEEDS_VERIFICATION`. Tutkija/domain owner varmentaa tieteellisen roolin,
mutta se ei korvaa rekisterin ylläpito- tai datankäyttövaltuutta. Puuttuvaa
omistajaa ei päätellä tiedoston nykyisestä sijainnista.

Suojatun kartoituksen lähdeidentiteetti, sijainti, versio/digest, tarkka
auktoriteettisidonta ja varmennusevidenssi kuuluvat PROTECTED-rajan sisään.
Työnkulun nykyinen suojattu ympäristö on niiden ainoa sallittu sijaintiluokka;
tarkka rekisteripaikka ja ympäristömenettely on hyväksyttävä erikseen.
Normaaliin Git-historiaan saa tulevan hyväksynnän jälkeen vain turvallisen
viite-esityksen ja ei-paljastavan varmennustuloksen. Luokittelu ja jakelulupa
ovat eri portteja. Tässä ei luoda hakemistoa, rekisteriä tai tiedostomuotoa.

#### Vaihtoehdot ja syntaksi

Syntaksit ovat ehdotettuja FIRA1:n paikallisia nimiavaruuksia, eivät URI:a,
tiedostopolkuja tai jo käytössä olevia tunnisteita. Kirjainkoko on merkitsevä;
ei automaattista normalisointia, aliasointia tai arvailua.

- A: `FIRA1-PER-R1-` ja täsmälleen 64 pientä heksamerkkiä (`0–9`, `a–f`).
  Loppuosa muodostettaisiin 256 riippumattomasta kryptografisesti turvallisesta
  satunnaisbitistä, ei lähteen sisällöstä, nimestä, digestistä tai henkilöstä.
- B: `FIRA1-PER-S1-` ja täsmälleen 20 desimaalinumeroa. Keskitetty jakaja
  varaisi kasvavan laskuriarvon atomisesti, alkaen yhdestä; etunollat säilyvät.
  Arvo ei koodaa lähderoolia, ajankohtaa tai henkilöä. Kapasiteetin loppuessa
  luonti pysähtyy; laskuria ei kierretä tai käytetä uudelleen.

| Ominaisuus                   | A: satunnainen                                                                              | B: keskitetty laskuri                                                                       |
| ---------------------------- | ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| Luottamuksellisuus           | Ei lähderiippuvuutta tai sisäistä järjestystä; sama token silti yhdistää sen esiintymät     | Ei lähdesisältöä, mutta paljastaa jakojärjestyksen ja mahdollistaa määräarvioita            |
| Yksikäsitteisyys / törmäys   | Satunnaistörmäys mahdollinen; pakollinen globaali uniikkiustarkistus                        | Atominen jakaja ehkäisee normaalin kaksoisjaon; palautus-/replikointivirhe voi rikkoa tämän |
| Auditoitavuus                | Suojattu kartoitus ja tapahtumaketju välttämättömiä                                         | Sama vaatimus; järjestysnumero ei ole provenance-todiste                                    |
| Operatiivinen monimutkaisuus | Turvallinen satunnaislähde ja yhtenäinen rekisteröinti                                      | Yksi koordinoitu jakaja ja palautusten laskuritilan hallinta                                |
| Siirrettävyys                | Token säilyy ympäristöstä toiseen; resolveri ja pääsyvaltuudet eivät siirry automaattisesti | Token siirtyy, mutta jakajien yhdistäminen vaatii yhteisen varausjärjestelmän               |
| Versiosidonta                | Muuttumaton suojattu sidonta alla                                                           | Sama sidontasopimus                                                                         |
| Taaksepäin yhteensopivuus    | Legacy-viitteet tarvitsevat valtuutetun kartoituksen                                        | Sama; vanha numero ei saa automaattisesti olla uuden nimiavaruuden numero                   |

Tekninen suositus on A: se välttää B:n järjestys-/määrävuodon ja keskitetyn
laskurijaon tarpeen. Se vaatii silti kanonisen rekisteröinnin, uniikkiuden ja
kestävän auditoinnin. Suositus perustuu tähän tietomallivertailuun, ei väitteeseen
jo hyväksytystä standardista. Tutkijan/Data Stewardin vaihtoehtohyväksyntä
puuttuu. Lähdehashia ei suositella: se voi yhdistää viitteen tunnettuun lähteeseen.

#### Sidonta, yksikäsitteisyys ja elinkaari

Kumpikin vaihtoehto sitoo tokenin muuttumattomaan yhdistelmään: evidenssin
versio, varmennettava evidenssisuhde ja auktoriteetti-/rooliväite. Tarkka
lähdeidentiteetti ja versiotodiste pysyvät suojatussa kartoituksessa.
Repository-esityksen turvallisen roolin on vastattava suojattua sidontaa.

Rekisterimerkinnän hallinnollinen revisio ja tokenin evidenssiversio ovat eri
asioita. Käyttötilan/peruutuksen muutos lokitetaan, mutta samaa tokenia ei saa
suunnata eri evidenssiin tai rooliin. Uusi versio tai rooliväite saa uuden
viitteen ja suojatun supersession-suhteen. Vanhaa tokenia ei uudelleenkäytetä,
eikä kuluttaja seuraa korvaavaa viitettä automaattisesti. Säilytysaikaa ei
määritellä tässä; historiavaatimuksen toteutus tarvitsee säilytyspäätöksen.

Luontivaiheen token-törmäys ennen julkaisua hylkää varauksen; A:ssa voidaan
luoda uusi ehdokas. Julkaistun tokenin duplikaatti, myös näennäisesti identtinen,
tai ristiriitainen kartoitus on eheysvirhe: ei first-match-valintaa eikä
hiljaista deduplikointia. Koko riippuva varmennus pysähtyy korjausvaltuutukseen.

#### Repository-esitys ja auditointi

Sallittu ehdotettu esitys sisältää vain tokenin, hyväksytyn ei-arkaluontoisen
auktoriteetti-/lähderoolin, politiikan luokan, turvallisesti kuvatun tarkoituksen,
vaaditun pääsyportin ja väitekohtaisen varmennustilan. Token ei saa sisältää
source-digestiä tai toimia pääsyavaimena. Esitystä käytetään scope-mallissa
vain READ_REFERENCE_ONLY-roolissa, ei allowed_write_paths-kohteena.

Tehtäväkortit, paketit, promptit, lokit, manifestit, Knowledge, HOTL-metatieto
ja audit-evidenssi eivät saa sisältää osallistujarivejä, henkilöominaisuuksia,
PII/PHI:tä, salaisuuksia, credentialeja, suojattua lähdesisältöä, tunnistavia
nimiä, schema-/arvo-otteita, suojattua lähdepaikanninta tai paljastavaa
virhediagnostiikkaa. Lähdenimi/digest ei siirry niihin korvaavana tokenina.

Turvallinen audit-yhteenveto kirjaa tokenin vain hyväksytyn esityksen mukaan,
tehtävän ja kriteerin, operaation yleisen tyypin, aikaleiman, hyväksytyn
roolitason valtuutus-/tarkastustiedon, tuloksen ja ei-paljastavan syyluokan.
Tarkka lähde-/versiotodiste ja valtuutustiedot säilyvät suojatussa auditissa.
Ei lähteiden lukumääriä, vertailuarvoja tai poimittuja rivejä diagnostiikkaan.
Audit-tuloksen puuttuminen ei saa muuttua PASSiksi.

#### Suojatun resoluution semanttiset vaiheet

1. Tarkista tehtävä, tarkoitus, tunnisteen syntaksi ja erillinen ihmis-/data-
   ja käyttövaltuus. Tokenin tunteminen ei ole valtuus.
2. Varmista valtuutettu suojattu ympäristö ja tietoraja. Ilman niitä ei hakua.
3. Hae hyväksytystä kanonisesta kartoituksesta tokenin merkintä.
4. Vaadi täsmälleen yksi ehjä osuma; varmista rekisterin eheys ja elinkaaritila.
5. Vertaa pyydettyä auktoriteetti-/rooliväitettä suojattuun sidontaan.
6. Tarkista täsmällinen evidenssiversio ja vaadittu ajantasaisuus. Historiallinen
   versio kelpaa vain tehtävän nimenomaisesti pyytäessä sitä.
7. Ratkaise evidenssin käyttöoikeus erikseen luokituksesta, operaatiosta ja
   tehtävästä; luku-, muunnos-, vienti- tai suorituslupa ei seuraa viitteestä.
8. Tee vain valtuutettu tarkistus suojatussa ympäristössä soveltuvin tiede-/QC-
   portein. Raakadata säilyy read-only; julkinen tulos on väitekohtainen aggregaatti.
9. Tallenna suojattu auditoitava sidonta ja sallittu repository-yhteenveto
   hyväksyttyjen lokikäytäntöjen mukaan. Älä paljasta lähdettä virheen selvittämiseksi.

Nämä ovat määrittelyaskelia, eivät dereferointikomentoja tai ajovaltuutus.

#### Varmennus ja virhematriisi

PASS = nimetty kriteeri on varmennettu; FAIL = todettu ristiriita tai kieltorajan
rikkominen; NEEDS_VERIFICATION = varmennus puuttuu; NOT_APPLICABLE = perustellusti
ei sovellu. BLOCKED on riippuvan suorituksen tila, ei puuttuvan tiedon korvike.
Alla jokainen epäonnistunut kriittinen riippuvuus ilman auktoritatiivista
fallbackia tuottaa BLOCKED. Ei-kriittinen puute ei estä riippumatonta työtä.
Luvaton tai tietorajan rikkova operaatio estetään aina, kriittisyydestä riippumatta.

| Virhe                                                  | Varmennustulos / suoritus                                        | Sallittu diagnoosi                                          |
| ------------------------------------------------------ | ---------------------------------------------------------------- | ----------------------------------------------------------- |
| Tuntematon viite                                       | NEEDS_VERIFICATION; kriittinen BLOCKED                           | Tuntematon viite                                            |
| Duplikaattiosuma                                       | FAIL; riippuva käyttö BLOCKED                                    | Yksikäsitteisyysvirhe                                       |
| Vanhentunut versio                                     | FAIL; kriittinen BLOCKED                                         | Versiovaatimus ei täyty                                     |
| Auktoriteetti-/rooliristiriita                         | FAIL; kriittinen BLOCKED                                         | Auktoriteettisidonta ei täsmää                              |
| Luvaton kutsuja                                        | FAIL; operaatio BLOCKED ennen hakua                              | Valtuutus puuttuu; ei lähteen olemassaolotietoa             |
| Resolveri poissa käytöstä                              | NEEDS_VERIFICATION; kriittinen BLOCKED                           | Varmennuspalvelu ei käytettävissä                           |
| Suojattu ympäristö ei käytettävissä                    | NEEDS_VERIFICATION; operaatio BLOCKED                            | Hyväksytty ympäristö puuttuu                                |
| Peruutettu/invalidi viite                              | FAIL; operaatio BLOCKED                                          | Viite ei käyttökelpoinen                                    |
| Superseded-viite                                       | FAIL nykyistä evidenssiä vaadittaessa; kriittinen BLOCKED        | Versiovaatimus ei täyty; ei automaattista uudelleenohjausta |
| Vioittunut merkintä                                    | FAIL; riippuva käyttö BLOCKED                                    | Eheysvirhe                                                  |
| Yhteensopivuusristiriita                               | FAIL; kriittinen BLOCKED                                         | Legacy-sidonta ei täsmää                                    |
| Tietorajan ulkopuolinen kohde                          | FAIL; operaatio BLOCKED                                          | Valtuutettu tietoraja ei täyty                              |
| Diagnoosi edellyttäisi suojatun sisällön paljastamista | NEEDS_VERIFICATION; diagnoosi BLOCKED, kriittinen käyttö BLOCKED | Turvallista varmennusta ei saatavilla                       |

Superseded-viitteen historiallinen varmennus ei ohita peruutusta tai pääsyportteja.
FAIL/NEEDS_VERIFICATION ei oikeuta automaattiseen tietueen korjaukseen.

#### Legacy-yhteensopivuus

Luokittelu perustuu vain nykyisten hyväksyttyjen dokumenttien pointer-muotoihin,
ei suojatun aineiston tai DENY-Registry-sisällön avaamiseen.

| Nykyinen muoto / rajaus                                        | Yhteensopivuus                   | Myöhempi edellytys                                                                 |
| -------------------------------------------------------------- | -------------------------------- | ---------------------------------------------------------------------------------- |
| KB:n hyväksytty domain-dokumenttilinkki                        | DIRECTLY_COMPATIBLE reitityksenä | Ei itsessään uuden tokenin resoluutio                                              |
| Symbolinen lähderooli                                          | REQUIRES_ADAPTER                 | Valtuutettu täsmäversio-/roolikartoitus; roolinimeä ei arvata tokeniksi            |
| Suora lähdenimi tai suhteellinen lähdepolku DATA_DICTIONARYssa | NEEDS_VERIFICATION               | Jakelulupa ja korvaava sidonta ratkaistava erikseen                                |
| Nykyinen lähdedigest-versionosoitus                            | REQUIRES_MIGRATION               | Säilytä auditability suojatulla hyväksytyllä sidonnalla; digest ei muutu tokeniksi |
| Absoluuttinen suojattu paikannin tai suojattu ote              | UNSAFE_TO_EXPOSE                 | Ei kopiointia; nykyinen kielto, ei väite uudesta havainnosta                       |
| Viite Registry-evidenssidokumenttiin                           | NEEDS_VERIFICATION               | Kohde DENY; kattavuutta/korvaavuutta ei tarkistettu                                |
| Repoartefaktin manifesti-/ajotunniste                          | REQUIRES_ADAPTER                 | Varmista tarkka evidenssi-/versiosuhde ja jakelulupa, ei automaattista muunnosta   |

Adapter- ja migraatioluokat kuvaavat suunnittelutarvetta, eivät lupaa lukea
kohdetta tai korjata vanhaa viitettä. Vanhoja viitteitä ei muuteta tässä.

#### Seitsemän hyväksymisporttia

Jokaiselle portille kirjataan erikseen määrityksen kattavuus ja myöhemmän
mekanismin ajonäyttö. Nykyinen ajonäyttö on kaikille NEEDS_VERIFICATION:
mekanismia ei ole toteutettu tai käytetty.

| Portti                          | PASS                                                                 | FAIL                                                                                                         | NEEDS_VERIFICATION                           |
| ------------------------------- | -------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ | -------------------------------------------- |
| DISTRIBUTION_SAFETY             | Hyväksytty esitys ja diagnostiikka eivät paljasta suojattua sisältöä | Suojattua payloadia tai paljastava token                                                                     | Esityksen jakelulupa/tarkistus puuttuu       |
| RESOLUTION_UNIQUENESS           | Täsmälleen yksi ehjä kanoninen sidonta                               | Duplikaatti tai ristiriitainen sidonta                                                                       | Haku tai eheysvarmennus ei saatavilla        |
| AUTHORITY_BINDING               | Tehtävän rooli ja evidenssisuhde vastaavat suojattua versiota        | Väärä rooli tai versio                                                                                       | Auktoriteetti-/versiotodiste puuttuu         |
| ACCESS_SEPARATION               | Viite ei myönnä käyttöä; erillinen valtuus ja ympäristö tarkistettu  | Token ohittaa portin tai antaa kirjoitus-/vientiluvan                                                        | Valtuutuksen/ympäristön varmennus puuttuu    |
| AUDITABILITY                    | Sidonta, valtuutus ja varmennus rekonstruoitavissa suojatusti        | Sidonta häviää tai audit paljastaa sisältöä                                                                  | Omistaja, tietue tai audit-evidenssi puuttuu |
| BACKWARD_COMPATIBILITY          | Nimetty legacy-sidonta säilyy hyväksytysti                           | Hiljainen uudelleentulkinta tai väärä kohde                                                                  | Kartoitus/legacy-tarkistus tekemättä         |
| SCIENTIFIC_SEMANTIC_EQUIVALENCE | Vain osoitusmekaniikka muuttuu                                       | Merkitys, evidenssirooli, scoring, inclusion/exclusion, kandidaattipäätös, QC tai hyväksymiskriteeri muuttuu | Domain ownerin vertailu puuttuu              |

Tieteellinen portti säilyttää lisäksi valid/missing-erot, ajoituksen,
derivointiketjun ja avoimien tutkijapäätösten tilan. Tekstisamankaltaisuus,
onnistunut lookup tai hash ei yksin todista tieteellistä ekvivalenssia.

#### Synteettiset esimerkit ja käyttöönoton päätökset

Kelvollinen A-vaihtoehdon repository-esitysesimerkki (ei oikea varaus):

```text
reference: FIRA1-PER-R1-0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
classification: PROTECTED
authority_role: DATA_DICTIONARY
purpose: ajoitussemantiikan valtuutettu tarkistus
access_gate: erillinen ihmis- ja datankäyttövaltuus
verification: NEEDS_VERIFICATION
```

Token on käsin rakennettu testiarvo, ei tuotantogeneraattorin satunnaisuusnäyttö.
Esitys on suunnitelman mukainen; se ei väitä olemassa olevaa suojattua sidontaa.

Virheellinen täysin synteettinen esimerkki:

```text
reference: ESIMERKKI-HENKILO-000-POTILASRIVI
payload: KUVITTEELLINEN_OSALLISTUJARIVI_TAHAN
```

Hylkäys: väärä syntaksi, tunnisteeseen koodattu henkilökytkentä ja suojatun
payloadin upotusyritys. Paikkamerkit eivät sisällä oikeita henkilö-/lähdearvoja.

Ennen toteutustehtävän luontia tarvitaan tutkijan/Data Stewardin nimenomainen
A- tai B-vaihtoehdon hyväksyntä. Lisäksi ratkaistaan operatiivinen rekisteriomistaja,
luonti-/päivitys-/peruutusvaltuudet, suojattu sijainti ja ympäristömenettely,
rekisterin eheys ja saatavuus, säilytys-/historiavaatimukset, turvallinen
julkinen roolisanasto ja audit-esitys sekä legacy-sidontojen varmennus.
Näiden tila on NEEDS_VERIFICATION, ei agentin hiljainen toteutuspäätös.

DATA_DICTIONARY-remediaatio ja tracking-migraatio säilyvät erillisinä.
GENERAL_FI:n muu työ voi jatkua omilla valtuuksillaan, ellei sen konkreettinen
tehtävä tarvitse tämän mekanismin suojattua dereferointia. Tämä määrittely
ei muuta recovery-statuksia, tiedepäätöksiä tai QC-sääntöjä.

### Step 3: hyväksytyn R1-tunnisteen rekisteritoimintamalli

Prompt 26 ja omistajan A-hyväksyntä ratkaisevat Step 2:n vaihtoehtovalinnan.
A on hyväksytty tunnisteformaatti, B jää vertailuhistoriaksi. Tämä osio ohittaa
aiemmat A-valintaa odottavat merkinnät vain formaatin osalta. Toimintamalli on
PARTIAL: operatiivinen omistaja ja tarkka suojattu sijoitus ovat edelleen
NEEDS_VERIFICATION. Määrittelyn katselmointi ei ole rekisterin käyttöönotto.

#### REGISTRY_IDENTIFIER_CONTRACT

Hyväksytty muoto on `FIRA1-PER-R1-` ja täsmälleen 64 heksamerkkiä.
Aiemman A-määrittelyn kanoninen esitys käyttää pieniä `0–9a–f`-merkkejä;
isoja kirjaimia ei hiljaisesti normalisoida. R1 on mekanismin versiomerkki,
ei evidenssin versio tai käyttöoikeus.

Loppuosa on lähteestä riippumatonta satunnaismateriaalia, ei SHA-256.
Siihen ei koodata henkilöä, päivää, diagnoosia, muuttujaa, lähdenimeä, polkua,
salaisuutta tai muuta sisältöä. Syntaksin hyväksyntä ei todista olemassaoloa,
yksikäsitteisyyttä, käyttövaltuutta tai varmennusta.

Uniikkius vaaditaan kanonisessa rekisterissä ennen varauksen julkaisemista.
Törmäys hylkää uuden varauksen; uusi ehdokas voidaan myöhemmin luoda vain
valtuutetussa luontioperaatiossa. Jo julkaistun tunnisteen duplikaatti tai
ristiriita pysäyttää riippuvan käytön. Vanhaa sidontaa ei muuteta, yhdistetä
hiljaisesti tai valita ensimmäistä osumaa. Tämä ei määrää tallennusteknologiaa.

#### OPERATIONAL_OWNER ja PROTECTED_PLACEMENT

WORKFLOWn Human Supervisor hyväksyy tehtävät; Owner/Data Steward omistaa
puuttuvat jakelu- ja datankäyttöpäätökset. Nämä politiikkaroolit eivät yksin
nimeä operatiivista rekisterivastuullista tai teknistä ylläpitäjää.
Vastuullinen operatiivinen omistaja, tekninen säilyttäjä ja delegointiketju:
NEEDS_VERIFICATION. FIRA1:n tieteellinen domain owner ei automaattisesti saa
rekisterin ylläpito-oikeutta.

Tunnisteen ja suojatun evidenssin kartoituksen sallittu sijoitusluokka on
PROTECTED, nykyisen työnkulun suojatun DATA_ROOT-rajan sisällä. Tämä ei ole
lupa valita hakemistoa tai avata DATA_ROOTia. Tarkka paikka, palveluympäristö,
säilytys, varmistus, salaustapa ja credential-/access-control-toteutus jäävät
NEEDS_VERIFICATION-tilaan. Niitä ei päätellä koneelta löytyvistä tiedostoista.

Kartoitus ei kuulu tavalliseen Knowledgeen, Gitiin, taskiin, promptiin,
manifestiin, raporttiin, lokiin tai HOTL-pakettiin. Git-ignored ei itsessään
ole suojattu säilytysratkaisu. Politiikan PROTECTED-etusija ja DENY-oletus säilyvät.

#### MAINTENANCE_AUTHORITY_MATRIX

Alla on hyväksyntävaatimus, ei myönnetty oikeus nimetylle käyttäjälle.
Operatiivisten suorittajaroolien nimeäminen jää ihmisen päätökseksi.

| Toimi             | Hyväksyvä auktoriteetti / suorittaja                                                | Ehto ja raja                                                                                                               |
| ----------------- | ----------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| CREATE_REFERENCE  | Owner/Data Stewardin hyväksymä tehtävä; ylläpitäjä NEEDS_VERIFICATION               | Tieteellinen roolisidonta domain ownerilta, erillinen suojatun lähteen käyttövaltuus ja uniikkiustarkistus ennen julkaisua |
| RESOLVE_REFERENCE | Tehtäväkohtainen ihmis-/data-access-valtuus; valtuutettu tarkastaja erikseen        | Vain hyväksytty tarkoitus ja ympäristö; ei kirjoitus- tai vientilupaa                                                      |
| UPDATE_METADATA   | Owner/Data Stewardin hyväksymä rajattu ylläpitotoimi; ylläpitäjä NEEDS_VERIFICATION | Vain sidontaa muuttamaton metadata; revisio ja syy auditoitava                                                             |
| REBIND_REFERENCE  | DEFAULT_DENY                                                                        | Turvallista uudelleensidontamenettelyä ei ole auktorisoitu; eri evidenssi/versio/rooli tarvitsee uuden viitteen            |
| RETIRE_REFERENCE  | Owner/Data Stewardin eksplisiittinen päätös; ylläpitäjä NEEDS_VERIFICATION          | Estää tulevan käytön, säilyttää auditoitavuuden eikä anna poistamislupaa                                                   |
| AUDIT_REFERENCE   | Erillinen suojatun auditoinnin valtuus; tarkastajarooli NEEDS_VERIFICATION          | Vain hyväksytty auditointitarve; repositoryyn turvallinen yhteenveto                                                       |

Tekninen säilyttäjä ei saa pelkän säilytysroolin perusteella muuttaa
lähdeauktoriteettia tai hyväksyä tieteellistä väitettä. Tutkijan hyväksyntä
sisällölliselle roolille ei poista erillistä datankäyttöporttia.

#### REGISTRY_METADATA_CONTRACT

Seuraavat ovat suojatun kartoituksen semanttiset vähimmäistiedot, eivät
käyttöönotettu skeema tai kenttien jakelulupa. Tietojen tarkka rakenne ja
varmennusmenettely ovat NEEDS_VERIFICATION ennen toteutusta.

| Tieto                                        | Tarkoitus ja rajaus                                                                                                              |
| -------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| R1-tunniste ja sopimusversio                 | Yksikäsitteinen viite; ei lähdeidentiteettiä koodaava                                                                            |
| Lähdeidentiteetti ja evidenssisuhde          | Oikean auktoritatiivisen kohteen yksilöinti suojatusti; ei participant-rivien kopiointia rekisteriin                             |
| Evidenssiversio ja vaadittu versiotodiste    | Muuttumaton sidonta; digest vain olemassa olevan governance-vaatimuksen mukaan, ei uusi hash-konventio                           |
| Suojattu paikannin                           | Vain hyväksytyn rajan sisäinen ratkaiseminen; tarkka sijoitus avoin                                                              |
| Auktoriteetti-/lähderooli ja luokitus        | Rooli-/evidenssisuhteen sekä käyttörajan varmennus                                                                               |
| Elinkaaritila ja hallinnollinen revisio      | Nykyinen käyttökelpoisuus, päivitys-/retirement-historia, mahdollinen supersession-suhde; ei hiljaista uudelleensidontaa         |
| Luonti-/muutos-/retirement-valtuutus ja aika | Kuka oli valtuutettu, mitä hyväksyttiin ja milloin; tarkka henkilöllisyys-/valtuutustieto vain hyväksytyssä suojatussa auditissa |
| Varmennusevidenssi ja tila                   | Väitekohtainen tarkistus, menetelmä, tulos ja turvallinen ulkoinen yhteenveto; ei tarpeettomia payload-kopioita                  |

Ulkopuolelle saa vain hyväksytyn opaakin tunnisteen ja eksplisiittisesti
hyväksytyn ei-arkaluontoisen rooli-, tarkoitus-, portti- ja tulosmetadatan.
Formaattipäätös ei yksin hyväksy kaikkia lisämetatietoja tai lähteen jakelua.
Metadata, jonka turvallisuus tai merkitys on epäselvä, jätetään ulkoisesta
esityksestä pois ja merkitään NEEDS_VERIFICATION.

#### DEREFERENCE_GATE ja AUDIT_CONTRACT

Resoluution jokainen käyttökerta tarvitsee erillisen tehtävä-, tarkoitus-,
ihmis-/data-access- ja ympäristövaltuutuksen. Tunnisteen hallussapito ei riitä.
Step 2:n authorization → ympäristö → lookup → uniqueness → authority/version
→ access decision → valtuutettu tarkistus → audit -järjestys säilyy.
Raakadata pysyy read-only. Tulevan tieteellisen käytön QC arvioidaan erikseen.

SKILLSin aikaleimaloki, Contributingin turvallinen artefaktilokitus ja Securityn
salassapitorajat edellyttävät seuraavia semanttisia audit-ominaisuuksia;
niiden tekninen toteutus, säilytysaika ja auditoijan oikeudet ovat avoimia.

| Tapahtuma                | Suojatusti rekonstruoitava näyttö                             | Sallittu ulkoinen näyttö                                                   |
| ------------------------ | ------------------------------------------------------------- | -------------------------------------------------------------------------- |
| Luonti                   | Hyväksyntä, tekijän valtuus, uniikkius ja muuttumaton sidonta | Hyväksytty viite, kriteeri, aika ja tulos                                  |
| Resoluutio               | Käyttölupa, rooli-/versiotarkistus ja operaation rajaus       | Kriteerikohtainen PASS/FAIL/NEEDS_VERIFICATION; ei kohdetietoja            |
| Metadatapäivitys         | Hyväksyntä, revisio, muutoksen syy ja sidonnan säilyminen     | Turvallinen operaatioluokka ja tulos                                       |
| Estetty pääsy            | Eston syy ja valtuutustarkistus ilman tarpeetonta kohdehakua  | Pääsy estetty; ei lähteen olemassaoloa tai sisältöä paljastavaa diagnoosia |
| Retirement               | Päätös, tila-/aikamuutos ja historiallinen sidonta            | Viite ei käyttökelpoinen; ei poistettua payloadia                          |
| Uudelleensidonnan yritys | Estetty toimi ja eheyden tarkistus                            | Uudelleensidonta estetty; ei ehdotettua kohdetta                           |

Audit-merkintä ei saa vuotaa protected-mappingia virheen, historian tai diffien
kautta. Auditin puuttuminen ei ole PASS. Retirement ei ratkaise datan tai
historian poistamista; säilytys-/poistopäätös tarvitaan erikseen.

#### FAILURE_SEMANTICS

FAIL tarkoittaa todettua virhettä, NEEDS_VERIFICATION puuttuvaa varmennusta ja
BLOCKED riippuvan suorituksen estoa. PASS voidaan antaa vain nimetylle
onnistuneelle tarkistukselle. Kaikki kriittiset epäonnistumiset ilman
auktoritatiivista fallbackia estävät suorituksen; ei-kriittinen puute sallii
vain siitä riippumattoman hyväksytyn työn.

| Tilanne                              | Tarkistustulos            | Toiminta ja turvallinen diagnoosi                                         |
| ------------------------------------ | ------------------------- | ------------------------------------------------------------------------- |
| Virheellinen syntaksi                | FAIL                      | Ei lookupia; tunnisteformaatti virheellinen                               |
| Tuntematon tunniste                  | NEEDS_VERIFICATION        | Kriittinen BLOCKED; ei laajaa kohdehakua                                  |
| Törmäys/duplikaatti                  | FAIL                      | Luonti/resoluutio BLOCKED; uniikkiusvirhe, ei uudelleensidontaa           |
| Luvaton dereferointi                 | FAIL                      | Operaatio aina BLOCKED ennen kohdehakua; valtuus puuttuu                  |
| Suojattu rekisteri/ympäristö puuttuu | NEEDS_VERIFICATION        | Ei dereferointia; kriittinen BLOCKED, ympäristö ei käytettävissä          |
| Retired/peruutettu viite             | FAIL käyttökelpoisuudelle | Käyttö BLOCKED; erikseen hyväksytty historiatarkastus ei aktivoi viitettä |
| Moniselitteinen kartoitus            | FAIL                      | Resoluutio BLOCKED; sidonta ei yksikäsitteinen                            |
| Eheysvirhe                           | FAIL                      | Resoluutio BLOCKED; eheyttä ei voi vahvistaa                              |
| Tuntematon sopimusversio             | NEEDS_VERIFICATION        | Ei tulkintaa R1:nä; kriittinen BLOCKED                                    |

Tuntematon tunniste ei anna lupaa etsiä lähdettä muista hakemistoista tai
avata suojattuja tietueita diagnoosin vuoksi. Epäonnistuneen viitteen
kirjoittaminen lokiin edellyttää myös syötteen turvallisuutta; paljastavaa
virhesyötettä ei toisteta.

#### COMPATIBILITY_CONTRACT

- Task-kortti ja Knowledge käyttävät vain hyväksyttyä turvallista esitystä.
  Tunniste ei korvaa puuttuvaa evidenssisidontaa eikä anna jakelulupaa.
- HOTL-scope käsittelee viitteen READ_REFERENCE_ONLY-riippuvuutena erillään
  allowed_write_pathsista. Ei automaattista poluksi muuntamista.
- Validation-evidenssi sitoo tuloksen hyväksymisväitteeseen; syntaksin PASS
  ei merkitse resoluution, tieteellisen validiteetin tai pääsyn PASSia.
- R1 on eksplisiittinen sopimusversio. Tuntematonta versiota ei hyväksytä
  parhaalla arvauksella eikä muunneta hiljaisesti. Uuden version syntaksia
  ei määritellä tässä; tuleva versio tarvitsee oman yhteensopivuuspäätöksen.
- Vanha lähdepolku, digest, manifesti- tai Registry-pointer ei muutu R1:ksi
  nimeämällä. Step 2:n adapter-/migraatioluokitus säilyy. Historiallinen
  sidonta on varmennettava suojatusti ennen korvaamista ja valtuutettava erikseen.
- DATA_DICTIONARY-remediaatio tarvitsee edelleen auditabilityn säilyttävän
  korvausmenettelyn sekä DISTRIBUTION_SAFETY- ja SCIENTIFIC_SEMANTIC_EQUIVALENCE-portit.
  Tässä ei korjata lähdeviitteitä, päivitetä Registryä tai toteuteta migraatiota.

#### Synteettiset toimintamalliesimerkit

Esimerkkitoken: `FIRA1-PER-R1-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa`.
Se on käsin kirjoitettu testipaikkamerkki, ei generoitu tai rekisteröity
viite eikä väite yhteydestä mihinkään evidenssiin. Syntaksi PASS; olemassaolo
NEEDS_VERIFICATION; dereferointivaltuus puuttuu, joten käyttö BLOCKED.

Esimerkkitoken `FIRA1-PER-R1-ESIMERKKI` epäonnistuu syntaksissa: FAIL, ei hakua.
Kuvitteellinen kahden kartoitusosuman tapaus on uniikkius-FAIL ja käyttö BLOCKED;
yhtään kartoitusta tai payloadia ei luoda tai esitetä esimerkissä.

#### IMPLEMENTATION_PREREQUISITES ja NEXT_RECOMMENDED_TASK

Toimintamalli on osittainen, koska nykyinen auktoriteetti ei nimeä operatiivista
omistajaa. Ennen toteutusta Owner/Data Stewardin tulee ratkaista:

1. vastuullinen operatiivinen omistaja, tekninen säilyttäjä ja delegoitavat
   create/resolve/update/retire/audit-roolit;
2. täsmällinen suojattu sijoitus ja hyväksytty käyttöympäristö;
3. metadata-/käyttörajapinta, hyväksytty ulkoinen metadata ja auditin todentaminen;
4. auditin säilytys ja poistovaltuudet sekä muut storage-/backup-/access-control-
   päätökset olemassa olevan tietoturva-auktoriteetin mukaisesti;
5. legacy-sidontojen hyväksytty yhteensopivuus- ja myöhempi remediaatiomenettely.

Seuraava suositeltu tehtävä on näiden toimintamallipäätösten hyväksyntä,
ei rekisterin toteutus. Tunnisteformaattia ei tarvitse hyväksyä uudelleen.
Implementation-, dereference-, DATA_DICTIONARY-, tracking- ja HOTL-enforcement-
valtuudet säilyvät erillisinä. Muu GENERAL_FI-työ ei riipu tästä ilman
tehtäväkohtaista todellista evidenssiriippuvuutta.

### DATA_DICTIONARYn staattinen provenienssisilta

Omistajan promptissa 32 hyväksymä ja promptissa 33 vahvistama linja on
AVOID_PRODUCTION_R1_FOR_DATA_DICTIONARY. Tämän käyttötapauksen korjaus ei
edellytä tuotanto-R1:tä, online-resolveria tai automaattista dereferointia.
Tämä osio omistaa käyttötapauksen staattisen sopimuksen ja ohittaa aiempien
R1-osioiden resolveriedellytyksen vain DATA_DICTIONARYn korjauspolulla.
R1 jää mahdolliseksi erikseen arvioitavaksi muuksi työksi.

Määrittely ei hyväksy yksittäisen viitteen jakelua, tietueen luontia,
DATA_DICTIONARYn muokkausta, legacy-korvausta tai tracking-migraatiota.
PROTECTED-etusija ja DENY_UNCLASSIFIED säilyvät. Git-seuranta ei määrää
sisällön herkkyyttä tai auktoriteettia.

#### GIT_VISIBLE_REFERENCE_CONTRACT

Vähimmäisesitys on vakaa, ei-paljastava ja ei-semanttinen evidenssiviite
liitettynä dokumentin täsmälliseen provenance-väitteeseen. Se ei ole linkki
suojattuun tiedostojärjestelmään eikä lupaus automaattisesta hausta.
Se ei saa koodata lähdeidentiteettiä, polkua, henkilöä, schemaa, diagnoosia,
salaisuutta tai muuta protected-semanttiikkaa. Näkyvä viite ei saa vaihtaa
kohdeversiota tai evidenssisuhdetta hiljaisesti.

Viite ei myönnä pääsyä tai lähteen uudelleenjakeluoikeutta. Token tai digest
voi yksilöidä vain sen, mihin hyväksytty suojattu tietue sen sitoo; se ei
yksin todista auktoriteettia, eheyttä tai tieteellistä ekvivalenssia.

Nykyinen päätös ei määrää static-bridge-syntaksia eikä nimenomaisesti hyväksy
R1-formaatin uudelleenkäyttöä tähän. Siksi konkreettinen esitys/syntaksi ja
sen jakeluhyväksyntä ovat NEEDS_VERIFICATION. Uutta tunnisteavaruusta,
URI:a tai hash-konventiota ei määritellä. Viitteen lisäksi julkaistaan vain
erikseen hyväksyttyä turvallista kontekstia; protected-only-kenttiä ei kopioida.

#### PROTECTED_CANONICAL_RECORD_CONTRACT

Kanoninen suojattu tietue säilyttää viitteen ja väitteen evidenssisidonnan
rekonstruoitavana ilman repositoryyn kopioitavaa mappingia. Owner/Data Steward
omistaa tietueen governance-/jakelu-/käyttövaltuuden; FIRA1:n asianomainen
domain owner varmentaa lähderoolin ja semanttisen suhteen. Nimetty operatiivinen
tietueomistaja, hyväksytty olemassa oleva tietue, sen säilytys ja tarkka
sijoitus ovat NEEDS_VERIFICATION. Tässä ei luoda uutta rekisteriä tai backendia.

| Suojattu vähimmäistieto                           | Tarve ja auktoriteetti                                                                    |
| ------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| Viiteidentiteetti                                 | Yksikäsitteinen yhteys Git-esitykseen ja nimettyyn provenance-väitteeseen                 |
| Suojattu lähdeidentiteetti                        | Saman auktoritatiivisen evidenssin todentaminen; ei source-nimeä Git-esitykseen           |
| Täsmällinen evidenssiversio / muuttumaton revisio | Ei hiljaista latest-versiota; tarvittava versiotodiste nykyisen lähdeauktoriteetin mukaan |
| Evidenssin rooli ja auktoriteetti-/lähderooli     | KB_INDEXin domain ownership sekä DATA_DICTIONARYn source-routing                          |
| Muuttuja-/semanttinen suhde                       | Merkitys, suunta, tieteellisesti tarvittavat valid/missing-erot ja timing säilyvät        |
| Derivointiketju ja evidenssisuhde                 | Sama lähde → derivointi → väite -suhde ilman uusia tieteellisiä tulkintoja                |
| Varmennustila ja historia                         | Tarkastus, valtuutus ja tulos rekonstruoitavissa suojatusti                               |
| Tutkijapäätöksen tila tarvittaessa                | Hyväksytty operationalisointi ja avoimet päätökset pysyvät erillään; GENERAL_FI ei muutu  |

Taulukko määrittää semanttiset vaatimukset, ei oikeita kenttäarvoja tai
valmista tallennusskeemaa. Puuttuvan kentän toteutus, lähdekohtainen
versiotodiste tai todentamaton sisältö merkitään NEEDS_VERIFICATION.
Protected-only-tiedot ja tarkka legacy-/uusi-viite-kartoitus pysyvät suojattuina.
Tietueen olemassaoloa tai riittävyyttä ei oleteta muiden tehtävien maininnoista.

#### AUTHORIZED_OFFLINE_VERIFICATION_PROCEDURE

1. Hyväksy yksi tehtävä tai vastaava täsmällinen tarkoitus, suojatun tiedon
   käyttövaltuus ja hyväksytty ympäristö. Nimeä asianmukainen valtuutettu
   tarkastaja sekä tieteellisen/domain-väitteen verifier-rooli.
2. Varmista, että tarkoitus osoittaa kanoniseen suojattuun tietueeseen.
   Puuttuva tietue ei oikeuta laajaan lähdehakuun tai sopivan lähteen arvailuun.
3. Vertaa Git-viiteidentiteettiä tietueeseen ja vaadi yksikäsitteinen sidonta.
   Tarkista täsmällinen evidenssi, versio ja authority/role-suhde suojatusti.
4. Tarkista evidenssin identiteetti ja eheys. Tee tästä erillinen tulos;
   hash-/identiteettiosuma ei ole tieteellisen semantiikan hyväksyntä.
5. Domain verifier vertaa merkitystä, valid/missing-eroja, suuntaa, ajoitusta,
   lineagea ja päätöstilaa kyseisen DATA_DICTIONARY-väitteen tarpeisiin.
6. Säilytä tarkka näyttö ja valtuutus hyväksytyssä suojatussa tietueessa tai
   siihen kuuluvassa nykyisessä audit-menettelyssä. Sen riittävyys on
   osoitettava ennen PASSia; tässä ei rakenneta uutta audit-palvelua.
7. Palauta repositoryyn vain alla määritelty turvallinen väitekohtainen tulos.
   Suojattua sisältöä ei paljasteta myöskään virheen diagnosoimiseksi.

Menettely on offline-tarkastuksen sopimus, ei datankäyttökomento tai uusi lupa.
Puuttuva ympäristö tai valtuutus estää tarkastuksen. Tulevan todellisen
operaation tiede-/QC-portit arvioidaan erikseen; raakadata säilyy read-only.

#### SAFE_VERIFICATION_RESULT_CONTRACT

| Ulkoinen metatieto            | Sallittu rajaus / perusta                                                                                |
| ----------------------------- | -------------------------------------------------------------------------------------------------------- |
| Viite-ID                      | Vain hyväksytty ei-paljastava esitys; syntaksipäätös vielä avoin                                         |
| Varmennuksen aikaleima        | SKILLSin tehtäväloki; tarkastusaika, ei lähteen tai osallistujan tapahtumapäivä                          |
| Verifier-rooli                | Hyväksytty ei-arkaluontoinen domain-/tarkastajarooli; ei credentialia tai suojattua henkilöllisyystietoa |
| Väite/kriteeri                | Tehtävän ei-paljastava hyväksymiskriteeri, kuten provenance- tai semanttisen ekvivalenssin tarkistus     |
| Tila ja turvallinen syyluokka | PASS/VERIFIED, FAIL, NEEDS_VERIFICATION tai perusteltu NOT_APPLICABLE                                    |

Aikaleima riittää tämän abstraktin tulosrakenteen ajalliseksi kentäksi;
uutta julkista revisionumerojärjestelmää ei keksitä. Protected-revisiohistoria
säilyy suojatusti. Tulos ei sisällä lähdeidentiteettiä, polkua, digestiä,
participant-tietoa, schema-/arvo-otteita tai payloadia. Aggregaattisuus ei
yksin takaa turvallisuutta: tunnistavia yhdistelmiä ei saa sisällyttää.

PASS/VERIFIED koskee vain nimettyä tarkistusta ja vaatii näyttöä. FAIL tarkoittaa
todettua poikkeamaa, NEEDS_VERIFICATION puuttuvaa varmennusta. NOT_APPLICABLE
vaatii perusteen eikä sovi pakollisen legacy-ekvivalenssin kiertämiseen.
BLOCKED kirjataan riippuvan suorituksen tilaksi erilleen väitteen tuloksesta.

#### LEGACY_EQUIVALENCE_PROCEDURE ja DISTRIBUTION_SAFETY_BOUNDARY

Vanha lähdenimi-/polku-/digest-/provenienssisidonta voidaan ehdottaa korvattavaksi
vain yksi viite kerrallaan. Tarkastaja todentaa valtuutetusti, että vanha sidonta
ja uusi staattinen viite osoittavat samaan auktoritatiiviseen evidenssiin,
täsmäversioon ja roolisuhteeseen. Säilytä tieteellinen merkitys ja suojattu
vertailunäyttö. Ei bulk-, heuristiikka-, nimi-, polku- tai digest-only-migraatiota.

Moniselitteinen, puuttuva, ristiriitainen tai todentamaton legacy-sidonta jää
NEEDS_VERIFICATION-tilaan. Todettu ristiriita voidaan lisäksi kirjata kyseisen
vertailutestin FAILiksi. Kriittinen korvaus pysyy BLOCKED; mitään viitettä ei
poisteta vain siksi, että sitä on vaikea jakaa tai todentaa.

SCIENTIFIC_SEMANTIC_EQUIVALENCE vaatii saman lähdeauktoriteetin, evidenssisuhteen,
muuttujamerkityksen, suunnan, valid/missing-semanttiikan, ajoituksen, derivoinnin,
GENERAL_FI-semanttiikan ja tutkijapäätösten tilan. Jakeluturvallinen teksti ei
itsessään läpäise tätä porttia.

DISTRIBUTION_SAFETY arvioi esityksen erikseen kohteen hyväksyttyä jakeluluokkaa
vasten. Tieteellisesti oikea mutta jakeluun hyväksymätöntä sisältöä paljastava
esitys on FAIL. Luokittelematon tai epäselvästi hyväksytty esitys ei saa PASSia.
Tämä määrittely ei muutu luokittelupolitiikan poikkeukseksi.

#### FAILURE_SEMANTICS: staattinen silta

| Tilanne                                  | Varmennustila ja toimintaraja                                                                         |
| ---------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Virheellinen viite                       | FAIL vain hyväksyttyä syntaksia vasten; syntaksisopimuksen puuttuessa NEEDS_VERIFICATION, ei arvausta |
| Tuntematon viite                         | NEEDS_VERIFICATION; ei laajaa lähdehakua                                                              |
| Kanoninen suojattu tietue puuttuu        | NEEDS_VERIFICATION; ei korvaavan lähteen keksimistä                                                   |
| Valtuutettu ympäristö ei käytettävissä   | NEEDS_VERIFICATION; tarkastus estyy                                                                   |
| Luvaton tarkastusyritys                  | Pääsyportti FAIL ja tarkastus BLOCKED ennen suojattua lookupia                                        |
| Evidence/version/role ei täsmää          | Vertailu FAIL, sidonta NEEDS_VERIFICATION korvausta varten                                            |
| Legacy-sidonta moniselitteinen           | NEEDS_VERIFICATION, ei ensimmäisen osuman valintaa                                                    |
| Semanttisen ekvivalenssin näyttö puuttuu | NEEDS_VERIFICATION, ei päätelmää hashista tai tekstisamankaltaisuudesta                               |
| Jakeluluokitus/hyväksyntä avoin          | NEEDS_VERIFICATION, ei julkaisu- tai tracking-lupaa                                                   |

Jokainen ratkaisematon execution-critical väite ilman auktoritatiivista
fallbackia tekee riippuvan korjauksen BLOCKED-tilaiseksi. Ei-kriittinen
NEEDS_VERIFICATION sallii vain siitä riippumattoman hyväksytyn työn.
Fallbackin auktoriteetti on osoitettava, eikä se saa heikentää tiede- tai
jakeluvaatimusta. Luvaton tarkastus estetään aina riippumatta kriittisyydestä.

#### SYNTHETIC_EXAMPLES

Kelvollinen rakenteellinen esimerkki: kuvitteellisessa erikseen hyväksytyssä
ympäristössä dokumentin ei-paljastava staattinen viite liittyy yhteen
kanoniseen suojattuun tietueeseen. Valtuutettu domain-tarkastaja varmentaa
saman evidenssin/version/roolin ja kirjaa turvallisen tuloksen:

```text
reference_identity: [HYVAKSYTYN_VIITTEEN_SYNTEETTINEN_PAIKKAMERKKI]
verifier_role: valtuutettu domain-tarkastaja
claim: evidenssi/version/roolin vastaavuus
status: PASS
verification_time: [TARKASTUSAIKA]
```

Hakasulkeet ovat havainnollistavia paikkamerkkejä, eivät ehdotettu syntaksi,
oikeita tunnisteita tai suoritettua varmennusta. Esimerkki on kelvollinen
sopimusmallina vain mainituin hyväksyntä-/näyttöehdoin; nykyistä sitomatonta
viitettä ei merkitä PASSiksi.

Virheellinen synteettinen esimerkki: viitteeksi annetaan
`[SUOJATTU_LAHDENIMI_JA_POLKU]` ja tuloslokiin liitetään `[OSALLISTUJARIVI]`.
Molemmat ovat pelkkiä paikkamerkkejä; rakenne hylätään, koska se siirtäisi
suojatun paikantimen ja payloadin repositoryyn. Oikea tieteellinen tulos ei
korjaa jakeluvirhettä.

#### OPEN_VERIFICATIONS ja tuleva porttijärjestys

Vielä NEEDS_VERIFICATION: hyväksytty konkreettinen Git-viite-esitys,
kanonisen suojatun tietueen yksilöinti ja vastuullinen säilyttäjä,
tarvittavien täsmäkenttien saatavuus ja versiotodiste, hyväksytty
suojattu offline-tarkastusympäristö/valtuutus sekä todellinen legacy-sidonta.
Nämä eivät estä määrittelyn katselmointia mutta estävät nykyisen provenance-
esityksen korvaamisen ilman seuraavaa täsmävaltuutusta ja näyttöä.

Tuleva järjestys on: staattisen korvausesityksen ehdotus → suojattu
legacy-ekvivalenssin varmennus → SCIENTIFIC_SEMANTIC_EQUIVALENCE →
DISTRIBUTION_SAFETY → review → erillinen tracking-migraatiopäätös.
Ehdotus ei tarkoita toteutettua korvausta tai vanhan evidenssin poistamista.

Seuraava suositeltu tehtävä on avoimen viite-esityksen, olemassa olevan
kanonisen tietueen roolisidonnan ja offline-varmennusvaltuuden täsmennys
Owner/Data Stewardin päätöksellä. Nykyistä DATA_DICTIONARY-remediaatiota ei
vielä käynnistetä, eikä uutta rinnakkaista remediaatiotehtävää tarvita.
Tässä ei anneta sisältömuokkaus-, oikean bindingin luonti- tai migraatiolupaa.

## Turvallinen etenemisjärjestys

1. Työskentele `Fear-of-Falling/`-juuresta ja varmista `pwd`.
2. Aktivoi projektin `renv`-ympäristö ja tarkista tila ennen tieteellistä ajoa.
3. Ratkaise `DATA_ROOT` ympäristöstä tai projektin suojatusta konfiguraatiosta;
   älä kirjoita absoluuttista polkua KB:hen.
4. Tarkista tuottaja, input-schema, data dictionary/`deficit_map`, variantti ja
   projektin tutkijapäätös ennen ajoa.
5. Aja oikea K40-entrypoint aliprojektin ohjeiden mukaisesti. Tällä koneella
   K40.V2 vaatii README:n mukaan vanilla-eristyksen.
6. Säilytä osallistujatason tuotokset vain `DATA_ROOT`-puolella. Repoon saa
   tulla vain aggregaatti-QC, päätösloki, session info ja vientikuitti.
7. Kirjaa jokainen repoartefakti `manifest/manifest.csv`-tiedostoon.
8. Aja `bash scripts/fof-preflight.sh` sekä analyysiportit
   `../tools/run-gates.sh --mode analysis --project Fear-of-Falling`.
9. Kun muutos vaikuttaa dataan, koodaukseen, puuttuvuuteen, inclusion/exclusion-
   logiikkaan, model frameen tai QC:hen, aja myös K18/QC-runner. Pelkässä
   KB-dokumentoinnissa kirjaa perusteltu `NOT APPLICABLE`.
10. Tarkista diff, ettei mukana ole raakadataa, osallistujatason tietoja,
    generoituja outputteja tai asiaankuulumattomia muutoksia.

## Projektin laskentaportit

K40.V2:n varmennetut portit ja poissulut on dokumentoitu kanonisesti
`project/FI_PROJECT_SPEC.md`-tiedostossa. Tämä työnkulku ei saa kopioida niitä
uudeksi tieteelliseksi omistajaksi; toteutuksen tulee lukea arvot aktiivisesta
tuottajakoodista ja verrata niitä projektispeciin.

## FI22-kartan varmennettu dataflow

`Quantify-FOF-Utilization-Costs/R/40_FI/K40_FI_KAAOS.R` lukee omasta
aliprojektijuurestaan polun `R/40_FI/deficit_map.csv`. Kartta vaikuttaa
missing-codejen käsittelyyn, tyyppi-/domain-/prioriteetti- ja cutoff-ohituksiin,
poissulkuihin sekä map-QC-artefakteihin. Downstream-tuotokset sisältävät
sovelletun kartan, drop-reasons-taulun, selected-deficits-taulun,
FI22-liitetaulut, red flags -taulun ja päätöslokin.

`Fear-of-Falling/R-scripts/K40/K40_FI_KAAOS.R` ratkaisee canonical kartan
sisarrepositorion polusta yhden resolverin kautta. Sama map-olio ja
SHA-256-identiteetti kulkevat laskentaan sekä appendix/auditiin; puuttuva,
virheellinen tai nollarivinen map pysäyttää ajon fail-closed. Nykyinen canonical
sensitivity-ajo `20260831_061227` käytti 22-rivistä karttaa end-to-end.

## Fail-closed-säännöt

- Puuttuva lähdeschema, epäselvä suunta tai kynnys: `NEEDS_VERIFICATION`.
- Puuttuva primaarikirjallisuus: `NEEDS_SOURCE`.
- Ristiriitainen tuottaja, kartta tai variantti: `REPOSITORY_CONFLICT` tai
  tarkasti rajattuna `NARROWED_REPOSITORY_CONFLICT`.
- Seuraamuksellinen valinta ilman hyväksyntää: `RESEARCHER_DECISION_REQUIRED`.
- Älä aja suojattua dataa vain dokumentaation validoimiseksi.

## Toistettavuusraportti

Raportoi vähintään entrypoint, repo-relative input/output-sopimus, variantti,
konfiguraatio, ajon tila, session info/renv-tila, manifestimerkinnät, QC-portit
ja ratkaisemattomat poikkeamat. Älä väitä konstrukti- tai ennustevalidointia
pelkän onnistuneen koodiajon perusteella.

## Korjattu FI22-entrypoint

FOF-entrypointin canonical map -sidonta ja kiinteät source-label-mappingit on
varmennettu ajossa `20260831_061227`. Ajo tallentaa lisäksi deficit-score- ja
coverage-jakaumat aggregate-only-artefakteina tulevaa reconciliationia varten.
Termuxissa K40 vaatii `VROOM_THREADS=1`; FI22 pysyy sensitivity-only-roolissa.
Tutkija hyväksyi ajon `20260831_061227` canonical technical sensitivity-runiksi.

## Primary FI PERSON_LEDGER → ASSESSMENT_LEDGER -upstream-portti

Reusable toteutus on `Fear-of-Falling/R/functions/primary_fi_person_ledger.R`.
Dataflow on AUTH_SOURCE → hyväksytyt prior exclusions → `PERSON_LEDGER` →
sama-person/sama-TK assessment-kontekstit → `ASSESSMENT_LEDGER` → kronologinen
`PRIMARY_FI_INDEX`. Toteutus varmentaa config-bindingit ja lähdehashin.

Sama-person/sama-validi-TK-fragmentit käyttävät muuttumatonta
`FIRA1-PRIMARY-FI-SAME-ASSESSMENT-1.0.0`-nelitilasopimusta ja field-level
provenienssia; konflikti pysäyttää promotionin. Eri TK-päivät eivät coalesce.
Index-sääntö `FIRA1-PRIMARY-FI-FIRST-QUALIFYING-TK-1.0.0` valitsee aikaisimman
qualifying TK:n ennen FI-, outcome-, model- tai target-N-tietojen tarkastelua.
Myöhemmät assessmentit säilyvät eikä cross-assessment fill ole sallittu.

Suojattu live-ajo rakensi 527 person-riviä ja 538 assessment-riviä, joista 527
on indexejä ja 11 myöhempiä arviointeja; execution-critical HITL=0. Artefaktit
ja source-/field-provenienssi ovat vain `DATA_ROOT`-alueella mode 0600.
Repository-safe receipt on
`project/PRIMARY_FI_TWO_LEVEL_LEDGER_RECEIPT_20260901.md`. K40/K33/K50/FI
pysyvät keskeytettyinä tutkijakatselmointiin asti.

## K40.V2 diagnostic-first re-anchor 2026-09-01

K40.V2 käyttää hash-varmennettua `PRIMARY_FI_INDEX`-framea ainoana cohort-
anchorina ja johtaa age ≥65 -screenin ilman target-N-vakioita. K33/K32/K15 on
poistettu cohort-polusta. Ajo inventoi 63 raakakandidaattia ja lopettaa ennen
automatic selection/scoring/FI-koodia. Required K18/QC jäi environment-blocked-
tilaan; ks. `../project/K40_CANONICAL_REANCHOR_DIAGNOSTIC_RECEIPT_20260901.md`.

## K40.V2 diagnostic-first canonical re-anchor 2026-09-01

K40.V2 varmentaa ledger-hash-ketjun ja käyttää ainoana cohort-anchorina
`PRIMARY_FI_INDEX`-framea. Age ≥65 -screen johdetaan index-iästä ilman target-N-
vakioita. K33/K32/K15 on poistettu cohort-rakennuspolusta; niitä ei tässä ajossa
joinattu, joten membership mutation ja cross-assessment fill olivat 0.

Canonical-haara inventoi 63 raakakandidaattia aggregate-only-diagnostiikkaan ja
lopettaa ennen historiallisen automatic selection/scoring/FI-koodin suorittamista.
K18/QC-ympäristöportti jäi blocked-tilaan; ks.
`../project/K40_CANONICAL_REANCHOR_DIAGNOSTIC_RECEIPT_20260901.md`.
