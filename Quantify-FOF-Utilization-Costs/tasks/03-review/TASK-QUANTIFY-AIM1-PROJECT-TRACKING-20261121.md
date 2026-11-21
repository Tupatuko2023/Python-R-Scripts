# Quantify AIM1: G4-työn projektiseuranta

## Context

- Tavoite: perustaa nykyisen Quantify-FOF-Utilization-Costs-aliprojektin AIM1-palvelukäyttö- ja kustannustyölle oma projektitietue ja kirjata G4:n todellinen katselmointitila.
- Projektitietue: `PRJ-QUANTIFY-AIM1-UTILIZATION-COSTS`.
- Käyttäjän 21.11.2026 toimeksianto valtuuttaa tämän rajatun dokumentaatiotyön, eristetyn työpuun ja tehtäväkortin perustamisen. Ei tutkimusajoa.
- `PRJ-AIM1-REPO` koskee erillisen AIM1-analyysirepon rakentamista; sitä tai sen avoimen tehtävän muutoksia ei päivitetä tässä.

## Inputs

- `docs/governance/project_registry/README.md` ja `TEMPLATE.md`, tarkistettu `origin/main`-commit `3a29c4c4359edf0252efbe3a14afc3eb2cccf644`.
- Jaetun työpuun seuraamaton `tasks/02-in-progress/AIM1_G4_COSTING_DECISION_PREP_20261022.md` luettiin vain tilan lähteenä. Korttia ei kopioida tai julkaista.
- Aiemmat paikalliset G4-katselmointitoimitukset erotetaan ihmishyväksynnästä ja main-toimituksesta.

## Outputs

- `docs/governance/project_registry/PRJ-QUANTIFY-AIM1-UTILIZATION-COSTS.md` ja sen ohjeenmukainen, ignoroitu CSV-näkymä.
- Tämä tehtäväkortti `03-review`-tilassa, kun dokumentaatiomuutos ja tarkistukset valmistuvat.
- Sallitut kirjoituspolut: `Quantify-FOF-Utilization-Costs/tasks/01-ready/TASK-QUANTIFY-AIM1-PROJECT-TRACKING-20261121.md`, `Quantify-FOF-Utilization-Costs/tasks/02-in-progress/TASK-QUANTIFY-AIM1-PROJECT-TRACKING-20261121.md`, `Quantify-FOF-Utilization-Costs/tasks/03-review/TASK-QUANTIFY-AIM1-PROJECT-TRACKING-20261121.md`, `docs/governance/project_registry/PRJ-QUANTIFY-AIM1-UTILIZATION-COSTS.md`, ignoroitu `tools/project_registry/outputs/projects.csv`.
- Toimitusraja: paikallinen katselmoitava muutos. Ei pushia, PR:ää, main-mergeä, `04-done`-siirtoa eikä työpuun siivousta.

## Definition of Done

- Olemassa olevat projektimerkinnät ja rinnakkaiset työpuut on tarkistettu; G4:ää ei liitetä erillisen analyysirepon projektiin.
- Uusi projektitietue erottaa G4:n valmistelun, myöhemmät paikalliset katselmointipaketit, avoimet menetelmäpäätökset ja toimitusvaiheet.
- Lähdekuvauksen hash, CSV-generointi, `--check`, ignore-tarkistus, rekisterin testit ja soveltuva repoportti on dokumentoitu. Henkilöaineistoa ei lueta.

## Log

- 2026-11-21T03:13:42Z: Käyttäjän rajattu valtuutus vastaanotettu. `origin/main`-viite varmennettiin etävaraston mainiksi; erillinen puhdas työpuu perustettiin. Samannimistä projektimerkintää ei löytynyt nykyisestä rekisteristä eikä tarkistetuista haaroista.
- 2026-11-21T03:13:42Z: Kortti siirrettiin `01-ready`-kansiosta `02-in-progress`-kansioon. Projektin luonti rajattiin tähän korttiin ja sen sallittuun rekisteripolkuun; jaetun työpuun G4-korttia ei muutettu.
- 2026-11-21T03:16:36Z: Uuden rekisteritietueen lähdehash `30f71e7f28837812dccaa0b5467bfc07a6fa7a813c78fbfc2afa456bf31102b3` vastasi tallennettua kenttää. CSV muodostettiin kahdesti; SHA-256 pysyi `3361a5aab9edbffc33647f513a40f5ca7b808b556005b6fc28c593947844f33f`. Viisi projektia, `--check` PASS, ignore-portti PASS ja repojuuren pre-push-smoke PASS.
- 2026-11-21T03:16:36Z: Rekisterin 62 synteettisen unittestin sarjassa 58 testiä suorittui ilman virhettä ja neljä pysähtyi Termux-Pythonin puuttuvaan `os.link`-ominaisuuteen (`AttributeError`). Koko sarjaa ei merkitä PASSiksi; tämä dokumentaatiomuutos ei koske generaattorikoodia. Ei tutkimus- tai aineistoajoa.
- 2026-11-21T03:16:36Z: Rajattu dokumentaatiomuutos siirrettiin `03-review`-tilaan ja projektitietueen tehtäväpolku päivitettiin. Ihmisomistajan hyväksyntää, main-toimitusta tai työpuun siivousta ei ole tehty.

## Blockers

- G4:n seuraamatonta, laajaa valmistelukorttia ei tuoda tähän dokumentaatiomuutokseen. Sen Git-julkaisukelpoisuus ja tehtäväelinkaari arvioidaan erikseen.
- Tieteellinen raportointipäätös, ihmishyväksyntä ja main-toimitus eivät kuulu tämän tehtävän valmistumiseen.

## Links

- `docs/governance/project_registry/README.md`
