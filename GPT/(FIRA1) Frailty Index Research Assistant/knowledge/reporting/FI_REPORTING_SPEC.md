---
title: "FI-raportoinnin määrittely"
status: "VERIFIED_SPEC_WITH_SOURCE_WARNINGS"
updated: "2026-08-30"
source_basis: "Tarkastetut projektisäännöt, K40-output-sopimus ja FIRA1 acceptance criteria"
canonical_for: "FI:n käsikirjoitus-, väitöskirja- ja liiteraportointi"
used_when: "FI-menetelmä, tulos, validointi tai provenienssi kirjoitetaan raporttiin"
not_authoritative_for: "Uudet tieteelliset päätökset tai puuttuvan lähteen sisältö"
related_files: "../project/FI_PROJECT_SPEC.md; ../validation/FI_QC_VALIDATION.md; ../sources/FI_SOURCE_STATUS.md"
update_triggers: "Variantti, analyysirooli, lähde, validointitulos tai raportointikohde muuttuu"
---

## FI-raportoinnin määrittely

## Käsikirjoituksen vähimmäissisältö

Raportoi variantin täsmällinen nimi ja rooli, kohdepopulaatio, tuottaja/versio,
ehdokas- ja poissulkuprosessi, lopullinen vajemäärä, jokaisen vajeen lähteistetty
pisteytys ja suunta, FI-kaava, puuttuvuus- ja kattavuussäännöt, jakauma-QC,
herkkyydet sekä suoritetun validoinnin tyyppi. Erota toteutuksen toimivuus
tieteellisestä validiteetista.

FI22:sta on ilmaistava, että `FI22_nonperformance_KAAOS` on Fear-of-Fallingissa
sensitiivisyysmuuttuja. Sitä ei saa kuvata ensisijaiseksi frailty-mittariksi
ilman uutta hyväksyttyä tutkijapäätöstä.

## Väitöskirjan menetelmäliite

Liitteen tulee sisältää versionoitu vaje-/pisteytystaulukko, lähdemuuttuja,
label, tyyppi, validit tasot, missing-koodit, suunta/kynnys, 0–1-muunnos,
domain, valinta-/poissulkusyy ja lähdeperusta. FI22-liite johdetaan ensisijaisesti
`deficit_map.csv`-kartasta ja ajon `k40_kaaos_selected_deficits.csv`-valinnasta.
Canonical map -omistajuus ja provenienssi ovat `CLOSED`; raportoinnissa käytetään
ajoa `20260831_061227 = CANONICAL_SENSITIVITY_RUN`. Historialliset ajot
`20260831_050926 = SUPERSEDED_SCORING_CONFLICT` ja
`20260320_150123 = LEGACY_PRE_MAP_PROVENANCE` säilytetään provenance-tietona,
ei nykyisinä blockereina.

## Tulosraportointi

- Raportoi aggregaattitasolla osallistujamäärä, laskentakelpoisten määrä/osuus,
  puuttuva FI, vajemäärä ja FI:n keskeinen jakauma.
- Raportoi lattia-/kattoilmiöt, domain-tasapaino ja redundanttius vain
  ajokohtaisen evidenssin perusteella.
- Ilmoita ensisijainen ja sensitiivisyyshaara erikseen.
- Älä kopioi osallistujatason arvoja KB:hen tai käsikirjoitushandoffiin.
- Älä kirjoita “validoitu” ilman nimettyä validointityyppiä ja evidenssiä.

## Lähde- ja epävarmuusmerkinnät

- `NEEDS_SOURCE`: menetelmäväite odottaa tarkastettua primaarilähdettä.
- `NEEDS_VERIFICATION`: toteutus-, schema- tai validointiväite odottaa näyttöä.
- `RESEARCHER_DECISION_REQUIRED`: tulkinta tai rooli vaatii tutkijan päätöksen.
- `REPOSITORY_CONFLICT`: omistaja, versio tai kanoninen polku on ristiriidassa.

Puuttuvaa lähdettä tai päätöstä ei saa häivyttää sujuvaksi raportointitekstiksi.

## FI22:n hyväksytty raportointiprovenienssi

Kanoninen tekninen sensitivity-ajo on `20260831_061227`
(`CANONICAL_SENSITIVITY_RUN`): 22 deficitiä, eligible 502, missing 50, mean
`0.382580535782`, SD `0.129520059529`, min `0.068181818182`, max
`0.674603174603`. Historialliset ajot ovat `20260831_050926` =
`SUPERSEDED_SCORING_CONFLICT` ja `20260320_150123` =
`LEGACY_PRE_MAP_PROVENANCE`. `050926`→`061227`: eligible 502→502 ja mean
`0.362874603448`→`0.382580535782`. Status ei tee FI22:sta ensisijaista tai
täysin validoitua mittaria.
