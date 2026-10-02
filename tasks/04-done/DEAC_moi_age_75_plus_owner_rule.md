# DEAC: MOI-ikäpisteet 75 vuotta täyttäneille

## Tila

- State: `04-done`
- Ownerin täsmennys: 2026-10-01
- Lähtöcommit: PR #174:n mergeen sisältynyt MOI-toteutus

## Auktoriteetti ja rajaus

- Owner vahvisti 2026-10-01, että Waris 2011 -pisteytyksen viimeinen
  ikäluokka tarkoittaa 75 vuotta täyttäneitä: lähtötilanteen ikä `>= 75`
  antaa 6 MOI-ikäpistettä.
- Waris 2011 §4.1:n lähdetekstin viimeinen ikämerkintä on `75 years`;
  `>=75` on Ownerin tulkinta, eikä sitä esitetä artikkelin eksplisiittisenä
  ikärajana.
- Ownerin täsmennys kirjattiin yksityiseen päätöslokiin tunnuksella
  `DMA1-D-012` ja kanoniseen `METHODS_AND_SCORING.md` §3.1:een. Julkinen
  handover 1.2.0 sisältää saman rajatun säännön.
- Provenienssiviitteet: METHODS SHA-256
  `4FD2DDF3D19268FEF09B90AA0D7AD8095DADB417B2601238FCFBEBF1EC7AAAEF`,
  päätösloki SHA-256
  `131DAB0920ED047422B5F228980489BAB29973E382B8A29BB6909FE6DB82C480`,
  handover SHA-256
  `B8527242BF9718ECBADDEE6514837B2AD4F1B77C99B55BD18DAF26ABE3A00890`.
  Yksityisiä lähdetiedostoja ei kopioida tähän julkiseen tehtävään.
- Tämä täsmentää nykyisen synteettisen apufunktion rajausta. Muita
  ikäluokkia, kvintiilisääntöä tai DEAC-komponentteja ei muuteta.
- Muuta lähtötilanteen MOI-indeksistä ikäpisteet täsmälleen kerran.
- Osallistuja-aineistoa tai suojattuja lähdekenttiä ei lueta, eikä tässä
  tehtävässä toteuteta lähdeadapteria tai tuotantoajoa.

## Tehtävä

- Päivitä `waris_2011_age_points` palauttamaan 6, kun lähtötilanteen ikä on
  vähintään 75 vuotta.
- Lisää synteettiset testit vähintään iille 75, 76 ja 80 sekä varmista, että
  MOI-ikäpisteet vähennetään indeksistä vain kerran.
- Päivitä rajauksen kuvaus README:ssä ja kirjaa Ownerin täsmennyksen
  provenienssi tähän tehtävään. Älä keksi päätöstunnusta tai viestin
  kellonaikaa.

## Definition of Done

- [x] Ikäluokat 55–59, 60–64, 65–69 ja 70–74 säilyvät ennallaan; ikä `>=75`
  palauttaa 6.
- [x] Synteettiset testit kattavat ikävuodet 75, 76 ja 80 sekä kertaluonteisen
  vähennyksen.
- [x] README ja tehtävä kuvaavat Ownerin hyväksymän rajan; kvintiilit ja muut
  DEAC-säännöt eivät muutu.
- [x] Ei raakadataa, lähdeheadereita, tuotantoajoa tai lähdeadapteria.
- [x] Kohdennetut testit ja repository-gate validoitiin ennen katselmointia.
- [x] Ownerin päätösprovenienssi on todennettu PR #176:n merge-reviewsta;
  sama tehtävätiedosto sisältyi hyväksyttyyn PR-diffiin.

## Loki

- 2026-10-01: tehtävä luotu Ownerin nimenomaisella ohjeella; tämä tehtävä
  kirjaa Ownerin täsmennyksen `age >= 75 → 6` paikallisen toteutuksen
  provenienssiksi. Osallistuja-aineistoa ei käytetty.
- 2026-10-01: tehtävä valittiin ready-jonosta ja siirrettiin
  `02-in-progress`-tilaan ennen toteutuksen muuttamista.
- 2026-10-01: toteutettu `age >= 75 → 6`; lisätty synteettiset rajatestit
  ikävuosille 75, 76 ja 80 sekä ikäpisteiden kertaluonteiselle vähennykselle.
- 2026-10-01: dokumentaatio erottaa Waris 2011:n ilmauksen `75 years`
  Ownerin 2026-10-01 vahvistamasta `age >= 75 → 6` -tulkinnasta. Kanonisen
  DMA1-kirjauksen ja handoverin päivitys valmistellaan erillisenä katselmointina.
- 2026-10-01T19:54:15+03:00: Kohdennetut MOI-, komponentti- ja kokoajatestit
  läpäisivät (`253 passed`); `bash tools/run-gates.sh --mode pre-push --smoke`
  ja `git diff --cached --check` läpäisivät. Tehtävä siirrettiin
  `03-review`-tilaan. Osallistuja-aineistoa ei luettu.
- 2026-10-02: Vahvistettu sääntö kirjattiin Ownerin toimittaman tiedon mukaan
  yksityiseen `DECISION_LOG.md`-tiedostoon tunnuksella `DMA1-D-012` ja
  kanonisen `METHODS_AND_SCORING.md` §3.1:een. Julkiset, muuttumattomat
  lähdeviitteet: päätöslokin SHA-256
  `131DAB0920ED047422B5F228980489BAB29973E382B8A29BB6909FE6DB82C480` ja
  METHODS-tiedoston SHA-256
  `4FD2DDF3D19268FEF09B90AA0D7AD8095DADB417B2601238FCFBEBF1EC7AAAEF`.
  Yksityisiä tiedostoja tai niiden sisältöä ei lisätty julkiseen repoon.
- 2026-10-02T09:45:10Z: Owner `Tupatuko2023` yhdisti PR #176:n
  (`https://github.com/Tupatuko2023/Python-R-Scripts/pull/176`), jonka
  muutoksissa tämä tehtävä oli mukana; merge-commit
  `552a283848c56d384186a1fb5ce4f7df50db9d0e`. Tämä on riippumaton
  hyväksyntänäyttö tehtävän sisällölle SKILLS.md:n mukaisesti.
- 2026-10-02: Tehtävä siirrettiin teknisesti `04-done`-tilaan saman tehtävän
  hyväksytyn review-sisällön sulkemiseksi. Elinkaarisiirto julkaistaan omassa
  Ownerin arvioitavassa PR:ssä.
