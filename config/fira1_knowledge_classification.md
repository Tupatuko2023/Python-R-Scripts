# FIRA1 Knowledge -luokittelupolitiikka

Versio: `1.0-review`. Tila: `OWNER_APPROVED_CLASSIFICATION_ONLY`.
Omistajan hyväksymä suunta: `MIXED_CLASSIFIED` (prompt 12, 2026-09-07).
Omistaja hyväksyi tämän version täsmäluokat ja etusijasäännöt 2026-09-07
paketissa `fira1-knowledge-classification-owner-approval-20260907` (prompt 13).
Hyväksyntä koskee vain luokittelua: kirjoitus-, tracking-, migraatio- ja
enforcement-luvat jäävät erillisiksi. Luokittelematon polku = DENY.

## Sijainti, auktoriteetti ja soveltamisala

WORKFLOW.md määrittelee `config/`-hakemiston ohjauksen ja asetusten paikaksi;
config/agent_policy.md täydentää SKILLS.md:tä. Tämä on FIRA1:n tracking-luokkien
kanoninen omistajadokumentti, ei uusi tehtäväjono tai tiedeauktoriteetti.
Lähteet löytyvät [WORKFLOW.md:stä](../WORKFLOW.md),
[SKILLS.md:stä](../SKILLS.md) ja [Security-ohjeesta](../.github/SECURITY.md).

Alla `K` tarkoittaa täsmälleen repo-relative-hakemistoa
`GPT/(FIRA1) Frailty Index Research Assistant/knowledge/`.
Täsmäsääntöjen polut ovat suhteessa K:hon, kirjainkoko säilyy.
Sääntö ei koske muuta GPT-puuta, FIRA1:n lähde-PDF:iä tai muita aliprojekteja.

Auktoriteettiroolit perustuvat K:n `KB_INDEX.md`:n canonical ownership -taulukkoon
sekä nimettyjen domain-dokumenttien canonical_for/not_authoritative_for-metatietoon.
Git-tilanne on erillinen havainto: workflow ei ole indeksissä ja
`.git/info/exclude:18:/GPT/` peittää sen. Tätä ei muuteta eikä käytetä perusteena
valita pysyvää luokkaa. Arkiston rooli on KB_INDEXissä `ARCHIVED_NOT_ACTIVE`.
Release-manifestin oma rooli on päivätty release-kandidaatin audit-evidenssi,
ei uusi tieteellinen päätös tai automaattinen julkaisu.

## Luokat ja lupien rajat

- `VERSION_CONTROLLED`: hyväksytyn politiikan mukaan periaatteessa normaaliksi
  katselmoiduksi projektihistoriaksi soveltuva artefakti. Ei tracking-, staging-,
  migraatio-, commit- tai push-lupa. Erillinen hyväksytty migraatiotehtävä tarvitaan.
- `LOCAL_ONLY`: hyväksytyn politiikan mukaan paikallinen projektitila normaalin
  Git-historian ulkopuolella. Ei lupaa kirjoittaa mielivaltaisia ignored-tiedostoja.
  Havaintomalli vaatii myöhemmin erikseen hyväksytyn täsmäpolun ja ennen-tilan
  digest/metadata-menetelmän; puuttuva evidenssi pysäyttää toiminnon.
- `PROTECTED`: raakadata, henkilötiedot, osallistujaledgerit, salaisuudet ja
  vastaavat suojatut sisällöt eivät kuulu normaaliin Git-historiaan tai HOTL-
  baselineen. Vain tietoturvapolitiikan sallima ei-arkaluontoinen luokkametadata
  on sallittua; ei sisältöjä, henkilöavaimia tai salaisuuksia lokiin/receiptteihin.
- `DENY_UNCLASSIFIED`: tuntematon tai epäselvä polku/luokka; ei tracking-, kirjoitus-
  eikä observation-lupaa. Uusi luokitus vaatii omistajan hyväksymän politiikkamuutoksen.

Luokitus ei ole kirjoituslupa. Jokainen tuleva tehtävä tarvitsee edelleen tarkat
hyväksytyt kirjoituspolut, operaatiot, muut lupaportit, QC-soveltuvuuden ja validoinnin.
Tieteelliset päätökset, candidate-status ja scoring eivät muutu tässä luokittelussa.
VERSION_CONTROLLED-luokankaan sisältöä ei katsota automaattisesti julkaistavaksi:
migraatiossa tarkistetaan ajantasainen privacy, provenance ja lähteiden käyttöoikeus.

## Deterministinen ratkaisujärjestys

1. Hyväksynnän puuttuessa kaikki sallivat säännöt pysyvät DENY-tilassa.
2. Hylkää absoluuttinen polku, `..`, tyhjä segmentti, epäselvä normalisointi,
   symlinkki tai K:n ulkopuolelle johtava alias: `DENY_UNCLASSIFIED`.
3. Turvallisuus ohittaa kaiken: auktoritatiivisesti suojattuun luokkaan kuuluva
   kohde on `PROTECTED` polkunimestä riippumatta. Epäilty/epäselvä herkkyys = DENY,
   ei suojatun sisällön avaamista asian selvittämiseksi.
4. Eksplisiittinen DENY-sääntö ohittaa kaikki sallivat täsmä- ja vanhempisäännöt.
   PROTECTED ohittaa myös DENY:n luokitusnimessä; molemmat estävät pääsyn.
5. Sovella vain alla lueteltuja täsmäsääntöjä. Vanhemman hakemiston rooli tai
   viereisen tiedoston luokka ei periydy. Mahdollisessa myöhemmin hyväksytyssä
   parent/child-luokituksessa protected/deny-lapsi voittaa sallivan vanhemman.
6. Keskenään ristiriitaiset sallivat säännöt, puuttuva roolievidenssi ja kaikki
   muut osumat jäävät `DENY_UNCLASSIFIED`-tilaan. Ei first-match- tai arvausratkaisua.

## Hyväksytyt täsmäsäännöt

Taulukon VC tarkoittaa VERSION_CONTROLLED. Jokainen taulukon solu on nimetty
artefakti, ei wildcard. Kaikkien VC-rivien tuleva havaintomalli on normaali Git
vasta erillisen hyväksytyn migraation jälkeen; nykyinen exclude ei muutu.
Herkkyys kuvaa todettua dokumenttiroolia, ei kattavaa julkaisukelpoisuusauditointia.

| Polku K:sta                                             | Luokka     | Auktoriteetti / peruste                                        | Herkkyys ja tarkoitus                                          | Tuleva havainto / migraatio                                          |
| ------------------------------------------------------- | ---------- | -------------------------------------------------------------- | -------------------------------------------------------------- | -------------------------------------------------------------------- |
| `KB_INDEX.md`                                           | VC         | Oma canonical_for; KB:n reititys                               | Projektin omistajuusmetadata, ei päätösautomaatti              | Git migraation jälkeen / kyllä                                       |
| `computational/FI_R_WORKFLOW.md`                        | VC         | KB_INDEX + oma canonical_for; nykyinen dokumentaatiopilotti    | Toteutus-, testaus- ja suojarajojen ohje, ei participant-FI    | Git migraation jälkeen / kyllä                                       |
| `methods/FI_METHODS_CANONICAL.md`                       | VC         | KB_INDEX:n menetelmäsynteesin omistaja                         | Lähteistetty menetelmäohje; lähteiden käyttöoikeus erikseen    | Git migraation jälkeen / kyllä                                       |
| `project/FI_PROJECT_SPEC.md`                            | VC         | KB_INDEX + PROJECT_RULE-omistajuus                             | Projektisäännöt ja variantit, ei osallistujadata               | Git migraation jälkeen / kyllä                                       |
| `project/DATA_DICTIONARY.md`                            | VC         | Oma canonical_for: semantiikka ja reititys, ei raakadata       | Schema-/semantiikkaohje; suojattu sisältö ei saa periä luokkaa | Git migraation jälkeen / kyllä                                       |
| `validation/FI_QC_VALIDATION.md`                        | VC         | Oma canonical_for: QC ja T01–T12                               | Testimääritys, ei ajon data tai validiteettitodiste            | Git migraation jälkeen / kyllä                                       |
| `reporting/FI_REPORTING_SPEC.md`                        | VC         | Oma canonical_for: raportointisopimus                          | Ohje, ei valmis osallistujatuloste                             | Git migraation jälkeen / kyllä                                       |
| `sources/FI_SOURCE_STATUS.md`                           | VC         | Oma canonical_for: lähdetila ja puutteet                       | Bibliografinen/provenienssimetadata, ei PDF-lähteiden lisenssi | Git migraation jälkeen / kyllä                                       |
| `archive/FIRA1_IMPLEMENTATION_EVIDENCE.md`              | LOCAL_ONLY | KB_INDEX: ARCHIVED_NOT_ACTIVE; päivätty initial-build snapshot | Historiallinen paikallinen evidenssi, ei runtime-auktoriteetti | Erillinen exact-path-metadata/digest-hyväksyntä / ei Git-migraatiota |
| `releases/FIRA1_KB_v1.1_2026-08-31_RELEASE_MANIFEST.md` | LOCAL_ONLY | Oma canonical_for ja release-periaate                          | Päivätty release-audit; ei nykyisten päätösten omistaja        | Erillinen exact-path-metadata/digest-hyväksyntä / ei Git-migraatiota |

LOCAL_ONLY on omistajan promptissa 13 hyväksymä ylläpitovalinta historialliselle
evidenssille, ei lupa muuttaa Git-seurantaa tai toteuttaa havainnointia. Ei koko archive/- tai
releases/-hakemiston lupaa eikä automaattista luokkaa uusille snapshoteille.

## Muut luokat ja ratkaisemattomat kohteet

| Kohde / luokkamatcher                                                                                            | Luokka            | Auktoriteetti, herkkyys ja peruste                                                                                                                                     | Tuleva havainto / migraatio                                                        |
| ---------------------------------------------------------------------------------------------------------------- | ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| `registry/FI_CANDIDATE_REGISTRY.csv`                                                                             | DENY_UNCLASSIFIED | KB_INDEX: current-state owner. Semanttisesti arvokas mutta laaja muuttuva schema ja vapaa evidenssiteksti vaativat erillisen kenttäkohtaisen jakelukelpoisuusrajauksen | Ei vielä / uusi luokituspäätös ja tarvittaessa migraatio                           |
| `registry/FI_CHANGELOG.md`                                                                                       | DENY_UNCLASSIFIED | KB_INDEX: append-only decision/supersession owner. Historia voi kantaa source-/protected-viitteitä; päätösmetadatan nimike ei yksin riitä jakeluluvaksi                | Ei vielä / uusi luokituspäätös ja tarvittaessa migraatio                           |
| Muut registry/-tiedostot                                                                                         | DENY_UNCLASSIFIED | Kandidaattiesityksiä, matriiseja ja historiallisia katselmointeja; ei automaattista current-state-omistajuutta tai privacy-luokkaa                                     | Ei / vaatii luokittelun                                                            |
| Muut project/- ja validation/-tiedostot                                                                          | DENY_UNCLASSIFIED | Suunnitelmia, review-poolia, aggregate-diagnostiikkaa, crosswalkia ja HITL-receipttejä; aggregaattinimi ei todista tietoturvallisuutta                                 | Ei / vaatii luokittelun                                                            |
| Uudet snapshot-, generated-, cache- ja temporary-artefaktit missä tahansa K:ssa                                  | DENY_UNCLASSIFIED | Ei hyväksyttyä yksilöityä roolia; ei periytymistä kanonisista naapureista                                                                                              | Ei / vaatii luokittelun                                                            |
| AUTH_SOURCE, PERSON_LEDGER, ASSESSMENT_LEDGER, PRIMARY_FI_INDEX, raakadata ja suojattu DATA_ROOT sisältö roolina | PROTECTED         | FI_R_WORKFLOW:n dataflow/turvaraja ja SECURITY; osallistujadata. Symboliset roolit, ei avattu eikä osoitettu KB:n alle                                                 | Ei sisältö-/digest-observationia tässä politiikassa / ei normaalia Git-migraatiota |
| Credentials, secrets ja osallistujatason tunnisteet sisällön auktoritatiivisena luokkana                         | PROTECTED         | SECURITY ja CONTRIBUTING; sijainti ei muuta suojausta                                                                                                                  | Vain sallittu ei-arkaluontoinen luokkametadata / ei                                |
| K:n ulkopuolinen tai muu tuntematon polku                                                                        | DENY_UNCLASSIFIED | Tämän politiikan ulkopuolella; muu auktoritatiivinen suojasääntö voi lisäksi merkitä PROTECTED                                                                         | Ei tämän politiikan nojalla / ei                                                   |

Inventaario 2026-09-07: 121 tiedostoa. Hyväksytty luokittelu kattaa 8 VC- ja 2 LOCAL_ONLY-
täsmäpolkua; muut 111 jäävät DENY-tilaan. Protected on lisäksi semanttinen
estoluokka, ei väite inventaariosta avatusta suojatusta tiedostosta. Tuntematon
herkkyys säilyy DENY-tilassa; sitä ei muuteta LOCAL_ONLYksi varmuuden vuoksi.

## Luokitteluregressiot (politiikan esimerkit, ei enforcement-toteutus)

Nämä odotukset koskevat hyväksynnän jälkeistä politiikkaversiota. Ennen hyväksyntää
myös VC/LOCAL_ONLY-esimerkit ovat DENY. Tapaukset arvioidaan säännöistä, ilman
kohdesisällön lukemista tai koneellisen havaintojärjestelmän toteuttamista.

| Tapaus                                                             | Odotettu luokka    | Peruste                                                                  |
| ------------------------------------------------------------------ | ------------------ | ------------------------------------------------------------------------ |
| K + `computational/FI_R_WORKFLOW.md`                               | VERSION_CONTROLLED | Täsmäsääntö; ei vielä tracking-lupaa                                     |
| K + `archive/FIRA1_IMPLEMENTATION_EVIDENCE.md`                     | LOCAL_ONLY         | Nimetty historiallinen snapshot                                          |
| Auktoriteetin PERSON_LEDGERiksi luokittelema kohde                 | PROTECTED          | Semanttinen suojasääntö ennen polkulupia                                 |
| K + `computational/new_notes.md`                                   | DENY_UNCLASSIFIED  | Ei periytymistä nimetystä workflowsta                                    |
| Synteettinen salliva `project/`-vanhempi + tarkka PROTECTED-lapsi  | PROTECTED          | Suojattu lapsi ohittaa; parent-lupa ei ole tämän politiikan oikea sääntö |
| Synteettinen salliva vanhempi + tarkka DENY-lapsi                  | DENY_UNCLASSIFIED  | Kielto ohittaa; ei oikean hakemistoluvan lisäystä                        |
| Samalle polulle ristiriitaiset VC ja LOCAL_ONLY                    | DENY_UNCLASSIFIED  | Epäselvä luokitus pysäyttää                                              |
| `Fear-of-Falling/README.md` tai muu GPT-haara                      | DENY_UNCLASSIFIED  | Ei K:n alainen                                                           |
| K + `project/../computational/FI_R_WORKFLOW.md` tai symlinkkialias | DENY_UNCLASSIFIED  | Ei epäselvää polkunormalisointia                                         |
| K + `registry/FI_CANDIDATE_REGISTRY.csv`                           | DENY_UNCLASSIFIED  | Rooli tunnistettu mutta jakelukelpoisuusluokitus avoin                   |

## Hyväksyntä ja seuraava sallittu vaihe

Omistajan promptin 13 hyväksyntä vahvistaa tämän version täsmäluokat, DENY-joukon,
suojausten etusijan ja tulevien havaintomallien rajat. Luokittelun auktoriteettieste
on ratkaistu; Batch 1a pysyy blocked-tilassa odottaen hyväksyttyä tracking-migraatiota
ja sen validointia. Batch 1a:n korttia ei muuteta tässä työssä.
Luokittelutehtävä säilyy `03-review`-tilassa: `HUMAN_DONE_TRANSITION_REQUIRED`.
Hyväksynnän jälkeen VERSION_CONTROLLED-polkujen tracking-migraatio vaatii vielä
oman hyväksytyn tehtävän ennen Git-observabilityyn perustuvaa Batch 1a -jatkoa.
LOCAL_ONLY-polkujen täsmähavainnointi tarvitsee erillisen toteutusluvan.
Sekaluokittelu ei oikeuta yleiseen ignored-tiedostojen skannaukseen.

### Seuraavan tehtävän rajaus: VERSION_CONTROLLED_TRACKING_MIGRATION

Tämä on suunnitelma, ei toteutuslupa tai uusi hyväksytty tehtävä.
Migraation Knowledge-scope saa sisältää vain yllä olevan taulukon kahdeksan
VC-täsmäpolkua. Kaksi LOCAL_ONLY-polkua ja kaikki DENY/PROTECTED-aineisto
jäävät tracking-muutosten ulkopuolelle. Ei wildcard-laajennusta.

Erikseen hyväksyttävän tehtävän tulee:

1. nimetä kaikki kahdeksan repo-relative-polkuista kohdetta sekä täsmällinen
   tracking/exclude-konfiguraatiomuutos ja task-evidenssin rajaus;
2. tarkistaa privacy, provenance ja lähteiden käyttöoikeus ennen trackingia;
3. tarkentaa nykyistä poissulkua vain kohdepolkujen verran — ei `/GPT/`-säännön
   poistamista kokonaisuutena eikä force-add-kiertotietä;
4. todentaa, että juuri hyväksytyt kahdeksan polkua tulevat Gitin havaittaviksi
   sovitulla tracking-menettelyllä ja kumpikin LOCAL_ONLY-polku sekä kaikki muut
   inventoidut DENY-polut säilyvät untracked-tilassa; suojattujen luokkien
   poissulku varmistetaan ilman suojattujen sisältöjen lukua;
5. validoida muutokset ja siirtää migraatiotehtävä vain `03-review`-tilaan.

Vasta tämän jälkeen erillinen Batch 1a -paketti voi jatkaa VC-polkujen staged/path-
valvontaa. Local-only-digest-havainnointi jää myöhempään erilliseen siivuun ja saa
koskea vain kahta hyväksyttyä LOCAL_ONLY-täsmäpolkua.

## Hyväksytty C22-minimitoimitus: exact-path-lisäys 2026-09-13

Omistaja hyväksyi MINIMAL DISTRIBUTABLE REPOSITORY CLOSEOUT -päätöksessä
vain classification review -matriisin kuusi PROPOSE_VERSION_CONTROLLED +
DISTRIBUTABLE_AS_IS -täsmäpolkua. Tämä lisäys laajentaa politiikan soveltamisalaa
vain alla yksilöityihin repo-relative-polkuhin myös K:n ulkopuolella.
Aiemmat kahdeksan VC-luokkaa, LOCAL_ONLY-luokat ja muut täsmäluokitukset säilyvät.
PROTECTED-etusija, eksplisiittiset kiellot ja DENY_UNCLASSIFIED-oletus säilyvät.
Ei wildcardia tai luokan periytymistä; uusi tai muuttunut sisältö tarkistetaan erikseen.

| Repo-relative täsmäpolku                                                                                                     | Hyväksytty luokka  |
| ---------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| `Fear-of-Falling/R/functions/general_fi22.R`                                                                                 | VERSION_CONTROLLED |
| `Fear-of-Falling/R/functions/qc_general_fi22.R`                                                                              | VERSION_CONTROLLED |
| `Fear-of-Falling/tests/test_general_fi22.R`                                                                                  | VERSION_CONTROLLED |
| `GPT/(FIRA1) Frailty Index Research Assistant/knowledge/reporting/GENERAL_FI_22_DEFERRED_FUTURE_WORK_20260912.md`            | VERSION_CONTROLLED |
| `GPT/(FIRA1) Frailty Index Research Assistant/knowledge/reporting/GENERAL_FI_22_PUBLICATION_ADAPTATION_BOUNDARY_20260912.md` | VERSION_CONTROLLED |
| `config/fira1_knowledge_classification.md`                                                                                   | VERSION_CONTROLLED |

Tämä repository-toimitus ei ole koko C22-science-arkisto eikä itsenäinen
reproduktiopaketti. Registry/FI_CANDIDATE_REGISTRY.csv ja registry/FI_CHANGELOG.md
säilyvät alkuperäisissä täsmällisissä DENY_UNCLASSIFIED-luokissaan.
Niitä käyttävien paikallisten ajoketjujen suhde on LOCAL_GOVERNING_DEPENDENCY;
niiden sisältöä ei kopioida koodiin tai synteettisiin testifixtureihin.
Synteettisen päätestin kaksi runtime-riippuvuutta hyväksyttiin alla erillisellä
exact-file/exact-hash Owner-päätöksellä. Lopullinen toimitusjoukko on kahdeksan polkua.

Muut manuscript/Abstract/reporting/validation-paketin kohteet ovat tämän toimituksen
rajauksessa LOCAL_ONLY_FOR_ANALYSIS_REPOSITORY_PENDING_DISSERTATION_HANDOFF.
Tämä on toimituksen poissulku, ei niiden aiempien täsmäluokkien muuttaminen,
tieteellisen auktoriteetin muutos tai PROTECTED-luokitus. Jäädytetty sisältö ja
hashit säilyvät. Erillinen dissertation-handoff ei saa lupaa tästä luokituksesta.
Hyväksytty remote deletion count on 0. Historialliset taskit ja välituotteet
jäävät tämän exact-setin ulkopuolelle; ei done-siirtoja tämän muutoksen osana.

CLASSIFICATION_POLICY_PORTABILITY = VERSION_CONTROLLED tämän täsmäpäätöksen nojalla.
Politiikan julkaiseminen ei anna oikeutta julkaista sen kuvaamia suojattuja kohteita.
Git-toimet, jakeluluokitus ja dissertation-siirto ovat erillisiä lupia.

## C22 runtime-riippuvuuksien Owner-jakelupäätös 2026-09-13

Omistaja hyväksyi seuraavat täsmäversiot VERSION_CONTROLLED + DISTRIBUTABLE_AS_IS
-luokkaan. Schema-/operationalisointiyksityiskohtien lupa koskee vain näitä
koodiversioita, ei underlying source materialia, participant-dataa tai muita
schema/value-tietoja. Muuttunut hash edellyttää uutta jakeluclearancea.

| Repo-relative täsmäpolku                                   | SHA-256                                                            | Luokka             |
| ---------------------------------------------------------- | ------------------------------------------------------------------ | ------------------ |
| `Fear-of-Falling/R/functions/general_fi_candidate_state.R` | `7ecfea636cdeb7ecc784c5741a225f652e4a6ded85c4c6a8bcaa507d405c3288` | VERSION_CONTROLLED |
| `Fear-of-Falling/scripts/run_general_fi22.R`               | `bf34bb0441e71b35d76f926eb1fb9f0246a4f44acc15a2cb28fb956057278c76` | VERSION_CONTROLLED |

Registry/Changelog säilyvät DENY_UNCLASSIFIED-tilassa. Nämä kaksi tiedostoa
eivät lue niiden sisältöä. Runner käyttää tuotannossa erikseen valtuutettuja
suojattuja inputteja; synteettinen testi luo omat fixturet. PROTECTED-etusija
ja oletuskielto säilyvät. Tämä ei laajenna underlying-aineiston jakeluoikeutta.
