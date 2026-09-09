---
title: "FIRA1 Knowledge Base -indeksi"
status: "READY_WITH_EXPLICIT_EXTERNAL_DEPENDENCIES"
updated: "2026-09-01"
source_basis: "Tarkastettu live-repositorio, audit 1 ja varmennetut FI-lähteet"
canonical_for: "FIRA1:n reititys, omistajuuskartta, aktiivinen inventaario ja authority hierarchy"
used_when: "Aina FIRA1-tehtävän ensimmäisenä KB-tiedostona"
not_authoritative_for: "Menetelmäväitteet, kandidaatipäätökset, osallistujadata tai uudet tutkijapäätökset"
related_files: "sources/FI_SOURCE_STATUS.md; methods/FI_METHODS_CANONICAL.md; project/DATA_DICTIONARY.md; project/FI_PROJECT_SPEC.md; computational/FI_R_WORKFLOW.md; validation/FI_QC_VALIDATION.md; reporting/FI_REPORTING_SPEC.md; registry/FI_CANDIDATE_REGISTRY.csv; registry/FI_CHANGELOG.md"
update_triggers: "Omistaja, route, status, variantti tai aktiivinen inventaario muuttuu"
---

## FIRA1 Knowledge Base -indeksi

## Scope ja authority hierarchy

Tämä tiedosto on router/control plane, ei toinen menetelmä-, lähde-, registry-
tai run-history-omistaja. Universal FI methodology -väitteissä järjestys on:

1. varmennettu suora primaarimenetelmälähde;
2. varmennettu myöhempi yksityiskohtainen metodiohje;
3. varmennettu myöhempi auktoritatiivinen synteesi;
4. `methods/FI_METHODS_CANONICAL.md`, jonka väitteet perivät auktoriteetin
   viitatuilta lähteiltä;
5. specialist FI/frailty -kirjallisuus;
6. yleinen kliininen/geriatrinen kirjallisuus.

Erillinen PROJECT LAYER sisältää hyväksytyt projektipäätökset, auktoritatiivisen
dataset-scheman ja registry-tilan. IMPLEMENTATION FACTS tulevat aktiivisesta
koodista, repository-schemasta ja run-evidenssistä; ne eivät todista
tieteellistä validiteettia.

## Tehtäväreititys

| Tehtävä                         | Ensisijainen reitti                                  | Kontrolli/write-back                                      |
| ------------------------------- | ---------------------------------------------------- | --------------------------------------------------------- |
| Semantiikka, timing, coding     | Data Dictionary → authoritative source schema        | `NEEDS_VERIFICATION`/`UNKNOWN` jos puutteellinen          |
| Deficit-kelpoisuus              | Dictionary → Methods → Project role screen           | Registry recommendation; ei automaattista päätöstä        |
| Exclusion/circularity           | Dictionary → Project Spec                            | Registry; Methods tarvittaessa                            |
| Scoring                         | Dictionary → Methods → underlying source             | Project/Registry; consequential choice vaatii hyväksynnän |
| Missingness/prevalence/age      | Methods                                              | Diagnostics + Project Spec                                |
| Conceptual/empirical redundancy | Methods → Dictionary / run diagnostics               | Registry tutkijakontrollilla                              |
| Domain breadth ja FI-laskenta   | Methods → Project Spec → Workflow                    | QC evidence                                               |
| Pitkittäinen FI                 | Methods → Dictionary wave metadata → Validation gate | Fail-closed tai hyväksytty harmonisointi                  |
| Validointi/sensitivity          | Validation                                           | Methods + Project + run evidence → Reporting              |
| R/provenance/repo conflict      | R Workflow                                           | Active code/schema; Changelog canonical muutoksille       |
| Source gap/conflict             | Source Status                                        | Competing sources; `NEEDS_SOURCE`                         |
| Candidate current state         | Candidate Registry                                   | Changelog history                                         |
| Raportointi                     | Reporting Spec                                       | Methods + Project + Registry + QC + Source Status         |

## Kanoninen omistajuus ja aktiivinen inventaario

| Resurssi                                   | Kanoninen omistajuus                                           | Tila                          |
| ------------------------------------------ | -------------------------------------------------------------- | ----------------------------- |
| `sources/FI_SOURCE_STATUS.md`              | Lähdeidentiteetti, saatavuus, source-conflicts, `NEEDS_SOURCE` | SOURCE_COMPLETE_WITH_WARNINGS |
| `methods/FI_METHODS_CANONICAL.md`          | Universal FI methodology synthesis                             | SOURCE_COMPLETE_WITH_WARNINGS |
| `project/DATA_DICTIONARY.md`               | Muuttujasemantiikka/timing/source-schema routing               | PARTIAL_NEEDS_VERIFICATION    |
| `project/FI_PROJECT_SPEC.md`               | Variant roles, PROJECT_RULEs, project decisions                | VERIFIED_WITH_OPEN_ITEMS      |
| `computational/FI_R_WORKFLOW.md`           | Toteutus, dataflow, outputs, run evidence, repo conflicts      | VERIFIED_WITH_GATES           |
| `validation/FI_QC_VALIDATION.md`           | QC taxonomy, T01–T12, longitudinal gate                        | IMPLEMENTED_TEST_SPEC         |
| `reporting/FI_REPORTING_SPEC.md`           | Methods/results/appendix reporting                             | VERIFIED_SPEC                 |
| `registry/FI_CANDIDATE_REGISTRY.csv`       | Candidate/variant current state                                | ACTIVE_CONTROLLED             |
| `registry/FI_CHANGELOG.md`                 | Append-only history ja supersession                            | ACTIVE                        |
| `archive/FIRA1_IMPLEMENTATION_EVIDENCE.md` | Historiallinen initial-build snapshot                          | ARCHIVED_NOT_ACTIVE           |

Underlying verified sources ovat `../../Searle2008.pdf`,
`../../Theou2023.pdf` ja `../../Frailty - A Multidisciplinary Approach to Assessment.pdf`
luvun 2 osalta. Archive ei kuulu aktiiviseen runtime-retrievaliin.

## Nykyinen projektikonfiguraatio ja variantit

- K40.V2 on Paper 01:n tutkimus-FI; sen thresholdit ja coverage ovat
  `PROJECT_RULE`-sääntöjä Project Specissä.
- `FI22_nonperformance_KAAOS` on sensitivity-only.
- `20260831_061227 = CANONICAL_SENSITIVITY_RUN`; map provenance `CLOSED`,
  22/22 scoring concordant.
- `20260831_050926 = SUPERSEDED_SCORING_CONFLICT` ja
  `20260320_150123 = LEGACY_PRE_MAP_PROVENANCE` ovat historiallisia.
- Primary FI Candidate Audit Phase 1B on toteutettu 63 canonical kandidaatin
  scoped-semantics- ja Paper 01 study-role -katselmointipakettina. Seitsemän
  semantiikkavajetta jää avoimeksi; kaikki roolit ovat provisiorisia ja
  tutkijapäätöstä odottavia. Phase 1C ei ole valtuutettu.
- Primary FI same-assessment-, first-qualifying-TK- ja two-level-ledger-
  PROJECT_RULEt on hyväksytty. Suojatut PERSON_LEDGER ja ASSESSMENT_LEDGER on
  rakennettu tilaan `PRIMARY_FI_LEDGER_READY_FOR_RESEARCHER_REVIEW` ilman
  execution-critical HITL-tapauksia; myöhemmät TK-arvioinnit säilyvät
  erillisinä. Yksityiskohtaiset säännöt kuuluvat Project Speciin, semantiikka
  Data Dictionaryyn, toteutus R Workflow'hun ja aggregate receipt tiedostoon
  `project/PRIMARY_FI_TWO_LEVEL_LEDGER_RECEIPT_20260901.md`. Downstream ei ole
  käynnistynyt.

## Status ownership ja avoimet dependencyt

`VERIFIED` ja `NEEDS_VERIFICATION` kuuluvat proposition domain ownerille;
`PROJECT_RULE` Project Specille; `NEEDS_SOURCE` Source Statusille;
`UNKNOWN` sille domain ownerille, jolta vaadittu tieto puuttuu;
candidate-`RESEARCHER_DECISION_REQUIRED` Registrylle ja variant/project-status
Project Specille; implementation-`REPOSITORY_CONFLICT` R Workflowlle.

Avoimet, ei-kriittiset dependencyt:

- paikallisten PDF:ien ulkoinen hankintaprovenienssi: `NEEDS_VERIFICATION`;
- nykyisen tuen ylittävä metodologia: `NEEDS_SOURCE`;
- täydellinen FOF/KAAOS candidate-variable schema, valid levels, missing codes
  ja wave metadata: `NEEDS_VERIFICATION`/`UNKNOWN`;
- Primary FI Candidate Audit Phase 1B: 63/63 `RESEARCHER_DECISION_REQUIRED`;
  verdict `PHASE1B_READY_WITH_SEMANTIC_GAPS`.
- Primary FI ledger: suojattu kaksitasoinen ledger odottaa tutkijakatselmointia
  ennen promotionia tai K40/K33/K50/FI-resumea.
- K40.V2 käyttää canonical `PRIMARY_FI_INDEX`-anchorin diagnostic-first-haaraa.
  Required K18/QC, manifest-skeema ja analytical conservation läpäisivät
  2026-09-01. Phase 1A:n 63 kandidaattia ovat semantics-first-review-tilassa;
  Phase 1B, scoring, Primary FI ja downstream eivät ole alkaneet. Aggregate
  receipt: `project/K40_CANONICAL_REANCHOR_DIAGNOSTIC_RECEIPT_20260901.md`.

## Tutkijan kontrolli ja päivityskäytäntö

GPT-suositus ei ole tutkijapäätös. Uusi deficit, scoring, cut-point, domain,
harmonisointi, poikkeus tai varianttirooli vaatii lähdeperustan ja tarvittaessa
eksplisiittisen hyväksynnän. Päivitä aina domain owner ensin, sitten Registry ja
Changelog soveltuvin osin ja tämä indeksi viimeisenä. Aja T01–T12 muutosten
jälkeen. Raaka- tai osallistujadataa ei kopioida KB:hen.
