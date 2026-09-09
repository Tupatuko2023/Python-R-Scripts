---
title: "FIRA1:n tietosanasto ja muuttujareititys"
status: "PARTIAL_NEEDS_VERIFICATION"
updated: "2026-09-01"
source_basis: "Tarkastetut K40-otsikot, skriptikoodi ja repositorion dokumentaatio"
canonical_for: "FIRA1:ssa turvallisesti käytettävien FI-kenttien merkitys ja reititys"
used_when: "Muuttujaa tulkitaan tai ehdotetaan vajeeksi"
not_authoritative_for: "Raakadatan täydellinen sanakirja tai todentamattomat yksiköt"
related_files: "FI_PROJECT_SPEC.md; ../registry/FI_CANDIDATE_REGISTRY.csv"
update_triggers: "Auktoritatiivinen data dictionary, deficit_map tai schema muuttuu"
---

## FIRA1:n tietosanasto ja muuttujareititys

## Varmennetut analyysikentät

| Kenttä                      | Merkitys                                                    | Tila                    | Auktoriteetti                 |
| --------------------------- | ----------------------------------------------------------- | ----------------------- | ----------------------------- |
| `id`                        | Osallistujan liitosavain K40 Paper 01 -haaran lähtötaulussa | VERIFIED_IMPLEMENTATION | `K40.V2_frailty-index.R`      |
| `frailty_index_fi`          | Valittujen 0–1-vajeiden keskiarvo kelvollisilla riveillä    | VERIFIED_IMPLEMENTATION | K40-skriptit                  |
| `frailty_index_fi_z`        | FI:n standardoitu johdannainen; ei erillinen konstruktio    | VERIFIED_IMPLEMENTATION | K40-skriptit                  |
| `n_deficits_observed`       | Rivillä havaittujen valittujen vajeiden lukumäärä           | VERIFIED_IMPLEMENTATION | K40-skriptit                  |
| `coverage`                  | Havaittujen valittujen vajeiden osuus                       | VERIFIED_IMPLEMENTATION | K40-skriptit                  |
| `fi_eligible`               | Täyttääkö rivi projektin kattavuus- ja vähimmäismääräportit | VERIFIED_IMPLEMENTATION | K40-skriptit                  |
| `FI22_nonperformance_KAAOS` | K50:n kanoninen FI22-sensitiivisyyskenttä                   | VERIFIED_PROJECT_ROLE   | FI22 handoff- ja K50-tehtävät |

Kentän olemassaolo ei yksin vahvista sen kliinistä merkitystä tai
validointitasoa.

## Vaje-ehdokkaan tulkintaprotokolla

1. Etsi muuttujan auktoritatiivinen nimi, label, tyyppi, validit arvot,
   puuttuvat koodit, yksikkö ja aikapiste sanakirjasta tai lähdeschemasta.
2. Jos jokin näistä puuttuu, merkitse ehdokas `NEEDS_VERIFICATION`; älä arvaa.
3. Tarkista projektin hard exclusion -säännöt ennen pisteytystä.
4. Kirjaa ehdotus Candidate Registryyn; älä muuta K40-koodia rekisterin avulla.
5. Hyväksy suunta, kynnys ja domain vain lähdenäytön sekä tutkijapäätöksen
   perusteella.

## Auktoritatiiviset ja ei-auktoritatiiviset sanakirjat

- `Fear-of-Falling/data/VARIABLE_STANDARDIZATION.csv` tukee nimien
  standardointia, mutta ei yksin todista FI-kelpoisuutta tai kliinisiä rajoja.
- `Electronic-Frailty-Index/docs/data_dictionary.md` kuvaa vain synteettistä
  demodataa eikä ole FOF/KAAOS-datan sanakirja.
- `deficit_map.csv` on FI22-pisteytyksen canonical projektikartta. Sen
  omistajuuspolku ja SHA-256-provenienssi ovat `CLOSED`; nykyinen canonical
  sensitivity-ajo on `20260831_061227`.

Raaka- tai osallistujatason arvoja ei saa kopioida tietämyskantaan.

## Canonical person-ledgerin varmennetut source-roolit

| Rooli                           | Varmennettu merkitys                                                          | Raja                                                                                                                 |
| ------------------------------- | ----------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| Configured canonical person key | Täsmällinen sama-henkilöavain; samalla henkilöllä saa olla useita lähderivejä | Ei todista samaa assessment contextia eikä yleistä row-level 1:1 -sääntöä                                            |
| TK/baseline-index visit date    | Auktoritatiivisen intake-/baseline-käynnin päivämääräkenttä                   | Sama henkilö + sama validi TK-päivä määrittää assessment-kontekstin; eri päivät ovat erillisiä assessment-havaintoja |
| Baseline/index age              | Hyväksytyn age-säännön auktoritatiivinen lähdesyöte                           | Age eligibility johdetaan vain valitulta PRIMARY_FI_INDEX-arvioinnilta                                               |
| Source-record provenance        | Lähderivin suojattu provenance-tunniste                                       | Ei analyysikenttä, henkilöavain tai rivinvalintaheuristiikka                                                         |

Person identity ja assessment identity ovat eri tasoja. AUTH_SOURCE ei tarjoa
erillistä assessment/episode-ID:tä, joten suojattu implementation identifier
johdetaan deterministisesti source-snapshotin, canonical person identityn ja
validin TK-päivän kontekstista. Se on tekninen tunniste, ei uusi source-kenttä.
Qualifying assessment edellyttää validia person identityä ja validia TK-päivää;
muita auktorisoituja non-FI-vaatimuksia ei ole varmennettu. FI-kattavuus,
outcome tai mallijäsenyys eivät ole assessment qualification -kenttiä.

Exact source-headerit ja osallistujatason arvot säilyvät vain suojatussa
ympäristössä. Tämä lisäys ei täydennä muiden candidatejen puuttuvaa semantiikkaa.

## Primary FI Candidate Audit Phase 1A -reititys 2026-09-01

Canonical K40 diagnostic -inventaario sisältää 63 `PRIMARY_FI_INDEX`-framen
raakakandidaattia. Niiden membership ja source-block-lineage on varmennettu
hash-sidotusta canonical ledgeristä, mutta exact source-headerit pysyvät
suojattuina eikä täydellistä Data Steward -hyväksyttyä label-, valid levels-,
missing code-, unit- tai health-direction-katalogia ole.

Tämän vuoksi kaikkien 63 kandidaatin `semantics_status` on Phase 1A:ssa
`NEEDS_VERIFICATION`. `source_variable` on canonical diagnostiikan
ei-identifioiva tekninen avain, ei yksin lupa tulkita merkitystä tai scoringia.
Varmennetut implementation facts ovat `PRIMARY_FI_INDEX`-applicability,
raakadatatype sekä canonical-frame availability-denominatorit. Study role,
FI-kelpoisuus, direction, scoring, cut-point, domain, käsitteellinen
redundanssi ja longitudinal equivalence eivät siirry `VERIFIED`-tilaan ilman
erillistä source-/project-evidenssiä.

## Primary FI Candidate Audit Phase 1B -semantiikkareititys 2026-09-01

Suojatun `AUTHSOURCE_SEMANTICS`-snapshotin kenttäkohtainen esitys on sidottu kaikkiin 63 Phase 1A -kandidaattiin ilman exact source-headerien tai osallistujatason esimerkkien replikointia. Esitys on scoped source-semantics -auktoriteetti merkitykselle, kategorioille, puuttuvakoodille, yksikölle ja TK/1SK/2SK-roolille vain silloin, kun tieto on eksplisiittinen. Se ei hyväksy FI-suuntaa, pisteytystä, cut-pointia, domainia tai deficit-kelpoisuutta.

Seitsemän kandidaattia jää `NEEDS_VERIFICATION`-tilaan: johdetun osteoporoosiriskin täydellinen asteikko sekä kuuden grip-luokkakentän luokkien merkitys eivät käy esityksestä riittävästi ilmi. Niiden study role ei etene semantiikkaportin ohi. Muille 56 kandidaatille source-merkitys on `VERIFIED_SCOPED_SEMANTICS`; Paper 01 -rooli on silti provisiorinen ja tutkijapäätöstä odottava. Kandidaattikohtainen evidenssi ja rooliseulonta ovat `../registry/FI_CANDIDATE_PHASE1B_REVIEW.csv`-tiedostossa.

## Composite provenance

Claim identifier: `DATA_DICTIONARY_FINAL_LINEAGE_PROVENANCE`.
Tämä esitys säilyttää varmennetun A1–A9-kokonaisuuden erilliset evidenssiroolit.
Viitteet ovat nykyiseen varmennettuun tilanteeseen tehtyjä prospective bindingeja.
Ne eivät osoita historiallista exact binding recoverya.

### SOURCE_EVIDENCE — A1

Taustalla oleva mittaus on määrällinen mittaussuure. P1 tukee vain tätä
measurement-semantics-ydintä, ei projektin kenttäkohdistusta, luokittelun
raja-arvojen valintaa tai lopullista FI-pisteytystä.

P1: `FIRA1-PER-R1-abd9b37290665581eeeb2f29b04a910bf91a8935c412f57a15236e8ee92f449a`.

### PROJECT_SCHEMA_DERIVATION_EVIDENCE — A2 ja A3

A2 sitoo projektin puolikohtaiset luokkakentät niiden nykyiseen
index-/assessment-mittauskontekstiin ja ajoitukseen. Kumpikin puoli säilyy
erillisenä; ajoitusta ei siirretä myöhempään mittaukseen. Projektikontekstin
kanoninen auktoriteetti on [FI_PROJECT_SPEC](FI_PROJECT_SPEC.md).

A3 erottaa määrällisen mittaussyötteen siitä johdetusta projektin luokkaesityksestä.
Lineagen suunta on mittaussyöte → projektin luokka, eikä luokka yksin palauta
täsmällistä alkuperäistä mittausta. Nykyisen muunnosketjun poiminta-, pyöristys-
ja referointivaiheet, luokkajärjestyksen merkitys sekä erityis-, validi- ja
puuttuvan tilan erot säilyvät täsmällisinä P2:n suojatussa claim-snapshotissa
ja rajatussa derivointievidenssissä. Niitä ei yhdistetä toisiinsa eikä määritellä
uudelleen tässä jakeluesityksessä. Täsmällisten koodien tai muunnoksen käyttö
edellyttää valtuutettua protected-verifiointia; tästä tekstistä ei johdeta
korvaavaa schemaa, arvoja tai pisteytysohjetta.

A2 ja A3 ovat saman P2-evidenssiobjektin erikseen auditoitavia suhteita.

P2: `FIRA1-PER-R1-cea23cf2c6075461759040979a874b85f33b02895e98bdd998009166b43f4a9a`.

### IMPLEMENTATION_VERIFICATION_EVIDENCE — A4

A4 käyttää samaa P2-viitettä omana kolmantena relationshipinaan. Projektissa
käytettyjen rajojen ja scoring-vaihtoehtojen näyttö säilyy `VERIFIED_SCOPED`-
toteutusnäyttönä. Yhteinen viite ei yhdistä A2:n kenttäkohdistusta, A3:n
lineagea ja A4:n toteutusnäyttöä yhdeksi tieteelliseksi väitteeksi.
[FI_R_WORKFLOW](../computational/FI_R_WORKFLOW.md) omistaa toteutus- ja
verifiointireitin, ei lopullista tieteellistä valintaa.

### PROJECT_RESEARCHER_DECISION_AUTHORITY — A5–A9

[FI_PROJECT_SPEC](FI_PROJECT_SPEC.md) ja erillinen tutkijapäätös omistavat
projektin operationalisointivalinnat. [FI_METHODS_CANONICAL](../methods/FI_METHODS_CANONICAL.md)
antaa menetelmällisen tukikehyksen; se ei korvaa projektipäätöstä tai tämän
dokumentin muuttujasemantiikan omistajuutta. Seuraamuksellinen lopullinen
hyväksyntä kuuluu Owner/Data Stewardille. Näille päätösrajoille ei tarvita
uusia protected-viitteitä.

| Väite | Säilyvä päätösraja                                                                                        | Tila                     |
| ----- | --------------------------------------------------------------------------------------------------------- | ------------------------ |
| A5    | Lineage ei hyväksy lopullista FI-pisteytystä                                                              | NOT_APPROVED_BY_LINEAGE  |
| A6    | Luokkien spacing ja lopullinen pisteytystulkinta vaativat erillisen päätöksen                             | OPEN_RESEARCHER_DECISION |
| A7    | Deficit-onset vaatii erillisen päätöksen                                                                  | OPEN_RESEARCHER_DECISION |
| A8    | Erityis-/rajatapauksen käsittely vaatii erillisen päätöksen; täsmärajauksen säilyttää P2:n claim-snapshot | OPEN_RESEARCHER_DECISION |
| A9    | Yhden tai molempien puolien lopullinen käyttö/yhdistäminen vaatii erillisen päätöksen                     | OPEN_RESEARCHER_DECISION |

Ikä-/sukupuolireferointi säilyy myöhemmän age-association-diagnostiikan
tulkintarajoitteena. Luokkataulukon alkuperäistä ulkoista lähdettä ei ole
varmennettu alkuperäislähteestä; jatkuvan mittauksen taustaevidenssi ei
osoita tämän projektin luokkataulukon alkuperää.

### Historiallinen konteksti ja audit-reitti

HISTORICAL_PROVENANCE_STATUS = `PARTIAL/HISTORICAL_CONTEXT`.
Aiemman provenance-esityksen täsmällinen sisältö ja lähdesidonnat säilyvät
olemassa olevien P1/P2-recordien protected claim-snapshotissa. Nykyisten
prospective bindingien varmennus ei promotoi historiallista näyttöä VERIFIEDiksi.
Historiallinen alkuperäisviittaus ja sen rajoitteet ovat rekonstruoitavissa
valtuutetussa offline-tarkastuksessa; niitä ei poisteta audit-ketjusta.

P1/P2 ovat opaakkeja evidenssiviitteitä, eivät käyttövaltuuksia, jakelulupia,
automaattisia resolver-linkkejä tai itsenäisiä tieteellisen vastaavuuden todisteita.
Tarkka source/version/authority/relationship-binding tarkistetaan hyväksytyssä
protected-ympäristössä [FI_R_WORKFLOWn](../computational/FI_R_WORKFLOW.md)
staattisen provenienssisillan menettelyllä. Owner/Data Steward omistaa binding-,
jakelu- ja protected-use-päätökset; FIRA1/domain verifier varmentaa semanttisen
suhteen. DATA_DICTIONARY säilyy muuttujasemantiikan kanonisena omistajana.
