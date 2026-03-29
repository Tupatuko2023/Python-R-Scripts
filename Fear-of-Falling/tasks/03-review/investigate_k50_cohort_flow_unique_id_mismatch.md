# Investigate K50 Cohort Flow Unique ID Mismatch

## Metadata

- Task type: read-only investigation
- Status: ready
- Owner: Codex
- Created: 2026-03-28T22:42:43+02:00
- Scope: audit current WIDE cohort-flow evidence chain for `535` vs historical `527 / 14 / 8 / 225`
- Constraints: no raw data edits, no output-discipline violations, no analysis-logic changes unless an unambiguous bug is proven

## Objective

Selvitä deterministisesti, mistä `diagram/paper_01_cohort_flow.wide.locomotor_capacity.resolved.dot`-tiedoston `Unique id = 535` ja `N = 535 participants with non-missing id` syntyvät, ja onko ristiriita historialliseen `527 / 14 / 8 / 225` -kontrolliin nykyisessä repossa regressio vai historiallinen/input-artifact-ero.

## Evidence Targets

- `tasks/03-review/K50_K20_person_dedup_consolidation.md`
- `tasks/03-review/2026-03-23_cohort-flow-align-to-k51-analytic.md`
- `R-scripts/K50/K50.1_COHORT_FLOW.V1_derive-cohort-flow.R`
- `R/functions/person_dedup_lookup.R`
- `R-scripts/K20/K20_duplicate_person_diagnostics.R`
- `diagram/paper_01_cohort_flow.wide.locomotor_capacity.resolved.dot`
- `diagram/render_paper_01_cohort_flow.sh`
- `R-scripts/K50/outputs/k50_wide_locomotor_capacity_cohort_flow_placeholders.csv`
- `R-scripts/K50/outputs/k50_wide_locomotor_capacity_input_receipt.txt`
- `R-scripts/K50/outputs/k50_wide_locomotor_capacity_modeled_cohort_provenance.txt`
- `manifest/manifest.csv`

## Log

- 2026-03-28T22:42:43+02:00 Created investigation task in `tasks/01-ready/` per orchestrator gate. Analysis to remain read-only unless documentation-only correction is justified by evidence.

## Audit Report

### 1. Executive Summary

Nykyisen repossa olevan evidenssin perusteella `Unique id = 535` ja `N = 535 participants with non-missing id` eivät ole regressio vaan nykyisen authoritative WIDE/LONG -ketjun mukainen arvo. `535` syntyy K50 cohort-flow -skriptissä muuttujasta `raw_id_n`, joka asetetaan myös `n_valid_id`:ksi, minkä jälkeen WIDE/locomotor-capacity-haara korvaa koko raw-continuity-laskentataulun authoritative LONG -placeholdereilla. Historiallista `527 / 14 / 8 / 225` -kontrollia ei nykyisellä inputilla saada enää toistettua, ja jo aiempi dedup-consolidation-task dokumentoi tämän input/artifact-history-eroksi.

### 2. Evidence Trail

- `tasks/03-review/K50_K20_person_dedup_consolidation.md` dokumentoi, että current local `DATA_ROOT` -inputilla `raw_id_n=535`, `n_raw_person_lookup=525`, `ex_duplicate_person_lookup=0` ja `ex_person_conflict_ambiguous=0`, eikä historiallista `527 / 14 / 8 / 225` -kontrollia saatu toistetuksi kummassakaan versiossa.
- `R/functions/person_dedup_lookup.R` sisältää nykyisen shared chooser/dedup-logiikan sekä LONG- että WIDE-haaroille (`pd_choose_*`, `dedup_person_records_*`). K50 ei enää käytä rinnakkaista paikallista chooseria.
- `R-scripts/K50/K50.1_COHORT_FLOW.V1_derive-cohort-flow.R` asettaa WIDE-haarassa `raw_id_n <- dedup_prep$diagnostics$raw_id_n` ja heti perään `n_valid_id <- raw_id_n`; samassa kohdassa luetaan myös `n_raw_person_lookup`, `ex_duplicate_person_lookup`, `ex_person_conflict_ambiguous` ja `n_dedup_person`.
- Samassa K50-skriptissä authoritative WIDE/locomotor-capacity-polku validoi K50 receipt/provenance- ja K51 receipt -artefaktit sekä korvaa `counts_tbl`- ja `placeholder_tbl`-sisällön LONG-authority-artifakteilla raw-continuity-ketjun säilyttämiseksi.
- `R-scripts/K50/outputs/k50_wide_locomotor_capacity_cohort_flow_placeholders.csv` näyttää eksplisiittisesti ketjun `1070 -> 535 -> 472 -> 240 -> 230` sekä lookup/dedup-tasot `N_RAW_PERSON_LOOKUP=525`, `EX_DUPLICATE_PERSON_LOOKUP=0`, `EX_PERSON_KEY_UNVERIFIED=10`, `EX_PERSON_CONFLICT_AMBIGUOUS=0`.
- `diagram/render_paper_01_cohort_flow.sh` ei laske mitään cohort-countteja itse. Se lukee template DOT:n, käy placeholder-CSV:n rivi kerrallaan läpi ja tekee pelkän `text.replace("__PLACEHOLDER__", value)` -substituution ennen Graphviz-renderiä.
- `diagram/paper_01_cohort_flow.wide.locomotor_capacity.resolved.dot` näyttää `Rows = 1070`, `Unique id = 535` ja `N = 535 participants with non-missing id`, mikä vastaa suoraan placeholder-CSV:n rivejä `N_RAW_ROWS=1070`, `N_RAW_ID=535` ja `N_VALID_ID=535`.
- Päivitetty `diagram/paper_01_cohort_flow.dot` ja uudelleenrenderöity `diagram/paper_01_cohort_flow.wide.locomotor_capacity.resolved.dot` näyttävät nyt myös raw-id continuity -solmun sisäisen jaon `525 verified person-linked + 10 fallback`; tämä breakdown tulee pipeline-generated placeholdereista `N_PERSON_VERIFIED` ja `N_PERSON_FALLBACK`, ei käsin tehdystä kuvapaikkauksesta.
- `tasks/03-review/2026-03-23_cohort-flow-align-to-k51-analytic.md` lukitsee DoD:ssa continuity chainin `1070 -> 535 -> 472 -> 240 -> 230` ja logissa toteaa, että WIDE placeholder CSV perii raw-row continuityn authoritative LONG -placeholdereista, mutta final analytic cohort pysyy authoritative WIDE/K51-taulun ankkurissa `230 / 161 / 69`.
- `R-scripts/K50/outputs/k50_wide_locomotor_capacity_input_receipt.txt`, `R-scripts/K50/outputs/k50_wide_locomotor_capacity_modeled_cohort_provenance.txt` ja `R-scripts/K51/outputs/k51_wide_input_receipt_analytic_wide_modeled_k14_extended.txt` kaikki vahvistavat authoritative snapshotin `paper_02_2026-03-21`, `rows_loaded_raw/rows_loaded=535` ja modeled/analytic `230`.

### 3. Root Cause Classification

Historiallinen artifact-ero / input-ero, tarkemmin vanhentunut historiallinen kontrolli nykyiseen authoritative inputiin nähden.

### 4. Technical Explanation

1. K50 cohort-flow lukee authoritative WIDE input-polun K50 receiptistä, ei ad hoc -kandidaateista.
2. Shared helper liittää workbookista verified SSN -person_keyn, deduplikoi verified-henkilöt shared chooserilla ja palauttaa diagnostiikat `raw_id_n`, `n_raw_person_lookup`, `ex_duplicate_person_lookup`, `ex_person_conflict_ambiguous`.
3. WIDE-haarassa `raw_id_n` asetetaan arvoksi `n_valid_id`, joten `535` on nimenomaan non-missing raw-id -taso eikä modeled final cohort.
4. Samasta dedup-objektista saadaan lookup-taso `525` ja ambiguity/duplicate-poistot `0`, joten nykyinen input ei sisällä historialliseksi väitettyjä `14` duplicate-person lookup -poistoja eikä `8` ambiguous-conflict -poistoja.
5. Tämän jälkeen WIDE-haara laskee final analytic cohortin paikallisesti arvoon `230` (`472 -> 240 -> 230`) ja varmistaa sen K50 receipt/provenance- sekä K51 analytic receipt -artefakteja vasten.
6. Kun authoritative WIDE-polku on käytössä, skripti korvaa `counts_tbl`- ja `placeholder_tbl`-objektit LONG-authority-artifakteilla raw-continuityn säilyttämiseksi; tästä syystä WIDE DOT:iin päätyy eksplisiittisesti `1070 -> 535 -> 472 -> 240 -> 230`.
7. Render-skripti ei tee uutta dedup- tai cohort-laskentaa, vaan kirjoittaa DOT:iin suoraan placeholder-CSV:n arvot. Siksi resolved DOT:n `535` voi tulla vain placeholder-CSV:stä, ei render-vaiheen omasta logiikasta.
8. Debian PRoot -validointi onnistui, kun `renv`-autoloader jätettiin päälle. `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE` johti tässä ympäristössä virheeseen `there is no package called 'dplyr'`, eli se oli ympäristö-/library-path-blokkeri eikä cohort-flow-logiikan poikkeama.
9. Onnistunut nykyinen PRoot-rerun kirjoitti cohort-flow-outputit uudelleen mutta säilytti samat luvut: `rows_loaded=535`, `n_dedup_person=535`, `n_raw_person_lookup=525`, `participants_modeled=230`, placeholder-ketju `1070 -> 535 -> 472 -> 240 -> 230`.

### 5. Recommended Action

- Älä muuta K50/K20 analyysilogiikkaa tämän auditin perusteella.
- Päivitä korkeintaan dokumentaatio, jossa historiallinen `527 / 14 / 8 / 225` esitetään nykyisen authoritative pipeline-ajon odotettuna kontrollina.
- Jos historiallinen luku halutaan säilyttää, merkitse se eksplisiittisesti eri inputin / eri artifact-version / pre-authoritative-lock -vaiheen kontrolliksi.
- Jos halutaan lisävarmistus, lisää dokumentaatioon yksi selittävä rivi: WIDE resolved DOT käyttää authoritative LONG raw-continuity-countteja, mutta final modeled cohort on authoritative WIDE/K51 `230 / 161 / 69`.

## Validation

- 2026-03-28: `bash tools/run-gates.sh --mode analysis --project Fear-of-Falling` onnistui repojuuresta ja kirjoitti metadata-artifaktit `manifest/`-kansioon.
- 2026-03-28: Debian PRoot `Rscript -e "cat(R.version.string)"` onnistui vasta, kun PATH pakotettiin Debianin omiin binääreihin.
- 2026-03-28: Debian PRoot `renv::restore()` raportoi kirjaston olevan synkronoitu lockfileen.
- 2026-03-28: Debian PRoot `R-scripts/K50/K50.1_COHORT_FLOW.V1_derive-cohort-flow.R --shape WIDE --outcome locomotor_capacity` onnistui autoloader päällä ja toisti samat `535 -> 472 -> 240 -> 230` arvot.

## Blockers

- Ei analyysiblokkeria. Ainoa havaittu kitka oli Debian PRoot -ympäristössä: jos `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE`, projektikirjaston paketit eivät tässä setupissa tule näkyviin.

## Log

- 2026-03-28T22:44:13+02:00 Ran `tools/run-gates.sh --mode analysis --project Fear-of-Falling` from repo root; gate passed and wrote run metadata.
- 2026-03-28T22:46:44+02:00 Verified current artifact chain from K50/K20/helper/render/receipt/provenance files; evidence already pointed to `535` as current authoritative raw-id continuity count.
- 2026-03-28T22:47:53+02:00 Confirmed Debian PRoot R works with Debian PATH; initial rerun with `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE` failed because `dplyr` was not visible in that library mode.
- 2026-03-28T22:48:53+02:00 Ran `renv::restore()` in Debian PRoot; library reported synchronized with lockfile.
- 2026-03-28T22:49:22+02:00 Successful Debian PRoot rerun of `K50.1_COHORT_FLOW.V1_derive-cohort-flow.R --shape WIDE --outcome locomotor_capacity` with renv autoload enabled; current environment reproduced `535 -> 472 -> 240 -> 230`.
- 2026-03-28T22:49:22+02:00 Audit conclusion: mismatch is best classified as historical/input-artifact difference, not current K50 regression.

## Workbook Addendum

### Workbook-Level Confirmation

Workbook `DATA_ROOT/paper_02/KAAOS_data_sotullinen.xlsx` on saatavilla nykyisessä ympäristössä ja helper käyttää juuri sitä lookup-lähteenä. Read-only helper-kysely nykyisellä authoritative K50 WIDE inputilla vahvisti seuraavan lukuketjun:

- `lookup_rows_total=541`
- `lookup_unique_ssn_total=527`
- `lookup_duplicate_ssn_total=14`
- `k50_input_rows=535`
- `k50_raw_id_n=535`
- `k50_raw_person_lookup=525`
- `k50_ex_duplicate_person_lookup=0`
- `k50_ex_duplicate_person_rows=0`
- `k50_ex_person_conflict_ambiguous=0`
- `k50_dedup_person_n=535`
- `k50_verified_person_n=525`
- `k50_unverified_person_n=10`
- `lookup_unique_ssn_linked_to_k50=525`
- `lookup_duplicate_ssn_linked_to_k50=0`

### Updated Interpretation

Tämä tarkoittaa, että käyttäjän `527`-havainto on nykyisessä ympäristössä tosi, mutta se koskee workbookin `normalized_ssn`-tasoa koko lookup-taulussa, ei K50 cohort-flow’n continuity-lukua.

Ero `527` vs `535` selittyy näin:

1. Workbookissa on `527` uniikkia `normalized_ssn`-henkilöä ja `14` duplicate-person-tapausta.
2. Näistä workbook-henkilöistä vain `525` linkittyy authoritative K50 WIDE -inputin riveihin bridge-keyn kautta.
3. K50 cohort-flow käyttää continuityssa `raw_id_n=535`, joka on authoritative WIDE inputin non-missing raw `id` -uniikit.
4. Samassa K50-inputissa `525` henkilöä saa verified workbook-SSN person-keyn ja `10` jää `id_fallback`-tasolle ilman verified SSN -linkkiä.
5. Siksi K50:n person-dedupin jälkeinen henkilömäärä on edelleen `535 = 525 verified + 10 unverified fallback`, vaikka workbookin oma SSN-uniikkitaso on `527`.
6. Koska K50 receipt/provenance näyttää `n_raw_person_lookup=525` ja `rows_loaded_raw=535`, repo itse jo erottaa nämä kaksi tasoa, mutta ne on helppo sekoittaa, jos `527` ja `535` käsitellään saman “unique id” -otsikon alla.

### Updated Root Cause Classification

Ei regressio eikä varsinainen ristiriita. Kyse on kahdesta eri laskentatasosta:

- Workbook person-unique count: `527` (`normalized_ssn` workbook lookupissa)
- K50 linked verified-person count: `525` (workbook-SSN:t, jotka linkittyvät authoritative K50 WIDE -inputiin)
- K50 raw-id continuity count: `535` (non-missing raw `id` authoritative WIDE -inputissa)

### Recommended Documentation Wording

Jos tästä tehdään dokumentaatiotäsmennys, turvallisin muotoilu on:

`527` on workbookin henkilöidentiteettitasoinen `normalized_ssn`-uniikkiluku, kun taas paper_01 cohort-flow’n `535` on authoritative K50 WIDE -inputin raw-id continuity count. Näistä `525` henkilöä linkittyy workbook-verified SSN -tasolle ja `10` jää `id_fallback`-tasolle, joten luvut eivät ole keskenään bugiluonteisessa ristiriidassa.

## Additional Validation

- 2026-03-28: Debian PRoot `R-scripts/K20/K20_duplicate_person_diagnostics.R` onnistui read-only-ajona ja raportoi `duplicate_persons_total=14`, `k50_ambiguous_total=0`.
- 2026-03-28: Debian PRoot custom helper query vahvisti workbookin `lookup_unique_ssn_total=527` sekä authoritative K50 WIDE -inputin jakauman `525 verified + 10 unverified = 535 raw-id continuity`.
- 2026-03-29: K50 WIDE rerun kirjoitti automaattisesti placeholderit `N_PERSON_VERIFIED=525` ja `N_PERSON_FALLBACK=10`, ja renderöity resolved DOT näytti nämä eksplisiittisesti raw-id continuity -solmussa samalla kun ketju `535 -> 472 -> 240 -> 230` pysyi ennallaan.

## Additional Log

- 2026-03-28T22:58:00+02:00 Confirmed workbook exists at `/data/data/com.termux/files/home/FOF_LOCAL_DATA/paper_02/KAAOS_data_sotullinen.xlsx` and that `resolve_ssn_lookup_path()` targets this exact file.
- 2026-03-28T22:59:00+02:00 Ran K20 duplicate-person diagnostics in Debian PRoot; summary confirmed `duplicate_persons_total=14` and `k50_ambiguous_total=0`.
- 2026-03-28T23:00:00+02:00 Ran custom read-only helper query in Debian PRoot; confirmed workbook `normalized_ssn` unique count `527`, K50-linked verified SSN count `525`, and K50 raw-id continuity count `535`.
- 2026-03-28T23:00:00+02:00 Refined audit conclusion: `527` and `535` are both correct in the current environment, but they describe different identity/count layers.
- 2026-03-29T13:40:00+02:00 Hardened workbook identity node into K50 placeholder generation: rerun of `K50.1_COHORT_FLOW.V1_derive-cohort-flow.R --shape WIDE --outcome locomotor_capacity` now writes `N_WORKBOOK_UNIQUE_SSN=527` automatically, and subsequent render keeps workbook 527 plus raw-id continuity 535 without manual CSV patching.
- 2026-03-29T14:05:00+02:00 Extended the same pipeline-generated diagram semantics into the raw-id continuity node: K50 placeholder output now emits `N_PERSON_VERIFIED=525` and `N_PERSON_FALLBACK=10`, and rerendered DOT shows `N = 535 participants with non-missing raw id (525 verified person-linked + 10 fallback)` without changing the downstream continuity chain.
