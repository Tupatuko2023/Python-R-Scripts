# DEAC v2:n kuvaileva mittariarviointi

## Status

- State: 03-review
- Priority: High
- Assignee: Termux DEAC agent

## Tausta

DEAC v2:n hyväksytty laskentatoteutus on mainissa. Varmennettu paikallinen
ajo sisältää 527 ensimmäisen käynnin henkilöä: 470 indeksin saanutta ja 57
80 prosentin kattavuusrajan alle jäänyttä. Alkutarkastelussa puuttuvuus
kasautui kattavuusryhmään; puuttuvuuden syytä ei ole vielä varmennettu.

## Tavoite

Tuota yksi toistettava, kuvaileva arviointierä viimeksi varmennetusta
suojatusta DEAC v2 -ajosta. Säilytä hyväksytty pisteytys ja 80 prosentin
kattavuusraja. Kaikki henkilöavaimet, lähderivit ja henkilötason tulokset
pysyvät paikallisesti suojattuina.

## Rajaus

1. Tallenna indeksijakauman taulukko ja histogrammi sekä havaittujen
   komponenttien määrän jakauma.
2. Tallenna kaikkien 20 komponentin pistejakaumat ja puuttuvuus koko
   kohortissa sekä indeksin saaneilla ja kattavuusrajan alle jääneillä.
3. Vertaa ryhmien lähtöikää, sukupuolta ja klinikkakäynnin vuotta vain, jos
   kentät, semantiikka, ajoitus ja lähdesidonta voidaan paikallisesti
   varmentaa. Raportoi kunkin vertailukentän puuttuvuus; älä arvaa sidontaa.
4. Kuvaa puuttuvuuden kasautumista komponenttiryhmiin ja erota dokumentoitu
   puuttuvuuden syy tulkinnasta tai oletuksesta.
5. Tuota koontiraportti ja suojattu arviointimanifesti, jotka yksilöivät
   koodin, asetushashit, lähtöajon manifestin ja tuloshashin sekä rajoitukset.

Herkkyysanalyysit ovat vain seuraavan vaiheen ehdotuksia. DEAC-pisteytystä,
komponentteja, MOI-rajoja tai kattavuussääntöä ei muuteta.

## Definition of Done

- [x] Arviointikoodi lukee täsmälleen manifestissa hashattua suojattua tulosta
      ja tarkistaa lähtömanifestin sekä tiedosto-oikeudet.
- [x] Kaikki sovitut jakauma-, puuttuvuus- ja kattavuustaulukot sekä histogrammi
      tallentuvat suojattuun arviointihakemistoon.
- [x] Ikä-, sukupuoli- ja klinikkakäyntivuosivertailut tehdään vain
      varmennetuista kentistä; puuttuva kenttä tai sidonta raportoidaan
      saatavuusrajoitteena ilman arvausta.
- [x] Koontiraportti erottaa diagnostiset havainnot tulkinnasta, dokumentoidun
      puuttuvuuden syyn oletuksista eikä väitä mittaria validoiduksi.
- [x] Ajon, koodin, konfiguraation ja lähdemanifestin provenienssi sekä
      keskeiset aggregaattitarkistukset täsmäävät.
- [x] Ei raakadataa, henkilötason tuloksia, henkilötunnisteita tai salaisuuksia
      tallennu repoon.

## Log

- 2026-10-05T14:42:45+03:00: Ihmisen toimeksiannosta luotu valmiiksi rajattu
  01-ready-tehtävä. Käynnistyy tarkistetun main-version ja suojatun
  2026-10-05 DEAC v2 -ajon perusteella.
- 2026-10-05T14:43:00+03:00: Työ aloitettu; siirretään tehtävä
  02-in-progress-tilaan ennen arviointia.
- 2026-10-05T15:02:00+03:00: Suojattu arviointierä valmistui.
  Ikä- ja klinikkakäyntivuosisidonnat varmennettiin lähdehashiin ja valitsimeen;
  sukupuolelle ei löytynyt varmennettua sidontaa eikä KAAOS-sanastoa.
  Puuttuvuuden henkilökohtaista syytä ei päätelty; lähtötulos ei säilytä
  lähteen syykoodeja.
- 2026-10-05T15:02:00+03:00: Suojattu arviointitulos
  `deac_v2_descriptive_20261005T120152Z`: 527 henkilöä, 470 indeksiä ja 57
  kattavuusrajan alle. Taulukot, histogrammi, raportti ja manifesti ovat
  paikallisesti tiloilla 0600; arviointihakemisto 0700.
- 2026-10-05T15:02:00+03:00: Manifestin yhdeksän artefaktihashia tarkistettiin.
  Asetus-, lähde-, tulos- ja laskentakoodihashit sidottiin lähtömanifestiin.
  Ajo säilytti hyväksytyn pisteytyksen ja kattavuusrajan.
- 2026-10-05T15:02:00+03:00: Dokumentaatiotarkistukset ja diff-check
  läpäisivät. Tehtävä siirretty 03-review-tilaan ihmiskatselmointia varten.
- 2026-10-05T15:30:00+03:00: Pyydetty viimeistely: lisätty käyntivuoden,
  kattavuusryhmän ja komponentin mukainen puuttuvuustaulukko sekä synteettiset
  kohdennetut testit. Arviointimanifesti yksilöi erikseen lähtöajon Git-HEADin,
  arvioinnin Git-HEADin ja ajetun arviointitiedoston SHA-256:n. Tehtävä pysyy
  03-review-tilassa, kunnes riippumaton ihmishyväksyntänäyttö on kirjattu.
