---
title: "FIRA1:n projektikohtainen FI-määrittely"
status: "VERIFIED_WITH_OPEN_ITEMS"
updated: "2026-09-01"
source_basis: "Fear-of-Falling K40 -skriptit, tehtäväkortit ja analyysiohjeet"
canonical_for: "FOF/KAAOS FI -variantit ja tutkijapäätökset"
used_when: "Projektin FI rakennetaan, auditoidaan tai käytetään mallissa"
not_authoritative_for: "Yleispätevä FI-metodologia tai muuttujien kliininen merkitys"
related_files: "../methods/FI_METHODS_CANONICAL.md; DATA_DICTIONARY.md; ../computational/FI_R_WORKFLOW.md"
update_triggers: "K40-tuottaja, analyysisuunnitelma tai tutkimuspäätös muuttuu"
---

## FIRA1:n projektikohtainen FI-määrittely

## Varmennetut aktiiviset variantit

### Paper 01: K40.V2

- Tuottaja: `Fear-of-Falling/R-scripts/K40/K40.V2_frailty-index.R`.
- Tuloskentät: `frailty_index_fi` ja johdettu `frailty_index_fi_z`.
- FI on valittujen 0–1-vajeiden rivikohtainen keskiarvo.
- Ensisijainen puuttuvuusraja on `p_miss <= 0.20`; `<= 0.30` otetaan käyttöön
  vain, jos ensisijaisessa haarassa on alle 10 kelvollista vajetta.
- Binäärivajeen prevalenssiraja on 0.01–0.80.
- FI lasketaan vain, kun havaittu kattavuus on vähintään 60 % ja havaittuja
  vajeita on vähintään 10. Muulloin FI on `NA`.
- Suorituskykytestit, ensisijaiset altisteet, outcome-komponentit, demografiset
  kentät, hallinnolliset kentät ja johdetut frailty-rakenteet suljetaan pois
  skriptin sääntöjen mukaan.
- Jatkuva ehdokas vaatii ennalta määritellyn, koodikirjaan perustuvan kynnyksen.
  Korrelaatioon perustuva suunnan kääntö on kielletty.

Nämä ovat projektin toteutussääntöjä, eivät yleisiä kirjallisuussuosituksia.

### Paper 02/KAAOS: FI22_nonperformance_KAAOS

- Tuottajaehdokas, jota repossa käytetään: `Fear-of-Falling/R-scripts/K40/K40_FI_KAAOS.R`.
- Kanoninen kuluttajakenttä: `FI22_nonperformance_KAAOS`; K40:n
  potilastason lähdekenttä on dokumentoidun handoffin mukaan
  `frailty_index_fi`.
- Rooli Fear-of-Falling-tutkimuksessa on vain sensitiivisyysanalyysi.
- K50:n WIDE- ja LONG-sensitiivisyyshaarojen puuttuvan kentän portti on
  dokumentoidusti ratkaistu upstream-viennissä.
- Vajeiden määrittelyliite rakennetaan `deficit_map.csv`-kartasta ja
  `k40_kaaos_selected_deficits.csv`-valinnasta; varavalinta `keep == 1` on
  sallittu vain, jos valintatiedosto puuttuu.

#### `deficit_map.csv`-provenienssi

- Repossa on yksi varsinainen kartta:
  `Quantify-FOF-Utilization-Costs/R/40_FI/deficit_map.csv`.
- Se on Git-seurattu ja lisättiin commitissa
  `517bce5d22c44f91799262c6dc372f46e0651b6f`. Nykyinen Git-blob on
  `c352ca8ee0acab04386529a53c0f88a38e296cf4` ja SHA-256
  `5e9606a35fb9d560e51c2399c97ec4a508039db8ffe352fd9cdca42a6f4a1c4e`.
- Tehtävähistoria kuvaa kartan manuaalisesti seedatuksi aktiivisen FI22-joukon
  rekisteriksi. Generoivaa skriptiä tai erillistä upstream-lähdetiedostoa ei
  löytynyt; ylläpitomekanismi on `MANUAL_TRACKED`.
- Kartassa on 22 yksilöllistä riviä ja 12 lähdesaraketta: `var_name`, `keep`,
  `domain`, `type`, `direction`, `cutoff`, `cutoff_low`, `cutoff_high`,
  `priority`, `missing_codes`, `exclude_reason`, `notes`.
- Quantify-tuottaja kuluttaa kartan suoraan omasta `R/40_FI/`-polustaan.
- FOF-tuottaja ratkaisee saman canonical sisarrepositorion kartan yhden
  resolverin kautta sekä laskentaan että appendix/auditiin ja epäonnistuu
  suljetusti, jos polku, rakenne tai sovellettavat rivit eivät täsmää.

## Study-role- ja circularity-governance

| Kohde                       | Nykyinen projektitason rooli          | Kontrolli                                                                                                                                                           |
| --------------------------- | ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| K40.V2                      | Paper 01:n tutkimus-FI                | Ehdokas ei saa olla analyysin ensisijainen altiste, outcome-komponentti, ennalta määritelty confounder, hallinnollinen/prosessikenttä tai johdettu frailty-rakenne. |
| `FI22_nonperformance_KAAOS` | Paper 02:n sensitivity-only-variantti | Ei primaarimittari eikä uusi rooli ilman tutkijapäätöstä.                                                                                                           |
| Uusi ehdokas                | Ei hyväksyttyä roolia                 | Data Dictionary → Methods → study-role/leakage-screen → Registry; seuraamuksellinen valinta on `RESEARCHER_DECISION_REQUIRED`.                                      |

Project Spec omistaa variantin tutkimusroolin ja circularity-/leakage-rajat.
Data Dictionary omistaa vain varmennetun muuttujasemantiikan, ja Candidate
Registry omistaa ehdokkaan nykyisen arviointi- ja päätöstilan. Tämä taulukko ei
hyväksy uusia ehdokkaita, pisteytyksiä tai poissulkuja.

## Avoimet kontrollit

- `CLOSED`: FOF:n canonical map -resolver, laskenta ja appendix/audit käyttävät
  samaa polkua ja SHA-256-identiteettiä. Nykyinen canonical sensitivity-ajo on
  `20260831_061227`; mapissa on 22 sovellettua riviä.
- `NEEDS_VERIFICATION`: FI22:n primaarilähteeseen perustuva menetelmävalidointi
  ja tarkka upstream gate -paketti on tarkastettava omistajarepositoriossa.
- `RESEARCHER_DECISION_REQUIRED`: uutta vajetta, kynnystä, suuntaa,
  domain-luokitusta tai FI:n roolia ei saa hyväksyä pelkän agenttitulkinnan
  perusteella.

## Tutkijan kontrolli

Koodissa havaittu sääntö voidaan kuvata toteutettuna, mutta sen tieteellinen
hyväksyttävyys on eri väite. Menetelmämuutokset, variantin ensisijaisuus ja
manuskriptiväitteet vaativat nimettyä tutkijapäätöstä ja lähdeperustan.

## FI22 scoring reconciliation 2026-08-31

`K40_FI_KAAOS.R` käyttää ID:ille 11, 18, 28 ja 31 lähdeotsikkoon sidottuja
kiinteitä raakataso–0–1-mappingeja. Tuntematon taso tuottaa fail-closed `NA`:n;
samplesta puuttuva validi taso ei skaalaa muita tasoja uudelleen. Varmennettu ajo
`20260831_061227` tuotti 22/22 concordant-deficitiä samalla canonical mapilla
(SHA-256 `5e9606a35fb9d560e51c2399c97ec4a508039db8ffe352fd9cdca42a6f4a1c4e`).
Tutkija hyväksyi myöhemmin ajon `20260831_061227` canonical technical
sensitivity-runiksi ja luokitteli aiemmat ajot alla kuvatulla tavalla.

## Hyväksytty FI22-ajostatus 2026-08-31

Tutkija hyväksyi: `20260831_061227` = `CANONICAL_SENSITIVITY_RUN`;
`20260831_050926` = `SUPERSEDED_SCORING_CONFLICT`; `20260320_150123` =
`LEGACY_PRE_MAP_PROVENANCE`. Ensimmäisessä legacy-ajossa map ei latautunut
(`deficit_map_loaded=FALSE`, `deficit_map_rows=0`). Luokitus ei muuta FI22:n
sensitivity-only-roolia. Historialliset ajot ja evidenssi säilytetään.

## Primary FI canonical person-ledger PROJECT_RULE 2026-08-31

Tutkija hyväksyi säännön `FIRA1-PRIMARY-FI-SAME-ASSESSMENT-1.0.0`:
AUTH_SOURCE-tietueet ovat saman canonical baseline/index assessment contextin
record-fragmentteja vain, kun niillä on sama configured canonical person key
ja sama ei-puuttuva auktoritatiivinen TK/baseline-index-käyntipäivä.

Kenttäkohtainen sopimus on `ALL_MISSING` → puuttuva,
`ONE_NON_MISSING` → ainoa havaittu arvo,
`MULTIPLE_IDENTICAL_NON_MISSING` → yhteinen arvo ja
`CONFLICTING_NON_MISSING` → `STOP/HITL`.

Kaikkien kontribuoivien lähdetietueiden provenance on säilytettävä. First/last,
earliest/latest, row order, completeness, majority, clinical plausibility,
legacy behavior, downstream outcome ja target-N eivät saa ratkaista tietuetta.
Tämä on projektin record-resolution-sääntö, ei source-semantiikkaa eikä FI:n
scoring-, eligibility-, missingness-, coverage-, age-, deficit- tai
varianttiroolipäätös.

Historiallinen S3-resolveriajo löysi 11 monirivistä henkilöä, joiden TK-päivät
erosivat, ja pysähtyi ennen ledgeriä. Tämä fail-closed-tulos säilyy
provenienssina; myöhempi tutkijapäätös ei muuta same-assessment-sääntöä.

## Primary FI index-assessment ja kaksitasoinen ledger PROJECT_RULE 2026-09-01

Tutkija hyväksyi säännöt `FIRA1-PRIMARY-FI-FIRST-QUALIFYING-TK-1.0.0` ja
`FIRA1-PRIMARY-FI-TWO-LEVEL-LEDGER-1.0.0`. Paper 01 Primary FI:n index on
henkilön kronologisesti ensimmäinen qualifying AUTH_SOURCE TK/tulokäynti,
jolla on validi canonical person identity ja validi auktoritatiivinen TK-päivä.
Muita non-FI qualification-vaatimuksia ei nykyisestä auktoriteetista löytynyt.

Valinta tehdään ennen FI-item-puuttuvuuden, coveragen, FI-eligibilityn,
outcomen, mallijäsenyyden tai target-N:n tarkastelua. Myöhemmät TK-arvioinnit
säilyvät erillisinä assessment-havaintoina eivätkä koskaan täydennä index-
arviointia. Eri TK-päiviä ei yhdistetä aikavälin perusteella. Dokumentoitu
source-authoritative correction/duplicate/replacement-päätös voi myöhemmin
ohittaa tavallisen kronologian vain omalla evidenssillään.

`PERSON_LEDGER` omistaa yhden vakaan henkilörivin per canonical identity;
`ASSESSMENT_LEDGER` omistaa erilliset TK-kontekstit, kronologisen järjestyksen
ja index-statuksen. Tämä PROJECT_RULE ei muuta scoringia, kandidaattiluokkia,
missingness-/coverage-rajoja, age ≥65 -sääntöä, deficit-koostumusta tai FI22:n
sensitivity-only-roolia.

Canonical ledger promotoitiin K40.V2:n diagnostic-first input contractiksi.
Source-derived 527/479 eivät ole target-N-vakioita. Re-anchor ei hyväksynyt
kandidaatteja, scoringia, deficit-settiä tai Primary FI:tä. K18/QC-
ympäristöblocker pitää Candidate Audit Phase 1:n suljettuna.

Canonical ledger on promotoitu K40.V2:n diagnostic-first input contractiksi.
Nykyiset source-derived construction/screening-luvut ovat 527/479, eivät
PROJECT_RULE-vakioita. Pakollinen K18/QC ja re-anchor-conservation läpäisivät
2026-09-01 infrastruktuurikorjauksen jälkeen. Phase 1A avattiin vain
kandidaattigovernancen ja tutkijakatselmointipaketin muodostamiseen; se ei
hyväksynyt kandidaatteja, scoringia, deficit-settiä tai valmista Primary FI:tä.
