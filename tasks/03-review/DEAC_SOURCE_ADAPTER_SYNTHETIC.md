# DEAC:n KAAOS-lähdeadapterin synteettinen rajapinta

## Tavoite

Toteuta suojattavalla, ajon aikana annettavalla kenttäkartalla konfiguroitava
adapteri, joka normalisoi lähtötilanteen KAAOS-arvot nykyisille DEAC-komponenteille
ja 20-paikkaiselle kokoajalle. Tämä tehtävä ei vahvista K40-snapshotia
tuotantolähteeksi eikä sisällä osallistujatason ajoa.

## Auktoriteetti ja rajat

- Käytä `DEAC-Frailty-Index/docs/DEAC_HANDOVER.md` v1.2.0:aa; sen SHA-256
  on `b8527242bf9718ecbaddee6514837b2ad4f1b77c99b55bd18daf26abe3a00890`.
- Käytä olemassa olevia pisteytysfunktioita ja `assemble_deac_index`-kokoajaa.
- Todelliset lähdeheaderit, lähdekoodistot ja kenttäkartta pysyvät repo- ja
  PR-sisällön ulkopuolella. Julkisessa koodissa on vain synteettisiä aliasnimiä.
- Puuttuva tai tuntematon arvo ei saa muuttua hiljaisesti nollaksi.
- E/E1-merkintöjä ei tulkita yleissääntönä. Testituloksen erityiskoodin
  merkitys on annettava komponentti-/testikohtaisena luokituksena.
- Adapteri ei valitse mittausyritystä, kättä tai jalkaa. Se saa vain jo
  valmiiksi valitun semanttisen tuloksen.
- Älä avaa `DATA_ROOT`ia tai osallistujarivejä, älä tallenna suojattuja
  headereita, koodistoja tai esimerkkirivejä.

## Toteutuksen rajaus

- Normalisoi konfiguroidut kentät semanttisiin syötteisiin ja kutsu nykyisiä
  DEAC-scorereita sekä 20-paikkaista kokoajaa.
- MOI: lähtötilanteen ikäpisteitä sisältävä kokonaisarvo miinus lähtötilanteen
  ikäpisteet täsmälleen kerran; käytä ulkoa annettuja, hyväksyttyyn
  lähtötilanteen kohorttiin sovitettuja kvintiilirajoja.
- Kipu: hyväksy vain pisteytysfunktiolle normalisoitu 0–10 cm-arvo; älä tee
  mm→cm-muunnosta ilman varmennettua kenttäsidontaa.
- SLS ja puristus: käytä jo valittua paremman jalan aikaa ja paremman käden
  lähdeluokkaa; älä johda valintaa legacy-skeemasta.
- Kävely: muunna jo valittu 10 metrin aika nopeudeksi `10 / sekunnit`;
  älä valitse yritystä tai apuvälinetilannetta.
- Fyysisten testien mitattu tulos, fyysinen/toiminnallinen kyvyttömyys,
  muu suorittamatta jääminen ja ei-sovellettavuus ovat erillisiä semanttisia
  tiloja. Tuntematon testikohtainen erityiskoodi pysähtyy näkyvään virheeseen.

## Avoimet lähdesidonnat

Varmista suojatusta kartasta ja hyväksytyistä protokollista ennen
tuotantoadapteria: MOI-indeksin ja lähtöiän tarkat kentät; VAS:n tallennusyksikkö;
paremman jalan ja käden muodostussäännöt; 10 m:n käytetty mittaus ja
mahdolliset yritys-/apuvälinevalinnat; sekä E/E1:n testikohtainen merkitys.

## Definition of Done

- Synteettiset testit kattavat kaikki 20 paikkaa, puuttuvuuden,
  ei-sovellettavuuden, testikohtaiset suoriutumistilat ja tunnetut scorer-rajat.
- Tuntematon header, koodi, kenttä tai osittain puuttuva neurologinen yhdistelmä
  ei johda hiljaiseen pisteeseen.
- Ei tuotantoaineiston lukua, source-headerien julkaisemista tai tieteellisten
  sääntöjen muutoksia.
- Soveltuvat DEAC-testit sekä tarkastettu repository-gate läpäisevät.
- README kuvaa selvästi synteettisen rajapinnan ja tuotantokenttäsidonnan
  keskeneräisyyden.

## Työloki

- 2026-10-02T13:52:39+03:00: Tehtävä luotiin orkestroijan ohjeesta valmiiksi
  valittavaksi. Julkisesta checkoutista ei löytynyt PPTX-/TOIMIVA-ohjetiedostoja
  eikä suojattua kenttäkarttaa; tästä syystä toteutus pidetään
  konfiguroitavana ja synteettisenä.
- 2026-10-02T13:53:00+03:00: Tehtävä siirrettiin `02-in-progress`-tilaan.
  Tarkastettu `tools/run-gates.sh --mode pre-push --smoke` läpäisi (exit 0);
  gate lukee vain repositoryn policyt, staged guardrails, renv-lockin ja
  tarvittaessa staged-koodin syntaksin.
- 2026-10-02T14:00:40+03:00: Lisätty runtime-konfiguroitava synteettinen
  adapteri. Se käyttää vain semanttisia kenttiä, erottaa puuttuvuuden,
  ei-soveltuvuuden ja testikohtaiset suoriutumistilat sekä kytkee pisteet
  20-paikkaiseen kokoajaan. VAS-arvo oletetaan jo cm-asteikolle normalisoiduksi;
  10 m sekunnit muunnetaan nopeudeksi vain jo valitusta tuloksesta.
- 2026-10-02T14:00:40+03:00: Kohdennetut DEAC-pytestit läpäisivät: 264 testiä.
  Ei osallistujarivejä tai suojattua lähdekarttaa käytetty.
- 2026-10-02T14:02:06+03:00: Korjattu testiajon aikana havaittu testin
  odotusarvo-/importtivirhe; lopullinen DEAC-ajokokonaisuus läpäisi 264/264.
  Staged `tools/run-gates.sh --mode pre-push --smoke` läpäisi (exit 0), mukaan
  lukien staged Python-syntaksitarkistus. Työ toimitetaan Ownerin review'hun;
  tuotantokenttäsidonta ja protokollavarmennus eivät sisälly tähän synteettiseen
  PR-ehdotukseen.
- 2026-10-02T15:12:43+03:00: PR #178:n Sourcery-katselmointi osoitti, että
  virheellisen gait-sidonnan testin raises-lohko oli epäselvä. Siirrettiin
  konfiguraation rakentaminen lohkon ulkopuolelle, jotta testi kohdistuu
  adapterin validointiin; ajetaan kohdennetut testit ja portit uudelleen.
