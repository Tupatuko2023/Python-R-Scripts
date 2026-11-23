# DEAC-komponentin toimitus yhdellä PR:llä

## Tavoite ja rajaus

Valmistele yhden toimitus-PR:n menettely uusille DEAC-komponenttitehtäville,
joiden tehtäväkortti nimeää menettelyn. Sama PR kattaa toteutuksen,
testinäytön, kortin ja tarvittavan projektirekisteriviitteen. Ihmisomistajan
pysyvä GitHub-hyväksyntä kohdistuu koko lopulliseen HEADiin. Nimetty siivous
voi sisältyä samaan valtuutukseen.

## Kirjoituspolut ja toimitusraja

- `SKILLS.md`, `AGENTS.md` ja `config/agent_policy.md`.
- Tämä kortti nykyisen menettelyn mukaisissa `01-ready`-, `02-in-progress`-
  ja `03-review`-poluissa.
- Tarkistus, commit, push ja yksi katselmointi-PR. Voimaantulo odottaa
  ihmisomistajan hyväksyntää ja varmennettua main-toimitusta.

## Hyväksymisehdot

- Rajaus koskee vain uusia, menettelyn erikseen nimeäviä DEAC-komponenttitehtäviä.
- `04-done`-polku toimitushaarassa on ehdotettu lopputila. Kortin ja
  rekisteriviitteen vastaavuus tarkistetaan synteettisessä Git-repossa.
- Yksi täsmähyväksyntä kattaa lopullisen diffiin sisältyvän työn. Toteutunut
  main-toimitus ja siivous tai perusteltu `retained` kirjataan yhdistetyn PR:n
  kommenttiin.
- Tämän ohjemuutostehtävän sulkeminen PR-kommentissa voidaan hyväksyä
  kertapoikkeuksena samalle HEADille. Kortti jää `03-review`-polkuun ja
  kommentti osoittaa sulun vasta main-toimituksen varmennuksen jälkeen.

## Loki

- 2026-11-21T20:46:36+02:00 Kortti luotiin `01-ready`-jonoon ihmisomistajan valtuutuksella.
- 2026-11-21T20:46:36+02:00 Kortti siirrettiin `02-in-progress`-jonoon.
- 2026-11-21T20:48:06+02:00 Synteettinen elinkaari- ja rekisteritarkistus läpäisty.
  Tarkistettiin kirjoitussuoja, lukittu lähdekuvaus, kortin ja viitteen
  vastaavuus, ehdollinen `04-done`-polku ja toistettava CSV.
  Kortti siirrettiin `03-review`-jonoon.

## Tila

- Katselmointiin valmis. Ihmisomistajan hyväksyntä ja main-toimitus odottavat.
