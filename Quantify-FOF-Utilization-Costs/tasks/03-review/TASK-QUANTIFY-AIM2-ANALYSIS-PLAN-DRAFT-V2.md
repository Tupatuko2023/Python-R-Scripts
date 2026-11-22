# TASK-QUANTIFY-AIM2-ANALYSIS-PLAN-DRAFT-V2: AIM2-analyysisuunnitelman Draft v2 -dokumenttipäivitys

## Context

- Tavoite: päivittää [ANALYSIS_PLAN.md](../../docs/ANALYSIS_PLAN.md) (`Draft v2`) erottamaan hyväksytyt tutkimus- ja tietosuojarajaukset, luonnosasteiset menetelmäehdotukset sekä avoimet AIM2-menetelmäpäätökset ilman lopullisen SAPin lukitsemista tai tutkimusanalyysien käynnistämistä.
- Mahdollinen projektitietue (`PRJ-*`): ei liitetä uuteen tai AIM1-projektitietueeseen (yksittäinen rajattu aliprojektin dokumenttipäivitys omassa tehtäväjonossa ohjeen [README.md](../../../docs/governance/project_registry/README.md) mukaisesti).
- Hyväksytyt operaatiot ja toimitusraja (kanoninen sääntö: [SKILLS.md](../../../SKILLS.md)): `git fetch origin main`, eristetty tehtäväworktree varmennetusta `origin/main`-revisiosta `039c545a08de86764b90a14b7d28508519e602d3`, tehtäväkortin elinkaarisiirrot (`01-ready` -> `02-in-progress` -> `03-review`), dokumenttipäivitys, soveltuvat dokumentaatiotarkistukset, kohdistettu stageaus, commit, push ja katselmointi-PR:n avaus. Ei mergeä, `04-done`-sulkua eikä työpuiden tai haarojen poistoa.

## Inputs

- [ANALYSIS_PLAN.md](../../docs/ANALYSIS_PLAN.md) (lähtöblob `d0ea9ca22836c50ac3510d30fe54a3ad5b818b4d`)
- [DATA_DICTIONARY_WORKFLOW.md](../../docs/DATA_DICTIONARY_WORKFLOW.md) ja [VARIABLE_STANDARDIZATION.md](../../data/VARIABLE_STANDARDIZATION.md)
- [2026-02-10_hospital_outcome_reconciliation.md](../../docs/reports/2026-02-10_hospital_outcome_reconciliation.md) ja [table2_technical_reproducibility_note.md](../../docs/table2_technical_reproducibility_note.md)
- [GEMINI.md](../../GEMINI.md), [CLAUDE.md](../../CLAUDE.md), [WORKFLOW.md](../../WORKFLOW.md), [runbook.md](../../docs/runbook.md) ja [RUNBOOK_SECURE_EXECUTION.md](../../../docs/guides/RUNBOOK_SECURE_EXECUTION.md)
- [DEAC_HANDOVER.md](../../../DEAC-Frailty-Index/docs/DEAC_HANDOVER.md) (vain julkisena viitteenä Osatyötä I varten valmistellun vajeindeksiluonnoksen komponenttirakenteeseen siirtämättä AIM1-päätöksiä AIM2:een)

## Outputs

- Sallitut kirjoituspolut (repojuureen suhteutettuina):
  - `Quantify-FOF-Utilization-Costs/docs/ANALYSIS_PLAN.md`
  - `Quantify-FOF-Utilization-Costs/tasks/01-ready/TASK-QUANTIFY-AIM2-ANALYSIS-PLAN-DRAFT-V2.md`
  - `Quantify-FOF-Utilization-Costs/tasks/02-in-progress/TASK-QUANTIFY-AIM2-ANALYSIS-PLAN-DRAFT-V2.md`
  - `Quantify-FOF-Utilization-Costs/tasks/03-review/TASK-QUANTIFY-AIM2-ANALYSIS-PLAN-DRAFT-V2.md`
- Rajauksen ulkopuoliset toimet:
  - Ei tutkimusanalyysejä, `DATA_ROOT`-aineiston lukua tai aineisto-QC-ajoja (`NOT_RUN` / `NOT APPLICABLE`).
  - Ei uutta `PRJ-*`-tietuetta eikä kytkentää AIM1-projektiseurantaan.
  - Ei muutoksia päächeckoutin paikallisiin tiedostoihin, vanhoihin tehtäväkortteihin tai muiden työpuihin.
  - Ei PR:n yhdistämistä (`merge`), teknistä `04-done`-sulkua eikä työpuun/haaran poistoa.

## Definition of Done (DoD)

- [x] [ANALYSIS_PLAN.md](../../docs/ANALYSIS_PLAN.md) erottaa hyväksytyt rajaukset, menetelmäehdotukset ja avoimet päätökset suomenkielisellä ohjeproosalla.
- [x] Kustannusmallin oletuskaavassa ei ole ennalta lukittua `person_time`-offsetia (seuranta-ajan käsittely esitetään avoimena/ehdollisena), ja kaksiosainen malli esitetään yhtenä ehdotuksena muiden vaihtoehtojen rinnalla.
- [x] Positiivisten kustannusten ehdollinen keskiarvo, koko kohortin odotettu kustannus ja `EUR/PY`-suureet (sekä palvelukäyttö, laskennallinen rahallinen arvo, toteutunut kustannus, laskutushinta ja asiakasmaksu) on erotettu selkeästi.
- [x] Tuotantoaineiston QC:n ja aggregaattien valtuutus- ja tietosuojaportit (`DATA_ROOT`, `frozen`-mappaus, kaksiosainen aggregaattiportti, `n < 5`, absoluuttisten polkujen esto) on kirjattu Quantify-ohjeiden mukaisesti ilman ajojen käynnistämistä.
- [x] AIM1:n mittari-, seuranta-, kovariaatti- tai hintavuosipäätöksiä ei ole siirretty AIM2:een lukittuina valintoina, viisi tunnistettua AIM2-menetelmäpäätöstä säilyvät avoimina, eikä muiden työtilojen tai `DATA_ROOT`-ympäristön toteutusten olemassaoloa kiistetä.
- [x] Kaikki suhteelliset linkit toimivat tiedostojen omista hakemistoista käsin, julkaistavuus- ja muotoilutarkistukset (`prettier`, `markdownlint-cli2`, `git diff --check`) menevät läpi ja tehtävä on luovutettu `03-review`-tilassa katselmointi-PR:ään.

## Log

- 2026-11-22T13:33:25+02:00 Varmennettu `origin/main` (`039c545a08de86764b90a14b7d28508519e602d3`) ja luotu eristetty tehtäväworktree haaralle `docs/quantify-aim2-analysis-plan-draft-v2` koskematta päächeckoutiin. Tehtäväkortti luotu `01-ready`-kansioon.
- 2026-11-22T13:36:15+02:00 Tehtäväkortti siirretty `01-ready` -> `02-in-progress` ennen kohdetiedoston muokkaamista.
- 2026-11-22T13:38:30+02:00 Päivitetty `Quantify-FOF-Utilization-Costs/docs/ANALYSIS_PLAN.md` (`Draft v2`) kaikkien kahdeksan tarkennuksen mukaisesti. Tutkimusanalyysejä ja `DATA_ROOT`-aineiston QC-ajoja ei suoritettu (`NOT_RUN` / `NOT APPLICABLE`).
- 2026-11-22T13:41:00+02:00 Siirretty kortti `02-in-progress` -> `03-review` ja ajettu dokumentaatio- ja turvaportit: `prettier --check` PASS, `markdownlint-cli2` PASS (`0 issues`), suhteelliset linkit `48/48` PASS, julkaistavuustarkistus PASS, `tools/run-gates.ps1 --mode pre-push --smoke` ja `git diff --check`. Valmis katselmointi-PR:ään.

## Blockers

- Pysähtymisehdot: tavoitteen, kirjoituspolkujen tai toimitusrajan laajennus, ratkaisematon porttivirhe tai lähderistiriita pysäyttää työn uuteen päätökseen asti. Ei aktiivisia esteitä.

## Links

- [ANALYSIS_PLAN.md](../../docs/ANALYSIS_PLAN.md)
- [WORKFLOW.md](../../WORKFLOW.md)
- [SKILLS.md](../../../SKILLS.md)
