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
- Toimitusraja: alkuperäinen valtuutus kattoi paikallisen katselmoitavan commitin. Käyttäjän 21.11.2026 jatkovaltuutus kattaa tämän toimitushaaran pushin ja PR:n avaamisen. Ei main-mergeä, `04-done`-siirtoa eikä työpuun siivousta.

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
- 2026-11-21T09:53:24Z: Käyttäjä valtuutti lähtöcommitin `fffc75752bc96922261322f42d4788aeed81e379` rajatun pushin ja PR:n. Diffissä on vain tämä kortti ja uusi projektitietue; suojattuja tuloksia, tunnisteita tai yksityisiä absoluuttisia polkuja ei löytynyt. Termuxin unittest-sarjassa 62 testiä, neljä `AttributeError: module 'os' has no attribute 'link'` -virhettä: `GitGateTests.test_ignored_hard_link_to_tracked_source_is_rejected`, `SafePublicationTests.test_alias_created_during_write_is_rechecked_before_replace`, `SafePublicationTests.test_atomic_replace_does_not_modify_other_hard_link` ja `SafePublicationTests.test_hard_link_to_source_is_rejected`. Linux-CI:n soveltuva tarkistus selvitetään; koko sarja ei ole PASS.
- 2026-11-21: [Ubuntu `python-ci` -ajo 44807014203](https://github.com/Tupatuko2023/Python-R-Scripts/actions/runs/44807014203) koski aiempaa main-committia `2de6c1e516ee207aa8fb193d684807e31e3fbb33`, jossa rekisterigeneraattorin ja sen testitiedoston Git-blobit täsmäävät tämän haaran versioihin. JUnit-artefakti sisältää 62 rekisteritestiä; edellä nimetyt neljä ovat PASS. Tämä on saman koodiversion aiempaa Linux-CI-näyttöä, ei tämän Markdown-PR:n oma testiajo. PR:n Markdown-lint tarkistetaan erikseen.
- 2026-11-21T09:58:47Z: Haara puskettiin ja [PR #241](https://github.com/Tupatuko2023/Python-R-Scripts/pull/241) avattiin katselmointiin. PR:n ensimmäinen Markdown-lint pysähtyi uuden projektitietueen Prettier-muotoiluun. Taulukot muotoiltiin paikallisella, jo välimuistissa olleella Prettierillä ja lukittu lähdekuvaus suojattiin muotoilulta; lähdehash sekä CSV:n `--check` pysyivät ennallaan. Korjaus toimitetaan samaan PR:ään. Ei hyväksyntää, mergeä tai siivousta.

## Blockers

- G4:n seuraamatonta, laajaa valmistelukorttia ei tuoda tähän dokumentaatiomuutokseen. Sen Git-julkaisukelpoisuus ja tehtäväelinkaari arvioidaan erikseen.
- Tieteellinen raportointipäätös, ihmishyväksyntä ja main-toimitus eivät kuulu tämän tehtävän valmistumiseen.

## Links

- `docs/governance/project_registry/README.md`
