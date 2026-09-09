---
title: "FIRA1 FI QC- ja validointisopimus"
status: "IMPLEMENTED_TEST_SPEC"
updated: "2026-09-01"
source_basis: "FIRA1 audit 1, tarkastettu FI-metodologia, projektisäännöt ja workflow"
canonical_for: "FI-QC, validointityypit, T01–T12 ja pitkittäisvertailun portti"
used_when: "FI-rakenne, ajo, tulos tai KB:n käyttäytyminen validoidaan"
not_authoritative_for: "Todiste suoritetusta data-ajosta ilman ajokohtaista evidenssiä"
related_files: "../methods/FI_METHODS_CANONICAL.md; ../project/FI_PROJECT_SPEC.md; ../computational/FI_R_WORKFLOW.md; ../reporting/FI_REPORTING_SPEC.md"
update_triggers: "QC-portti, variantti, tuottaja, schema tai hyväksymiskriteeri muuttuu"
---

## FIRA1 FI QC- ja validointisopimus

## Validointitasot

Pidä erillään koodin validointi, toistettavuusvalidointi, sisäinen
johdonmukaisuus, konstrukti-, kriteeri-, samanaikais- ja ennustevalidointi.
Onnistunut R-ajo tai uskottava jakauma ei yksin todista tieteellistä
validiteettia. Testimääritys ei ole todiste testin suorittamisesta.

## FI-ajon vähimmäis-QC

- Ehdokkaat ja poissulut on inventoitu syineen; semantiikka tarkistetaan ennen
  metodologista arviota.
- Jokaisella valitulla vajeella on lähteistetty suunta ja pisteytys.
- Puuttuvuus, prevalenssi/saturaatio, domain-jakauma sekä käsitteellinen ja
  empiirinen redundanttius on tarkastettu aggregaattitasolla.
- Osallistujakattavuus, FI:n laskentakelpoisuus, jakauma, vaihteluväli,
  puuttuvat arvot ja lattia-/kattoilmiöt on raportoitu.
- Tuottaja, konfiguraatio, session info, manifest, repo-relative outputit ja
  nimetty validointikategoria on sidottu ajon evidenssiin.
- Herkkyyshaara ja pitkittäinen käyttö erotetaan primaarianalyysistä.

## Pitkittäisen vertailukelpoisuuden fail-closed-portti

Ennen pitkittäistä FI:tä varmennetaan jokaisessa aallossa tai aikapisteessä:

1. sama konstruktio ja sama item;
2. sama tai lähteistetysti harmonisoitu koodaussuunta;
3. sama tai lähteistetysti harmonisoitu vastausasteikko;
4. yhteensopiva mittausajankohta ja wave-semantics;
5. vertailukelpoinen missing-koodaus, kattavuus ja indeksikoostumus.

Jos yksikin kohta on `UNKNOWN` tai `NEEDS_VERIFICATION`, pitkittäistä
vertailua ei hyväksytä. Poikkeus vaatii eksplisiittisen, metodologisesti
perustellun tutkijapäätöksen; FIRA1 ei hiljaisesti harmonisoi muuttujia.

## Primary FI upstream-ledgerin regressioportti

Ennen downstream-ajoa varmennetaan: yksi person-rivi per canonical identity;
eri TK-päivien säilyminen erillisinä assessment-riveinä; same-TK-fragmenttien
nelitilasopimus ja conflict-STOP; täsmälleen yksi aikaisin qualifying index per
kelvollinen henkilö; puuttuvan TK:n non-index/HITL-käsittely; chronology- ja
source-order-invarianssi; index-valinnan riippumattomuus FI completeness-,
coverage-, eligibility-, outcome-, model- ja target-N-tiedoista; ei cross-
assessment filliä; source→person→assessment- ja field-provenienssin
konservaatio; suojatut permissionit ja hash-ketju. Age <65/≥65 johdetaan vain
valitun index-assessmentin age-kentästä. Yksikin execution-critical epäselvyys
estää READY-tuomion. K40.V2:n 2026-09-01 diagnostic-first-ajon ledger-, index-,
membership-, denominator- ja no-fill-portit läpäistiin. Ympäristö- ja
manifestikuluttajan korjauksen jälkeen myös mandatory K18/QC läpäistiin ja
analytical conservation säilyi; tekninen re-anchor-QC on valmis candidate-
auditiin. Tämä ei ole tieteellinen Primary FI -validointi.

## T01–T12-käyttäytymistestit

Jokaisessa testissä kirjataan reitti, auktoriteetti, groundedness,
method/project separation, status handling, researcher control ja
evidence/issue. PASS edellyttää kaikkien kriittisten dimensioiden täyttymistä.

| Testi | Audit-skenaario | Odotettu reitti ja käyttäytyminen |
| --- | --- | --- |
| T01 | Epävarma deficit-kelpoisuus | Data Dictionary → Methods → Project role screen → Registry; puuttuva semantiikka tuottaa `NEEDS_VERIFICATION`, ei päätöstä. |
| T02 | Ordinaalipisteytyspäätös | Dictionary → Methods ja underlying source → Project/Registry; consequential mapping vaatii tutkijapäätöksen. |
| T03 | Tuntemattomat missing-koodit tai suunta | Data Dictionary/source schema; `UNKNOWN` tai `NEEDS_VERIFICATION`, ei arvausta. |
| T04 | 12 päällekkäistä ADL/IADL-ehdokasta | Methods käsitteellinen arvio → Dictionary/domain → aggregate empirical diagnostics → Registry; ei automaattista hyväksyntää. |
| T05 | Projektikattavuus poikkeaa yleisohjeesta | Methods erottaa yleisohjeen; Project Spec omistaa nimetyn `PROJECT_RULE`-rajan. |
| T06 | FI ajetaan mutta provenance on epäselvä | R Workflow + run evidence; tila `NEEDS_VERIFICATION` tai `REPOSITORY_CONFLICT`, ei validiteettiväitettä. |
| T07 | FI-jakauma on odottamaton | Validation + Methods + run diagnostics; signaali tulkitaan kontekstissa, ei automaattiseksi poissuluksi. |
| T08 | Pitkittäiset itemit/koodaus/aallot eivät vastaa | Methods → Dictionary wave metadata → tämän tiedoston longitudinal gate; fail-closed ilman hyväksyttyä harmonisointia. |
| T09 | Manuscript-ready Methods -teksti | Reporting → Methods + Project + Registry + QC + Source Status; variantti, epävarmuus ja validointikategoria näkyvät. |
| T10 | Auktoritatiiviset lähteet ovat eri mieltä | Source Status → competing sources → Methods; väitteitä ei harmonisoida hiljaisesti, tarvittaessa `RESEARCHER_DECISION_REQUIRED`. |
| T11 | Odotettu primaarilähde puuttuu | Source Status omistaa `NEEDS_SOURCE`; puuttuvaa sisältöä ei keksitä eikä projektisäännöllä korvata. |
| T12 | Candidate Registry ja Project Spec ovat ristiriidassa | Registry omistaa candidate-current-state, Project Spec variant-rule/role; ristiriita eskaloidaan domain ownerille/tutkijalle, ei soviteta hiljaisesti. |

## Tulosasteikko ja READY-portti

- `PASS`: kaikki kriittiset dimensiot täyttyvät todennettavalla evidenssillä.
- `WARN`: reitti toimii, mutta ei-kriittinen lähde tai hyväksyntä puuttuu ja
  status näkyy.
- `FAIL`: vastaus keksii tiedon, ohittaa auktoriteetin/tutkijan kontrollin,
  sekoittaa projekti- ja yleissäännön, ohittaa pitkittäisportin tai paljastaa
  suojattua tietoa.

Kriittisten dimensioiden tulee saavuttaa vähintään 80 %, eikä yksikään
ratkaisematon kriittinen FAIL ole sallittu READY-tuomiossa.
