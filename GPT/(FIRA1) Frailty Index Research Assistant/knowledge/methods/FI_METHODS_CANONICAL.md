---
title: "FI-menetelmien kanoninen yhteenveto"
status: "SOURCE_COMPLETE_WITH_WARNINGS"
updated: "2026-08-30"
source_basis: "Suoraan tarkastetut Searle ym. 2008, Theou ym. 2023 ja Searle & Rockwood 2024"
canonical_for: "Yleisten FI-kysymysten lähdekohtainen operatiivinen synteesi"
used_when: "Ehdokasvajetta, pisteytystä, puuttuvuutta tai FI-laskentaa arvioidaan"
not_authoritative_for: "FOF/KAAOS-projektipäätökset, muuttujamerkitykset tai kliininen käyttö"
related_files: "../project/FI_PROJECT_SPEC.md; ../sources/FI_SOURCE_STATUS.md"
update_triggers: "Lähde lisätään/tarkastetaan tai lähteiden välillä havaitaan ristiriita"
---

## FI-menetelmien kanoninen yhteenveto

## Auktoriteetti ja lähteiden roolit

- Searle ym. (2008) on suoraan tarkastettu alkuperäinen standardimenettely.
- Theou ym. (2023) on suoraan tarkastettu myöhempi 10-vaiheinen ohje, joka
  perustuu asiantuntijaryhmän evidenssi- ja kokemuskatsaukseen sekä worked
  exampleen.
- Searle & Rockwood (2024) on suoraan tarkastettu myöhempi tiivis synteesi.
- K40/FI22:n säännöt ovat projektikohtaisia ja omistaa
  `project/FI_PROJECT_SPEC.md`; ne eivät muutu yleiseksi metodologiaksi.

## Yhteinen suoraan tuettu ydin

FI kuvaa kertyneiden terveysvajeiden osuutta. Henkilön 0–1-välille koodattujen
vajeiden summa jaetaan häneltä mitattujen FI-muuttujien määrällä. Ehdokkaiden
tulee mitata terveysongelmia, osoittaa asianmukainen ikäyhteys, välttää liian
varhaista saturaatiota ja kattaa useita terveysalueita/järjestelmiä. Molemmat
artikkelit tukevat vähintään noin 30 muuttujan indeksin rakentamista ja samojen
muuttujien käyttämistä pitkittäismittauksissa.

Binäärivaje pisteytetään 0/1. Ordinaali- ja jatkuvat muuttujat voidaan muuntaa
asteikolle 0–1; osittainen vaje on sallittu. Pisteytyksen suunta, tasot,
cut-point tai skaalaus on dokumentoitava eikä sitä saa keksiä muuttujan nimestä.

## Searle ym. 2008: alkuperäinen menettely

Artikkeli esittää viisi ehdokaskriteeriä: muuttuja kuvaa terveydentilan vajetta,
sen prevalenssi yleensä kasvaa iän myötä, se ei saturoidu liian aikaisin,
vajekokonaisuus kattaa useita järjestelmiä ja samassa pitkittäisessä indeksissä
käytetään samoja osia. Artikkeli suosittelee 30–40 vajetta ja toteaa hyvin
pienten, noin 10 tai vähemmän vajetta sisältävien indeksien estimaattien olevan
epävakaita.

Artikkelin esimerkissä binääriset osat ovat 0/1, yksi välitaso voidaan koodata
0.5:ksi ja ordinaali-/jatkuvat osat porrastetaan 0–1-välille. Se käyttää sekä
tunnustettuja rajoja että aineiston/judgementin avulla määritettyjä rajoja;
nämä ovat artikkelin menetelmäesimerkkejä eivätkä valtuuta FIRA1:ää keksimään
uutta kliinistä cut-pointia. Artikkeli tarkastelee ikäyhteyttä, jakaumaa,
ylärajaa ja ennustevaliditeettia kuolleisuudella sekä toteaa, ettei frailtylle
ole gold standardia.

Searle 2008 ei tässä tekstissä aseta Theou 2023:n 5 %:n muuttujapuuttuvuusrajaa
tai 20 %:n henkilökohtaista missing-items-rajaa. Niitä ei saa attribuoida sille.

## Theou ym. 2023: myöhempi 10-vaiheinen ohje

Kymmenen vaihetta ovat: (1) valitse terveysongelmamuuttujat, (2) sulje yleensä
pois yli 5 % puuttuvat muuttujat, (3) koodaa 0–1, (4) käsittele alle 1 %:n
harvinaiset ja yli 80 %:n yleiset/saturoituvat vajeet, (5) tarkista ikäyhteys,
(6) tarkista keskinäinen korrelaatio, (7) laske säilyneet muuttujat, (8) laske
FI, (9) testaa indeksin ominaisuudet ja (10) käytä FI:tä analyysissä.

Ohje täsmentää, että 5 %:n muuttujapuuttuvuusrajaa voidaan nostaa, jos
kelvollisia muuttujia ei muuten ole tarpeeksi, mutta tämä voi poistaa enemmän
henkilöitä vaiheessa 8. Se suosittelee poistamaan toisistaan erittäin
korreloivista (`r > 0.95`) muuttujista sen, jolla on enemmän puuttuvia
vastauksia. FI:tä ei ohjeen mukaan lasketa henkilölle, jolta puuttuu yli 20 %
FI-osista. Nämä ovat Theou 2023:n lähdekohtaisia ohjeita, eivät K40/FI22:n
automaattisia sääntöjä.

Ohje antaa ordinaalipisteytykselle tasavälisiä esimerkkejä (3 tasoa:
0/0.5/1; 4 tasoa: 0/0.33/0.67/1; 5 tasoa: 0/0.25/0.50/0.75/1). Jatkuville
muuttujille se suosii vakiintuneita cut-pointeja; vaihtoehtoinen aineistoon
perustuva skaalaus voi olla huonosti yleistyvä. U-muotoiset riskit voidaan
koodata molemmista ääripäistä vajeiksi, kun tämä perustellaan.

## Redundanttius ja odotetut ominaisuudet

Käsitteellinen redundanttius arvioidaan ensin muuttujien merkityksen ja
domainin perusteella; empiirinen redundanttius arvioidaan tämän jälkeen
ajokohtaisilla diagnostiikoilla. Theou 2023:n `r > 0.95` on lähdekohtainen
ohje, ei lupa sivuuttaa käsitteellistä päällekkäisyyttä eikä universaali
automaattinen poissulkuraja.

Jatkuva tai epälineaarinen, myös U-muotoinen, pisteytys edellyttää
auktoritatiivisesti perusteltua suuntaa, asteikkoa ja rajoja. Puuttuva
ehdokaskohtainen perusta tuottaa `NEEDS_VERIFICATION` tai seuraamuksellisessa
valinnassa `RESEARCHER_DECISION_REQUIRED`.

Ikäyhteys, jakauman oikealle vino muoto ja noin 0.7:n havaittu yläraja ovat
kontekstissa arvioitavia odotettuja ominaisuuksia ja diagnostisia signaaleja,
eivät itsenäisiä universaaleja hard exclusion -lakeja.

## Pitkittäinen vertailukelpoisuus

Saman pitkittäisen FI:n tulee käyttää samoja konstrukteja ja osia. Ennen
pitkittäistä käyttöä on lisäksi varmennettava aallon/aikapisteen semantiikka,
koodaussuunta, vastausasteikko ja mittausajankohta. Jos vastaavuus ei toteudu,
käyttö pysähtyy fail-closed, ellei tutkija ole hyväksynyt lähteistettyä
harmonisointia. Operatiivisen portin omistaa `validation/FI_QC_VALIDATION.md`;
tämä periaate ei itsessään todista aineiston vertailukelpoisuutta.

## Vuoden 2024 synteesi ja erot

Vuoden 2024 luku tiivistää menettelyn yhdeksään rakentamis-/testausvaiheeseen
ja viittaa Theou 2023:een päivityksenä. Se tukee samoja 5 %, 1/80 %,
`r > 0.95` ja vähintään 30 muuttujan ohjearvoja, mutta ei korvaa 2023
artikkelin yksityiskohtaista vaihetta 10 eikä kaikkia sen poikkeuksia.

Lähdekohtaisia eroja ei harmonisoida hiljaisesti. Uusi soveltamiskonteksti,
ristiriitainen cut-point tai seuraamuksellinen poikkeus merkitään
`NEEDS_VERIFICATION`/`RESEARCHER_DECISION_REQUIRED`.

## Tarkastetut lähteet

1. Searle ym. (2008), BMC Geriatrics 8:24. DOI `10.1186/1471-2318-8-24`.
2. Theou ym. (2023), Age and Ageing 52:afad221. DOI
   `10.1093/ageing/afad221`.
3. Searle & Rockwood (2024), “Deficit Accumulation”. DOI
   `10.1007/978-3-031-57361-3_2`.
