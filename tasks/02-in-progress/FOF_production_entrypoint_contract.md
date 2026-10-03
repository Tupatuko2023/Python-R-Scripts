# Fear-of-Falling: production-entrypointin hallintasopimus

## Context

Ownerin arkkitehtuuripäätös määrittää nykyiseksi väitöskirjatuotannon
entrypointiksi `Fear-of-Falling/reanalysis/R/cohort_implementation/cohort_implementation.R`.
Sen auktoritatiivinen syöte on `AUTH_SOURCE`, joka luetaan paikallisesta
`Fear-of-Falling/config/.env`-tiedostosta. Tiedosto on ignored ja untracked;
sen arvoa tai sisältöä ei saa julkaista. Nykyinen toteutus on olemassa,
mutta repositorion ohjeistus kuvaa osin vanhoja ajopolkuja nykyisinä.

K1 ja K05_MAIN ovat legacy-ajopintoja. `Fear-of-Falling/data/external/KaatumisenPelko.csv`
on `LEGACY_NOT_CURRENT_INPUT`, ja git-crypt on `LEGACY_NOT_CURRENT_RUNTIME`.
Nämä roolit ovat tuotantosopimuksen rajauksia, eivät lupa poistaa historiallisia
artefakteja tai tulkita niiden sisältöä julkaisukelpoiseksi.

## Inputs

- Ownerin yllä oleva normatiivinen tuotantoarkkitehtuuripäätös.
- Tuoreen upstream `origin/main`-basen entrypoint, helper ja synteettinen testi.
- Nykyiset repo- ja Fear-of-Falling-ohjeet sekä `config/steering.md`.

## Outputs

Vain seuraavat implementation-polut ovat tämän tehtävän piirissä:

1. `Fear-of-Falling/AGENTS.md`
2. `Fear-of-Falling/README.md`
3. `README.md`
4. `Fear-of-Falling/reanalysis/R/cohort_implementation/tests/test_output_routing.R`

Lisäksi vain tämän tehtävän oma READY → IN-PROGRESS → REVIEW -lifecycle-polku.
Erillistä Owner receipt -tiedostoa ei luoda valmisteluvaiheessa.

## Definition of Done (DoD)

- [x] Dokumentaatio nimeää `cohort_implementation.R`:n nykyiseksi
      väitöskirjatuotannon entrypointiksi ja `AUTH_SOURCE`:n auktoritatiiviseksi
      syötesopimukseksi.
- [x] Dokumentaatio kertoo, että `Fear-of-Falling/config/.env` on paikallinen,
      Gitin ohittama ja versionhallintaan kielletty. Yhtään oikeaa
      `AUTH_SOURCE`-arvoa, dataa tai salaisuutta ei esitetä.
- [x] K1 ja K05_MAIN luokitellaan legacypoluiksi;
      `KaatumisenPelko.csv` = `LEGACY_NOT_CURRENT_INPUT` ja git-crypt =
      `LEGACY_NOT_CURRENT_RUNTIME`. Historiallisia artefakteja ei poisteta.
- [x] Suora regressiotesti todentaa tuotantoentrypointin, odotetun `.env`-sijainnin,
      `AUTH_SOURCE`-valinnan ja legacy-CSV-fallbackin puuttumisen ilman oikeaa
      `.env`-tiedostoa, sen arvoa tai analyysidataa. Testi säilyttää nykyiset
      output-routing- ja tietoturva-assertionsa.
- [x] Muutos koskee vain neljää yllä lueteltua implementation-polkuа sekä
      tämän tehtävän lifecycle-tiedostoa. `cohort_implementation.R`- tai
      `cohort_security_helpers.R`-analyysilogiikkaa, K1/K05_MAIN-koodia,
      git-crypt-konfiguraatiota, legacy-CSV:tä, FOF-superprojektia ja
      submodule-gitlinkkiä ei muuteta.
- [x] Repo- ja task-policy sekä soveltuva suora synteettinen testi läpäisevät;
      `AUTH_SOURCE`-arvoa tai suojattua sisältöä ei lueta eikä tulosteta.

## Log

- 2026-10-03: READY-tehtävä valmisteltu Ownerin tuotantosopimuspäätöksestä
  tuoreelle upstream-mainille. Toteutusta, commitia ja pushia ei tehty.

- 2026-10-03T10:01:28+03:00: Owner valtuutti tämän taskin admissionin, neljän tiedoston
  toteutuksen sekä erilliset implementation- ja REVIEW-commitit ilman pushia.
  READY → IN-PROGRESS. Upstream main = ba8a77794481e871c8afa0ba93125eba91fb3cf9;
  canonical smoke-gate PASS. Erillistä admission-receiptiä ei vaadita.

- 2026-10-03T10:10:01+03:00: Toteutettu kolmen dokumentin nykyinen tuotantosopimus ja
  historiallisen Kxx-ohjeistuksen rajaus. Olemassa olevaan testiin lisätty
  staattinen/synteettinen --contract-only-ajo; analyysikoodia ei muutettu.
- 2026-10-03T10:10:01+03:00: Kohdistettu regressio PASS (20/20), komento aliprojektin juuresta:
  `Rscript --vanilla reanalysis/R/cohort_implementation/tests/test_output_routing.R --contract-only`.
  Todennettu entrypoint, AUTH_SOURCE, config/.env-sijainti, puuttuvan/tyhjän/
  moninkertaisen syötteen fail-closed, lähdehash-portti, legacy-CSV-fallbackin
  puuttuminen sekä K1/K05_MAIN-legacy-luokitus kaikissa kolmessa dokumentissa.
  Ensimmäisen testiajon Windows-polkuvertailu korjattu testissä; uusinta PASS.
- 2026-10-03T10:10:01+03:00: `run-gates.ps1 --mode pre-push --smoke` PASS toimivassa
  sandboxin ulkopuolisessa runtimessa. R 4.4.2; renv.lock read PASS.
  Prettier --check PASS ja markdownlint-cli2 PASS (3 dokumenttia, 0 virhettä)
  valmiiksi paikallisilla työkaluilla, ei asennuksia. `git diff --check` PASS.
- 2026-10-03T10:10:01+03:00: K18/QC: NOT APPLICABLE — dokumentaatio ja staattinen/synteettinen
  sopimustesti, ei data-, analyysilogiikka- tai QC-muutoksia. Täyttä Unix-
  turvatestistöä ei ajettu Windowsissa; sen olemassa olevat assertions säilyivät
  muuttumattomina. Kohdistettu PASS ei tarkoita täyden turvatestistön PASSia.
- 2026-10-03T10:10:01+03:00: Exact diff audit PASS: 4 implementation-tiedostoa + tämä task,
  luvattomia polkuja 0. config/.env ignored, untracked, unstaged; ei luettu.
  Oikeaa AUTH_SOURCE-arvoa tai suojattua dataa ei luettu/tulostettu.
  Analyysilogiikka, K1/K05_MAIN-koodi, legacy-CSV, git-crypt ja FOF-superprojekti
  säilyivät muuttumattomina. UPSTREAM_PRODUCTION_CONTRACT_ACCEPTANCE=PASS
  tarkoittaa taskin teknistä hyväksyntää; Owner-review on edelleen erillinen.

## Blockers

- Ei valmistelun yhteydessä havaittua production-kutsuketjun legacy-CSV-viitettä.
  Jos toteutusvaiheen uusi evidenssi osoittaa sellaisen, pysähdy ennen
  arkkitehtuuriväitteen vahvistamista.

## Links

- `Fear-of-Falling/reanalysis/R/cohort_implementation/cohort_implementation.R`
- `Fear-of-Falling/reanalysis/R/cohort_implementation/cohort_security_helpers.R`
- `SKILLS.md`
- `WORKFLOW.md`
