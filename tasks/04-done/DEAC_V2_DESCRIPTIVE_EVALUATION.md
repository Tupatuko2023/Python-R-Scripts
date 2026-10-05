# DEAC v2:n kuvaileva mittariarviointi

## Status

- State: 04-done
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
-  arvioinnin Git-HEADin ja ajetun arviointitiedoston SHA-256:n.
- 2026-10-05T15:42:52+03:00: Ihmishyväksyntä ja merge todennettu PR:ssä
  [#186](https://github.com/Tupatuko2023/Python-R-Scripts/pull/186):
  hyväksyjä `Tupatuko2023`, aika 2026-10-05T12:42:52Z, hyväksytty head
  `b986c7cb38483eb1946d25f7109e176d9c99ddac`, squash-merge
  `606cda42713b4c05748b4f31796436bf46cdb71c`. PR:n diff sisälsi tämän
  tehtävän ja arvioinnin koodin, testin sekä dokumentaation. Headin checkit
  läpäisivät; vain soveltumattomat checkit ohitettiin.
- 2026-10-05T15:45:24+03:00: Käyntivuosittainen aggregaattitaulukko tuotettiin
  uudelleen varmennettua lähtöajoa vasten ilman pisteytyksen uusimista.
  Arviointitunnus `20261005T124524Z`; suojatut tulokset säilyvät
  repo-ulkopuolella.
- 2026-10-05T15:46:39+03:00: Tehtävä teknisesti suljettu ja siirretty
  `04-done`-tilaan ihmishyväksynnän, pysyvän PR-näytön ja paikallisen
  validoinnin jälkeen. Ihminen vastaa PR:n mergepäätöksestä; agentti ei
  yhdistänyt PR:ää.
