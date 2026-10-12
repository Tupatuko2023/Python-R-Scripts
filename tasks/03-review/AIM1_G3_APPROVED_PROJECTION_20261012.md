# AIM1 G3: hyväksytyn vastehierarkian operatiivinen projektio

## Context

Owner hyväksyi 2026-10-12 julkaistavaksi neljä G3-päätöskenttää. Suojattua lähdehandoffia käytetään yksityisenä provenance-näyttönä, eikä sitä julkaista. Tämä tehtävä peilaa jo hyväksytyn hierarkian Guidance Packageen; se ei tee uutta tieteellistä päätöstä.

## Inputs

- Ownerin hyväksymä `aim1-g3-approved-projection-20261012`-tehtäväpaketti.
- Yksityisesti varmennettu G3-auktoriteettihandoff ja päivitysluonnos.
- Canonical `origin/main`, AIM1 Analysis Guidance Package ja repositoryn governance.

## Outputs

- `AIM1_ANALYSIS_GUIDANCE_PACKAGE/ANALYSIS_DECISIONS.md`
- `AIM1_ANALYSIS_GUIDANCE_PACKAGE/EXECUTION_PLAN.md`
- Yksi rajattu, ihmisarviointiin jätettävä PR.

## Definition of Done (DoD)

- Julkaistu päätössisältö on vain: G3 RESOLVED / ADOPTED; E2 ensisijaiset vammaperusteiset hoitopäivät/henkilövuosi; E3 toissijaiset vammaperusteiset hoitojaksot/henkilövuosi; G3:n tekniset säännöt OPEN.
- G4 säilyy seuraavana operatiivisena tehtävänä; G5:n osasäännöt, G8 ja G11 säilyvät avoimina; G7:n E1–E4-päätös ja E5/E6-varmennustarve säilyvät.
- Suojatut handoffit, päätösrekisterit ja yksityinen provenance eivät päädy diffiin.
- Staattiset, reititys-, diff- ja lifecycle-tarkistukset läpäisevät. Data-QC ei sovellu tähän dokumenttipäivitykseen.
- Tehtävä siirtyy review-tilaan ja PR avataan; agentti ei hyväksy tai mergeä omaa työtään.

## Log

- 2026-10-12T14:05:12+03:00 READY-tehtävä luotu Ownerin rajatulla toteutus- ja julkaisuluvalla.

- 2026-10-12T14:05:24+03:00 READY -> IN_PROGRESS; pakollinen tehtäväjonon tarkistus läpäisty ennen Guidance Package -muutosta.

- 2026-10-12T14:08:23+03:00 Guidance Package -päätösprojektio valmis; staattinen scope/reititys/provenance PASS, git diff --check PASS ja tools/run-gates.sh --mode pre-push --smoke PASS. K18/QC: NOT APPLICABLE (vain dokumentaatiopäivitys).
- 2026-10-12T14:08:23+03:00 IN_PROGRESS -> REVIEW; PR odottaa ihmiskatselmointia. Paikallinen Prettier/markdownlint ei ole asennettu; GitHub CI tarkistaa ne.

- 2026-10-12T14:14:33+03:00 PR #205:n Prettier-CI osoitti G3-reititinrivin lyhentäneen WHAT_BLOCKS-sarakkeen leveyttä; sanamuoto täsmennettiin säilyttämään taulukon muoto. Paikallinen Prettier 3.9.9 --check PASS; tieteellinen päätössisältö ja reititys ennallaan.

## Blockers

- Ihmisen PR-katselmointi ja merge ovat myöhempiä pakollisia portteja.

## Links

- Repo-suhteelliset Guidance Package -polut yllä.
