---
title: "FI-lähteiden tila"
status: "SOURCE_COMPLETE_WITH_WARNINGS"
updated: "2026-08-30"
source_basis: "Searle 2008-, Theou 2023- ja Searle/Rockwood 2024 -PDF:ien suora tarkastus"
canonical_for: "FI-kirjallisuuden saatavuus, tarkastusaste ja lähdepuutteet"
used_when: "Menetelmäväitteen lähdeperusta arvioidaan"
not_authoritative_for: "Projektin toteutussäännöt tai lähteen soveltamisalan ylittävät päätelmät"
related_files: "../methods/FI_METHODS_CANONICAL.md; ../KB_INDEX.md"
update_triggers: "Lähde lisätään, korvataan, ristiriita havaitaan tai provenienssi täsmentyy"
---

## FI-lähteiden tila

## Tarkastettu evidenssitaulukko

| Repository path                                                                                                 | Julkaisun identiteetti                                                                                                                                                                                         | Evidenssitaso                                                                             | Metodologinen rooli                                     | Täydellisyys/käyttökelpoisuus                                                                  | Tila                |
| --------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- | ------------------------------------------------------- | ---------------------------------------------------------------------------------------------- | ------------------- |
| `GPT/(FIRA1) Frailty Index Research Assistant/Searle2008.pdf`                                                   | Searle, S. D., Mitnitski, A., Gahbauer, E. A., Gill, T. M. & Rockwood, K. (2008), _A standard procedure for creating a frailty index_. BMC Geriatrics 8:24. DOI `10.1186/1471-2318-8-24`                       | Suora PDF-tarkastus: nimiö, abstrakti, menetelmät, tulokset, keskustelu ja lähteet        | Alkuperäinen/primaarinen FI-rakentamisen menetelmälähde | 10/10 sivua, jatkuva tekstikerros ja lopullinen viitesivu; käyttökelpoinen metodisynteesiin    | VERIFIED            |
| `GPT/(FIRA1) Frailty Index Research Assistant/Theou2023.pdf`                                                    | Theou, O., Haviva, C., Wallace, L., Searle, S. D. & Rockwood, K. (2023), _How to construct a frailty index from an existing dataset in 10 steps_. Age and Ageing 52:1–7, afad221. DOI `10.1093/ageing/afad221` | Suora PDF-tarkastus: nimiö, abstrakti, 10 vaihetta, worked example, keskustelu ja lähteet | Myöhempi yksityiskohtainen menetelmäohje                | 7/7 sivua, jatkuva tekstikerros ja vastaanotto-/päätöspäivä; käyttökelpoinen metodisynteesiin  | VERIFIED            |
| `GPT/(FIRA1) Frailty Index Research Assistant/Frailty - A Multidisciplinary Approach to Assessment.pdf`, luku 2 | Searle, S. D. & Rockwood, K. (2024), “Deficit Accumulation”, teoksessa Ruiz & Theou (toim.), _Frailty_. DOI `10.1007/978-3-031-57361-3_2`                                                                      | Suora luvun tarkastus                                                                     | Myöhempi auktoritatiivinen synteesi                     | Painetut sivut 11–14 tarkastettu; käyttökelpoinen kontekstiksi ja lähteiden väliseksi sillaksi | VERIFIED            |
| Sama 2024-teos, nimiö                                                                                           | Ruiz, J. G. & Theou, O. (toim.) (2024), _Frailty: A Multidisciplinary Approach to Assessment, Management, and Prevention_. ISBN 978-3-031-57360-6; eISBN 978-3-031-57361-3; DOI `10.1007/978-3-031-57361-3`    | Suora nimiötarkastus                                                                      | Toimitettu teos                                         | Identiteetti varmennettu; aiempi `Frailty_2024`-lead ratkaistu                                 | VERIFIED            |
| `Electronic-Frailty-Index/docs/EFI_MINIMUMS.md`                                                                 | Synteettisen EFI-demon ohje                                                                                                                                                                                    | Suora repoasiakirjan tarkastus                                                            | Negatiivinen rajaus                                     | Ei tutkimus-FI:n menetelmäauktoriteetti                                                        | VERIFIED_SCOPE_ONLY |

## Provenienssi- ja käyttöraja

PDF:ien sisäinen bibliografinen identiteetti ja sisällön täydellisyys on
varmennettu. Tiedostojen repo-hankintaketjua tai kustantajalähteen ulkoista
tarkistussummaa ei ole tässä tehtävässä todistettu; tämä on
`NEEDS_VERIFICATION`, mutta ei estä paikallisen sisällön lähdekohtaista käyttöä.
Pitkiä tekstijaksoja ei kopioida KB:hen.

## Ratkaisemattomat asiat

- `NEEDS_VERIFICATION`: kahden uuden PDF:n repo-hankintaprovenienssi.
- `NEEDS_SOURCE`: laajempi hyväksytty Rockwood/Mitnitski-lähdekokoelma, jos
  tuleva tehtävä tarvitsee väitteitä näiden kolmen varmennetun lähteen yli.
- Kirjallisuuslähteiden välisiä aktiivisia ristiriitoja ei ole tunnistettu.
  Repository-polkujen ja toteutusartefaktien ristiriidat omistaa
  `computational/FI_R_WORKFLOW.md`, eivät lähdestatukset.

## Grip-kirjallisuuden claim-audit 2026-09-02

- `Searle2008.pdf` on grip-claimien osalta suoraan varmennettu: Table 1 sisältää
  mitatun Grip Strength -itemin ja Table 2 sex/BMI-spesifiset binääriset
  kg-cutoffit. Searlen viisitasoinen tasaväli on self-rated-health-esimerkki,
  ei universaali grip-sääntö.
- `Theou2023.pdf` varmentaa yleisen viiden ordinal-tason
  `0/0.25/0.50/0.75/1`-ohjeen, valid-item-denominatorin ja `r > 0.95`
  -korrelaatioseulan; se ei ole grip-spesifi lähde.
- `grip_strength_FI-deficit.md` on `DERIVED_UNVERIFIED`. Sen claim-audit löytyy
  `../registry/GENERAL_FI_GRIP_LITERATURE_CLAIM_VERIFICATION_20260902.csv`.
- `NEEDS_SOURCE`: Theou 2013 full text/supplement, Blodgett 2015
  full text/appendix, Williams 2019, Wallace 2015, Mitnitski 2001 ja Howlett
  2014, jos niiden täsmällisiä grip-, unable-, spacing- tai representation-
  väitteitä halutaan käyttää. Noten bibliografia ei yksin varmista niitä.
- Blodgett-claim on nykyisellään misattribuoitu: note kutsuu sitä ELSAksi,
  vaikka sen oma viite nimeää NHANESin.

Nämä lähdestatukset eivät hyväksy projektin grip-scoringia, `E`-käsittelyä tai
bilateral representationia eivätkä sulje
`ORIGINAL_THRESHOLD_PROVENANCE=NEEDS_SOURCE`-aukkoa.
